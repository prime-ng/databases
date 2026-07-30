# vnd_Vendor_Master_TcList

## Module: Vendor → Vendor Management → Vendor CRUD

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Vendor (VND) |
| Tab Group | Vendor Dashboard (Tabbed Interface) |
| Features | Vendor List, Create/Edit/View/Delete/Restore/Force-Delete, Toggle Status, Activity Logging, Multi-Tab Dashboard (Vendor, Agreements, Items, Invoices, Payments, Usage Logs) |
| URL(s) | `/vendor`, `/vendor/create`, `/vendor/{vendor}/edit`, `/vendor/{vendor}`, `/vendor/trash/view`, `/vendor/{id}/restore`, `/vendor/{id}/force-delete`, `/vendor/{id}/toggle-status` |
| Controller | `Modules\Vendor\Http\Controllers\VendorController` |
| Model(s) | `Vendor`, `VndAgreement`, `VndItem`, `VndInvoice`, `VndPayment`, `VndUsageLog` |
| Validation | `VendorRequest` (14 rules) |
| Permission Gates | `tenant.vendor.viewAny`, `tenant.vendor.view`, `tenant.vendor.create`, `tenant.vendor.update`, `tenant.vendor.delete`, `tenant.vendor.restore`, `tenant.vendor.forceDelete` |
| Soft Deletes | Yes — Vendor model uses `SoftDeletes` trait |
| Events | `activityLog()` on store, update, destroy, restore, forceDelete, toggleStatus |

---

## 2. Pre-conditions

- Required permissions: `tenant.vendor.viewAny`, `tenant.vendor.create`, `tenant.vendor.update`, `tenant.vendor.view`, `tenant.vendor.delete`, `tenant.vendor.restore`, `tenant.vendor.forceDelete`
- At least one active Vendor Type must exist in `sys_dropdown_table` (referenced by `vendor_type_id`)
- For search/filter tests: at least one vendor record with populated fields
- For tab-view tests: related records (agreements, items, invoices, payments, usage logs) must exist in their respective tables
- For toggle-status tests: at least one active and one inactive vendor record
- For trash/restore tests: at least one soft-deleted vendor record
- For GST/PAN/IFSC validation tests: values within max length constraints

---

## 3. Default Data Load

### 3.1 Filter Data for Vendor Tab

The `vendorsQuery()` method returns:
- `vendors` — Paginated vendor records with search support (vendor_name, contact_person, contact_number, email)
- `vendorsList` — All vendors (unpaginated, used for dropdown filters in other tabs)

Search/filter parameters:
- `search` — Text search on vendor_name, contact_person, contact_number, email
- `status` — is_active filter (converted to boolean)

### 3.2 Filter Data for Agreements Tab

The `vendorAgreementsQuery()` method returns:
- `vendorAgreements` — Paginated VndAgreement records with vendor relation
- Search: vendor_name (through vendor relation) and agreement_ref_no
- Status: is_active filter

### 3.3 Filter Data for Items Tab

The `vendorItemsQuery()` method returns:
- `vendorItems` — Paginated VndItem records
- Search: item_name, item_code, hsn_sac_code
- Status: is_active filter

### 3.4 Filter Data for Invoices Tab

The `vendorInvoiceQuery()` method returns:
- `vendorinvoice` — Paginated VndAgreementItem records with agreement.vendor, item, invoices relations
- Returns empty set if no filters applied (status, date_range, data_type required)
- data_type: `Inv. Need To Generate` or `Invoicing Done`
- Date range filters on start_date (need to generate) or invoice_date (invoicing done)

### 3.5 Filter Data for Payments Tab

The `vendorPaymentsQuery()` method returns:
- `vendorPayments` — Paginated VndPayment records with vendor and invoice relations
- Filters: vendor_id, date_range, status, reconciled

### 3.6 Filter Data for Usage Logs Tab

The `vendorUsageLogsQuery()` method returns:
- `vendorUsageLogs` — Paginated VndUsageLog records with vendor and agreementItem relations
- Filters: vendor_id, date

---

## 4. BC-DB — Database Schema

### 4.1 `vnd_vendors` — Primary Vendor Table

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| vendor_name | VARCHAR(100) | NOT NULL | — | Unique vendor name |
| vendor_type_id | INT UNSIGNED | NOT NULL | — | FK → sys_dropdown_table(id) RESTRICT |
| contact_person | VARCHAR(100) | NOT NULL | — | Contact person name |
| contact_number | VARCHAR(30) | NOT NULL | — | Contact number |
| email | VARCHAR(100) | YES | NULL | Email address |
| address | VARCHAR(512) | YES | NULL | Vendor address |
| gst_number | VARCHAR(50) | YES | NULL | GST registration number |
| pan_number | VARCHAR(50) | YES | NULL | PAN card number (SafeEncrypted) |
| bank_name | VARCHAR(100) | YES | NULL | Bank name |
| bank_account_no | VARCHAR(50) | YES | NULL | Bank account number (SafeEncrypted) |
| bank_ifsc_code | VARCHAR(20) | YES | NULL | Bank IFSC code (SafeEncrypted) |
| bank_branch | VARCHAR(100) | YES | NULL | Bank branch name |
| upi_id | VARCHAR(100) | YES | NULL | UPI ID |
| is_active | TINYINT(1) | YES | 1 | Active flag |
| is_deleted | TINYINT(1) | YES | 0 | Deleted flag (legacy — SoftDeletes also used) |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | Update time |
| deleted_at | TIMESTAMP | YES | NULL | Soft delete time |

**Indexes:**
- PRIMARY KEY (`id`)
- UNIQUE KEY `uq_vnd_vendor_name` (`vendor_name`)
- KEY `idx_vnd_vendor_type` (`vendor_type_id`)

---

## 5. BC-VAL — Validation Rules

### 5.1 VendorRequest Validation

| Field | Rules | Error Message |
|-------|-------|---------------|
| vendor_name | required, string, max:100, unique:vnd_vendors,vendor_name (ignore $vendorId on update, whereNull deleted_at) | "The vendor name has already been taken." (unique) |
| vendor_type_id | required, integer | "The vendor type id field is required." |
| contact_person | required, string, max:100 | "The contact person field is required." |
| contact_number | required, string, max:20 | "The contact number field is required." |
| email | nullable, email, max:100 | "The email must be a valid email address." |
| address | required, string, max:500 | "The address field is required." |
| gst_number | nullable, string, max:20 | — |
| pan_number | nullable, string, max:20 | — |
| bank_name | nullable, string, max:100 | — |
| bank_account_no | nullable, string, max:30 | — |
| bank_ifsc_code | nullable, string, max:20 | — |
| bank_branch | nullable, string, max:100 | — |
| upi_id | nullable, string, max:100 | — |
| is_active | required, boolean | "The is active field must be true or false." |

**prepareForValidation:** `is_active` is converted from checkbox to boolean via `$this->boolean('is_active')`

**Unique Rule On Update:** Uses `Rule::unique('vnd_vendors', 'vendor_name')->ignore($vendorId)->whereNull('deleted_at')` to exclude soft-deleted records and the current record

**Authorization:** `authorize()` method returns `true` (no Gate check in FormRequest — defence delegated to controller)

---

## 6. BC-AUTH — Authorization

| Permission Gate | Controller Method(s) | Model Policy |
|----------------|---------------------|-------------|
| tenant.vendor.viewAny | index() (via `Gate::any()` with 6 other permissions) | VendorPolicy@viewAny |
| tenant.vendor.view | show() | VendorPolicy@view |
| tenant.vendor.create | create(), store() | VendorPolicy@create |
| tenant.vendor.update | edit(), update(), toggleStatus() | VendorPolicy@update |
| tenant.vendor.delete | destroy() | VendorPolicy@delete |
| tenant.vendor.restore | trashed(), restore() | VendorPolicy@restore |
| tenant.vendor.forceDelete | forceDelete() | VendorPolicy@forceDelete |

**index() Gate Behaviour:** Uses `Gate::any([...6 permissions...]) || abort(403)` — any one of 7 vendor-related permissions grants access to the dashboard tab view

**Policy status() Method:** Defined in VendorPolicy as `$user->can('tenant.vendor.view')` — uses the same permission as view

**Blade @can directives (expected in views):**
- `@can('tenant.vendor.viewAny')` — Dashboard access
- `@can('tenant.vendor.create')` — Create button
- `@can('tenant.vendor.update')` — Edit and Toggle Status actions
- `@can('tenant.vendor.view')` — View action button
- `@can('tenant.vendor.delete')` — Delete action button

---

## 7. BC-BIZ — Business Logic

| BC-BIZ ID | Rule | Description |
|-----------|------|-------------|
| BC-BIZ-01 | Tabbed Dashboard View | index() returns unified tab view with 6 independent query methods (vendors, agreements, items, invoices, payments, usage logs) each paginated at 10 per page |
| BC-BIZ-02 | Multi-Permission Index Gate | index() uses `Gate::any()` with 7 permissions OR abort(403) — any one grants dashboard access |
| BC-BIZ-03 | Search Across Vendor Fields | vendorsQuery searches vendor_name, contact_person, contact_number, email via `like` with wildcards |
| BC-BIZ-04 | Tab-Specific Filtering | Each query method only applies filters when `$request->input('tab')` matches its tab key |
| BC-BIZ-05 | Invoice Tab Mandatory Filters | vendorInvoiceQuery returns empty set if no status/date_range/data_type filter is provided |
| BC-BIZ-06 | Change Tracking on Update | update() captures `$vendor->getChanges()` and logs old/new values before redirect |
| BC-BIZ-07 | Deactivate Before Soft-Delete | destroy() manually sets `is_active=false` before calling `$vendor->delete()` — redundant with SoftDeletes (Known Issue) |
| BC-BIZ-08 | Restore with Save | restore() calls `restore()` then `save()` on the restored model |
| BC-BIZ-09 | Activity Log All Operations | activityLog() called on store, update, destroy, restore, forceDelete, toggleStatus |
| BC-BIZ-10 | Toggle Status via AJAX | toggleStatus() validates is_active as required|boolean, returns JSON success/error response |
| BC-BIZ-11 | Force Delete with SoftDeletes | forceDelete() uses `withTrashed()->findOrFail()` to bypass SoftDeletes and permanently delete |
| BC-BIZ-12 | Unique Vendor Name (Soft-Delete Aware) | Validation ignores soft-deleted records and the current record on update |
| BC-BIZ-13 | PII Encryption via SafeEncrypted | pan_number, bank_account_no, bank_ifsc_code encrypted at DB level; accessible via accessor |
| BC-BIZ-14 | Masked Accessors | getPanMaskedAttribute (first 5 + XXXX + last 1) and getBankAccountMaskedAttribute (all X except last 4) |
| BC-BIZ-15 | Vendor Type FK Restrict | vendor_type_id FK → sys_dropdown_table(id) with RESTRICT — cannot delete referenced dropdown if vendors exist |

---

## 8. BC-REF — Referential Integrity

| Foreign Key | Column | References Table | On Delete |
|-------------|--------|-----------------|-----------|
| fk_vnd_vendor_type | vnd_vendors.vendor_type_id | sys_dropdown_table.id | RESTRICT |
| fk_vnd_agreement_vendor | vnd_agreements.vendor_id | vnd_vendors.id | CASCADE (implied by model relationships) |
| fk_vnd_item_vendor | vnd_items.vendor_id | vnd_vendors.id | CASCADE (implied by model relationships) |
| fk_vnd_invoice_vendor | vnd_invoices.vendor_id | vnd_vendors.id | CASCADE (implied by model relationships) |
| fk_vnd_payment_vendor | vnd_payments.vendor_id | vnd_invoices.vendor_id (through) | CASCADE (implied by model relationships) |
| fk_vnd_usage_log_vendor | vnd_usage_logs.vendor_id | vnd_vendors.id | CASCADE (implied by model relationships) |

---

## 9. Test Case Summary

### 9.1 Vendor CRUD — Positive TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-VND-P01 | Vendor CRUD | Positive | Vendor tab list loads with search and filter | 5 |
| TC-VND-P02 | Vendor CRUD | Positive | Create vendor — all required fields | 6 |
| TC-VND-P03 | Vendor CRUD | Positive | Create vendor — all optional fields (GST, PAN, Bank, UPI) | 6 |
| TC-VND-P04 | Vendor CRUD | Positive | Create vendor — duplicate vendor_name rejected | 2 |
| TC-VND-P05 | Vendor CRUD | Positive | View vendor detail | 3 |
| TC-VND-P06 | Vendor CRUD | Positive | Edit vendor — update vendor_name, contact info | 5 |
| TC-VND-P07 | Vendor CRUD | Positive | Edit vendor — change tracking logs old/new values | 4 |
| TC-VND-P08 | Vendor CRUD | Positive | Toggle status — active to inactive | 4 |
| TC-VND-P09 | Vendor CRUD | Positive | Toggle status — inactive to active | 4 |
| TC-VND-P10 | Vendor CRUD | Positive | Soft-delete vendor | 4 |
| TC-VND-P11 | Vendor CRUD | Positive | Restore vendor from trash | 4 |
| TC-VND-P12 | Vendor CRUD | Positive | Force-delete vendor | 4 |
| TC-VND-P13 | Vendor CRUD | Positive | Search vendors — by vendor_name | 3 |
| TC-VND-P14 | Vendor CRUD | Positive | Search vendors — by contact_person | 3 |
| TC-VND-P15 | Vendor CRUD | Positive | Search vendors — by contact_number | 3 |
| TC-VND-P16 | Vendor CRUD | Positive | Search vendors — by email | 3 |
| TC-VND-P17 | Vendor CRUD | Positive | Filter vendors — by status (active/inactive) | 3 |
| TC-VND-P18 | Vendor CRUD | Positive | Agreements tab loads with search and filter | 5 |
| TC-VND-P19 | Vendor CRUD | Positive | Items tab loads with search and filter | 5 |
| TC-VND-P20 | Vendor CRUD | Positive | Invoices tab — data type "Inv. Need To Generate" with date range | 4 |
| TC-VND-P21 | Vendor CRUD | Positive | Invoices tab — data type "Invoicing Done" with date range | 4 |
| TC-VND-P22 | Vendor CRUD | Positive | Payments tab loads with vendor_id, date range, status filters | 5 |
| TC-VND-P23 | Vendor CRUD | Positive | Usage logs tab loads with vendor_id and date filters | 4 |
| TC-VND-P24 | Vendor CRUD | Positive | PII fields — panMasked and bankAccountMasked accessors return masked values | 3 |
| TC-VND-P25 | Vendor CRUD | Positive | Activity log created on vendor store | 3 |
| TC-VND-P26 | Vendor CRUD | Positive | Activity log created on vendor update | 3 |
| TC-VND-P27 | Vendor CRUD | Positive | Activity log created on vendor soft-delete | 3 |
| TC-VND-P28 | Vendor CRUD | Positive | Activity log created on vendor restore | 3 |
| TC-VND-P29 | Vendor CRUD | Positive | Activity log created on vendor force-delete | 3 |
| TC-VND-P30 | Vendor CRUD | Positive | Activity log created on vendor toggle-status | 3 |
| TC-VND-P31 | Vendor CRUD | Positive | PII SafeEncrypted — fields encrypted at rest in DB (raw query) | 2 |
| TC-VND-P32 | Vendor CRUD | Positive | PII SafeEncrypted — fields decrypted on Eloquent access | 3 |
| TC-VND-P33 | Vendor CRUD | Positive | Masked accessor — panMasked format and null handling | 4 |
| TC-VND-P34 | Vendor CRUD | Positive | Masked accessor — bankAccountMasked handles standard and short strings | 4 |
| TC-VND-P35 | Vendor CRUD | Positive | hasManyThrough — payments accessible via Vendor model | 3 |
| TC-VND-P36 | Vendor CRUD | Positive | Spatie Media Library — add document to vendor_documents collection | 3 |
| TC-VND-P37 | Vendor CRUD | Positive | Spatie Media Library — singleFile replaces old document on re-upload | 3 |
| TC-VND-P38 | Vendor CRUD | Positive | Spatie Media Library — media conversions generate small and medium thumbnails | 3 |
| TC-VND-P39 | Vendor CRUD | Positive | Scope active() — filters is_active = true only | 3 |

### 9.2 Vendor CRUD — Negative TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-VND-N01 | Vendor CRUD | Negative | Create — missing vendor_name | 2 |
| TC-VND-N02 | Vendor CRUD | Negative | Create — vendor_name exceeds 100 chars | 2 |
| TC-VND-N03 | Vendor CRUD | Negative | Create — missing vendor_type_id | 2 |
| TC-VND-N04 | Vendor CRUD | Negative | Create — missing contact_person | 2 |
| TC-VND-N05 | Vendor CRUD | Negative | Create — contact_person exceeds 100 chars | 2 |
| TC-VND-N06 | Vendor CRUD | Negative | Create — missing contact_number | 2 |
| TC-VND-N07 | Vendor CRUD | Negative | Create — contact_number exceeds 20 chars | 2 |
| TC-VND-N08 | Vendor CRUD | Negative | Create — invalid email format | 2 |
| TC-VND-N09 | Vendor CRUD | Negative | Create — email exceeds 100 chars | 2 |
| TC-VND-N10 | Vendor CRUD | Negative | Create — missing address | 2 |
| TC-VND-N11 | Vendor CRUD | Negative | Create — address exceeds 500 chars | 2 |
| TC-VND-N12 | Vendor CRUD | Negative | Create — GST number exceeds 20 chars | 2 |
| TC-VND-N13 | Vendor CRUD | Negative | Create — PAN number exceeds 20 chars | 2 |
| TC-VND-N14 | Vendor CRUD | Negative | Create — bank_account_no exceeds 30 chars | 2 |
| TC-VND-N15 | Vendor CRUD | Negative | Create — bank_ifsc_code exceeds 20 chars | 2 |
| TC-VND-N16 | Vendor CRUD | Negative | Create — UPI ID exceeds 100 chars | 2 |
| TC-VND-N17 | Vendor CRUD | Negative | Create — is_active missing (checkbox not checked) — expect false/default | 2 |
| TC-VND-N18 | Vendor CRUD | Negative | Create — duplicate vendor_name (existing active) | 2 |
| TC-VND-N19 | Vendor CRUD | Negative | Update — duplicate vendor_name (existing different vendor) | 3 |
| TC-VND-N20 | Vendor CRUD | Negative | Update — vendor_name changed to soft-deleted vendor's name | 3 |
| TC-VND-N21 | Vendor CRUD | Negative | Toggle status — missing is_active parameter | 2 |
| TC-VND-N22 | Vendor CRUD | Negative | Toggle status — non-boolean is_active value | 2 |
| TC-VND-N23 | Vendor CRUD | Negative | Toggle status — non-existent vendor ID | 2 |
| TC-VND-N24 | Vendor CRUD | Negative | Force delete — non-existent vendor ID | 2 |
| TC-VND-N25 | Vendor CRUD | Negative | Restore — non-existent vendor ID | 2 |
| TC-VND-N26 | Vendor CRUD | Negative | Permission — index without any tenant.vendor.* permission | 2 |
| TC-VND-N27 | Vendor CRUD | Negative | Permission — create without tenant.vendor.create | 2 |
| TC-VND-N28 | Vendor CRUD | Negative | Permission — store without tenant.vendor.create | 2 |
| TC-VND-N29 | Vendor CRUD | Negative | Permission — edit without tenant.vendor.update | 2 |
| TC-VND-N30 | Vendor CRUD | Negative | Permission — update without tenant.vendor.update | 2 |
| TC-VND-N31 | Vendor CRUD | Negative | Permission — view show without tenant.vendor.view | 2 |
| TC-VND-N32 | Vendor CRUD | Negative | Permission — destroy without tenant.vendor.delete | 2 |
| TC-VND-N33 | Vendor CRUD | Negative | Permission — trashed without tenant.vendor.restore | 2 |
| TC-VND-N34 | Vendor CRUD | Negative | Permission — restore without tenant.vendor.restore | 2 |
| TC-VND-N35 | Vendor CRUD | Negative | Permission — forceDelete without tenant.vendor.forceDelete | 2 |
| TC-VND-N36 | Vendor CRUD | Negative | Permission — toggleStatus without tenant.vendor.update | 2 |
| TC-VND-N37 | Vendor CRUD | Negative | Edit — email field accepts whitespace-only string (null check gap) | 2 |

### 9.3 Code Review TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-CR01 | Code Review | Review | index() — Gate::any() with 7 permissions + tab routing | 4 |
| TC-CR02 | Code Review | Review | vendorsQuery() — search and filter logic | 4 |
| TC-CR03 | Code Review | Review | vendorInvoiceQuery() — mandatory filter enforcement | 4 |
| TC-CR04 | Code Review | Review | store() — Gate + create + activityLog + flash | 5 |
| TC-CR05 | Code Review | Review | update() — change tracking logic with getOriginal/getChanges | 5 |
| TC-CR06 | Code Review | Review | destroy() — manual is_active=false before delete (redundant) | 4 |
| TC-CR07 | Code Review | Review | restore() — onlyTrashed()->findOrFail + restore + save | 4 |
| TC-CR08 | Code Review | Review | forceDelete() — withTrashed()->findOrFail + forceDelete | 3 |
| TC-CR09 | Code Review | Review | toggleStatus() — Gate + validation + AJAX JSON response | 5 |
| TC-CR10 | Code Review | Review | VendorRequest — all field rules and unique ignore logic | 5 |
| TC-CR11 | Code Review | Review | VendorRequest — authorize() returns true (no Gate) | 2 |
| TC-CR12 | Code Review | Review | VendorRequest — prepareForValidation is_active boolean cast | 3 |
| TC-CR13 | Code Review | Review | VendorPolicy — all 7 method signatures | 4 |
| TC-CR14 | Code Review | Review | VendorPolicy — status() reuses view permission | 2 |
| TC-CR15 | Code Review | Review | Vendor Model — fillable, casts, accessors, scopes | 5 |
| TC-CR16 | Code Review | Review | Vendor Model — relationships (vendorType, invoices, agreements, payments) | 4 |
| TC-CR17 | Code Review | Review | Vendor Model — Spatie Media Collections (vendor_documents) | 3 |
| TC-CR18 | Code Review | Review | Flash messages — all 6 controller operations | 6 |

### 9.4 Dependency TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-D01 | Dependency | Dependency | Vendor type FK → sys_dropdown_table — RESTRICT on delete | 3 |
| TC-D02 | Dependency | Dependency | SoftDelete — deleted vendors excluded from unique vendor_name validation | 3 |
| TC-D03 | Dependency | Dependency | PII SafeEncrypted — pan_number, bank_account_no, bank_ifsc_code encrypted at rest | 3 |
| TC-D04 | Dependency | Dependency | Spatie Media Library — vendor_documents collection single-file | 3 |
| TC-D05 | Dependency | Dependency | Invoice tab requires agreement_item + agreement + invoice relations | 4 |
| TC-D06 | Dependency | Dependency | Index tab view — all 6 query methods return paginated data | 4 |
| TC-D07 | Cross-Module Dependency | Dependency | Transport Vehicle FK CASCADE — deleting vendor cascades to tpt_vehicle records | 4 |
| TC-D08 | Cross-Module Dependency | Dependency | Invoice FK RESTRICT — cannot force-delete vendor with invoices | 3 |
| TC-D09 | Cross-Module Dependency | Dependency | Payment FK RESTRICT — cannot force-delete vendor with payments | 3 |
| TC-D10 | Cross-Module Dependency | Dependency | Library Book Purchase FK RESTRICT — cannot force-delete vendor with lib_book_purchases | 3 |
| TC-D11 | Cross-Module Dependency | Dependency | Complaint Dept SLA FK SET NULL — deleting vendor nullifies target_vendor_id in cmp_department_sla | 4 |

---

## 10. Test Case Steps

### 10.1 Positive TC Steps — Vendor CRUD

#### TC-VND-P01: Vendor tab list loads with search and filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with any one of 7 vendor permissions navigates to `/vendor` | Dashboard tab view loads |
| 2 | Verify Vendor tab is active by default | Vendor tab selected |
| 3 | Verify search input and status filter dropdown are present | Filters visible |
| 4 | Verify paginated vendor list with columns: vendor_name, vendor_type, contact_person, contact_number, email, is_active toggle, Actions | All columns present |
| 5 | Verify pagination links (10 per page) | Paginated |

#### TC-VND-P02: Create vendor — all required fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.vendor.create` permission clicks "Add Vendor" | Create form loads |
| 2 | Enter vendor_name="Test Vendor", select vendor_type_id (valid), enter contact_person="John Doe", contact_number="9876543210", address="123 Test St" | Fields populated |
| 3 | Leave email, gst_number, pan_number, bank fields blank | Optional fields empty |
| 4 | Set is_active=true (checkbox checked) | Active |
| 5 | Click Submit | Redirected to vendor index |
| 6 | Verify success flash message appears and new vendor appears in vendor list | Vendor created |

#### TC-VND-P03: Create vendor — all optional fields (GST, PAN, Bank, UPI)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Fill all required fields: vendor_name="Full Data Vendor", vendor_type_id=valid, contact_person="Jane Doe", contact_number="9876543210", address="456 Main St" | Required fields set |
| 3 | Fill optional fields: email="vendor@example.com", gst_number="27AAAPL1234C1Z5", pan_number="ABCDE1234F", bank_name="SBI", bank_account_no="12345678901", bank_ifsc_code="SBIN0001234", bank_branch="Main Branch", upi_id="vendor@upi" | All optional fields populated |
| 4 | Submit form | Success |
| 5 | Verify DB record has all 14 fillable fields populated | DB verified |
| 6 | Verify pan_number and bank_account_no are encrypted in DB (raw value not plaintext) | PII encrypted |

#### TC-VND-P04: Create vendor — unique vendor_name enforced

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create first vendor with vendor_name="UniqueVendor" | Created successfully |
| 2 | Create second vendor with same vendor_name="UniqueVendor" | Validation error: "The vendor name has already been taken." |

#### TC-VND-P05: View vendor detail

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.vendor.view` permission clicks "View" on a vendor row | Show page loads |
| 2 | Verify all vendor fields are displayed: name, type, contact, address, tax details, bank details | All fields visible |
| 3 | Verify masked PAN (first 5 + XXXX + last 1) and masked bank account (all X except last 4) | Accessors applied |

#### TC-VND-P06: Edit vendor — update vendor_name, contact info

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.vendor.update` permission clicks "Edit" on a vendor | Edit form loads with pre-filled data |
| 2 | Change vendor_name to "Updated Vendor", contact_person to "Jane Updated" | Fields changed |
| 3 | Click Update | Redirected to vendor index |
| 4 | Verify success flash message appears | Success message |
| 5 | Verify vendor list shows updated vendor_name and contact_person | Changes reflected |

#### TC-VND-P07: Edit vendor — change tracking logs old/new values

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor has contact_number="1111111111" | Existing value |
| 2 | Edit vendor and change contact_number to "2222222222" | Field changed |
| 3 | Submit update | Success |
| 4 | Verify activity log entry contains old="1111111111" and new="2222222222" for contact_number | Change tracked |

#### TC-VND-P08: Toggle status — active to inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate an active vendor (is_active=true) in the list | Active vendor visible |
| 2 | Click status toggle to deactivate | AJAX call made |
| 3 | Verify JSON response: `{"success": true, "is_active": false, "message": "..."}` | AJAX success |
| 4 | Verify DB: is_active = 0 for the vendor and activity log entry created | Deactivated |

#### TC-VND-P09: Toggle status — inactive to active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate an inactive vendor (is_active=false) in the list | Inactive vendor visible |
| 2 | Click status toggle to activate | AJAX call made |
| 3 | Verify JSON response: `{"success": true, "is_active": true, "message": "..."}` | AJAX success |
| 4 | Verify DB: is_active = 1 for the vendor and activity log entry created | Activated |

#### TC-VND-P10: Soft-delete vendor

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.vendor.delete` permission clicks "Delete" on an active vendor | Confirmation prompt |
| 2 | Confirm deletion | Vendor soft-deleted |
| 3 | Verify vendor no longer appears in active vendor list | Removed from active |
| 4 | Verify DB: deleted_at is not null AND is_active = 0 | Soft-deleted |

#### TC-VND-P11: Restore vendor from trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.vendor.restore` permission navigates to `/vendor/trash/view` | Trash list loads |
| 2 | Locate a soft-deleted vendor | Vendor visible in trash |
| 3 | Click Restore | Vendor restored |
| 4 | Verify vendor appears in active list, deleted_at is NULL, and activity log entry created | Restored |

#### TC-VND-P12: Force-delete vendor

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.vendor.forceDelete` permission navigates to trash view | Trash list loads |
| 2 | Locate a soft-deleted vendor and click "Force Delete" | Confirmation prompt |
| 3 | Confirm permanent deletion | Vendor permanently deleted |
| 4 | Verify DB record no longer exists (including withTrashed) and activity log entry created | Permanently deleted |

#### TC-VND-P13: Search vendors — by vendor_name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | In Vendor tab, enter search term matching part of a vendor_name | Filter applied |
| 2 | Verify result list contains only vendors with matching vendor_name | Filtered results |
| 3 | Verify search is case-insensitive and uses LIKE %term% | Wildcard search |

#### TC-VND-P14: Search vendors — by contact_person

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | In Vendor tab, enter search term matching a contact_person | Filter applied |
| 2 | Verify result list contains vendors with matching contact_person | Filtered results |
| 3 | Verify search is case-insensitive LIKE %term% | Wildcard search |

#### TC-VND-P15: Search vendors — by contact_number

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | In Vendor tab, enter partial contact_number | Filter applied |
| 2 | Verify result list contains vendors with matching contact_number | Filtered results |
| 3 | Verify partial match works (e.g. "9876" matches "9876543210") | Wildcard search |

#### TC-VND-P16: Search vendors — by email

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | In Vendor tab, enter partial email address | Filter applied |
| 2 | Verify result list contains vendors with matching email | Filtered results |
| 3 | Verify search is case-insensitive LIKE %term% | Wildcard search |

#### TC-VND-P17: Filter vendors — by status (active/inactive)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | In Vendor tab, set status filter to "Active" (1) | Filter applied |
| 2 | Verify only active vendors (is_active=1) are shown | Active-only list |
| 3 | Set status filter to "Inactive" (0) and verify only inactive vendors shown | Inactive-only list |

#### TC-VND-P18: Agreements tab loads with search and filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | In Vendor dashboard, click "Agreements" tab | Tab switches to vendor_agreement |
| 2 | Verify search input and status filter visible | Filters present |
| 3 | Enter search term matching a vendor_name or agreement_ref_no | Filtered results |
| 4 | Set status = Active | Filtered to active agreements |
| 5 | Verify paginated list (10 per page) with agreement data | Agreements loaded |

#### TC-VND-P19: Items tab loads with search and filter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | In Vendor dashboard, click "Items" tab | Tab switches to vendor_item |
| 2 | Verify search input and status filter visible | Filters present |
| 3 | Enter search term matching item_name, item_code, or hsn_sac_code | Filtered results |
| 4 | Set status = Inactive | Filtered to inactive items |
| 5 | Verify paginated list (10 per page) | Items loaded |

#### TC-VND-P20: Invoices tab — data type "Inv. Need To Generate" with date range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | In Vendor dashboard, click "Invoices" tab | Tab switches to vendor_invoice |
| 2 | Set data_type = "Inv. Need To Generate", select a date range, select a vendor_id | Filters set |
| 3 | Verify list shows agreement items without invoices within the date range | Filtered results |
| 4 | Verify paginated list with agreement.vendor, item information | Data loaded |

#### TC-VND-P21: Invoices tab — data type "Invoicing Done" with date range

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | In Vendor dashboard, click "Invoices" tab | Tab switches |
| 2 | Set data_type = "Invoicing Done", select a date range, select a vendor_id | Filters set |
| 3 | Verify list shows agreement items that HAVE invoices within the date range | Filtered results |
| 4 | Verify paginated list with invoice data | Data loaded |

#### TC-VND-P22: Payments tab loads with vendor_id, date range, status filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | In Vendor dashboard, click "Payments" tab | Tab switches to payment_details |
| 2 | Select a vendor_id from dropdown | Vendor filter applied |
| 3 | Select a date range | Date range applied |
| 4 | Select a payment status | Status filter applied |
| 5 | Verify paginated list (10 per page) with vendor and invoice relations | Payments loaded |

#### TC-VND-P23: Usage logs tab loads with vendor_id and date filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | In Vendor dashboard, click "Usage Logs" tab | Tab switches to vendor_usage_log |
| 2 | Select a vendor_id from dropdown | Vendor filter applied |
| 3 | Select a usage date | Date filter applied |
| 4 | Verify paginated list (10 per page) with vendor and agreementItem relations | Usage logs loaded |

#### TC-VND-P24: PII fields — panMasked and bankAccountMasked accessors return masked values

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor record has pan_number = "ABCDE1234F" | PAN stored |
| 2 | Access `$vendor->panMasked` | Returns "ABCDEXXXXF" |
| 3 | Vendor has bank_account_no = "1234567890" | Account stored |
| 4 | Access `$vendor->bankAccountMasked` | Returns "XXXXXX7890" |

#### TC-VND-P25: Activity log created on vendor store

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a new vendor via store() | Success |
| 2 | Verify `activityLog()` was called with the Vendor model, action='Stored', and message='A new vendor was created.' | Logged |
| 3 | Verify performed_by = authenticated user's name | Performer tracked |

#### TC-VND-P26: Activity log created on vendor update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Update a vendor via update() | Success |
| 2 | Verify `activityLog()` called with action='Updated' and changes array | Logged |
| 3 | Verify changes contains old/new values for modified fields | Change tracking |

#### TC-VND-P27: Activity log created on vendor soft-delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a vendor via destroy() | Success |
| 2 | Verify `activityLog()` called with action='Trashed' and message='Vendor was deactivated and trashed.' | Logged |

#### TC-VND-P28: Activity log created on vendor restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Restore a trashed vendor via restore() | Success |
| 2 | Verify `activityLog()` called with action='Restored' and message='Vendor was restored.' | Logged |

#### TC-VND-P29: Activity log created on vendor force-delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Force-delete a trashed vendor via forceDelete() | Success |
| 2 | Verify `activityLog()` called with action='Deleted' and message='Vendor was permanently deleted.' | Logged |

#### TC-VND-P30: Activity log created on vendor toggle-status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Toggle vendor status via toggleStatus() | AJAX success |
| 2 | Verify `activityLog()` called with action='Toggled' and message='Vendor status was updated.' | Logged |
| 3 | Verify performed_by = authenticated user's name | Performer tracked |

#### TC-VND-P31: PII SafeEncrypted — fields encrypted at rest in DB (raw query)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create vendor with pan_number="ABCDE1234F", bank_account_no="1234567890", bank_ifsc_code="SBIN0001234" | Vendor created successfully |
| 2 | Query raw DB: SELECT pan_number, bank_account_no, bank_ifsc_code FROM vnd_vendors WHERE id = X | All three values show encrypted ciphertext (not plaintext values) |

#### TC-VND-P32: PII SafeEncrypted — fields decrypted on Eloquent access

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Use vendor from TC-VND-P31 (or create new with same values) | Vendor exists |
| 2 | Access `$vendor->pan_number` | Returns plaintext "ABCDE1234F" (decrypted) |
| 3 | Access `$vendor->bank_account_no` | Returns plaintext "1234567890" (decrypted) |
| 4 | Access `$vendor->bank_ifsc_code` | Returns plaintext "SBIN0001234" (decrypted) |

#### TC-VND-P33: Masked accessor — panMasked format and null handling

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor has pan_number = "ABCDE1234F" | PAN stored |
| 2 | Access `$vendor->panMasked` | Returns "ABCDEXXXXF" (first 5 chars + XXXX + last 1 char) |
| 3 | Vendor has pan_number = NULL | No PAN stored |
| 4 | Access `$vendor->panMasked` | Returns NULL |

#### TC-VND-P34: Masked accessor — bankAccountMasked handles standard and short strings

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor has bank_account_no = "1234567890" (10 chars) | Account stored |
| 2 | Access `$vendor->bankAccountMasked` | Returns "XXXXXX7890" (all X except last 4 visible) |
| 3 | Vendor has bank_account_no = "AB" (2 chars, length ≤ 4) | Short account stored |
| 4 | Access `$vendor->bankAccountMasked` | Returns "XX" (all X — no characters revealed for short strings) |

#### TC-VND-P35: hasManyThrough — payments accessible via Vendor model

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create vendor, create invoice for vendor (VndInvoice with vendor_id), create payment for invoice (VndPayment with invoice_id) | Related records exist |
| 2 | Access `$vendor->payments` | Returns Collection of VndPayment records |
| 3 | Verify the payment is linked through the invoice (hasManyThrough via VndInvoice) | Relationship chain works correctly |

#### TC-VND-P36: Spatie Media Library — add document to vendor_documents collection

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Upload a file to vendor via `$vendor->addMedia(file)->toMediaCollection('vendor_documents')` | File uploaded successfully |
| 2 | Access `$vendor->getMedia('vendor_documents')` | Returns a collection with 1 media record |
| 3 | Verify the media record is associated with the Vendor model via morphs relationship | Media attached to correct model |

#### TC-VND-P37: Spatie Media Library — singleFile replaces old document on re-upload

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Upload first document (doc1.pdf) to vendor_documents collection | First file stored |
| 2 | Upload second document (doc2.pdf) to same vendor same collection | Second file uploaded, first file automatically removed |
| 3 | Access `$vendor->getMedia('vendor_documents')` | Only 1 media record returned (doc2.pdf — the new file) |

#### TC-VND-P38: Spatie Media Library — media conversions generate small and medium thumbnails

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Upload an image file to vendor_documents collection | Image uploaded |
| 2 | Access `$media->getUrl('small')` | Returns URL for 150x150 thumbnail |
| 3 | Access `$media->getUrl('medium')` | Returns URL for 400x400 thumbnail |

#### TC-VND-P39: Scope active() — filters is_active = true only

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active vendor (is_active=true) and inactive vendor (is_active=false) | Both vendors exist in DB |
| 2 | Execute `Vendor::active()->get()` | Returns collection containing only the active vendor |
| 3 | Verify the inactive vendor is excluded from the result set | Scope filters correctly |

### 10.2 Negative TC Steps — Vendor CRUD

#### TC-VND-N01: Create — missing vendor_name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form without vendor_name | Validation error |
| 2 | Verify error: "The vendor name field is required." | Error shown |

#### TC-VND-N02: Create — vendor_name exceeds 100 chars

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set vendor_name to a 101-character string | Exceeds max |
| 2 | Submit | Validation error: "The vendor name must not be greater than 100 characters." |

#### TC-VND-N03: Create — missing vendor_type_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form without vendor_type_id | Validation error |
| 2 | Verify error: "The vendor type id field is required." | Error shown |

#### TC-VND-N04: Create — missing contact_person

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form without contact_person | Validation error |
| 2 | Verify error: "The contact person field is required." | Error shown |

#### TC-VND-N05: Create — contact_person exceeds 100 chars

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set contact_person to a 101-character string | Exceeds max |
| 2 | Submit | Validation error |

#### TC-VND-N06: Create — missing contact_number

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form without contact_number | Validation error |
| 2 | Verify error: "The contact number field is required." | Error shown |

#### TC-VND-N07: Create — contact_number exceeds 20 chars

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set contact_number to a 21-character string | Exceeds max |
| 2 | Submit | Validation error |

#### TC-VND-N08: Create — invalid email format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter email = "not-an-email" | Invalid format |
| 2 | Submit | Validation error: "The email must be a valid email address." |

#### TC-VND-N09: Create — email exceeds 100 chars

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set email to a 101-character string | Exceeds max |
| 2 | Submit | Validation error |

#### TC-VND-N10: Create — missing address

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form without address | Validation error |
| 2 | Verify error: "The address field is required." | Error shown |

#### TC-VND-N11: Create — address exceeds 500 chars

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set address to a 501-character string | Exceeds max |
| 2 | Submit | Validation error |

#### TC-VND-N12: Create — GST number exceeds 20 chars

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set gst_number to a 21-character string | Exceeds max |
| 2 | Submit | Validation error |

#### TC-VND-N13: Create — PAN number exceeds 20 chars

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set pan_number to a 21-character string | Exceeds max |
| 2 | Submit | Validation error |

#### TC-VND-N14: Create — bank_account_no exceeds 30 chars

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set bank_account_no to a 31-character string | Exceeds max |
| 2 | Submit | Validation error |

#### TC-VND-N15: Create — bank_ifsc_code exceeds 20 chars

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set bank_ifsc_code to a 21-character string | Exceeds max |
| 2 | Submit | Validation error |

#### TC-VND-N16: Create — UPI ID exceeds 100 chars

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set upi_id to a 101-character string | Exceeds max |
| 2 | Submit | Validation error |

#### TC-VND-N17: Create — is_active missing (checkbox not checked)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form without checking is_active checkbox | Field not sent / false |
| 2 | Verify `prepareForValidation()` converts missing to boolean false and vendor is created with is_active=0 | Defaults to false |

#### TC-VND-N18: Create — duplicate vendor_name (existing active)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor "ABC Corp" already exists (active) | Existing record |
| 2 | Submit create with vendor_name="ABC Corp" | Validation error: "The vendor name has already been taken." |

#### TC-VND-N19: Update — duplicate vendor_name (existing different vendor)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor A has name="VendorA", Vendor B has name="VendorB" | Two vendors exist |
| 2 | Edit Vendor B and change name to "VendorA" | Duplicate attempt |
| 3 | Submit | Validation error: "The vendor name has already been taken." |

#### TC-VND-N20: Update — vendor_name changed to soft-deleted vendor's name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor "DeletedVendor" is soft-deleted | Trashed vendor |
| 2 | Edit any active vendor and change name to "DeletedVendor" | Unique validation ignores soft-deleted records |
| 3 | Submit — should succeed because unique ignores whereNull deleted_at | Update successful |

#### TC-VND-N21: Toggle status — missing is_active parameter

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/vendor/{id}/toggle-status` without is_active in request body | Validation error |
| 2 | Verify error: "The is active field is required." | Error returned |

#### TC-VND-N22: Toggle status — non-boolean is_active value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/vendor/{id}/toggle-status` with is_active="not-a-boolean" | Validation error |
| 2 | Verify error: "The is active field must be true or false." | Error returned |

#### TC-VND-N23: Toggle status — non-existent vendor ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST `/vendor/99999/toggle-status` with is_active=true | Vendor 99999 doesn't exist |
| 2 | Verify 404 Not Found from findOrFail | 404 error |

#### TC-VND-N24: Force delete — non-existent vendor ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | DELETE `/vendor/99999/force-delete` | Vendor 99999 doesn't exist |
| 2 | Verify 404 Not Found from withTrashed()->findOrFail | 404 error |

#### TC-VND-N25: Restore — non-existent vendor ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | GET `/vendor/99999/restore` | Vendor 99999 doesn't exist |
| 2 | Verify 404 Not Found from onlyTrashed()->findOrFail | 404 error |

#### TC-VND-N26: Permission — index without any tenant.vendor.* permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without any of the 7 vendor-related permissions accesses `/vendor` | 403 Forbidden |
| 2 | Verify Gate::any() fails and abort(403) is triggered | Aborted |

#### TC-VND-N27: Permission — create without tenant.vendor.create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor.create` accesses `/vendor/create` | 403 Forbidden |

#### TC-VND-N28: Permission — store without tenant.vendor.create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor.create` POSTs to `/vendor` | 403 Forbidden |

#### TC-VND-N29: Permission — edit without tenant.vendor.update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor.update` accesses `/vendor/{id}/edit` | 403 Forbidden |

#### TC-VND-N30: Permission — update without tenant.vendor.update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor.update` PUTs to `/vendor/{id}` | 403 Forbidden |

#### TC-VND-N31: Permission — view show without tenant.vendor.view

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor.view` accesses `/vendor/{id}` | 403 Forbidden |

#### TC-VND-N32: Permission — destroy without tenant.vendor.delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor.delete` DELETEs `/vendor/{id}` | 403 Forbidden |

#### TC-VND-N33: Permission — trashed without tenant.vendor.restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor.restore` accesses `/vendor/trash/view` | 403 Forbidden |

#### TC-VND-N34: Permission — restore without tenant.vendor.restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor.restore` POSTs to `/vendor/{id}/restore` | 403 Forbidden |

#### TC-VND-N35: Permission — forceDelete without tenant.vendor.forceDelete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor.forceDelete` DELETEs `/vendor/{id}/force-delete` | 403 Forbidden |

#### TC-VND-N36: Permission — toggleStatus without tenant.vendor.update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.vendor.update` POSTs to `/vendor/{id}/toggle-status` | 403 Forbidden |

#### TC-VND-N37: Edit — email field accepts whitespace-only string (null check gap)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit vendor, set email = "   " (whitespace-only) | Passes nullable + string validation |
| 2 | Submit | May succeed (nullable only checks null/missing, not whitespace) |
| 3 | Verify DB storage — depending on implementation, may store whitespace string instead of NULL | Potential data quality issue |

### 10.3 Code Review TC Steps

#### TC-CR01: index() — Gate::any() with 7 permissions + tab routing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::any([...7 permissions...]) || abort(403)` at method start | Gate present |
| 2 | Review $filters extracted from $request->only(['data_type','date_range','status','type','vendor_id']) | Filters extracted |
| 3 | Review 6 private query methods called with paginate(10) each with distinct page name | 6 query methods |
| 4 | Review vendorsList = Vendor::get() passed for tab dropdown filters | Dropdown data |

#### TC-CR02: vendorsQuery() — search and filter logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review tab check: `$request->input('tab') === 'vendor'` | Tab-gated |
| 2 | Review search: where like %term% on vendor_name, contact_person, contact_number, email with nested OR | Search logic |
| 3 | Review status filter: `where('is_active', (bool) $request->status)` | Status filter |
| 4 | Review default return: `$query->latest()` | Default ordering |

#### TC-CR03: vendorInvoiceQuery() — mandatory filter enforcement

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review tab check: tab !== 'vendor_invoice' → return empty | Tab-gated |
| 2 | Review empty filter check: returns `whereRaw('1 = 0')` if no filters provided | Empty result without filters |
| 3 | Review data_type="Inv. Need To Generate" logic: doesNotHave invoices + date range | Pending invoices logic |
| 4 | Review data_type="Invoicing Done" logic: has invoices + date range | Completed invoices logic |

#### TC-CR04: store() — Gate + create + activityLog + flash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor.create')` | Gate present |
| 2 | Review `Vendor::create($request->validated())` | Creation via validated data |
| 3 | Review `activityLog($vendor, 'Stored', [...])` | Activity logged |
| 4 | Review `redirect()->route('vendor.vendor.index')->with('success', flash('created.vendor'))` | Flash success |
| 5 | Review no try-catch wrapper — exception bubbles up | Exception handling |

#### TC-CR05: update() — change tracking logic with getOriginal/getChanges

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor.update')` | Gate present |
| 2 | Review `$original = $vendor->getOriginal()` before update | Original captured |
| 3 | Review `$vendor->update($request->validated())` | Update via validated data |
| 4 | Review `$changes = $vendor->getChanges()` — iterates fields, excludes updated_at | Changes captured |
| 5 | Review activityLog with changes array including old/new values | Change tracking logged |

#### TC-CR06: destroy() — manual is_active=false before delete (redundant)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor.delete')` | Gate present |
| 2 | Review `$vendor->is_active = false; $vendor->save();` before delete | Manual deactivation |
| 3 | Review `$vendor->delete()` — triggers SoftDeletes | Soft delete |
| 4 | Review activityLog with action='Trashed' and flash message | Activity + flash |

#### TC-CR07: restore() — onlyTrashed()->findOrFail + restore + save

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor.restore')` | Gate present |
| 2 | Review `Vendor::onlyTrashed()->findOrFail($id)` | Scoped to trashed only |
| 3 | Review `$vendor->restore(); $vendor->save();` | Restore then save |
| 4 | Review activityLog and flash redirect | Activity + flash |

#### TC-CR08: forceDelete() — withTrashed()->findOrFail + forceDelete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor.forceDelete')` | Gate present |
| 2 | Review `Vendor::withTrashed()->findOrFail($id)` | Bypasses soft-delete scope |
| 3 | Review `$vendor->forceDelete()` and activityLog | Permanent delete + log |

#### TC-CR09: toggleStatus() — Gate + validation + AJAX JSON response

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.vendor.update')` — uses update permission, not dedicated status permission (Known Issue) | Gate uses update |
| 2 | Review inline validation: `$request->validate(['is_active' => 'required|boolean'])` | Validation |
| 3 | Review `Vendor::findOrFail($id)` | Model binding |
| 4 | Review activityLog call before save | Activity before save |
| 5 | Review JSON success/error response based on `$vendor->save()` | AJAX JSON response |

#### TC-CR10: VendorRequest — all field rules and unique ignore logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review vendor_name: required|string|max:100|unique with ignore $vendorId and whereNull deleted_at | Unique logic |
| 2 | Review vendor_type_id: required|integer (no exists validation — potential gap) | FK validation |
| 3 | Review contact_number: required|string|max:20 (no specific format validation) | Format gap |
| 4 | Review nullable fields: gst_number, pan_number, bank fields, upi_id — all string|max | Nullable fields |
| 5 | Review is_active: required|boolean with prepareForValidation boolean cast | Boolean handling |

#### TC-CR11: VendorRequest — authorize() returns true (no Gate)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `authorize()` method | Returns `true` |
| 2 | Note: No Gate check in FormRequest — relies entirely on controller Gate | Defence-in-depth gap |

#### TC-CR12: VendorRequest — prepareForValidation is_active boolean cast

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `prepareForValidation()` method | Merges is_active |
| 2 | Review `$this->boolean('is_active')` conversion | Checkbox to boolean |
| 3 | Note: This runs before validation so is_active is always boolean when validated | Pre-processing |

#### TC-CR13: VendorPolicy — all 7 method signatures

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review viewAny(User) | Returns $user->can('tenant.vendor.viewAny') |
| 2 | Review view(User, Vendor) | Returns $user->can('tenant.vendor.view') |
| 3 | Review create(User) | Returns $user->can('tenant.vendor.create') |
| 4 | Review update(User, Vendor) | Returns $user->can('tenant.vendor.update') |

#### TC-CR14: VendorPolicy — status() reuses view permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `status(User, Vendor)` method | Returns `$user->can('tenant.vendor.view')` |
| 2 | Note: No dedicated `tenant.vendor.status` permission exists — status toggle uses view permission | Permission reuse |

#### TC-CR15: Vendor Model — fillable, casts, accessors, scopes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$fillable` array — 14 fields | All fillable fields |
| 2 | Review `$casts` — is_active→boolean, pan_number/bank_account_no/bank_ifsc_code→SafeEncrypted | Casts configured |
| 3 | Review `getPanMaskedAttribute()` — first 5 + XXXX + last 1 | PAN masking |
| 4 | Review `getBankAccountMaskedAttribute()` — all X except last 4 chars | Bank account masking |
| 5 | Review `scopeActive()` — where is_active = true | Active scope |

#### TC-CR16: Vendor Model — relationships (vendorType, invoices, agreements, payments)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `vendorType()` — belongsTo Dropdown::class | FK relationship |
| 2 | Review `invoices()` — hasMany VndInvoice | Has many invoices |
| 3 | Review `agreements()` — hasMany VndAgreement | Has many agreements |
| 4 | Review `payments()` — hasManyThrough VndPayment via VndInvoice | Through relationship |

#### TC-CR17: Vendor Model — Spatie Media Collections (vendor_documents)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `registerMediaCollections()` — 'vendor_documents' collection, singleFile() | Collection defined |
| 2 | Review `registerMediaConversions()` — 'small' (150x150) and 'medium' (400x400) | Conversions defined |
| 3 | Review `InteractsWithMedia` trait is used via `HasMedia` interface | Trait present |

#### TC-CR18: Flash messages — all 6 controller operations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review store() flash: `flash('created.vendor')` | Create flash |
| 2 | Review update() flash: `flash('updated.vendor')` | Update flash |
| 3 | Review destroy() flash: `flash('trashed.vendor')` | Delete flash |
| 4 | Review restore() flash: `flash('restored.vendor')` | Restore flash |
| 5 | Review forceDelete() flash: `flash('force_deleted.vendor')` | Force delete flash |
| 6 | Review toggleStatus() flash: `flash('status_updated.vendor')` on success, `flash('status_switch_failed.vendor')` on failure | Toggle flash messages |

### 10.4 Dependency TC Steps

#### TC-D01: Vendor type FK → sys_dropdown_table — RESTRICT on delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor type D1 has 2 associated vendors in vnd_vendors | Referenced dropdown |
| 2 | Attempt to delete D1 from sys_dropdown_table | RESTRICT violation |
| 3 | Verify DB error: Cannot delete or update a parent row — FK constraint fails | Delete blocked |

#### TC-D02: SoftDelete — deleted vendors excluded from unique vendor_name validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Vendor "TestCorp" is soft-deleted (deleted_at NOT NULL) | Trashed vendor |
| 2 | Create new vendor with vendor_name="TestCorp" | Unique validation ignores soft-deleted record |
| 3 | Verify vendor created successfully despite name matching soft-deleted record | Created |

#### TC-D03: PII SafeEncrypted — pan_number, bank_account_no, bank_ifsc_code encrypted at rest

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create vendor with pan_number="ABCDE1234F", bank_account_no="1234567890", bank_ifsc_code="SBIN0001234" | Vendor created |
| 2 | Query raw DB: SELECT pan_number, bank_account_no, bank_ifsc_code FROM vnd_vendors WHERE id = X | Values are encrypted (not plaintext) |
| 3 | Access via Eloquent model: $vendor->pan_number returns plaintext value | Decrypted on read |

#### TC-D04: Spatie Media Library — vendor_documents collection single-file

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Upload a document to vendor with collection='vendor_documents' | File uploaded |
| 2 | Upload a second document to same vendor same collection | First file replaced (singleFile()) |
| 3 | Access $vendor->getMedia('vendor_documents') | Only 1 media record |

#### TC-D05: Invoice tab requires agreement_item + agreement + invoice relations

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | VndAgreementItem record must exist with agreement_id linking to VndAgreement | Agreement item present |
| 2 | VndAgreement must have vendor_id linking to Vnd Vendor | Agreement has vendor |
| 3 | VndAgreementItem may have invoices (VndInvoice) via relationship | Invoice relation |
| 4 | vendorInvoiceQuery loads with('agreement.vendor', 'item', 'invoices') | Eager loading confirmed |

#### TC-D06: Index tab view — all 6 query methods return paginated data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Access vendor index with data in all related tables | Dashboard loads |
| 2 | Verify vendors (vendor tab) has paginate(10) | Vendors paginated |
| 3 | Verify vendorAgreements (agreements tab) has paginate(10) | Agreements paginated |
| 4 | Verify vendorItems, vendorinvoice, vendorPayments, vendorUsageLogs each have paginate(10) | All tabs paginated |

#### TC-D07: Transport Vehicle FK CASCADE — deleting vendor cascades to tpt_vehicle records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create vendor V1 in vnd_vendors | Vendor created |
| 2 | Create vehicle in tpt_vehicle with vendor_id = V1 | Vehicle linked to V1 |
| 3 | Force-delete vendor V1 via DELETE `/vendor/{id}/force-delete` | Force-delete succeeds |
| 4 | Query tpt_vehicle WHERE vendor_id = V1 | 0 records — vehicle cascaded-deleted |

#### TC-D08: Invoice FK RESTRICT — cannot force-delete vendor with invoices

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create vendor V1 with is_active = false, soft-delete it | Vendor in trash |
| 2 | Create invoice in vnd_invoices with vendor_id = V1 | Invoice linked |
| 3 | Attempt to force-delete vendor V1 via DELETE `/vendor/{id}/force-delete` | FK RESTRICT violation — DB error: cannot delete parent row |

#### TC-D09: Payment FK RESTRICT — cannot force-delete vendor with payments

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create vendor V1 with is_active = false, soft-delete it | Vendor in trash |
| 2 | Create payment in vnd_payments with vendor_id = V1 | Payment linked |
| 3 | Attempt to force-delete vendor V1 via DELETE `/vendor/{id}/force-delete` | FK RESTRICT violation — DB error: cannot delete parent row |

#### TC-D10: Library Book Purchase FK RESTRICT — cannot force-delete vendor with lib_book_purchases

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create vendor V1 with is_active = false, soft-delete it | Vendor in trash |
| 2 | Create lib_book_purchases record with vendor_id = V1 | Book purchase linked |
| 3 | Attempt to force-delete vendor V1 via DELETE `/vendor/{id}/force-delete` | FK RESTRICT violation — DB error: cannot delete parent row |

#### TC-D11: Complaint Dept SLA FK SET NULL — deleting vendor nullifies target_vendor_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create vendor V1 in vnd_vendors | Vendor created |
| 2 | Create cmp_department_sla record with target_vendor_id = V1 | SLA linked to V1 |
| 3 | Force-delete vendor V1 via DELETE `/vendor/{id}/force-delete` | Force-delete succeeds |
| 4 | Query cmp_department_sla WHERE id = SLA_ID | Record exists with target_vendor_id = NULL |

---

## 11. Route Reference

| Method | URL | Name | Controller Method | Required Permission |
|--------|-----|------|-------------------|---------------------|
| GET | `/vendor` | vendor.vendor.index | index() | Any of 7 vendor permissions |
| GET | `/vendor/create` | vendor.vendor.create | create() | tenant.vendor.create |
| POST | `/vendor` | vendor.vendor.store | store() | tenant.vendor.create |
| GET | `/vendor/{vendor}` | vendor.vendor.show | show() | tenant.vendor.view |
| GET | `/vendor/{vendor}/edit` | vendor.vendor.edit | edit() | tenant.vendor.update |
| PUT | `/vendor/{vendor}` | vendor.vendor.update | update() | tenant.vendor.update |
| DELETE | `/vendor/{vendor}` | vendor.vendor.destroy | destroy() | tenant.vendor.delete |
| GET | `/vendor/trash/view` | vendor.trashed | trashed() | tenant.vendor.restore |
| GET | `/vendor/{id}/restore` | vendor.restore | restore() | tenant.vendor.restore |
| DELETE | `/vendor/{id}/force-delete` | vendor.forceDelete | forceDelete() | tenant.vendor.forceDelete |
| POST | `/vendor/{id}/toggle-status` | vendor.toggleStatus | toggleStatus() | tenant.vendor.update |

---

## 12. Known Issues

| # | Issue | Severity | Details |
|---|-------|----------|---------|
| KI-01 | index() Gate uses Gate::any() with 7 permissions OR abort(403) | **Medium** | Comment in code notes this pattern is a workaround; any single permission grants full dashboard access |
| KI-02 | destroy() manually sets is_active=false before delete — redundant with SoftDeletes | **Low** | SoftDeletes already marks deleted_at; manual is_active=false is unnecessary |
| KI-03 | toggleStatus() uses tenant.vendor.update instead of a dedicated status permission | **Low** | No dedicated `tenant.vendor.status` permission exists; status toggle reuses update permission |
| KI-04 | No DB-level UNIQUE KEY on GSTIN or PAN | **Medium** | Uniqueness only at application level; no DB constraint preventing duplicate GST/PAN values |
| KI-05 | PII fields encrypted via SafeEncrypted cast but no migration for existing data backfill | **Medium** | Existing plaintext data remains unencrypted until explicitly re-saved |
| KI-06 | index() returns a unified tab view, not a dedicated vendor list page | **Info** | Single page handles 6 data types (vendors, agreements, items, invoices, payments, usage logs) |
| KI-07 | VendorRequest authorize() returns true | **Medium** | No Gate check in FormRequest — defence-in-depth collapsed; relies solely on controller Gate |
| KI-08 | vendor_type_id validation lacks `exists:sys_dropdown_table,id` rule | **Medium** | Foreign key is validated only as `required|integer`; no exists check for referential integrity |
| KI-09 | contact_number validation lacks format/pattern validation | **Low** | Only `required|string|max:20`; no mobile/phone format validation |
| KI-10 | vendorInvoiceQuery returns empty set when no filters provided | **Info** | Design decision — invoice tab shows no data until user applies filters |
| KI-11 | Cross-Module: Inventory tables (PO, Quotation, GRN, RateContract, ItemVendorJnt, AssetMaintenance) have vendor_id column but NO DB-level FK constraint | **High** | `inv_purchase_orders`, `inv_quotations`, `inv_goods_receipt_notes`, `inv_rate_contracts`, `inv_item_vendor_jnt`, `inv_asset_maintenance` — all reference `vnd_vendors.id` via indexed column only, no foreign() constraint. Deleting a vendor via raw DB leaves orphaned records. Application-level validation (exists rule in FormRequests) is the only guard. |
| KI-12 | Cross-Module: Accounting tables (acc_ledgers, acc_fixed_assets) have vendor_id column but NO DB-level FK constraint | **Medium** | Same gap as Inventory — no foreign() constraint, only an index and comment. Deleting a vendor via raw DB would orphan ledger and fixed asset records. |

---

## 13. Feature Summary Matrix

| Feature | Controller Method(s) | Key Models | Pagination |
|---------|---------------------|------------|------------|
| Vendor List (Tab) | index() + vendorsQuery() | Vendor | 10 per page |
| Create Vendor | create(), store() | Vendor | None (form) |
| View Vendor | show() | Vendor | None |
| Edit Vendor | edit(), update() | Vendor | None (form) |
| Soft-Delete / Restore | destroy(), trashed(), restore() | Vendor | 10 per page (trash) |
| Force Delete | forceDelete() | Vendor | None |
| Toggle Status | toggleStatus() | Vendor | None (AJAX) |
| Agreements Tab | index() + vendorAgreementsQuery() | VndAgreement | 10 per page |
| Items Tab | index() + vendorItemsQuery() | VndItem | 10 per page |
| Invoices Tab | index() + vendorInvoiceQuery() | VndAgreementItem, VndInvoice | 10 per page |
| Payments Tab | index() + vendorPaymentsQuery() | VndPayment | 10 per page |
| Usage Logs Tab | index() + vendorUsageLogsQuery() | VndUsageLog | 10 per page |
| **TC Count** | **Positive: 39 / Negative: 37 / Code Review: 18 / Dependency: 11** | **Total: 105** | |
