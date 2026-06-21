# Screen Requirement: Attendance Masters Configuration
## Document ID: SR-EM-04
**Module:** SchoolSetup / EmployeeSetup  
**Screen Name:** Attendance Masters Configuration  
**Route:** `school-setup.attendance-master.index`  
**User Role:** School Administrator, HR Manager  
**Priority:** P0 (Critical)  
**Status:** Approved for Development  

---

## 1. Screen Overview

### 1.1 Purpose & Business Objective
This screen serves as the central hub for configuring all attendance-related master data, including attendance type definitions, holiday calendars, shifts (already covered in SR-EM-03), and shift assignments. It provides tabbed access to configure the foundation for daily attendance tracking and leave management.

### 1.2 Key Capabilities
- ✅ Define attendance types (Present, Absent, Leave, Late, Holiday, Half-Day, etc.)
- ✅ Configure attendance type behavior (payroll impact, approval requirements, half-day rules)
- ✅ Manage school holiday calendar (annual, religious, optional holidays)
- ✅ View and manage staff shifts (delegated to SR-EM-03)
- ✅ Assign shifts to employees (delegated to SR-EM-03)
- ✅ Configure shift-specific rules and grace periods
- ✅ Define annual leave sessions (calendar year vs academic year)

---

## 2. Data Model & DDL References

### 2.1 Primary Tables
```sql
sch_staff_attendance_types — Attendance category definitions
├── Identification: code (unique), name, category (ENUM)
├── Behavior: is_present, can_be_half_day, affects_payroll
├── Payroll: payroll_percentage, requires_approval
└── Display: color_hex, icon_class, display_order

sch_holidays — School holiday calendar
├── Date: holiday_date, annual_leave_sessions_id (FK)
├── Type: holiday_type (ENUM), is_optional, is_paid
├── Scope: applies_to_role_id, applies_to_department_id
└── Status: is_active

sch_annual_leave_sessions — Leave year definitions
├── Period: name, start_date, end_date
└── Usage: linked to holidays and leave balances
```

### 2.2 Related Tables
- `sch_employee_shifts` — Shift master
- `sch_employee_shift_assignments` — Employee ↔ Shift mapping
- `sch_employee_roles` — For role-specific holidays
- `sch_departments` — For department-specific holidays

---

## 3. Screen Layout & UI Components

### 3.1 Page Structure: Tabbed Interface

```
┌─ Attendance Master Management ─────────────────────┐
│                                                    │
│  [+ New Type] [+ Holiday] [+ Shift] [View Config]│
│                                                    │
├────────────────────────────────────────────────────┤
│  TAB 1: STAFF ATTENDANCE TYPES                    │
│  ┌──────────────────────────────────────────────┐ │
│  │Code │ Name    │ Category  │ Payroll% │Active│ │
│  │ PR  │ Present │ Attendance│  100%   │  ✓  │ │
│  │ AB  │ Absent  │ Attendance│   0%    │  ✓  │ │
│  │ LV  │ Leave   │ Leave     │  100%   │  ✓  │ │
│  │ LT  │ Late    │ Attendance│  100%   │  ✓  │ │
│  │ HD  │ Half Day│ Attendance│   50%   │  ✓  │ │
│  │ HO  │ Holiday │ Holiday   │  100%   │  ✓  │ │
│  └──────────────────────────────────────────────┘ │
│  [Edit] [View Details] [Delete]
│
├────────────────────────────────────────────────────┤
│  TAB 2: ANNUAL LEAVE SESSIONS                     │
│  ┌──────────────────────────────────────────────┐ │
│  │Name│ Start Date │ End Date │ Active │ Action│ │
│  │2025│ 01/01/2025│31/12/2025│  ✓   │ Edit  │ │
│  │2026│ 01/01/2026│31/12/2026│  ✓   │ Edit  │ │
│  └──────────────────────────────────────────────┘ │
│
├────────────────────────────────────────────────────┤
│  TAB 3: HOLIDAY CALENDAR                          │
│  Showing: [Select Year: 2026 ▼] [Select Month ▼]│
│  ┌──────────────────────────────────────────────┐ │
│  │Date │ Holiday Name │ Type │ Optional│ Paid│A│ │
│  │26/01│ Republic Day │Public│  No   │ Yes│✓│ │
│  │08/03│ Maha Shivaratri│Relig│  Yes  │ Yes│✓│ │
│  │17/04│ School Summer │Vacat│  No   │ Yes│✓│ │
│  └──────────────────────────────────────────────┘ │
│  [+ Add Holiday] [Bulk Import]
│
├────────────────────────────────────────────────────┤
│  TAB 4: EMPLOYEE SHIFTS (View/Configure)          │
│  [Delegates to SR-EM-03]                         │
│  - Create/Edit Shift Templates                    │
│  - Assign Shifts to Employees                     │
│  - View Shift Assignments                         │
│                                                    │
└────────────────────────────────────────────────────┘
```

### 3.2 Attendance Type Form (Create/Edit)

```
┌─ ATTENDANCE TYPE CONFIGURATION ────────────────────┐
│                                                    │
│  Code*              [_____________]               │
│  Name*              [_____________]               │
│  Category*          [▼ Select Category]           │
│                    (Attendance / Leave / Holiday  │
│                     / Other)                      │
│                                                    │
│  Description        [________________]            │
│                                                    │
├─ BEHAVIOR FLAGS ──────────────────────────────────┤
│                                                    │
│  [✓] Is Present (Counts toward attendance)       │
│  [✓] Can Be Half-Day (Allow half-day marking)   │
│  [✓] Affects Payroll (Impacts salary)            │
│  [  ] Requires Approval (Need supervisor OK)    │
│                                                    │
├─ PAYROLL CONFIGURATION ────────────────────────────┤
│                                                    │
│  Payroll Percentage*    [___]%                    │
│  (e.g., 100 = Full Day, 50 = Half Day, 0 = None)│
│                                                    │
│  [? Help: This % of daily wage is paid]          │
│                                                    │
├─ DISPLAY SETTINGS ─────────────────────────────────┤
│                                                    │
│  Color (for Calendar)*  [#_____] [■ Preview]    │
│  Icon Class (Font Awesome)  [_____________]     │
│  Display Order          [___]                     │
│                                                    │
│  [✓] Is System Type (Cannot delete)              │
│  [ ] Is Active                                    │
│                                                    │
│  [Cancel] [Save] [Save & Add More]               │
└────────────────────────────────────────────────────┘
```

### 3.3 Annual Leave Session Form

```
┌─ ANNUAL LEAVE SESSION ─────────────────────────────┐
│                                                    │
│  Name*              [_____________]               │
│  (e.g., "2026 Calendar Year")                    │
│                                                    │
│  Start Date*        [__/__/____]                  │
│  (Typically 01/01 or 01/04)                      │
│                                                    │
│  End Date*          [__/__/____]                  │
│  (Typically 31/12 or 31/03)                      │
│                                                    │
│  Description        [________________]            │
│                                                    │
│  [ ] Is Active                                    │
│                                                    │
│  [Cancel] [Save]                                  │
└────────────────────────────────────────────────────┘
```

### 3.4 Holiday Calendar Form

```
┌─ ADD HOLIDAY TO CALENDAR ──────────────────────────┐
│                                                    │
│  Annual Leave Session*  [▼ 2026 Calendar Year]   │
│                                                    │
│  Holiday Date*      [__/__/____]                  │
│  Holiday Name*      [_____________]               │
│  (e.g., "Republic Day", "Diwali")                │
│                                                    │
│  Holiday Type*      (O Public                     │
│                     O Religious                   │
│                     O Optional                    │
│                     O School_Specific             │
│                     O Sunday                      │
│                     O Saturday                    │
│                     O Vacation                    │
│                     O Other)                      │
│                                                    │
│  [ ] Is Optional (Employee can choose)           │
│  [✓] Is Paid (Counts as paid holiday)            │
│                                                    │
│  Applies to Role     [▼ All Roles]               │
│  (Leave blank = applies to all)                  │
│                                                    │
│  Applies to Dept     [▼ All Depts]               │
│  (Leave blank = applies to all)                  │
│                                                    │
│  [Cancel] [Save]                                  │
└────────────────────────────────────────────────────┘
```

---

## 4. Input Validation Rules

### 4.1 Attendance Type Validations

| Field | Type | Validation Rule | Error Message |
|-------|------|-----------------|----------------|
| Code | String | Required, 2-10 chars, unique, uppercase | Code must be 2-10 chars and unique |
| Name | String | Required, 1-100 chars | Name is required |
| Category | Enum | Required (Attendance/Leave/Holiday/Other) | Category must be selected |
| Description | Text | Optional, max 500 chars | Description must not exceed 500 chars |
| Is Present | Boolean | Required | Must specify if counts as present |
| Can Be Half-Day | Boolean | Optional | Toggle allowed |
| Affects Payroll | Boolean | Required | Must specify payroll impact |
| Payroll % | Decimal | Required, 0-100.00 | Must be 0-100% |
| Requires Approval | Boolean | Optional | Toggle allowed |
| Color Hex | String | Optional, format #RRGGBB | Must be valid hex color |
| Icon Class | String | Optional, max 50 chars | Font Awesome class |
| Display Order | Integer | Optional, 0-9999 | Order value |
| Is System | Boolean | Optional (set true for defaults) | Cannot delete if true |
| Is Active | Boolean | Required | Must specify active status |

### 4.2 Leave Session Validations

| Field | Type | Validation Rule | Error Message |
|-------|------|-----------------|----------------|
| Name | String | Required, unique, 1-100 chars | Name is required and must be unique |
| Start Date | Date | Required, valid date, <= end_date | Valid date required |
| End Date | Date | Required, valid date, >= start_date | Must be after start date |
| Description | Text | Optional, max 500 chars | Max 500 chars |
| Is Active | Boolean | Required | Must specify |

### 4.3 Holiday Validations

| Field | Type | Validation Rule | Error Message |
|-------|------|-----------------|----------------|
| Leave Session | FK | Required, must exist | Session must be selected |
| Holiday Date | Date | Required, within session range | Must be between session start/end |
| Holiday Name | String | Required, 1-150 chars | Name is required |
| Holiday Type | Enum | Required | Type must be selected |
| Is Optional | Boolean | Optional | Toggle allowed |
| Is Paid | Boolean | Required | Must specify |
| Applies to Role | FK | Optional | Can leave blank for all |
| Applies to Dept | FK | Optional | Can leave blank for all |
| Is Active | Boolean | Required | Must specify |

### 4.4 Cross-Field Validations

| Condition | Validation | Action |
|-----------|-----------|--------|
| Payroll % > 0 | Check requires_approval | If payroll impacts salary, may need approval |
| Holiday Date not in range | Error raised | Holiday date must be within leave session |
| Duplicate attendance code | Error raised | Cannot create duplicate attendance type |
| Duplicate holiday date | Warn user | Same date exists; confirm to create duplicate |

---

## 5. Business Logic & Calculations

### 5.1 Attendance Type Behavior Logic

#### Payroll Impact Calculation
```
IF affects_payroll = true:
    daily_pay_impact = daily_wage * (payroll_percentage / 100)
ELSE:
    daily_pay_impact = 0

FOR HALF-DAY:
    IF can_be_half_day = true:
        half_day_pay = daily_wage * (payroll_percentage / 100) * 0.5
    ELSE:
        half_day_pay = NOT_ALLOWED
```

#### Attendance Type Category Impact
```
IF category = 'Attendance':
    affects_balance = NO (not counted against leave)
ELSE IF category = 'Leave':
    affects_balance = YES (consumes leave balance)
ELSE IF category = 'Holiday':
    affects_balance = NO (not charged to leave)
ELSE IF category = 'Other':
    affects_balance = NO (configurable per type)
```

### 5.2 Holiday Calendar Logic

#### Holiday Exclusion in Leave Day Count
```
FUNCTION: Count_Working_Days(start_date, end_date, leave_session_id)
    working_days = 0
    FOR each day IN (start_date TO end_date):
        IF day NOT IN (weekends or holidays for that session):
            working_days += 1
        ELSE:
            working_days += 0  (skip holidays)
    RETURN working_days
```

#### Optional Holiday Selection
```
IF holiday.is_optional = true:
    ACTION:
    1. Employee can SELECT from available optional holidays
    2. Selection counted as separate leave balance
    3. Example: "Diwali" vs "Holi" — choose one
```

### 5.3 Default Values
- `is_active` = true
- `created_by` = current_user_id
- `created_at` = CURRENT_TIMESTAMP
- `payroll_percentage` = 100 (if is_present=true)
- `affects_payroll` = true (default)

---

## 6. Database Operations

### 6.1 Create Attendance Type
```sql
INSERT INTO sch_staff_attendance_types (
    code, name, category, description,
    is_present, can_be_half_day, affects_payroll,
    payroll_percentage, requires_approval,
    color_hex, icon_class, display_order,
    is_system, is_active, created_by
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 1, ?);
```

### 6.2 Create Holiday
```sql
INSERT INTO sch_holidays (
    annual_leave_sessions_id, holiday_date, name,
    description, holiday_type, is_optional, is_paid,
    applies_to_role_id, applies_to_department_id,
    is_active, created_by
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?);
```

### 6.3 Create Leave Session
```sql
INSERT INTO sch_annual_leave_sessions (
    name, start_date, end_date, description,
    is_active, created_by
) VALUES (?, ?, ?, ?, 1, ?);
```

### 6.4 Get Working Days (excluding holidays)
```sql
SELECT COUNT(*) as working_days
FROM (
    SELECT CURDATE() + INTERVAL (a.a + (10 * b.a) + (100 * c.a)) DAY as holiday_free_date
    FROM (SELECT 0 as a UNION SELECT 1 UNION SELECT 2 UNION... UNION SELECT 9) a,
         (SELECT 0 as a UNION SELECT 1 UNION SELECT 2 UNION... UNION SELECT 9) b,
         (SELECT 0 as a UNION SELECT 1 UNION SELECT 2 UNION... UNION SELECT 9) c
) days
WHERE holiday_free_date >= ? AND holiday_free_date <= ?
  AND DAYOFWEEK(holiday_free_date) NOT IN (1, 7)  -- Exclude Sundays and Saturdays
  AND holiday_free_date NOT IN (
      SELECT holiday_date FROM sch_holidays 
      WHERE annual_leave_sessions_id = ? AND is_active = 1
  );
```

---

## 7. Permissions & Authorization

### 7.1 Role-Based Permissions

| Permission | Admin | HR Mgr | Manager | Employee |
|-----------|-------|--------|---------|----------|
| view.attendance_type.list | ✓ | ✓ | ✓ | ✓ |
| create.attendance_type | ✓ | ✓ | ✗ | ✗ |
| edit.attendance_type | ✓ | ✓ | ✗ | ✗ |
| delete.attendance_type | ✓ | ✗ | ✗ | ✗ |
| view.holiday.calendar | ✓ | ✓ | ✓ | ✓ |
| create.holiday | ✓ | ✓ | ✗ | ✗ |
| edit.holiday | ✓ | ✓ | ✗ | ✗ |
| delete.holiday | ✓ | ✗ | ✗ | ✗ |
| view.leave_session | ✓ | ✓ | ✗ | ✗ |
| create.leave_session | ✓ | ✗ | ✗ | ✗ |

---



## 9. Error Handling

### 9.1 Common Error Scenarios

| Error Code | HTTP | Message | Cause | Action |
|-----------|------|---------|-------|--------|
| ATT-001 | 400 | Attendance type code already exists | Duplicate code | Use unique code |
| ATT-002 | 400 | Payroll % must be 0-100 | Invalid range | Correct percentage |
| ATT-003 | 404 | Attendance type not found | ID doesn't exist | Check type ID |
| HOL-001 | 400 | Holiday date outside session range | Invalid date | Use date within session |
| HOL-002 | 400 | Leave session not found | Invalid FK | Select valid session |
| HOL-003 | 409 | Holiday already exists | Duplicate date | Check calendar |
| SES-001 | 400 | End date must be after start date | Invalid range | Fix date range |
| SES-002 | 409 | Leave session already exists | Duplicate name | Use unique name |

---

## 10. Performance Considerations

### 10.1 Indexing Strategy
```sql
CREATE INDEX idx_attendance_code ON sch_staff_attendance_types(code);
CREATE INDEX idx_attendance_active ON sch_staff_attendance_types(is_active);
CREATE INDEX idx_holiday_date ON sch_holidays(holiday_date, annual_leave_sessions_id);
CREATE INDEX idx_holiday_session ON sch_holidays(annual_leave_sessions_id, is_active);
CREATE INDEX idx_leave_session_date ON sch_annual_leave_sessions(start_date, end_date);
```

### 10.2 Caching Strategy
- Attendance types: Cache 1 hour
- Holiday calendar: Cache 24 hours (invalidate on update)
- Leave sessions: Cache 1 hour

---

## 11. Integration Points

### 11.1 Dependent Screens
- **SR-EM-08 (Leave Applications):** Uses leave sessions and holidays
- **SR-EM-12 (Daily Attendance):** Uses attendance types
- **Payroll System:** Uses attendance types and payroll percentages

---

## 12. Testing Checklist

- [ ] Create attendance type with all behavior flags
- [ ] Validate unique attendance code
- [ ] Configure payroll percentage impact
- [ ] Create leave session with valid date range
- [ ] Add holidays to calendar
- [ ] Mark holidays as optional/paid
- [ ] Apply holidays to specific roles/departments
- [ ] Calculate working days excluding holidays
- [ ] Test payroll percentage for half-day
- [ ] Verify soft delete of attendance types

---

**Next Steps:** 
- Implement attendance type CRUD
- Build holiday calendar UI
- Create leave session management
- Add bulk holiday import
- Implement working day calculation for leave

