# Screen Requirement: Leave Type Configuration
## Document ID: SR-EM-06
**Module:** SchoolSetup / EmployeeSetup  
**Screen Name:** Leave Type Configuration  
**Route:** `school-setup.leave-type.index`  
**User Role:** School Administrator, HR Manager  
**Priority:** P0 (Critical)  
**Status:** Approved for Development  

---

## 1. Screen Overview

### 1.1 Purpose & Business Objective
This screen defines the master list of leave types (Casual Leave, Sick Leave, Earned Leave, Maternity Leave, Paternity Leave, Lieu Leave, Leave Without Pay, etc.) with their behavior flags and rules that govern how each leave type operates across the school.

### 1.2 Key Capabilities
- ✅ Create and manage leave type master
- ✅ Configure leave type behavior (paid/unpaid, carry-forward, encashment)
- ✅ Set documentation requirements (medical cert for Sick Leave)
- ✅ Configure leave constraints (min/max days, advance notice, consecutive days)
- ✅ Define half-day and back-dated leave eligibility
- ✅ Configure approval requirements per leave type
- ✅ Set color coding for calendar display

---

## 2. Data Model & DDL References

### 2.1 Primary Table
```sql
sch_staff_leave_types — Master definition of leave categories
├── Identification: code (unique), name, description
├── Financial: is_paid, payroll_percentage
├── Carry-Forward: is_carry_forwardable, max_carry_forward
├── Encashment: is_encashable, max_encashable_days
├── Separation: is_encashable_at_separation, max_encashable_days
├── Documentation: requires_doc, min_doc_required_days
├── Constraints: min_days_per_application, max_days_per_application
├── Timing: min_advance_notice_days, max_consecutive_days
├── Features: allows_half_day, allows_back_dated, requires_substitute
├── Display: color_hex, display_order
└── Status: is_system, is_active
```

### 2.2 Related Tables
- `sch_staff_leave_config` — Role/department-based entitlements (references this table)
- `sch_employee_leave_applications` — Leave requests (uses this table)
- `sch_leave_approval_policies` — Approval workflows (can reference this table)

---

## 3. Screen Layout & UI Components

### 3.1 List View

```
┌─ Leave Type Master ────────────────────────────────┐
│                                                    │
│  [+ New Leave Type] [Import] [Export]             │
│  Search: [_________] Active: [All ▼]              │
│                                                    │
├────────────────────────────────────────────────────┤
│Code │ Name     │ Paid │ Carry │ Encash │ Half-Day│
│ CL  │ Casual   │ Yes  │ No    │ Yes    │ Yes    │
│ SL  │ Sick     │ Yes  │ No    │ No     │ Yes    │
│ EL  │ Earned   │ Yes  │ Yes   │ Yes    │ Yes    │
│ ML  │ Maternity│ Yes  │ No    │ Yes@Sep│ No     │
│ LWP │ Leave W/o│ No   │ No    │ No     │ No     │
│     │ Pay     │      │       │        │        │
└────────────────────────────────────────────────────┘
[Edit] [View Details] [Delete]

Page: 1 of 1  |  Total: 5 Leave Types
```

### 3.2 Create/Edit Form (Multi-Section)

#### Section A: Basic Information
```
┌─ LEAVE TYPE DETAILS ────────────────────────────┐
│                                                  │
│  Code*              [_____________]             │
│  (e.g., CL, SL, EL, ML, PL, LWP, COMP)       │
│                                                  │
│  Name*              [_____________]             │
│  Description        [_______________]           │
│                                                  │
│  [Next →]                                       │
└──────────────────────────────────────────────────┘
```

#### Section B: Financial Configuration
```
┌─ FINANCIAL CONFIGURATION ──────────────────────┐
│                                                  │
│  [ ] Is Paid Leave                             │
│      (Checked = Paid, Unchecked = Unpaid)      │
│                                                  │
│  [ ] Is Encashable at Year-End                 │
│      (Can unused leave be paid out)            │
│                                                  │
│  [ ] Is Encashable at Separation               │
│      (Can leave be encashed on exit)           │
│                                                  │
│  [ ] Requires Substitute Teacher Assignment     │
│      (For teaching staff; auto-trigger subst) │
│                                                  │
│  [Next →]                                       │
└──────────────────────────────────────────────────┘
```

#### Section C: Carry-Forward Rules
```
┌─ CARRY-FORWARD CONFIGURATION ──────────────────┐
│                                                  │
│  [ ] Is Carry-Forwardable                       │
│      (Can unused leave carry to next year)    │
│                                                  │
│  IF checked:                                    │
│    Maximum Carry Forward  [___] days            │
│    (NULL = No limit)                           │
│                                                  │
│    Example:                                    │
│    - EL: 10 days carry-forward allowed         │
│    - CL: 5 days carry-forward allowed          │
│                                                  │
│  [Next →]                                       │
└──────────────────────────────────────────────────┘
```

#### Section D: Encashment at Separation
```
┌─ ENCASHMENT AT SEPARATION ─────────────────────┐
│                                                  │
│  [ ] Encashable at Separation                   │
│      (When employee resigns/retires)           │
│                                                  │
│  IF checked:                                    │
│    Maximum Encashable Days  [___] days          │
│    (NULL = No limit; e.g., ML max: 90)        │
│                                                  │
│  Examples:                                     │
│  - EL: All unused days encashable at sep       │
│  - ML: Max 30 days encashable at sep           │
│  - LWP: Not encashable (leave checked)        │
│                                                  │
│  [Next →]                                       │
└──────────────────────────────────────────────────┘
```

#### Section E: Documentation Requirements
```
┌─ DOCUMENTATION REQUIREMENTS ───────────────────┐
│                                                  │
│  [ ] Requires Documentation/Certificate         │
│      (E.g., medical cert for Sick Leave)      │
│                                                  │
│  IF checked:                                    │
│    Min Days for Document  [___] days            │
│    (Require doc only if leave > N days)        │
│                                                  │
│  Examples:                                     │
│  - SL: Requires doc if > 2 days                │
│  - ML: Requires medical cert always            │
│  - CL: No doc required                         │
│                                                  │
│  [Next →]                                       │
└──────────────────────────────────────────────────┘
```

#### Section F: Leave Constraints
```
┌─ LEAVE CONSTRAINTS ────────────────────────────┐
│                                                  │
│  Minimum Days per Application  [___] days       │
│  (Minimum that can be applied; e.g., 0.5 = HF)│
│                                                  │
│  Maximum Days per Application  [___] days      │
│  (NULL = No limit; e.g., ML max: 90)         │
│                                                  │
│  Min Advance Notice Required  [___] days       │
│  (Must apply N days in advance)               │
│                                                  │
│  Max Consecutive Days  [___] days              │
│  (NULL = No limit; e.g., EL: 30 consecutive) │
│                                                  │
│  [? Help: These apply globally unless          │
│     overridden by role/department config]      │
│                                                  │
│  [Next →]                                       │
└──────────────────────────────────────────────────┘
```

#### Section G: Feature Flags
```
┌─ FEATURE FLAGS ────────────────────────────────┐
│                                                  │
│  [✓] Allows Half-Day Leave                      │
│      (Can mark as 0.5 day, full day = 1.0)    │
│                                                  │
│  [ ] Allows Back-Dated Application              │
│      (Can apply for past dates; e.g., Sick)   │
│                                                  │
│  [✓] Requires Approval                          │
│      (Need supervisor approval)                │
│                                                  │
│  [Next →]                                       │
└──────────────────────────────────────────────────┘
```

#### Section H: Display & System Settings
```
┌─ DISPLAY SETTINGS ─────────────────────────────┐
│                                                  │
│  Color for Calendar*    [#_____] [■ Preview]  │
│  (RGB hex; e.g., #FF5733 for Sick Leave)     │
│                                                  │
│  Display Order          [___]                   │
│  (Sort order in dropdowns; lower = first)     │
│                                                  │
│  [ ] Is System Leave Type                       │
│      (Built-in; cannot be deleted by users)   │
│                                                  │
│  [✓] Is Active                                  │
│                                                  │
│  [← Back] [Save]                               │
└──────────────────────────────────────────────────┘
```

---

## 4. Input Validation Rules

### 4.1 Validations

| Field | Type | Validation Rule | Error Message |
|-------|------|-----------------|----------------|
| Code | String | Required, 2-20 chars, unique, uppercase | Code must be 2-20 chars and unique |
| Name | String | Required, 1-100 chars | Name is required |
| Description | Text | Optional, max 500 chars | Max 500 chars |
| Is Paid | Boolean | Required | Must specify |
| Is Carry Forwardable | Boolean | Optional | Toggle |
| Max Carry Forward | Decimal | If is_carry_forward=true: required, 0-365 | Must be > 0 if carry-forward enabled |
| Is Encashable | Boolean | Optional | Toggle |
| Is Encashable at Separation | Boolean | Optional | Toggle |
| Max Encashable Days | Decimal | If enabled: optional, > 0 | Must be > 0 if specified |
| Requires Doc | Boolean | Optional | Toggle |
| Min Doc Required Days | Integer | If requires_doc=true: optional, >= 1 | Must be >= 1 if specified |
| Requires Substitute | Boolean | Optional | Toggle |
| Allows Half-Day | Boolean | Required | Must specify |
| Allows Back-Dated | Boolean | Required | Must specify |
| Requires Approval | Boolean | Required | Must specify |
| Min Days per App | Decimal | Required, 0.5-365 | Must be 0.5 or greater |
| Max Days per App | Decimal | Optional, if provided: > min_days | Must be >= min_days_per_application |
| Min Advance Notice | Integer | Optional, 0-365 | Days to advance |
| Max Consecutive | Integer | Optional, >= min_days | Must be >= min_days_per_application |
| Color Hex | String | Optional, format #RRGGBB | Must be valid hex color |
| Display Order | Integer | Optional, 0-9999 | Sort order |
| Is System | Boolean | Optional | Cannot delete if true |
| Is Active | Boolean | Required | Must specify |

### 4.2 Cross-Field Validations

| Condition | Validation | Action |
|-----------|-----------|--------|
| is_carry_forwardable=true | max_carry_forward required | Show error if null |
| is_encashable_at_separation=true | max_encashable_days optional | Can be null (unlimited) |
| requires_doc=true | min_doc_required_days optional | Can be null (always required) |
| max_days_per_application < min_days_per_application | Error raised | Max must be >= Min |
| allows_half_day=true | min_days can be 0.5 | Enables fractional days |
| allows_back_dated=true | Warn risk | Show: "Back-dated leaves require verification" |

---

## 5. Business Logic & Calculations

### 5.1 Leave Type Usage Scenarios

#### Standard Leave Types (Indian Schools)
```
CL (Casual Leave)
├─ Paid: Yes, Carry-forward: 5-10 days, Encashable: Yes
├─ Approval: Required, Half-day: Yes
├─ Min advance: 1 day, Max consecutive: No limit
└─ Color: #FFD700 (Gold)

SL (Sick Leave)
├─ Paid: Yes, Carry-forward: No, Encashable: No
├─ Approval: Required, Half-day: Yes
├─ Back-dated: Yes (up to 2 days), Min doc: 3 days
├─ Min advance: 0 (no advance), Max consecutive: 30 days
└─ Color: #FF6B6B (Red)

EL (Earned Leave)
├─ Paid: Yes, Carry-forward: Yes (10 days), Encashable: Yes
├─ Approval: Required, Half-day: Yes
├─ Min advance: 15 days, Max consecutive: 30 days
└─ Color: #4ECDC4 (Cyan)

ML (Maternity Leave)
├─ Paid: Yes, Encashable@Separation: Yes (30 days max)
├─ Approval: Required, Half-day: No
├─ Min advance: 0, Max consecutive: 90 days (typically)
└─ Color: #FF69B4 (Pink)

LWP (Leave Without Pay)
├─ Paid: No, Carry-forward: No, Encashable: No
├─ Approval: Required, Half-day: No
├─ No constraints (negotiated per case)
└─ Color: #808080 (Gray)
```

### 5.2 Validation Logic
```
FUNCTION: Validate_Leave_Application(leave_app_days, leave_type)
    
    # Check minimum days per application
    IF leave_app_days < leave_type.min_days_per_application:
        RAISE ERROR: "Minimum {min_days} days required"
    
    # Check maximum days per application
    IF leave_type.max_days_per_application IS NOT NULL:
        IF leave_app_days > leave_type.max_days_per_application:
            RAISE ERROR: "Maximum {max_days} days allowed"
    
    # Check consecutive days limit
    IF leave_type.max_consecutive_days IS NOT NULL:
        IF leave_app_days > leave_type.max_consecutive_days:
            RAISE ERROR: "Cannot take > {max_consec} consecutive days"
    
    # Check advance notice
    IF leave_type.min_advance_notice_days > 0:
        days_in_advance = application_date - leave_start_date
        IF days_in_advance < leave_type.min_advance_notice_days:
            RAISE ERROR: "Minimum {advance} days notice required"
    
    # Check balance availability (not in this function, but in approval)
    
    RETURN: VALID
```

---

## 6. Database Operations

### 6.1 Create Leave Type
```sql
INSERT INTO sch_staff_leave_types (
    code, name, description,
    is_paid, is_carry_forwardable, max_carry_forward,
    is_encashable, is_encashable_at_separation, max_encashable_days,
    requires_doc, min_doc_required_days,
    requires_substitute, allows_half_day, allows_back_dated,
    requires_approval, min_days_per_application,
    max_days_per_application, min_advance_notice_days,
    max_consecutive_days, color_hex, display_order,
    is_system, is_active, created_by
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 1, ?);
```

### 6.2 Update Leave Type
```sql
UPDATE sch_staff_leave_types
SET name=?, description=?, is_paid=?, is_carry_forwardable=?,
    max_carry_forward=?, is_encashable=?, requires_doc=?,
    min_days_per_application=?, max_days_per_application=?,
    min_advance_notice_days=?, max_consecutive_days=?,
    allows_half_day=?, allows_back_dated=?, requires_approval=?,
    color_hex=?, display_order=?, is_active=?,
    updated_by=?, updated_at=NOW()
WHERE id=? AND is_system=0;  -- Cannot edit system types
```

### 6.3 Get All Active Leave Types
```sql
SELECT id, code, name, is_paid, max_days_per_application,
       min_advance_notice_days, color_hex
FROM sch_staff_leave_types
WHERE is_active=1 AND deleted_at IS NULL
ORDER BY display_order, name;
```

---



## 8. Permissions & Authorization

### 8.1 Role-Based Permissions

| Permission | Admin | HR Mgr | Manager | Employee |
|-----------|-------|--------|---------|----------|
| view.leave_type.list | ✓ | ✓ | ✓ | ✓ |
| create.leave_type | ✓ | ✓ | ✗ | ✗ |
| edit.leave_type | ✓ | ✓ | ✗ | ✗ |
| delete.leave_type (soft) | ✓ | ✗ | ✗ | ✗ |

---

## 9. Error Handling

### 9.1 Common Errors

| Error Code | HTTP | Message | Action |
|-----------|------|---------|--------|
| LTYPE-001 | 400 | Leave type code already exists | Use unique code |
| LTYPE-002 | 400 | Max days must be >= min days | Fix constraint |
| LTYPE-003 | 400 | Cannot edit system leave type | Contact admin |
| LTYPE-004 | 404 | Leave type not found | Check ID |
| LTYPE-005 | 409 | Cannot delete; used in applications | Archive instead |

---

## 10. Testing Checklist

- [ ] Create standard leave types (CL, SL, EL, ML, PL, LWP)
- [ ] Validate carry-forward configuration
- [ ] Validate encashment rules
- [ ] Validate constraints (min/max days, advance notice)
- [ ] Test half-day enable/disable
- [ ] Test back-dated leave flag
- [ ] Test color picker
- [ ] Verify system leave types cannot be edited
- [ ] Test archive (soft delete)

---

**Next Steps:** 
- Implement CRUD operations
- Build form with step-by-step wizard
- Add validation logic
- Create role-based access control
- Implement bulk import for standard types

