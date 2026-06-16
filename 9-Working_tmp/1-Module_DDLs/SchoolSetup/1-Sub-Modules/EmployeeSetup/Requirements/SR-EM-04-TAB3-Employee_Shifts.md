# Screen Requirement: Employee Shifts Configuration
## Document ID: SR-EM-04-TAB3
**Module:** SchoolSetup / EmployeeSetup  
**Screen Name:** Employee Shifts (Tab 3 of Attendance Masters)  
**Route:** `school-setup.attendance-master.index?tab=employee-shifts`  
**User Role:** School Administrator, HR Manager  
**Priority:** P0 (Critical)  
**Status:** Approved for Development  

---

## 1. Screen Overview

### 1.1 Purpose & Business Objective
This tab manages shift templates that define working hours, break times, and grace periods for different employee groups. Shifts are assigned to employees on specific dates and control what constitutes a "working day" for attendance and payroll purposes.

### 1.2 Key Capabilities
- ✅ Create shift templates with start/end times
- ✅ Configure break durations and grace periods
- ✅ Define working days (Mon-Sun selection)
- ✅ Calculate net working hours automatically
- ✅ Copy existing shifts for variants
- ✅ Preview affected working days
- ✅ Bulk assign shifts to employees
- ✅ Manage shift history and versioning

---

## 2. Data Model & DDL Reference

### 2.1 Primary Table

#### sch_employee_shifts — Shift Template Master
```sql
sch_employee_shifts
├── Identification: id (INT), code (VARCHAR 20), name (VARCHAR 100)
├── Schedule: start_time (TIME), end_time (TIME)
├── Break: break_duration_minutes (INT) — e.g., 60 = 1 hour
├── Grace Periods: 
│   ├── grace_minutes_late (INT) — e.g., 5 mins late allowed
│   └── grace_minutes_early_departure (INT) — e.g., 5 mins early OK
├── Thresholds:
│   ├── half_day_threshold_minutes (INT) — e.g., work 2+ hrs = half day
│   └── absent_threshold_minutes (INT) — e.g., <15 mins = absent
├── Working Days: applies_to_days_json (JSON array)
│   └── Example: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
├── Calculation: net_working_hours (DECIMAL 5,2) — auto-calculated
├── Description: description (TEXT)
├── Status: is_active (BOOL), deleted_at (TIMESTAMP)
└── Audit: created_by (INT), created_at, updated_at
```

### 2.2 Related Tables
- `sys_users` — For created_by audit
- `sch_employee_shift_assignments` — Links employees to shifts

---

## 3. Screen Layout & UI Components

### 3.1 List View

```
┌─ EMPLOYEE SHIFTS ──────────────────────────────────────┐
│                                                         │
│ [+ New Shift] [Copy Shift] [Export] [Filter]          │
│ Search: [_________] Active: [All ▼]                   │
│                                                         │
├─────────────────────────────────────────────────────────┤
│ Code │ Name     │ Time      │ Break│ Net Hrs│ Days│Act
│─────────────────────────────────────────────────────────│
│ S1   │ Standard │ 9:00-5:00 │ 60m  │ 7.5   │ 5   │ ✓
│ S2   │ Morning  │ 8:00-2:00 │ 30m  │ 5.5   │ 5   │ ✓
│ S3   │ Afternoon│ 2:00-8:00 │ 30m  │ 5.5   │ 5   │ ✓
│ S4   │ Weekend  │ 9:00-5:00 │ 60m  │ 7.5   │ 2   │ ✓
│ S5   │ Flexible │ 8:00-6:00 │ 60m  │ 9.0   │ 5   │ ✓
│                                                         │
└─────────────────────────────────────────────────────────┘
[View Details] [Edit] [View Assignments] [Delete]

Total Shifts: 5 | Active: 5 | Archived: 0
```

### 3.2 Create/Edit Shift Form

#### Section A: Basic Information
```
┌─ SHIFT DETAILS ────────────────────────────────────────┐
│                                                         │
│ Shift Code*         [______] (e.g., S1, S2, S3)       │
│ (3-10 chars, uppercase, unique)                       │
│                                                         │
│ Shift Name*         [________________]                │
│ (e.g., Standard Shift, Morning Shift, Afternoon)      │
│                                                         │
│ Description         [________________________]         │
│ (Optional notes about shift usage)                    │
│                                                         │
│ [Next →]                                             │
└────────────────────────────────────────────────────────┘
```

#### Section B: Working Hours Configuration
```
┌─ WORKING HOURS ────────────────────────────────────────┐
│                                                         │
│ Start Time*         [09:00] (HH:MM format)            │
│ End Time*           [17:00] (HH:MM format)            │
│                                                         │
│ Total Hours:        8.0 hours (calculated)            │
│                                                         │
│ Break Duration*     [___] minutes (e.g., 60)         │
│ (Lunch/tea break deducted from working hours)         │
│                                                         │
│ Net Working Hours:  7.5 hours (8.0 - 1.0 break)      │
│                                                         │
│ FORMULA:                                              │
│ Net Hours = (End Time - Start Time) - Break Minutes   │
│ 17:00 - 09:00 = 8 hours - 60 min break = 7.5 hours   │
│                                                         │
│ [Next →]                                             │
└────────────────────────────────────────────────────────┘
```

#### Section C: Grace Periods & Thresholds
```
┌─ GRACE PERIODS & THRESHOLDS ───────────────────────────┐
│                                                         │
│ Grace Period (Late Arrival)*  [___] minutes (e.g., 5) │
│ → Employee can be up to 5 mins late without penalty   │
│                                                         │
│ Grace Period (Early Departure)* [___] minutes (e.g., 5)│
│ → Employee can leave up to 5 mins early without issue │
│                                                         │
│ Half-Day Threshold*           [___] minutes (e.g., 120)│
│ → Work 120+ mins = Half day; <120 mins = Absent      │
│                                                         │
│ Absent Threshold*             [___] minutes (e.g., 15) │
│ → Work <15 mins = Absent (regardless of threshold)   │
│                                                         │
│ EXAMPLE: If thresholds are (120 min half-day, 15 min │
│ absent):                                              │
│ • Worked 0 mins     → Absent                          │
│ • Worked 10 mins    → Absent                          │
│ • Worked 100 mins   → Half-Day                        │
│ • Worked 150 mins   → Present (Full day)             │
│                                                         │
│ [Next →]                                             │
└────────────────────────────────────────────────────────┘
```

#### Section D: Working Days Selection
```
┌─ APPLICABLE WORKING DAYS ──────────────────────────────┐
│                                                         │
│ Select Days:                                          │
│ [✓] Monday     [✓] Tuesday    [✓] Wednesday          │
│ [✓] Thursday   [✓] Friday     [ ] Saturday           │
│ [ ] Sunday                                            │
│                                                         │
│ Days Applicable: 5 days/week                          │
│ Working Hours/Week: 37.5 hours                        │
│                                                         │
│ EXAMPLE:                                              │
│ • Standard: Mon-Fri (5 days) → 37.5 hrs/week        │
│ • Weekend Shift: Sat-Sun (2 days) → 15 hrs/week      │
│ • 6-day: Mon-Sat (6 days) → 45 hrs/week             │
│                                                         │
│ [Next →]                                             │
└────────────────────────────────────────────────────────┘
```

#### Section E: Review & Save
```
┌─ SHIFT SUMMARY ────────────────────────────────────────┐
│                                                         │
│ Shift Code:      S1                                   │
│ Name:            Standard Shift                       │
│ Time:            09:00 - 17:00 (8 hours)             │
│ Break:           60 minutes                          │
│ Net Hours:       7.5 hours/day                        │
│ Working Days:    Monday - Friday (5 days/week)       │
│ Weekly Hours:    37.5 hours                          │
│ Grace (Late):    5 minutes                           │
│ Grace (Early):   5 minutes                           │
│ Half-Day Min:    120 minutes                         │
│                                                         │
│ [✓] Is Active    [← Back] [Save]                    │
└────────────────────────────────────────────────────────┘
```

---

## 4. Input Validation Rules

### 4.1 Field Validations

| Field | Type | Validation Rule | Error Message |
|-------|------|-----------------|----------------|
| Code | String | Required, 3-10 chars, unique, uppercase | Code must be 3-10 uppercase chars |
| Name | String | Required, 1-100 chars | Name is required |
| Start Time | Time | Required, valid HH:MM format | Valid time required |
| End Time | Time | Required, > Start Time | End time must be after start time |
| Break Duration | Integer | Required, 0-480 (8 hours) | Break must be 0-480 minutes |
| Grace Late | Integer | Required, 0-60 | Must be 0-60 minutes |
| Grace Early | Integer | Required, 0-60 | Must be 0-60 minutes |
| Half-Day Min | Integer | Required, 30-480 | Must be 30-480 minutes |
| Absent Min | Integer | Required, 0-240 | Must be 0-240 minutes |
| Working Days | Array | Required, 1-7 days selected | Select at least one working day |
| Is Active | Boolean | Required | Must specify status |

### 4.2 Cross-Field Validations

| Condition | Validation | Action |
|-----------|-----------|--------|
| Break ≥ (End - Start) | Error | "Break cannot be ≥ working hours" |
| Half-Day Min > Net Hours | Warning | "Half-day threshold > working hours" |
| Absent Min > Half-Day Min | Error | "Absent min cannot exceed half-day min" |
| No working days selected | Error | "Select at least one working day" |
| Grace periods > 60 | Warning | "Grace >60 mins is unusual" |
| Net Hours < 4 hours | Warning | "Very short working hours" |

---

## 5. Business Logic & Calculations

### 5.1 Net Working Hours Calculation

```
Net Working Hours = (End Time - Start Time) - Break Duration

Example 1: Standard 9-5 with 1 hour break
  End: 17:00, Start: 09:00 = 8 hours
  Break: 60 minutes = 1 hour
  Net = 8 - 1 = 7.5 hours/day

Example 2: Morning shift 8am-2pm with 30 min break
  End: 14:00, Start: 08:00 = 6 hours
  Break: 30 minutes = 0.5 hours
  Net = 6 - 0.5 = 5.5 hours/day

Example 3: Flexible 8am-6pm with 1 hour break
  End: 18:00, Start: 08:00 = 10 hours
  Break: 60 minutes = 1 hour
  Net = 10 - 1 = 9.0 hours/day
```

### 5.2 Weekly Working Hours Calculation

```
Weekly Hours = Net Daily Hours × Number of Working Days

Example: Standard Shift (7.5 hrs/day, 5 days/week)
  Weekly = 7.5 × 5 = 37.5 hours/week

Example: Weekend Shift (7.5 hrs/day, 2 days/week)
  Weekly = 7.5 × 2 = 15 hours/week

Example: 6-Day Shift (7.5 hrs/day, 6 days/week)
  Weekly = 7.5 × 6 = 45 hours/week
```

### 5.3 Shift Behavior Rules

#### Grace Period Logic
```
Late Arrival Grace:
  IF (login_time - shift_start_time) ≤ grace_minutes_late
    → Mark as Present (no penalty)
  ELSE
    → Mark as Late (may have payroll impact)

Early Departure Grace:
  IF (shift_end_time - logout_time) ≤ grace_minutes_early
    → Mark as Present (no penalty)
  ELSE
    → Mark as Early Departure (may have payroll impact)
```

#### Attendance Status Logic
```
Worked Minutes < Absent Threshold
  → Mark as ABSENT (regardless of other rules)

Worked Minutes ≥ Absent Threshold AND < Half-Day Min
  → Mark as HALF-DAY

Worked Minutes ≥ Half-Day Min
  → Mark as PRESENT (Full Day)

EXAMPLE: Thresholds = (Absent: 15 min, Half-Day: 120 min)
• Worked 0 min     → ABSENT
• Worked 10 min    → ABSENT
• Worked 30 min    → HALF-DAY
• Worked 150 min   → PRESENT
```

### 5.4 JSON Format for Working Days

```json
{
  "applies_to_days": [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday"
  ]
}

OR for weekend shift:
{
  "applies_to_days": [
    "Saturday",
    "Sunday"
  ]
}

OR for 6-day week:
{
  "applies_to_days": [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday"
  ]
}
```

---

## 6. Database Operations

### 6.1 Create Shift
```sql
INSERT INTO sch_employee_shifts (
    code, name, description,
    start_time, end_time, break_duration_minutes,
    grace_minutes_late, grace_minutes_early_departure,
    half_day_threshold_minutes, absent_threshold_minutes,
    applies_to_days_json, net_working_hours,
    is_active, created_by
) VALUES (
    ?, ?, ?,
    ?, ?, ?,
    ?, ?,
    ?, ?,
    ?, TIMEDIFF(?, ?) - INTERVAL ? MINUTE,
    1, ?
);
```

### 6.2 Calculate Net Working Hours Trigger
```sql
BEFORE INSERT ON sch_employee_shifts
FOR EACH ROW
SET NEW.net_working_hours = 
    (HOUR(TIMEDIFF(NEW.end_time, NEW.start_time)) +
     MINUTE(TIMEDIFF(NEW.end_time, NEW.start_time))/60) -
    (NEW.break_duration_minutes / 60);
```

### 6.3 Get Shift Detail with Calculations
```sql
SELECT 
    id, code, name, start_time, end_time,
    break_duration_minutes, net_working_hours,
    grace_minutes_late, grace_minutes_early_departure,
    half_day_threshold_minutes, absent_threshold_minutes,
    JSON_UNQUOTE(JSON_EXTRACT(applies_to_days_json, '$[*]')) as working_days,
    JSON_LENGTH(applies_to_days_json) as days_per_week,
    net_working_hours * JSON_LENGTH(applies_to_days_json) as weekly_hours,
    is_active
FROM sch_employee_shifts
WHERE id = ? AND deleted_at IS NULL;
```

---



## 8. Permissions & Authorization

| Permission | Admin | HR Mgr | Manager | Employee |
|-----------|-------|--------|---------|----------|
| view.shift.list | ✓ | ✓ | ✓ | ✓ |
| create.shift | ✓ | ✓ | ✗ | ✗ |
| edit.shift | ✓ | ✓ | ✗ | ✗ |
| delete.shift | ✓ | ✗ | ✗ | ✗ |
| view.shift.detail | ✓ | ✓ | ✓ | ✓ |

---

## 9. Error Handling

| Error Code | HTTP | Message | Cause | Action |
|-----------|------|---------|-------|--------|
| SHIFT-001 | 400 | Shift code already exists | Duplicate | Use unique code |
| SHIFT-002 | 400 | End time must be after start time | Invalid time | Correct times |
| SHIFT-003 | 400 | Break cannot exceed working hours | Invalid break | Reduce break |
| SHIFT-004 | 400 | Select at least one working day | No days | Select days |
| SHIFT-005 | 409 | Cannot delete; active assignments exist | In use | Archive instead |
| SHIFT-006 | 400 | Invalid time format | Bad format | Use HH:MM |

---

## 10. Testing Checklist

- [ ] Create shift with working hours calculation
- [ ] Test various time combinations
- [ ] Verify net hours calculation
- [ ] Test working day selection
- [ ] Calculate weekly/monthly hours
- [ ] Test grace period logic
- [ ] Verify half-day threshold
- [ ] Test absent threshold
- [ ] Create multiple shifts
- [ ] Copy existing shift

---

**Next Steps:** 
- Implement shift CRUD
- Build time picker UI
- Calculate net working hours
- Test shift assignment
- Implement shift history

