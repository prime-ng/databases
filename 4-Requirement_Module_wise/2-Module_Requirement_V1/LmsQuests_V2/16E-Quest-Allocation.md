# Business Requirements Document (BRD)
## Module: LMS Quests
### Screen: Quest Allocation

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **Quest Allocation** screen controls the deployment of an assessment. It defines exactly *who* receives it (Target resolution), *when* they can access it (Schedule), and *how* results are published (Configuration).

### 1.2 Why is this necessary? (Business Justification)
- **Targeted Deployment:** Enables differentiated learning by allowing a teacher to assign a Quest to a whole Class, a specific Section, an arbitrary Group, or an individual Student.

---

## 2. Document Scope
- **In-Scope:** Creation and management of `lms_quest_allocations`. Target resolution via UI logic. Schedule/Date constraint validation. Result publish configurations.
- **Out-of-Scope:** Student portal rendering (Execution).

---

## 3. User Personas
1. **Teacher:** Deploys the configured Quest to students.

---

## 4. Detailed Functional Requirements (FR)

### FR-01: Section 1 - Allocation Target
- **Action:** Select who receives the Quest.
- **Fields & Validations:**
  - **Quest Select:** Dropdown to select the parent Quest. Includes an **"Unused Quest" toggle** (`filter_unallocated`). If ON, it filters the dropdown to only show Quests that haven't been allocated yet.
  - **Allocation Type:** Dropdown (`CLASS`, `SECTION`, `GROUP`, `STUDENT`).
  - **Target Resolution (JS & Backend):**
    - If `CLASS`: Auto-locks to the Class assigned to the selected Quest.
    - If `SECTION`: Shows a dropdown of Sections belonging to that Class.
    - If `GROUP`: Shows a dropdown of custom entity groups.
    - If `STUDENT`: Shows two dropdowns: a Section filter, and a Student dropdown loaded via AJAX (`get-students-by-class`).
  - **Backend Validation:** The `QuestAllocationRequest` ensures the `target_id` exists, is active, and (for students) is not soft-deleted.

### FR-02: Section 2 - Schedule & Deadlines
- **Action:** Set the timeline for the Quest.
- **Fields & Validations:**
  - **Visible From (Published At):** The datetime the quest appears for the student. Can be left empty to publish immediately.
  - **Due Date:** The target completion datetime (Max 2 years in the future).
  - **Cut-off Date:** Optional hard-stop datetime. If provided, MUST be on or after the `due_date`. After this date, submissions are blocked.

### FR-03: Section 3 - Result & Status Configuration
- **Action:** Configure post-test behavior.
- **Fields & Validations:**
  - **Auto Publish Result Switch:** If checked, the results will be automatically revealed to the student after submission.
  - **Result Publish Date:** This field is **hidden** by default. It only appears if the "Auto Publish Result" switch is turned ON. The date must be on or after the `due_date`.
  - **Active Allocation Switch:** Master toggle (`is_active`) to pause or resume the allocation.

---

## 5. Agile User Stories & Acceptance Criteria
#### Story 1: Finding Unused Quests
**As a** Teacher,
**I want to** check the "Unused Quest" switch,
**So that** my dropdown only shows Quests that I haven't already assigned to a class.

**Acceptance Criteria:**
- **Given** I am on the Allocation screen, **When** I toggle the `filter_unallocated` switch to ON, **Then** an AJAX call triggers, and the Quest dropdown is re-populated with only unallocated quests.

#### Story 2: Individual Student Allocation
**As a** Teacher,
**I want to** assign a remedial Quest to a specific student,
**So that** they can practice their weak areas.

**Acceptance Criteria:**
- **Given** I select `STUDENT` as the Allocation Type, **When** I do so, **Then** the Section filter and Student dropdown appear, allowing me to pick exactly one target student ID.

---

## 6. Dependency & Impact Mapping
- **Incoming Dependencies:** `lms_quests`, `sch_classes`, `sch_sections`, `sch_entity_groups`, `std_students`.
- **Outgoing Dependencies:** `lms_quest_allocations` signals the Student Portal dashboard.
