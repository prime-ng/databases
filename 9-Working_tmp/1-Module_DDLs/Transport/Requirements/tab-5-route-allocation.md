# Transport Tab 5: Route Allocation

This screen handles two critical allocation tasks: assigning drivers and vehicles to routes, and allocating students to their pickup and drop stops. It also manages daily route scheduling for trip execution.

---

## How It Works

The first section is **Driver-Vehicle-Route Assignment**. The administrator selects a shift, a route, a direction (Pickup or Drop), a vehicle, a driver, and optionally a helper. These assignments have an effective date range and can overlap with other assignments only if the dates do not conflict. A database trigger prevents overlapping assignments for the same shift, route, vehicle, and driver combination.

The second section is **Daily Route Scheduling**. From the master assignments, the administrator generates daily schedules by selecting a specific date, shift, route, vehicle, driver, and helper. Each day's schedule is a concrete instance of the master assignment. A unique constraint ensures that on a given date, a vehicle, driver, or helper can only be assigned to one route per shift per direction.

The third section is **Student Route Allocation**. The administrator allocates each student to their pickup route/stop and drop route/stop. The student can use transport for Pickup only, Drop only, or Both. The fare is set at the allocation level. Each allocation has an effective from date and an active status flag.

---

## Important Business Rules

- A driver, vehicle, or helper cannot be assigned to overlapping date ranges for the same shift, route, and direction. A database trigger enforces this.
- In daily scheduling, a vehicle cannot be on two different routes on the same date, shift, and direction.
- A driver or helper cannot be scheduled on two different routes on the same date, shift, and direction.
- Students must already have an active academic session record before they can be allocated to a transport route.
- A student's pickup and drop routes can be different — they do not have to use the same route both ways.
- If a student uses transport for Both, the `both_side_fare` from the pickup point junction is used; otherwise the one-side fare applies.
- The `total_students` field on the driver-route-vehicle junction is denormalized for quick reference and should be updated when student allocations change.
- When a student is deactivated from transport, the `active_status` flag is set to 0 rather than deleting the record.

---

## Database Columns & Behavior

### tpt_driver_route_vehicle_jnt
- `id` — INT UNSIGNED AUTO_INCREMENT. Primary key.
- `shift_id` — INT UNSIGNED, NOT NULL. FK to tpt_shift.
- `route_id` — INT UNSIGNED, NOT NULL. FK to tpt_route.
- `vehicle_id` — INT UNSIGNED, NOT NULL. FK to tpt_vehicle.
- `driver_id` — INT UNSIGNED, NOT NULL. FK to tpt_personnel (role = Driver).
- `helper_id` — INT UNSIGNED, nullable. FK to tpt_personnel (role = Helper).
- `pickup_drop` — ENUM('Pickup','Drop'), NOT NULL, default 'Pickup'. Direction.
- `effective_from` — DATE, NOT NULL. Assignment start date.
- `effective_to` — DATE, nullable. Assignment end date. NULL = ongoing.
- `total_students` — INT, NOT NULL, default 0. Denormalized student count.
- `is_active` — TINYINT(1), default 1. Soft-delete flag.
- `created_at`, `updated_at`, `deleted_at` — Standard timestamp fields.
- Trigger `trg_driver_route_vehicle_unique_assignment` prevents overlapping date ranges for the same shift, route, vehicle, and driver combination.

### tpt_route_scheduler_jnt
- `id` — INT UNSIGNED AUTO_INCREMENT. Primary key.
- `scheduled_date` — DATE, NOT NULL. The date this schedule is for.
- `shift_id` — INT UNSIGNED, NOT NULL. FK to tpt_shift.
- `route_id` — INT UNSIGNED, NOT NULL. FK to tpt_route.
- `vehicle_id` — INT UNSIGNED, NOT NULL. FK to tpt_vehicle.
- `driver_id` — INT UNSIGNED, NOT NULL. FK to tpt_personnel.
- `helper_id` — INT UNSIGNED, nullable. FK to tpt_personnel.
- `pickup_drop` — ENUM('Pickup','Drop'), NOT NULL, default 'Pickup'. Direction.
- `is_active` — TINYINT(1), default 1. Soft-delete flag.
- `created_at`, `updated_at`, `deleted_at` — Standard timestamp fields.
- Unique keys: (scheduled_date, shift_id, route_id, pickup_drop); (vehicle_id, scheduled_date, shift_id, pickup_drop); (driver_id, scheduled_date, shift_id, pickup_drop); (helper_id, scheduled_date, shift_id, pickup_drop).

### tpt_student_route_allocation_jnt
- `id` — INT UNSIGNED AUTO_INCREMENT. Primary key.
- `student_session_id` — INT UNSIGNED, NOT NULL. FK to std_student_academic_sessions.
- `student_id` — INT UNSIGNED, NOT NULL. FK to std_students.
- `transport_use_type` — ENUM('Pickup','Drop','Both'), NOT NULL. Transport usage type.
- `pickup_route_id` — INT UNSIGNED, nullable. FK to tpt_route. Pickup route.
- `pickup_stop_id` — INT UNSIGNED, nullable. FK to tpt_pickup_points. Pickup stop.
- `drop_route_id` — INT UNSIGNED, nullable. FK to tpt_route. Drop route.
- `drop_stop_id` — INT UNSIGNED, nullable. FK to tpt_pickup_points. Drop stop.
- `fare` — DECIMAL(10,2), NOT NULL. Allocated fare amount.
- `effective_from` — DATE, NOT NULL. Allocation start date.
- `active_status` — TINYINT(1), default 1. 0 = deactivated, 1 = active.
- `created_at`, `updated_at`, `deleted_at` — Standard timestamp fields.

---

## Deep Analysis

### Business Workflows & State Machines

- **Driver-Vehicle-Route Assignment:** Select shift → Select route + direction → Assign vehicle + driver + optional helper → Set effective date range → Trigger validates no overlapping assignments → INSERT.
- **Daily Route Scheduling:** Select date → Pick from master assignments → Generate daily schedule → Unique constraints prevent duplicates → INSERT into `tpt_route_scheduler_jnt`.
- **Student Route Allocation:** Select student (must have active academic session) → Set transport use type (Pickup/Drop/Both) → Assign pickup and/or drop route+stop → Set fare → Effective from date → INSERT.
- **State Machine (Assignment):** Active → (effective_to passed) → Expired automatically; manual `is_active = 0` for early termination.
- **State Machine (Student Allocation):** Active → `active_status = 0` deactivates; record retained for history.

### Validation Rules & Edge Cases

- **Overlap prevention:** The trigger `trg_driver_route_vehicle_unique_assignment` checks date ranges for same (shift, route, vehicle, driver). Edge case: NULL `effective_to` means "ongoing" — only one ongoing assignment allowed per combination.
- **Daily scheduling uniqueness:** Four unique keys prevent a vehicle/driver/helper from being on multiple routes on the same date/shift/direction.
- **Student session FK:** Student must have a record in `std_student_academic_sessions` before allocation.
- **Fare derivation:** If `transport_use_type = Both`, the fare should default to `both_side_fare` from the junction; for Pickup or Drop only, use `pickup_drop_fare`.
- **`total_students` denormalization:** Must be updated via trigger or application logic whenever a student allocation is created or deactivated.
- **Route+Stop consistency:** Pickup route must have stops with appropriate `stop_type`; validation must ensure pickup_stop_id belongs to pickup_route_id.

### Integration Points

- **tpt_shift** — `shift_id` FK across all three sections.
- **tpt_route** — `route_id`, `pickup_route_id`, `drop_route_id` FKs.
- **tpt_vehicle** — `vehicle_id` FK.
- **tpt_personnel** — `driver_id`, `helper_id` FKs (role filtered to Driver/Helper).
- **tpt_pickup_points** — `pickup_stop_id`, `drop_stop_id` FKs.
- **std_student_academic_sessions** — `student_session_id` FK.
- **std_students** — `student_id` FK.
- **tpt_trip** — Created from route scheduler entries.
- **tpt_student_fee_detail** — Monthly fees generated from student allocations.

### Permissions Matrix

| Role | View | Create Assignment | Create Schedule | Allocate Student |
|---|---|---|---|---|
| Super Admin | Full | Full | Full | Full |
| School Admin | Full | Full | Full | Full |
| Transport Manager | Full | Yes | Yes | Yes |
| Driver / Helper | Own assignments | No | No | No |
