# Business Requirements Document (BRD)
## Module: LMS Quiz
### Sub-Module: Quiz Management
### Screen: Quiz Activity Logs

---

## 1. Executive Summary & Business Motive
### 1.1 The Core Motive
The **Quiz Activity Logs** screen is a security and audit interface that tracks every significant event occurring during a student's quiz attempt.

### 1.2 Why is this necessary? (Business Justification)
- **Proctoring & Anti-Cheating:** Tracks events like tab-switching, window blurring, or network disconnections to provide evidence if a student is suspected of cheating.
- **Technical Debugging:** Logs submission failures or browser crashes.

---

## 2. Document Scope
- **In-Scope:** The filterable audit datagrid and event tracking logic.
- **Out-of-Scope:** Real-time proctoring video feeds.

---

## 3. User Personas
1. **Exam Invigilator / Admin:** Reviews logs to disqualify cheating students or investigate claims of technical failure.

---

## 4. Detailed Functional Requirements (FR)

### FR-01: Audit Filters
- **System Behavior:** Users can drill down into millions of log rows.
- **Fields:**
  - **Quiz:** Dropdown of all quizzes.
  - **Event Type:** Dropdown (e.g., `TAB_SWITCH`, `SUBMISSION`, `WINDOW_BLUR`).
  - **Attempt ID:** Integer search.
  - **Student Name:** Text search.
  - **Date From / Date To:** Date boundaries.

### FR-02: Audit Datagrid
- **Action:** Review the chronological list of events.
- **Columns & Logic:**
  - **ID:** Log Record ID.
  - **Quiz & Student:** The context of the event.
  - **Event:** The `event_name`. If the event code contains `VIOLATION` (e.g., `VIOLATION_TAB_SWITCH`), the badge color is styled red (`bg-danger`), otherwise yellow (`bg-warning`).
  - **Event Data:** A JSON payload containing technical specifics (e.g., time spent off-tab, IP address).
  - **Occurred At:** Exact Timestamp.
  - **Actions:** A "View" button that opens the specific attempt log history.

---

## 5. Agile User Stories & Acceptance Criteria

#### Story 1: Identifying Cheaters
**As an** Invigilator,
**I want to** filter the logs for "VIOLATION" events on the Final Exam Quiz,
**So that** I can see which students switched their browser tabs to look up answers.

**Acceptance Criteria:**
- **Given** a student switched tabs during an active attempt, **When** I filter the logs by that student's name, **Then** I see a red `VIOLATION_TAB_SWITCH` event along with the exact timestamp.

---

## 6. Business Data Dictionary & Validations
| Field | Data Format |
|-------|-------------|
| **Event Data** | Stored and displayed as raw JSON. |
| **Event Code** | String. System detects `VIOLATION` substring for color coding. |

---

## 7. Dependency & Impact Mapping
- **Incoming Dependencies:** `lms_quiz_activity_logs` (populated heavily via API by the frontend Student Portal during an attempt).
- **Outgoing Dependencies:** Action links to detailed attempt views.
