# Separation & Retirement — Requirement Document

## Screen Purpose & Overview

This screen is part of the Employee Transfer & Promotion sub-menu. Its primary purpose is to manage the career exit transition process for employees leaving the school (resigning, retiring, or terminated).

The screen facilitates the entire exit workflow: initiating resignations, calculating and tracking notice periods, managing department clearance checklists (such as returning IT assets, library books, and clearing accounting dues), recording exit interview notes, updating Full & Final (F&F) settlement amounts, and issuing official exit documentation (such as Relieving Letters and Experience Certificates).

---

## Common Use Cases

1. **Staff Resignation Process:** Initiating the exit process when an employee submits their resignation.
2. **Superannuation / Retirement Registration:** Recording retirement details when senior teachers or staff members reach the age limit.
3. **Contract Termination/Expiry:** Commencing the offboarding process when a contractual employee's agreement term expires.
4. **Exit Clearance Checklist:** Verifying that the departing staff member has cleared all dues across school departments (e.g., returned IT devices, library items, or settled financial advances).
5. **Full & Final Settlement:** Recording the final payout, generating exit documents, and providing signed Relieving and Experience Certificates.

---

## Screen Fields & Input Rules

### Section A: Exit Initiation
| Field Name (Screen Label) | Input Description | Conditions / Rules (Simple terms) |
|---|---|---|
| Employee Name | The employee undergoing offboarding | Required. Search and select from the active employee list. |
| Separation Type | Nature of the exit | Required. Dropdown: Resignation / Termination / Retirement / End of Contract / Death / Absconded / Other. |
| Initiated By | The party initiating the exit process | Required. Dropdown: Employee / Employer / System. |
| Notice Start Date | Start date of the notice period | Required. Date picker (e.g., 01-May-2026). |
| Notice Period (Days) | Notice period duration in days | Required. Numeric input (e.g., 30 days or 90 days). Defaults to 0. |
| Intended Last Working Date | Expected final work date | Automatically calculated: **Notice Start Date + Notice Period (Days)**. The Admin can override this date manually. |
| Actual Last Working Date | Final approved last work day | Optional. Must be greater than or equal to the *Notice Start Date*. |
| Exit Reason Category | Classification of exit reasons | Optional. Dropdown (e.g., Better Opportunity, Personal Reasons, Relocation). |
| Detailed Reason | Detailed explanation for the departure | Optional. Remarks text area. |

### Section B: Exit Checklist & Documentation
| Field Name (Screen Label) | Input Description | Conditions / Rules (Simple terms) |
|---|---|---|
| Exit Interview Done? | Indicates if the exit interview is completed | Required. Toggle button (Yes/No). Defaults to "No". |
| Exit Interview Notes | Summary of the exit interview feedback | Optional. Detailed text area. |
| Clearance Status | Status of department clearances | Required. Toggle (Complete / Pending). Defaults to "Pending". |
| Final Settlement Done? | Indicates if the F&F payout has been processed | Required. Toggle (Yes/No). |
| Final Settlement Amount | Final settlement payment amount | Optional. Numeric value. Must be zero or positive. |
| Eligible for Rehire? | Rehire eligibility status | Required. Toggle (Yes/No). Defaults to "Yes". |
| Relieving Letter Issued? | Indicates if relieving letter has been generated | Required. Toggle (Yes/No). |
| Experience Letter Issued? | Indicates if experience certificate has been generated | Required. Toggle (Yes/No). |
| Upload Relieving Letter | Copy of the issued relieving letter | Optional. PDF upload. Max file size: 2MB. |
| Upload Experience Letter | Copy of the issued experience certificate | Optional. PDF upload. Max file size: 2MB. |

---

## Business Rules & Validation Policies

1. **Workflow Status States (Offboarding Lifecycle):**
   - **Initiated:** Exit process created (resignation submitted).
   - **Under Review:** HR and Department Heads are reviewing the exit details.
   - **Notice Period:** Employee is actively serving their notice period.
   - **Approved:** Separation approved by HR; last working date is locked.
   - **Completed:** Clearance checklist cleared, F&F settlement complete, and exit certificates uploaded. Once marked "Completed", the system automatically archives the employee's profile (status changes to Inactive) and disables their login credentials.
   - **Rejected / Cancelled:** Exit request is rejected by HR or retracted by the employee; the staff member continues in their normal role.

2. **Clearance Checklist Dependency:**
   - The system prevents updating the status to `Completed` until the *Clearance Status* toggle is set to `Complete`.

3. **Auto-Recording Audit Logs:**
   - On approval or completion of the separation workflow, the system automatically captures the approving manager's user ID and timestamp (Approved By, Approved At).

---

## Screen Workflows & Operations

### 1. Initiating the Separation Process (Create)
- The employee submits a request through their self-service portal, or HR initiates it through the administrator dashboard.
- The Admin selects the Employee and specifies the Separation Type (e.g., Resignation).
- Enters the Notice Start Date and notice duration.
- Clicks Save. The status is set to `Initiated`, and an email notification is automatically dispatched to the department head.

### 2. Processing Department Clearances
- The IT, Library, and Finance departments receive notification tasks.
- Once all clearances are verified, HR updates the *Clearance Status* toggle to `Complete`.

### 3. Exit Interview & Settlement Finalization (Close Out)
- HR conducts the exit interview and inputs the feedback notes.
- The Finance department calculates and enters the final F&F payout amount.
- HR marks the exit documents as issued and uploads the signed PDF certificates.
- Transitioning the status to "Completed" archives the employee profile, removing them from the active directory.

---

## Real-World Example Scenario

**TGT Science Teacher Shalini Sen** resigns for career growth opportunities:

1. Shalini submits a resignation request on her portal. Her notice period is `30 Days`, starting `01-May-2026`. The system automatically calculates her `Intended Last Working Date` as `31-May-2026` and marks the status as `Initiated`.
2. The Principal reviews and approves the request, transitioning the status to `Notice Period`.
3. During the notice period, Shalini:
   - Returns all library materials (Library Clearance).
   - Hands over her school laptop to the IT administrator (IT Clearance).
   - Resolves outstanding financial advances (Finance Clearance).
4. HR records clearance as complete, conducts the exit interview, and notes: `Shalini's feedback is positive. Leaving for higher studies.`
5. On `31-May-2026`, HR confirms her actual last working day, enters the final payout amount: `Rs 45,500.00`, and uploads the Relieving Letter and Experience Certificate PDFs.
6. HR marks the status as `Completed`. The system automatically deactivates Shalini's user account and moves her profile to the archived database.
