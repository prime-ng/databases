# Employee Shifts — Requirement Document

## Screen Purpose & Overview

This screen is used to create and manage **Shift Templates** under the Attendance Masters sub-menu. A shift template defines the parameters of a working day for different staff groups, including start and end times, break/lunch durations, late arrival grace periods, early logout allowances, and the minimum working duration required to qualify for half-day or full-day attendance.

Defining shift templates allows the school to cater to different schedules across various employee groups — such as a "Morning Shift" for Teachers, a "Night Shift" for Security Guards, and a "Regular Shift" for Administrative Staff.

---

## Common Use Cases

1. **Configuring Shift Timings:** Creating a standard work shift template, such as "Standard Teaching Shift", starting at 08:00 AM and ending at 02:00 PM.
2. **Setting Break/Lunch Durations:** Subtracting break times (e.g., 30 minutes) from total shift hours to calculate the net required working hours.
3. **Defining Grace Periods for Late Arrival:** Setting a rule that allows employees a minor delay (e.g., up to 10 minutes past the start time) before marking them as late.
4. **Setting Half-Day & Absent Thresholds:** Configuring rules to automatically mark an employee "Absent" if they work less than a set threshold (e.g., 15 minutes) or "Half-Day" if they only work a partial duration (e.g., between 2 to 4 hours).

---

## Screen Fields & Input Rules

| Field Name (Screen Label) | Input Description | Conditions / Rules (Simple terms) |
|---|---|---|
| Shift Code | Unique short code for the shift (e.g., S-TCH, S-ADM) | Required. Must be unique. Two shift templates cannot share the same code. |
| Shift Name | Full descriptive name (e.g., Teachers Shift, Guard Rotation) | Required. Length must be between 1 to 100 characters. |
| Description | Details about who the shift is for and its purpose | Optional. |
| Start Time | The official shift start time | Required. HH:MM (AM/PM) format. |
| End Time | The official shift end time | Required. End time must be after the Start Time. |
| Break Duration (Mins) | Duration of lunch/tea break in minutes | Required. Specified in minutes (e.g., 30 or 60). This duration is subtracted from total elapsed time to find net working hours. |
| Net Working Hours | Net required work hours | Automatically calculated using the formula: **(End Time - Start Time) - Break Duration**. |
| Grace Period (Late in Mins) | Permitted late arrival allowance in minutes | Required. For example, if set to 10 minutes for an 08:00 AM shift, arrivals up to 08:10 AM will not be flagged as 'Late'. |
| Grace Period (Early Out in Mins) | Permitted early departure allowance in minutes | Required. For example, if set to 5 minutes for a 02:00 PM shift, logging out at 01:55 PM will not incur a penalty. |
| Half-Day Threshold (Mins) | Minimum work duration required to earn a half-day present | Required. E.g., 120 minutes. Working less than this threshold automatically marks the employee as absent instead of half-day. |
| Absent Threshold (Mins) | Minimum work duration to avoid a complete absent mark | Required. E.g., 15 minutes. Working less than this threshold is counted as zero attendance (Absent). |
| Applicable Days | Days of the week when this shift is active | Selectable checkboxes (Monday through Sunday). At least one day must be selected. |
| Is Active | Status toggle (Yes/No Checkbox) | Required. Inactive shifts cannot be assigned to employees. |

---

## Business Rules & Validation Policies

1. **Net Working Hours Logic:**
   - The system calculates net working hours by deducting the break duration from the total elapsed time between start and end times.
   - *Example:* Start: 09:00 AM, End: 05:00 PM (Total duration = 8 hours). Break: 60 mins (1 hour). Net Working Hours = 7 hours.

2. **Late and Early Out Attendance Calculation:**
   - If an employee's biometric punch time falls outside the shift parameters plus the defined grace period, the system flags the daily attendance record:
     - Shift Start: 08:00 AM, Late Grace: 10 minutes.
     - Punch-in at 08:08 AM -> Present (Within grace period, no penalty).
     - Punch-in at 08:12 AM -> Marked Late (Past grace period, late penalty applies).

3. **Hours-Based Attendance Determination:**
   - Based on biometric check-in and check-out times, the system computes the exact working minutes to determine the attendance status:
     - **Worked Minutes < Absent Threshold (e.g., 15 mins):** Automatically marked as **Absent**.
     - **Worked Minutes >= Absent Threshold but < Half-Day Threshold (e.g., 120 mins):** Automatically marked as **Half-Day**.
     - **Worked Minutes >= Half-Day Threshold but less than full shift hours:** Marked as either **Half-Day** or **Present** based on school policy rules.

---

## Screen Workflows & Operations

### 1. Creating a New Shift Template (Create)
- The Admin clicks the "+ New Shift" button.
- Enters the Shift Code, Name, and sets the Start Time and End Time.
- Specifies the Break Duration in minutes (the system automatically updates the Net Working Hours).
- Defines the late/early grace periods and attendance thresholds.
- Selects the days of the week when this shift is active using the checkboxes.
- Clicks Save to store the template.

### 2. Duplicating a Shift (Copy / Versioning)
- To create a similar shift (e.g., a winter version of a summer shift), the Admin can use the "Duplicate" or "Copy Shift" function.
- This pre-populates all field values into a new form, allowing the Admin to modify the name, code, or timings without entering all data from scratch.

### 3. Deactivating/Archiving a Shift (Delete)
- To maintain historical integrity for attendance reports, shifts cannot be permanently deleted if they have historical data.
- Instead, clicking "Delete" performs a soft-delete (archives the shift), preventing it from being assigned to new employees while preserving historical logs.

---

## Real-World Example Scenario

**School ABC** wants to set up a new shift template for Teachers during the winter season:

1. The Admin opens the "New Shift" form.
2. Enters Code: `W-TCH-26` and Name: `Winter Teacher Shift 2026`.
3. Sets Timings: 08:30 AM to 02:30 PM (Total elapsed time: 6 Hours).
4. Sets Break Duration: `30 minutes` (resulting in Net Working Hours = 5.5 Hours).
5. Sets Grace Late: `10 minutes` (arrivals up to 08:40 AM are allowed without being flagged late).
6. Sets Grace Early Out: `5 minutes` (teachers should not check out before 02:25 PM).
7. Sets Half-Day Threshold: `180 minutes` (3 hours) and Absent Threshold: `15 minutes`.
8. Selects Days: Monday to Friday (5 days).
9. Clicks Save.
10. **System Calculation:** The system displays the weekly workload: 5.5 Net Hours * 5 Days = 27.5 Net Hours/Week. The shift is active and can now be assigned to teachers.
