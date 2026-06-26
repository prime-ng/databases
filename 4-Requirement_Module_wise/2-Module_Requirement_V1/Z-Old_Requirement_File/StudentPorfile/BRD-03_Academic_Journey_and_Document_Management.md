# BRD-03: Academic Journey & Document Management

**Document Version:** 1.0
**Date:** 2026-05-21
**Author:** Business Analyst
**Status:** Draft

---

## 1. Business Need

### 1.1 Problem Statement
Schools need to track every student's academic journey across school years — which class and section they were in each year, their roll numbers, house assignments, subject choices, and promotion history. Additionally, schools must maintain previous education records and scanned documents (transfer certificates, ID proofs, mark sheets) for compliance and audit purposes. Without a structured system, this information is scattered across registers, making it difficult to generate accurate student histories and government-required reports.

### 1.2 Business Objectives
- Maintain a complete chronological history of every student's class and section assignments
- Enable smooth promotion/transfer workflows with automatic historical record preservation
- Allow students to select optional subjects according to their subject group
- Capture previous school history for all transfer-in students
- Store and verify student documents digitally with an audit trail
- Support roll number assignment within each class-section

---

## 2. Scope

### 2.1 In Scope
- Academic session allocation (class, section, roll number)
- Promotion from one class to the next across academic years
- House assignment (Red, Blue, Green, Yellow, etc.)
- Subject group assignment for stream-based classes
- Optional subject selection per student per session
- Previous school education records
- Student document upload and verification
- Missing optional subject detection

### 2.2 Out of Scope
- Timetable generation (covered by SmartTimetable module)
- Exam results and grade tracking (covered by Exam module)
- Syllabus and lesson planning (covered by Syllabus module)
- Fee calculation per academic session (covered by Fee module)

---

## 3. Stakeholders

| Stakeholder | Interest |
|---|---|
| School Admin | Manages class promotions, subject allocations |
| Clerk/Admission Officer | Assigns students to classes, captures previous education |
| Academic Coordinator | Plans class strengths, allocates sections |
| Class Teacher | Receives student rosters, needs access to historical records |
| Principal | Needs visibility into class-wise strength and promotion data |
| Student | Needs subject selection capability for optional subjects |
| Parent | Wants to understand child's academic placement |

---

## 4. User Roles & Permissions

| Role | View | Create | Edit | Delete |
|---|---|---|---|---|
| Super Admin | ✓ | ✓ | ✓ | ✓ |
| School Admin | ✓ | ✓ | ✓ | ✓ |
| Principal | ✓ | ✗ | ✗ | ✗ |
| Clerk | ✓ | ✓ | ✓ | ✗ |
| Teacher | ✓ | ✗ | ✗ | ✗ |

---

## 5. Functional Requirements

### 5.1 Academic Session Allocation
**As a** School Admin / Clerk,
**I want to** assign a student to a class and section for an academic year
**So that** the student's academic placement is recorded in the system.

**Requirements:**
- FR-01: System shall allow assigning a student to a specific class and section for a given academic session
- FR-02: System shall capture the student's roll number within the class-section
- FR-03: System shall assign the student to a house (Red, Blue, Green, Yellow, etc.)
- FR-04: System shall capture which subject group (stream) the student belongs to
- FR-05: System shall track the student's session status (Active, Promoted, Left, Suspended, Alumni, Withdrawn)

### 5.2 Promotion Workflow
**As a** School Admin / Clerk,
**I want to** promote a student to the next class for a new academic year
**So that** the student's academic progression is recorded and historical data is preserved.

**Requirements:**
- FR-06: System shall allow promoting a student by selecting a new session, new class, and new section
- FR-07: System shall mark the previous session's record as historical (not current) when promoting
- FR-08: System shall preserve all previous session records for the student's academic history
- FR-09: System shall require setting the session status when promoting (e.g., "Promoted")
- FR-10: System shall update the class-section's student count automatically when a student joins or leaves

### 5.3 Optional Subject Selection
**As a** School Admin / Clerk,
**I want to** manage which optional subjects each student takes
**So that** students in higher classes can customize their subject choices according to their stream.

**Requirements:**
- FR-11: System shall display available optional subjects based on the student's class and subject group
- FR-12: System shall allow selecting core (mandatory) and optional subjects per student
- FR-13: System shall ensure a student cannot select the same subject twice in the same session
- FR-14: System shall detect and flag students who have NOT completed their optional subject selection
- FR-15: System shall display a dedicated view showing all students with missing optional subject selections

### 5.4 Previous Education Records
**As a** School Admin / Clerk,
**I want to** capture a student's education history from previous schools
**So that** the school has a complete academic background for admission and audit purposes.

**Requirements:**
- FR-16: System shall capture previous school name, address, board (CBSE, ICSE, State Board, etc.)
- FR-17: System shall capture class passed, year of passing, percentage/grade, and medium of instruction
- FR-18: System shall capture Transfer Certificate (TC) number and date
- FR-19: System shall allow adding multiple previous school entries per student
- FR-20: System shall capture whether the previous school was recognized

### 5.5 Student Document Management
**As a** School Admin / Clerk,
**I want to** upload and manage student documents
**So that** important records (Transfer Certificates, ID proofs, Mark Sheets) are stored digitally and available for verification.

**Requirements:**
- FR-21: System shall support uploading student documents in PDF, JPG, JPEG, PNG, DOC, and DOCX formats
- FR-22: System shall capture document name, type (TC, Aadhar Card, Birth Certificate, etc.), and document number
- FR-23: System shall capture issue date, expiry date, and issuing authority
- FR-24: System shall support a document verification workflow — admin can mark documents as verified
- FR-25: System shall record who verified the document and when
- FR-26: System shall allow unlimited documents per student
- FR-27: System shall enforce that expiry date, if provided, is after the issue date
- FR-28: System shall display unverified documents as a dashboard alert for admin action

### 5.6 Missing Subject Detection
**As a** Academic Coordinator / School Admin,
**I want to** see which students have not completed their optional subject selections
**So that** I can follow up and ensure all students have chosen their subjects before the academic term begins.

**Requirements:**
- FR-29: System shall display a dedicated tab showing only students with incomplete optional subject selections
- FR-30: System shall detect two cases: (a) students with subject groups but missing selections, and (b) students whose class offers optional subjects but have no subject group assigned

---

## 6. Business Rules

| Rule ID | Rule Description |
|---|---|
| BR-01 | A student can have only ONE current (active) session at any time |
| BR-02 | A student can have only ONE record per academic session (cannot be in two classes in the same year) |
| BR-03 | When a student is promoted to a new session, the old session is automatically marked as historical |
| BR-04 | Previous education records are optional (new admission students may not have prior schooling) |
| BR-05 | A student's optional subjects for a session are wiped and re-created when the session is updated |
| BR-06 | The same subject cannot be selected twice within the same session |
| BR-07 | Class-section student counts are auto-updated when students are added, removed, or promoted |

---

## 7. Workflow: Student Promotion

```
Step 1: Admin navigates to student's Academic tab in Edit mode
        ↓
Step 2: Admin clicks "Promote / Transfer"
        ↓
Step 3: Admin selects New Academic Session (e.g., 2026-27)
        ↓
Step 4: Admin selects New Class (e.g., Class 10)
        ↓
Step 5: Admin selects New Section (e.g., Section A)
        ↓
Step 6: Admin sets Session Status (e.g., "Promoted")
        ↓
Step 7: System saves the new session record
        ↓
Step 8: System marks the old session as NOT current
        ↓
Step 9: System updates class-section student counts for both old and new sections
        ↓
Step 10: Student's new class-section appears as the current placement
```

---

## 8. Acceptance Criteria

| Criterion | Description |
|---|---|
| AC-01 | Admin can promote a student from Class 9 to Class 10 with 3 clicks |
| AC-02 | After promotion, old session shows as historical with `is_current = false` |
| AC-03 | Student's 360° profile shows the complete academic history across all years |
| AC-04 | Optional subject selection enforces unique subjects within a session |
| AC-05 | Missing subject tab shows at least one student when optional subjects are unassigned |
| AC-06 | Previous education entries are stored and visible on the student's profile |
| AC-07 | Uploaded documents appear in the student's document section with verification status |
| AC-08 | Admin can mark a document as verified and see who verified it and when |
| AC-09 | Dashboard shows count of unverified documents needing attention |

---

## 9. Dependencies

| Dependency | Description |
|---|---|
| BRD-01 — Student Onboarding | Academic allocation requires an existing student record |
| School Setup Module | Classes, sections, subject groups, houses must be pre-configured |
| Global Masters | Academic sessions must be created before assignment |
| BRD-02 — Guardian Management | Completed before academic session tab in the admission flow |
| Media Library | Document uploads require Spatie Media Library |

---

## 10. Assumptions

- Academic sessions are pre-configured by the school admin before student allocation
- Class sections have a configured maximum capacity (soft-check on assignment)
- Subject groups and their subject mappings are pre-configured
- Optional subjects are only relevant for higher classes (typically Class 9 and above)
- Documents are uploaded by school staff during/after admission (not self-uploaded by parents)

---

*End of BRD-03*
