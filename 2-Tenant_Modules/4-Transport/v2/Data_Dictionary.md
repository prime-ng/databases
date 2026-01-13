# Transport Module - Data Dictionary (v2)

**Document Version:** 2.0
**Schema Version:** 2.2
**Last Updated:** 2025-12-29

This document details the database schema for the **Transport Module**, including all tables, columns, data types, and relationships.

---

## 1. Core Master Tables

### 1.1 `tpt_vehicle`
Stores details of all vehicles managed by the school.

| Column | Type | Nullable | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | NO | PK, Auto Increment |
| `vehicle_no` | VARCHAR(20) | NO | Unique Vehicle/Chassis Number |
| `registration_no` | VARCHAR(30) | NO | Govt Registration Number |
| `model` | VARCHAR(50) | YES | Vehicle Model |
| `manufacturer` | VARCHAR(50) | YES | Manufacturer Name |
| `vehicle_type_id` | BIGINT UNSIGNED | NO | FK to `sys_dropdown_table` (Bus, Van, etc.) |
| `fuel_type_id` | BIGINT UNSIGNED | NO | FK to `sys_dropdown_table` (Diesel, Petrol, etc.) |
| `capacity` | INT UNSIGNED | NO | Seating Capacity (Default 40) |
| `max_capacity` | INT UNSIGNED | NO | Max Capacity incl. standing |
| `ownership_type_id` | BIGINT UNSIGNED | NO | FK to `sys_dropdown_table` (Owned, Leased) |
| `vendor_id` | BIGINT UNSIGNED | NO | FK to `tpt_vendor` |
| `fitness_valid_upto` | DATE | NO | Fitness Cert Expiry |
| `insurance_valid_upto` | DATE | NO | Insurance Expiry |
| `pollution_valid_upto` | DATE | NO | PUC Expiry |
| `vehicle_emission_class_id` | BIGINT UNSIGNED | NO | FK (BS IV, BS VI) |
| `gps_device_id` | VARCHAR(50) | YES | GPS Device ID |
| `availability_status` | TINYINT(1) | NO | 1=Available, 0=Not Available |
| `is_active` | TINYINT(1) | NO | Soft Delete Flag |
| `*_upload` | TINYINT(1) | NO | Flags for uploaded docs in `sys_media` |

### 1.2 `tpt_personnel`
Stores drivers, helpers, and transport staff.

| Column | Type | Nullable | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | NO | PK |
| `user_id` | BIGINT UNSIGNED | YES | FK to `sys_users` (Linked User Account) |
| `user_qr_code` | VARCHAR(30) | NO | Unique QR Code for Attendance |
| `name` | VARCHAR(100) | NO | Full Name |
| `role` | VARCHAR(20) | NO | Driver, Helper, Manager |
| `license_no` | VARCHAR(50) | YES | Driving License No |
| `license_valid_upto` | DATE | YES | License Expiry |
| `assigned_vehicle_id` | BIGINT UNSIGNED | YES | Default Vehicle |
| `police_verification_done` | TINYINT(1) | NO | 1=Done |

### 1.3 `tpt_shift`
Defines transport shifts (Morning, Afternoon, etc.).

| Column | Type | Nullable | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | NO | PK |
| `code` | VARCHAR(20) | NO | Unique Code |
| `name` | VARCHAR(100) | NO | Shift Name |
| `effective_from` | DATE | NO | Start Date |
| `effective_to` | DATE | NO | End Date |

---

## 2. Route & Stop Management

### 2.1 `tpt_route`
Defines a specific path taken by a vehicle.

| Column | Type | Nullable | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | NO | PK |
| `code` | VARCHAR(50) | NO | Unique Route Code |
| `name` | VARCHAR(200) | NO | Route Name |
| `pickup_drop` | ENUM | NO | Pickup, Drop, Both |
| `shift_id` | BIGINT UNSIGNED | NO | FK to `tpt_shift` |
| `route_geometry` | LINESTRING | YES | Spatial Data for Map |

### 2.2 `tpt_pickup_points`
Defines a physical stop location.

| Column | Type | Nullable | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | NO | PK |
| `name` | VARCHAR(200) | NO | Stop Name |
| `latitude` | DECIMAL(10,7) | YES | Lat |
| `longitude` | DECIMAL(10,7) | YES | Long |
| `location` | POINT | NO | Spatial Point |
| `stop_type` | ENUM | NO | Pickup, Drop, Both |

### 2.3 `tpt_pickup_points_route_jnt`
Mapping of stops to a route in a specific sequence.

| Column | Type | Nullable | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | NO | PK |
| `route_id` | BIGINT UNSIGNED | NO | FK to `tpt_route` |
| `pickup_point_id` | BIGINT UNSIGNED | NO | FK to `tpt_pickup_points` |
| `ordinal` | SMALLINT | NO | Sequence Number (1, 2, 3...) |
| `pickup_drop_fare` | DECIMAL | YES | Fare for this stop |
| `arrival_time` | INT | YES | Mins from start |

---

## 3. Operations & Scheduling

### 3.1 `tpt_route_scheduler_jnt`
Daily or Periodic schedule of a vehicle on a route.

| Column | Type | Nullable | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | NO | PK |
| `scheduled_date` | DATE | NO | Date of Schedule |
| `route_id` | BIGINT UNSIGNED | NO | FK to `tpt_route` |
| `vehicle_id` | BIGINT UNSIGNED | NO | FK to `tpt_vehicle` |
| `driver_id` | BIGINT UNSIGNED | NO | FK to `tpt_personnel` |

### 3.2 `tpt_trip`
Actual execution of a scheduled route.

| Column | Type | Nullable | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | NO | PK |
| `trip_date` | DATE | NO | Trip Date |
| `route_scheduler_id` | BIGINT UNSIGNED | NO | FK |
| `start_time` | DATETIME | YES | Actual Start |
| `end_time` | DATETIME | YES | Actual End |
| `start_odometer_reading` | DECIMAL | YES | Odo at Start |
| `end_odometer_reading` | DECIMAL | YES | Odo at End |
| `status` | VARCHAR(20) | NO | Scheduled, Ongoing, Completed |

### 3.3 `tpt_trip_incidents`
Incidents happened during a trip.

| Column | Type | Nullable | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | NO | PK |
| `trip_id` | BIGINT UNSIGNED | NO | FK |
| `incident_type` | BIGINT | NO | FK to Dropdown |
| `severity` | ENUM | DEFAULT 'MEDIUM' | LOW/MEDIUM/HIGH |
| `description` | VARCHAR(512) | YES | Details |
| `status` | BIGINT | YES | Incident Status |

---

## 4. Student & Attendance

### 4.1 `tpt_student_route_allocation_jnt`
Allocates a student to a route and stop.

| Column | Type | Nullable | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | NO | PK |
| `student_id` | BIGINT UNSIGNED | NO | FK |
| `route_id` | BIGINT UNSIGNED | NO | FK |
| `pickup_stop_id` | BIGINT UNSIGNED | NO | FK |
| `drop_stop_id` | BIGINT UNSIGNED | NO | FK |
| `fare` | DECIMAL | NO | Allocated Fare |

### 4.2 `tpt_attendance_device` (Enhanced)
Registered devices for marking attendance.

| Column | Type | Nullable | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | NO | PK |
| `user_id` | BIGINT UNSIGNED | NO | FK to `tpt_personnel` (Owner) |
| `device_uuid` | CHAR(36) | NO | Unique Device Identifier |
| `device_type` | ENUM | NO | Mobile, Tablet, etc. |
| `pg_fcm_token` | TEXT | YES | Firebase Token for Push |
| `is_active` | TINYINT | DEFAULT 1 | Active Status |

### 4.3 `tpt_student_boarding_log` (New)
Logs every student boarding/unboarding event.

| Column | Type | Nullable | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | NO | PK |
| `trip_id` | BIGINT UNSIGNED | YES | FK to Trip |
| `student_session_id` | BIGINT UNSIGNED | YES | FK to Student |
| `stop_id` | BIGINT UNSIGNED | YES | FK to Stop |
| `event_type` | ENUM | NO | 'BOARD' or 'UNBOARD' |
| `recorded_at` | DATETIME | NO | Exact timestamp |
| `device_id` | VARCHAR(200) | YES | UUID of scanning device |

### 4.4 `tpt_notification_log` (New)
Logs notifications sent regarding transport events.

| Column | Type | Nullable | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | NO | PK |
| `student_session_id` | BIGINT UNSIGNED | YES | FK |
| `notification_type` | ENUM | YES | TripStart, ReachedStop, etc. |
| `sent_time` | DATETIME | YES | When sent |
| `app_notification_status` | ENUM | YES | Sent/Failed |

---

## 5. Maintenance & Finance

### 5.1 `tpt_vehicle_maintenance`
Vehicle maintenance records.

| Column | Type | Nullable | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | NO | PK |
| `cost` | DECIMAL | NO | Total Cost |
| `status` | ENUM | DEFAULT 'Pending' | Approval Status |

### 5.2 `tpt_student_fee_collection`
Transport fee collection records.

| Column | Type | Nullable | Description |
|---|---|---|---|
| `id` | BIGINT UNSIGNED | NO | PK |
| `paid_amount` | DECIMAL | NO | Amount Paid |
| `payment_date` | DATE | NO | Date of Payment |

---

**End of Dictionary**
