# Vendor Usage Log — Business Requirements

## What This Screen Does

The Vendor Usage Log screen tracks actual consumption for vendors on Per Unit and Hybrid billing models. Every time a vendor's service or product is used, a usage log entry is created. This lets the system calculate invoices based on how much was actually used, instead of charging a flat rate.

Each usage log entry records: the vendor, the specific line item from the vendor agreement, the date of usage, the quantity used, optional notes, and who entered it.

---

## When This Screen Is Used

- **Logging Vendor Usage** — When an authorised person needs to record how much of a vendor's service was used on a given day
- **Reviewing Usage History** — To look at past usage entries for checking and reconciling
- **Invoice Preparation** — Usage log entries feed into invoice generation for Per Unit and Hybrid billing models
- **Usage Analysis** — To study consumption patterns over time when evaluating vendors

---

## Who Can Access This Screen

- **Vendor Manager** — Can view, create, edit, and manage usage logs for assigned vendors
- **Finance Team** — Full access for billing and reconciliation
- **School Admin** — Full access
- **Principal** — Can only view, cannot make changes

The system checks the user's permissions before allowing any action.

---

## How This Screen Works

### The Usage Log List

When a user opens the screen, the system shows a list of usage log entries (20 per page). Each row shows: ID, Vendor name, Agreement Item, Usage Date, Quantity Used, Notes, Logged By, and action buttons (View, Edit, Delete).

A filter panel lets users narrow down by Vendor, Agreement Item, Date Range, and who logged it.

### Creating a Usage Log Entry

When the user clicks "Add Usage Log," a form loads with the following fields:
- **Vendor** — Dropdown choosing from active vendors
- **Agreement Item** — Dropdown choosing from the vendor's agreement items
- **Usage Date** — Date selector (cannot pick a future date)
- **Quantity Used** — Number input (must be greater than 0)
- **Notes** — Optional text field

The system checks all fields, saves the usage log entry, and returns to the list with a success message.

### Editing a Usage Log Entry

Users can edit existing usage log entries. The form shows the saved values. On save, the system checks and updates the entry.

### Viewing a Usage Log Entry

The detail view shows all fields as read-only: Vendor ID and name, Agreement Item and description, Usage Date, Quantity Used, Notes, Logged By user name, Created At, and Updated At.

### Deleting Usage Log Entries

- **Remove from view:** Hides the entry (requires the system to store a removal date — see Known Issues)
- **Bring back:** Makes a hidden entry visible again
- **Permanently remove:** Erases the entry completely

---

## Known Issues

- **No validation on save:** When creating or editing a usage log, the system does not check the data before saving. It accepts whatever the user enters. Business rules like "quantity must be greater than 0" and "date cannot be in the future" are not enforced yet. (See Validation section for what SHOULD be checked.)
- **Toggle button doesn't work:** The system has a route registered for a toggle button (to turn entries on/off), but the supporting logic was never built. Clicking this toggle will cause an error.
- **No hide/show field exists:** The system does not store a flag to hide or show usage log entries. Even if the toggle button were built, it would fail because the necessary field does not exist.
- **Remove from view doesn't work:** The system tries to store a removal date when an entry is hidden, but there is no field to hold that date. Any attempt to hide, restore, or permanently delete will fail.

---

## Validation — What the System SHOULD Check

The system SHOULD check these fields before saving a usage log. This is NOT yet implemented.

**Required Fields:**
- **Vendor** — Must be selected and must exist in the vendor records
- **Agreement Item** — Must be selected and must exist in the agreement items
- **Usage Date** — Must be provided in a valid date format, and must be today or earlier
- **Quantity Used** — Must be provided, must be a number, at least 0.01

**Optional Fields:**
- **Notes** — Text only, maximum 255 characters

### Expected Error Messages

| Field | What to Check | Error Message |
|-------|--------------|---------------|
| Vendor | Must be selected | "Please select a vendor." |
| Vendor | Must be a valid vendor | "The selected vendor is not valid." |
| Agreement Item | Must be selected | "Please select an agreement item." |
| Agreement Item | Must be a valid item | "The selected agreement item is not valid." |
| Usage Date | Must be provided | "Please enter a usage date." |
| Usage Date | Must be a valid date | "The usage date is not a valid date." |
| Usage Date | Must not be in the future | "The usage date must be today or earlier." |
| Quantity Used | Must be provided | "Please enter a quantity." |
| Quantity Used | Must be a number | "The quantity must be a number." |
| Quantity Used | Must be at least 0.01 | "The quantity must be at least 0.01." |
| Notes | Must be text | "The notes must be plain text." |
| Notes | Max 255 characters | "The notes must not exceed 255 characters." |

---

## Business Rules and Conditions

### BR-VND-013: Quantity Must Be Positive
The quantity used must be greater than 0. Zero or negative values are not allowed.

### BR-VND-014: Usage Date Within Agreement Period
The usage date must fall within the vendor's agreement period for the selected agreement item. The date cannot be in the future. The system should cross-check the agreement's start and end dates to make sure the usage date is valid.

### BR-VND-015: Default Quantity for Invoice Generation
When generating invoices, if no usage logs exist for a given period, the system assumes a default quantity of 1. This makes sure that Per Unit billing models still produce an invoice even when usage was not logged. This rule applies at invoice time, not when logging usage.

---

## Business Rules Summary

| Rule | What It Means |
|------|--------------|
| BR-VND-013 | Quantity used must be strictly greater than 0 |
| BR-VND-014 | Usage date must be within the agreement period and not in the future |
| BR-VND-015 | If no usage logs exist, invoice uses quantity of 1 |

---

## Success Scenarios

- A Vendor Manager logs 50 units of service used on 2026-07-15 against Vendor ABC's agreement item "Support Services — Per Unit." The system checks all fields, saves the entry, and shows it in the list with ID, Vendor, Agreement Item, Date, Qty = 50.00, and Logged By.

- A Finance Team member reviews usage logs for Vendor XYZ for June 2026. They apply a date-range filter and see 15 entries totalling 320 units. These entries are used to generate the monthly invoice under the Hybrid billing model.

---

## Failure Scenarios

- A user tries to log a quantity of 0. The system should reject it with "The quantity must be at least 0.01." (This check is NOT yet implemented.)

- A user tries to set a usage date of 2027-01-01 (future date). The system should reject it with "The usage date must be today or earlier." (This check is NOT yet implemented.)

- A user clicks the toggle button. The system crashes because the DDL has no `is_active` column for usage logs. (Toggle route exists but cannot function.)

- A user tries to remove a usage log entry from view. The system attempts to record a removal date but the DDL has no `deleted_at` column. The operation fails.

---

## Example Scenario

Ms. Patel, a Vendor Manager at Sunshine School, needs to log service usage for Vendor "EduTech Solutions."

The school has a Hybrid billing agreement with EduTech for "Cloud Storage Services":
- Base fee: ₹5,000/month (fixed)
- Per-unit fee: ₹100/GB for storage beyond 50 GB

On 2026-07-18, the IT team reports that 25 GB of additional storage was used in June. Ms. Patel opens the Vendor Usage Log screen and clicks "Add Usage Log":

1. She selects **Vendor** = "EduTech Solutions" from the dropdown
2. She selects **Agreement Item** = "Cloud Storage — Additional GB" (the per-unit line item)
3. She sets **Usage Date** = 2026-06-30 (last day of the billing month)
4. She enters **Quantity Used** = 25.00 (GB)
5. She adds **Notes** = "June 2026 — additional storage over 50 GB base"
6. She clicks "Save"

The system saves the usage log entry. At month-end, the invoice process picks up this log entry:
- Base fee: ₹5,000
- Usage: 25 GB × ₹100 = ₹2,500
- Total: ₹7,500

Later, Ms. Patel realises the actual usage was 30 GB, not 25 GB. She opens the entry, changes the quantity to 30.00, saves, and the system updates the entry — ready for the corrected invoice.

---

## Related Screens

- **Vendor Master** — Where vendor profiles are managed
- **Vendor Agreement** — Where agreement items are defined (line items linked to billing models)
- **Vendor Agreement Items** — Specific line items that usage logs refer to
- **Vendor Invoice** — Where usage log entries are used for Per Unit and Hybrid billing
- **User Management** — Where user records are managed (referenced by "Logged By")

---

## Dependencies

| Area | What It Depends On |
|------|-------------------|
| Vendor Usage Log | The usage log entries themselves |
| Vendor Master | Vendor records (each log links to a vendor) |
| Vendor Agreement | Agreement item records (each log links to an agreement line item) |
| System Config | User records (each log records who entered it) |
| Vendor Invoice | Invoices read usage logs to calculate billing |
