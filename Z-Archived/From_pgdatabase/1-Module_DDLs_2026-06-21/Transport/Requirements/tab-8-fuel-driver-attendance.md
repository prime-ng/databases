# Transport Tab 8: Fuel Log & Driver Attendance

This screen manages two operational workflows: recording fuel purchases for each vehicle and tracking driver/helper attendance through digital ID card scans. Both workflows include an approval step and detailed logging.

---

## How It Works

The screen has two sections.

**Fuel Log:** The driver or administrator records each fuel refill by selecting the vehicle, driver, date, quantity in liters, total cost, fuel type, and current odometer reading. Each fuel entry starts with a Pending status and must be approved by an authorized person before it is finalized. Approved fuel entries cannot be edited.

**Driver Attendance:** Personnel scan their QR/RFID/NFC/Barcode ID card at a device when they arrive for their shift (IN) and when they leave (OUT). The scan records the time, attendance type (IN/OUT), scan method (QR/RFID/NFC/Manual), device information, and GPS coordinates. The system creates a daily attendance record for each person with first-in and last-out times, total work minutes, and an overall status (Present, Absent, Half-Day, Late). Duplicate scans within a short window are flagged as Duplicate and ignored.

Each personnel member must first register their device in the `tpt_attendance_device` table before they can scan attendance. The device registration includes the device UUID, type, OS, app version, and FCM token for push notifications.

---

## Important Business Rules

- A fuel entry must be approved by an authorized person before it is considered finalized.
- Approved fuel entries cannot be modified or deleted.
- The odometer reading on a fuel entry should be greater than the previous fuel entry's odometer reading for the same vehicle.
- Each person can have only one attendance record per date — the unique key on (driver_id, attendance_date) enforces this.
- The first scan of the day is recorded as `first_in_time`; subsequent scans are logged in the attendance log but do not overwrite `first_in_time`.
- The last OUT scan of the day is recorded as `last_out_time`.
- Total work minutes are calculated as the difference between first IN and last OUT.
- Duplicate scans (same person, same device, same type within a configurable time window) are marked as Duplicate and not counted.
- A scan can be marked Rejected if the GPS location is outside the authorized geofence (validated at the application level).
- Attendance can be marked manually by an administrator if the device scan fails.

---

## Database Columns & Behavior

### tpt_vehicle_fuel
- `id` — INT UNSIGNED AUTO_INCREMENT. Primary key.
- `vehicle_id` — INT UNSIGNED, NOT NULL. FK to tpt_vehicle.
- `driver_id` — INT UNSIGNED, nullable. FK to tpt_personnel.
- `date` — DATE, NOT NULL. Date of refueling.
- `quantity` — DECIMAL(10,3), NOT NULL. Fuel quantity in liters.
- `cost` — DECIMAL(12,2), NOT NULL. Total cost of fuel.
- `fuel_type` — INT UNSIGNED, NOT NULL. FK to sys_dropdown_table. Fuel type (Diesel, Petrol, CNG, Electric).
- `odometer_reading` — INT UNSIGNED, nullable. Odometer reading at time of refuel.
- `remarks` — VARCHAR(512), nullable.
- `status` — ENUM('Approved','Pending','Rejected'), default 'Pending'. Approval status.
- `created_at`, `updated_at`, `deleted_at` — Standard timestamp fields.

### tpt_attendance_device
- `id` — INT UNSIGNED AUTO_INCREMENT. Primary key.
- `user_id` — INT UNSIGNED, NOT NULL. FK to tpt_personnel. Personnel who owns this device.
- `device_uuid` — CHAR(36), NOT NULL. Unique device identifier (UUID).
- `device_type` — ENUM('Mobile','Tablet','Laptop','Desktop'), NOT NULL.
- `location` — VARCHAR(150), nullable. Device location description.
- `device_os` — INT, NOT NULL. FK to sys_dropdown_table. OS type (android, ios, windows, linux, mac).
- `os_version` — VARCHAR(50), nullable. OS version string.
- `device_name` — VARCHAR(100), NOT NULL. Device friendly name.
- `device_model` — VARCHAR(100), nullable. Device model (e.g., iPhone 12 Pro).
- `pg_app_version` — VARCHAR(20), nullable. Prime-AI app version.
- `pg_fcm_token` — TEXT, nullable. Firebase Cloud Messaging token for push notifications.
- `pg_first_registered_at` — TIMESTAMP. Auto-set on first registration.
- `pg_last_seen_at` — TIMESTAMP, nullable. Last time the device was used.
- `is_active` — TINYINT(1), default 1.
- `created_at`, `updated_at`, `deleted_at` — Standard timestamp fields.
- Unique keys: `device_uuid` unique; `(user_id, device_uuid)` unique.

### tpt_driver_attendance
- `id` — INT UNSIGNED AUTO_INCREMENT. Primary key.
- `driver_id` — INT UNSIGNED, NOT NULL. FK to tpt_personnel.
- `attendance_date` — DATE, NOT NULL. Date of attendance.
- `first_in_time` — DATETIME, nullable. First IN scan of the day.
- `last_out_time` — DATETIME, nullable. Last OUT scan of the day.
- `total_work_minutes` — INT, nullable. Computed total minutes worked.
- `attendance_status` — INT, NOT NULL. FK to sys_dropdown_table. Values: Present, Absent, Half-Day, Late.
- `via_app` — TINYINT(1), default 1. 1 = scanned via app, 0 = manual entry.
- `created_at` — TIMESTAMP.
- Unique key on (`driver_id`, `attendance_date`).

### tpt_driver_attendance_log
- `id` — INT UNSIGNED AUTO_INCREMENT. Primary key.
- `attendance_id` — INT UNSIGNED, NOT NULL. FK to tpt_driver_attendance.
- `scan_time` — DATETIME, NOT NULL. Timestamp of the scan.
- `attendance_type` — ENUM('IN','OUT'), NOT NULL. Direction of scan.
- `scan_method` — ENUM('QR','RFID','NFC','Manual'), NOT NULL. How the scan was performed.
- `device_id` — INT UNSIGNED, NOT NULL. FK to tpt_attendance_device.
- `latitude` — DECIMAL(10,6), nullable. GPS latitude of scan.
- `longitude` — DECIMAL(10,6), nullable. GPS longitude of scan.
- `scan_status` — ENUM('Valid','Duplicate','Rejected'), NOT NULL, default 'Valid'. Scan validation result.
- `remarks` — VARCHAR(255), nullable.
- `created_at` — TIMESTAMP.

---

## Deep Analysis

### Business Workflows & State Machines

- **Fuel Entry State Machine:** `Pending` → (admin approves) → `Approved` or `Rejected`. Approved entries are immutable.
- **Fuel Entry Flow:** Select vehicle → Select driver → Enter date, quantity, cost, fuel type, odometer → INSERT with `status = 'Pending'`.
- **Attendance Scan Flow:** Personnel arrives → Device scans QR/RFID/NFC → Log IN scan → Upsert `tpt_driver_attendance` (set `first_in_time` if not set) → INSERT scan log. On departure, same flow for OUT scan → Update `last_out_time` and compute `total_work_minutes`.
- **Manual Attendance:** Authorized admin can manually create attendance records or override scans (`via_app = 0`).
- **Duplicate Detection:** Same person + same device + same type within configurable time window → set `scan_status = 'Duplicate'` and ignore.

### Validation Rules & Edge Cases

- **Fuel approval immutability:** Once `status = 'Approved'`, all fields except `remarks` should be locked.
- **Odometer progression:** New fuel entry odometer must be ≥ previous entry's odometer for same vehicle.
- **First IN / Last OUT:** The first scan of type 'IN' on a date sets `first_in_time`; subsequent IN scans are logged but don't overwrite. The last OUT scan sets `last_out_time`.
- **Duplicate window:** Configurable (e.g., 5 minutes). Scans within the window for same (driver, device, type) are marked Duplicate.
- **Geofence rejection:** Application-level check: if GPS coordinates are outside the school's authorized geofence, set `scan_status = 'Rejected'`.
- **Unique attendance per day:** UNIQUE KEY (driver_id, attendance_date) ensures one aggregated record per person per day.
- **Work minutes calculation:** `total_work_minutes = TIMESTAMPDIFF(MINUTE, first_in_time, last_out_time)`; if either is NULL, total remains NULL.
- **Device registration prerequisite:** A device must exist in `tpt_attendance_device` before scanning.

### Integration Points

- **tpt_vehicle** — `vehicle_id` in fuel entries.
- **tpt_personnel** — `driver_id` in fuel and attendance; `user_id` in device registration.
- **tpt_attendance_device** — Device registration linked to personnel.
- **sys_dropdown_table** — `fuel_type` and `attendance_status` value resolution.
- **Geofencing** — School geofence configuration for scan validation.

### Permissions Matrix

| Role | Add Fuel | Approve Fuel | View Fuel | Scan Attendance | Manual Attendance | View Attendance |
|---|---|---|---|---|---|---|
| Super Admin | Yes | Yes | Full | Yes | Yes | Full |
| School Admin | Yes | Yes | Full | Yes | Yes | Full |
| Transport Manager | Yes | No | Full | Yes | No | Full |
| Driver | Own vehicle | No | Own entries | Own scans | No | Own records |
| Helper | No | No | No | Own scans | No | Own records |
