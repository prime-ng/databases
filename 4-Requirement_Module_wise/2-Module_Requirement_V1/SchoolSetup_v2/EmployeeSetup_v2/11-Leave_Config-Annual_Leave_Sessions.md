# Annual Leave Sessions — Requirement Document

## Screen Purpose & Overview

This screen is the seventh and final tab under the Leave Config sub-menu. It is used by the Admin to define the school's annual time-off cycles (Annual Leave Sessions).

Employee leave balances and holiday calendars are managed within a fixed time-period (cycle) — such as the Calendar Year (Jan-Dec) for corporate offices or the Academic Year (Apr-Mar) for schools. When a session ends, a rollover process transfers eligible unused leaves to the new active session.

---

## Common Use Cases

1. **Creating a New Session:** Defining a new cycle (e.g., the 2026-27 Academic Year) to start mapping balances and holidays for the upcoming year.
2. **Activating the Current Session:** Setting the current year as Active so that leave balances are checked and deducted from this session during submission.
3. **Triggering Year-End Rollovers:** Executing the rollover script at the end of a session to carry forward eligible balances into the new active session.

---

## Screen Fields & Input Rules

| Field Name (Screen Label) | Input Description | Conditions / Rules (Simple terms) |
|---|---|---|
| Session Name | Descriptive name of the session (e.g., 2026-27 Academic Year) | Required. Must be unique. Two sessions cannot share the same name. |
| Start Date | The start date of the session | Required. Selected using a date picker (e.g., 01-Apr-2026). |
| End Date | The end date of the session | Required. Selected using a date picker (e.g., 31-Mar-2027). Must be after the Start Date. |
| Description | Brief summary details about the session | Optional. Max 255 characters. |
| Is Active | Status toggle for the session | Default is Active (Toggle ON). Only the rules and holiday calendars of an active session are loaded during attendance and leave processing. |

---

## Business Rules & Validation Policies

1. **Active Session Resolution Logic:**
   - If multiple sessions are marked as active in the database, the system determines the current session using the following priority:
     - **Priority 1:** The session whose start and end date range includes today's date (Today).
     - **Priority 2:** If today's date falls within multiple overlapping active sessions, the system prioritizes the most recently created session (latest ID).
     - If no active session is found, the system blocks leave submissions with the error: *"No active leave session configured"*.

2. **Date Order Validation:**
   - The *Start Date* must always precede the *End Date*. Sessions with reverse or identical date ranges cannot be saved.

3. **Delete Restrictions:**
   - If a session is referenced by existing employee leave balances or historical leave applications, it cannot be permanently deleted.
   - The Admin can only deactivate the session by toggling **Is Active = No**. This preserves historical data for audits while preventing new transactions.

4. **Holiday Cascade Deletion:**
   - Deleting a leave session automatically deletes (cascades) all holiday calendars and holiday events linked to that specific session.

---

## Screen Workflows & Operations

### 1. Adding a New Session (Create)
- The Admin clicks the "+ New Session" button.
- Inputs the Session Name, and selects the Start Date and End Date.
- Toggles **Is Active** to 'Yes'.
- Clicks Save to register the new session.

### 2. Modifying Session Status (Edit)
- The Admin clicks "Edit" next to the target session in the list.
- **Rule:** If the session is historical or has completed its rollover, the core date fields (Start/End Dates) are locked. Only the status toggle can be modified.
- Toggling **Is Active** to 'No' displays a warning alert: *"Deactivating an active session may affect current leave requests. Do you want to proceed?"*

### 3. Executing Year-End Rollover (Rollover)
- When a session ends, the Admin selects the new active session and clicks "Trigger Rollover".
- The system automatically evaluates the remaining balances from the previous session, applies the rollover limits (e.g., carry-forward rules), and creates initialized leave balance records for the new session.

---

## Real-World Example Scenario

The Admin is setting up the upcoming **Academic Session 2026-27**:

1. The Admin navigates to the "Annual Leave Sessions" tab and clicks "+ New Session".
2. Inputs the following values:
   - **Session Name** = `2026-27 Academic Year`
   - **Start Date** = `01-Apr-2026`
   - **End Date** = `31-Mar-2027`
   - **Is Active** = `Yes`
3. Clicks Save.
4. **System Response:** The new session is added to the system. Once April 1st, 2026 is reached, the system automatically loads this session for leave tracking, and initializes leave balances for all active staff members.
