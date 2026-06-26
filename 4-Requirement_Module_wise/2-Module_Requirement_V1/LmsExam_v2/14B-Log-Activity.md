# Business Requirements Document (BRD)
## Module: LMS Examination
### Sub-Module: Logs & Grievance
### Screen: Tab 2: Activity Log

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **Activity Log** tab provides a strict, immutable audit trail of every technical and user-driven event that occurs during an Online Exam attempt.

### 1.2 Why is this necessary? (Business Justification)
- **Anti-Cheat Monitoring:** If a student switches tabs, loses internet, or tries to close the browser, the system logs it. The school can use this log to determine if a student was cheating or genuinely faced technical issues.
- **Dispute Resolution:** "Sir, my exam auto-submitted!" The teacher can check the log to see exactly when the timer expired or if the student clicked submit.

---

## 2. Document Scope
- **In-Scope:** Viewing read-only system and user event logs for online attempts. Filtering logs by date and event type.
- **Out-of-Scope:** Creating or deleting logs (Logs are system-generated and immutable).

---

## 3. User Personas
1. **IT Admin / Exam Proctor:** Investigates technical glitches or suspicious student behavior during online exams.

---

## 4. Detailed Functional Requirements (FR)

### FR-01: Advanced Filtering
- **Action:** Filter the logs.
- **UI/JS Logic:**
  - Cascading AJAX dropdowns: `Class -> Section -> Student`.
  - Dropdown for `Event Type`.
  - Integrates `daterangepicker`. *Note: Unlike the Assessment tab, changing the date here does NOT auto-submit the form (per user request to stop auto-filter).*

### FR-02: Activity Display Grid
- **Action:** View the events.
- **System Behavior:**
  - Displays: Student Name, Attempt ID, Paper Title, Exact Timestamp (`occurred_at`).
  - **Dynamic JSON Rendering:** The `event_data` JSON column is parsed and displayed as neat badges (`Key: Value`) in the "Details" column.
  - If no `event_data` exists, it displays "System triggered event".

---

## 5. Agile User Stories & Acceptance Criteria

#### Story 1: Investigating an auto-submit claim
**As an** Exam Proctor,
**I want to** filter the activity log for Sarah's math exam,
**So that** I can verify if she clicked "Submit" or if the "Timer Expired" event fired.

**Acceptance Criteria:**
- **Given** I select Sarah and the Math paper, **When** I click Search, **Then** I see a chronological list of all her actions, including exact timestamps.

---

## 6. Business Data Dictionary & Validations
| Field | Validation Rules |
|-------|------------------|
| **Event Data** | Stored as a JSON object in the database, allowing flexible logging of arbitrary metadata (e.g., `{"browser": "Chrome", "ip": "192.168.1.1"}`). |

---

## 7. Exception & Error Handling Scenarios
- **Scenario:** No logs match the selected filters.
  - *Response:* The table shows an empty state with a clipboard icon and "No activity logs found."

---

## 8. Dependency & Impact Mapping
### 8.1 Incoming Dependencies
- `lms_exam_attempt_activity_logs` (System must be generating logs during the online exam attempt).
- `lms_exam_event_types` (Reference table for event categories).
