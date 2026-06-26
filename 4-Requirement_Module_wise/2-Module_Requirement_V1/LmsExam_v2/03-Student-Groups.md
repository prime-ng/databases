# Business Requirements Document (BRD)
## Module: LMS Examination
### Sub-Module: Exam Masters 
### Screen: Student Groups

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
While most standard examinations (like Annual Exams) are conducted uniformly across an entire Class and Section, schools frequently need to conduct specialized assessments for specific cohorts of students. 
For example:
- **Remedial Classes:** An English test designed only for 10 students who failed the previous term.
- **Advanced Olympiads:** A high-difficulty math exam for top performers spanning across Sections A, B, and C.
- **Batch Divisions:** Dividing a computer science lab exam into "Batch 1" and "Batch 2".

The **Student Groups** configuration screen solves this by allowing school administrators to define these ad-hoc, specialized cohorts.

### 1.2 Why is this necessary? (Business Justification)
- **Targeted Allocations:** Without Student Groups, an exam would have to be manually mapped to 50 individual students one by one. By creating a "Group" first, the Exam Creation module can simply allocate the exam to "Batch 1", instantly mapping all underlying students.
- **Code Standardization:** The backend handles automatic code generation (e.g., `GRP_10_A_XYZ1`) to ensure that thousands of dynamic groups created over the years do not suffer from naming collisions, keeping database records clean.

---

## 2. Document Scope
- **In-Scope:** The definition of the group container (Name, Code, linked Class, and Section). Handling composite uniqueness. Protecting groups from deletion if they are mapped to live exam allocations.
- **Out-of-Scope:** Assigning actual students to these groups (This is handled in the `Group Members` screen).

---

## 3. User Personas
1. **Exam Coordinator / Class Teacher:** Frequently creates these groups when they need to segment students for upcoming specialized tests.
2. **System Administrator:** Oversees the groups to ensure no redundant or orphan groups are cluttering the system.

---

## 4. Detailed Functional Requirements (FR)

### FR-01: Initialization & Group Creation
- **Action:** Authorized users select a **Class** and a **Section**, then provide a custom **Name** (e.g., "Remedial Math").
- **System Behavior (Auto-Code Generation):** If the user leaves the `Code` field blank, the Model's logic automatically generates a unique string combining the Class, Section, and a random identifier (e.g., `GRP_10_A_829`).
- **Composite Validation:** The system strictly checks the `uq_esg_code` constraint. A specific Code cannot be duplicated within the *exact same* Class and Section.

### FR-02: Data Grid & Cascading Filters
- **Action:** Users view the configured groups in a grid.
- **System Behavior:** 
  - To prevent UI clutter for large schools, the search bar includes dedicated dropdowns for `Class` and `Section`.
  - The Class and Section data on the grid are displayed as visually distinct badges for quick readability.

### FR-03: Editing a Group
- **Action:** Users attempt to rename the group or change its code.
- **Critical Business Constraint (Allocation Guard):** 
  - The `ExamStudentGroupUsageCheckService` queries the `lms_exam_allocations` table.
  - *If mapped:* The system strictly blocks the edit form. *Rationale: If an exam was assigned to "Batch 1", renaming it to "Batch 2" mid-exam would logically break the exam's allocation target and corrupt the assessment tracking.*

### FR-04: Lifecycle Management (Archive & Restore)
- **Action:** Users can Trash (soft-delete), Restore, or permanently Force Delete a group.
- **Constraint:** Completely blocked if the group is allocated to any exam. Only unused, orphan groups can be permanently purged.

---

## 5. Agile User Stories & Acceptance Criteria

### Epic: Specialized Cohort Management
#### Story 1: Auto-generating a secure Group Code
**As a** Class Teacher,
**I want to** quickly create a group named "Science Project Team" without worrying about creating a unique system code,
**So that** I can save time and let the system handle background data integrity.

**Acceptance Criteria:**
- **Given** I leave the Code field empty, **When** I click submit, **Then** the backend's `generateCode()` method creates a unique string and saves the record successfully.

#### Story 2: Enforcing Allocation Integrity
**As an** Exam Coordinator,
**I want to** block the deletion of any group that is currently scheduled to take a test,
**So that** the students in that group do not suddenly lose access to their upcoming exam paper.

**Acceptance Criteria:**
- **Given** "Remedial Batch" is allocated to tomorrow's English Exam, **When** an admin clicks Delete on the group, **Then** the action is aborted with a flash error: *"Cannot delete this group because it is allocated to exams."*

---

## 6. Business Data Dictionary & Validations

| Field Name | Data Type | UI Element | Mandatory? | Business Validations & Rules |
|------------|-----------|------------|------------|------------------------------|
| **Class ID** | Integer | Dropdown | **Yes** | Must securely map to a valid, active `sch_classes.id`. |
| **Section ID** | Integer | Dropdown | **Yes** | Must securely map to a valid, active `sch_sections.id`. |
| **Name** | String | Text Input | **Yes** | Max 100 characters. E.g., "Olympiad Advanced". |
| **Code** | String | Text Input | **Yes (UI)** | Max 50 characters. Database enforces unique composite key `uq_esg_code (class_id, section_id, code)`. |
| **Description**| String | Text Area | No | Max 255 characters. |

---

## 7. Exception & Error Handling Scenarios

1. **Scenario: Composite Duplicate Constraint**
   - *Trigger:* User manually types a code `SET-A` for Class 9, Section A, when `SET-A` already exists for Class 9, Section A.
   - *System Response:* Form validation fails indicating the code is not unique for this specific Class and Section.
2. **Scenario: Exam Allocation Lock**
   - *Trigger:* User attempts to edit or delete a group that exists in `lms_exam_allocations.exam_group_id`.
   - *System Response:* The action is aborted. Message: `"Cannot edit/delete this group because it is allocated to exams."`

---

## 8. Dependency & Impact Mapping

### 8.1 What this module depends on (Incoming Dependencies)
- **`sch_classes` (Classes Master):** Requires an active `class_id` to anchor the group.
- **`sch_sections` (Sections Master):** Requires an active `section_id` to restrict the group to a specific section.

### 8.2 What depends on this module (Outgoing Dependencies)
- **`lms_exam_student_group_members` (Group Roster):** This is the direct child table. Deleting a group cascade-deletes all its mapped students.
- **`lms_exam_allocations` (Exam Allocation/Scheduling):** Uses `exam_group_id` as the target demographic when dispatching an exam paper.
  - *Business Impact:* If a group is deleted or its parameters altered while it is actively allocated, all students within that group will immediately lose authorization to access their scheduled live exams.

---

## 9. Database Schema

**Table Name**: `lms_exam_student_groups`

| Column Name | Data Type | Properties |
|-------------|-----------|------------|
| `id` | INT UNSIGNED| Primary Key, Auto Increment |
| `class_id` | INT UNSIGNED| NOT NULL, Foreign Key (`sch_classes.id`) |
| `section_id`| INT UNSIGNED| NOT NULL, Foreign Key (`sch_sections.id`) |
| `code` | VARCHAR(50) | NOT NULL, UNIQUE (`class_id`, `section_id`, `code`) |
| `name` | VARCHAR(100)| NOT NULL |
| `description`| VARCHAR(255)| NULLABLE |
| `is_active` | TINYINT(1)| DEFAULT 1 |
| `created_at` | TIMESTAMP | |
| `updated_at` | TIMESTAMP | |
| `deleted_at` | TIMESTAMP | NULLABLE (SoftDeletes) |

---

## 10. API / Routes Reference

| Route Name | Method | URI Pattern | Controller Action |
|------------|--------|-------------|-------------------|
| `lms-exam.exam-student-group.index` | GET | `/lms-exam/exam-student-group` | `ExamStudentGroupController@index` |
| `lms-exam.exam-student-group.create` | GET | `/lms-exam/exam-student-group/create` | `ExamStudentGroupController@create` |
| `lms-exam.exam-student-group.store` | POST | `/lms-exam/exam-student-group` | `ExamStudentGroupController@store` |
| `lms-exam.exam-student-group.show` | GET | `/lms-exam/exam-student-group/{id}` | `ExamStudentGroupController@show` |
| `lms-exam.exam-student-group.edit` | GET | `/lms-exam/exam-student-group/{id}/edit` | `ExamStudentGroupController@edit` |
| `lms-exam.exam-student-group.update` | PUT/PATCH | `/lms-exam/exam-student-group/{id}` | `ExamStudentGroupController@update` |
| `lms-exam.exam-student-group.destroy` | DELETE | `/lms-exam/exam-student-group/{id}` | `ExamStudentGroupController@destroy` |
| `lms-exam.exam-student-group.trashed` | GET | `/lms-exam/exam-student-group/trash/view` | `ExamStudentGroupController@trashed` |
| `lms-exam.exam-student-group.restore` | GET | `/lms-exam/exam-student-group/{id}/restore` | `ExamStudentGroupController@restore` |
| `lms-exam.exam-student-group.forceDelete` | DELETE | `/lms-exam/exam-student-group/{id}/force-delete`| `ExamStudentGroupController@forceDelete` |
| `lms-exam.exam-student-group.toggleStatus`| POST | `/lms-exam/exam-student-group/{id}/toggle-status`| `ExamStudentGroupController@toggleStatus` (AJAX) |
