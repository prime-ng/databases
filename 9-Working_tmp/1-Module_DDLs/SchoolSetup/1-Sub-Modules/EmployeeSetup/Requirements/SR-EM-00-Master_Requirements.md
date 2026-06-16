# Employee Setup Module — Comprehensive Functional Requirements
## Master Requirements Document (v5.0)

**Document ID:** SR-EM-00  
**Module:** SchoolSetup / EmployeeSetup  
**Version:** 5.0 (Final)  
**Date:** May 2026  
**Status:** Approved for Development  

---

## 1. Module Overview

### 1.1 Purpose & Scope
The **Employee Setup Module** provides comprehensive management of school personnel throughout their employment lifecycle, from hiring and onboarding through retirement. It encompasses role-based configuration, shift management, attendance tracking, and comprehensive leave management aligned with Indian labor laws and school-specific policies.

### 1.2 Core Functional Areas
1. **Employee Creation & Profile Management** — Comprehensive employee master data
2. **Role & Designation Configuration** — Hierarchical organization structure
3. **Shift & Working Hour Configuration** — Flexible work schedules with grace periods
4. **Attendance Type Masters** — Configurable attendance categories with payroll impact
5. **Leave Type Configuration** — Leave category definitions with carry-forward and encashment rules
6. **Leave Policy & Entitlement** — Role/department-based leave allocation
7. **Approval Workflows** — Multi-level leave approval pipelines
8. **Employee Leave Balances** — Automatic balance calculation and carry-forward
9. **Holiday Calendar Management** — School-specific holiday definitions
10. **Employee Transfer & Promotion Lifecycle** — Career progression tracking
11. **Employee Reports & Analytics** — Comprehensive reporting on attendance, leave, and utilization

### 1.3 Stakeholders & Permissions
- **School Administrator** — Full access to all configuration and employee records
- **HR Manager** — Leave approval, employee records, policy configuration
- **Reporting Manager** — Leave approval for direct reports, attendance marking
- **Employee** — Self-service leave applications (view-only access to own records)
- **Principal / Director** — Approvals, policy oversight, strategic reports
- **System Admin** — Master data, audit trails, system configuration

---

## 2. Database Schema Overview

### 2.1 Table Prefix Convention
All tables use prefix **`sch_`** (SchoolSetup module scope).

### 2.2 Core Table Groups

#### Group A: Attendance Configuration
- `sch_staff_attendance_types` — Attendance category definitions
- `sch_employee_shifts` — Shift master (working hour templates)
- `sch_employee_shift_assignments` — Employee ↔ shift active mapping
- `sch_annual_leave_sessions` — Leave year definitions (calendar/academic year)
- `sch_holidays` — School holiday calendar

#### Group B: Leave Configuration
- `sch_staff_leave_types` — Leave type master (CL, SL, EL, ML, PL, LWP, etc.)
- `sch_staff_leave_config` — Role/department-based leave entitlements
- `sch_leave_approval_policies` — Policy definitions
- `sch_leave_approval_policy_levels` — Multi-level approval workflows

#### Group C: Employee Core
- `sch_employees` — Employee master record (from SchoolSetup core)
- `sch_employee_leave_balance` — Current year leave balance per employee
- `sch_employee_leave_applications` — Leave requests (with approval workflow tracking)
- `sch_employee_attendance` — Daily attendance records

#### Group D: Lifecycle Management
- `sch_employee_roles` — Role master (Teacher, Principal, Admin, etc.)
- `sch_departments` — Department master
- `sch_designations` — Designation master

---

## 3. Screens & Features

### Screen Mapping (from Menu Structure)
```
Staff Management
├── Attendance & Leave Management
│   ├── Attendance Masters (SR-EM-04)
│   ├── Leave Config (SR-EM-05, SR-EM-06, SR-EM-07)
│   ├── Employee Creation & Profile (SR-EM-02)
│   ├── Employee Transfer & Promotion (SR-EM-10)
│   ├── Employee Attendance Management (SR-EM-08)
│   ├── Leave Management (SR-EM-08)
│   └── Employee Reports (SR-EM-11)
```

### 3.1 Screen List
| # | Screen Code | Title | Section | Priority |
|---|------------|-------|---------|----------|
| 1 | SR-EM-02 | Employee Creation & Profile Management | Employee Master | P0 |
| 2 | SR-EM-03 | Employee Shift Assignment | Configuration | P1 |
| 3 | SR-EM-04 | Attendance Masters Configuration | Attendance | P0 |
| 4 | SR-EM-05 | Leave Configuration (Master) | Leave Config | P0 |
| 5 | SR-EM-06 | Leave Type Configuration | Leave Config | P0 |
| 6 | SR-EM-07 | Leave Approval Policies & Workflows | Leave Config | P1 |
| 7 | SR-EM-08 | Employee Leave Balances & Applications | Leave Mgmt | P0 |
| 8 | SR-EM-09 | Holiday Calendar Configuration | Attendance | P1 |
| 9 | SR-EM-10 | Employee Transfer & Promotion Lifecycle | Lifecycle | P2 |
| 10 | SR-EM-11 | Employee Reports & Analytics | Reporting | P2 |

---

## 4. Cross-Module Dependencies

### 4.1 Dependencies ON Other Modules
- **SystemConfig** — User accounts, roles, permissions, dropdown tables
- **GlobalMaster** — Countries, states, cities, language codes
- **SchoolSetup (Core)** — Organizations, academic sessions, classes, sections, buildings

### 4.2 Dependencies FROM Other Modules
- **StudentProfile** — If staff also manage student records
- **Transport** — If staff assigned to transport operations
- **SmartTimetable** — If teacher shift management required
- **LmsExam** — If exam invigilation tracking required

---

## 5. Key Business Rules (Summary)

### 5.1 Attendance Rules
- **BR-ATT-001:** Only one active shift per employee (enforced via UNIQUE KEY)
- **BR-ATT-002:** Shift can have multiple time configurations (morning, afternoon, full day)
- **BR-ATT-003:** Grace periods (late/early departure) configurable per shift
- **BR-ATT-004:** Attendance types can affect payroll calculation

### 5.2 Leave Rules
- **BR-LEV-001:** Leave entitlements determined by (role + department + designation + employment_type) — most specific match wins
- **BR-LEV-002:** Annual leave balance must be reset at year end
- **BR-LEV-003:** Carry-forward limited by `max_carry_forward` setting (NULL = no limit)
- **BR-LEV-004:** Holidays excluded from leave day count
- **BR-LEV-005:** Leave applications must have approval chains defined per leave type/role
- **BR-LEV-006:** No approval required if `requires_approval = false`
- **BR-LEV-007:** Multi-level approvals must complete in sequence; escalation timers optional
- **BR-LEV-008:** Encashment at separation allowed only if `is_encashable_at_separation = true`

### 5.3 Approval Rules
- **BR-APR-001:** Each approval level can be ANY_ONE (single approver sufficient) or ALL (unanimous)
- **BR-APR-002:** Escalation auto-advances if not approved within `escalation_after_hours` (NULL = no escalation)
- **BR-APR-003:** Applicant notification on escalation controlled by `notify_applicant_on_escalation`
- **BR-APR-004:** Approver list determined by reporting hierarchy + policy designation

---

## 6. Implementation Phases

### Phase 1: Foundations (P0)
- Employee creation & profile management
- Shift master & assignment
- Attendance type configuration
- Leave type configuration
- Basic leave balance calculation
- Holiday calendar

### Phase 2: Advanced Configuration (P1)
- Leave approval policies & workflows
- Role-based leave entitlements
- Transfer & promotion tracking

### Phase 3: Analytics & Reports (P2)
- Attendance reports
- Leave utilization analytics
- Employee lifecycle reports

---

## 7. Document Navigation

| Document | Purpose |
|----------|---------|
| [SR-EM-02](./SR-EM-02-Employee_Creation_Profile.md) | Employee master data and profile management |
| [SR-EM-03](./SR-EM-03-Shift_Assignment.md) | Shift configuration and employee shift assignment |
| [SR-EM-04](./SR-EM-04-Attendance_Masters.md) | Attendance types, holidays, shift management |
| [SR-EM-05](./SR-EM-05-Leave_Configuration.md) | Leave policy by role/department/designation |
| [SR-EM-06](./SR-EM-06-Leave_Type_Configuration.md) | Leave type master (CL, SL, EL, ML, PL, LWP) |
| [SR-EM-07](./SR-EM-07-Leave_Approval_Policies.md) | Approval workflows and escalation policies |
| [SR-EM-08](./SR-EM-08-Leave_Balances_Applications.md) | Leave balance calculation and applications |
| [SR-EM-09](./SR-EM-09-Holiday_Calendar.md) | Holiday master and calendar configuration |
| [SR-EM-10](./SR-EM-10-Employee_Lifecycle.md) | Transfer, promotion, and lifecycle events |
| [SR-EM-11](./SR-EM-11-Employee_Reports.md) | Reports and analytics |

---

## 8. Technical Standards

### 8.1 Validation Standards
- All date fields must validate against academic session dates
- Leave application dates must exclude weekends and holidays
- Approval workflows must validate permission hierarchies
- Shift times must follow HH:MM:SS format with proper range validation

### 8.2 Calculation Standards
- Leave balance = opening balance + accrued - consumed - encashed
- Accrual calculated based on `accrual_method` (Lump Sum / Monthly Pro-Rata / Quarterly)
- Pro-rata calculations based on employment start date
- Carry-forward capped by `max_carry_forward` per leave type config

### 8.3 Workflow Standards
- All approval workflows must be auditable (who approved, when, with remarks)
- State transitions must be immutable (no edit after approval)
- Escalations must trigger notifications
- Withdrawal only allowed before first approval level

---

## 9. Version History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | Jan 2026 | DB Team | Initial schema |
| 4.0 | Mar 2026 | DB Team | Leave management overhaul |
| 5.0 | May 2026 | DB Architect | Final comprehensive review |

---

**Next Step:** Review individual screen requirements documents (SR-EM-02 through SR-EM-11) for detailed implementation specifications.
