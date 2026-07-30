# Vendor Master — Business Requirements

## What This Screen Does

The Vendor Master screen is where school administrators manage their vendor ecosystem — think suppliers, service providers, contractors, and partners. It serves as the central directory: administrators create vendor profiles with all essential details (business name, contact person, GSTIN, PAN, bank info, UPI ID), upload KYC documents for compliance, and control vendor activity status.

The main list view shows all vendors with filters to narrow down by search keywords (name, contact person, contact number, email) and active/inactive status. Administrators can create new vendors, edit existing profiles, view full details, remove vendors from view, restore them, permanently delete them, and turn their active status on or off right from the list.

---

## When This Screen Is Used

- **Registering a New Vendor** — When a school onboards a new supplier or service provider
- **Editing Vendor Details** — When a vendor's contact, bank, or tax information changes
- **Viewing Vendor Profile** — To review the full profile including KYC documents and activity history
- **Uploading KYC Documents** — To attach compliance documents (GST certificate, PAN card, bank proof)
- **Removing and Restoring** — To temporarily remove a vendor from view or reinstate them from trash
- **Permanently Deleting** — To permanently remove a vendor record from the system
- **Turning Active Status On or Off** — To quickly activate or deactivate a vendor from the list view

---

## Who Can Access This Screen

- **School Admin** — Full access including remove, restore, permanent delete, toggle status, and document management
- **Accounts Manager** — Can view and edit vendor financial details (bank info, GST, PAN)
- **Purchase Manager** — Can view and create vendors for procurement purposes
- **Principal** — Read-only access to view vendor profiles

The system checks the user's permissions before every action to ensure only authorised staff can perform each operation.

---

## How This Screen Works — Step by Step

### The Vendor List

When an administrator opens the Vendor Master, the system shows a list of vendors (10 per page) with columns: #, Vendor Name, Vendor Type, Contact Person, Contact Number, Email, GST Number, PAN Number, Active toggle, and Actions (View, Edit, Delete). A filter panel above the list lets administrators narrow down by search keywords (name, contact person, contact number, email) and Active/Inactive status.

The list shows only active vendors by default. A separate "Trash" tab shows removed records.

### Creating a Vendor

When the administrator clicks "Add Vendor," they see a single-page form with the following sections:

**Business Information:**
- Vendor Name (required, must be unique across the school)
- Vendor Type (required, chosen from a predefined list)
- Contact Person (required)
- Contact Number (required)
- Email (optional)
- Address (optional)

**Tax & Compliance:**
- GST Number (optional, checked for correct format)
- PAN Number (optional, checked for correct format)

**Banking Details:**
- Bank Name (optional)
- Bank Account Number (optional, saved securely)
- Bank IFSC Code (optional, saved securely)
- Bank Branch (optional)
- UPI ID (optional)

**Status:**
- Active toggle (defaults to Active)

When the administrator clicks "Save," the system checks all fields, encrypts sensitive personal information (PAN number, bank account number, IFSC code), creates the vendor record, and returns to the list with a success message.

### Editing a Vendor

The edit form opens with all existing values pre-filled. The vendor name uniqueness check ignores the current vendor being edited and also ignores deleted records (so a deleted vendor's name can be reused). Sensitive fields are unencrypted for display and encrypted again on save. Every change is recorded with a timestamp.

### Viewing Vendor Profile

The detail view shows the full vendor profile in a structured layout:
- **Business Info Card:** Vendor name, type badge, contact person, contact number, email, address
- **Tax Info Card:** GST number, PAN number
- **Banking Info Card:** Bank name, account number (masked), IFSC code (masked), branch, UPI ID
- **Documents Section:** All uploaded KYC documents with upload/delete controls
- **Activity Log:** Timestamped log of all changes made to this vendor

### Uploading KYC Documents

Administrators can upload multiple documents per vendor (GST certificate, PAN card, bank proof, etc.). Documents are stored in the vendor's document collection. Each upload is checked for file type (PDF, JPG, PNG, max 5MB) and linked to the vendor record.

### Removing and Restoring

When an administrator removes a vendor, the record is hidden but retained in the system. The administrator can restore the vendor from the Trash page.

### Permanently Deleting

When an administrator permanently deletes a vendor from the Trash, the record and all its documents (KYC files) are permanently removed from the system. This action cannot be undone.

### Toggle Status

Administrators can turn a vendor's active status on or off directly from the list view without reloading the page. Each change is saved with a timestamp. Inactive vendors are excluded from selection lists elsewhere in the system.

---

## Validation Rules — What's Required Before Saving

### Business Information:

| Field | Rule |
|-------|------|
| Vendor Name | Required, up to 100 characters, must be unique across the school (ignores the vendor being edited and deleted records) |
| Vendor Type | Required, must be a valid option from the predefined list |
| Contact Person | Required, up to 100 characters |
| Contact Number | Required, up to 30 characters |
| Email | Optional, must be a valid email format, up to 100 characters |
| Address | Optional, up to 512 characters |

### Tax & Compliance:

| Field | Rule |
|-------|------|
| GST Number | Optional, must be in correct format |
| PAN Number | Optional, must be in correct format |

### Banking Details:

| Field | Rule |
|-------|------|
| Bank Name | Optional, up to 100 characters |
| Bank Account Number | Optional, up to 50 characters |
| Bank IFSC Code | Optional, up to 20 characters |
| Bank Branch | Optional, up to 100 characters |
| UPI ID | Optional, up to 100 characters |

### Status:

| Field | Rule |
|-------|------|
| Active | Optional, can be Yes or No |

---

## Business Rules and Conditions

### Rule BR-VND-001: GSTIN Unique Per School, PAN Unique Per School
GST Number must be unique across all active vendors within the same school. PAN Number must similarly be unique. Duplicate entries are rejected. Deleted records are excluded from this check.

### Rule BR-VND-019: Only Active Vendors in Selection Lists
When vendor lists are shown in dropdown menus elsewhere in the system (e.g., Purchase Order creation, Expense entry), only vendors with Active status are displayed. Inactive or removed vendors are excluded.

### Rule 4: Sensitive Information Is Saved Securely
Sensitive fields — PAN number, bank account number, bank IFSC code — are encrypted when stored. They are automatically decrypted for display and encrypted again on save. These fields are masked in list views (e.g., `XXXXXX1234`) for privacy.

### Rule 5: Vendor Name Must Be Unique
Vendor name must be unique across all non-deleted vendor records. When editing, the check ignores the vendor's own name. Deleted records are also excluded, so a deleted vendor's name can be reused.

### Rule 6: Vendor Type Must Be a Valid Option
The vendor type must come from the predefined list of vendor types. If someone tries to delete a vendor type that is already in use, the system will block the deletion to prevent broken links.

### Rule 7: Permanent Removal Also Removes Documents
When a vendor is permanently deleted, all associated documents (KYC files) are also permanently removed from the system. This is done as a single complete operation.

### Rule 8: All Changes Are Tracked
Every operation — create, edit, remove, restore, permanent delete, toggle status — is recorded with a timestamp. Each entry captures who did it, what action was taken, and a description of the change.

### Rule 9: Document Upload Rules
All vendor KYC documents are stored attached to the vendor record. Supported file types: PDF, JPG, PNG. Maximum file size: 5MB per document.

---

## Business Rules Summary (Quick Reference)

| Rule | What It Means |
|------|--------------|
| BR-VND-001 | GSTIN and PAN must be unique per school |
| BR-VND-019 | Only active vendors appear in selection lists |
| PII Encryption | PAN, bank account, IFSC encrypted for secure storage |
| Unique Name | Vendor name unique across non-deleted records |
| Vendor Type Validity | Vendor type must be from the predefined options |
| Document Cleanup | Permanently deleting a vendor also removes all documents |
| Activity Logging | All changes recorded with user and timestamp |
| Document Upload | KYC docs in PDF/JPG/PNG format, 5MB max |

---

## Error Messages

| Scenario | Error Message |
|----------|--------------|
| Missing vendor name | "The vendor name field is required." |
| Vendor name too long | "The vendor name must not exceed 100 characters." |
| Duplicate vendor name | "The vendor name has already been taken." |
| Vendor type not selected | "The vendor type is required." |
| Invalid vendor type | "The selected vendor type is invalid." |
| Missing contact person | "The contact person field is required." |
| Missing contact number | "The contact number field is required." |
| Invalid email format | "The email must be a valid email address." |
| Invalid GSTIN format | "The GST number must be in the correct format." |
| Duplicate GSTIN | "The GST number has already been taken." |
| Invalid PAN format | "The PAN number must be in the correct format." |
| Duplicate PAN | "The PAN number has already been taken." |
| Invalid active status | "The active field must be set to Yes or No." |

| Document upload — wrong type | "The document must be a file of type: pdf, jpg, png." |
| Document upload — too large | "The document must not exceed 5 MB." |
| Toggle — record not found | "Vendor not found." |

---

## Success Scenarios

- An administrator creates a new vendor: Vendor Name = "EduSupplies India Pvt Ltd", Vendor Type = "Supplier", Contact Person = "Rajesh Kumar", Contact Number = "+91-9876543210", Email = "rajesh@edusupplies.in", Address = "Mumbai, Maharashtra", GST Number = "27AABCU9603R1ZM", PAN Number = "AABCU9603R". The system saves the vendor record, encrypts the PAN securely, and returns to the list with a success message.

- An administrator uploads a GST certificate PDF to an existing vendor. The file is stored in the vendor's document collection. The document appears in the vendor's profile view.

- An administrator turns a vendor from Active to Inactive via the list toggle. The vendor's status is set to Inactive. The vendor disappears from all selection lists across the system. A timestamped record is created.

- An administrator removes a vendor with no active agreements. The vendor disappears from the main list but appears in the Trash tab. The administrator later restores the vendor — all original data is reinstated.

---

## Failure Scenarios

- An administrator tries to create a vendor with a duplicate vendor name "EduSupplies India Pvt Ltd". The system rejects with "The vendor name has already been taken."

- An administrator tries to upload a Word document (.docx) as KYC. The system rejects with "The document must be a file of type: pdf, jpg, png."

- An administrator enters a GST number with only 12 characters. The system rejects with "The GST number must be in the correct format."

- An administrator tries to delete a vendor type that is linked to existing vendors. The system blocks the deletion.

---

## Example Scenario

Mrs. Mehta, the School Admin of Sunshine International School, needs to onboard a new stationery supplier.

She navigates to Vendor Master and clicks "Add Vendor":

1. **Business Information:** She enters Vendor Name = "Sunshine Stationery Mart", selects Vendor Type = "Supplier" from the dropdown, enters Contact Person = "Amit Shah", Contact Number = "+91-9988776655", Email = "amit@ssmart.in", Address = "123, Market Road, Delhi".

2. **Tax & Compliance:** She enters GST Number = "07AABCS1234R1ZM" (correct format) and PAN Number = "AABCS1234R" (correct format).

3. **Banking Details:** She enters Bank Name = "HDFC Bank", Account Number = "50100234567890", IFSC Code = "HDFC0001234", Branch = "Delhi Main Branch", UPI ID = "amit@hdfcbank".

4. **Status:** She leaves Active toggle ON.

5. She clicks "Save". The system checks all fields, encrypts the PAN number and bank account number securely, creates the vendor, and returns to the vendor list showing the new entry.

Six months later, the contract with Sunshine Stationery Mart ends. Mrs. Mehta goes to the vendor list, finds the vendor, and clicks "Delete". The system removes the vendor from view. The vendor moves to the Trash.

After one year, the school re-engages the same vendor. Mrs. Mehta goes to the Trash tab, finds Sunshine Stationery Mart, and clicks "Restore". The vendor is reinstated with all original data intact.

---

## Related Screens

- **Vendor Type Master** — Where vendor type options are managed
- **Purchase Order** — Uses vendor information and checks for active agreements before allowing removal
- **Expense Management** — Uses vendor information for expense entries
- **Contract Management** — Tracks vendor contracts and agreements

---

## How Other Parts of the System Depend on This Screen

| Area | What It Needs From Vendor Master |
|------|----------------------------------|
| **Vendor records** | All vendor information is stored and managed here |
| **System settings** | Vendor types come from shared system settings; user information is used for activity tracking |
| **Document storage** | KYC documents are stored and linked to vendor records |
| **Change history** | All changes to vendors are recorded with timestamps |
| **Purchasing** | Purchase orders and expenses reference vendors |
| **Contracts** | Contracts and agreements are linked to vendors |
