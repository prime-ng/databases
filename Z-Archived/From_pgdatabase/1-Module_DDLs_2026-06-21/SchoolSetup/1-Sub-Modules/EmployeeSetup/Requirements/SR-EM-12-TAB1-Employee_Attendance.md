# Technical Specification & Requirements: Employee Daily Attendance marking
## Document ID: SR-EM-12-TAB1
**Module:** SchoolSetup / EmployeeSetup  
**Version:** 5.0 (Final)  
**Date:** May 2026  
**Status:** Approved Specification  

---

## 1. Tab Overview: Employee Attendance (`employee_attendance`)

The **Employee Attendance** tab provides a real-time tracking interface for daily attendance status. School administrators and HR managers can manually mark, view, and bulk-update daily attendance logs. It integrates shift-based hours, weekends, holidays, and approved leave statuses.

The primary system entity involved is:
* **Employee Attendance** (`sch_employee_attendance`): Captures work sessions, status IDs, working hours, grace check parameters, and geolocation metrics.

---

## 2. Database Schema Details (`sch_employee_attendance`)

| Column Name | Data Type | Cast / Type | Default | Nullable | Description |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `id` | `BIGINT` | Primary Key | *Auto-increment* | No | Unique identifier. |
| `employee_id` | `BIGINT` | Foreign Key | | No | Reference to target `sch_employees.id`. |
| `date` | `DATE` | `date` | | No | Target calendar date. |
| `shift_id` | `BIGINT` | Foreign Key | `NULL` | Yes | Reference to shift configurations (`sch_employee_shifts.id`). |
| `check_in_time` | `TIME` | `string` | `NULL` | Yes | Calculated/manual clock-in time. |
| `check_out_time` | `TIME` | `string` | `NULL` | Yes | Calculated/manual clock-out time. |
| `total_punches` | `INT` | `integer` | `0` | Yes | Count of punch logs synced. |
| `attendance_source` | `VARCHAR(30)` | `string` | `'Manual'` | No | Source: `Manual`, `QRCode`, `Biometric`, `MobileApp`, etc. |
| `device_id` | `VARCHAR(50)` | `string` | `NULL` | Yes | Device or scanner identifier. |
| `check_in_lat` / `check_in_lng` | `DECIMAL(10,7)` | `float` | `NULL` | Yes | Geolocation coordinate for clock-in. |
| `check_out_lat` / `check_out_lng` | `DECIMAL(10,7)` | `float` | `NULL` | Yes | Geolocation coordinate for clock-out. |
| `working_hours` | `DECIMAL(5,2)` | `decimal:2` | `NULL` | Yes | Total hours worked minus breaks. |
| `late_minutes` | `INT` | `integer` | `0` | Yes | Calculated lateness relative to shift start. |
| `early_minutes` | `INT` | `integer` | `0` | Yes | Calculated early check-out relative to shift end. |
| `is_overtime` | `TINYINT(1)` | `boolean` | `0` | No | Overtime designation. |
| `overtime_hours` | `DECIMAL(5,2)` | `decimal:2` | `0.00` | Yes | Extra hours worked beyond shift expectation. |
| `is_holiday` | `TINYINT(1)` | `boolean` | `0` | No | True if date is a configured public holiday. |
| `is_weekend` | `TINYINT(1)` | `boolean` | `0` | No | True if date is a weekend day. |
| `status` | `BIGINT` | Foreign Key | | No | Reference to `sch_staff_attendance_types.id`. |
| `leave_application_id` | `BIGINT` | Foreign Key | `NULL` | Yes | Reference to approved leave certificate (`sch_staff_leave_applications.id`). |
| `remarks` | `TEXT` | `string` | `NULL` | Yes | Custom supervisor/HR notes. |
| `marked_by` | `BIGINT` | Foreign Key | `NULL` | Yes | Reference to supervisor user (`sys_users.id`). |
| `marked_at` | `TIMESTAMP` | `datetime` | `NULL` | Yes | Execution timestamp of the marking. |
| `auto_marked` | `TINYINT(1)` | `boolean` | `0` | No | True if auto-calculated by biometric system. |
| `is_active` | `TINYINT(1)` | `boolean` | `1` | No | Active record status. |
| `created_by` | `BIGINT` | Foreign Key | `NULL` | Yes | Creator ID. |
| `deleted_at` | `TIMESTAMP` | Soft Delete | `NULL` | Yes | Soft-delete timestamp. |

---

## 3. Business Logic & Validation Rules

### A. Bulk Daily Saving (`EmployeeAttendanceController@storeEmployeeAttendance`)
* **`attendance_date`**: Required valid date.
* **`attendance`**: Required associative array where keys are employee IDs and values represent status IDs (or nested array with times/remarks).
* **`manual_check_in` / `manual_check_out`**: Optional batch times (HH:MM format) used as default fallbacks when individual values are absent.

### B. Shift & Status Determinations
1. **Weekend / Holiday Sync**: Automatically flags `is_weekend` and `is_holiday` if matching calendar configuration.
2. **Leave Auto-Detection**: Pre-selects the "On Leave" attendance type ID if an approved leave application overlaps the chosen date.
3. **Late and Early Clocking**: 
   - Lateness calculated as: `check_in_time` minus `shift.start_time` (if greater than grace period).
   - Early leave calculated as: `shift.end_time` minus `check_out_time`.
4. **Scanner Integration**: Allows real-time clock-in/out via QR scanner (`/school-setup/employee-attendance/scanner`), updating records and immediately dispatching raw biometric punch rows.
