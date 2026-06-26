# Vendor Master — Business Requirements

## What This Screen Does

The Vendor Master screen is the foundation of the entire Vendor module. This is where the school records every company or individual that provides goods or services to the school — whether it is a bus service provider, a canteen supplier, a stationery shop, a security agency, or a software company.

Think of the Vendor Master as the school's official contact book for all its suppliers. Before the school can sign any agreement, raise any invoice, or make any payment to a vendor, that vendor must first be registered here.

---

## When This Screen Is Used

- A new supplier starts delivering goods or services to the school and needs to be registered
- Admin wants to update a vendor's contact details, bank account, or GST number
- Finance team needs to verify a vendor's PAN or bank information before processing a payment
- A vendor is no longer working with the school and needs to be deactivated
- Admin wants to search or list all active vendors for reporting purposes

---

## Key Fields at a Glance

**Basic Identity**
Every vendor must have a unique name. The vendor type (e.g., Transport, Canteen, IT Services, Security) is selected from a master dropdown list, which helps categorise and filter vendors easily.

**Contact Information**
The name of the person to contact at the vendor's organisation, along with their phone number and email address. This is used for day-to-day communication and invoice delivery.

**Address**
The vendor's registered business address. Useful for documentation, agreements, and sending physical correspondence.

**GST and PAN Details**
The vendor's GST registration number (GSTIN) and PAN number are required for compliance and tax invoicing. These are stored securely and referenced when generating invoices.

**Bank Details**
Bank name, account number, IFSC code, branch name, and UPI ID are recorded for payment processing. These details are used by the finance team when making bank transfers or UPI payments.

**Document Upload**
A scanned copy of the vendor's registration certificate, GST certificate, or any other key document can be uploaded and attached to the vendor record.

**Status**
Each vendor can be Active (currently operational) or Inactive (suspended or no longer used).

---

## Business Rules and Conditions

**Unique Vendor Name**
No two vendors in the same school (tenant) can have the exact same name. The system must prevent duplicate registrations to avoid confusion during agreement creation and invoice processing.

**Vendor Type is Mandatory**
A vendor must be classified under a type before it can be saved. Without a type, the vendor cannot be used in filters or reports effectively.

**GST and PAN Formats**
If provided, the GSTIN must follow the standard 15-character format (e.g., 27ABCDE1234F1Z5). PAN must be a valid 10-character alphanumeric code. These validations prevent incorrect data from being stored.

**Soft Delete Protection**
When a vendor is deactivated or deleted, the system should check whether there are active agreements, pending invoices, or outstanding payments linked to that vendor. If yes, the system must warn the admin before allowing deletion.

**Active Status and Visibility**
Only Active vendors appear in agreement creation forms and invoice generation dropdowns. Inactive vendors remain in the system for historical reference but cannot be used for new transactions.

---

## Workflow Steps

**Adding a New Vendor**
Admin opens the Add Vendor form, fills in the vendor name, selects the vendor type from the dropdown, enters contact person details, fills in the address, adds GST and PAN numbers, provides bank details, optionally uploads a document, and submits. A success message confirms the vendor is registered.

**Viewing Vendor List**
The vendor list screen displays all vendors with search and filter options — filter by vendor type, filter by Active/Inactive status, or search by name. Each row shows vendor name, type, contact number, and status.

**Editing a Vendor**
Admin clicks on a vendor and edits any field — contact details, bank information, or address. Changes are saved and reflected immediately.

**Deactivating a Vendor**
Admin can toggle a vendor's status to Inactive using the status switch on the list screen. The vendor disappears from active dropdowns but remains in the records for past transactions.

**Deleting a Vendor**
Admin soft-deletes a vendor. Deleted vendors move to the trash and are hidden from the normal view. They can be restored if needed. Permanent deletion requires additional confirmation.

---

## Example Scenario

A school contracts a new bus operator called "Sharma Transport Services" to run three routes. Admin registers this vendor with:
- Vendor Type: Transport
- Contact Person: Ramesh Sharma, 9876543210
- GST Number: 27SHRMS1234A1Z3
- Bank: HDFC Bank, A/C 1234567890, IFSC HDFC0001234

Once registered, the admin can proceed to create a transport agreement with Sharma Transport Services, define the services (routes, vehicles), and set up billing terms. All future invoices and payments will be linked back to this vendor record.

---

## Related Screens

- **Vendor Agreement** — A vendor must exist before any agreement can be created
- **Vendor Invoice** — Invoices are always raised against a specific vendor
- **Payment Details** — Payments are always linked to a vendor and its invoice
