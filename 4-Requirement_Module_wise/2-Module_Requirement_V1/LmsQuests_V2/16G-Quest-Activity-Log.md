# Business Requirements Document (BRD)
## Module: LMS Quests
### Screen: Activity Log

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **Activity Log** is an audit trail mechanism that tracks micro-interactions a student has while attempting a Quest. It acts as an anti-cheat mechanism and system diagnostic tool.

### 1.2 Why is this necessary? (Business Justification)
- **Security & Proctoring:** Teachers need to know if a student tab-switched, lost internet connection, or resized their browser window during a timed, strict Quest.

---

## 2. Document Scope
- **In-Scope:** Displaying and filtering `lms_attempt_activity_logs`.
- **Out-of-Scope:** Logging the actual events (this happens on the frontend during the attempt execution).

---

## 3. User Personas
1. **Teacher / Admin:** Investigates suspicious student behavior during a Quest.

---

## 4. Detailed Functional Requirements (FR)

### FR-01: Log Retrieval & Filtering
- **Action:** Load the Activity Log tab.
- **System Behavior (`LmsQuestController::index`):**
  - Queries `lms_attempt_activity_logs`.
  - Hard-filters by `attempt_type = 'QUEST'`.
  - Allows dynamic filtering by:
    - `event_type_id` (joined from `AttemptActivityEventType` which holds names like "Tab Switched", "Connection Lost").
    - Date Range (`date_from`, `date_to`) mapping to `occurred_at`.

### FR-02: Log Visualization
- **System Behavior:**
  - Displays the exact timestamp (`occurred_at`).
  - Identifies the user via relationships (`Attempt -> Student`).
  - Identifies the context via relationships (`Attempt -> Quest`).
  - Displays any metadata captured in the `event_data` JSON column (e.g., specific URLs visited, exact screen dimensions when resized).

---

## 5. Agile User Stories & Acceptance Criteria
#### Story 1: Auditing a student's attempt
**As a** Teacher,
**I want to** filter the Activity Log for "Tab Switched" events for yesterday's Math Quest,
**So that** I can see which students attempted to Google answers during the test.

**Acceptance Criteria:**
- **Given** I select the "Tab Switched" event type, **When** I click search, **Then** the grid shows all instances where a student minimized or navigated away from the Quest browser tab.

---

## 6. Dependency & Impact Mapping
- **Incoming Dependencies:** `lms_attempt_activity_logs`, `lms_attempt_activity_event_types`, `lms_quiz_quest_attempts`.
