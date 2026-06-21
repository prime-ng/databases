# BRD-02: Family & Guardian Management

**Document Version:** 1.0
**Date:** 2026-05-21
**Author:** Business Analyst
**Status:** Draft

---

## 1. Business Need

### 1.1 Problem Statement
Schools need to maintain accurate parent/guardian information for every student for emergency contacts, fee collection, parent-teacher communication, and Parent Portal access. When siblings attend the same school, their guardian information is often entered multiple times, creating duplicate records and inconsistent data. Parents who have multiple children in the school should not have to provide their details more than once.

### 1.2 Business Objectives
- Capture complete guardian information (Father, Mother, Guardian) for each student
- Automatically detect and link existing guardians when siblings are admitted
- Eliminate duplicate guardian records across sibling students
- Provide parents with login credentials for the Parent Portal
- Define granular permissions per guardian (fee payer, emergency contact, pickup authorization, notification preferences)

---

## 2. Scope

### 2.1 In Scope
- Guardian master record creation (shared across siblings)
- Mobile number-based duplicate detection
- Linking existing guardians to new students
- Multi-guardian support per student (Father, Mother, Guardian)
- Guardian permissions (emergency contact, pickup, fee payer, portal access, notifications)
- Parent Portal user account creation
- Guardian photo upload
- Guardian record update and deletion

### 2.2 Out of Scope
- Student identity details (covered in BRD-01)
- Parent Portal screens and features (separate portal module)
- SMS/email notification delivery (covered by Notification module)
- Fee payment by guardian (covered by Student Fee module)

---

## 3. Stakeholders

| Stakeholder | Interest |
|---|---|
| School Admin | Needs accurate guardian records for communication and compliance |
| Clerk/Admission Officer | Enters guardian data during admission |
| Parent | Needs Parent Portal access to monitor child's progress |
| Class Teacher | Requires emergency contact information |
| Transport Manager | Needs pickup authorization information |
| Accountant | Needs fee payer identification |
| Student | Benefits from parent involvement via portal |

---

## 4. User Roles & Permissions

| Role | View Guardian | Create Guardian | Edit Guardian | Delete Guardian |
|---|---|---|---|---|
| Super Admin | ✓ | ✓ | ✓ | ✓ |
| School Admin | ✓ | ✓ | ✓ | ✓ |
| Principal | ✓ | ✗ | ✗ | ✗ |
| Clerk | ✓ | ✓ | ✓ | ✗ |
| Teacher | ✓ | ✗ | ✗ | ✗ |

---

## 5. Functional Requirements

### 5.1 Guardian Record Creation
**As a** School Admin / Clerk,
**I want to** create guardian records for a student
**So that** the school has accurate parent/guardian contact information.

**Requirements:**
- FR-01: System shall support adding multiple guardians per student (typically Father and Mother)
- FR-02: System shall capture guardian details: first name, last name, gender, mobile number, email, phone number
- FR-03: System shall capture professional details: occupation, qualification, annual income
- FR-04: System shall support guardian types: Father, Mother, Guardian
- FR-05: System shall support relationship types: Father, Mother, Uncle, Brother, Sister, Grandfather, Grandmother, Guardian, etc.

### 5.2 Duplicate Guardian Detection (Sibling Linking)
**As a** School Admin / Clerk,
**I want to** search for and link existing guardians when admitting a new student
**So that** siblings automatically share the same guardian record without data duplication.

**Requirements:**
- FR-06: System shall detect an existing guardian when a mobile number is entered and prompt the user to link
- FR-07: System shall auto-fill guardian details from the existing record when linking
- FR-08: System shall allow the user to choose between linking to an existing guardian or creating a new one
- FR-09: When linked, the guardians shall be shared across all sibling students
- FR-10: System shall display a warning when the same mobile number is linked to multiple students

### 5.3 Guardian Permissions Configuration
**As a** School Admin,
**I want to** set permissions for each guardian per student
**So that** I can control who can pick up the child, who pays fees, and who receives communications.

**Requirements:**
- FR-11: System shall allow marking a guardian as an Emergency Contact
- FR-12: System shall allow authorizing a guardian to pick up the child from school
- FR-13: System shall allow marking a guardian as the Fee Payer
- FR-14: System shall allow granting Parent Portal access to a guardian
- FR-15: System shall allow setting notification preferences (Email, SMS, WhatsApp, or All)
- FR-16: System shall allow controlling whether a guardian can receive notifications

### 5.4 Parent Portal User Account
**As a** School Admin,
**I want to** create Parent Portal login accounts for guardians
**So that** parents can access the portal to view their child's attendance, grades, and communicate with teachers.

**Requirements:**
- FR-17: System shall auto-create a system user account when a new guardian is added
- FR-18: System shall assign the "Parent" role to the account
- FR-19: System shall auto-generate a parent code in format `PRN-YYYY-NNNNN`
- FR-20: System shall share one parent user account across all guardians for the same student
- FR-21: System shall allow updating parent login details (name, email, mobile, password)

### 5.5 Guardian Photo Upload
**As a** School Admin / Clerk,
**I want to** upload a photo for each guardian
**So that** the school can identify parents at pickup time or on Parent Portal profiles.

**Requirements:**
- FR-22: System shall accept guardian photo uploads in JPG, JPEG, PNG, and GIF formats
- FR-23: System shall allow replacing the guardian photo

### 5.6 Guardian Record Update & Removal
**As a** School Admin / Clerk,
**I want to** update or remove guardian information
**So that** records stay current when parents change contact details or relationships.

**Requirements:**
- FR-24: System shall allow updating all guardian fields (name, contact, occupation, permissions)
- FR-25: System shall sync guardian changes to the linked parent user account (name, email, mobile)
- FR-26: System shall allow removing the link between a guardian and a student
- FR-27: System shall only delete a guardian record if no other students are linked to it

---

## 6. Business Rules

| Rule ID | Rule Description |
|---|---|
| BR-01 | Each guardian is uniquely identified by their mobile number |
| BR-02 | A guardian's mobile number must be unique across the system |
| BR-03 | A specific guardian can be linked to a specific student only once |
| BR-04 | A guardian can be linked to multiple students (siblings) |
| BR-05 | A student can have multiple guardians, but each with a distinct relationship type |
| BR-06 | At least one guardian must be linked to every student |
| BR-07 | When a guardian is deleted, the parent user account is NOT deleted (only unlinked) |
| BR-08 | Parent user accounts are shared: changing guardian details syncs to the parent's login |
| BR-09 | If a linked guardian already has a user account, it is reused (not duplicated) |

---

## 7. Workflow: Adding Guardians During Admission

```
Step 1: After saving student details, system advances to Parent Details tab
        ↓
Step 2: Admin enters Father's mobile number
        ↓
Step 3: System checks: Does this mobile exist for another guardian?
        ├── YES → Show existing guardian details → Admin confirms linking
        └── NO  → Admin fills in new guardian details
                    ↓
Step 4: Admin enters Mother's details (if applicable), repeating Step 2-3
        ↓
Step 5: Admin configures permissions per guardian:
        - Is Emergency Contact?
        - Can Pickup?
        - Is Fee Payer?
        - Portal Access?
        - Notification Preference?
        ↓
Step 6: Admin clicks Save
        ↓
Step 7: System creates/links guardians, creates parent user account
        ↓
Step 8: System advances to next section (Session Details — see BRD-03)
```

---

## 8. Acceptance Criteria

| Criterion | Description |
|---|---|
| AC-01 | Admin can add Father + Mother + Guardian in under 3 minutes |
| AC-02 | Entering an existing mobile number auto-suggests the existing guardian |
| AC-03 | When linking an existing guardian, no duplicate guardian record is created |
| AC-04 | Sibling students share the same guardian record (verified via database query) |
| AC-05 | Parent Portal login credentials are created immediately upon guardian save |
| AC-06 | Updating a guardian's mobile number syncs to the Parent Portal account |
| AC-07 | At least one guardian must be present for a student to have a "complete" profile |

---

## 9. Dependencies

| Dependency | Description |
|---|---|
| BRD-01 — Student Onboarding | Guardian linking requires an existing student record |
| System Users Module | Parent Portal accounts require the core user management system |
| RBAC/Roles Module | Parent role must exist for role assignment |
| Notification Module | For sending credentials and notifications based on preferences |

---

## 10. Assumptions

- Every student has at least one guardian (typically Father or Mother)
- Mobile number is the primary identifier for guardians (not email)
- Some guardians may not need or want Parent Portal access
- The school will provide guardian contact details during admission, not self-registration

---

*End of BRD-02*
