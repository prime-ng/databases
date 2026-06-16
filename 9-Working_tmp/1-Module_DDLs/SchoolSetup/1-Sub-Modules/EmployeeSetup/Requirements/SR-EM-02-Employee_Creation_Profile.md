# Screen Requirement: Employee Creation & Profile Management
## Document ID: SR-EM-02
**Module:** SchoolSetup / EmployeeSetup  
**Screen Name:** Employee Creation & Profile Management  
**Route:** `school-setup.employee-management.index`  
**User Role:** School Administrator, HR Manager  
**Priority:** P0 (Critical)  
**Status:** Approved for Development  

---

## 1. Screen Overview

### 1.1 Purpose & Business Objective
This screen serves as the primary hub for creating, viewing, editing, and managing employee master records throughout their lifecycle in the school system. It provides comprehensive employee information capture, validation, and document management for all school staff members.

### 1.2 Key Capabilities
- ✅ Create new employee records with comprehensive validation
- ✅ Edit existing employee information (with role-based restrictions)
- ✅ Bulk import employees via Excel
- ✅ Soft-delete employees (archive without data loss)
- ✅ Upload and manage employee documents (ID proof, certificates, medical)
- ✅ View employee status history and lifecycle events
- ✅ Assign roles, departments, designations
- ✅ Configure employment terms (permanent, contract, temporary, etc.)

---

## 2. Data Model & DDL References

### 2.1 Primary Tables
```sql
sch_employees — Main employee master record
├── Basic Info: name, email, phone, date_of_birth
├── Employment: department_id, designation_id, role_id
├── Joining Details: date_of_joining, employment_type, probation_end_date
├── Contact Info: address, city, state, country
├── Bank Details: bank_account_number, ifsc_code
└── Status: is_active, deleted_at (soft delete)
```

### 2.2 Related Tables (Lookups & Configuration)
- `sch_departments` — Department master (FK: department_id)
- `sch_designations` — Designation master (FK: designation_id)
- `sch_employee_roles` — Role master (FK: role_id)
- `sch_buildings` — Building/campus location (FK: building_id)
- `sys_users` — System user account (FK: user_id) [when employee login required]
- `sys_media` — Document storage (profile photo, certificates, ID proofs)

---

## 3. Screen Layout & UI Components

### 3.1 Page Structure: Tabbed Interface

```
┌─ Employee Management ──────────────────────────────────┐
│                                                         │
│  [+ New Employee] [Import Excel] [View Archived] [Export]
│                                                         │
│  Search: [________] Department: [▼] Designation: [▼]  │
│                                                         │
├─────────────────────────────────────────────────────────┤
│  TAB 1: ACTIVE EMPLOYEES (List View)                    │
│  ┌─────────────────────────────────────────────────────┐
│  │ ID │ Name │ Dept │ Desig │ Joining │ Status │ Action│
│  │... │...   │...   │...    │...      │  Active│ Edit  │
│  └─────────────────────────────────────────────────────┘
│  Total: 45 | Page: 1 of 3  [< 1 2 3 >]
│
├─────────────────────────────────────────────────────────┤
│  TAB 2: EMPLOYEE DETAILS (Form View)                    │
│  [Selected Employee Info — see section 3.2]            │
│                                                         │
├─────────────────────────────────────────────────────────┤
│  TAB 3: BULK IMPORT                                     │
│  [Upload Excel → Validation → Preview → Confirm]       │
│                                                         │
├─────────────────────────────────────────────────────────┤
│  TAB 4: ARCHIVED EMPLOYEES                              │
│  [Soft-deleted records with Restore option]            │
└─────────────────────────────────────────────────────────┘
```

### 3.2 Employee Details Form (Create/Edit)

#### Section A: Basic Information
```
┌─ BASIC INFORMATION ────────────────────┐
│                                        │
│  First Name*       [_____________]    │
│  Middle Name       [_____________]    │
│  Last Name*        [_____________]    │
│  Email*            [_____________]    │
│  Phone Number*     [_____________]    │
│  Alternative Phone [_____________]    │
│  Date of Birth*    [__/__/____]  (Age: 32)
│  Gender*           (O Male O Female O Other)
│  Marital Status    (O Single O Married O Divorced O Widow)
│  Nationality*      [▼ Select Country]
│  Blood Group       [▼ Select]         │
│                                        │
│  [Save] [Reset] [Preview]             │
└────────────────────────────────────────┘
```

#### Section B: Employment Information
```
┌─ EMPLOYMENT INFORMATION ──────────────┐
│                                        │
│  Department*       [▼ Select Dept]    │
│  Designation*      [▼ Select Desg]    │
│  Role*             [▼ Teacher/Admin]  │
│  Employment Type*  (O Permanent       │
│                    O Contract         │
│                    O Temporary        │
│                    O Visiting/Guest   │
│                    O Intern           │
│                    O Probation)       │
│                                        │
│  Date of Joining*  [__/__/____]       │
│  Probation Period  [__] months        │
│  Probation End Dt  [__/__/____] (auto)│
│                                        │
│  Reporting Manager [▼ Select Emp.]    │
│  Campus/Building   [▼ Select]         │
│                                        │
│  [Save] [Reset]                       │
└────────────────────────────────────────┘
```

#### Section C: Contact & Address
```
┌─ ADDRESS & CONTACT ───────────────────┐
│                                        │
│  Address Line 1*   [_____________]    │
│  Address Line 2    [_____________]    │
│  City*             [_____________]    │
│  State*            [▼ Select State]   │
│  Postal Code*      [_____________]    │
│  Country*          [▼ India]          │
│                                        │
│  [Save]                                │
└────────────────────────────────────────┘
```

#### Section D: Bank & Payroll Details
```
┌─ BANK ACCOUNT DETAILS ────────────────┐
│                                        │
│  Bank Name*        [_____________]    │
│  Account Number*   [_____________]    │
│  IFSC Code*        [_____________]    │
│  Account Type      (O Savings O Current)
│  Account Holder    [_____________]    │
│  PAN Number        [_____________]    │
│  UAN Number        [_____________]    │
│  Aadhar Number     [_____________]    │
│                                        │
│  [Save]                                │
└────────────────────────────────────────┘
```

#### Section E: Documents & Media
```
┌─ DOCUMENTS & ATTACHMENTS ─────────────┐
│                                        │
│  Document Type*    [▼ Select]         │
│  ┌─────────────────────────────────┐ │
│  │ Profile Photo                   │ │
│  │ [Upload] [Remove]               │ │
│  │ (Max: 5MB, PNG/JPG)             │ │
│  └─────────────────────────────────┘ │
│                                        │
│  ┌─────────────────────────────────┐ │
│  │ ID Proof (Aadhar/PAN)           │ │
│  │ [Upload] [Remove]               │ │
│  │ Uploaded: aadhaar_2024.pdf (2MB)│ │
│  └─────────────────────────────────┘ │
│                                        │
│  ┌─────────────────────────────────┐ │
│  │ Educational Certificates        │ │
│  │ [Upload] [Remove]               │ │
│  │ Uploaded: degree_2020.pdf (1.5MB)
│  └─────────────────────────────────┘ │
│                                        │
│  [+ Add More Documents]                │
│  [Save]                                │
└────────────────────────────────────────┘
```

---

## 4. Input Validation Rules

### 4.1 Basic Information Validations

| Field | Type | Validation Rule | Error Message |
|-------|------|-----------------|----------------|
| First Name | String | Required, 1-100 chars, no special chars | First name is required and must be 1-100 characters |
| Middle Name | String | Optional, 1-100 chars | Middle name must not exceed 100 characters |
| Last Name | String | Required, 1-100 chars, no special chars | Last name is required and must be 1-100 characters |
| Email | Email | Required, unique, valid format | Email is required and must be unique in the system |
| Phone | Phone | Required, 10 digits Indian format | Phone must be 10 digits (no country code) |
| Alt Phone | Phone | Optional, 10 digits Indian format | Alternative phone must be 10 digits if provided |
| DOB | Date | Required, valid date, >= 1950, age >= 18 | Date of birth must be valid and employee must be at least 18 years old |
| Gender | Enum | Required (M/F/Other) | Gender must be specified |
| Nationality | String | Required, must exist in Country master | Nationality must be selected from available countries |
| Blood Group | Enum | Optional (A/B/AB/O/Rh+/Rh-) | Blood group, if provided, must be valid |

### 4.2 Employment Information Validations

| Field | Type | Validation Rule | Error Message |
|-------|------|-----------------|----------------|
| Department | FK | Required, must exist in `sch_departments` | Department must be selected |
| Designation | FK | Required, must exist in `sch_designations` | Designation must be selected |
| Role | FK | Required, must exist in `sch_employee_roles` | Role must be selected |
| Employment Type | Enum | Required (Permanent/Contract/Temp/Visit/Intern) | Employment type is required |
| Joining Date | Date | Required, date <= TODAY(), >= 1900 | Joining date must not be in future |
| Probation Period | Integer | Optional, 0-12 months if provided, integer only | Probation period must be 0-12 months if specified |
| Probation End Dt | Date | Auto-calculated if probation_period set, or manually | Must be >= joining_date |
| Reporting Manager | FK | Optional, must be valid employee_id if provided | Reporting manager must be an active employee |

### 4.3 Address Validations

| Field | Type | Validation Rule | Error Message |
|-------|------|-----------------|----------------|
| Address Line 1 | String | Required, 5-255 chars | Address is required (5-255 chars) |
| Address Line 2 | String | Optional, max 255 chars | Address line 2 must not exceed 255 chars |
| City | String | Required, 2-100 chars | City is required |
| State | FK | Required, must exist in `glb_states` | State must be selected |
| Postal Code | String | Required, 6 chars (Indian PIN) | Postal code must be 6 digits |
| Country | FK | Required, must exist in `glb_countries` | Country must be selected |

### 4.4 Bank Details Validations

| Field | Type | Validation Rule | Error Message |
|-------|------|-----------------|----------------|
| Bank Name | String | Required, max 100 chars | Bank name is required |
| Account Number | String | Required, 9-18 digits, unique | Account number must be 9-18 digits and unique |
| IFSC Code | String | Required, format: 4 letters + 0 + 6 digits | IFSC must be in format: ABCD0123456 |
| Account Type | Enum | Optional (Savings/Current) | Account type must be valid if provided |
| Account Holder | String | Optional, max 100 chars | Account holder name must not exceed 100 chars |
| PAN Number | String | Optional, format: 10 char PAN | PAN must be in format: AAAAA9999A |
| Aadhar Number | String | Optional, 12 digits, unique per tenant | Aadhar must be 12 unique digits |

### 4.5 Cross-Field Validations

| Condition | Validation | Action |
|-----------|-----------|--------|
| Probation Period > 0 | Probation End Date auto-calculated | `probation_end_date = date_of_joining + probation_period months` |
| Age < 18 | Error raised | Cannot create employee if age < 18 years |
| Email exists | Error raised | Cannot create duplicate email (per tenant) |
| Account # exists | Error raised | Cannot create duplicate bank account (per tenant) |
| Date of Joining > Today | Error raised | Cannot join in future |
| Reporting Manager = Self | Error raised | Cannot report to self |
| Reporting Manager inactive | Warning | System allows but shows warning |

---

## 5. Business Logic & Calculations

### 5.1 Auto-Calculated Fields

#### Probation End Date Calculation
```
IF probation_period IS NOT NULL AND probation_period > 0:
    probation_end_date = date_of_joining + (probation_period MONTHS)
ELSE:
    probation_end_date = NULL
```

#### Age Calculation (for display)
```
age = TODAY().year - date_of_birth.year
IF TODAY().month < date_of_birth.month OR 
   (TODAY().month == date_of_birth.month AND TODAY().day < date_of_birth.day):
    age = age - 1
```

#### Email Handle/Username (optional auto-generation)
```
IF email_provided:
    username = first_letter_of_first_name + last_name + employee_id
    EXAMPLE: "John Doe" with ID 15 → "jdoe15"
```

### 5.2 Default Values
- `is_active` = true (on creation)
- `created_by` = current_user_id
- `created_at` = CURRENT_TIMESTAMP
- `employment_type` = 'Permanent' (if not specified)

### 5.3 Computed Fields (View-Only)
- **Age** = Calculated from date_of_birth
- **Tenure (Years)** = TODAY() - date_of_joining
- **In Probation** = TODAY() <= probation_end_date (if applicable)
- **Employment Status** = "Active" / "On Leave" / "Suspended" / "Terminated"

---

## 6. State Transitions & Workflows

### 6.1 Employee Lifecycle States
```
┌─────────────┐
│   CREATED   │
└──────┬──────┘
       │ (On Joining Date)
       ▼
┌──────────────┐
│   PROBATION  │─── (If Probation Period > 0)
│    (Active)  │
└──────┬───────┘
       │ (After Probation Ends)
       ▼
┌──────────────┐
│   ACTIVE     │────────────────┐
│  (Full Emp)  │                │
└──────┬───────┘                │
       │                        │
       ├─[Transfer]─────────►┌──────────────┐
       │                     │  TRANSFERRED │
       │                     │  (Same Active)
       │                     └──────────────┘
       │
       ├─[Promotion]────────►┌──────────────┐
       │                     │  PROMOTED    │
       │                     │  (Same Active)
       │                     └──────────────┘
       │
       ├─[Suspension]──────►┌──────────────┐
       │                    │  SUSPENDED   │
       │                    │ (Inactive)   │
       │                    └──────────────┘
       │
       ├─[Resignation]─────►┌──────────────┐
       │                    │ RESIGNED     │
       │                    │ (Archived)   │
       │                    └──────────────┘
       │
       └─[Retirement]──────►┌──────────────┐
                            │ RETIRED      │
                            │ (Archived)   │
                            └──────────────┘
```

### 6.2 State Transition Rules
- **Creation → Probation/Active:** Automatic on joining date
- **Probation → Active:** Automatic after `probation_end_date`
- **Active ↔ Suspended:** Manual, requires approval
- **Active → Transferred:** Requires transfer event creation (SR-EM-10)
- **Active → Promoted:** Requires promotion event creation (SR-EM-10)
- **Active → Resigned/Retired:** One-way transition (moved to archived)

---

## 7. Permissions & Authorization

### 7.1 Role-Based Permissions

| Permission | Admin | HR Mgr | Mgr | Employee |
|-----------|-------|--------|-----|----------|
| view.employee.list | ✓ | ✓ | ✓ (own reports) | ✓ (self only) |
| create.employee | ✓ | ✓ | ✗ | ✗ |
| edit.employee | ✓ | ✓ | ✗ | ✗ (self only) |
| delete.employee (soft) | ✓ | ✓ | ✗ | ✗ |
| view.salary_info | ✓ | ✓ | ✗ | ✓ (self only) |
| edit.salary_info | ✓ | ✓ | ✗ | ✗ |
| bulk_import | ✓ | ✓ | ✗ | ✗ |
| export.employees | ✓ | ✓ | ✓ (own reports) | ✗ |

### 7.2 Field-Level Permissions
- **Sensitive fields** (Aadhar, PAN, Bank Details): Only admin/HR can view/edit
- **Salary fields:** Only admin/HR can view/edit
- **Profile fields:** Admin/HR can view; employees can self-edit

---

## 8. Excel Bulk Import Specification

### 8.1 File Format
- Format: `.xlsx` (Excel 2007+)
- Header row: Required
- Max rows per import: 500
- Max file size: 10 MB
- Character encoding: UTF-8

### 8.2 Required Columns
```
Column A | First Name         | Required
Column B | Last Name          | Required
Column C | Email              | Required
Column D | Phone              | Required
Column E | Department         | Required (must exist)
Column F | Designation        | Required (must exist)
Column G | Role               | Required (must exist)
Column H | Employment Type    | Required (Permanent/Contract/Temporary)
Column I | Date of Joining    | Required (DD/MM/YYYY format)
Column J | DOB                | Required (DD/MM/YYYY format)
Column K | Gender             | Required (M/F/Other)
Column L | Address            | Required
Column M | City               | Required
Column N | State              | Required
Column O | Postal Code        | Required
Column P | Country            | Required (default: India)
Column Q | Aadhar Number      | Optional
Column R | PAN Number         | Optional
Column S | Bank Account       | Optional
Column T | IFSC Code          | Optional
```

### 8.3 Import Process
1. **Upload** → Select file
2. **Validate** → Check format, required fields, FK existence
3. **Preview** → Show summary of records to import
4. **Confirm** → Create records in batch
5. **Report** → Show success/failure summary

### 8.4 Validation During Import
- ✓ All required fields present
- ✓ Email unique (no duplicates in import or existing)
- ✓ Department/Designation/Role exist in master
- ✓ Date format valid (DD/MM/YYYY)
- ✓ Phone format valid (10 digits)
- ✓ Age >= 18

---

## 9. Database Operations

### 9.1 Create Employee (POST)
```sql
INSERT INTO sch_employees (
    first_name, middle_name, last_name, email, phone, 
    date_of_birth, gender, nationality, blood_group,
    department_id, designation_id, role_id, employment_type,
    date_of_joining, probation_period, probation_end_date,
    reporting_manager_id, building_id,
    address_line1, address_line2, city, state_id, postal_code,
    bank_name, account_number, ifsc_code, pan_number, aadhar_number,
    is_active, created_by, created_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW());

-- Auto-calculate probation_end_date if needed
UPDATE sch_employees 
SET probation_end_date = DATE_ADD(date_of_joining, INTERVAL probation_period MONTH)
WHERE id = LAST_INSERT_ID() AND probation_period IS NOT NULL;
```

### 9.2 Update Employee (PUT)
```sql
UPDATE sch_employees 
SET first_name=?, last_name=?, email=?, phone=?, 
    department_id=?, designation_id=?, role_id=?,
    ... (other fields)
    updated_by=?, updated_at=NOW()
WHERE id = ? AND deleted_at IS NULL;
```

### 9.3 Soft Delete Employee (DELETE)
```sql
UPDATE sch_employees 
SET is_active=0, deleted_at=NOW(), updated_by=?
WHERE id = ? AND deleted_at IS NULL;
```

### 9.4 Restore Archived Employee
```sql
UPDATE sch_employees 
SET is_active=1, deleted_at=NULL, updated_by=?
WHERE id = ? AND deleted_at IS NOT NULL;
```

---



## 11. Error Handling

### 11.1 Common Error Scenarios

| Error Code | HTTP | Message | Cause | Action |
|-----------|------|---------|-------|--------|
| EMP-001 | 400 | Email already exists | Duplicate email | Use unique email |
| EMP-002 | 400 | Department not found | Invalid FK | Select valid department |
| EMP-003 | 400 | Age must be >= 18 | DOB too recent | Select valid DOB |
| EMP-004 | 422 | Validation failed | Multiple field errors | Fix validation errors |
| EMP-005 | 404 | Employee not found | ID doesn't exist | Check employee ID |
| EMP-006 | 403 | Permission denied | Insufficient role | Contact administrator |
| EMP-007 | 409 | Employee already transferred | Duplicate event | Check transfer record |
| EMP-008 | 500 | Database error | Transaction failed | Retry or contact support |

---

## 12. Performance Considerations

### 12.1 Indexing Strategy
```sql
-- Already in DDL (should be added if not present)
CREATE INDEX idx_emp_email ON sch_employees(email);
CREATE INDEX idx_emp_department ON sch_employees(department_id, is_active);
CREATE INDEX idx_emp_designation ON sch_employees(designation_id, is_active);
CREATE INDEX idx_emp_status ON sch_employees(is_active, deleted_at);
CREATE INDEX idx_emp_joining ON sch_employees(date_of_joining);
```

### 12.2 Query Optimization
- Paginate list view (25 per page max)
- Load related data (dept, desig, role) via eager loading
- Use database cursors for large Excel imports
- Cache role/dept/designation dropdowns (5-minute TTL)

### 12.3 Caching Strategy
- Employee list: Cache 5 minutes
- Department/Designation dropdowns: Cache 1 hour
- Individual employee profile: Cache 10 minutes (invalidate on edit)

---

## 13. Document & Media Management

### 13.1 Supported Document Types
- Profile Photo: PNG, JPG (Max 5 MB)
- ID Proof: PDF, JPG (Max 10 MB)
- Educational Certificates: PDF (Max 10 MB)
- Work Experience Certificates: PDF (Max 10 MB)
- Medical/Health Certificate: PDF (Max 10 MB)

### 13.2 Storage
- Store in `sys_media` table
- Path: `storage/employees/{tenant_id}/{employee_id}/`
- Generate thumbnail for images
- Soft delete on file removal (set deleted_at)

---

## 14. Integration Points

### 14.1 Dependent Screens
- **SR-EM-03:** Shift Assignment requires employee existence
- **SR-EM-08:** Leave Balance & Applications requires employee existence
- **SR-EM-10:** Transfer/Promotion requires employee existence
- **SmartTimetable:** Teacher assignment requires employee existence

### 14.2 Notification Events
- Employee created → Send welcome email
- Employee archived → Notify HR/Admin
- Probation ending soon → Send reminder (3 days before)

---

## 15. Testing Checklist

- [ ] Create employee with all fields
- [ ] Validate email uniqueness
- [ ] Validate phone format (10 digits)
- [ ] Validate age >= 18
- [ ] Auto-calculate probation end date
- [ ] Edit employee information
- [ ] Soft delete and restore employee
- [ ] Bulk import with validation
- [ ] Permission-based field visibility
- [ ] Export employee list

---

**Next Steps:** 
- Implement create/edit forms with validation
- Build Excel import parser
- Create employee list view with pagination
- Add document upload functionality
- Implement soft delete with restore option

