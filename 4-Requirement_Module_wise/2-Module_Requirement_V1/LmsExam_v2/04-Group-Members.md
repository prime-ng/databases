# Business Requirements Document (BRD)
## Module: LMS Examination
### Sub-Module: Exam Masters 
### Screen: Group Members

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
Creating an empty "Student Group" (e.g., *Remedial Math*) is only the first half of the process. The **Group Members** screen acts as the operational mapping interface where individual student profiles are securely bound to that specific group. This junction mapping is what actually determines *who* gets to see and take the specialized exam on their portal.

### 1.2 Why is this necessary? (Business Justification)
- **Bulk Operational Efficiency:** Adding students to an exam one by one is an administrative nightmare. This module is built heavily for bulk operations. A teacher can filter a class, select 20 checkboxes, and instantly populate a group.
- **Silent Duplication Handling:** In a busy school, a teacher might forget that "John Doe" was already added to the "Olympiad Group" last week. The system's business logic handles duplicate additions silently, ensuring smooth UI operations without crashing or throwing confusing database errors.
- **Strict Data Junctioning:** The module strictly protects the composite uniqueness `(group_id, student_id)`. A student cannot logically exist in the exact same ad-hoc group twice.

---

## 2. Document Scope
- **In-Scope:** The bulk mapping of students to groups. Dynamic AJAX cascading filters to narrow down large student lists. The silent exclusion of duplicate entries. Restriction of UI actions (disabling view/edit).
- **Out-of-Scope:** Creating the actual groups or students (handled in their respective master modules).

---

## 3. User Personas
1. **Class Teacher / Subject Teacher:** The primary user. They know exactly which specific students need to be placed into which specialized test batches.
2. **Exam Coordinator:** Audits the groups to ensure no student is accidentally left out of an allocated exam.

---

## 4. Detailed Functional Requirements (FR)

### FR-01: AJAX Cascading Data Filters
- **Action:** A user wants to add members but the school has 5,000 students.
- **System Behavior:** The UI implements cascading dropdowns (`getGroupDetails` API). 
  - Selecting a *Class* automatically narrows down the *Section* and *Student* dropdowns.
  - Selecting a specific *Group* automatically forces the Class and Section filters to match the group's predefined boundaries, ensuring a teacher cannot add a Class 10 student to a Class 9 group.

### FR-02: Bulk Addition & Silent De-duplication (Store Logic)
- **Action:** The user submits an array of multiple `student_ids` to be added to a single `group_id`.
- **System Behavior:**
  - The Controller loops through the array.
  - For every student, it checks: *Does this student already exist in this group?*
  - **If Yes:** It silently skips the student.
  - **If No:** It inserts the record and writes a unique `activityLog` entry for that specific student.
  - *Result:* Returns a success message displaying the exact count of *new* members successfully added (e.g., "5 members added successfully").

### FR-03: Restricted Grid Actions
- **Action:** A user views the list of mapped members in the data grid.
- **System Constraint:** Unlike other masters, a junction mapping does not need a "Show Detail" page or an "Edit Form". The system enforces `show=false` and `edit=false` on the action buttons. The only valid action is **Delete** (Removing the student from the group).

### FR-04: Active Allocation Protection
- **Action:** A user attempts to remove a student from a group or edit their mapping via backend.
- **Critical Business Constraint:** 
  - The `ExamStudentGroupMemberUsageCheckService` validates if the *Parent Group* is currently allocated to a live exam.
  - *If mapped:* The system completely blocks the removal of the student. *Rationale: Removing a student from an allocated group right before or during an exam would instantly revoke their access and corrupt their active assessment session.*

---

## 5. Agile User Stories & Acceptance Criteria

### Epic: Junction Mapping & Bulk Enrollment
#### Story 1: Bulk Additions with Duplicate Safety
**As a** Class Teacher,
**I want to** select 10 students at once and add them to the "Set A" group, even if I accidentally selected 2 students who were already added yesterday,
**So that** I don't have to manually cross-check the list, saving me time.

**Acceptance Criteria:**
- **Given** John is already in Group A, **When** the teacher submits an array containing John and 3 new students, **Then** the system silently skips John, inserts the 3 new students, and shows: *"3 members added successfully."*

#### Story 2: Preventing Mid-Exam Roster Changes
**As an** Exam Coordinator,
**I want to** lock the group roster once it has been allocated to a live exam,
**So that** no teacher accidentally deletes a student from the group, thereby revoking their ability to take the test.

**Acceptance Criteria:**
- **Given** "Group A" is mapped to tomorrow's Science Exam, **When** a user clicks the Delete button next to a student in Group A, **Then** the action is aborted with a flash error: *"Cannot delete this member because the group is allocated to exams."*

---

## 6. Business Data Dictionary & Validations

| Field Name | Data Type | UI Element | Mandatory? | Business Validations & Rules |
|------------|-----------|------------|------------|------------------------------|
| **Group ID** | Integer | Dropdown | **Yes** | Must securely map to a valid `lms_exam_student_groups.id`. |
| **Student ID(s)**| Array/Int | Multi-Select | **Yes** | Must map to `std_students.id`. Database enforces composite unique key `uq_esgm_member (group_id, student_id)`. |

---

## 7. Exception & Error Handling Scenarios

1. **Scenario: Mismatched Class/Section Injection**
   - *Trigger:* A malicious or erroneous request tries to insert a Class 10 student into a Class 9 group via direct API manipulation.
   - *System Response:* While the UI prevents this via cascading dropdowns, any insertion that breaks logical boundaries is handled and logged appropriately.
2. **Scenario: Live Exam Roster Lock**
   - *Trigger:* Attempting to delete a member whose parent group is actively attached to `lms_exam_allocations`.
   - *System Response:* System aborts the transaction. Error Message: `"Cannot delete this member because the group is allocated to exams."`

---

## 8. Dependency & Impact Mapping

### 8.1 What this module depends on (Incoming Dependencies)
- **`lms_exam_student_groups` (Parent Group Master):** Requires an active `group_id`. You cannot add members to a non-existent group.
- **`std_students` (Student Master):** Requires an active `student_id`.

### 8.2 What depends on this module (Outgoing Dependencies)
- **No Direct Table Foreign Keys:** As a junction table, no other tables strictly define a foreign key referencing `lms_exam_student_group_members`.
- **Logical Dependency (`lms_exam_allocations`):** Although there is no DB foreign key, removing a member from this table acts as a permission revocation. If the parent group is currently attached to `lms_exam_allocations`, deleting a member effectively blocks that student from viewing or taking a live exam mid-flight.

---

## 9. Database Schema

**Table Name**: `lms_exam_student_group_members`

| Column Name | Data Type | Properties |
|-------------|-----------|------------|
| `id` | INT UNSIGNED| Primary Key, Auto Increment |
| `group_id` | INT UNSIGNED| NOT NULL, Foreign Key (`lms_exam_student_groups.id`) |
| `student_id`| INT UNSIGNED| NOT NULL, Foreign Key (`std_students.id`) |
| `created_at` | TIMESTAMP | |
| `updated_at` | TIMESTAMP | |
| `deleted_at` | TIMESTAMP | NULLABLE (SoftDeletes) |

*(Note: Unique Key enforced on `group_id, student_id`)*

---

## 10. API / Routes Reference

| Route Name | Method | URI Pattern | Controller Action |
|------------|--------|-------------|-------------------|
| `lms-exam.exam-group-member.index` | GET | `/lms-exam/exam-group-member` | `ExamStudentGroupMemberController@index` |
| `lms-exam.exam-group-member.create` | GET | `/lms-exam/exam-group-member/create` | `ExamStudentGroupMemberController@create` |
| `lms-exam.exam-group-member.store` | POST | `/lms-exam/exam-group-member` | `ExamStudentGroupMemberController@store` |
| `lms-exam.exam-group-member.destroy` | DELETE | `/lms-exam/exam-group-member/{id}` | `ExamStudentGroupMemberController@destroy` |
| `lms-exam.exam-group-member.trashed` | GET | `/lms-exam/exam-group-member/trash/view` | `ExamStudentGroupMemberController@trashed` |
| `lms-exam.exam-group-member.restore` | GET | `/lms-exam/exam-group-member/{id}/restore` | `ExamStudentGroupMemberController@restore` |
| `lms-exam.exam-group-member.forceDelete` | DELETE | `/lms-exam/exam-group-member/{id}/force-delete`| `ExamStudentGroupMemberController@forceDelete` |
| `lms-exam.get-group-details` | POST | `/lms-exam/get-group-details` | `ExamStudentGroupMemberController@getGroupDetails` (AJAX Cascade) |
