# Employee Attendance — Requirement Document

## Screen Purpose & Overview

This screen is part of the Employee Attendance Management sub-menu. Its primary purpose is to track daily attendance, record manual attendance adjustments, and view automatically calculated attendance statuses (such as Present, Absent, Half-Day, or Late) for school teachers and staff.

Using this screen, school administrators or HR managers can select any date to view the entire staff's attendance register. The screen dynamically correlates assigned shifts, biometric punch times, holiday schedules, and approved leaves to calculate and display the final daily attendance status for each employee.

---

## Common Use Cases

1. **Daily Attendance Review:** Allowing HR or the Principal to review daily staff attendance and identify absentees.
2. **Manual Attendance Adjustments:** Manually recording attendance for guest lecturers or staff members in the event of a biometric device malfunction.
3. **Leave Integration Sync:** Automatically marking employees as "On Leave" in the daily attendance sheet if they have a pre-approved leave application for that date.
4. **Weekend & Holiday Auto-Tagging:** Automatically labeling weekends and calendar holidays as "Weekend" or "Holiday" on the daily sheet to prevent incorrect absence logging.
5. **QR Code Attendance Scanning:** Utilizing a front-office web scanner to register real-time check-in and check-out logs as employees scan their digital QR codes.

---

## Screen Fields & Input Rules

### Section A: Filter & Date Settings
| Field Name (Screen Label) | Input Description | Conditions / Rules (Simple terms) |
|---|---|---|
| Attendance Date | The target date for viewing or recording attendance | Required. Defaults to 'Today'. Future dates are blocked. |
| Select Department | Filter data by department | Optional. Dropdown: Academic, Admin, Support, etc. |
| Select Shift | Filter data by shift template | Optional. Dropdown of active shift templates. |

### Section B: Daily Attendance Grid Details
| Field Name (Screen Label) | Input Description | Conditions / Rules (Simple terms) |
|---|---|---|
| Employee Name | Name of the staff member | Display field. Auto-populated from the employee card. |
| Shift Timings | Start and end times of the assigned shift | Display field (e.g., General Shift: 08:30 AM to 02:30 PM). |
| Check-In Time | Time of arrival (In-Time) | Optional. Auto-synced from biometric logs or entered manually (HH:MM format). |
| Check-Out Time | Time of departure (Out-Time) | Optional. Auto-synced from biometric logs or entered manually (HH:MM format). |
| Attendance Status | Final daily attendance status | Required. Dropdown: Present / Absent / Half-Day / Late (linked to the Staff Attendance Types master). |
| Source | The source of the attendance log | System-generated tag (Biometric / QR Code / Manual / Mobile App). |
| Total Working Hours | Cumulative working hours logged | Automatically calculated: **Check-Out - Check-In - Break Duration**. |
| Remarks | Explanatory notes from the supervisor | Optional. Text area (e.g., "Arrived late due to public transit delay"). |

---

## Business Rules & Validation Policies

1. **Leave Interlock Constraint:**
   - If an employee has a pre-approved leave request for the selected date, the attendance status dropdown is locked to "On Leave". HR cannot modify this status unless the underlying leave application is cancelled or edited.

2. **Weekend & Holiday Exclusion Policy:**
   - If the selected date is a weekend or public holiday, the system automatically flags the row as `Is Weekend` or `Is Holiday`. Standard unpaid "Absent" markers are disabled on these dates unless manually overridden by the Admin.

3. **Late Arrival & Early Departure Calculation:**
   - If clock-in occurs after the shift start time plus the defined grace period (e.g., 15 minutes), the system computes and logs the "Late Minutes".
   - If clock-out occurs before the shift end time minus the early departure grace period, the system computes and logs "Early Departure Minutes".

4. **Biometric Integration Override:**
   - When biometric synchronization is active, raw punches are parsed to automatically populate check-in/out times, and the *Source* tag is set to "Biometric".

---

## Screen Workflows & Operations

### 1. Recording Bulk Daily Attendance (Bulk Save)
- HR selects the target date (defaults to the current date).
- The system loads the staff list with active shift employees set to their default statuses.
- HR modifies rows for employees who are late, absent, or have missing punches.
- Clicks "Save Attendance" to update and submit the entire register in a single batch.

### 2. Overriding Attendance Manually
- HR locates the employee's row, enters the correct check-in and check-out times, and adjusts the status (e.g., from Absent to Present).
- Enters an adjustment remark (e.g., "Biometric device sync failure").
- Clicks Save to commit the individual record override.

---

## Real-World Example Scenario

**HR Admin Rajesh Kumar** reviews school attendance for **May 21st, 2026**:

1. Rajesh opens the `Employee Attendance` screen. The date is set to `21-May-2026`.
2. Selects Department: `Academic`.
3. The system displays the teaching staff, their biometric logs, and calculated statuses:
   - **Sunita Sharma:** Punch-In: `08:25 AM`, Punch-Out: `02:35 PM`. Calculated status = `Present`.
   - **Vikram Rathore:** Punch-In: `09:10 AM` (Shift: `08:30 AM`, Grace: 15 mins). Calculated status = `Late` (Late Minutes: 40).
   - **Pooja Gupta:** Display status = `On Leave` (synced from an approved overlapping Sick Leave request).
4. Rajesh identifies a support staff member with a missing check-out punch. He inputs a manual check-in of `08:30 AM` and check-out of `02:30 PM`, selects status as `Present`, adds a remark, and clicks Save.
5. All attendance data is finalized and synchronized with the payroll processing engine.
