# Business Requirements Document (BRD)
## Module: LMS Examination
### Sub-Module: Exam Creation & Allocation 
### Screen: Exam Allocations

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **Exam Allocation** screen bridges the configuration phase with the execution phase. It maps a finished Exam Paper Set to a specific target audience (a class, a section, an exam group, or a specific student) and schedules the exact start and end times for the attempt.

### 1.2 Why is this necessary? (Business Justification)
- **Targeted Deployment:** Enables differentiated testing (e.g., assigning a remedial Paper Set strictly to a specific group of underperforming students).
- **Physical vs Virtual Logistics:** The screen captures whether the exam is being held physically in a school room or externally.

---

## 2. Document Scope
- **In-Scope:** Target resolution via UI logic (`CLASS`, `SECTION`, `EXAM_GROUP`, `STUDENT`). Scheduling limits. Venue capturing (Room dropdown vs Location text).
- **Out-of-Scope:** Student portal rendering.

---

## 3. User Personas
1. **Exam Admin / Teacher:** Schedules the exam for their students.

---

## 4. Detailed Functional Requirements (FR)

### FR-01: The Paper Context & Unused Filter
- **Action:** Select the Paper and Set.
- **Fields & JS Logic:**
  - **Exam Paper Dropdown:** Lists all papers.
  - **"Unused Exam" Toggle (`filter_unallocated`):** A boolean switch beneath the dropdown. If ON, JS filters the dropdown to hide any Exam Papers that have already been allocated.
  - **Paper Set Dropdown:** Populates via AJAX based on the selected Exam Paper.

### FR-02: Target Resolution
- **Action:** Define who takes the exam.
- **Allocation Type Dropdown:** `CLASS`, `SECTION`, `EXAM_GROUP`, `STUDENT`.
  - **If CLASS:** Automatically locks to the parent Exam Paper's assigned class.
  - **If SECTION:** Displays a Section dropdown (AJAX loaded for the class).
  - **If EXAM_GROUP:** Displays a Group dropdown.
  - **If STUDENT:** Displays a Section filter dropdown AND a Student dropdown (AJAX loaded).

### FR-03: Scheduling
- **Fields:**
  - **Scheduled Date:** Date the exam occurs.
  - **Start Time & End Time:** Precise time windows.
- **Validation:** `scheduled_end_time` must logically follow the `scheduled_start_time`.

### FR-04: Venue Configuration (JS Toggle)
- **Action:** Specify where the exam is taking place.
- **Fields & JS Logic:**
  - **"Conducted in School" Switch:** A boolean toggle.
  - **If ON (Checked):** JS displays a **Room Dropdown** populated with the school's configured physical rooms.
  - **If OFF (Unchecked):** JS hides the Room dropdown and displays a free-text **Location** input field for external exam centers.

---

## 5. Agile User Stories & Acceptance Criteria

#### Story 1: External Center Assignment
**As an** Exam Admin,
**I want to** specify that the exam is at a regional center,
**So that** students know where to report on their admit cards.

**Acceptance Criteria:**
- **Given** I uncheck the "Conducted in School" switch, **When** I do so, **Then** the Room dropdown disappears and a free-text "Location" field appears, allowing me to type "City Hall".

#### Story 2: Individual Remedial Allocation
**As a** Teacher,
**I want to** allocate Set B only to John Doe,
**So that** he can retake his missed exam.

**Acceptance Criteria:**
- **Given** I select "STUDENT" as Allocation Type, **When** I do so, **Then** I am forced to select a specific student ID via the dependent dropdowns.

---

## 6. Business Data Dictionary & Validations
| Field | Validation Rules |
|-------|------------------|
| **Target Resolution** | `target_id` validation varies dynamically based on `allocation_type`. |
| **Room vs Location** | Mutually exclusive. One is required based on `conducted_in_school` state. |

---

## 7. Dependency & Impact Mapping
- **Incoming Dependencies:** `lms_exam_papers`, `lms_exam_paper_sets`, `sch_classes`, `sch_sections`, `sch_rooms`, `lms_exam_student_groups`, `std_students`.
- **Outgoing Dependencies:** `lms_exam_allocations` signals the Student Portal dashboard.
