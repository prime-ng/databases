# BRD-01: Student Onboarding & Core Profile Management

## 1. Business Need

### 1.1 Problem Statement
Schools lack a standardized, step-by-step process to admit new students, capture their identity information, and create their system login credentials. Currently, new student setup may involve multiple uncoordinated data entries, leading to duplicate records, inconsistent data, and delays in providing students with access to school portals.

### 1.2 Business Objectives
- Reduce the time to admit a new student from days to minutes
- Ensure all mandatory student identity information is captured in one structured workflow
- Eliminate duplicate student records by enforcing unique identifiers
- Provide students and parents with login credentials immediately upon admission
- Maintain a searchable, filterable registry of all students (current and past)

---

## 2. Scope

### 2.1 In Scope
- Student system login account creation
- Student core demographic profile capture (name, DOB, gender, ID documents)
- Extended profile (religion, caste, nationality, mother tongue, bank details)
- Physical attributes snapshot (height, weight)
- Student photo upload and management
- Multiple address capture (permanent, correspondence, guardian, local)
- Student listing with search, filter, sort
- Student detail view (360° profile)
- Student status management (activate/deactivate)
- Student record deletion, restoration, and permanent removal

### 2.2 Out of Scope
- Family/guardian details (covered in BRD-02)
- Academic session allocation (covered in BRD-03)
- Document uploads (covered in BRD-03)
- Health records (covered in BRD-04)
- Fee management (separate module)

---

## 3. Stakeholders

| Stakeholder | Interest |
|---|---|
| School Admin | Responsible for admitting students, maintaining accurate records |
| Clerk/Admission Officer | Performs day-to-day data entry for new admissions |
| Principal | Requires visibility into student demographics and admission trends |
| Parent | Needs login credentials to access Parent Portal |
| Student | Needs login credentials for Student Portal |
| Academic Coordinator | Uses student data for class allocation planning |
| IT/System Admin | Manages system configuration and user accounts |

---

## 4. User Roles & Permissions

| Role | View | Create | Edit | Delete | Restore | Export |
|---|---|---|---|---|---|---|
| Super Admin | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| School Admin | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Principal | ✓ | ✗ | ✗ | ✗ | ✗ | ✓ |
| Teacher | ✓ | ✗ | Limited* | ✗ | ✗ | ✗ |
| Clerk | ✓ | ✓ | ✓ | ✗ | ✗ | ✓ |

*\*Teachers may only edit specific operational fields, not identity data.*

---

## 5. Functional Requirements

### 5.1 Student Login Account Creation
**As a** School Admin / Clerk,
**I want to** create a system login account for a new student
**So that** the student can access the Student Portal and receive official school credentials.

**Requirements:**
- FR-01: System shall generate a unique employee code for each student in format `STD-YYYY-NNNNNN`
- FR-02: System shall capture student email (unique across all users), short name (unique), and password
- FR-03: System shall assign the "Student" role to the new account automatically
- FR-04: System shall allow photo upload during account creation
- FR-05: System shall send an email notification to the student's email address with login credentials
- FR-06: System shall allow updating student login details (name, email, password, photo) at any time

### 5.2 Student Core Profile — Identity Information
**As a** School Admin / Clerk,
**I want to** capture the student's identity details
**So that** the school has an accurate, verifiable record of every enrolled student.

**Requirements:**
- FR-07: System shall capture the student's full name (first, middle, last) and automatically combine them for the system user name
- FR-08: System shall capture admission number (unique), admission date, gender, and date of birth
- FR-09: System shall capture government ID numbers: Aadhar (unique), APAAR ID, birth certificate number
- FR-10: System shall capture the student's current status (Active, Left, Suspended, Alumni, Withdrawn)
- FR-11: System shall validate that admission number and Aadhar ID are unique across all students
- FR-12: System shall auto-generate a QR code for the student based on their employee code

### 5.3 Extended Profile — Demographics & Financial
**As a** School Admin / Clerk,
**I want to** capture additional demographic and financial details
**So that** the school can generate government-mandated reports (caste, religion, RTE quota compliance).

**Requirements:**
- FR-13: System shall capture religion, caste category, nationality, and mother tongue from predefined dropdown lists
- FR-14: System shall capture bank account details (account number, bank name, IFSC code, branch, UPI ID)
- FR-15: System shall capture fee depositor PAN number for tax benefit processing
- FR-16: System shall capture RTE (Right to Education) and EWS (Economically Weaker Section) flags
- FR-17: System shall capture height, weight, and measurement date as a snapshot

### 5.4 Student Photo Management
**As a** School Admin / Clerk,
**I want to** upload and manage the student's photograph
**So that** the student can be visually identified on ID cards, profile views, and reports.

**Requirements:**
- FR-18: System shall accept photo uploads in JPG, JPEG, PNG, GIF, and WebP formats
- FR-19: System shall sync the student photo to their system login profile automatically
- FR-20: System shall allow removal and replacement of the student photo
- FR-21: System shall automatically generate multiple image sizes for different display contexts

### 5.5 Address Management
**As a** School Admin / Clerk,
**I want to** capture multiple addresses for a student
**So that** the school can communicate via the correct address and maintain permanent records.

**Requirements:**
- FR-22: System shall support multiple addresses per student with types: Permanent, Correspondence, Guardian, and Local
- FR-23: System shall allow the user to mark exactly one address as the primary communication address
- FR-24: System shall capture address line, city, and pincode for each address
- FR-25: System shall allow adding, editing, and removing addresses dynamically

### 5.6 Student List & Search
**As a** School Admin / Teacher / Principal,
**I want to** view a searchable, filterable list of all students
**So that** I can quickly find any student's information and take appropriate action.

**Requirements:**
- FR-26: System shall display students in a paginated table with key columns (Admission No, Name, Class-Section, Guardian, Gender, Status)
- FR-27: System shall support filtering by academic session, class, section, and status (Active/Alumni/Withdrawn)
- FR-28: System shall support omni-search by name, admission number, Aadhar number, or mobile number
- FR-29: System shall allow sorting by admission number and name
- FR-30: System shall provide quick actions from the list: View full profile, Edit, Print ID Card

### 5.7 Student 360° Profile View
**As a** School Admin / Teacher / Principal,
**I want to** see a comprehensive view of a student's complete profile
**So that** I can understand the student's background, current status, and history at a glance.

**Requirements:**
- FR-31: System shall display a consolidated view showing: basic details, photo, class-section, guardian info, contact, address
- FR-32: System shall provide tabbed sub-navigation: Overview, Attendance, Academics, Fees, Health, Timeline, Documents

### 5.8 Student Status Management
**As a** School Admin,
**I want to** activate or deactivate a student's record
**So that** I can manage access and ensure only active students appear in operational reports.

**Requirements:**
- FR-33: System shall allow toggling a student's active/inactive status via a single click
- FR-34: Inactive students shall be excluded from daily operational views but remain in historical records

### 5.9 Student Record Lifecycle (Delete/Restore)
**As a** School Admin / Super Admin,
**I want to** remove, restore, or permanently delete student records
**So that** I can manage data retention in compliance with school policies.

**Requirements:**
- FR-35: System shall soft-delete student records (hide from list, retain in database)
- FR-36: System shall provide a trash/recycle bin view showing all soft-deleted students
- FR-37: System shall allow restoring soft-deleted students with all their data intact
- FR-38: System shall allow permanent deletion (force delete) of already soft-deleted records
- FR-39: System shall support bulk operations: restore all, bulk restore, bulk force delete, empty trash

### 5.10 Student Data Export
**As a** School Admin / Clerk,
**I want to** export the student list to Excel
**So that** I can share data with authorities or perform offline analysis.

**Requirements:**
- FR-40: System shall provide an Excel export of the student list based on current filters

---

## 6. Business Rules

| Rule ID | Rule Description |
|---|---|
| BR-01 | A student must have a unique admission number — no two students can share the same admission number |
| BR-02 | A student must have a unique Aadhar ID if provided |
| BR-03 | A student must have a unique system user login (email must be unique) |
| BR-04 | The student's full name (first + middle + last) must not exceed 100 characters |
| BR-05 | Height must be between 30 cm and 300 cm; weight must be between 1 kg and 500 kg |
| BR-06 | Measurement date must be provided if height or weight is entered |
| BR-07 | A student can have only one primary address at any time — setting one as primary removes primary status from others |
| BR-08 | Soft-deleting a student cascades to all their related records (sessions, addresses, documents, etc.) |
| BR-09 | Only already soft-deleted records can be permanently deleted |
| BR-10 | The student QR code is auto-generated on first save and never regenerated |

---

## 7. Workflow: New Student Admission

```
Step 1: Admin clicks "+ New Admission"
        ↓
Step 2: Enter basic identity (name, DOB, gender, admission number, IDs)
        ↓
Step 3: Upload student photograph (optional)
        ↓
Step 4: Enter demographic details (religion, caste, nationality, bank details)
        ↓
Step 5: Enter addresses (at least one required)
        ↓
Step 6: Review and Save
        ↓
Step 7: System creates login account, sends credentials email
        ↓
Step 8: System advances to next section (Family/Guardians — see BRD-02)
```

---

## 8. Acceptance Criteria

| Criterion | Description |
|---|---|
| AC-01 | Admin can complete a new student admission in 5 minutes or less |
| AC-02 | Duplicate admission numbers are rejected with a clear error message |
| AC-03 | Duplicate Aadhar IDs are rejected with a clear error message |
| AC-04 | Email notification is sent within 1 minute of student login creation |
| AC-05 | Student appears in the student list immediately after creation |
| AC-06 | Search returns results within 2 seconds for a database of 10,000+ students |
| AC-07 | Soft-deleted students disappear from the main list and appear in the trash view |
| AC-08 | Restored students return with all associated data intact |
| AC-09 | A student can have a maximum of one primary address at any time |
| AC-10 | Excel export includes all columns visible in the current filtered view |

---

## 9. Dependencies

| Dependency | Description |
|---|---|
| System Users Module | Student login requires the core user management system |
| RBAC/Roles Module | Student role must exist in the system for role assignment |
| Global Masters | Cities/states lookups for addresses; dropdowns for religion, caste, etc. |
| Email System | SMTP/Mail configuration must be active for credential emails |
| Media Library | Photo storage requires Spatie Media Library setup |

---

## 10. Assumptions

- A school or system admin will be performing the admission process (not parents self-registering)
- The admission number is assigned by the school following their internal numbering scheme
- Email server is configured and operational for sending credential notifications
- Student photos will be uploaded as image files (not captured via webcam in the system)

---

*End of BRD-01*
