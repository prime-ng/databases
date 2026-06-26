# Compliance Report — Requirement Document

## Screen Purpose & Overview

This screen is part of the Employee Reports sub-menu. The main purpose of this screen is to track and audit compliance violations of school rules and policies.

Through this report, HR and management can check events that go against school standards. These include: shift violations (such as arriving late or leaving early without authorization), misuse of attendance corrections (such as submitting multiple manual time adjustment requests), and approval flow blockages (such as managers leaving leave applications pending for several days).

---

## Common Use Cases

1. **Shift Timings Violations:** Identifying staff and teachers who have arrived late, exceeding the shift grace period, more than 3 times in a month.
2. **Pending Leaves Backlog:** Auditing which department heads have leave applications pending approval for more than 5 days.
3. **Missing Punch Regularity:** Identifying staff members who regularly fail to record check-out punches on the biometric scanner and rely heavily on manual corrections.
4. **Compliance Audit Presentation:** Exporting and presenting compliance metrics to the board of trustees during annual session audits.

---

## Screen Fields & Input Rules

### Section A: Compliance Scope Settings (Search Controls)
| Field Name (Screen Label) | Input Description | Conditions / Rules (Simple terms) |
|---|---|---|
| Violation Type | The category of policy violation to analyze | Required. Dropdown options: Late Arrival Backlog / Missing Punch Pattern / Leave Approval Delay / Shift Timings Breach. |
| Threshold Days/Hours | The duration limit defining a policy breach | Optional. Numeric input (e.g., show approvals pending for more than 48 hours). |
| Department | Filter by department | Optional. Dropdown. |

### Section B: Compliance Data Columns (Table Columns)
| Column Name (Screen Label) | Display Description | Meaning (Simple terms) |
|---|---|---|
| Target Person | The employee or manager associated with the violation | Staff name. |
| Role Type | The staff role or approval level | Job category (e.g., HOD, Teacher). |
| Metric/Event | The specific policy violation event triggered | Violation summary (e.g., "Late arrival: 6 times in 30 days"). |
| Breach Duration | The amount of time the breach has been active | E.g., "Pending for 72 Hours" or "Late by 45 minutes". |
| Violation Category | The severity rating of the violation | Visual flag tag: High (Red) / Medium (Orange) / Low (Yellow). |
| Verification Remark | Notes from the compliance auditor | Optional text comments. |

---

## Business Rules & Validation Policies

1. **Manager Delay (Blockage) Metric:**
   - If a leave request remains unresolved on a manager's dashboard beyond the defined time limit (e.g., escalation threshold of 48 hours), the system automatically flags this under the "Leave Approval Delay" category and triggers a supervisor alert.

2. **Late Arrival Breach Severity:**
   - **Low Severity (Yellow):** 1-2 occurrences of arriving late.
   - **Medium Severity (Orange):** 3-5 occurrences of arriving late.
   - **High Severity (Red):** More than 5 occurrences of arriving late. This severity level requires the generation of a formal warning letter.

---

## Screen Workflows & Operations

### 1. Generating a Compliance Audit Report
- The user selects the Violation Type (e.g., `Leave Approval Delay`).
- The user sets the threshold (e.g., `48 Hours`).
- Click "Audit Compliance". The system populates the table with managers/approvers who have pending actions exceeding the threshold.

### 2. Triggering Warnings
- HR clicks the warning generator button next to the employee's name, automatically sending a policy reminder email to the selected staff member.

---

## Real-World Example Scenario

**School HR Director Rajesh Kumar** is conducting a monthly review of the school compliance checklist:

1. Rajesh opens the `Compliance Report` page.
2. He selects: Violation Type = `Late Arrival Breach` and Month = `May-2026`.
3. He clicks "Audit Compliance" to load the list:
   - **Vikram Rathore:** Late count = `7 times`, Max late delay = `45 minutes`, Severity = `High (Red)`.
   - **Teacher C:** Late count = `3 times`, Max late delay = `16 minutes`, Severity = `Medium (Orange)`.
4. Rajesh clicks "Send Reminder Email" next to Vikram Rathore's name to automatically email a system-generated compliance reminder along with his late timing logs.
5. Next, Rajesh switches the Violation Type to `Leave Approval Delay` and notices that the accounts head has left 4 applications pending for 5 days. Rajesh sends an alert notification to the department head.
