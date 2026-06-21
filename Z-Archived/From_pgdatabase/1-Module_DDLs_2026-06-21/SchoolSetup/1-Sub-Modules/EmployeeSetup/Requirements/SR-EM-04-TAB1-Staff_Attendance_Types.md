# Screen Requirement: Staff Attendance Types Configuration
## Document ID: SR-EM-04-TAB1
**Module:** SchoolSetup / EmployeeSetup  
**Screen Name:** Staff Attendance Types (Tab 1 of Attendance Masters)  
**Route:** `school-setup.attendance-master.index?tab=attendance-types`  
**User Role:** School Administrator, HR Manager  
**Priority:** P0 (Critical)  
**Status:** Approved for Development  

---

## 1. Screen Overview

### 1.1 Purpose & Business Objective
This tab within Attendance Masters enables administrators to define and manage all attendance type categories (Present, Absent, Leave, Late, Half-Day, Holiday, etc.) that will be used for daily attendance marking. Each type has configurable behavior flags, payroll impact, and display settings.

### 1.2 Key Capabilities
- ✅ Create new attendance types with customizable codes
- ✅ Configure behavioral flags (is_present, can_be_half_day, affects_payroll)
- ✅ Set payroll impact percentage (0-100%)
- ✅ Define approval requirements
- ✅ Configure color coding for calendar display
- ✅ Manage system vs custom types
- ✅ Soft delete and restore attendance types
- ✅ Bulk export for reference

---

## 2. Data Model & DDL Reference

### 2.1 Primary Table
```sql
sch_staff_attendance_types — Attendance category definitions
├── Identification: id (INT), code (VARCHAR 10), name (VARCHAR 100)
├── Behavior: is_present (BOOL), can_be_half_day (BOOL), affects_payroll (BOOL)
├── Approval: requires_approval (BOOL)
├── Payroll: payroll_percentage (DECIMAL 5,2)
├── Category: category (ENUM: Attendance/Leave/Holiday/Other)
├── Display: color_hex (VARCHAR 7), icon_class (VARCHAR 50), display_order (INT)
├── System: is_system (BOOL) — Cannot delete if true
├── Status: is_active (BOOL), deleted_at (TIMESTAMP)
└── Audit: created_by (INT), created_at, updated_at
```

### 2.2 Related Tables
- `sys_users` — For created_by audit trail
- `sch_employee_attendance` — Uses attendance type for daily marking

---

## 3. Screen Layout & UI Components

### 3.1 List View

```
┌─ STAFF ATTENDANCE TYPES ─────────────────────────────────┐
│                                                           │
│  [+ New Type] [Import Types] [Export] [Filter]           │
│  Search: [_________] Category: [All ▼] Active: [All ▼]  │
│                                                           │
├───────────────────────────────────────────────────────────┤
│ Code │ Name      │ Category   │ Payroll% │ Half-Day │ Act
│─────────────────────────────────────────────────────────│
│ PR   │ Present   │ Attendance │ 100%     │ No       │ ✓
│ AB   │ Absent    │ Attendance │ 0%       │ No       │ ✓
│ LT   │ Late      │ Attendance │ 100%     │ Yes      │ ✓
│ HD   │ Half Day  │ Attendance │ 50%      │ Yes      │ ✓
│ LV   │ Leave     │ Leave      │ 100%     │ Yes      │ ✓
│ HO   │ Holiday   │ Holiday    │ 100%     │ No       │ ✓
│ EL   │ Earned Lv │ Leave      │ 100%     │ Yes      │ ✓
│ SL   │ Sick Lv   │ Leave      │ 100%     │ Yes      │ ✓
│ OTH  │ Other     │ Other      │ 0%       │ No       │ ✓
│                                                           │
└───────────────────────────────────────────────────────────┘
[View Details] [Edit] [View in Calendar] [Delete]

Total: 9 Types | Active: 9 | Archived: 0
```

### 3.2 Create/Edit Form

#### Section A: Basic Information
```
┌─ ATTENDANCE TYPE DETAILS ────────────────────────────────┐
│                                                           │
│  Code*              [_____] (e.g., PR, AB, LT, HD)      │
│  (2-10 chars, unique, uppercase)                        │
│                                                           │
│  Name*              [________________]                   │
│  (e.g., Present, Absent, Late, Half-Day)               │
│                                                           │
│  Category*          (O Attendance  O Leave               │
│                     O Holiday      O Other)              │
│                                                           │
│  Description        [____________________]              │
│  (Optional: brief description of type usage)            │
│                                                           │
│  [Next →]                                                │
└────────────────────────────────────────────────────────┘
```

#### Section B: Behavior Flags
```
┌─ BEHAVIOR CONFIGURATION ─────────────────────────────────┐
│                                                           │
│  [✓] Is Present (Counts toward attendance mark)         │
│  (Checked = Considered "present", Unchecked = "absent") │
│                                                           │
│  [✓] Can Be Half-Day                                     │
│  (Checked = Can mark 0.5 day, Unchecked = Full day only)│
│                                                           │
│  [✓] Affects Payroll                                     │
│  (Checked = Impacts salary, Unchecked = No effect)      │
│                                                           │
│  [  ] Requires Approval                                  │
│  (For supervisory review, e.g., Absent, Late)          │
│                                                           │
│  LOGIC EXAMPLES:                                        │
│  • Present (PR):     is_present=✓, affects_payroll=✓   │
│  • Absent (AB):      is_present=✗, affects_payroll=✓   │
│  • Half-Day (HD):    is_present=✓, can_be_half=✓       │
│  • Holiday (HO):     is_present=✓, affects_payroll=✓   │
│                                                           │
│  [Next →]                                                │
└────────────────────────────────────────────────────────┘
```

#### Section C: Payroll Configuration
```
┌─ PAYROLL IMPACT SETTINGS ───────────────────────────────┐
│                                                           │
│  Payroll Percentage*  [___]%                            │
│  (0 = No pay, 50 = Half pay, 100 = Full pay)           │
│                                                           │
│  EXAMPLES:                                              │
│  • Present (PR):       100% (full day wage)            │
│  • Half-Day (HD):      50%  (half day wage)            │
│  • Absent (AB):        0%   (no wage)                  │
│  • Late (LT):          100% (full wage - grace period) │
│  • Leave (LV):         100% (paid leave)               │
│  • Holiday (HO):       100% (paid holiday)             │
│  • Leave Without Pay:  0%   (no wage)                  │
│                                                           │
│  ℹ️ Note: Half-day = 50% of calculated payroll %       │
│                                                           │
│  [Next →]                                                │
└────────────────────────────────────────────────────────┘
```

#### Section D: Display & System Settings
```
┌─ DISPLAY SETTINGS ──────────────────────────────────────┐
│                                                           │
│  Color for Calendar*     [#______] [■ Preview]          │
│  (RGB hex: #RRGGBB, e.g., #FF5733 for red)             │
│                                                           │
│  Icon Class              [____________________]          │
│  (Font Awesome class, e.g., fas fa-check, fas fa-times)│
│                                                           │
│  Display Order           [___]                          │
│  (Sort order in dropdowns; lower = first; default: 0)  │
│                                                           │
│  [ ] Is System Type                                      │
│      (Built-in type; users cannot delete)              │
│                                                           │
│  [✓] Is Active                                          │
│                                                           │
│  [← Back] [Save]                                        │
└────────────────────────────────────────────────────────┘
```

---

## 4. Input Validation Rules

### 4.1 Validations

| Field | Type | Validation Rule | Error Message |
|-------|------|-----------------|----------------|
| Code | String | Required, 2-10 chars, unique, uppercase, alphanumeric | Code must be 2-10 uppercase characters and unique |
| Name | String | Required, 1-100 chars, no special chars | Name is required (1-100 chars) |
| Category | Enum | Required (Attendance/Leave/Holiday/Other) | Category must be selected |
| Description | Text | Optional, max 255 chars | Description must not exceed 255 chars |
| Is Present | Boolean | Required | Must specify if attendance counts as present |
| Can Be Half-Day | Boolean | Required | Must specify half-day capability |
| Affects Payroll | Boolean | Required | Must specify payroll impact |
| Requires Approval | Boolean | Optional | Toggle if supervision required |
| Payroll % | Decimal | Required, 0-100.00 | Must be between 0 and 100 |
| Color Hex | String | Optional, format #RRGGBB | Must be valid 6-digit hex color |
| Icon Class | String | Optional, max 50 chars | Font Awesome class name |
| Display Order | Integer | Optional, 0-9999 | Must be positive integer |
| Is System | Boolean | Optional (admin only) | Cannot mark custom types as system |
| Is Active | Boolean | Required | Must specify active status |

### 4.2 Cross-Field Validations

| Condition | Validation | Action |
|-----------|-----------|--------|
| is_present = false | Check affects_payroll | Warning: "Absent type usually has payroll impact" |
| payroll_percentage > 0 AND affects_payroll = false | Warn | "Payroll % set but affects_payroll is false" |
| category = Holiday | Check is_present | Holiday should typically be is_present=true |
| category = Leave | Check affects_payroll | Leave usually affects payroll or shows in reports |
| color_hex not provided | Use default | Assign random color from palette |

---

## 5. Business Logic & Calculations

### 5.1 Attendance Type Categories & Behavior

#### Category: Attendance
```
Typical Types: Present, Absent, Late, Half-Day, Work From Home
├─ is_present: Usually TRUE (counts toward present)
├─ affects_payroll: Usually TRUE
├─ can_be_half_day: Varies (Late=Yes, Absent=No)
└─ payroll_percentage: 100 (or varies for Late)
```

#### Category: Leave
```
Typical Types: Casual Leave, Sick Leave, Earned Leave, Maternity Leave
├─ is_present: TRUE (considered "present on leave")
├─ affects_payroll: Usually TRUE (paid leave)
├─ can_be_half_day: TRUE
├─ payroll_percentage: Usually 100 or 0 (for LWP)
└─ Note: References sch_staff_leave_types for detailed rules
```

#### Category: Holiday
```
Typical Types: Weekend, Public Holiday, School Holiday
├─ is_present: TRUE (no mark needed; auto-filled)
├─ affects_payroll: TRUE (paid holiday)
├─ can_be_half_day: FALSE
├─ payroll_percentage: 100
└─ Note: Cannot be manually marked; auto-applied from calendar
```

#### Category: Other
```
For miscellaneous types (Vacation, Training, Conference, etc.)
├─ is_present: Usually FALSE
├─ affects_payroll: Configurable
├─ can_be_half_day: Configurable
└─ payroll_percentage: Configurable (0-100)
```

### 5.2 Default Values
- `display_order` = 100 (if not specified)
- `color_hex` = Random from palette (if not specified)
- `is_active` = true (on creation)
- `is_system` = false (unless marked by admin)
- `created_by` = current_user_id
- `created_at` = CURRENT_TIMESTAMP

### 5.3 System Types (Cannot Edit/Delete)
```
Standard system types that schools typically need:
├─ PR  (Present)
├─ AB  (Absent)
├─ LT  (Late)
├─ HD  (Half-Day)
├─ HO  (Holiday)
├─ LV  (Leave)
└─ WFH (Work From Home)

Once marked is_system=true, users cannot:
• Delete the type
• Change core fields
• Mark as inactive (can only archive)
```

---



## 8. Permissions & Authorization

### 8.1 Role-Based Permissions

| Permission | Admin | HR Mgr | Manager | Employee |
|-----------|-------|--------|---------|----------|
| view.attendance_type.list | ✓ | ✓ | ✓ | ✓ |
| create.attendance_type | ✓ | ✓ | ✗ | ✗ |
| edit.attendance_type | ✓ | ✓ | ✗ | ✗ |
| delete.attendance_type | ✓ | ✗ | ✗ | ✗ |
| edit.system_type | ✓ only | — | — | — |

### 8.2 Field-Level Permissions
- **Payroll %:** Only Admin/HR can view/edit
- **Is System:** Only Super-Admin can set
- **Color/Icon:** All admins can edit

---

## 9. Error Handling

### 9.1 Common Error Scenarios

| Error Code | HTTP | Message | Cause | Action |
|-----------|------|---------|-------|--------|
| ATT-001 | 400 | Code already exists | Duplicate code | Use unique code |
| ATT-002 | 400 | Invalid payroll percentage | Value > 100 or < 0 | Enter 0-100 |
| ATT-003 | 404 | Attendance type not found | ID doesn't exist | Check ID |
| ATT-004 | 403 | Cannot edit system type | Trying to modify built-in | Contact admin |
| ATT-005 | 409 | Cannot delete; used in attendance records | Active usage | Archive instead |
| ATT-006 | 400 | Invalid hex color | Bad format | Use #RRGGBB format |

---

## 10. Testing Checklist

- [ ] Create standard types (PR, AB, LT, HD, HO)
- [ ] Validate unique attendance code
- [ ] Set payroll percentage (0, 50, 100)
- [ ] Configure color coding
- [ ] Test half-day enable/disable
- [ ] Prevent deletion of system types
- [ ] Soft delete and restore
- [ ] Verify payroll percentage logic
- [ ] Export types list
- [ ] Permission restrictions

---

**Next Steps:** 
- Implement CRUD operations
- Build form with validation
- Create color picker UI
- Add bulk import for standard types
- Implement soft delete with restore

