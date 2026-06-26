# Business Requirements Document (BRD)
## Module: LMS Examination
### Sub-Module: Exam Masters 
### Screen: Exam Status Events

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The lifecycle of an examination is complex and involves multiple stages. An exam starts as a *Draft*, gets *Scheduled*, and eventually concludes. The papers within that exam go through their own transitions: *Not Started -> In Progress -> Submitted -> Evaluation Pending -> Results Published*. 
Instead of hardcoding these statuses into the application, the **Exam Status Events** module allows the system to define these statuses dynamically. 

### 1.2 Why is this necessary? (Business Justification)
- **Workflow Automation:** Different schools have varying approval workflows. By storing statuses dynamically, the system can attach specific `action_logic` (JSON rules) to a status. For instance, transitioning to a `PUBLISHED` status could trigger automated SMS alerts to parents.
- **Granularity (Entity Targeting):** A status like `EVALUATION_PENDING` applies to an individual *Paper*, but not to the overall *Exam*. This module uses the `Event Type` categorization (`EXAM`, `PAPER`, `RESULT`, `ATTEMPT`) to ensure that dropdowns only show relevant statuses for the specific entity being managed.
- **Data Integrity Constraints:** Hardcoding workflow steps makes the application rigid. Allowing administrators to configure statuses ensures the ERP can adapt to different state board or internal school policies.

---

## 2. Document Scope
- **In-Scope:** The creation, modification, viewing, archiving, and retrieval of dynamic status definitions for Exams, Papers, Results, and Attempts. It includes the auto-generation of system-level logic bindings (`action_logic`) and strict dependency protections.
- **Out-of-Scope:** The actual triggering of these statuses (e.g., the student submitting a paper) happens in the assessment transaction screens, not here.

---

## 3. User Personas
1. **System Administrator / ERP Implementation Team:** The primary actors. They configure these statuses during the initial school onboarding to match the school's operational workflow.
2. **Exam Coordinator:** Usually has "View Only" access here to understand what statuses mean, but rarely creates new ones mid-year.
3. **Teachers & Students:** Consumers of these statuses. They see badges like "Evaluation Pending" on their dashboards.

---

## 4. Detailed Functional Requirements (FR)

### FR-01: Initialization & Creation
- **Action:** An authorized user can define a new Status Event.
- **Fields Required:**
  - **Code (Unique):** A system-readable string (e.g., `EVAL_PENDING`). 
  - **Name:** The human-readable string displayed to users (e.g., `Evaluation Pending`).
  - **Event Type:** A dropdown binding the status to its logical parent. Options: `EXAM`, `PAPER`, `RESULT`, `ATTEMPT`.
  - **Description:** Optional context.
- **System Behavior:** 
  - Validates uniqueness of the `Code`.
  - *Automation:* The backend automatically constructs a JSON object `action_logic` using the provided Name, Code, and Event Type. This JSON allows developers to hook background jobs (like sending emails) to this status later.

### FR-02: Data Grid, Badges, & Searchability
- **Action:** Users view the configured statuses in a grid.
- **System Behavior:** 
  - The grid defaults to showing 10 records per page.
  - **Visual Badges:** To improve scannability, the `Event Type` is color-coded:
    - `EXAM` = Primary (Blue)
    - `PAPER` = Info (Light Blue)
    - `RESULT` = Success (Green)
    - `ATTEMPT` = Warning (Yellow)
  - Users can filter explicitly by `Event Type` and `Active/Inactive` status.

### FR-03: Editing a Status Event
- **Action:** Users click to edit a status name or code.
- **Critical Business Constraint (Usage Guard):** 
  - The system checks if the status ID is currently linked to any real record in `lms_exams` or `lms_exam_papers`.
  - *If mapped:* The edit form is entirely blocked. *Rationale: Changing "Draft" to "Published" manually in the master table would instantly flip the logical state of all Draft exams to Published, causing mass workflow failures.*
  - *If unmapped:* Edits are allowed.

### FR-04: Lifecycle Management (Status Toggle & Soft Delete)
- **Action (Deactivation):** Toggling a status to "Inactive" stops it from appearing in workflow dropdowns for future use, but preserves existing historical linkages.
- **Action (Archiving/Soft Delete):** 
  - Trashing the record is strictly blocked if the status is currently linked to any exam or paper.
  - Admins can manage the Trash bin (Restore or Force Delete unused statuses).

---

## 5. Agile User Stories & Acceptance Criteria

### Epic: Exam Lifecycle Configurations
#### Story 1: Creating a specific Paper Status
**As a** System Administrator,
**I want to** create a status called "Under Moderation" specifically for Exam Papers,
**So that** the school can flag papers that require a secondary review before publishing results.

**Acceptance Criteria:**
- **Given** I select "PAPER" as the Event Type and input the Code "MOD_PENDING", **When** I click save, **Then** the record saves, and the grid displays it with a light-blue "PAPER" badge.
- **Given** I inspect the database, **Then** the `action_logic` column contains a valid JSON string mapping this newly created logic.

#### Story 2: Protecting Active Workflows
**As an** Exam Coordinator,
**I want to** prevent anyone from deleting the "PUBLISHED" status,
**So that** live exams visible to students don't suddenly break or lose their state.

**Acceptance Criteria:**
- **Given** the "PUBLISHED" status is tied to the live "Annual Exam 2024", **When** an admin attempts to Trash or Edit the status, **Then** the action is rejected with a flash message: *"Cannot edit/delete this status because it is being used in exams or exam papers."*

---

## 6. Business Data Dictionary & Validations

| Field Name | Data Type | UI Element | Mandatory? | Business Validations & Rules |
|------------|-----------|------------|------------|------------------------------|
| **Code** | String | Text Input | **Yes** | Max 50 characters. Must be globally unique to prevent workflow logic conflicts. |
| **Name** | String | Text Input | **Yes** | Max 100 characters. Displayed on student/teacher dashboards. |
| **Event Type** | Enum | Dropdown | **Yes** | Must strictly be one of: `EXAM`, `PAPER`, `RESULT`, `ATTEMPT`. |
| **Description**| String | Text Area | No | Max 255 characters. |
| **Action Logic**| JSON | Hidden (Auto)| **Yes** | Evaluated and built by the Controller during save. |
| **Active** | Boolean | Toggle | **Yes** | Defaults to True (1). |

---

## 7. Exception & Error Handling Scenarios

1. **Scenario: Unique Workflow Code Conflict**
   - *Trigger:* User submits a code like `PUBLISHED` which already exists.
   - *System Response:* `"This status code already exists."`
2. **Scenario: Invalid Event Type Injection**
   - *Trigger:* A malicious user modifies the DOM to submit an Event Type like `STUDENT`.
   - *System Response:* The FormRequest validation fails with `"Event type is required and must be valid."`
3. **Scenario: Active Dependency Block**
   - *Trigger:* User attempts to Delete or Edit a status that is actively referenced in the `status_id` column of the `lms_exams` or `lms_exam_papers` tables.
   - *System Response:* The `ExamStatusEventUsageCheckService` blocks the action. Error: `"Cannot perform this action because it is being used in exams or exam papers."`

---

## 8. Dependency & Impact Mapping

### 8.1 What this module depends on (Incoming Dependencies)
- **None:** `lms_exam_status_events` is a top-level independent master configuration.

### 8.2 What depends on this module (Outgoing Dependencies)
- **`lms_exams` (Exam Transaction):** Uses `status_id` to track the overall exam state (e.g., DRAFT, PUBLISHED).
- **`lms_exam_papers` (Paper Transaction):** Uses `status_id` to track the state of individual papers (e.g., NOT_STARTED, EVALUATION_PENDING).
  - *Business Impact:* Modifying a status definition that is actively linked to an ongoing exam or paper will derail automated workflows (`action_logic`) and corrupt the UI dashboard states for teachers and students.

---

## 9. Database Schema

**Table Name**: `lms_exam_status_events`

| Column Name | Data Type | Properties |
|-------------|-----------|------------|
| `id` | BIGINT | Primary Key, Auto Increment |
| `code` | VARCHAR(50) | NOT NULL, UNIQUE |
| `name` | VARCHAR(100)| NOT NULL |
| `description`| VARCHAR(255)| NULLABLE |
| `event_type` | ENUM | NOT NULL ('EXAM', 'PAPER', 'RESULT', 'ATTEMPT') |
| `action_logic`| JSON | NOT NULL |
| `is_active` | TINYINT(1)| DEFAULT 1 |
| `created_at` | TIMESTAMP | |
| `updated_at` | TIMESTAMP | |
| `deleted_at` | TIMESTAMP | NULLABLE (SoftDeletes) |

---

## 10. API / Routes Reference

| Route Name | Method | URI Pattern | Controller Action |
|------------|--------|-------------|-------------------|
| `lms-exam.exam-status-event.index` | GET | `/lms-exam/exam-status-event` | `ExamStatusEventController@index` |
| `lms-exam.exam-status-event.create` | GET | `/lms-exam/exam-status-event/create` | `ExamStatusEventController@create` |
| `lms-exam.exam-status-event.store` | POST | `/lms-exam/exam-status-event` | `ExamStatusEventController@store` |
| `lms-exam.exam-status-event.show` | GET | `/lms-exam/exam-status-event/{id}` | `ExamStatusEventController@show` |
| `lms-exam.exam-status-event.edit` | GET | `/lms-exam/exam-status-event/{id}/edit` | `ExamStatusEventController@edit` |
| `lms-exam.exam-status-event.update` | PUT/PATCH | `/lms-exam/exam-status-event/{id}` | `ExamStatusEventController@update` |
| `lms-exam.exam-status-event.destroy` | DELETE | `/lms-exam/exam-status-event/{id}` | `ExamStatusEventController@destroy` |
| `lms-exam.exam-status-event.trashed` | GET | `/lms-exam/exam-status-event/trash/view` | `ExamStatusEventController@trashed` |
| `lms-exam.exam-status-event.restore` | GET | `/lms-exam/exam-status-event/{id}/restore` | `ExamStatusEventController@restore` |
| `lms-exam.exam-status-event.forceDelete` | DELETE | `/lms-exam/exam-status-event/{id}/force-delete`| `ExamStatusEventController@forceDelete` |
| `lms-exam.exam-status-event.toggleStatus`| POST | `/lms-exam/exam-status-event/{id}/toggle-status`| `ExamStatusEventController@toggleStatus` (AJAX) |
