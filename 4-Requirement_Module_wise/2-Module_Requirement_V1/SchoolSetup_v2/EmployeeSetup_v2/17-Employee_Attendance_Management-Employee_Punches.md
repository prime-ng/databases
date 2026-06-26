# Employee Punches — Requirement Document

## Screen Purpose & Overview

This screen is part of the Employee Attendance Management sub-menu. Its primary purpose is to display a chronological audit log of raw entry punches (fingerprint scans, smart card swipes, or mobile application check-ins) captured from biometric hardware and mobile check-in channels.

Acting as a read-only transaction ledger, this page records the exact timestamp, machine location (e.g., Main Entrance Gate, Lobby Access), direction (In/Out/Break), and source for every punch. The system parses this raw ledger to calculate total daily working hours and compute final daily attendance statuses.

---

## Common Use Cases

1. **Auditing Biometric Raw Logs:** Inspecting an employee's complete swipe log to troubleshoot daily punch mismatches (e.g., verifying if the employee scanned their finger on the device).
2. **Reviewing Mobile Check-Ins & Geofencing:** Verifying if field duty check-ins logged via the mobile app fell within approved geographical boundaries (geofencing).
3. **Troubleshooting Hardware Sync Issues:** Confirming if physical biometric devices are successfully transmitting logs to the school's central server.
4. **Filtering Duplicate Punches:** Checking raw logs for duplicate inputs, such as when an employee scans their finger multiple times within a single minute.
5. **Security & IP Verification:** Checking browser user-agents and network IP addresses for web check-ins to detect proxy attendance attempts.

---

## Screen Fields & Input Rules

### Section A: Search Filters
| Field Name (Screen Label) | Input Description | Conditions / Rules (Simple terms) |
|---|---|---|
| Search Employee | Target employee name or ID | Optional. Search and select from the active employee list. |
| Date Range | Time window for the audit | Required. Date range boundary filters (e.g., May 1st to May 15th). |
| Punch Type | Direction of the punch | Optional. Dropdown: In (Entry) / Out (Exit) / Break In / Break Out. |
| Punch Source | Input source channel | Optional. Dropdown: Biometric (Fingerprint) / Smart Card / Mobile App / QR Code / Web Check-In. |
| Status Filters | Validation status of the log | Optional. Options: Processed (Parsed) / Raw / Invalid. |

### Section B: Punches Log Grid
| Field Name (Screen Label) | Input Description | Conditions / Rules (Simple terms) |
|---|---|---|
| Employee Name | Name of the staff member | Display field. Linked to the employee profile. |
| Punch Date & Time | Exact date and time of the punch | Display field (e.g., 21-May-2026 08:34:12 AM). |
| Direction | Swipe direction | Display field: In / Out / Break. |
| Device Location | Physical location of the biometric device | Display field (e.g., "Main Gate Entry Point"). |
| Geofence Status | Mobile app boundary check status | Display tag: Inside Geofence (Approved) / Outside Geofence (Rejected). |
| Valid? | Log validity status | Display indicator: Green (Valid) / Red (Invalid). |
| Invalidation Reason | Detailed reason for invalid punches | Display text if the log is flagged as invalid (e.g., "Duplicate swipe within 60s", "Outside approved perimeter"). |

---

## Business Rules & Validation Policies

1. **Geofence Perimeter Validation (Mobile App):**
   - When an employee checks in using the mobile app, the system checks their GPS coordinates (Latitude/Longitude) against the school's defined geofence radius.
   - If coordinates fall outside the perimeter, the punch is marked `Invalid` with the invalidation reason set to "Outside approved perimeter". These logs are excluded from working hour calculations.

2. **Immutable Record Policy:**
   - The raw punch ledger is strictly **read-only** (Immutable). No user, including HR and Administrators, can edit, insert, or delete raw punch timestamps. Any corrections to daily attendance must be processed through the "Employee Corrections" workflow.

3. **Chronological Sorting:**
   - Grid data is sorted in descending chronological order by default (latest logs shown at the top of the grid).

---

## Screen Workflows & Operations

### 1. Daily Punches Verification
- HR selects a date range and filters the logs.
- The system loads parsed data from the device servers, showing a chronological list of actions.
- The "Processed" tag indicates if the raw punch has been parsed and integrated into the employee's daily hours card.

### 2. Auditing Invalidated Logs
- HR filters the grid by "Invalid" status to check for anomalies.
- HR reviews invalidation reasons to identify hardware timing drifts or network sync errors, ensuring the hardware setup is corrected.

---

## Real-World Example Scenario

**Accountant Manish** informs HR that his attendance for yesterday is showing as "Absent" in the system, even though he punched in at the main gate.

1. HR opens the `Employee Punches` screen.
2. Filters by: Employee Name = `Manish`, Date = `20-May-2026`.
3. The system displays Manish's raw logs:
   - Punch 1: `08:28 AM`, Direction = `In`, Device = `Main Gate Biometric`, Status = `Processed` (Valid).
   - Punch 2: `08:29 AM`, Direction = `In`, Device = `Main Gate Biometric`, Status = `Invalid` (Reason: Duplicate swipe).
   - Punch 3: No records found for the afternoon/evening.
4. The logs show that Manish checked in, but failed to swipe out at the end of the day.
5. HR informs Manish that the raw logs are clear and he must submit an "Attendance Correction Request" for his check-out punch, as raw records cannot be edited directly.
