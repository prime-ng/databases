# Screen Requirement: Employee Attendance Management
## Document ID: SR-EM-12
**Module:** SchoolSetup / EmployeeSetup  
**Screen Name:** Employee Attendance Management  
**Route:** `school-setup.employee-attendance.index`  
**User Role:** School Administrator, HR Manager, Reporting Manager, Employee (self)  
**Priority:** P0 (Critical)  
**Status:** Approved for Development  

---

## 1. Screen Overview

### 1.1 Purpose & Business Objective
This screen enables daily marking, tracking, and management of employee attendance. It supports multiple attendance types (Present, Absent, Late, Half-Day, On Leave, Holiday), integrates with configured shifts for grace period validation, and calculates payroll-relevant statistics.

### 1.2 Key Capabilities
- ✅ Mark daily attendance for employees (bulk and individual)
- ✅ Configure attendance types with payroll impact
- ✅ Automatic half-day detection based on shift grace periods
- ✅ Manual correction requests with approval workflow
- ✅ Employee self-service attendance view (view-only)
- ✅ Attendance reports and statistics
- ✅ Punch-time integration (if biometric device connected)
- ✅ Monthly/weekly summary dashboards

---

## 2. Data Model & DDL References

### 2.1 Primary Tables
```sql
sch_employee_attendance — Daily attendance records
├── Identification: employee_id, attendance_date (composite unique)
├── Status: attendance_type_id (FK), is_half_day, mark_type (manual/device)
├── Timing: check_in_time, check_out_time, total_hours_worked
├── Workflow: correction_status, correction_approved_by, correction_reason
├── Calculation: effective_hours, payroll_percentage_applied
└── Audit: marked_by, marked_at, updated_by, updated_at

sch_employee_punches — Raw punch data from devices
├── Employee: employee_id
├── Time: punch_datetime, punch_type (IN/OUT)
├── Device: device_id, device_location
└── Sync: sync_status, synced_at

sch_employee_attendance_corrections — Correction request log
├── Original: original_date, original_type_id
├── Requested: requested_type_id, requested_reason
├── Workflow: status (pending/approved/rejected), approved_by, approved_at
└── Audit: requested_by, requested_at, decision_remarks
```

### 2.2 Related Tables
- `sch_staff_attendance_types` — Attendance type master (FK: attendance_type_id)
- `sch_employees` — Employee master (FK: employee_id)
- `sch_employee_shift_assignments` — Active shift for grace period calculation
- `sch_holidays` — Holiday calendar (for auto-marking holidays)
- `sch_staff_leave_applications` — Approved leaves (for auto-marking leave)

---

## 3. Screen Layout & UI Components

### 3.1 Page Structure: Dashboard + Actions

```
┌─ Employee Attendance Management ──────────────────────────────┐
│                                                                  │
│  [+ Mark Attendance] [Bulk Mark] [Import Punches] [Export]    │
│                                                                  │
│  📊 Dashboard: Today: 45 Present | 2 Absent | 3 Late | 1 On Leave │
│                                                                  │
│  Date: [▼ 16/05/2026]  Department: [▼ All ▼]  Status: [All ▼] │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│  TAB 1: DAILY ATTENDANCE MARKING                                │
│  ┌─────────────────────────────────────────────────────────────┐
│  │ Emp ID │ Name      │ Dept   │ Shift │ In Time │ Status    │
│  │ 001    │ John Doe  │ Science│ Mor   │ 08:05   │ Present   │
│  │ 002    │ Jane Smith│ Maths  │ Mor   │ 08:12   │ Late (7m) │
│  │ 003    │ Mike Brown│ English│ Aft   │ --      │ Absent    │
│  │ 004    │ Sarah Lee │ Science│ --    │ 14:00   │ On Leave  │
│  └─────────────────────────────────────────────────────────────┘
│  [Mark Present] [Mark Absent] [Mark Leave] [Mark Late] [Edit]  │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│  TAB 2: ATTENDANCE REGISTER (Monthly View)                      │
│  Month: [▼ May 2026 ▼]  Employee: [Search...]                  │
│  ┌─────────────────────────────────────────────────────────────┐
│  │ Employee │ 01 │ 02 │ 03 │ ... │ 31 │ Total P │ Total A │%
│  │ John Doe │ P  │ P  │ P  │ ... │ P  │   15    │   0    │100%
│  │ Jane S.  │ P  │ L  │ P  │ ... │ A  │   13    │   2    │ 86%
│  └─────────────────────────────────────────────────────────────┘
│  Legend: P=Present, A=Absent, L=Late, H=Holiday, HD=Half-Day  │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│  TAB 3: CORRECTION REQUESTS                                     │
│  ┌─────────────────────────────────────────────────────────────┐
│  │ Date   │ Employee │ From  │ To    │ Reason    │ Status    │
│  │ 14/05  │ John D.  │ Absent│ Present│ Medical   │ Pending   │
│  │ 15/05  │ Jane S.  │ Late  │ Present│ Car issue │ Approved  │
│  └─────────────────────────────────────────────────────────────┘
│  [Approve] [Reject] [View Details]                              │
│                                                                  │
├─────────────────────────────────────────────────────────────────┤
│  TAB 4: PUNCH TIMELINE (Device Integration)                    │
│  Employee: [▼ Select]  Date: [16/05/2026]                      │
│  ┌─────────────────────────────────────────────────────────────┐
│  │ Time     │ Type │ Device    │ Location                      │
│  │ 08:02:15 │ IN   │ DEV-001   │ Main Gate                     │
│  │ 13:05:30 │ OUT  │ DEV-001   │ Main Gate                     │
│  │ 13:55:10 │ IN   │ DEV-001   │ Main Gate                     │
│  │ 17:30:45 │ OUT  │ DEV-001   │ Main Gate                     │
│  └─────────────────────────────────────────────────────────────┘
│  [Manual Add Punch] [Sync Devices]                               │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 Mark Attendance Modal (Single Employee)

```
┌─ MARK ATTENDANCE ──────────────────────────────────────────────┐
│                                                                      │
│  Employee*          [▼ Search: John...]                            │
│  (Selected: John Doe - Science Dept)                               │
│                                                                      │
│  Date*             [16/05/2026]                                   │
│                                                                      │
│  Attendance Type* (•) Present                                     │
│                     ( ) Absent                                    │
│                     ( ) Late                                      │
│                     ( ) Half-Day (AM)                             │
│                     ( ) Half-Day (PM)                             │
│                     ( ) On Leave                                   │
│                     ( ) Holiday (Auto-detected)                   │
│                                                                      │
│  Check-in Time     [08:05] (Auto-populated from punch)            │
│  Check-out Time    [17:00]                                         │
│                                                                      │
│  Notes             [_______________________________]              │
│                                                                      │
│  [Cancel] [Mark Attendance]                                       │
└────────────────────────────────────────────────────────────────────┘
```

### 3.3 Bulk Attendance Marking

```
┌─ BULK ATTENDANCE MARKING ────────────────────────────────────────┐
│                                                                      │
│  Date*             [16/05/2026]                                   │
│                                                                      │
│  Department        [▼ Select Department]                          │
│  (All employees in selected dept will be marked)                  │
│                                                                      │
│  OR Select Employees:                                              │
│  [□] John Doe (Science)                                            │
│  [□] Jane Smith (Maths)                                            │
│  [□] Mike Johnson (English)                                        │
│  ...                                                               │
│                                                                      │
│  Attendance Type* (•) Present                                      │
│                     ( ) Absent                                    │
│                     ( ) Late                                      │
│                                                                      │
│  Include in Punch   [✓] Mark employees with no punch as absent   │
│                                                                      │
│  Total Selected: 3 employees                                        │
│                                                                      │
│  [Cancel] [Mark Bulk Attendance]                                   │
└────────────────────────────────────────────────────────────────────┘
```

### 3.4 Correction Request Form

```
┌─ ATTENDANCE CORRECTION REQUEST ───────────────────────────────────┐
│                                                                      │
│  Employee          John Doe                                       │
│  Current Attendance: Absent (on 14/05/2026)                       │
│                                                                      │
│  Requested Type*   ( ) Present                                    │
│                     (•) On Leave (SL)                             │
│                                                                      │
│  Supporting Document [Upload Medical Certificate]                 │
│  (Required if leave > 2 days)                                      │
│                                                                      │
│  Reason*           [Doctor appointment - medical emergency]       │
│                                                                      │
│  [Cancel] [Submit Request]                                         │
└────────────────────────────────────────────────────────────────────┘
```

---

## 4. Input Validation Rules

### 4.1 Daily Attendance Validations

| Field | Type | Validation Rule | Error Message |
|-------|------|-----------------|----------------|
| Employee | FK | Required, must exist, is_active=1 | Employee must be selected and active |
| Date | Date | Required, valid date, <= TODAY | Date is required and cannot be future |
| Attendance Type | FK | Required, must exist, is_active=1 | Attendance type must be selected |
| Check-in Time | Time | Optional, valid time format | Time must be in HH:MM:SS format |
| Check-out Time | Time | Optional, must be > check-in if provided | End time must be after start time |
| Mark Type | Enum | Required (Manual/Device/Import) | Mark type is required |
| Notes | Text | Optional, max 500 chars | Notes must not exceed 500 chars |

### 4.2 Correction Request Validations

| Field | Type | Validation Rule | Error Message |
|-------|------|-----------------|----------------|
| Original Date | Date | Required, valid past date | Original date is required |
| Requested Type | FK | Required, must differ from original | Must select different type |
| Reason | String | Required, 10-500 chars | Reason is required (10-500 chars) |
| Supporting Doc | File | Optional (required if leave > configured days) | Document required |
| Duplicate Check | Composite | Cannot submit if already pending for same date | Correction already pending |

### 4.3 Cross-Field Validations

| Condition | Validation | Action |
|-----------|-----------|--------|
| Punch times within shift grace | Auto-detect Late status | If in_time > shift.start_time + grace_minutes_late → Mark Late |
| Punch missing | Configurable | If "mark absent on no punch" enabled → auto-mark absent |
| Leave approved for date | Auto-mark leave | Check sch_employee_leave_applications, auto-set leave type |
| Holiday for date | Auto-mark holiday | Check sch_holidays, auto-set holiday type |
| Half-day threshold | Calculate | If total_hours < shift.half_day_threshold → Suggest Half-Day |
| Same date attendance exists | Error raised | Cannot mark twice for same date; must use correction |

---

## 5. Business Logic & Calculations

### 5.1 Automatic Status Detection

#### Grace Period Late Detection
```
FUNCTION: Detect_Attendance_Status(employee_id, check_in_time, shift)
    
    IF shift IS NULL:
        RETURN: "Present" (no shift assigned)
    
    late_threshold = shift.start_time + shift.grace_minutes_late
    early_threshold = shift.end_time - shift.grace_minutes_early
    
    IF check_in_time > late_threshold:
        RETURN: "Late" (within grace minutes)
    ELSE IF check_in_time <= late_threshold:
        RETURN: "Present"
    
    IF check_out_time IS NOT NULL:
        IF check_out_time < early_threshold:
            RETURN: "Early Leave" (within grace minutes)
    
    RETURN: "Present"
```

#### Half-Day Auto-Suggestion
```
FUNCTION: Suggest_Half_Day(check_in, check_out, shift)
    
    IF shift IS NULL:
        RETURN: false
    
    total_minutes = (check_out - check_in) - shift.break_duration_minutes
    
    IF total_minutes < shift.half_day_threshold_minutes:
        RETURN: true  (suggest half-day)
    
    RETURN: false
```

### 5.2 Payroll Percentage Calculation

```
FUNCTION: Calculate_Payroll_Percentage(attendance_type, is_half_day)
    
    base_percentage = attendance_type.payroll_percentage
    
    IF is_half_day = true AND attendance_type.can_be_half_day = true:
        payroll_percentage = base_percentage * 0.5
    ELSE:
        payroll_percentage = base_percentage
    
    RETURN: payroll_percentage
```

**Example:**
| Attendance Type | Payroll % | Half-Day % | Notes |
|----------------|-----------|------------|-------|
| Present | 100% | 50% | Full day = 100%, Half = 50% |
| Absent | 0% | 0% | No pay |
| Late | 100% | 50% | Still paid full (within grace) |
| On Leave (Paid) | 100% | 50% | As per leave type |
| Holiday | 100% | N/A | If is_paid=true |

### 5.3 Attendance Summary Calculations

#### Monthly Summary
```
FOR each employee IN month:
    present_count = COUNT WHERE attendance_type.category = 'Attendance' 
                                  AND is_present = true
    absent_count = COUNT WHERE attendance_type.category = 'Attendance'
                                  AND is_present = false
    leave_count = COUNT WHERE attendance_type.category = 'Leave'
    late_count = COUNT WHERE attendance_type = 'Late'
    
    attendance_percentage = (present_count / total_working_days) * 100
    
    STORE: {employee_id, present_count, absent_count, leave_count, 
             late_count, attendance_percentage}
```

### 5.4 Default Values
- `marked_by` = current_user_id
- `marked_at` = CURRENT_TIMESTAMP
- `mark_type` = 'Manual' (default)
- `is_half_day` = false (default)
- `correction_status` = NULL (no correction pending)

---

## 6. State Transitions & Workflows

### 6.1 Attendance Marking States
```
┌─────────────┐
│   PENDING   │ (Marked but not processed for payroll)
└──────┬──────┘
       │ (End of day / payroll cutoff)
       ▼
┌─────────────┐
│  PROCESSED  │ (Included in payroll calculation)
└──────┬──────┘
       │
       ├─[Correction]──► PENDING_CORRECTION
       │
       └─[Month Close]──► LOCKED (No more changes allowed)
```

### 6.2 Correction Workflow
```
┌─────────────┐
│   PENDING   │ (Correction submitted by employee/manager)
└──────┬──────┘
       │ (HR/Admin reviews)
       ▼
┌──────────────┐
│   APPROVED   │───► Original attendance updated
│              │     Payroll recalculated (if within window)
└──────────────┘

OR

┌──────────────┐
│   REJECTED   │───► Original attendance unchanged
│              │     Employee notified of rejection
└──────────────┘
```

### 6.3 Punch Processing States
```
┌─────────────┐
│   RECEIVED  │ (Raw punch data received)
└──────┬──────┘
       │ (System processes)
       ▼
┌─────────────┐
│   MATCHED   │ (Paired IN/OUT for same employee same day)
└──────┬──────┘
       │ (Attendance calculated)
       ▼
┌─────────────┐
│   CONFLICT  │ (Multiple punches, requires manual review)
└─────────────┘
```

---

## 7. Database Operations

### 7.1 Mark Daily Attendance
```sql
INSERT INTO sch_employee_attendance (
    employee_id, attendance_date, attendance_type_id,
    is_half_day, check_in_time, check_out_time,
    total_hours_worked, payroll_percentage_applied,
    mark_type, marked_by, marked_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'Manual', ?, NOW());
```

### 7.2 Bulk Mark Attendance
```sql
INSERT INTO sch_employee_attendance (
    employee_id, attendance_date, attendance_type_id,
    is_half_day, mark_type, marked_by, marked_at
)
SELECT e.id, ?, ?, 0, 'Bulk', ?, NOW()
FROM sch_employees e
WHERE e.department_id = ? AND e.is_active = 1
  AND e.id NOT IN (
      SELECT employee_id FROM sch_employee_attendance 
      WHERE attendance_date = ?
  );
```

### 7.3 Submit Correction Request
```sql
INSERT INTO sch_employee_attendance_corrections (
    employee_id, original_date, original_type_id,
    requested_type_id, requested_reason, requested_by, requested_at
) VALUES (?, ?, ?, ?, ?, ?, NOW());

UPDATE sch_employee_attendance 
SET correction_status = 'pending', updated_by = ?
WHERE employee_id = ? AND attendance_date = ?;
```

### 7.4 Approve Correction
```sql
UPDATE sch_employee_attendance 
SET attendance_type_id = ?, 
    correction_status = 'approved',
    correction_approved_by = ?,
    updated_by = ?,
    updated_at = NOW()
WHERE employee_id = ? AND attendance_date = ?;

UPDATE sch_employee_attendance_corrections 
SET status = 'approved', 
    approved_by = ?,
    approved_at = NOW(),
    decision_remarks = ?
WHERE employee_id = ? AND original_date = ?;
```

---



## 9. Permissions & Authorization

### 9.1 Role-Based Permissions

| Permission | Admin | HR Mgr | Manager | Employee |
|-----------|-------|--------|---------|----------|
| view.attendance.list | ✓ | ✓ | ✓ (own dept) | ✓ (self) |
| view.attendance.details | ✓ | ✓ | ✓ (own dept) | ✓ (self) |
| create.attendance | ✓ | ✓ | ✓ (own dept) | ✗ |
| edit.attendance (same day) | ✓ | ✓ | ✓ (own dept) | ✗ |
| submit.correction | ✓ | ✓ | ✓ | ✓ (self) |
| approve.correction | ✓ | ✓ | ✗ | ✗ |
| view.punches | ✓ | ✓ | ✓ | ✓ (self) |
| import.punches | ✓ | ✓ | ✗ | ✗ |
| export.attendance | ✓ | ✓ | ✓ | ✗ |

### 9.2 Approval Hierarchy for Corrections
- **Employee →** Request correction (self only)
- **Manager →** Approve if same department (for their reports)
- **HR Manager →** Approve any correction
- **Admin →** Override any decision

---

## 10. Error Handling

### 10.1 Common Error Scenarios

| Error Code | HTTP | Message | Cause | Action |
|-----------|------|---------|-------|--------|
| ATT-001 | 400 | Attendance already marked for this date | Duplicate entry | Use edit or correction |
| ATT-002 | 400 | Cannot mark attendance for future date | Invalid date | Use valid past/current date |
| ATT-003 | 400 | Employee not found | Invalid employee ID | Select valid employee |
| ATT-004 | 400 | Half-day not allowed for this type | Type configuration | Select allowed type |
| ATT-005 | 409 | Correction already pending | Duplicate request | Wait for resolution |
| ATT-006 | 422 | Validation failed | Multiple errors | Fix validation errors |
| ATT-007 | 403 | Permission denied | Unauthorized access | Contact administrator |
| ATT-008 | 423 | Month locked for editing | Payroll closed | Contact HR to unlock |

### 10.2 Warning Scenarios
- **No shift assigned** → Show warning, allow marking with default 100% payroll
- **Punch time outside shift hours** → Show warning, allow override
- **Leave approved for same date** → Show info, pre-select leave type

---

## 11. Performance Considerations

### 11.1 Indexing Strategy
```sql
CREATE INDEX idx_attendance_emp_date ON sch_employee_attendance(employee_id, attendance_date);
CREATE INDEX idx_attendance_date ON sch_employee_attendance(attendance_date);
CREATE INDEX idx_attendance_type ON sch_employee_attendance(attendance_type_id);
CREATE INDEX idx_attendance_month ON sch_employee_attendance(employee_id, attendance_date);
CREATE INDEX idx_correction_status ON sch_employee_attendance_corrections(status);
CREATE INDEX idx_punch_employee ON sch_employee_punches(employee_id, punch_datetime);
```

### 11.2 Query Optimization
- Use covering index for daily attendance queries
- Pre-calculate monthly summaries and cache
- Batch process bulk operations
- Use database cursor for large exports

### 11.3 Caching Strategy
- Daily attendance summary: Cache 5 minutes
- Monthly register: Cache 1 hour
- Employee shift info: Cache 1 hour

---

## 12. Integration Points

### 12.1 Dependent Screens
- **SR-EM-04 (Attendance Masters):** Uses attendance type configurations
- **SR-EM-03 (Shift Assignment):** Uses shift for grace period calculation
- **SR-EM-08 (Leave Applications):** Auto-marks approved leaves
- **Payroll System:** Uses attendance and payroll_percentage
- **SmartTimetable:** Syncs with teacher schedules

### 12.2 Device Integration (Future)
- Biometric device connectivity
- RFID card readers
- Geo-fenced mobile attendance

### 12.3 Notification Events
- Attendance marked → Notify employee (optional)
- Correction pending → Notify approver
- Correction approved/rejected → Notify employee
- Monthly summary → Email to HR/Admin

---

## 13. Testing Checklist

- [ ] Mark individual attendance with all types
- [ ] Bulk mark attendance by department
- [ ] Auto-detect Late based on shift grace period
- [ ] Auto-detect Half-Day based on hours worked
- [ ] Auto-mark holidays from calendar
- [ ] Auto-mark leave from approved applications
- [ ] Submit and approve correction request
- [ ] Reject correction with reason
- [ ] View monthly attendance register
- [ ] Export attendance report
- [ ] Permission-based view filtering
- [ ] Test punch time integration (if available)
- [ ] Verify payroll percentage calculation
- [ ] Test half-day payroll calculation

---

**Next Steps:** 
- Implement daily attendance marking UI
- Build bulk marking functionality
- Create correction workflow
- Add monthly register view
- Integrate with shift management
- Connect with payroll system for salary calculation
- Implement punch device sync (future phase)