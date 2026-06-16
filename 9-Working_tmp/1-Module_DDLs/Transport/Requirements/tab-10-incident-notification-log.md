# Transport Tab 10: Incident, Boarding & Notification Log

This screen consolidates three tracking functions: recording trip incidents (accidents, breakdowns, delays), logging student boarding and unboarding events in real time, and maintaining a record of all notifications sent to parents about trip status.

---

## How It Works

The screen has three sub-sections.

**Trip Incidents:** During or after a trip, any authorized user can log an incident. Each incident records the trip, time, incident type (selected from a system dropdown — e.g., Accident, Breakdown, Medical Emergency, Road Block, etc.), severity level (LOW, MEDIUM, HIGH), GPS coordinates of the incident location, and a description. Incidents can be raised by one user and resolved by another. The status field tracks resolution progress through a system dropdown.

**Student Boarding Log:** As students board and unboard at each stop, the driver or helper scans the student's ID card or marks them manually. The system records the student, the trip, the stop, and the exact boarding and unboarding times. This provides a complete ridership audit trail. A student must have an active route allocation to be logged.

**Notification Log:** The system automatically sends notifications to parents at various trip milestones — when the trip starts, when the vehicle is approaching a stop, when it has reached a stop, when there is a delay, or when the trip is cancelled. Each notification is logged with the student, trip, stop, notification type, and delivery status for each channel (app push, SMS, email, WhatsApp). This log is read-only and serves as an audit trail of all parent communications.

---

## Important Business Rules

- Incident severity levels are LOW, MEDIUM, and HIGH. HIGH severity incidents should trigger immediate notification to school administrators (this is an application-level process).
- An incident can be raised without being resolved immediately. The `resolved_at` and `resolved_by` fields are filled when an authorized user marks it as resolved.
- A student must have an active route allocation to be eligible for boarding logging.
- The same student cannot be boarded twice on the same trip without first being unboarded (enforced at the application level).
- Boarding and unboarding times are stored separately to track the full journey for each student.
- The notification log is generated automatically by the system based on trip events. No manual notification entries can be created.
- If a notification channel fails (e.g., SMS service is down), the status is marked as 'Failed' and the system may retry based on application-level configuration.
- The notification log is read-only — no modifications are allowed once a notification record is created.
- Each notification type corresponds to a specific trip event: TripStart, ApproachingStop, ReachedStop, Delayed, Cancelled.

---

## Database Columns & Behavior

### tpt_trip_incidents
- `id` — INT UNSIGNED AUTO_INCREMENT. Primary key.
- `trip_id` — INT UNSIGNED, NOT NULL. FK to tpt_trip. The trip during which the incident occurred.
- `incident_time` — TIMESTAMP, NOT NULL. When the incident occurred.
- `incident_type` — INT UNSIGNED, NOT NULL. FK to sys_dropdown_table. Type of incident.
- `severity` — ENUM('LOW','MEDIUM','HIGH'), default 'MEDIUM'. Severity level.
- `latitude` — DECIMAL(10,7), nullable. GPS latitude of incident.
- `longitude` — DECIMAL(10,7), nullable. GPS longitude of incident.
- `description` — VARCHAR(512), nullable. Description of the incident.
- `status` — INT UNSIGNED, nullable. FK to sys_dropdown_table. Resolution status.
- `raised_by` — INT UNSIGNED, nullable. FK to sys_users. Who reported the incident.
- `raised_at` — TIMESTAMP, nullable. When the incident was raised.
- `resolved_at` — TIMESTAMP, nullable. When the incident was resolved.
- `resolved_by` — INT UNSIGNED, nullable. FK to sys_users. Who resolved the incident.
- `created_at`, `updated_at`, `deleted_at` — Standard timestamp fields.

### tpt_student_boarding_log
- `id` — INT UNSIGNED AUTO_INCREMENT. Primary key.
- `trip_date` — DATE, NOT NULL. Date of boarding/unboarding.
- `student_id` — INT UNSIGNED, nullable. FK to std_students.
- `student_session_id` — INT UNSIGNED, nullable. FK to std_student_academic_sessions.
- `boarding_route_id` — INT UNSIGNED, nullable. FK to tpt_route. Route used for boarding.
- `boarding_trip_id` — INT UNSIGNED, nullable. FK to tpt_trip. Trip used for boarding.
- `boarding_stop_id` — INT UNSIGNED, nullable. FK to tpt_pickup_points. Stop where student boarded.
- `boarding_time` — DATETIME, nullable. When the student boarded.
- `unboarding_route_id` — INT UNSIGNED, nullable. FK to tpt_route. Route used for unboarding.
- `unboarding_trip_id` — INT UNSIGNED, nullable. FK to tpt_trip. Trip used for unboarding.
- `unboarding_stop_id` — INT UNSIGNED, nullable. FK to tpt_pickup_points. Stop where student got off.
- `unboarding_time` — DATETIME, nullable. When the student unboarded.
- `device_id` — INT UNSIGNED, nullable. FK to tpt_attendance_device. Device used for scanning.
- `created_at`, `updated_at`, `deleted_at` — Standard timestamp fields.

### tpt_notification_log
- `id` — INT UNSIGNED AUTO_INCREMENT. Primary key.
- `student_session_id` — INT UNSIGNED, nullable. FK to std_student_academic_sessions.
- `trip_id` — INT UNSIGNED, nullable. FK to tpt_trip.
- `boarding_stop_id` — INT UNSIGNED, nullable. FK to tpt_pickup_points. The stop this notification is about.
- `notification_type` — ENUM('TripStart','ApproachingStop','ReachedStop','Delayed','Cancelled'), nullable. Type of notification event.
- `sent_time` — DATETIME, nullable. When the notification was sent.
- `app_notification_status` — ENUM('NotRegistered','Sent','Failed'), nullable. Push notification delivery status.
- `sms_notification_status` — ENUM('NotRegistered','Sent','Failed'), nullable. SMS delivery status.
- `email_notification_status` — ENUM('NotRegistered','Sent','Failed'), nullable. Email delivery status.
- `whatsapp_notification_status` — ENUM('NotRegistered','Sent','Failed'), nullable. WhatsApp delivery status.
- `created_at`, `updated_at`, `deleted_at` — Standard timestamp fields.

---

## Deep Analysis

### Business Workflows & State Machines

- **Incident Lifecycle:** Raised (any authorized user) → `raised_by` + `raised_at` set → Status set to initial value (e.g., "Reported") → Resolved by authorized user → `resolved_by` + `resolved_at` set → Status updated to "Resolved".
- **Incident Severity Escalation:** HIGH severity → Application should trigger immediate notification to school administrators (email/SMS/push).
- **Student Boarding Flow:** Student arrives at stop → Driver/Helper scans student ID → Record boarding with `boarding_time` → At destination → Scan again → Record `unboarding_time`. Same student cannot board twice without unboarding first (application-enforced).
- **Notification Generation:** System events (TripStart, ApproachingStop, ReachedStop, Delayed, Cancelled) → System auto-generates notification log entries → Send via configured channels (app push, SMS, email, WhatsApp) → Log delivery status per channel.
- **Notification Retry:** If a channel status is 'Failed', system may retry based on application configuration.

### Validation Rules & Edge Cases

- **Incident resolution:** An incident can be resolved by a different user than who raised it; `resolved_at` must be ≥ `raised_at`.
- **HIGH severity alert:** Must auto-notify; applications should implement a listener/observer pattern for severity-based escalation.
- **Boarding prerequisite:** Student must have `active_status = 1` in `tpt_student_route_allocation_jnt` to be boarded.
- **Double-board prevention:** Same (student_id, boarding_trip_id) where `boarding_time IS NOT NULL` and `unboarding_time IS NULL` → reject second board.
- **Notification log read-only:** No manual INSERT/UPDATE/DELETE — all entries are system-generated.
- **Channel status granularity:** Each notification type has 4 independent channel statuses; a failure on one channel does not affect others.
- **Notification types:** Only 5 valid types (TripStart, ApproachingStop, ReachedStop, Delayed, Cancelled); unknown types must be rejected.
- **GPS coordinates for incidents:** Latitude/longitude are optional but should be validated if provided (-90/90, -180/180).

### Integration Points

- **tpt_trip** — `trip_id` FK across all three sub-sections.
- **tpt_pickup_points** — `boarding_stop_id`, `unboarding_stop_id`, `boarding_stop_id` (notification).
- **tpt_route** — `boarding_route_id`, `unboarding_route_id`.
- **std_students** — `student_id` FK for boarding log.
- **std_student_academic_sessions** — `student_session_id` FK.
- **tpt_attendance_device** — `device_id` FK for boarding scans.
- **sys_users** — `raised_by`, `resolved_by` for incidents.
- **sys_dropdown_table** — `incident_type` and `status` value resolution.
- **Notification channels** — External SMS/Email/WhatsApp/Push services for delivery.

### Permissions Matrix

| Role | Log Incident | Resolve Incident | View Incidents | Scan Boarding | View Boarding | View Notifications |
|---|---|---|---|---|---|---|
| Super Admin | Yes | Yes | Full | Yes | Full | Full |
| School Admin | Yes | Yes | Full | Yes | Full | Full |
| Transport Manager | Yes | Yes | Full | Yes | Full | Full |
| Driver | Yes | No | Own trips | Yes | Own trips | Own trips |
| Helper | Yes | No | Own trips | Yes | Own trips | Own trips |
| Parent | No | No | No | No | Own child only | Own child only |
