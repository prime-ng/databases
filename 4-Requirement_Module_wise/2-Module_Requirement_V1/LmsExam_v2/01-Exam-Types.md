# Business Requirements Document (BRD)
## Module: LMS Examination
### Sub-Module: Exam Masters 
### Screen: Exam Types

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
Every educational institution conducts multiple assessments throughout an academic year, varying significantly in their weightage, format, and purpose. The **Exam Types** module is the foundational configuration screen that allows an institution to define these broad categories (e.g., *Unit Tests, Half-Yearly Exams, Pre-Boards, Weekly Quizzes, Annual Examinations*).

### 1.2 Why is this necessary? (Business Justification)
- **Reporting & Analytics:** Without categorizing exams, generating comparative progress reports (e.g., comparing a student's performance across all "Unit Tests") is impossible. Exam Types act as the primary grouping mechanism.
- **Grading Schema Alignment:** Different exam types often follow different grading logics (e.g., Formative Assessments vs. Summative Assessments). Defining the type first is a prerequisite for mapping grading schemas.
- **System Organization:** It prevents clutter. When a teacher creates an exam, selecting a predefined "Type" ensures standardized nomenclature across the entire school rather than teachers creating arbitrary names.

---

## 2. Document Scope
- **In-Scope:** The ability for authorized administrative users to create, view, edit, search, toggle status (activate/deactivate), and archive (soft delete) standard exam classifications. It includes strict dependency checks to prevent data corruption.
- **Out-of-Scope:** The actual scheduling of exams, paper creation, and result generation are handled in subsequent workflow modules.

---

## 3. User Personas
1. **Exam Coordinator / Admin:** The primary owner of this screen. They configure the types at the beginning of the academic year.
2. **Teachers:** Secondary users. They do not have access to *create* or *edit* these types, but they *consume* this data from dropdowns when creating an actual exam paper.
3. **Principal / Management:** Consumers of reports. They filter analytics dashboards using these Exam Types.

---

## 4. Detailed Functional Requirements (FR)

### FR-01: Initialization & Creation
- **Action:** An authorized user can define a new Exam Type.
- **Fields Required:**
  - **Code (Unique):** A short, easily identifiable string (e.g., `UT`, `HY`, `PB`). Used as a quick reference in tables and APIs.
  - **Name:** The full descriptive title (e.g., `Unit Test`, `Half Yearly Exam`).
  - **Description:** An optional field to define the internal policy (e.g., "Monthly assessments carrying 10% weightage").
- **System Behavior:** Upon saving, the system trims whitespaces, validates uniqueness of the `Code` across the tenant, and sets the default status to **Active**.

### FR-02: Data Grid & Searchability (Index)
- **Action:** Users can view all configured Exam Types in a tabular format.
- **System Behavior:** 
  - The grid defaults to showing 10 records per page.
  - A persistent search bar must allow querying across `Code` and `Name`.
  - A status filter dropdown must allow filtering by "All", "Active", or "Inactive".

### FR-03: Editing an Exam Type
- **Action:** Users can click the "Edit" icon to modify typos or update the description.
- **Critical Business Constraint (Usage Guard):** 
  - The system must verify if this specific Exam Type is mapped to any record in the `lms_exams` table.
  - *If mapped (Used):* The system completely disables the edit form and throws a hard block error. *Rationale: Changing "Unit Test" to "Annual Exam" mid-year would logically corrupt all past Unit Test records and report cards.*
  - *If unmapped (Not Used):* The user can freely edit the Name, Code, and Description.

### FR-04: Lifecycle Management (Status Toggle & Soft Delete)
- **Action (Deactivation):** Instead of deleting, admins can toggle an Exam Type to "Inactive" via an inline switch.
  - *Impact:* The Exam Type remains visible in historical reports but disappears from the dropdowns when teachers try to create *new* exams.
- **Action (Archiving/Soft Delete):** Admins can click "Delete" to move the record to a Trash bin.
  - *Constraint:* Similar to Editing, the system strictly blocks deletion if the type is in use.
- **Action (Trash Management):** Admins can view trashed items and choose to either "Restore" them to active use or "Force Delete" them permanently (if completely unused).

---

## 5. Agile User Stories & Acceptance Criteria

### Epic: Exam Master Configuration
#### Story 1: Standardizing Assessment Nomenclature
**As an** Exam Coordinator,
**I want to** create distinct Exam Types like "Formative Assessment" and "Summative Assessment",
**So that** teachers use standardized categories when scheduling exams instead of making up their own names.

**Acceptance Criteria:**
- **Given** I am on the Exam Types tab, **When** I fill in "FA" for Code and "Formative Assessment" for Name, **Then** the record saves successfully.
- **Given** "FA" already exists, **When** I try to create another record with "FA", **Then** the system rejects it with a "Code must be unique" validation error.

#### Story 2: Preserving Historical Integrity
**As a** System Administrator,
**I want to** prevent the deletion or modification of an Exam Type that has already been used in an exam,
**So that** past student report cards linked to this Exam Type are not broken or misrepresented.

**Acceptance Criteria:**
- **Given** the Exam Type "UT-1" is linked to the "Class 9 Math Test", **When** I click the Edit or Delete button for "UT-1", **Then** the system blocks the action and shows an alert: *"Cannot edit/delete because it is being used in exams."*
- **Given** the Exam Type "UT-1" is linked to an exam, **When** I toggle the active switch to OFF, **Then** the status changes successfully, hiding it from future use without breaking past records.

---

## 6. Business Data Dictionary & Validations

| Field Name | Data Type | UI Element | Mandatory? | Business Validations & Rules |
|------------|-----------|------------|------------|------------------------------|
| **Code** | String | Text Input | **Yes** | Max 50 characters. Must be globally unique within the tenant's database to prevent conflict. |
| **Name** | String | Text Input | **Yes** | Max 100 characters. Represents the human-readable display name. |
| **Description**| String | Text Area | No | Max 255 characters. Used for internal school policy notes regarding the exam type. |
| **Active** | Boolean | Toggle | **Yes** | Defaults to True (1). Determines visibility in downstream transaction forms. |

---

## 7. Exception & Error Handling Scenarios

1. **Scenario: Unique Constraint Violation**
   - *Trigger:* User submits a new or updated Exam Type with a `Code` that already exists.
   - *System Response:* Form validation fails. Error Message: `"This exam type code already exists."`
2. **Scenario: Dependency Lock Violation**
   - *Trigger:* User attempts to Edit, Trash, Restore, or Force Delete an Exam Type actively linked to the `lms_exams` transaction table.
   - *System Response:* The Controller blocks the database transaction via the `ExamTypeUsageCheckService`. Flash Error Message: `"Cannot perform this action because it is being used in exams or exam papers."`
3. **Scenario: Unauthorized Access Attempt**
   - *Trigger:* A teacher without `tenant.exam-type.viewAny` permission attempts to access the URL directly.
   - *System Response:* System aborts with an HTTP 403 / 404 response.

---

## 8. Dependency & Impact Mapping

### 8.1 What this module depends on (Incoming Dependencies)
- **None:** `lms_exam_types` is a top-level independent master configuration.

### 8.2 What depends on this module (Outgoing Dependencies)
- **`lms_exams` (Exam Creation Transaction):** The `exam_type_id` foreign key is strictly required when scheduling any exam. 
  - *Business Impact:* If an Exam Type is modified or deleted while in use, it immediately corrupts the fundamental categorization of existing exams, causing downstream analytics and student report cards to break.

---

## 9. Database Schema

**Table Name**: `lms_exam_types`

| Column Name | Data Type | Properties |
|-------------|-----------|------------|
| `id` | BIGINT | Primary Key, Auto Increment |
| `code` | VARCHAR(50) | NOT NULL, UNIQUE |
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
| `lms-exam.exam-type.index` | GET | `/lms-exam/exam-type` | `ExamTypeController@index` |
| `lms-exam.exam-type.create` | GET | `/lms-exam/exam-type/create` | `ExamTypeController@create` |
| `lms-exam.exam-type.store` | POST | `/lms-exam/exam-type` | `ExamTypeController@store` |
| `lms-exam.exam-type.show` | GET | `/lms-exam/exam-type/{id}` | `ExamTypeController@show` |
| `lms-exam.exam-type.edit` | GET | `/lms-exam/exam-type/{id}/edit` | `ExamTypeController@edit` |
| `lms-exam.exam-type.update` | PUT/PATCH | `/lms-exam/exam-type/{id}` | `ExamTypeController@update` |
| `lms-exam.exam-type.destroy` | DELETE | `/lms-exam/exam-type/{id}` | `ExamTypeController@destroy` |
| `lms-exam.exam-type.trashed` | GET | `/lms-exam/exam-type/trash/view` | `ExamTypeController@trashed` |
| `lms-exam.exam-type.restore` | GET | `/lms-exam/exam-type/{id}/restore` | `ExamTypeController@restore` |
| `lms-exam.exam-type.forceDelete` | DELETE | `/lms-exam/exam-type/{id}/force-delete`| `ExamTypeController@forceDelete` |
| `lms-exam.exam-type.toggleStatus`| POST | `/lms-exam/exam-type/{id}/toggle-status`| `ExamTypeController@toggleStatus` (AJAX) |
