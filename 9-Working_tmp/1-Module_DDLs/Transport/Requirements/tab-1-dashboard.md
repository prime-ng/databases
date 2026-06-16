# Transport Tab 1: Transport Dashboard

This is the main overview screen for the Transport module. It gives administrators a real-time snapshot of the entire fleet — active routes, vehicle availability, upcoming certificate expirations, maintenance alerts, and driver attendance — all in one place.

---

## How It Works

When the administrator opens this tab, they see summary cards at the top. One card shows the total number of vehicles in the fleet and how many are currently available. Another shows how many routes are active today. A third shows how many trips are in progress or scheduled for the day. A fourth displays the count of drivers marked present for the current shift.

Below the cards, a list shows vehicles whose certificates (fitness, insurance, pollution, fire extinguisher) are expiring within the next 30 days, color-coded by urgency. A second list shows any open maintenance requests that have not yet been resolved. A third section lists today's scheduled trips with their current status (Scheduled, In Progress, Completed).

The dashboard is read-only and serves as a command center for monitoring fleet health and daily operations.

---

## Important Business Rules

- The dashboard is read-only — no data can be created or edited from this screen.
- If no vehicles are registered, all cards show zero and appropriate empty-state messages are displayed.
- Certificate expiry alerts trigger 30 days before the expiry date and disappear once the certificate is renewed.
- A vehicle is considered "available" only when `availability_status` = 1 AND `is_active` = 1 AND there is no open trip assigned to it for the current shift.
- Attendance data shown is for the current date only.
- Trip status values are: Scheduled, In Progress, Completed, Cancelled.
- The dashboard filters data to the logged-in user's school; super-admins can view all schools via a dropdown.

---

## Database Columns & Behavior

### tpt_vehicle (used via aggregate queries)
- `id` — Primary key. Used for counting total and available vehicles.
- `availability_status` — TINYINT(1). 0 = Not Available, 1 = Available. Determines vehicle card count.
- `is_active` — TINYINT(1). Only active (1) vehicles are counted.
- `fitness_valid_upto` — DATE. Used for expiry alerts within next 30 days.
- `insurance_valid_upto` — DATE. Used for expiry alerts within next 30 days.
- `pollution_valid_upto` — DATE. Used for expiry alerts within next 30 days.
- `fire_extinguisher_valid_upto` — DATE. Used for expiry alerts within next 30 days.

### tpt_route (used via aggregate queries)
- `id` — Primary key. Used for counting active routes.
- `is_active` — TINYINT(1). Only active routes are counted.
- `shift_id` — INT FK to tpt_shift. Routes are counted per shift.

### tpt_trip (used via aggregate queries)
- `id` — Primary key. Used for counting today's trips.
- `trip_date` — DATE. Only today's trips are shown.
- `status` — VARCHAR(20). Values: Scheduled, In Progress, Completed, Cancelled.
- `start_time` — DATETIME. NULL until trip begins.
- `end_time` — DATETIME. NULL until trip ends.

### tpt_driver_attendance (used via aggregate queries)
- `driver_id` — INT FK to tpt_personnel.
- `attendance_date` — DATE. Only current date is shown.
- `attendance_status` — INT FK to sys_dropdown_table. Determines present/absent counts.

### tpt_vehicle_service_request (used via aggregate queries)
- `id` — Primary key. Counts open requests.
- `request_approval_status` — ENUM('Approved','Pending','Rejected'). Pending requests appear in the maintenance alert list.

---

## Deep Analysis

### Business Workflows & State Machines

- **Dashboard Load Flow:** User logs in → resolve school_id (or super-admin dropdown) → execute aggregate queries across 5 tables → render KPI cards + alert lists + trip status widgets.
- **No state transitions** — the dashboard is purely a read-only aggregation view with no mutations.

### Validation Rules & Edge Cases

- **Zero-state:** If tpt_vehicle, tpt_route, or tpt_trip are empty, all card counts display 0 with an empty-state message rather than errors.
- **Certificate expiry edge:** A certificate expiring exactly 30 days from today should be included; expiry at 00:00:00 on day 31 should not.
- **Vehicle availability logic:** Must check `availability_status = 1 AND is_active = 1 AND no open trip for current shift` — requires a sub-query against tpt_trip.
- **Attendance date boundary:** Only `CURDATE()` data is shown; timezone handling must match the school's configured timezone.
- **Trip status filter:** Only "Scheduled" and "In Progress" trips are meaningful for the "today's trips" widget; "Completed" and "Cancelled" are displayed but non-actionable.

### Integration Points

- **tpt_vehicle** — aggregate count and availability/expiry data.
- **tpt_route** — count of active routes filtered by `is_active = 1`.
- **tpt_trip** — daily trip list with status-based filtering.
- **tpt_driver_attendance** — current-date attendance summary (present vs. absent).
- **tpt_vehicle_service_request** — unresolved maintenance request count.
- **sys_dropdown_table** — attendance status value resolution.
- **School context:** Filter by `school_id` from the authenticated user's session; super-admins see a multi-school selector.

### Permissions Matrix

| Role | View Dashboard |
|---|---|
| Super Admin | Full access, school dropdown |
| School Admin | Own school only |
| Transport Manager | Own school only |
| Driver / Helper | No access (dashboard is admin-only)
