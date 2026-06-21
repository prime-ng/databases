# Screen Requirement: Holiday Calendar Management
## Document ID: SR-EM-04-TAB2
**Module:** SchoolSetup / EmployeeSetup  
**Screen Name:** Holiday Calendar (Tab 2 of Attendance Masters)  
**Route:** `school-setup.attendance-master.index?tab=holiday-calendar`  
**User Role:** School Administrator, HR Manager  
**Priority:** P0 (Critical)  
**Status:** Approved for Development  

---

## 1. Screen Overview

### 1.1 Purpose & Business Objective
This tab manages the school's holiday calendar within a specific academic session. It defines dates that are non-working (paid holidays, public holidays, school closures) and can specify which employee roles/departments are affected. The holiday calendar directly impacts leave balance calculations and working day counts.

### 1.2 Key Capabilities
- ✅ Create holidays with date ranges or specific dates
- ✅ Assign holiday categories (Public, School, Restricted)
- ✅ Define applicability scope (All Employees, By Role, By Department)
- ✅ Generate working day counts (excludes holidays + weekends)
- ✅ Bulk import holidays from Excel/CSV
- ✅ View calendar grid with holiday marks
- ✅ Optional holidays (employees can choose to work)
- ✅ Soft delete and restore holidays

---

## 2. Data Model & DDL Reference

### 2.1 Primary Tables

#### sch_holidays — Holiday Master
```sql
sch_holidays
├── Identification: id (INT), code (VARCHAR 20), name (VARCHAR 100)
├── Dates: date_from (DATE), date_to (DATE)
├── Category: category (ENUM: Public/School/Restricted/Optional)
├── Scope: scope_type (ENUM: All/ByRole/ByDept/ByDesignation)
├── Payroll: is_paid (BOOL) — default TRUE
├── Applicability: is_optional (BOOL) — default FALSE
├── Academic: annual_leave_session_id (FK)
├── Description: description (TEXT)
├── Status: is_active (BOOL), deleted_at (TIMESTAMP)
└── Audit: created_by (INT), created_at, updated_at
```

#### sch_holiday_role_jnt — Holiday Role Scope
```sql
sch_holiday_role_jnt
├── FK: holiday_id, role_id (from sys_roles)
└── Audit: created_at
```

#### sch_holiday_department_jnt — Holiday Department Scope
```sql
sch_holiday_department_jnt
├── FK: holiday_id, department_id (from sch_departments)
└── Audit: created_at
```

### 2.2 Related Tables
- `sch_annual_leave_sessions` — Academic year context
- `sys_roles` — For role-based holiday assignment
- `sch_departments` — For department-based holiday assignment

---

## 3. Screen Layout & UI Components

### 3.1 List View

```
┌─ HOLIDAY CALENDAR (2026 Academic Year) ──────────────┐
│                                                        │
│ [+ New Holiday] [Import from CSV] [View Calendar]     │
│ Filter: Category [All ▼] Scope [All ▼] [Search_____] │
│                                                        │
├────────────────────────────────────────────────────────┤
│ Date Range │ Name          │ Category│ Scope  │ Paid│Act
│────────────────────────────────────────────────────────│
│ 26 Jan     │ Republic Day  │ Public  │ All    │ ✓ │ ✓
│ 08 Mar     │ Women's Day   │ Public  │ All    │ ✓ │ ✓
│ 15 Mar - 21 Mar │ Spring Break │ School │ All │ ✓ │ ✓
│ 04 Jul     │ Independence  │ Public  │ All    │ ✓ │ ✓
│ 15 Aug     │ Independence  │ Public  │ All    │ ✓ │ ✓
│ 02 Oct     │ Gandhi Jayant │ Public  │ All    │ ✓ │ ✓
│ 25 Dec     │ Christmas     │ Public  │ All    │ ✓ │ ✓
│ 20 May-24 May │ Summer Vacat │ School │ All   │ ✓ │ ✓
│                                                        │
└────────────────────────────────────────────────────────┘
[View Details] [Edit] [Delete]

Total Holidays: 12 | Paid Holidays: 12 | Optional: 0
Total Non-Working Days in Year: 147 (Holidays + Weekends)
Working Days: 218 (365 - 147)
```

### 3.2 Create/Edit Holiday Form

#### Section A: Holiday Identification
```
┌─ HOLIDAY DETAILS ────────────────────────────────────┐
│                                                       │
│ Holiday Code*        [______] (e.g., REP-26JAN)      │
│                                                       │
│ Holiday Name*        [________________]              │
│ (e.g., Republic Day, Summer Vacation)               │
│                                                       │
│ Category*            (O Public    O School           │
│                      O Restricted O Optional)        │
│                                                       │
│ Description          [________________________]       │
│ (Optional)                                          │
│                                                       │
│ [Next →]                                            │
└───────────────────────────────────────────────────────┘

CATEGORY DEFINITIONS:
• Public: Government/National holiday (bank holiday)
• School: School-specific holiday (summer break, annual events)
• Restricted: Special holiday (for specific groups only)
• Optional: Employees can work or take (e.g., Diwali)
```

#### Section B: Date Range
```
┌─ DATE CONFIGURATION ─────────────────────────────────┐
│                                                       │
│ Holiday Type: (O Single Date  O Date Range)         │
│                                                       │
│ From Date*          [__/__/____] (DD/MM/YYYY)       │
│ To Date             [__/__/____] (If range)         │
│                                                       │
│ Days Span: 1 Day                                     │
│                                                       │
│ Number of Days to Exclude from Leave Balance: 1     │
│                                                       │
│ NOTE: Only working days (Mon-Fri) are counted       │
│ Example: 15-17 Mar (Sat-Mon) = 1 working day        │
│                                                       │
│ [Next →]                                            │
└───────────────────────────────────────────────────────┘
```

#### Section C: Applicability Scope
```
┌─ WHO DOES THIS APPLY TO? ────────────────────────────┐
│                                                       │
│ Scope Type: (O All Employees  O By Role              │
│             O By Department   O By Designation)      │
│                                                       │
│ IF "By Role":                                        │
│ Select Roles: [✓] Admin  [✓] Teacher  [✓] Support   │
│                                                       │
│ IF "By Department":                                  │
│ Select Depts: [✓] Academic  [✓] Admin  [✓] Support  │
│                                                       │
│ IF "By Designation":                                │
│ Select Desig: [✓] Principal  [✓] Coordinator        │
│                                                       │
│ [Next →]                                            │
└───────────────────────────────────────────────────────┘

SCOPE LOGIC:
• All: Applies to every employee (default)
• By Role: Only selected roles don't work
• By Dept: Only selected departments don't work
• By Desig: Only selected designations don't work
```

#### Section D: Holiday Configuration
```
┌─ HOLIDAY SETTINGS ──────────────────────────────────┐
│                                                      │
│ [✓] Is Paid Holiday                                │
│     (Checked = counts as working day, no leave used)│
│     (Unchecked = no pay if worked)                 │
│                                                      │
│ [  ] Is Optional Holiday                           │
│     (Checked = employee can work or take off)      │
│     (Unchecked = mandatory non-working day)        │
│                                                      │
│ [✓] Is Active                                       │
│                                                      │
│ [← Back] [Save]                                    │
└───────────────────────────────────────────────────────┘
```

### 3.3 Calendar Grid View

```
┌─ HOLIDAY CALENDAR GRID (May 2026) ─────────────────┐
│                                                      │
│ ← April 2026        May 2026        June 2026 →     │
│                                                      │
│ Sun│ Mon│ Tue│ Wed│ Thu│ Fri│ Sat│                 │
│────┼────┼────┼────┼────┼────┼────┤                 │
│    │    │    │    │    │  1 │  2 │                 │
│  3 │  4 │  5 │  6 │  7 │  8 │  9 │                 │
│ 10 │ 11 │ 12 │ 13 │ 14 │ 15 │ 16 │                 │
│ 17 │ 18 │ 19 │ 20 │[21]│[22]│[23]│ ← Summer       │
│[24]│[25]│[26]│ 27 │ 28 │ 29 │ 30 │    Break       │
│ 31 │    │    │    │    │    │    │    (Holidays)   │
│                                                      │
│ Legend:                                             │
│ [■] Public Holiday    [■] School Holiday           │
│ [■] Restricted        [■] Optional                  │
│                                                      │
└──────────────────────────────────────────────────────┘
```

---

## 4. Input Validation Rules

### 4.1 Validations

| Field | Type | Validation Rule | Error Message |
|-------|------|-----------------|----------------|
| Code | String | Required, unique, 5-20 chars, uppercase | Code must be unique and uppercase |
| Name | String | Required, 1-100 chars | Name is required (1-100 chars) |
| Category | Enum | Required (Public/School/Restricted/Optional) | Category must be selected |
| From Date | Date | Required, valid date, ≥ session start | Date must be within academic session |
| To Date | Date | Optional, ≥ From Date if provided | End date must be ≥ start date |
| Days Count | Integer | Auto-calculated, display only | N/A |
| Scope Type | Enum | Required | Must specify who it applies to |
| Is Paid | Boolean | Required | Must specify if paid |
| Is Optional | Boolean | Optional | Toggle for employee choice |
| Is Active | Boolean | Required | Must specify active status |

### 4.2 Cross-Field Validations

| Condition | Validation | Action |
|-----------|-----------|--------|
| To Date < From Date | Error | "End date cannot be before start date" |
| Date range outside session | Error | "Holiday must fall within academic session" |
| Duplicate dates | Warning | "Another holiday exists on this date" |
| is_optional = true AND is_paid = false | Warning | "Optional holidays are usually paid" |
| scope_type = All | Ignore role/dept selection | Clear previous selections |
| scope_type = By Role AND no roles selected | Error | "Select at least one role" |

---

## 5. Business Logic & Calculations

### 5.1 Holiday Categories & Behavior

#### Public Holiday (National/Government)
```
• Is Paid: true
• Applies to: All employees
• Working Day Count: Excludes from total
• Example: Republic Day (26 Jan), Independence Day (15 Aug)
```

#### School Holiday
```
• Is Paid: true
• Applies to: All employees
• Working Day Count: Excludes from total
• Example: Summer vacation (3 months), Annual break
```

#### Restricted Holiday (Special Groups)
```
• Is Paid: true (if applies to employee)
• Applies to: Specific role/dept/designation
• Working Day Count: Excludes for applicable employees only
• Example: Diwali (for Hindu staff), Christmas (for Christian staff)
```

#### Optional Holiday
```
• Is Paid: true (if taken)
• Applies to: All or specific groups
• Working Day Count: Conditional (if worked, counts as working day)
• Example: Holi, Diwali, Eid (employees choose to work or take)
```

### 5.2 Working Day Calculation Formula

```
Working Days in Academic Session =
    Total Days in Session
    - Public Holidays (all employees)
    - School Holidays (all employees)
    - Weekends (Saturday + Sunday)
    - Restricted Holidays (if applicable to employee)
    + Optional Holidays (if employee works)

EXAMPLE:
Session: Jan 1 - Dec 31, 2026 (365 days)
- Weekends: ~104 days
- Public Holidays: 12 days
- School Holidays: 30 days (summer break)
= Working Days: 365 - 104 - 12 - 30 = 219 days
```

### 5.3 Holiday Scope Logic Query

```sql
-- Get applicable holidays for specific employee
SELECT h.* FROM sch_holidays h
WHERE h.annual_leave_session_id = ? 
  AND h.is_active = 1
  AND h.deleted_at IS NULL
  AND (
    -- All employees
    h.scope_type = 'All'
    OR
    -- By Role
    (h.scope_type = 'ByRole' AND 
     EXISTS (SELECT 1 FROM sch_holiday_role_jnt 
             WHERE holiday_id = h.id AND role_id = ?))
    OR
    -- By Department
    (h.scope_type = 'ByDept' AND 
     EXISTS (SELECT 1 FROM sch_holiday_department_jnt 
             WHERE holiday_id = h.id AND department_id = ?))
    OR
    -- By Designation
    (h.scope_type = 'ByDesignation' AND 
     EXISTS (SELECT 1 FROM sch_holiday_designation_jnt 
             WHERE holiday_id = h.id AND designation_id = ?))
  )
ORDER BY h.date_from;
```

### 5.4 Weekday Calculation

```
For date range (from_date to to_date):
  working_days = 0
  FOR each date in range:
    IF day_of_week NOT IN (Saturday, Sunday):
      working_days += 1
  
Example: 15 Mar - 19 Mar 2026
  15 Mar = Wed ✓ (count)
  16 Mar = Thu ✓ (count)
  17 Mar = Fri ✓ (count)
  18 Mar = Sat ✗ (skip)
  19 Mar = Sun ✗ (skip)
  Total Working Days in Range = 3
```

---

## 6. Database Operations

### 6.1 Create Holiday
```sql
INSERT INTO sch_holidays (
    code, name, category, description,
    date_from, date_to, scope_type,
    is_paid, is_optional, annual_leave_session_id,
    is_active, created_by
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?);

-- Then insert role/dept/desig relationships if applicable
INSERT INTO sch_holiday_role_jnt (holiday_id, role_id)
SELECT ?, id FROM sys_roles WHERE id IN (...);
```

### 6.2 Get Working Days in Session
```sql
SELECT COUNT(DISTINCT DATE(d.date)) as working_days
FROM (
    SELECT DATE_ADD(?, INTERVAL seq DAY) as date
    FROM (
        SELECT @row:=@row+1 as seq FROM 
        (SELECT @row:=-1) init, 
        sch_holidays LIMIT 
        DATEDIFF(?, ?)
    ) dates
) d
WHERE DAYOFWEEK(d.date) NOT IN (1, 7)  -- Exclude Sunday(1) & Saturday(7)
  AND NOT EXISTS (
      SELECT 1 FROM sch_holidays h
      WHERE d.date BETWEEN h.date_from AND h.date_to
        AND h.is_active = 1 AND h.deleted_at IS NULL
  );
```

### 6.3 Get Holidays for Employee (with scope)
```sql
SELECT h.* FROM sch_holidays h
WHERE h.annual_leave_session_id = ? AND h.is_active = 1
  AND h.deleted_at IS NULL
  AND (h.scope_type = 'All' OR 
       h.id IN (SELECT hr.holiday_id FROM sch_holiday_role_jnt hr 
                WHERE hr.role_id = ?) OR
       h.id IN (SELECT hd.holiday_id FROM sch_holiday_department_jnt hd 
                WHERE hd.department_id = ?))
ORDER BY h.date_from;
```

---



## 8. Permissions & Authorization

| Permission | Admin | HR Mgr | Manager | Employee |
|-----------|-------|--------|---------|----------|
| view.holiday.list | ✓ | ✓ | ✓ | ✓ |
| create.holiday | ✓ | ✓ | ✗ | ✗ |
| edit.holiday | ✓ | ✓ | ✗ | ✗ |
| delete.holiday | ✓ | ✗ | ✗ | ✗ |
| view.holiday.calendar | ✓ | ✓ | ✓ | ✓ |
| bulk_import.holiday | ✓ | ✓ | ✗ | ✗ |

---

## 9. Error Handling

| Error Code | HTTP | Message | Cause | Action |
|-----------|------|---------|-------|--------|
| HOL-001 | 400 | Holiday code already exists | Duplicate | Use unique code |
| HOL-002 | 400 | End date before start date | Invalid range | Correct date range |
| HOL-003 | 400 | Date outside session | Invalid date | Select within session |
| HOL-004 | 400 | No scope specified | Missing selection | Choose All or specific groups |
| HOL-005 | 409 | Cannot delete; referenced in calculations | Active usage | Mark as inactive |
| HOL-006 | 400 | Invalid CSV format | Bad import file | Check CSV structure |

---

## 10. Testing Checklist

- [ ] Create single-day and multi-day holidays
- [ ] Verify public/school/restricted/optional categories
- [ ] Test scope: All, By Role, By Dept, By Designation
- [ ] Calculate working days correctly
- [ ] Verify holiday exclusion from leave balance
- [ ] Test bulk import from CSV
- [ ] View calendar grid
- [ ] Soft delete and restore
- [ ] Verify holiday applicability per employee role
- [ ] Test optional holiday marking

---

**Next Steps:** 
- Implement holiday CRUD
- Build calendar grid UI
- Create bulk import feature
- Implement working day calculation
- Add holiday scope filtering

