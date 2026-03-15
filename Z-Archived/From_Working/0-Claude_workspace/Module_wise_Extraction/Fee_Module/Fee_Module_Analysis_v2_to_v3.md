# Student Fee Management Module - Analysis & Enhancement Document
## v2 -> v3 Upgrade Analysis

**Date**: 2026-02-24
**Author**: AI Systems Architect
**Input File**: `DATABASES/2-Tenant_Modules/19-Student_Fees_Module/DDL/Student_Fee_Module_v2.sql`
**Output File**: `DATABASES/2-Tenant_Modules/19-Student_Fees_Module/DDL/Student_Fee_Module_v3.sql`

---

## 1. MY UNDERSTANDING OF THE PROJECT

### 1.1 Project Overview
- **System**: School ERP + LMS + LXP
- **Tech Stack**: PHP (Laravel) + MySQL
- **Architecture**: Multi-tenant with separate database per school
- **Current Module**: Student Fee Management (sub-module of Student Management)

### 1.2 Existing Modules Already Designed
- Authentication & Authorization
- Plan & Subscription
- Tenant Creation & Billing
- Core ERP (School Setup, Class Setup, Infra Setup, Staff Management)
- Vendor Management, Transport (Standard + Advanced), Complaint Management
- Notification Module (cross-module)
- LMS (Question Bank, Homework, Quiz, Exam)
- Timetable, Library, Syllabus
- Student Management (Profile, Address, Guardian, Previous Record, Medical, Attendance)

### 1.3 Key Dependencies (Tables from Other Modules)
| Table | Module | PK Type | Key Columns |
|-------|--------|---------|-------------|
| `std_students` | Student Profile | `INT UNSIGNED` | admission_no, first_name, last_name, current_status_id |
| `std_guardians` | Student Profile | `INT UNSIGNED` | first_name, last_name, mobile_no |
| `std_student_guardian_jnt` | Student Profile | `INT UNSIGNED` | student_id, guardian_id, `is_fee_payer` flag |
| `sch_classes` | Class Setup | `INT UNSIGNED` | name, code, ordinal |
| `sch_org_academic_sessions_jnt` | Tenant DB | **`SMALLINT UNSIGNED`** | short_name, start_date, end_date, is_current |
| `sys_users` | Prime DB | `INT UNSIGNED` | emp_code, name, email |
| `sys_dropdown_table` | Tenant DB | `INT UNSIGNED` | ordinal, `key` (format: `table.column`), value, type |

### 1.4 Naming Conventions Observed
| Prefix | Module |
|--------|--------|
| `fee_` | Fee Management (this module) |
| `std_` | Student Management |
| `sch_` | School Setup |
| `sys_` | System Configuration |
| `tpt_` | Transport |
| `ntf_` | Notification |
| `_jnt` suffix | Junction/mapping tables |

**DDL Standards**:
- All IDs: `INT UNSIGNED AUTO_INCREMENT` (except `sch_org_academic_sessions_jnt` which uses `SMALLINT`)
- Timestamps: `created_at`, `updated_at`, `deleted_at` (soft delete pattern)
- Unique keys: `uq_<table>_<field>`
- Foreign keys: `fk_<shortTable>_<field>`
- Indexes: `idx_<table>_<field>`
- Engine: InnoDB, Charset: utf8mb4, Collation: utf8mb4_unicode_ci
- `is_active TINYINT(1) DEFAULT 1` universal on master tables

### 1.5 Transport Module Integration
- Transport has its own fee tables: `tpt_student_fee_detail`, `tpt_student_fee_collection`
- Fee module references transport via `fee_head_master` entry with head_type = 'Transport'
- Integration is "Data Fetch" (application-level), not FK-based
- Transport fare comes from `tpt_pickup_points_route_jnt.pickup_drop_fare` / `both_side_fare`

### 1.6 Accounting Module Integration
- Accounting uses `ledger_mappings.source_module = 'Fees'` to pull fee data
- Fee module connects via `fee_head_master.account_head_code` (loose text coupling, not FK)
- Accounting has its own `sales_invoices` and `receipts` tables for double-entry bookkeeping

---

## 2. MY UNDERSTANDING OF THE REQUIREMENTS

### 2.1 Fee Setup (Masters)
- Different classes have different fee structures (class-wise fee amount)
- Fee Groups suitable for different classes/streams (e.g., Academic, Transport, Hostel packages)
- Students are assigned to a particular Fee Group
- Fee heads define types: Tuition, Transport, Hostel, Library, Sports, Exam, Lab, etc.
- Tax applicability per fee head (GST)
- Fee head frequency: One-time, Monthly, Quarterly, Half-Yearly, Yearly

### 2.2 Fine Setup (Masters)
- Different fine structures for different fee types (e.g., Education fine != Transport fine)
- **Tiered fine slots by delay day range**:
  - Tier 1: Day 1-10 -> Rs.25/day (or 10%)
  - Tier 2: Day 11-30 -> Rs.50/day (or 20%)
  - Tier 3: Day 31-60 -> Rs.100/day (or 30%)
  - Day 61+: Name removal from class
- Fine can be Fixed amount/day OR Percentage
- **Fine calculation is configurable**: PerDay (accumulates daily) OR FlatPerTier (once for the tier)
- Actions on extreme delay: Mark Defaulter, Suspend, Remove Name
- After name removal: Re-admission with fine payment required, then re-activation
- Fine waiver (full or partial) by designated roles (Account Manager, Principal)
- System logs all delays, suspensions for **Frequent Defaulter** tracking

### 2.3 Student Fee Assignment
- Auto-assign class-wise fees to students
- Students can select optional fee heads/groups
- Preview fee breakdown before applying to batch
- Validate student-class mapping
- **Prorated amount** for mid-year joins (partial month/session calculation)

### 2.4 Fee Payment
- Multiple payment modes: Cash, Cheque, DD, UPI, Credit Card, Debit Card, Net Banking, Wallet
- Installment-based payments (Monthly, Quarterly, Half-Yearly, Yearly)
- Online payment gateway integration (Razorpay, Paytm, CCAvenue, BillDesk)
- Auto-reconciliation of online payments

### 2.5 Fee Receipts & Invoices
- Receipt generated per payment
- Receipt shared with parents via Email, SMS, WhatsApp, Print
- Invoice generation per installment

### 2.6 Scholarships
- Define fund name, sponsor, total amount
- Set eligibility criteria (Academic, Financial Need, Category)
- Online scholarship application form
- Multi-stage approval workflow with review committee
- Auto-apply scholarship to student fee account
- Renewal tracking (maintain grades criteria)
- Per academic session applications

### 2.7 Concessions
- Types: Sibling, Merit, Staff Ward, Financial Aid, Sports, Alumni
- Discount type: Percentage or Fixed Amount
- Applicable on: Total Fee, Specific Heads, or Specific Groups
- Max cap amount supported
- Approval workflow with designated roles
- Conditional logic (e.g., sibling discount if 2+ students -- handled at application level)

### 2.8 Notifications
- Uses existing Notification Engine (`ntf_` module)
- Triggers: Fee Due, Overdue, Payment confirmation, Scholarship status, Fine applied

### 2.9 Reports & Analytics
- Daily Collection Report, Receipt Register, Cheque Clearance Report
- Outstanding Analysis, Default Risk Prediction, Fee Collection Summary
- Tax Report (GST), Fee Defaulter List, Name Removal Log
- Student Fee Ledger, Payment History, Installment Schedule

### 2.10 Refunds
- Refund processing when payments are reversed or student withdraws
- Refund approval workflow
- Track refund mode, reference, reason

### 2.11 Cheque/DD Management
- Track cheque lifecycle: Pending Deposit -> Deposited -> Cleared/Bounced
- Bounce handling with bounce charge and reason
- Resubmission tracking

---

## 3. EXISTING SCHEMA EVALUATION (v2 - 21 Tables)

### 3.1 Tables in v2

| # | Table | Purpose | Status |
|---|-------|---------|--------|
| 1 | `fee_head_master` | Fee types (Tuition, Transport, etc.) | OK (minor: needs created_by/updated_by) |
| 2 | `fee_group_master` | Logical grouping (Academic Package, etc.) | OK (minor: needs created_by/updated_by) |
| 3 | `fee_group_heads_jnt` | Maps heads to groups | OK |
| 4 | `fee_structure_master` | Per session+class+category structure | **BUG**: academic_session_id wrong type |
| 5 | `fee_structure_details` | Head-wise amounts in structure | OK |
| 6 | `fee_installments` | Installment schedule | OK |
| 7 | `fee_fine_rules` | Tiered fine rules | **GAP**: No per-day vs flat-per-tier mode |
| 8 | `fee_concession_types` | Discount definitions | OK (naming inconsistency) |
| 9 | `fee_concession_applicable_heads` | Maps concessions to heads/groups | **BUG**: Syntax + NOT NULL contradiction |
| 10 | `fee_student_assignments` | Student fee assignment | **BUG + GAP**: Type mismatch + no proration |
| 11 | `fee_student_concessions` | Per-student concessions | OK |
| 12 | `fee_invoices` | Invoices with balance calc | **GAP**: No tax_amount |
| 13 | `fee_transactions` | Payment records | OK |
| 14 | `fee_transaction_details` | Head-wise payment split | OK |
| 15 | `fee_receipts` | Official receipts | OK |
| 16 | `fee_fine_transactions` | Applied fines with waiver | OK |
| 17 | `fee_payment_gateway_logs` | Gateway logs | OK |
| 18 | `fee_scholarships` | Scholarship definitions | OK (naming inconsistency) |
| 19 | `fee_scholarship_applications` | Student applications | **BUG + GAP**: FK collision + no session |
| 20 | `fee_scholarship_approval_history` | Approval audit trail | OK |
| 21 | `fee_name_removal_log` | Name removal tracking | **BUG + GAP**: Type mismatch + no user tracking |

### 3.2 What v2 Already Covers Well
- Class-wise fee structure with session + category + board dimensions
- Fee head grouping with optional/mandatory flags
- Tiered fine rules with day ranges and escalation actions
- Installment scheduling with grace days
- Complete payment workflow (transaction -> receipt)
- Concession types with approval workflow
- Scholarship management with multi-stage approval
- Name removal and re-admission tracking
- Online payment gateway logging
- Soft delete pattern across all master tables

---

## 4. CRITICAL BUGS FOUND IN v2

### BUG-1: CHECK Constraint Syntax Error
**Table**: `fee_concession_applicable_heads` (line 216)
**Issue**: Trailing period (`.`) after CHECK constraint — DDL won't execute
```sql
-- BROKEN (v2):
CONSTRAINT `chk_cah_head_group` CHECK (...). -- trailing period
-- FIXED (v3):
CONSTRAINT `chk_cah_head_or_group` CHECK (...)  -- no period
```

### BUG-2: NOT NULL vs CHECK Contradiction
**Table**: `fee_concession_applicable_heads` (lines 209-210)
**Issue**: `head_id NOT NULL` and `group_id NOT NULL`, but CHECK requires exactly one to be NULL
```sql
-- BROKEN (v2):
`head_id` INT UNSIGNED NOT NULL,
`group_id` INT UNSIGNED NOT NULL,
-- FIXED (v3):
`head_id` INT UNSIGNED NULL,
`group_id` INT UNSIGNED NULL,
```

### BUG-3: Seed INSERTs Use Old v1 Column Names
**Lines 570-608**: INSERTs reference `head_code`, `head_name`, `group_code`, `group_name`, `concession_category`, `approval_level` which don't exist in v2.
**Fix**: Rewrite using v2/v3 names: `code`, `name`, `head_type_id`, `concession_category_id`, `approval_level_role_id`

### BUG-4: sys_dropdown_table Seed Uses Wrong Schema
**Lines 527-567**: References columns `dropdown_type`, `dropdown_key`, `dropdown_value`, `display_order` which don't exist.
**Fix**: Use actual schema: `ordinal`, `key` (format: `table.column`), `value`, `type`

### BUG-5: FK Data Type Mismatch - academic_session_id
**Tables**: `fee_structure_master`, `fee_student_assignments`, `fee_name_removal_log`
**Issue**: Declared as `INT UNSIGNED` but `sch_org_academic_sessions_jnt.id` is `SMALLINT UNSIGNED`
**Fix**: Changed all to `SMALLINT UNSIGNED`

### BUG-6: FK Constraint Name Collision
**Tables**: `fee_student_assignments` AND `fee_scholarship_applications` both use `fk_fsa_student`
**Fix**: Renamed scholarship FK to `fk_fschapp_student`

---

## 5. REQUIREMENT GAPS IDENTIFIED

### 5.1 Core Gaps (Addressed in v3)

| # | Gap | Solution in v3 |
|---|-----|----------------|
| G1 | No fine per-day vs flat-per-tier distinction | Added `fine_calculation_mode ENUM('PerDay','FlatPerTier')` to `fee_fine_rules` |
| G2 | Scholarship applications not session-scoped | Added `academic_session_id` to `fee_scholarship_applications`; changed UNIQUE to include session |
| G3 | No proration for mid-year joins | Added `is_prorated`, `proration_start_date`, `proration_percentage` to `fee_student_assignments` |
| G4 | No tax amount on invoices | Added `tax_amount DECIMAL(12,2)` to `fee_invoices` |
| G5 | Missing audit columns | Added `created_by`, `updated_by` to 6 master tables |
| G6 | No refund tracking | NEW table: `fee_refunds` |
| G7 | No cheque lifecycle tracking | NEW table: `fee_cheque_clearance` |
| G8 | No defaulter analytics summary | NEW table: `fee_defaulter_history` |
| G9 | Name removal log missing user tracking | Added `removed_by`, `re_admitted_by`, `re_admission_fee_head_id` to `fee_name_removal_log` |
| G10 | Naming inconsistency | Renamed `concession_code`->`code`, `scholarship_code`->`code`, etc. |

### 5.2 Items Handled at Application Level (No Schema Change Needed)
- Sibling discount conditional logic (detect via `std_student_guardian_jnt`)
- Preview fee breakdown before applying to batch (UI concern)
- Fee due/overdue notifications (uses existing `ntf_` module)
- Scholarship renewal reminders (cron job)
- AI default risk prediction (uses `fee_defaulter_history.defaulter_score` + application logic)
- Transport fee fetch from `tpt_` module (Data Fetch integration)
- Hostel fee integration (same pattern as transport)

---

## 6. v3 SCHEMA SUMMARY (24 Tables)

### 6.1 Existing Tables (21 - Fixed)
1. `fee_head_master` - +created_by, +updated_by
2. `fee_group_master` - +created_by, +updated_by
3. `fee_group_heads_jnt` - unchanged
4. `fee_structure_master` - SMALLINT fix, +created_by, +updated_by
5. `fee_structure_details` - unchanged
6. `fee_installments` - unchanged
7. `fee_fine_rules` - +fine_calculation_mode, +created_by, +updated_by
8. `fee_concession_types` - renamed columns, +created_by, +updated_by
9. `fee_concession_applicable_heads` - NULL fix, CHECK fix, +uq_concession_group
10. `fee_student_assignments` - SMALLINT fix, +proration columns, +created_by, +updated_by
11. `fee_student_concessions` - unchanged
12. `fee_invoices` - +tax_amount, renamed FK prefixes to `fk_finv_`
13. `fee_transactions` - unchanged
14. `fee_transaction_details` - unchanged
15. `fee_receipts` - unchanged
16. `fee_fine_transactions` - +waived_amount for partial waiver
17. `fee_payment_gateway_logs` - unchanged
18. `fee_scholarships` - renamed columns, +created_by, +updated_by
19. `fee_scholarship_applications` - +academic_session_id, FK rename, +created_by, +updated_by
20. `fee_scholarship_approval_history` - unchanged
21. `fee_name_removal_log` - SMALLINT fix, +removed_by, +re_admission_fee_head_id, +re_admitted_by

### 6.2 New Tables (3)
22. `fee_refunds` - Refund tracking (refund_no, original_transaction_id, amount, mode, approval workflow)
23. `fee_cheque_clearance` - Cheque/DD lifecycle (deposit, clearance, bounce, resubmit)
24. `fee_defaulter_history` - Per-student-per-session defaulter summary (fine counts, days late, risk score)

### 6.3 Seed Data
- `sys_dropdown_table`: Fee head types (10 values), Concession categories (7 values)
- `fee_head_master`: 8 sample heads (TUIT, TRAN, HOST, LIBR, SPRT, EXAM, LAB, DEVL)
- `fee_group_master`: 4 groups (Academic, Transport, Hostel, Activity)
- `fee_group_heads_jnt`: 7 head-to-group mappings
- `fee_fine_rules`: 4 tiered rules (3 PerDay tiers + 1 Name Removal)
- `fee_concession_types`: 4 types (Sibling 10%, Merit 25%, Staff 50%, Financial Aid Rs.5000)

---

## 7. OPEN QUESTIONS / AREAS FOR YOUR REVIEW

1. **Fine rule polymorphic FK**: `fee_fine_rules.applicable_id` is a polymorphic reference (its meaning depends on `applicable_on` ENUM value). This works but lacks referential integrity. Should we split into separate nullable FK columns (`applicable_structure_id`, `applicable_installment_id`, `applicable_head_id`) instead?

2. **Invoice line items**: `fee_invoices` stores amounts as aggregates (base_amount, tax_amount, etc.) but has no head-wise breakdown table. The head-wise detail exists only at the structure level (`fee_structure_details`) and transaction level (`fee_transaction_details`). Should we add a `fee_invoice_items` table for per-invoice head-wise breakdown?

3. **Section-level fee structure**: Currently `fee_structure_master` supports class-level granularity. Some schools (especially for Class 11-12) may need section-level fee structures (Science vs Commerce). Should we add `section_id` to `fee_structure_master`?

4. **Multiple payment modes per transaction**: Currently `fee_transactions` supports one payment mode per transaction. Some schools allow split payments (e.g., part cash + part UPI). Is this a requirement?

5. **Hostel integration**: The requirement mentions "Assign room type, Apply mess charges, Partial month calculation, Room change adjustment". Should the fee module have explicit hostel-fee columns, or is it handled the same way as transport (Data Fetch)?

6. **Concession approval history**: `fee_student_concessions` tracks only the final approval status. Should there be a `fee_concession_approval_history` table (similar to `fee_scholarship_approval_history`) for multi-level concession approvals?

7. **Fee adjustment/credit notes**: If a fee amount needs to be corrected after invoicing (e.g., wrong amount, mid-year fee revision), is there a need for a credit note / adjustment mechanism?

8. **Academic session in fine rules**: Fine rules currently reference `applicable_id` (an installment or head ID) but have no session scoping. The same rule applies across sessions. Should fine rules be session-specific, or is the current design (global rules) correct?

---

## 8. FILES REFERENCED

| File Path | Purpose |
|-----------|---------|
| `2-Tenant_Modules/19-Student_Fees_Module/DDL/Student_Fee_Module.sql` | v1 DDL (original) |
| `2-Tenant_Modules/19-Student_Fees_Module/DDL/Student_Fee_Module_v2.sql` | v2 DDL (input for this analysis) |
| `2-Tenant_Modules/19-Student_Fees_Module/DDL/Student_Fee_Module_v3.sql` | v3 DDL (output - generated) |
| `2-Tenant_Modules/19-Student_Fees_Module/Design/Data_Dictionary.md` | Data dictionary |
| `2-Tenant_Modules/19-Student_Fees_Module/Design/Data_Flow.md` | Data flow & integration points |
| `2-Tenant_Modules/19-Student_Fees_Module/Design/Additional_Info.md` | Cron jobs, business logic, API endpoints |
| `2-Tenant_Modules/19-Student_Fees_Module/Design/process_flow.md` | Process flow diagrams |
| `2-Tenant_Modules/19-Student_Fees_Module/Design/Screen_Design.md` | UI screen wireframes |
| `2-Tenant_Modules/19-Student_Fees_Module/Design/Reports_Design.md` | Report designs with SQL |
| `0-master_dbs/1-DDL_schema/tenant_db.sql` | Tenant DB schema (sys_dropdown_table, academic sessions) |
| `0-master_dbs/1-DDL_schema/prime_db.sql` | Prime DB schema (sys_users, naming conventions) |
| `2-Tenant_Modules/13-StudentProfile/DDL/StudentProfile_ddl_v1.3.sql` | Student & Guardian tables |
| `2-Tenant_Modules/3-School_Setup/DDLs/Class_Setup_ddl_v2.sql` | Class & Section tables |
| `2-Tenant_Modules/4-Transport/DDLs/tpt_transport_v2.2.sql` | Transport module (fee integration) |
| `2-Tenant_Modules/20-Accounting/DDL/Accounting_ddl_v1.sql` | Accounting module (ledger integration) |
