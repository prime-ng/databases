# Screen Requirement: Shift Assignments Management
## Document ID: SR-EM-04-TAB4
**Module:** SchoolSetup / EmployeeSetup  
**Screen Name:** Shift Assignments (Tab 4 of Attendance Masters)  
**Route:** `school-setup.attendance-master.index?tab=shift-assignments`  
**User Role:** School Administrator, HR Manager  
**Priority:** P0 (Critical)  
**Status:** Approved for Development  

---

## 1. Screen Overview

### 1.1 Purpose & Business Objective
This tab manages the assignment of shift templates to individual employees with effective date ranges. It ensures only one active shift per employee at any time, handles shift transitions, and maintains complete assignment history for audit purposes.

### 1.2 Key Capabilities
- ✅ Assign shift to single employee or bulk assign to multiple
- ✅ Set effective date ranges (from/to dates)
- ✅ Auto-expire previous shift when new one starts
- ✅ View assignment history per employee
- ✅ Schedule future shifts
- ✅ Override shift for specific date ranges
- ✅ Generate list of employees by shift
- ✅ Bulk import shift assignments

---

## 2. Data Model & DDL Reference

### 2.1 Primary Table

#### sch_employee_shift_assignments — Assignment History
```sql
sch_employee_shift_assignments
├── Foreign Keys:
│   ├── employee_id (FK: sch_employees)
│   └── shift_id (FK: sch_employee_shifts)
├── Assignment Dates:
│   ├── effective_from (DATE) — When this shift begins
│   ├── effective_to (DATE) — When this shift ends (nullable = ongoing)
│   └── actual_end_date (DATE) — When employee left (nullable)
├── Status Management:
│   ├── status (ENUM: DRAFT/SCHEDULED/ACTIVE/EXPIRED/CANCELLED)
│   └── is_active_flag (BOOL) — Only one per employee = true at a time
├── Assignment Type:
│   ├── assignment_type (ENUM: Regular/Temporary/Contract/Probation)
│   └── reason (VARCHAR) — Why change: "New Joining", "Transfer", etc.
├── Reference Data:
│   ├── shift_code_snapshot (VARCHAR) — For historical reference
│   └── remarks (TEXT) — Additional notes
├── Audit: created_by, updated_by, created_at, updated_at, deleted_at
└── Unique Constraint: UNIQUE KEY (employee_id, effective_from, effective_to)
```

### 2.2 Status Workflow

```
DRAFT ─→ SCHEDULED ─→ ACTIVE ─→ EXPIRED/CANCELLED
 ↑         ↓           ↓
 └─────────┴───────────┴─ Manual Override
```

### 2.3 Related Tables
- `sch_employees` — Employee being assigned
- `sch_employee_shifts` — Shift template
- `sch_employee_attendance` — Uses active shift for marking

---

## 3. Screen Layout & UI Components

### 3.1 List View: Current Assignments

```
┌─ CURRENT SHIFT ASSIGNMENTS ──────────────────────────┐
│                                                       │
│ [+ Assign Shift] [Bulk Import] [Export] [Filter]   │
│ Search: [________] Employee: [____] Shift: [____]  │
│                                                       │
├───────────────────────────────────────────────────────┤
│ Employee   │ Shift    │ From Date  │ To Date   │Status
│───────────────────────────────────────────────────────│
│ Raj Kumar  │ Standard │ 01-01-2026 │ —         │ Active
│ Priya Singh│ Morning  │ 01-01-2026 │ —         │ Active
│ Amit Patel │ Afternoon│ 15-01-2026 │ —         │ Active
│ Neha Gupta │ Standard │ 01-01-2026 │ 14-01-2026│ Expired
│ Vikram Das │ Flexible │ —          │ —         │ Scheduled
│                                                       │
└───────────────────────────────────────────────────────┘
[View History] [Edit] [End Assignment] [Delete]

Total Assignments: 145 | Active: 142 | Scheduled: 2 | Expired: 156
```

### 3.2 Assignment Form: Single Employee

#### Section A: Employee & Shift Selection
```
┌─ SHIFT ASSIGNMENT ────────────────────────────────────┐
│                                                       │
│ Employee*              [Search: _________]           │
│                        → Shows: Name, Emp ID, Dept   │
│                        Selected: Raj Kumar (E00145)  │
│                        Dept: Academic                │
│                                                       │
│ Current Shift:         Standard (09:00-17:00)       │
│ (From 01-Jan-2026)                                  │
│                                                       │
│ Assign New Shift*      [Standard ▼]                  │
│ (Available: S1-Standard, S2-Morning, S3-Afternoon,  │
│  S4-Weekend, S5-Flexible)                          │
│                                                       │
│ [Next →]                                            │
└───────────────────────────────────────────────────────┘
```

#### Section B: Effective Dates
```
┌─ ASSIGNMENT PERIOD ───────────────────────────────────┐
│                                                       │
│ Effective From Date*   [01/01/2026] (DD/MM/YYYY)    │
│ (When shift starts for this employee)               │
│                                                       │
│ Assignment Type*       (O Regular   O Temporary      │
│                        O Contract   O Probation)     │
│                                                       │
│ Effective To Date      [________] (DD/MM/YYYY)      │
│ (Leave empty for ongoing; date to end shift)        │
│                                                       │
│ NOTE: Will auto-end previous shift assignment       │
│ Current: Standard (ends on 31-Dec-2025)             │
│ New: Morning (starts on 01-Jan-2026)                │
│                                                       │
│ [Next →]                                            │
└───────────────────────────────────────────────────────┘
```

#### Section C: Reason & Notes
```
┌─ REASON & REMARKS ────────────────────────────────────┐
│                                                       │
│ Reason for Change*     [New Joining ▼]              │
│ (Options: New Joining, Transfer, Promotion,         │
│  Request, Performance, Restructure, Other)          │
│                                                       │
│ Additional Notes       [________________________]   │
│ (e.g., "Transfer to Admin dept", "By request")     │
│                                                       │
│ [ ] Notify Employee                                  │
│ (Send email notification to employee)              │
│                                                       │
│ [← Back] [Save]                                     │
└───────────────────────────────────────────────────────┘
```

### 3.3 Bulk Assignment View

```
┌─ BULK ASSIGN SHIFT ───────────────────────────────────┐
│                                                       │
│ Shift*                 [Standard ▼]                  │
│                                                       │
│ Effective From*        [01/01/2026]                  │
│ Effective To           [________]                     │
│                                                       │
│ Reason*                [New Joining ▼]              │
│                                                       │
│ Select Employees:                                    │
│ [Search: ______________] [Select All] [Clear All]   │
│                                                       │
│ [✓] Raj Kumar (E00145)      [✓] Priya Singh (E00146)│
│ [✓] Amit Patel (E00147)     [ ] Neha Gupta (E00148) │
│ [✓] Vikram Das (E00149)     [ ] Anjali Sharma(E00150)│
│ ...                                                  │
│                                                       │
│ Selected: 5 employees                                │
│                                                       │
│ [← Back] [Assign to All] [Assign to Selected]       │
└───────────────────────────────────────────────────────┘
```

### 3.4 Assignment History View

```
┌─ SHIFT HISTORY: Raj Kumar (E00145) ──────────────────┐
│                                                       │
│ Shift      │ From Date  │ To Date    │ Status│ Reason
│─────────────────────────────────────────────────────│
│ Standard   │ 01-01-2025 │ 31-12-2025 │ Exp   │ Joining
│ Morning    │ 01-01-2026 │ —          │ Act   │ Transfer
│ [Previous] │ 15-01-2023 │ 31-12-2024 │ Exp   │ Joining
│                                                       │
└───────────────────────────────────────────────────────┘
[Export] [Print]
```

---

## 4. Input Validation Rules

### 4.1 Field Validations

| Field | Type | Validation Rule | Error Message |
|-------|------|-----------------|----------------|
| Employee | Reference | Required, must exist | Employee not found |
| Shift | Reference | Required, must exist, must be active | Shift not found or inactive |
| From Date | Date | Required, valid date | Valid date required |
| To Date | Date | Optional, ≥ From Date if provided | End date must be ≥ start date |
| Assignment Type | Enum | Required | Must specify type |
| Reason | String | Required, 1-100 chars | Reason is required |
| Status | Enum | Auto-set based on dates | N/A |
| Notify Employee | Boolean | Optional | N/A |

### 4.2 Cross-Field Validations

| Condition | Validation | Action |
|-----------|-----------|--------|
| New From Date overlaps existing active | Error | "Shift already assigned during this period" |
| To Date = From Date | Error | "Assignment must span ≥ 1 day" |
| From Date in past | Warning | "Assignment start date is in the past" |
| From Date = Today AND shift change | Info | "Shift change effective immediately" |
| From Date = Future | Status set | SCHEDULED (auto-activate on from_date) |
| To Date empty & others have future dates | Error | "Only last assignment can have no end date" |
| Duplicate assignment same dates | Error | "Shift already assigned for these dates" |

---

## 5. Business Logic & Calculations

### 5.1 Status Determination Logic

```
IF from_date > TODAY():
  status = "SCHEDULED"  (Will activate on from_date)
ELSE IF from_date ≤ TODAY() AND (to_date IS NULL OR to_date ≥ TODAY()):
  status = "ACTIVE"  (Currently in effect)
ELSE IF to_date < TODAY():
  status = "EXPIRED"  (Assignment period ended)
ELSE:
  status = "CANCELLED"  (Manually cancelled)
```

### 5.2 Active Flag Management (Critical)

```
Business Rule: Only ONE assignment per employee can have is_active_flag = true

SCENARIO 1: Assign new shift to employee
  Step 1: Find current active assignment
    SELECT * FROM sch_employee_shift_assignments 
    WHERE employee_id = ? AND is_active_flag = 1 AND deleted_at IS NULL
  
  Step 2: If found, deactivate it
    UPDATE sch_employee_shift_assignments
    SET is_active_flag = 0, effective_to = ?, updated_by = ?
    WHERE employee_id = ? AND is_active_flag = 1
  
  Step 3: Insert new assignment
    INSERT INTO sch_employee_shift_assignments (
      employee_id, shift_id, effective_from, effective_to,
      is_active_flag, status, assignment_type, reason
    ) VALUES (?, ?, ?, ?, 1, 'ACTIVE', ?, ?)

SCENARIO 2: Assignment period expires (to_date = today)
  Cron Job (daily):
    UPDATE sch_employee_shift_assignments
    SET is_active_flag = 0, status = 'EXPIRED'
    WHERE effective_to = CURDATE() AND is_active_flag = 1
```

### 5.3 Automatic Status Transitions

```
SCHEDULED → ACTIVE (on from_date via cron job):
  UPDATE sch_employee_shift_assignments
  SET status = 'ACTIVE', is_active_flag = 1
  WHERE status = 'SCHEDULED' AND effective_from = CURDATE()

ACTIVE → EXPIRED (on to_date via cron job):
  UPDATE sch_employee_shift_assignments
  SET status = 'EXPIRED', is_active_flag = 0
  WHERE status = 'ACTIVE' AND effective_to = CURDATE()
```

### 5.4 Unique Constraint Logic

```
Constraint: UNIQUE KEY (employee_id, effective_from, effective_to)

This allows:
✓ Multiple assignments for same employee (different date ranges)
✓ Non-overlapping assignments
✗ Overlapping date ranges for same employee

Example (VALID):
  Employee: Raj Kumar
  • Shift 1: 01-Jan-2025 to 31-Dec-2025
  • Shift 2: 01-Jan-2026 to NULL (ongoing)

Example (INVALID):
  Employee: Raj Kumar
  • Shift 1: 01-Jan-2026 to 31-Mar-2026
  • Shift 2: 15-Feb-2026 to 30-Apr-2026 ← OVERLAPS!
```

---

## 6. Database Operations

### 6.1 Assign Shift to Employee (with Auto-End Previous)
```sql
START TRANSACTION;

-- Step 1: Deactivate current active assignment if exists
UPDATE sch_employee_shift_assignments
SET is_active_flag = 0, effective_to = DATE_SUB(?, INTERVAL 1 DAY),
    status = 'EXPIRED', updated_by = ?, updated_at = NOW()
WHERE employee_id = ? AND is_active_flag = 1 AND deleted_at IS NULL;

-- Step 2: Insert new assignment
INSERT INTO sch_employee_shift_assignments (
    employee_id, shift_id, effective_from, effective_to,
    is_active_flag, status, assignment_type, reason,
    created_by, created_at
) VALUES (
    ?, ?,
    ?, ?,  -- from_date, to_date
    1, IF(? > CURDATE(), 'SCHEDULED', 'ACTIVE'),
    ?, ?,  -- assignment_type, reason
    ?, NOW()
);

COMMIT;
```

### 6.2 Get Current Shift for Employee
```sql
SELECT 
    esa.id, esa.shift_id, es.code, es.name,
    es.start_time, es.end_time, es.net_working_hours,
    esa.effective_from, esa.effective_to,
    esa.status, esa.is_active_flag
FROM sch_employee_shift_assignments esa
JOIN sch_employee_shifts es ON esa.shift_id = es.id
WHERE esa.employee_id = ? 
  AND esa.is_active_flag = 1 
  AND esa.deleted_at IS NULL
LIMIT 1;
```

### 6.3 Get Employees by Shift
```sql
SELECT 
    e.id, e.emp_number, e.first_name, e.last_name, e.email,
    esa.effective_from, esa.effective_to, esa.status,
    es.code, es.start_time, es.end_time
FROM sch_employee_shift_assignments esa
JOIN sch_employees e ON esa.employee_id = e.id
JOIN sch_employee_shifts es ON esa.shift_id = es.id
WHERE esa.shift_id = ? AND esa.is_active_flag = 1 
  AND esa.deleted_at IS NULL
ORDER BY e.first_name;
```

### 6.4 Get Assignment History
```sql
SELECT 
    esa.id, esa.shift_id, es.code, es.name,
    esa.effective_from, esa.effective_to,
    esa.status, esa.reason,
    esa.created_by, esa.created_at
FROM sch_employee_shift_assignments esa
JOIN sch_employee_shifts es ON esa.shift_id = es.id
WHERE esa.employee_id = ? AND esa.deleted_at IS NULL
ORDER BY esa.effective_from DESC;
```

---



## 8. Permissions & Authorization

| Permission | Admin | HR Mgr | Manager | Employee |
|-----------|-------|--------|---------|----------|
| view.assignment.list | ✓ | ✓ | ✓ | View Own |
| create.assignment | ✓ | ✓ | ✗ | ✗ |
| edit.assignment | ✓ | ✓ | ✗ | ✗ |
| delete.assignment | ✓ | ✗ | ✗ | ✗ |
| view.assignment.history | ✓ | ✓ | ✓ | View Own |
| bulk_assign.assignment | ✓ | ✓ | ✗ | ✗ |

---

## 9. Error Handling

| Error Code | HTTP | Message | Cause | Action |
|-----------|------|---------|-------|--------|
| ASSIGN-001 | 404 | Employee not found | Invalid emp ID | Check employee exists |
| ASSIGN-002 | 404 | Shift not found or inactive | Invalid shift ID | Check shift exists/active |
| ASSIGN-003 | 409 | Shift already assigned during this period | Overlapping dates | Choose different dates |
| ASSIGN-004 | 400 | End date before start date | Invalid range | Correct date range |
| ASSIGN-005 | 400 | Assignment must span ≥ 1 day | Same dates | Add span |
| ASSIGN-006 | 409 | Duplicate assignment | Already exists | No action needed |
| ASSIGN-007 | 400 | Cannot modify expired assignment | Past assignment | Create new one |

---

## 10. Testing Checklist

- [ ] Assign shift to single employee
- [ ] Bulk assign shift to multiple employees
- [ ] Verify only one active assignment per employee
- [ ] Auto-end previous shift
- [ ] Schedule future shift
- [ ] View assignment history
- [ ] Test status transitions (SCHEDULED → ACTIVE → EXPIRED)
- [ ] Get employees by shift
- [ ] Prevent overlapping assignments
- [ ] Bulk import from CSV
- [ ] Test notifications
- [ ] Verify soft delete

---

**Next Steps:** 
- Implement shift assignment CRUD
- Build employee search/selection UI
- Implement bulk assignment
- Create status auto-transition cron job
- Add shift history view
- Implement notification system

