# Screen Requirement: Shift Assignment & Management
## Document ID: SR-EM-03
**Module:** SchoolSetup / EmployeeSetup  
**Screen Name:** Employee Shift Assignment  
**Route:** `school-setup.shift-assignment.index`  
**User Role:** School Administrator, HR Manager  
**Priority:** P1 (High)  
**Status:** Approved for Development  

---

## 1. Screen Overview

### 1.1 Purpose & Business Objective
This screen enables administrators to define shift templates (working hour schedules) and assign active shifts to employees with effective date ranges. It supports flexible work schedules including morning/afternoon/full-day shifts with configurable grace periods for late arrivals and early departures.

### 1.2 Key Capabilities
- ✅ Create and manage shift master templates
- ✅ Define working hours, breaks, and grace periods
- ✅ Assign shifts to employees with effective date ranges
- ✅ Ensure only one active shift per employee (database constraint)
- ✅ View shift history and active assignments
- ✅ Bulk assign shifts to multiple employees
- ✅ Support shift-specific holiday exclusions

---

## 2. Data Model & DDL References

### 2.1 Primary Tables
```sql
sch_employee_shifts — Shift master template
├── Code: VARCHAR(20) — e.g., 'MORNING', 'AFTERNOON', 'FULL_DAY'
├── Working Hours: start_time, end_time, break_duration_minutes
├── Grace Periods: grace_minutes_late, grace_minutes_early
├── Half-Day Threshold: half_day_threshold_minutes
└── Configuration: applies_to_days (JSON), is_default

sch_employee_shift_assignments — Employee ↔ Shift mapping
├── Employee: employee_id (FK)
├── Shift: shift_id (FK)
├── Effective Range: effective_from, effective_to
└── Status: is_active, active_flag (generated column)
```

### 2.2 Related Tables
- `sch_employees` — Employee master (FK: employee_id)
- `sch_holidays` — Holiday calendar (for shift exclusions)

---

## 3. Screen Layout & UI Components

### 3.1 Page Structure: Tabbed Interface

```
┌─ Shift Management ──────────────────────────────────┐
│                                                      │
│  [+ New Shift] [+ Bulk Assign] [View History]      │
│                                                      │
├──────────────────────────────────────────────────────┤
│  TAB 1: SHIFT MASTER (Configuration)                 │
│  ┌────────────────────────────────────────────────┐ │
│  │ Shift Code │ Name │ Start │ End │ Break │ Active│
│  │ MORNING    │ M... │ 08:00│ 14:00│ 60 min │  ✓  │
│  │ AFTERNOON  │ A... │ 14:00│ 20:00│ 30 min │  ✓  │
│  │ FULL_DAY   │ F... │ 08:00│ 17:00│ 60 min │  ✓  │
│  └────────────────────────────────────────────────┘
│  [Edit] [Delete] [View Details]
│
├──────────────────────────────────────────────────────┤
│  TAB 2: SHIFT ASSIGNMENTS (Effective)                │
│  Search: [_________] Dept: [▼] Status: [▼]         │
│  ┌────────────────────────────────────────────────┐ │
│  │ Employee │ Shift │ From Date │ To Date │ Active │
│  │ John Doe │ Morning│01/01/26 │    -    │  ✓   │
│  │ Jane Smith│Afternoon│01/06/25│31/03/26│  ✓   │
│  └────────────────────────────────────────────────┘
│  [View History] [Change Shift] [End Assignment]
│
├──────────────────────────────────────────────────────┤
│  TAB 3: SHIFT HISTORY (Archive)                      │
│  [Inactive assignments with dates]                  │
└──────────────────────────────────────────────────────┘
```

### 3.2 Shift Master Form (Create/Edit)

#### Section A: Basic Configuration
```
┌─ SHIFT DETAILS ─────────────────────────────┐
│                                              │
│  Shift Code*        [_____________]         │
│  Shift Name*        [_____________]         │
│  Description        [________________]      │
│                                              │
│  [Cancel] [Save & Continue]                 │
└──────────────────────────────────────────────┘
```

#### Section B: Time Configuration
```
┌─ WORKING HOURS & BREAKS ────────────────────┐
│                                              │
│  Start Time*        [HH:MM ▼]               │
│  End Time*          [HH:MM ▼]               │
│  Net Working Hours  [___] hours (auto)      │
│                                              │
│  Break Duration*    [___] minutes           │
│  (Grace: 10 min late, 10 min early)         │
│                                              │
│  Grace Minutes Late*       [___] minutes    │
│  (Beyond this = Half-day)                   │
│                                              │
│  Grace Minutes Early*      [___] minutes    │
│  (Leaving before = Half-day)                │
│                                              │
│  Half-Day Threshold*       [___] minutes    │
│  (If present < this = half-day mark)        │
│                                              │
│  [Save]                                      │
└──────────────────────────────────────────────┘
```

#### Section C: Applicability
```
┌─ APPLICABLE DAYS ───────────────────────────┐
│                                              │
│  Applies to Days* (Select):                 │
│  [✓] Monday    [✓] Tuesday   [✓] Wednesday │
│  [✓] Thursday  [✓] Friday    [ ] Saturday  │
│  [ ] Sunday                                 │
│                                              │
│  ( ) All Days (Leave empty for all days)   │
│  (✓) Specific Days (Check above)           │
│                                              │
│  Is Default Shift  [ ] Yes  [✓] No         │
│                                              │
│  [Save]                                      │
└──────────────────────────────────────────────┘
```

### 3.3 Shift Assignment Form (Create/Edit)

#### Section A: Employee & Shift Selection
```
┌─ SHIFT ASSIGNMENT ──────────────────────────┐
│                                              │
│  Employee*          [▼ Search: John...]    │
│  Selected: John Doe (Dept: Science)        │
│                                              │
│  Shift*             [▼ Select Shift]        │
│  Description: 08:00 - 14:00 (6 hrs)        │
│                                              │
│  [Next →]                                   │
└──────────────────────────────────────────────┘
```

#### Section B: Effective Date Range
```
┌─ EFFECTIVE DATE RANGE ──────────────────────┐
│                                              │
│  Effective From*    [__/__/____]            │
│  (Start date for this shift)                │
│                                              │
│  Effective To       [__/__/____]            │
│  (Leave blank if ongoing)                   │
│                                              │
│  Assignment Reason  [________________]      │
│  (e.g., "Based on duty requirement")       │
│                                              │
│  ⚠️ Warning: Employee has existing shift:  │
│     Afternoon (01/06/25 - 31/03/26)        │
│     This assignment will end the previous  │
│                                              │
│  [← Back] [Save]                            │
└──────────────────────────────────────────────┘
```

### 3.4 Bulk Shift Assignment Modal

```
┌─ BULK SHIFT ASSIGNMENT ─────────────────────┐
│                                              │
│  Shift*             [▼ Select Shift]        │
│  Description: 08:00 - 14:00                │
│                                              │
│  Effective From*    [__/__/____]            │
│                                              │
│  Select Employees:                         │
│  [□ John Doe (Science)]                    │
│  [□ Jane Smith (English)]                  │
│  [✓ Mike Johnson (Math)]                   │
│  [□ Sarah Lee (History)]                   │
│  ...                                        │
│  [Select All] [Clear All] [Invert]         │
│                                              │
│  Total Selected: 1                         │
│                                              │
│  [Cancel] [Assign Shift]                   │
└──────────────────────────────────────────────┘
```

---

## 4. Input Validation Rules

### 4.1 Shift Master Validations

| Field | Type | Validation Rule | Error Message |
|-------|------|-----------------|----------------|
| Code | String | Required, 3-20 chars, unique, uppercase | Shift code is required and must be unique |
| Name | String | Required, 1-100 chars | Shift name is required |
| Description | Text | Optional, max 255 chars | Description must not exceed 255 chars |
| Start Time | Time | Required, HH:MM:SS format, < end_time | Start time is required and must be before end time |
| End Time | Time | Required, HH:MM:SS format, > start_time | End time must be after start time |
| Break Duration | Integer | Required, 0-480 minutes (0-8 hrs) | Break must be 0-480 minutes |
| Grace Late | Integer | Required, 0-120 minutes | Grace minutes late must be 0-120 |
| Grace Early | Integer | Required, 0-120 minutes | Grace minutes early must be 0-120 |
| Half-Day Threshold | Integer | Required, 60-480 minutes | Threshold must be 60-480 minutes |
| Applies to Days | Array | Required, at least 1 day selected | Must select at least one day |
| Is Default | Boolean | Optional | If true, only one shift can be default |

### 4.2 Shift Assignment Validations

| Field | Type | Validation Rule | Error Message |
|-------|------|-----------------|----------------|
| Employee | FK | Required, must exist, is_active=1 | Employee must be selected and active |
| Shift | FK | Required, must exist, is_active=1 | Shift must be selected and active |
| Effective From | Date | Required, valid date format | Valid date required in DD/MM/YYYY format |
| Effective To | Date | Optional, if provided: >= effective_from | End date must be after start date |
| Assignment Reason | String | Optional, max 255 chars | Reason must not exceed 255 chars |
| Unique Active | Composite | Max 1 active shift per employee | Employee already has active shift; end previous? |

### 4.3 Cross-Field Validations

| Condition | Validation | Action |
|-----------|-----------|--------|
| Employee has active shift | Allow with warning | Show existing shift; confirm end? |
| Effective To < Today | Warning shown | This shift is already expired |
| Effective From > Today | Info message | Assignment is future-dated |
| Shift time conflicts with other | Check only | For reporting only; no hard block |

---

## 5. Business Logic & Calculations

### 5.1 Auto-Calculated Fields

#### Net Working Hours
```
net_working_hours = (end_time - start_time - break_duration_minutes) / 60
EXAMPLE: 08:00 to 14:00 (6 hrs) - 60 min break = 5 hours
```

#### Active Shift Flag (Generated Column)
```sql
-- Database level - ensures only ONE active shift per employee
UNIQUE KEY `uq_employee_shift_active` (employee_id, active_flag)
WHERE active_flag = 1 AND deleted_at IS NULL
```

#### Effective To (when bulk assigning)
```
IF effective_to NOT PROVIDED:
    effective_to = NULL  (ongoing shift)
ELSE:
    effective_to = provided_value
```

### 5.2 Shift Assignment Logic

#### New Assignment with Existing Active Shift
```
IF (employee has active shift) AND (new assignment effective_from <= today):
    ACTION:
    1. End previous shift: UPDATE ... SET effective_to = effective_from - 1 day
    2. Create new shift: INSERT with effective_from = new_date
    3. Audit trail: Log both changes
```

#### Future-Dated Assignment
```
IF effective_from > TODAY():
    ACTION:
    1. Keep existing active shift as-is
    2. Create future assignment
    3. Scheduler: Auto-activate on effective_from date
```

### 5.3 Default Values
- `is_active` = true
- `created_by` = current_user_id
- `created_at` = CURRENT_TIMESTAMP
- `active_flag` = 1 (if is_active=1 AND deleted_at IS NULL)

---

## 6. State Transitions & Workflows

### 6.1 Shift State Machine
```
┌─────────────┐
│   DRAFT     │ (New shift master, not yet used)
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   ACTIVE    │ (Assigned to employees, in use)
└──────┬──────┘
       │
       ├─[Archive]──► Archived (no longer assign new)
       │
       └─[Delete]──► Deleted (with validation: no active assignments)
```

### 6.2 Assignment State Machine
```
┌──────────────┐
│  ASSIGNED    │ (Effective From <= Today)
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  ACTIVE      │ (Employee working on this shift)
└──────┬───────┘
       │
       ├─[End]───────► EXPIRED (Effective To reached)
       │
       └─[Change]───► REPLACED (New shift assigned)

┌──────────────┐
│  SCHEDULED   │ (Effective From > Today — future assignment)
└──────┬───────┘
       │
       ├─[Auto-activate]─► ACTIVE (when effective_from date reached)
       │
       └─[Cancel]────────► CANCELLED (if removed before effective date)
```

---

## 7. Database Operations

### 7.1 Create Shift Master
```sql
INSERT INTO sch_employee_shifts (
    code, name, description, start_time, end_time,
    break_duration_minutes, working_hours,
    grace_minutes_late, grace_minutes_early,
    half_day_threshold_minutes, applies_to_days,
    is_default, is_active, created_by
) VALUES (?, ?, ?, ?, ?, ?, 
    TIMESTAMPDIFF(MINUTE, ?, ?) / 60 - ?/60,
    ?, ?, ?, JSON_ARRAY(...), ?, 1, ?);
```

### 7.2 Create Shift Assignment
```sql
INSERT INTO sch_employee_shift_assignments (
    employee_id, shift_id, effective_from, effective_to,
    assignment_reason, is_active, created_by
) VALUES (?, ?, ?, ?, ?, 1, ?);

-- If new assignment starts today/before, end previous active
UPDATE sch_employee_shift_assignments
SET effective_to = DATE_SUB(?, INTERVAL 1 DAY),
    is_active = 0
WHERE employee_id = ? AND shift_id != ? 
  AND effective_from <= ? AND is_active = 1;
```

### 7.3 End Shift Assignment
```sql
UPDATE sch_employee_shift_assignments
SET effective_to = ?, is_active = 0, updated_by = ?
WHERE id = ? AND deleted_at IS NULL;
```

### 7.4 Bulk Assign Shift
```sql
INSERT INTO sch_employee_shift_assignments 
    (employee_id, shift_id, effective_from, is_active, created_by)
SELECT ?, ?, ?, 1, ?
FROM sch_employees
WHERE id IN (?, ?, ?, ...)
  AND deleted_at IS NULL;
```

---



## 9. Permissions & Authorization

### 9.1 Role-Based Permissions

| Permission | Admin | HR Mgr | Manager | Employee |
|-----------|-------|--------|---------|----------|
| view.shift.list | ✓ | ✓ | ✓ | ✗ |
| create.shift | ✓ | ✓ | ✗ | ✗ |
| edit.shift | ✓ | ✓ | ✗ | ✗ |
| delete.shift | ✓ | ✓ | ✗ | ✗ |
| view.assignment | ✓ | ✓ | ✓ | ✓ (self) |
| create.assignment | ✓ | ✓ | ✗ | ✗ |
| edit.assignment | ✓ | ✓ | ✗ | ✗ |

---

## 10. Error Handling

### 10.1 Common Error Scenarios

| Error Code | HTTP | Message | Cause | Action |
|-----------|------|---------|-------|--------|
| SHIFT-001 | 400 | Shift code already exists | Duplicate code | Use unique code |
| SHIFT-002 | 400 | Start time must be before end time | Invalid times | Fix time range |
| SHIFT-003 | 400 | Only one shift can be default | Multiple defaults | Clear other defaults |
| SHIFT-004 | 400 | Cannot delete; assigned to employees | Active assignments | Archive instead |
| SHIFT-005 | 409 | Employee already has active shift | Conflict | End previous first |
| SHIFT-006 | 404 | Shift not found | Invalid shift_id | Check shift ID |
| SHIFT-007 | 403 | Permission denied | Insufficient role | Contact admin |
| SHIFT-008 | 422 | Validation failed | Multiple errors | Fix validation |

---

## 11. Performance Considerations

### 11.1 Indexing Strategy
```sql
CREATE INDEX idx_shift_code ON sch_employee_shifts(code);
CREATE INDEX idx_shift_active ON sch_employee_shifts(is_active);
CREATE INDEX idx_assignment_employee ON sch_employee_shift_assignments(employee_id, is_active);
CREATE INDEX idx_assignment_shift ON sch_employee_shift_assignments(shift_id);
CREATE INDEX idx_assignment_effective ON sch_employee_shift_assignments(effective_from, effective_to);
```

### 11.2 Query Optimization
- Use pagination for large shift lists
- Eager-load related shifts for employees
- Cache shift master (5-min TTL)
- Index on (employee_id, is_active) for active shift lookup

---

## 12. Integration Points

### 12.1 Dependent Screens
- **SR-EM-04 (Attendance Masters):** Uses shift for attendance validation
- **SR-EM-08 (Attendance Management):** Marks daily attendance per shift
- **SmartTimetable:** Synchronizes shift working hours with timetable slots

### 12.2 Notification Events
- Shift assigned → Email to employee
- Shift ending soon → Reminder notification (5 days)
- Shift changed → Notify affected employees

---

## 13. Testing Checklist

- [ ] Create shift with all fields
- [ ] Validate unique shift code
- [ ] Calculate net working hours
- [ ] Set default shift (only one allowed)
- [ ] Assign shift to employee
- [ ] End active shift and assign new
- [ ] Bulk assign shift to multiple employees
- [ ] Prevent duplicate active shifts per employee
- [ ] Show shift history
- [ ] Export shift assignments

---

**Next Steps:** 
- Implement shift master CRUD
- Build shift assignment workflow
- Create bulk assignment feature
- Add shift history view
- Implement audit trail logging

