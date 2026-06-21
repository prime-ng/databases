# Technical Specification & Requirements: Employee Biometric & QR Punches
## Document ID: SR-EM-12-TAB2
**Module:** SchoolSetup / EmployeeSetup  
**Version:** 5.0 (Final)  
**Date:** May 2026  
**Status:** Approved Specification  

---

## 1. Tab Overview: Employee Punches (`employee_attendance_punches`)

The **Employee Punches** tab displays a chronological audit trail of raw biometric scans, RFID cards, and mobile app or QR scanner check-in/out check logs. It acts as the immutable log ledger where raw inputs from physical scanner gates or browser QR tools are synced before being parsed into processed daily attendance totals.

The primary system entity involved is:
* **Employee Attendance Punch** (`sch_employee_attendance_punches`): Captures timestamps, physical device locations, browser user agents, and IP addresses.

---

## 2. Database Schema Details (`sch_employee_attendance_punches`)

| Column Name | Data Type | Default | Nullable | Description |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `BIGINT` | *Auto-increment* | No | Primary Key. |
| `employee_id` | `BIGINT` | | No | Reference to target `sch_employees.id`. |
| `attendance_id` | `BIGINT` | `NULL` | Yes | Reference to target processed day `sch_employee_attendance.id`. |
| `punch_at` | `TIMESTAMP` | | No | Raw timestamp of biometric/scanner swipe event. |
| `punch_type` | `VARCHAR(20)` | | No | Direction: `In`, `Out`, `Break_In`, `Break_Out`. |
| `attendance_source` | `VARCHAR(30)` | | No | Source channel: `Biometric`, `Manual`, `MobileApp`, `QRCode`, `SmartCard`, `WebCheckIn`. |
| `device_id` | `VARCHAR(50)` | `NULL` | Yes | Machine hardware address or software scanner tag. |
| `device_location` | `VARCHAR(100)` | `NULL` | Yes | Name of physical location or campus entry gate. |
| `latitude` / `longitude` | `DECIMAL(10,7)` | `NULL` | Yes | Geo coordinates captured via mobile GPS. |
| `ip_address` | `VARCHAR(45)` | `NULL` | Yes | IP address of request initiator. |
| `user_agent` | `TEXT` | `NULL` | Yes | HTTP User Agent header info. |
| `is_within_geofence` | `TINYINT(1)` | `0` | No | True if coordinate is within approved school perimeter. |
| `is_processed` | `TINYINT(1)` | `0` | No | True if successfully analyzed into a daily shift total. |
| `is_invalid` | `TINYINT(1)` | `0` | No | Flag indicating suspicious or corrupted punches. |
| `invalidation_reason` | `TEXT` | `NULL` | Yes | Detail/cause for invalidation (e.g. duplicate punch). |
| `raw_payload` | `JSON` | `NULL` | Yes | Complete biometric sync JSON packet. |
| `created_at` | `TIMESTAMP` | `CURRENT_TIMESTAMP` | No | Log row creation timestamp. |

---

## 3. Business Logic & Processing Rules

### A. Network & Geo Validation
* **IP/User-Agent Tracking**: Standard HTTP headers are logged for security audits on every browser QR scan.
* **Geofence Check**: If mobile location tracking is enabled, the latitude and longitude must match approved school geo-boundaries. Otherwise, the punch is marked `is_invalid = 1` and rejected with `invalidation_reason = 'Outside approved perimeter'`.

### B. Index Filtering & Sorting
* **Timeline Listing**: Queries must sort punch rows in strict descending chronological order (`punch_at desc`) to prioritize recent logs.
* **Filter Conditions**: Allows filtering by employee name, punch type, sync source (e.g., `Biometric` vs `Manual`), validation status, and customizable date ranges using the `punch_daterange` picker.
