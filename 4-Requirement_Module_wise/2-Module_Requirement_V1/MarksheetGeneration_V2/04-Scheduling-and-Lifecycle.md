# Business Requirements Document (BRD)
## Module: Marksheet Generation
### Screen: Scheduling & Lifecycle

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **Marksheet Schedule** is the trigger event. Once the configuration is perfect, the school "Schedules" the generation for specific classes (e.g., "Generate Term 1 for Class 10-A").

### 1.2 Why is this necessary? (Business Justification)
- **State Machine Control:** Marksheets cannot be edited once published to parents. The schedule enforces a strict lifecycle (Draft -> Reviewed -> Published) ensuring data integrity.

---

## 2. Document Scope
- **In-Scope:** MarksheetSchedule creation, `ScheduleClasses` mapping, and the `MarksheetScheduleLifecycleService` state machine.

---

## 3. Detailed Functional Requirements (FR)

### FR-01: Schedule Creation
- **System Behavior:** The user selects a `ConfigTemplate` and maps it to specific `ClassSections`.
- **Date:** A `schedule_date` is defined indicating when this marksheet applies.

### FR-02: The Lifecycle State Machine
Handled strictly via `MarksheetScheduleLifecycleService`.
1. **DRAFT:** Initial state. Teachers can enter IA/Co-Scholastic marks. Results are computed via `ComputeMarksheetJob`.
2. **REVIEWED:** The Exam Coordinator locks the marks. Standard teachers can no longer modify marks.
3. **PUBLISHED:** The schedule is finalized. The generated marksheets are now visible to Students/Parents in their portal.
4. **LOCKED/UNLOCKED:** An Admin can override and Unlock a published schedule, but they MUST provide an `unlock_reason` which is tracked in the `activityLog`.

### FR-03: Security & Authorization
- Action buttons for state changes are protected by explicit Gates:
  - `tenant.msh-marksheet-schedule.review`
  - `tenant.msh-marksheet-schedule.publish`
  - `tenant.msh-marksheet-schedule.unlock`

---

## 4. Agile User Stories & Acceptance Criteria

#### Story 1: Unlocking a Published Schedule
**As a** Principal,
**I want to** unlock a published Term-1 marksheet to fix a critical math error,
**So that** the corrected marksheet can be regenerated.

**Acceptance Criteria:**
- **Given** the schedule is Published, **When** I click Unlock, **Then** a modal forces me to enter an `unlock_reason`, **And** upon submission, the reason is logged via `activityLog` and the schedule reverts to Draft/Reviewed.
