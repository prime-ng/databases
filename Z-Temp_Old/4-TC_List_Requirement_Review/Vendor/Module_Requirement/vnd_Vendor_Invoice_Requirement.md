# Vendor Invoice — Business Requirements

## What This Screen Does

The Vendor Invoice screen handles everything about billing and payments to vendors. It generates invoices for services or products bought from vendors, calculates charges based on three billing methods (Fixed Price, Unit Rate, and Minimum Guarantee), prevents duplicate invoices for the same item and time period, and manages the full process — generation, printing, email delivery, payment recording, and status tracking.

The main listing shows all invoices with filters to narrow down by vendor, agreement, invoice date range, status, and active or inactive. Users can generate single or batch invoices, view invoice details, download PDFs individually or as a ZIP batch, email invoices to vendors, record payments, add notes, and turn invoice visibility on or off.

---

## When This Screen Is Used

- **Generating an Invoice** — When a billing period ends (monthly or one-time) and an invoice needs to be created for a vendor agreement item
- **Viewing Invoice Details** — To review the full invoice with billing information, usage data, tax breakdown, and payment history
- **Downloading Invoice PDF** — To print or save a single invoice as PDF
- **Batch Downloading Invoices** — To download multiple invoice PDFs together in a ZIP file
- **Emailing Invoices** — To send invoice PDFs to vendors by email
- **Recording Payments** — To track how much has been paid against an invoice
- **Adding Notes** — To attach internal notes or dispute comments to an invoice
- **Turning Status On or Off** — To make an invoice visible or hidden

---

## Who Can Access This Screen

- **School Admin** — Full access: generate, view, edit, delete, PDF download, email delivery
- **Accounts Manager** — Can generate invoices, record payments, download PDFs, email vendors
- **Principal** — Can only view invoices (read-only)

Every action checks the user's permissions. The system checks whether the user is allowed to view, create, update, delete, change status, add notes, download PDF, print, or email invoices before allowing any action.

---

## How This Screen Works — Step by Step (Plain Language)

### The Invoice List

When a user opens the Vendor Invoice screen, the system shows a list of invoices. Each row shows: number, invoice number, vendor, agreement, item description, invoice date, amount due, amount paid, balance remaining, status label, on/off toggle, and action buttons. A panel at the top lets users filter by vendor, agreement, status, invoice date range, billing start or end date, and whether the invoice is active or inactive.

The list only shows invoices that have not been removed (soft delete is used to hide records without permanently destroying them).

### Generating a Single Invoice

When the user picks an agreement item and clicks "Generate Invoice," the system does the following:

1. Checks that the vendor agreement is currently active (this check is supposed to happen but currently is NOT working — see Known Flaw below)
2. Checks that no invoice already exists for the same agreement item and the same billing period
3. Adds up the usage quantity from the usage log for the billing period (if no usage records exist, it assumes a quantity of 1)
4. Calculates the subtotal based on the billing method:
   - **Fixed Price:** subtotal = the fixed charge amount
   - **Unit Rate:** subtotal = quantity used × rate per unit
   - **Minimum Guarantee:** subtotal = whichever is larger (quantity used or minimum guaranteed quantity) × rate per unit
5. Adds up all tax percentages (up to four tax rates) and applies them to the subtotal
6. Calculates the final amount due = subtotal + total tax + other charges − discount
7. Sets the due date = invoice date + payment terms (in days) from the agreement
8. Assigns an invoice number (currently using a random 3-digit number — see Known Flaw below about possible duplicates)
9. Records the billing settings as they were at the time of generation, so future changes to the agreement do not alter already-generated invoices

The system then saves the invoice and returns the user to the invoice list.

### Generating Batch Invoices

The user can select several agreement items and trigger batch generation. The system repeats the same calculation process for each selected item and shows a summary of which ones succeeded or failed.

### Viewing Invoice Details

The detail screen shows the full invoice in a clear layout:
- **Header:** Invoice number, vendor name, agreement reference, invoice date, due date, status label
- **Billing Period:** Start date and end date
- **Item Details:** Description of the item
- **Charge Breakdown:** Billing method, fixed charge, unit charge, quantity used, rate per unit, minimum guarantee quantity
- **Tax Breakdown:** Up to four tax percentages with calculated amounts, subtotal, total tax
- **Financial Summary:** Other charges, discount, amount due, amount paid, balance remaining
- **Payments:** List of payments linked to this invoice
- **Notes:** Internal notes or dispute comments

### Turning Status On or Off

Users can switch an invoice between active and inactive directly from the list. This also turns the associated agreement item on or off.

### Invoice PDF Download (Single)

The system creates a PDF of the invoice and sends it for download. The user's permission to download PDFs is checked first.

### Invoice PDF Download (Batch/ZIP)

The user selects multiple invoices and clicks "Download ZIP." The system creates PDFs and packages them into a ZIP file for download.

**KNOWN FLAW:** The batch download currently pulls information from the wrong place — it uses agreement item records instead of invoice records. This will likely produce incorrect PDFs.

### Email Delivery

The user can select one or more invoices and click "Send Email." The system sends each invoice PDF to the vendor by email. The user's permission to email invoices is checked first.

### Notes

The user can add or edit notes on an invoice. The user's permission to add notes is checked first.

---

## Validation Before Saving

### Invoice Generation — What the System Checks

**Agreement Item Checks:**
- Vendor must be provided and must exist in the system
- Agreement must be provided and must exist in the system
- Agreement item must be provided and must exist in the system
- Agreement must be in Active status (this check is NOT working — see Known Flaw below)
- No duplicate invoice may exist for the same agreement item and billing period

**Billing Information Checks:**
- Invoice date must be provided and valid
- Billing start and end dates must be provided (used to calculate usage)
- Billing method is taken from the agreement item (Fixed Price, Unit Rate, or Minimum Guarantee)

---

## Business Rules

### Rule 1: No Duplicate Invoice for Same Item and Period
Before generating an invoice, the system must check that no invoice already exists for the same agreement item with an overlapping billing period. If a duplicate is found, generation is blocked with an error message.

### Rule 2: Invoice Generation Requires Active Agreement
The vendor agreement must be in Active status for invoice generation to proceed. **KNOWN FLAW: This rule is NOT currently working in the system.** Without this check, invoices can be created against agreements that have been cancelled or turned off.

### Rule 3: Record Billing Settings at Generation Time
All billing settings (fixed charge amount, unit charge amount, quantity used, rate per unit, minimum guarantee quantity, tax percentages) must be captured when the invoice is generated. Later changes to the agreement item should not change already-generated invoices.

### Rule 4: Billing Frequency
- **Monthly:** Only one invoice per agreement item per calendar month is allowed
- **One-Time:** Only one invoice per agreement item in its entire lifetime is allowed

### Rule 5: Unique Invoice Number Per Vendor
Each invoice must have a unique invoice number within a vendor. **KNOWN FLAW: The system currently uses a random 3-digit number to create invoice numbers. This means two invoices could end up with the same number, especially when many invoices are being created at the same time.** A proper sequential numbering system should be used instead.

### Rule 6: Default Quantity When No Usage Records
If no usage records exist for the billing period, the system assumes a quantity of 1 instead of failing. This ensures fixed-price and one-time items still generate correctly.

### Rule 7: Three Billing Methods
- **Fixed Price:** subtotal = fixed charge amount. No usage tracking needed. Best for one-time fees or setup charges.
- **Unit Rate (Consumption):** subtotal = quantity used × rate per unit. Usage is added up from usage records.
- **Minimum Guarantee:** subtotal = whichever is larger (quantity used or minimum guaranteed quantity) × rate per unit. If actual usage is below the minimum guarantee, the minimum applies.

### Rule 8: Tax Calculation
Up to four tax percentages are added together and applied to the subtotal. Total tax = subtotal × (sum of all tax percentages) / 100.

### Rule 9: Final Amount Due
Amount due = subtotal + total tax + other charges − discount. The balance remaining is calculated as amount due − amount paid.

### Rule 10: Due Date
Due date = invoice date + payment terms (in days) from the vendor agreement. If the agreement has no payment terms defined, the due date is left blank.

### Rule 11: Status Values
Status can be Pending, Approved, Paid, Disputed, or Cancelled. These values are managed in the system's dropdown configuration.

### Rule 12: No Removal When Payments Exist
Invoices should not be removable if they have payment records linked to them. A check must be done before allowing removal.

### Rule 13: Balance Automatically Calculated
The balance remaining is always calculated automatically as amount due minus amount paid, so it is never out of date.

---

## Business Rules Summary (Quick Reference)

| Rule | What It Means |
|------|--------------|
| Rule 1 | No duplicate invoice for same item and billing period |
| Rule 2 | Invoice generation requires Active agreement (NOT working) |
| Rule 3 | Record billing settings at generation time |
| Rule 4 | Monthly = 1 per month, One-Time = 1 total |
| Rule 5 | Unique invoice number per vendor (uses random number — may cause duplicates) |
| Rule 6 | Assume quantity = 1 if no usage records exist |
| 3 Billing Methods | Fixed Price, Unit Rate, Minimum Guarantee |
| Tax Calculation | Sum of up to 4 tax percentages applied to subtotal |
| Amount Due | subtotal + total tax + other charges − discount |
| Balance Remaining | Automatically calculated as amount due − amount paid |
| Due Date | Invoice date + payment terms from agreement |

---

## Known Flaws — What Is Broken

### 1. The "Save Payment" Button Is on the Wrong Page
The button that records payments against an invoice is mislabeled and confusing. It looks like it should create invoices but instead it records payments. This needs to be renamed or moved to the payments section.

### 2. Updating an Invoice Does Not Work
When a user tries to edit and save changes to an invoice, nothing actually happens. The system accepts the request but does not change anything. The feature was never finished.

### 3. Deleting an Invoice Does Not Work
When a user tries to remove an invoice, nothing actually happens. The system accepts the request but does not remove anything. The feature was never finished.

### 4. Viewing Removed (Trashed) Invoices Will Cause an Error
There is a page meant to show invoices that have been removed (trashed), but the feature was never built. Accessing this page will cause the system to crash with an error.

### 5. Validation Rules Are Not Centralized
The rules for checking invoice data are written directly in the code instead of being in a single, reusable place. This makes them harder to maintain and update.

### 6. Some Permissions May Not Be Registered
The system checks for five specific permissions that may not actually exist yet:
- Permission to change invoice status
- Permission to add notes
- Permission to download PDF
- Permission to print
- Permission to email invoices

If any of these are missing, the system will block the action even for users who should have access.

### 7. Batch PDF Download Uses Wrong Records
When downloading multiple invoice PDFs as a ZIP file, the system pulls information from agreement item records instead of invoice records. This will likely produce incorrect or empty PDFs.

### 8. Invoice Numbers Might Get Duplicated
The system creates invoice numbers using a random 3-digit number. With many invoices, especially if two people generate invoices at the same time, there is a high chance two invoices get the same number. This will cause an error for the second one.

---

## What Is Working

| Feature | What It Does | Permission Checked |
|---------|-------------|-------------------|
| View invoice list | Shows a filtered list of invoices | View invoices |
| Open generation form | Shows the form to create an invoice | Create invoices |
| View invoice details | Shows full invoice information | View invoices |
| Open edit form | Shows the form to edit an invoice | Update invoices |
| Toggle active status | Turns invoice and agreement item on or off | Change invoice status |
| Generate single invoice | Creates one invoice using the billing engine | Create invoices |
| Generate batch invoices | Creates multiple invoices at once | Create invoices |
| Billing engine (internal) | Calculates usage, billing, tax, and prevents duplicates | Internal |
| Save notes | Adds or changes notes on an invoice | Add notes to invoice |
| Batch PDF download | ZIP download of PDFs (currently generates from agreement items — see flaw above) | Download invoice PDF |
| Print view | Shows a print-friendly version | Print invoices |
| Detail panel | Shows invoice information (used by popup) | View invoices |
| Send emails | Sends invoice PDFs to vendors by email | Email invoices |

---

## Error Messages

| Situation | Error Message |
|-----------|--------------|
| Duplicate invoice for same item and period | "An invoice already exists for this agreement item in the specified billing period." |
| Agreement not found | "Agreement not found." |
| Agreement item not found | "Agreement item not found." |
| Vendor not found | "Vendor not found." |
| Invoice generation — agreement not active | "Invoice generation requires an active agreement." (this check is NOT working) |
| Invoice date not provided | "The invoice date field is required." |
| Invoice not found (any action) | "Invoice not found." |
| Cannot remove invoice with payments | "Cannot delete invoice with existing payment records." |

---

## Example Scenarios

### Success Scenario 1 — Generate Single Fixed-Price Invoice
An accounts manager selects a vendor agreement item with Fixed Price billing of ₹10,000. The billing period is April 2026. No usage records exist. The system assumes quantity = 1, calculates subtotal = ₹10,000, applies 18% GST, calculates tax = ₹1,800, total amount due = ₹11,800. Invoice number "342" is assigned. Invoice is created successfully.

### Success Scenario 2 — Generate Unit Rate Invoice with Usage
An agreement item has a rate of ₹50 per unit and uses Unit Rate billing. The billing period is May 2026. Usage records show 150 units were used. The system calculates subtotal = 150 × ₹50 = ₹7,500, applies 12% GST, total amount due = ₹8,400. Invoice is created successfully.

### Success Scenario 3 — Generate Minimum Guarantee Invoice
An agreement item has a rate of ₹100 per unit and a minimum guarantee of 500 units. Actual usage is 320 units. The system applies the minimum guarantee: subtotal = whichever is larger (320, 500) × ₹100 = ₹50,000. Invoice is created successfully.

### Success Scenario 4 — Batch Generate Monthly Invoices
A user selects 5 agreement items across different vendors and clicks "Generate All." All 5 pass the duplicate check. The system creates 5 invoices, each with its own calculated values. A success summary is shown.

### Success Scenario 5 — Download Single Invoice PDF
A user views an invoice and clicks "Download PDF." The system creates a PDF and downloads it.

### Success Scenario 6 — Batch Download ZIP of PDFs
A user selects 3 invoices and clicks "Download ZIP." The system creates a ZIP file containing 3 PDFs and downloads it.

### Success Scenario 7 — Email Invoice to Vendor
A user selects an invoice and clicks "Send Email." The system sends the invoice PDF to the vendor by email.

### Failure Scenario 1 — Duplicate Invoice Generation
A user tries to create an invoice for an agreement item that already has an invoice for the same billing period. The system blocks with "An invoice already exists for this agreement item in the specified billing period."

### Failure Scenario 2 — Invoice Number Collision
Two users create invoices for the same vendor at the same time. Both get the same random 3-digit number (e.g., "342"). The system cannot save the second one and shows an error.

### Failure Scenario 3 — Invoice Created on Cancelled Agreement (Gap)
A user creates an invoice for an agreement that has been cancelled. The system currently allows this because the check for active agreements is not working. The invoice is created against a cancelled agreement, causing problems later when trying to match payments.

### Failure Scenario 4 — Access Removed Invoices Page (Error)
A user navigates to the page for viewing removed (trashed) invoices. The feature was never built, so the system crashes with an error.

### Failure Scenario 5 — Update Invoice Does Nothing
A user edits an invoice and saves. The feature was never finished, so the request succeeds but nothing changes.

### Failure Scenario 6 — Delete Invoice Does Nothing
A user tries to remove an invoice. The feature was never finished, so the request succeeds but the invoice is not removed.

### Failure Scenario 7 — Batch PDF Download Gets Wrong Records
A user selects 3 invoices and clicks "Download ZIP." The system generates PDFs from agreement item records instead of invoice records, producing incorrect or empty PDFs.

---

## Example Walkthrough

Mrs. Sharma, the Accounts Manager of Sunshine International School, needs to generate monthly invoices for vendors.

She opens the Vendor Invoice screen and clicks "Generate Invoice":

1. **Pick Agreement Item:** She selects Vendor = "EduSupplies India Pvt Ltd", Agreement = "Stationery Supply 2026", Agreement Item = "A4 Paper Ream Supply". Billing method = Unit Rate, rate = ₹250 per ream.

2. **Set Billing Period:** She sets Billing Start = 2026-04-01, Billing End = 2026-04-30, Invoice Date = 2026-05-01.

3. **Generate:** Clicking "Generate" starts the calculation:
   - Duplicate check: No existing invoice for this item and April 2026 period — PASS
   - Usage: Usage records show 80 reams used in April — quantity = 80
   - Calculation: subtotal = 80 × ₹250 = ₹20,000
   - Tax: 18% GST = ₹3,600
   - Total amount due = ₹20,000 + ₹3,600 = ₹23,600
   - Due date = 2026-05-01 + 30 days (payment terms) = 2026-05-31
   - Invoice number = random 3-digit (e.g., "847")

4. The system creates the invoice and shows a success message.

Later, she views the invoice, clicks "Download PDF," and emails it to the vendor for payment.

---

## Related Screens

- **Vendor Master** — Where vendor profiles are managed and linked to invoices
- **Vendor Agreement** — Where agreement items with billing methods are set up
- **Vendor Item / Service Catalogue** — Where items are defined that appear in agreement items
- **Usage Log** — Where usage or consumption data is tracked for unit-rate billing
- **Payments** — Where payments recorded against invoices

---

## Dependencies

This screen depends on information from these areas:

| Area | What Information It Provides |
|------|---------------------------|
| Vendor Master | Vendor names and details |
| Vendor Agreement | Agreement details and billing settings |
| Usage Log | Quantity used for consumption-based billing |
| Payments | Payment records linked to invoices |
| System Settings | Status dropdown values and user records |
| Activity Log | Record of changes made (who did what and when) |
