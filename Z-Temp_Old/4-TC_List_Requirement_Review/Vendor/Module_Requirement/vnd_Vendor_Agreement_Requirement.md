# Vendor Agreement — Business Requirements

## What This Screen Does

The Vendor Agreement screen is where school administrators manage contractual agreements with vendors. Think of it as a contract repository: administrators create agreements defining the commercial terms, billing models, and items/services covered under each vendor relationship. Each agreement tracks a lifecycle through stages: Draft, Active, Expiry, or Termination.

The main list view shows all agreements with filters to narrow down by vendor, agreement reference, and status. Administrators can create new agreements with itemised services listed right inside the form, upload signed agreement documents, manage the status lifecycle, temporarily remove or restore agreements (along with their items), permanently remove agreements together with their items and documents, and turn agreements on or off from the list.

---

## When This Screen Is Used

- **Creating a New Agreement** — When a school enters into a new contractual relationship with a vendor
- **Editing an Agreement** — When agreement terms, billing model, items, or dates need modification
- **Viewing Agreement Details** — To review the full agreement with items, billing breakdown, and uploaded document
- **Uploading Signed Agreement** — To attach the signed PDF or scanned copy of the agreement document
- **Advancing Status** — To move an agreement from Draft → Active, or to Terminated when the contract ends early
- **Removing from View and Restoring** — To temporarily remove an agreement or reinstate it from the trash area (its items are removed/reinstated together)
- **Permanently Removing** — To permanently delete an agreement along with all its items and attached documents
- **Turning On/Off** — To quickly activate or deactivate an agreement from the list view

---

## Who Can Access This Screen

- **School Admin** — Full access including remove from view, restore, permanently remove, toggle status on/off, and document upload
- **Accounts Manager** — Can view, create, edit agreements and manage billing terms
- **Purchase Manager** — Can view and create agreements for procurement
- **Principal** — Read-only access to view agreements

All access is controlled by permissions. The system checks the user's role on every action.

---

## How This Screen Works — Step by Step

### The Agreement List

When an administrator opens the Vendor Agreement screen, the system shows a list of agreements (10 per page) with: reference number, vendor name, start date, end date, status (Draft / Active / Expired / Terminated), billing cycle, total number of items, an on/off toggle, and action buttons (View, Edit, Delete, Upload Document). A filter panel above lets administrators narrow down by Vendor, Agreement Reference, and Active/Inactive status.

The list shows only agreements that have not been removed from view. A separate "Trash" tab shows agreements that were temporarily removed.

### Creating an Agreement

When the administrator clicks "Add Agreement," they see a form with two sections:

**Agreement Header:**
- Vendor (required, dropdown of only active vendors)
- Agreement Reference No (optional, filled automatically if left blank)
- Start Date (required, date picker)
- End Date (required, date picker, must be after Start Date)
- Billing Cycle (required, dropdown: Monthly / One-Time / On-Demand)
- Payment Terms Days (defaults to 30, number of days allowed for payment)
- Remarks (optional, text area)
- Status (defaults to Draft)
- Active toggle (defaults to Active)
- Agreement File Upload (optional, PDF / JPG / PNG, max 5MB)

**Agreement Items (listed inline, at least 1 item required):**
- Item (required, dropdown of only active items)
- Billing Model (required, dropdown: Fixed / Per Unit / Hybrid)
- Fixed Charge (required if billing model is Fixed or Hybrid, a flat dollar amount)
- Unit Rate (required if billing model is Per Unit or Hybrid, rate per single unit)
- Minimum Guarantee Quantity (used for Hybrid model only)
- Tax 1% through Tax 4% (optional, percentage values)
- Related Entity Type (optional — e.g., links to a specific vehicle or driver)
- Related Entity Name (optional)
- Related Entity ID (optional)
- Description (optional, up to 255 characters)

When the administrator clicks "Save," the system checks the header fields, creates the agreement and its items together, and returns to the list with a success message. If anything fails, nothing is saved at all.

### Editing an Agreement

The edit form opens with all existing values filled in. The items appear inline with their existing data. On save, the system figures out which items to add, which to update, and which to remove from view. The entire save either completes fully or fails fully — no partial saves.

### Viewing Agreement Details

The detail view shows the full agreement in a structured layout:
- **Agreement Info Card:** Vendor name, agreement reference, start date, end date, status badge, billing cycle, payment terms
- **Items Table:** All items listed with billing model, charges, tax percentages, and calculated subtotals
- **Billing Breakdown:** Per-item subtotal calculation based on billing model
- **Documents Section:** Uploaded signed agreement document

### Uploading Agreement Document

Administrators can upload a signed agreement document in PDF, JPG, or PNG format (up to 5MB). Once uploaded, a flag is set to indicate a document exists. The document is stored in the system's file storage and appears in the detail view.

### Removing from View and Restoring

When an administrator temporarily removes an agreement, the agreement disappears from the main list and all its items are also removed from view. The administrator can restore the agreement from the Trash page — restoring the agreement brings back all its items too.

### Permanently Removing

When an administrator permanently deletes an agreement from the Trash, the system permanently erases the agreement, all its items, and all attached documents. This action cannot be undone.

### Turning On/Off (Inline Toggle)

Administrators can turn an agreement on or off directly from the list view. This activates or deactivates the agreement without reloading the page. Every toggle is recorded in the activity log.

---

## Validation Rules

### When Creating an Agreement

**Agreement Header:**
- Vendor — Required, must pick from the vendor list
- Agreement Reference No — Optional, up to 50 characters
- Start Date — Required
- End Date — Required, must be after Start Date
- Status — Optional, must be one of: Draft, Active, Expired, Terminated
- Billing Cycle — Optional, must be one of: Monthly, One-Time, On-Demand
- Payment Terms Days — Optional, minimum 0
- Remarks — Optional, any text
- Agreement File — Optional, must be PDF, JPG, or PNG, max 5MB
- Is Active — Optional, must be Yes or No

**Note:** Agreement item fields are not checked during save. They are handled directly when processing the form.

---

## Business Rules and Conditions

### Rule 1: End Date Must Be After Start Date
The agreement end date must always be strictly after the start date. The system checks this when saving.

### Rule 2: Only Active Vendors in the List
The vendor dropdown during agreement creation or editing shows only vendors that are currently active and not removed from view.

### Rule 5: Only Active Items in the List
The item dropdown used when adding agreement items shows only items that are currently active and not removed from view.

### Rule 6: Status Lifecycle
Agreements follow this lifecycle:
- **(New) → Draft:** Default status when created
- **Draft → Active:** Moved manually by the administrator
- **Active → Terminated:** Moved manually when a contract ends early
- **Expired or Terminated:** No further changes allowed

### Rule 7: Billing Model Calculations
Each billing model calculates the item subtotal differently:
- **Fixed:** Subtotal = fixed charge (a flat fee)
- **Per Unit:** Subtotal = unit rate × quantity used (quantity comes from usage logs)
- **Hybrid:** Subtotal = fixed charge + extra charges for usage above the minimum guarantee (extra = unit rate × (quantity used − minimum guarantee), only if quantity used exceeds the minimum)

### Rule 8: Items Move Together with Agreement
- **Removing from View:** The agreement and all its items are hidden together. Documents are kept.
- **Restoring:** The agreement and all its items are brought back together.
- **Permanently Removing:** The agreement, all its items, and all uploaded documents are erased completely. All operations either fully complete or fully fail — no partial changes.

### Rule 9: All Saves Are All-or-Nothing
Every action that changes data — create, update, remove from view, restore, permanently remove — either completes fully or rolls back completely. There are no partial saves.

### Rule 10: Agreement Document Upload
The agreement document is uploaded and stored in the system's file storage. A flag is set to Yes when a document exists and No when it does not. Supported file types: PDF, JPG, PNG. Maximum file size: 5MB.

### Rule 11: Items Cannot Be Removed If Used by an Agreement
If an item is being used in any agreement, it cannot be deleted from the system. This prevents breaking existing agreements.

### Rule 12: Linking Items to Specific Entities
An agreement item can be linked to a specific entity — for example, a particular vehicle or driver — for billing purposes. This is optional and used when billing depends on a specific asset or person.

---

## Business Rules Summary (Quick Reference)

| Rule | What It Means |
|------|--------------|
| Rule 1 | End date must be after start date |
| Rule 2 | Only active vendors shown in the dropdown list |
| Rule 3 | Only active items shown in the selection list |
| Status Lifecycle | Draft → Active → Terminated (manual) |
| Billing Models | Fixed (flat fee), Per Unit (rate × quantity), Hybrid (base + extra) |
| Items Move Together | Removing, restoring, or permanently deleting an agreement affects its items too |
| All-or-Nothing | Every save either fully completes or fully rolls back |
| Document Upload | File storage for documents, PDF/JPG/PNG, max 5MB |
| Item Protection | Items in use by an agreement cannot be removed |

---

## Error Messages

| Scenario | Error Message |
|----------|--------------|
| No vendor selected | "The vendor field is required." |
| Invalid vendor chosen | "The selected vendor is invalid." |
| No start date entered | "The start date field is required." |
| No end date entered | "The end date field is required." |
| End date is before or same as start | "The end date must be a date after the start date." |
| Invalid status value | "The selected status is invalid." |
| Invalid billing cycle | "The selected billing cycle is invalid." |
| Payment terms is negative | "The payment terms days must be at least 0." |
| Wrong file type uploaded | "The agreement file must be a file of type: pdf, jpg, png." |
| File too large | "The agreement file must not exceed 5 MB." |
| Invalid active status | "The active field must be Yes or No." |
| Deletion failed due to system error | "An error occurred while deleting the agreement." |
| Agreement not found | "Agreement not found." |

---

## Success Scenarios

- An administrator creates a new agreement: Vendor = "EduSupplies India Pvt Ltd", Start Date = 2026-01-01, End Date = 2026-12-31, Billing Cycle = Monthly, Payment Terms = 30 days, Status = Draft, with 2 items: Item 1 (Billing Model = Fixed, Fixed Charge = 25000.00) and Item 2 (Billing Model = Per Unit, Unit Rate = 150.00). The system saves the agreement with both items, sets the status to Draft, and confirms success.

- An administrator uploads a signed PDF agreement document. The file is stored in the system's file storage. The document flag is set to Yes. The document appears in the agreement detail view.

- An administrator temporarily removes an agreement. The agreement and its two items are hidden from view. Later, the administrator restores the agreement — all items are restored with it.

---

## Failure Scenarios

- An administrator tries to create an agreement with End Date = 2026-01-01 and Start Date = 2026-06-01. The system rejects with "The end date must be a date after the start date."

- An administrator tries to upload a .docx file as the agreement document. The system rejects with "The agreement file must be a file of type: pdf, jpg, png."

- An administrator tries to upload a 10MB PDF. The system rejects with "The agreement file must not exceed 5 MB."

- An administrator tries to permanently delete an agreement whose items have usage records. The system blocks the deletion because those records are still needed.

---

## Example Scenario

Mrs. Mehta, the School Admin of Sunshine International School, needs to create a yearly maintenance agreement with "EduSupplies India Pvt Ltd".

She goes to Vendor Agreement and clicks "Add Agreement":

1. **Agreement Header:** She selects Vendor = "EduSupplies India Pvt Ltd" from the list, leaves Agreement Reference No blank (it will be filled automatically), sets Start Date = 2026-04-01, End Date = 2027-03-31 (next year), selects Billing Cycle = Monthly, Payment Terms Days = 45, adds a remark "Annual maintenance contract for IT equipment", leaves Status as Draft.

2. **Agreement Items:** She adds 2 items:
   - Item 1: "IT Equipment Maintenance", Billing Model = Fixed, Fixed Charge = 50000.00, Tax 1% = 18 (GST)
   - Item 2: "Per-Visit Service Charge", Billing Model = Per Unit, Unit Rate = 2000.00, Minimum Guarantee Quantity = 0

3. She clicks "Save". The system checks the information, creates the agreement with reference "AG-2026-0001" and both items, and returns to the list showing the new agreement as Draft.

A week later, both parties have signed. Mrs. Mehta opens the agreement, uploads the signed PDF, and the agreement is set to Active. The agreement is now live.

---

## Related Screens

- **Vendor Master** — Where vendor profiles are managed (source for vendor dropdown during agreement creation)
- **Vendor Items** — Where service/item information is managed (source for item dropdown in agreement items)
- **Usage Logs** — Where Per Unit and Hybrid billing quantities are recorded for billing calculations
- **Invoice Generation** — The billing module that uses agreement information
- **Payment Tracking** — The module that uses agreement payment terms

---

## Dependencies

| Area | What Is Needed |
|------|---------------|
| Agreement Core | The agreement record itself and its list of items |
| Vendor Core | Vendor profiles (each agreement is linked to a vendor) |
| Vendor Items | Item/service records (each agreement item is linked to a service) |
| System Configuration | Standardised lists for status, billing cycle, and related entity types |
| Document Storage | File storage system for uploaded agreement documents |
| Activity Log | Record of all changes made to agreements |
| Usage Logs | Quantity records needed for Per Unit and Hybrid billing calculations |
| Invoices | The billing module that uses agreement data |
| User Profiles | User information for sending notifications (e.g., Finance Manager) |
