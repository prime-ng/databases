# Transport Tab 6: Trip Management

This screen tracks the real-time execution of each scheduled trip. When a driver starts their route, they record the beginning of the trip with odometer and fuel readings. As they visit each stop, they mark arrival and departure times. The trip ends when the driver reaches the final stop and completes the route.

---

## How It Works

The trip lifecycle begins from a scheduled entry created in the Route Allocation screen. The driver sees a list of their scheduled trips for the day. When they start the trip, the system captures the start time, start odometer reading, and start fuel level. The trip status changes from "Scheduled" to "In Progress."

As the driver proceeds along the route, they arrive at each stop and record the actual arrival time (reaching_time) and departure time (leaving_time). The system compares actual times against scheduled arrival/departure times for reporting. Each stop has a `reached_flag` that is set to 1 when the driver confirms arrival.

At any stop, the driver can raise an emergency flag with remarks and a timestamp. This is used for breakdowns, accidents, or any urgent situation requiring attention.

When the driver completes the route, they end the trip. The system captures the end time, end odometer reading, and end fuel reading. The trip status changes to "Completed." An authorized person (admin) then reviews and approves the trip completion.

---

## Important Business Rules

- A trip can only start if it has a valid scheduled entry in the route scheduler. Trips cannot be created ad-hoc without a schedule.
- Trip statuses: Scheduled, In Progress, Completed, Cancelled.
- The start odometer reading is mandatory when starting a trip; end odometer reading is mandatory when completing.
- Odometer readings must be in ascending order — the end reading must be greater than or equal to the start reading.
- A trip cannot be started twice. If a trip is already In Progress, the start action is disabled.
- The emergency flag at a stop can be set regardless of whether the stop has been reached or not.
- Once a trip is marked Completed, no further stop updates are allowed unless the trip is reopened by an authorized administrator.
- Trip approval (`approved` = 1) is a separate step performed by an authorized person. Approval updates vendor usage logs if the school setting `trip_usage_needs_to_be_updated_into_vendor_usage_log` is enabled.

---

## Database Columns & Behavior

### tpt_trip
- `id` — INT UNSIGNED AUTO_INCREMENT. Primary key.
- `trip_date` — DATE, NOT NULL. Calendar date of the trip.
- `route_scheduler_id` — INT UNSIGNED, NOT NULL. FK to tpt_route_scheduler_jnt.
- `route_id` — INT UNSIGNED, NOT NULL. FK to tpt_route. Denormalized for convenience.
- `vehicle_id` — INT UNSIGNED, NOT NULL. FK to tpt_vehicle.
- `driver_id` — INT UNSIGNED, NOT NULL. FK to tpt_personnel.
- `helper_id` — INT UNSIGNED, nullable. FK to tpt_personnel.
- `start_time` — DATETIME, nullable. When the trip started. NULL until trip begins.
- `end_time` — DATETIME, nullable. When the trip ended. NULL until trip completes.
- `start_odometer_reading` — DECIMAL(11,2), default 0.00. Odometer at trip start.
- `end_odometer_reading` — DECIMAL(11,2), default 0.00. Odometer at trip end.
- `start_fuel_reading` — DECIMAL(8,3), default 0.00. Fuel level at trip start.
- `end_fuel_reading` — DECIMAL(8,3), default 0.00. Fuel level at trip end.
- `status` — VARCHAR(20), default 'Scheduled'. Trip lifecycle status.
- `approved` — TINYINT(1), default 0. 0 = Pending Approval, 1 = Approved.
- `approved_by` — INT UNSIGNED, nullable. FK to sys_users.
- `approved_at` — TIMESTAMP, nullable. When the trip was approved.
- `remarks` — VARCHAR(512), nullable. Free-text remarks.
- `created_at`, `updated_at`, `deleted_at` — Standard timestamp fields.
- Index on (`route_scheduler_id`, `trip_date`) for fast lookup.

### tpt_trip_stop_detail
- `id` — INT UNSIGNED AUTO_INCREMENT. Primary key.
- `trip_id` — INT UNSIGNED, NOT NULL. FK to tpt_trip. Cascades on delete.
- `stop_id` — INT UNSIGNED, nullable. FK to tpt_pickup_points. NULL if stop is unknown.
- `pickup_drop` — ENUM('Pickup','Drop'), NOT NULL, default 'Pickup'. Direction.
- `ordinal` — SMALLINT UNSIGNED, default 1. Stop sequence number.
- `sch_arrival_time` — DATETIME, nullable. Scheduled arrival time from route planning.
- `sch_departure_time` — DATETIME, nullable. Scheduled departure time from route planning.
- `reached_flag` — TINYINT(1), default 0. 1 = driver confirmed arrival at this stop.
- `reaching_time` — TIMESTAMP, nullable. Actual arrival time recorded by driver.
- `leaving_time` — TIMESTAMP, nullable. Actual departure time recorded by driver.
- `emergency_flag` — TINYINT(1), default 0. 1 = emergency raised at this stop.
- `emergency_time` — TIMESTAMP, nullable. When the emergency was flagged.
- `emergency_remarks` — VARCHAR(512), nullable. Emergency details.
- `created_at`, `updated_at`, `deleted_at` — Standard timestamp fields.
- `updated_by` — INT UNSIGNED, nullable. FK to tpt_personnel. Who last updated this stop.

---

## Deep Analysis

### Business Workflows & State Machines

- **Trip State Machine:** `Scheduled` → (driver starts) → `In Progress` → (driver completes) → `Completed` → (admin approves) → `Approved` (via `approved` flag, status stays `Completed`).
- **Cancellation:** From `Scheduled` or `In Progress` → `Cancelled` (admin only).
- **Start Trip:** Validate schedule exists → Check no other trip in progress for this vehicle/driver → Capture start_time, start_odometer, start_fuel → Set status = 'In Progress'.
- **Stop Progression:** Driver arrives at stop → Set `reached_flag = 1`, `reaching_time` → Driver departs → Set `leaving_time` → Emergency can be raised at any point (`emergency_flag = 1`).
- **End Trip:** All stops reached → Capture end_time, end_odometer, end_fuel → Set status = 'Completed' → Admin reviews and sets `approved = 1`.
- **Post-Approval:** If `sch_settings.trip_usage_needs_to_be_updated_into_vendor_usage_log` is true, update `vnd_usage_logs` with trip usage data.

### Validation Rules & Edge Cases

- **No ad-hoc trips:** Must have a valid `route_scheduler_id` — trips cannot be manually created without a schedule.
- **Odometer cascade:** `end_odometer_reading` ≥ `start_odometer_reading`; enforce at application level.
- **Fuel reading cascade:** `end_fuel_reading` can be less than, equal to, or greater than `start_fuel_reading` (refueling during trip), but both must be reasonable values.
- **Double-start prevention:** If `status = 'In Progress'`, the start action must be disabled.
- **Stop updates locked:** After trip status = 'Completed', no further stop updates allowed unless an authorized admin reopens the trip.
- **Emergency at any stop:** `emergency_flag` can be 1 even if `reached_flag = 0`.
- **Trip approval scope:** Only authorized users (based on role/permission) can approve a trip.

### Integration Points

- **tpt_route_scheduler_jnt** — `route_scheduler_id` FK; trip must reference a valid schedule.
- **tpt_route** — `route_id` (denormalized).
- **tpt_vehicle** — `vehicle_id` FK.
- **tpt_personnel** — `driver_id`, `helper_id` FKs.
- **tpt_pickup_points** — `stop_id` in trip stop detail.
- **tpt_trip_stop_detail** — Child table CASCADE on trip delete.
- **sch_settings** — Check `trip_usage_needs_to_be_updated_into_vendor_usage_log` flag on approval.
- **vnd_usage_logs** — Updated when trip is approved if school setting is enabled.
- **sys_users** — `approved_by` FK for approval tracking.

### Permissions Matrix

| Role | View Trips | Start/End Trip | Record Stops | Approve Trip | Cancel Trip |
|---|---|---|---|---|---|
| Super Admin | Full | All | All | Yes | Yes |
| School Admin | Own school | All | All | Yes | Yes |
| Transport Manager | Own school | All | All | Yes | Yes |
| Driver | Own assigned | Own trips | Own stops | No | No |
| Helper | Own assigned | No | Own stops | No | No |
