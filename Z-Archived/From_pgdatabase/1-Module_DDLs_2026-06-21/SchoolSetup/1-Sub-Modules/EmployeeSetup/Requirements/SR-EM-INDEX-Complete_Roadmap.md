# Employee Setup Module — Complete Requirements Index
## Document ID: SR-EM-INDEX
**Module:** SchoolSetup / EmployeeSetup  
**Version:** 5.0 (Final) 
**Date:** May 2026  
**Status:** Master Index for All Screens

---

## 📋 Complete Screen Documentation Map

### ✅ COMPLETED DOCUMENTS
1. **SR-EM-00** — Master Requirements & Module Overview
2. **SR-EM-02** — Employee Creation & Profile Management
3. **SR-EM-03** — Shift Assignment & Management
4. **SR-EM-04** — Attendance Masters (Types, Holiday Calendar, Annual Sessions)
5. **SR-EM-05** — Leave Configuration (Role/Department-Based Entitlements)
6. **SR-EM-06** — Leave Type Configuration (Master Definitions)

### 📝 REMAINING TO CREATE
| # | Screen Code | Title | Key Features | Priority |
|---|------------|-------|-------------|----------|
| 7 | SR-EM-07 | Leave Approval Policies & Workflows | Multi-level approval chains, escalation timers, approver routing | P1 |
| 8 | SR-EM-08 | Leave Balances & Applications | Leave application CRUD, balance tracking, approval workflow | P0 |
| 9 | SR-EM-09 | Holiday Calendar Management | Holiday CRUD, bulk import, role/dept specific holidays | P1 |
| 10 | SR-EM-10 | Employee Lifecycle (Transfer/Promotion/Separation) | Career progression tracking, transfers, promotions, retirements | P2 |
| 11 | SR-EM-11 | Employee Reports & Analytics | Attendance, leave utilization, staffing reports | P2 |
| 12 | SR-EM-12 | Daily Attendance Management | Mark attendance, correct entries, attendance summary | P0 |
| 13 | SR-EM-13 | Leave Management Hub | Leave applications, approvals, workflows | P0 |
| 14 | SR-EM-14 | Teacher-Specific Profile | Teacher details, qualifications, certifications | P1 |

---

## 🔄 High-Level Workflow Map

```
EMPLOYEE LIFECYCLE FLOW:
┌─────────────┐
│  CREATION   │ (SR-EM-02)
│ Hiring Data │
└──────┬──────┘
       │
       ▼
┌──────────────┐
│  SHIFT ASSIGN│ (SR-EM-03)
│ Working Hrs  │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  ATTENDANCE  │ (SR-EM-12)
│ Daily Mark   │
└──────┬───────┘
       │ ├─→ Attendance Masters (SR-EM-04)
       │ └─→ Holiday Calendar (SR-EM-09)
       │
       ▼
┌──────────────┐
│  LEAVE MGMT  │ (SR-EM-13)
│  Apply       │
│  Approve     │
└──────┬───────┘
       │ ├─→ Leave Types (SR-EM-06)
       │ ├─→ Leave Config (SR-EM-05)
       │ ├─→ Leave Policies (SR-EM-07)
       │ └─→ Leave Balances (SR-EM-08)
       │
       ▼
┌──────────────┐
│  LIFECYCLE   │ (SR-EM-10)
│ Transfer     │
│ Promotion    │
│ Separation   │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  REPORTS &   │ (SR-EM-11)
│  ANALYTICS   │
└──────────────┘
```

---

## 🗂️ SR-EM-07: Leave Approval Policies & Workflows

### Key Components
- **Approval Levels:** Multi-tier approval chains (L1: Manager, L2: HR, L3: Principal)
- **Approval Modes:** ANY_ONE (single approver sufficient) or ALL (unanimous)
- **Escalation:** Auto-escalate if not approved within N hours
- **Routing:** Dynamic approver assignment based on reporting hierarchy
- **Audit Trail:** Complete tracking of who approved, when, with remarks

### Core Tables
```
sch_leave_approval_policies
├─ Policy Definition (name, scope, priority)
├─ Applies to (role, department, designation, leave_type)
└─ Multiple Levels (via sch_leave_approval_policy_levels)

sch_leave_approval_policy_levels
├─ Level Number (1, 2, 3, etc.)
├─ Approval Mode (ANY_ONE, ALL)
├─ Escalation Rules (hours, notify_applicant)
└─ Approver Assignment (via routing rules)
```

### Key Validations
- Policy must have at least 1 approval level
- Level numbers must be sequential and unique per policy
- Escalation hours must be >= 1
- Approver must exist in reporting hierarchy

### Business Rules
- Multiple policies can apply to same employee; most specific wins
- Escalation auto-advances to next level (manual if no escalation set)
- Withdrawal allowed only before Level 1 approval
- Once approved, cannot edit application (immutable)

---

## 🗂️ SR-EM-08: Leave Balances & Applications

### Key Components
- **Leave Balance Tracking:** Opening + Accrued - Consumed - Encashed
- **Leave Applications:** CRUD with approval workflow integration
- **Balance Calculation:** Based on policy and accrual method
- **Carry-Forward Logic:** Auto-applied at year-end
- **Encashment:** At separation based on policy

### Core Tables
```
sch_employee_leave_balance
├─ Employee & Leave Type (annual, per type)
├─ Balance Tracking (opening, accrued, consumed, encashed, carry_forward)
├─ Policy Reference (from sch_staff_leave_config)
└─ Year/Period (annual_leave_sessions_id)

sch_employee_leave_applications
├─ Application (from_date, to_date, days, type)
├─ Approval Chain (status, approver_id, level, remarks)
├─ Attachment (for documents like medical cert)
└─ Audit (created_by, created_at, updated_at)
```

### Key Validations
- Leave dates must be within session
- Exclude weekends and holidays from day count
- Cannot apply if insufficient balance
- Must meet advance notice requirement
- Must have necessary documentation (if required)

### Business Rules
- Balance = opening + accrued - consumed - encashed - carried_from_previous
- Accrual = policy.annual_entitlement (method: lump sum / monthly / quarterly)
- Carry-forward capped by policy.max_carry_forward (NULL = unlimited)
- Encashment only if policy.is_encashable_at_separation = true

---

## 🗂️ SR-EM-09: Holiday Calendar Management

### Key Components
- **Holiday Master:** Annual holidays (public, religious, optional, school-specific)
- **Holiday Sessions:** Link holidays to leave sessions
- **Role/Dept Specific:** Some holidays apply only to certain roles/departments
- **Paid/Unpaid:** Configure holiday pay impact
- **Optional Holidays:** Employee can choose from list

### Additional Features Beyond SR-EM-04
- Bulk import holidays from CSV template
- Holiday calendar grid view (monthly)
- Export holidays for payroll integration
- Optional holiday selection workflow
- Copy holidays from previous year

### Key Validations
- Holiday date must be within leave session
- Cannot create duplicate holiday same date (per session)
- Optional holidays: max N selections per employee
- Role/Dept specific: must exist in master

---

## 🗂️ SR-EM-10: Employee Lifecycle (Transfer/Promotion/Separation)

### Key Components
- **Transfers:** Change of department/designation/location
- **Promotions:** Advancement with new designation/salary
- **Separations:** Resignation, retirement, termination
- **Career History:** Complete audit trail of changes
- **Benefit Settlements:** Encashment, insurance, gratuity calculations

### Core Tables
```
sch_employee_transfers
├─ From: Current dept, designation, location
├─ To: New dept, designation, location
├─ Effective: transfer_date, reason
└─ Status: Approved, Rejected, Pending

sch_employee_promotions
├─ From: Current designation, grade
├─ To: New designation, grade, salary
├─ Effective: promotion_date, reason
└─ Approval: Approval chain

sch_employee_separations
├─ Separation Type: Resignation, Retirement, Termination
├─ Details: last_working_date, notice_period, reason
├─ Settlements: Final salary, encashment, gratuity
└─ Exit Interview: Feedback, remarks
```

### Key Business Rules
- Transfer/Promotion effective from specified date
- Cannot transfer to same dept/designation (validation)
- Settlement includes: EL encashment, carry-forward leave, gratuity
- Leave balance freeze on separation (no new applications)
- Probation restart for some transfers (policy-driven)

---

## 🗂️ SR-EM-11: Employee Reports & Analytics

### Report Types
1. **Attendance Report:** Monthly, quarterly, annual attendance summary
2. **Leave Balance Report:** Current balances, utilized, available
3. **Staffing Report:** Headcount, vacancy, turnover
4. **Leave Usage Report:** Leave type-wise utilization
5. **Compliance Report:** Attendance policy violations, pending approvals

### Key Metrics
- Attendance %: (Present days / Working days) * 100
- Leave Utilization: (Consumed / Entitlement) * 100
- Headcount: Active employees per department
- Turnover: Separations in period
- Pending Approvals: Leaves awaiting action

### Export Formats
- PDF (formatted report with charts)
- Excel (data table with formulas)
- CSV (raw data export)

---

## 🗂️ SR-EM-12: Daily Attendance Management

### Key Components
- **Mark Attendance:** Per employee, per date, select type
- **Bulk Mark:** For entire class/department
- **Attendance Correction:** Edit past entries with approval
- **Punch Records:** Optional integration with biometric
- **Summary View:** Calendar grid or list view

### Core Tables
```
sch_employee_attendance
├─ Employee & Date (unique per employee per date)
├─ Attendance Type (from sch_staff_attendance_types)
├─ Half-Day: is_half_day flag
├─ Status: Marked, Corrected, Pending Approval
└─ Audit: Marked by, Corrected by, Remarks

sch_employee_punches (Optional)
├─ In Time: punch_in_time
├─ Out Time: punch_out_time
├─ Duration: calculated_hours
└─ Shift: Assigned shift for validation
```

### Key Validations
- Cannot mark attendance for future dates
- Cannot mark for dates > 30 days past (or configurable)
- Half-day only if attendance_type.can_be_half_day = true
- Holiday dates: auto-mark as Holiday type
- Weekends: configurable (auto-mark or require marking)

### Business Rules
- Attendance affects payroll via attendance_type.payroll_percentage
- Correction triggers approval (if amount significant)
- Punch-based calculation: (punch_out - punch_in) vs shift.working_hours
- Grace periods: late_grace and early_departure_grace

---

## 🗂️ SR-EM-13: Leave Management Hub

### Key Components
- **Leave Applications:** Submit, view, edit, withdraw
- **Approval Requests:** View pending approvals, approve/reject
- **Workflow Status:** Tracking application through approval chain
- **Notifications:** Email/SMS on status changes

### Integration Points
- Connects SR-EM-06, SR-EM-07, SR-EM-08, SR-EM-05
- Uses Leave Types, Policies, Balances, Configurations
- Triggers notifications and approval routing
- Maintains audit trail for compliance

### Key Workflows
1. **Employee View:** My applications, my balance, apply new
2. **Approver View:** Pending approvals, history, bulk actions
3. **HR View:** All applications, edit, override, generate reports

---

## 🗂️ SR-EM-14: Teacher-Specific Profile

### Additional Fields Beyond Employee Master
- **Qualifications:** Degrees, certifications, board registrations
- **Subject Expertise:** Primary and secondary subjects
- **Classes Assigned:** Current class-section assignments
- **Experience:** Total teaching experience, experience with school
- **Ratings:** Performance ratings, student feedback (if integrated)

### Integration Points
- Links to SR-EM-02 (Employee Master)
- References sch_classes, sch_subjects, sch_subject_study_format_jnt
- Optional: Links to LmsExam, SmartTimetable

---

## 🔗 Cross-Module Dependencies

### Inbound (Modules depending on EmployeeSetup)
- **SmartTimetable:** Uses teachers (shifts, allocation)
- **Transport:** Uses staff assignments
- **LmsExam:** Uses teachers (invigilation, paper setter)
- **Payroll:** Uses attendance, leaves for salary calculation
- **HR/Staff Module:** Uses employee master and leave management

### Outbound (EmployeeSetup depends on)
- **SystemConfig:** User accounts, roles, permissions
- **GlobalMaster:** Countries, states, cities
- **SchoolSetup (Core):** Organizations, departments, designations

---

## 📊 Data Flow & Calculations

### Attendance to Payroll Flow
```
Daily Attendance (SR-EM-12)
    ↓ (Marked as attendance type)
Attendance Type Configuration (SR-EM-04)
    ↓ (Has payroll_percentage)
Payroll_Impact = daily_wage * (payroll_percentage / 100)
    ↓
Salary Calculation (External Payroll Module)
```

### Leave Balance Calculation Flow
```
Employee + Leave Type
    ↓
Find Policy (SR-EM-05 — Matching by role/dept/desig)
    ↓
Get Annual Entitlement + Accrual Method
    ↓
Accrual Calculation (Lump Sum / Monthly / Quarterly)
    ↓
Applied to Leave Balance (SR-EM-08)
    ↓
Leave Applications reduce balance (SR-EM-13)
    ↓
Carry-Forward applied at year-end (if allowed by policy)
    ↓
Final Balance for next year
```

### Approval Workflow Flow
```
Leave Application Submitted (SR-EM-13)
    ↓
Policy Matching (SR-EM-07 — Find applicable policy)
    ↓
Level 1 Approval (Reporting Manager)
    ↓ (if not approved within escalation_hours)
Auto-Escalation to Level 2 (HR) → Level 3 (Principal)
    ↓
Final Approval Status (Approved / Rejected)
    ↓
Balance Updated (SR-EM-08)
    ↓
Notification sent to Employee
```

---

## ✅ Implementation Checklist

### Phase 1: Foundation (Weeks 1-2) — P0 Features
- [ ] SR-EM-02: Employee CRUD with validation
- [ ] SR-EM-04: Attendance types, annual sessions
- [ ] SR-EM-06: Leave types master
- [ ] SR-EM-03: Shift assignment (already documented)
- [ ] SR-EM-05: Leave configuration (role-based)
- [ ] SR-EM-12: Daily attendance marking
- [ ] SR-EM-08: Leave balance & basic applications

### Phase 2: Workflows (Weeks 3-4) — P1 Features
- [ ] SR-EM-07: Leave approval policies & workflows
- [ ] SR-EM-13: Leave management (applications, approvals)
- [ ] SR-EM-09: Holiday calendar
- [ ] SR-EM-14: Teacher profile extension
- [ ] Notifications & email integration

### Phase 3: Advanced (Weeks 5-6) — P2 Features
- [ ] SR-EM-10: Employee lifecycle (transfer/promotion)
- [ ] SR-EM-11: Comprehensive reporting
- [ ] Analytics dashboards
- [ ] Payroll integration
- [ ] Bulk operations & import

---

## 🎯 Key Decision Points

### D1: Leave Session Timing
**Decision:** Leave sessions can be calendar year (Jan-Dec) OR academic year (Apr-Mar)
**Impact:** Holiday calendar, balance calculation, accrual timing
**Configuration:** Multiple concurrent sessions possible per tenant

### D2: Approval Workflow
**Decision:** Multi-level approval with escalation and notification
**Impact:** Leave application processing, audit trail
**Configuration:** Policy-driven, role-specific approvers

### D3: Attendance & Holiday Integration
**Decision:** Holidays auto-excluded from leave day counts
**Impact:** Accurate leave balance calculation
**Configuration:** Holiday calendar per leave session

### D4: Balance Carry-Forward
**Decision:** Carry-forward capped by policy, applied at year-end
**Impact:** Leave accumulation across years
**Configuration:** Per leave type, per role/department

---

## 📝 Notes for Implementation Team

1. **DDL Readiness:** All tables defined in Employee_setup_ddl_v5.sql
2. **Foreign Keys:** Ensure referential integrity with cascading deletes where appropriate
3. **Indexes:** Create on frequently queried columns (employee_id, leave_type_id, effective_from)
4. **Caching:** Consider caching leave types, policies, attendance types (low volatility)
5. **Notifications:** Integrate with Notification module for approvals, reminders
6. **Audit Trail:** Use created_by/updated_by fields for compliance
7. **Soft Deletes:** All tables use soft deletes (deleted_at field)
8. **Multi-Tenancy:** All queries must filter by tenant context
9. **Performance:** Test with 500+ employees, 10+ leave types, complex approval workflows
10. **Batch Jobs:** Implement year-end carry-forward, accrual calculation as scheduled jobs

---

## 📞 Support & References

- **DDL File:** `Employee_setup_ddl_v5.sql`
- **Data Dictionary:** `DataDictionary_EmpSetup.md`
- **Leave Flow Guide:** `Leave_Management_Flow_Guide.md`
- **Test Cases:** `Leave_Management_Test_Cases.md`
- **Related Modules:** GlobalMaster, SystemConfig, Notification

---

**Document Version:** 5.0  
**Last Updated:** May 2026  
**Status:** Ready for Development

