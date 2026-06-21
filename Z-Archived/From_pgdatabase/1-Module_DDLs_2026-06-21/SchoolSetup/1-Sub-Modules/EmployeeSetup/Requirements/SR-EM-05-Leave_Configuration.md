# Screen Requirement: Leave Configuration (Role/Department Based)
## Document ID: SR-EM-05
**Module:** SchoolSetup / EmployeeSetup  
**Screen Name:** Staff Leave Config (Entitlement Configuration)  
**Route:** `school-setup.leave-config.index`  
**User Role:** School Administrator, HR Manager  
**Priority:** P0 (Critical)  
**Status:** Approved for Development  

---

## 1. Screen Overview

### 1.1 Purpose & Business Objective
This screen defines role- and department-specific leave entitlements that drive year-round leave allocation and carry-forward behavior. It allows schools to differentiate leave policies for teachers vs administrators, or by department, ensuring compliance with employment contracts and school policies.

### 1.2 Key Capabilities
- ✅ Define leave entitlements by role, department, designation, and employment type
- ✅ Configure annual allocation and accrual methods (Lump Sum, Monthly Pro-Rata, Quarterly)
- ✅ Set probation-period leave behavior (available during probation or not)
- ✅ Manage priority-based policy matching (most specific = highest priority)
- ✅ Configure carry-forward and encashment overrides per policy
- ✅ Preview policy matching for employees
- ✅ Bulk apply policies to multiple employee groups

---

## 2. Data Model & DDL References

### 2.1 Primary Table
```sql
sch_staff_leave_config — Role/Dept/Designation-based leave entitlements
├── Policy Matching: 
│   ├─ applies_to_role_id (FK, nullable = all roles)
│   ├─ applies_to_department_id (FK, nullable = all depts)
│   ├─ applies_to_designation_id (FK, nullable = all desigs)
│   └─ applies_to_employment_type (ENUM: Permanent/Contract/Temp/etc)
├── Entitlement:
│   ├─ leave_type_id (FK to sch_staff_leave_types)
│   ├─ annual_entitlement (days per year)
│   ├─ accrual_method (Lump_Sum / Monthly_Pro_Rata / Quarterly)
│   └─ accrual_start_offset_months (wait N months before accrual starts)
├── Probation Rules:
│   ├─ available_during_probation
│   └─ probation_entitlement_pro_rata
├── Carry-Forward Override:
│   ├─ is_carry_forwardable
│   └─ max_carry_forward
├── Encashment Override:
│   ├─ is_encashable_at_separation
│   └─ max_encashable_days
└── Priority: priority (lower = higher priority)
```

### 2.2 Related Tables
- `sch_staff_leave_types` — Leave types referenced
- `sch_employee_roles` — Role master
- `sch_departments` — Department master
- `sch_designations` — Designation master
- `sch_employees` — For preview/testing

---

## 3. Screen Layout & UI Components

### 3.1 List View with Policy Matrix

```
┌─ LEAVE CONFIGURATION (Role/Department Based) ──────┐
│                                                     │
│  [+ New Policy] [Preview for Employee] [Export]   │
│  Leave Type: [▼ All] Department: [▼ All]          │
│  Priority Filter: [All ▼]                          │
│                                                     │
├─────────────────────────────────────────────────────┤
│Policy │ Leave   │ Role      │ Dept │ Ent │ Accrual │
│ID     │ Type    │           │      │Days │ Method  │
├─────────────────────────────────────────────────────┤
│ 1     │ CL      │ All       │ All  │ 12  │ Lump Sum
│ 2     │ CL      │ Teacher   │ All  │ 14  │ Lump Sum
│ 3     │ CL      │ Teacher   │ Sc   │ 16  │ L.Sum
│ 4     │ EL      │ All       │ All  │ 20  │ M.Pro-R
│ 5     │ EL      │ Admin     │ All  │ 18  │ M.Pro-R
│ 6     │ SL      │ All       │ All  │ 10  │ Lump Sum
│ 7     │ ML      │ All       │ All  │ 90  │ Lump Sum
│ 8     │ PL      │ All       │ All  │ 60  │ Lump Sum
└─────────────────────────────────────────────────────┘
[View Details] [Edit] [Duplicate] [Delete]

Priority Note: More specific matches override general policies.
E.g., "Teacher + Science Dept" overrides "All + Science Dept"
```

### 3.2 Create/Edit Policy Form (Wizard)

#### Step 1: Leave Type & Scope Selection
```
┌─ SELECT LEAVE TYPE & SCOPE ────────────────────────┐
│                                                     │
│  Leave Type*        [▼ Select Leave Type]         │
│  (e.g., CL, SL, EL, ML, PL, LWP)                │
│                                                     │
│  Policy Scope (Select filters, leave blank=All):   │
│                                                     │
│  Applies to Role*   [▼ All Roles]                 │
│  (Select specific role or leave blank for all)   │
│                                                     │
│  Applies to Dept    [▼ All Departments]           │
│                                                    │
│  Applies to Desig   [▼ All Designations]          │
│                                                    │
│  Employment Type    [▼ All Types]                 │
│  (Permanent / Contract / Temporary / etc)         │
│                                                    │
│  ⓘ Policy Matching: More specific combinations    │
│     take priority. E.g., "Teacher+Science Dept"  │
│     overrides "All+Science Dept"                 │
│                                                    │
│  [Next →]                                         │
└────────────────────────────────────────────────────┘
```

#### Step 2: Annual Entitlement & Accrual
```
┌─ ENTITLEMENT & ACCRUAL CONFIGURATION ──────────────┐
│                                                     │
│  Annual Entitlement*  [___] days per year         │
│  (Total days granted per academic/calendar year) │
│                                                     │
│  Accrual Method*      (O Lump_Sum                 │
│                       O Monthly_Pro_Rata          │
│                       O Quarterly)                │
│                                                     │
│  ACCRUAL METHOD EXPLANATION:                      │
│  • Lump Sum: All days on Jan 1 (or year-start)   │
│  • Monthly Pro-Rata: entitlement/12 per month    │
│  • Quarterly: entitlement/4 per quarter          │
│                                                     │
│  Accrual Start Offset [___] months                │
│  (Wait N months from joining before accrual)     │
│  (E.g., 3 months for probation period)           │
│                                                     │
│  Examples:                                       │
│  - CL: 12 days, Lump Sum, offset 0               │
│  - EL: 20 days, Monthly Pro-Rata, offset 0       │
│  - ML: 90 days, Lump Sum, offset 0               │
│                                                     │
│  [Next →]                                         │
└────────────────────────────────────────────────────┘
```

#### Step 3: Probation Behavior
```
┌─ PROBATION PERIOD BEHAVIOR ────────────────────────┐
│                                                     │
│  [ ] Available During Probation                    │
│      (Can employee take this leave while in        │
│       probation period? e.g., CL=No, EL=Yes)     │
│                                                     │
│  [ ] Pro-Rata During Probation                     │
│      (If available, is it pro-rated based on       │
│       probation duration?)                        │
│                                                     │
│  EXAMPLES:                                        │
│  • CL: NOT available during probation             │
│  • EL: Available but PRO-RATA during probation    │
│  • SL: Available FULL during probation            │
│                                                     │
│  [Next →]                                         │
└────────────────────────────────────────────────────┘
```

#### Step 4: Carry-Forward & Encashment Overrides
```
┌─ CARRY-FORWARD & ENCASHMENT OVERRIDES ─────────────┐
│                                                     │
│  [ ] Is Carry-Forwardable                          │
│      (Override leave type setting if checked)     │
│                                                     │
│  IF checked:                                      │
│    Max Carry Forward  [___] days                  │
│                                                     │
│  [ ] Is Encashable at Separation                   │
│      (Override leave type setting if checked)     │
│                                                     │
│  IF checked:                                      │
│    Max Encashable Days [___] days                 │
│                                                     │
│  OVERRIDE LOGIC:                                  │
│  Config setting > Leave Type setting              │
│  (If configured here, it takes precedence)       │
│                                                     │
│  [Next →]                                         │
└────────────────────────────────────────────────────┘
```

#### Step 5: Priority & Review
```
┌─ PRIORITY & REVIEW ────────────────────────────────┐
│                                                     │
│  Priority*          [___] (1-10, lower=higher)    │
│  (When multiple policies match, lower priority    │
│   number applies first)                          │
│                                                     │
│  MATCHING EXAMPLE:                                │
│  Employee: John Doe, Teacher, Science Dept       │
│                                                     │
│  Matching Policies (in priority order):          │
│  1. Teacher + Science (Priority 1) → 16 CL days  │
│  2. Teacher + All (Priority 5) → 14 CL days      │
│  3. All + All (Priority 10) → 12 CL days         │
│  → APPLIED: 16 CL days (highest priority)        │
│                                                     │
│  [ ] Is Active                                     │
│                                                     │
│  [REVIEW SUMMARY]                                 │
│  Leave Type: CL (Casual Leave)                    │
│  Scope: Teacher / Science Department              │
│  Annual Entitlement: 16 days                      │
│  Accrual: Lump Sum, Year-start                    │
│  Carry-Forward: 5 days max (from type)            │
│  Encashment@Sep: Yes, 16 days max                 │
│                                                     │
│  [← Back] [Save]                                  │
└────────────────────────────────────────────────────┘
```

### 3.3 Preview for Employee
```
┌─ PREVIEW POLICY FOR EMPLOYEE ──────────────────────┐
│                                                     │
│  Select Employee: [▼ Search: John...]            │
│  (Selected: John Doe - Teacher, Science Dept)    │
│                                                     │
│  Employment Type: Permanent                       │
│  Date of Joining: 01/01/2024                      │
│                                                     │
├─────────────────────────────────────────────────────┤
│ Leave Type │ Annual │ Carry-Fwd │ Encash@Sep │Notes
│ CL         │ 16    │ 5        │ Yes, 16   │ Policy:1
│ SL         │ 10    │ No       │ No        │ Policy:2
│ EL         │ 22    │ 10       │ Yes, 22   │ Policy:3
│ ML         │ 90    │ No       │ Yes, 30   │ Type:ML
│ LWP        │ Nego  │ No       │ No        │ Type:LWP
└─────────────────────────────────────────────────────┘

[Note: Teacher + Science Dept has highest priority,
overriding "All + All" and "Teacher + All" policies]

[Close]
```

---

## 4. Input Validation Rules

### 4.1 Validations

| Field | Type | Validation Rule | Error Message |
|-------|------|-----------------|----------------|
| Leave Type | FK | Required, must exist | Leave type must be selected |
| Applies to Role | FK | Optional, must exist if provided | Role must be valid |
| Applies to Dept | FK | Optional, must exist if provided | Department must be valid |
| Applies to Desig | FK | Optional, must exist if provided | Designation must be valid |
| Applies to Emp Type | Enum | Optional | Employment type, if provided, must be valid |
| Annual Entitlement | Decimal | Required, 0-365 days | Must be 0-365 days |
| Accrual Method | Enum | Required (Lump_Sum/M_Pro_Rata/Quarterly) | Accrual method must be selected |
| Accrual Offset | Integer | Required, 0-12 months | Must be 0-12 months |
| Available During Probation | Boolean | Optional | Toggle |
| Probation Pro-Rata | Boolean | Optional | Toggle |
| Is Carry Forwardable | Boolean | Optional | Toggle |
| Max Carry Forward | Decimal | If carry=true: optional, > 0 | Must be > 0 if specified |
| Is Encashable at Separation | Boolean | Optional | Toggle |
| Max Encashable Days | Decimal | If encash=true: optional, > 0 | Must be > 0 if specified |
| Priority | Integer | Required, 1-100 | Must be 1-100 |
| Is Active | Boolean | Required | Must specify |

### 4.2 Cross-Field Validations

| Condition | Validation | Action |
|-----------|-----------|--------|
| All scope fields null | Warning shown | "This applies to ALL employees" |
| Combination exists | Error raised | Cannot create duplicate (same leave type + scope) |
| Priority conflict | Auto-adjust | Re-number conflicting priorities |
| Scope too restrictive | Warn | "No employees match this scope" |

---

## 5. Business Logic & Calculations

### 5.1 Policy Matching Algorithm

```
FUNCTION: Get_Applicable_Policy(employee, leave_type)
    
    CANDIDATES = []
    
    FOR EACH config IN sch_staff_leave_config:
        IF config.leave_type_id != leave_type.id:
            CONTINUE
        
        IF config.applies_to_role_id IS NOT NULL:
            IF config.applies_to_role_id != employee.role_id:
                CONTINUE
        
        IF config.applies_to_department_id IS NOT NULL:
            IF config.applies_to_department_id != employee.dept_id:
                CONTINUE
        
        IF config.applies_to_designation_id IS NOT NULL:
            IF config.applies_to_designation_id != employee.desig_id:
                CONTINUE
        
        IF config.applies_to_employment_type IS NOT NULL:
            IF config.applies_to_employment_type != employee.emp_type:
                CONTINUE
        
        CANDIDATES.add(config)
    
    RESULT = CANDIDATES.sort_by('priority').first
    
    IF RESULT IS NULL:
        RETURN: Leave_Type.default_policy  (fallback)
    ELSE:
        RETURN: RESULT
```

### 5.2 Accrual Calculation

#### Lump Sum
```
IF accrual_method = 'Lump_Sum':
    accrued_days = annual_entitlement  (on year start)
    per_month = 0
```

#### Monthly Pro-Rata
```
IF accrual_method = 'Monthly_Pro_Rata':
    accrued_days = (annual_entitlement / 12) per month
    cumulative = accrued_days * months_employed
```

#### Quarterly
```
IF accrual_method = 'Quarterly':
    accrued_days = (annual_entitlement / 4) per quarter
    cumulative = accrued_days * quarters_employed
```

#### Probation Pro-Rata
```
IF employee.in_probation AND config.probation_entitlement_pro_rata:
    probation_entitlement = annual_entitlement * (probation_months_elapsed / probation_total_months)
    ELSE IF employee.in_probation AND NOT config.available_during_probation:
        entitlement = 0
    ELSE:
        entitlement = annual_entitlement
```

---

## 6. Database Operations

### 6.1 Create Leave Config
```sql
INSERT INTO sch_staff_leave_config (
    leave_type_id, applies_to_role_id, applies_to_department_id,
    applies_to_designation_id, applies_to_employment_type,
    annual_entitlement, accrual_method, accrual_start_offset_months,
    is_carry_forwardable, max_carry_forward,
    is_encashable_at_separation, max_encashable_days,
    available_during_probation, probation_entitlement_pro_rata,
    priority, is_active, created_by
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?);
```

### 6.2 Get Policy for Employee
```sql
SELECT * FROM sch_staff_leave_config slc
WHERE slc.leave_type_id = ?
  AND (slc.applies_to_role_id IS NULL OR slc.applies_to_role_id = ?)
  AND (slc.applies_to_department_id IS NULL OR slc.applies_to_department_id = ?)
  AND (slc.applies_to_designation_id IS NULL OR slc.applies_to_designation_id = ?)
  AND (slc.applies_to_employment_type IS NULL OR slc.applies_to_employment_type = ?)
  AND slc.is_active = 1 AND slc.deleted_at IS NULL
ORDER BY slc.priority ASC
LIMIT 1;
```

---



## 8. Testing Checklist

- [ ] Create policy with all scope combinations
- [ ] Test policy matching for different employees
- [ ] Validate priority-based matching
- [ ] Test accrual calculations (all methods)
- [ ] Test probation pro-rata logic
- [ ] Test carry-forward overrides
- [ ] Test encashment at separation overrides
- [ ] Verify no duplicate policies created
- [ ] Export policies
- [ ] Test permission restrictions

---

**Next Steps:** 
- Implement CRUD operations with step wizard
- Build policy matching algorithm
- Create preview functionality
- Add bulk policy assignment
- Implement audit trail

