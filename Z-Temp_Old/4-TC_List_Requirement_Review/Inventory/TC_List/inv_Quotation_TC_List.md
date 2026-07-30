# inv_Quotation — Test Case List & Business Conditions

**Module:** Inventory (CODE `INV`, prefix `inv_`) · **Feature:** Quotations / RFQs (CRUD + Status Lifecycle + Items + Convert to PO)
**DB scope:** TENANT-side (`inv_quotations`, `inv_quotation_items`) · **Test style:** Browser Dusk
**Primary table:** `inv_quotations` (Layer 5) · **Module URL prefix:** `/inventory/procurement?tab=quotations`
**Test file:** `inv_Quotation_TestCas.php`
**Tab:** Quotations (second tab of Procurement page)

Controllers:
- `QuotationController` — CRUD + markAsReceived + convertToPo + trashed lifecycle
- `InvMenuController::procurement()` — loads quotations + dropdowns for all 4 tabs

Service:
- `QuotationService` — create, update, delete

Routes (`inventory.` prefix):
- `GET /inventory/procurement` — combined tab page
- `GET /inventory/quotations` — index (redirects to procurement tab)
- `POST /inventory/quotations` — store (with nested items array)
- `GET /inventory/quotations/{quotation}` — show
- `GET /inventory/quotations/{quotation}/edit` — edit
- `PUT /inventory/quotations/{quotation}` — update
- `DELETE /inventory/quotations/{quotation}` — soft delete (guarded if received)
- `PATCH /inventory/quotations/{quotation}/receive` — mark as received
- `POST /inventory/quotations/{quotation}/convert-to-po` — convert to PO
- `GET /inventory/quotations/trash/view` — trashed
- `GET /inventory/quotations/{id}/restore` — restore
- `DELETE /inventory/quotations/{id}/force-delete` — force delete

**DDL reference:** `inv_quotations` (Layer 5), `inv_quotation_items` (Layer 6)

---

## 1. Business Conditions

### BC-DB — Schema & Foreign Keys
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `inv_quotations`: id (BIGINT PK AI), rfq_number (VARCHAR 50 NOT NULL UNIQUE), pr_id (BIGINT UNSIGNED NULL), vendor_id (INT UNSIGNED NOT NULL), validity_date (DATE NULL), status (ENUM draft/sent/received/expired/converted DEFAULT draft), notes (TEXT NULL), is_active, created_by, updated_by, created_at, updated_at, deleted_at. Indexes: uq_inv_quot_rfq_number, idx_inv_quot_pr_id/vendor_id/status/is_active. FK: pr_id → inv_purchase_requisitions.id SET NULL, vendor_id FK commented out | DDL |
| BC-DB-02 | Table `inv_quotation_items`: id (BIGINT PK AI), quotation_id (BIGINT UNSIGNED NOT NULL), item_id (BIGINT UNSIGNED NOT NULL), quoted_rate (DECIMAL 15,2 NOT NULL), lead_time_days (INT NULL), remarks (VARCHAR 255 NULL), is_active, created_by, updated_by, created_at, updated_at, deleted_at. FKs: quotation_id → inv_quotations.id CASCADE, item_id → inv_stock_items.id | DDL |
| BC-DB-03 | Model `Quotation`: table inv_quotations, SoftDeletes, fillable 8 fields, casts: validity_date→date, is_active→boolean, status→string. Relations: vendor() BelongsTo (Vendor::class), purchaseRequisition() BelongsTo (PurchaseRequisition::class, 'pr_id'), items() HasMany (QuotationItem), createdBy() BelongsTo (User::class) | Model |
| BC-DB-04 | Model `QuotationItem`: table inv_quotation_items, SoftDeletes. Casts: quoted_rate→decimal:2, lead_time_days→integer. Relations: quotation() BelongsTo, stockItem() BelongsTo (StockItem::class) | Model |

### BC-VAL — Validation (StoreQuotationRequest)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `pr_id` required exists:inv_purchase_requisitions,id (filtered to approved PRs in view) | FR |
| BC-VAL-02 | `vendor_id` required exists:vnd_vendors,id | FR |
| BC-VAL-03 | `validity_date` nullable date | FR |
| BC-VAL-04 | `notes` nullable string max:2000 | FR |
| BC-VAL-05 | `items` required array min:1 | FR |
| BC-VAL-06 | `items.*.item_id` required integer exists:inv_stock_items,id | FR |
| BC-VAL-07 | `items.*.quoted_rate` required numeric min:0 | FR |
| BC-VAL-08 | `items.*.lead_time_days` nullable integer min:0 | FR |

### BC-AUTH — Authorization (QuotationPolicy)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | index/viewAny gate `tenant.inventory.quotation.viewAny` | Policy |
| BC-AUTH-02 | create/store gate `tenant.inventory.quotation.create` | Policy |
| BC-AUTH-03 | show gate `tenant.inventory.quotation.view` | Policy |
| BC-AUTH-04 | edit/update/markAsReceived gate `tenant.inventory.quotation.edit` | Policy |
| BC-AUTH-05 | destroy/trashed/restore/forceDelete gate `tenant.inventory.quotation.delete` | Policy |
| BC-AUTH-06 | convertToPo gate `tenant.inventory.purchase-order.create` (separate PO permission) | Policy |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Procurement page: Quotations is second tab | MenuCtrl |
| BC-BIZ-02 | Quotations tab: card list — rfq_number (linked), vendor name, PR reference (linked), validity date, status badge (draft/sent/received/expired/converted), items count, actions | View |
| BC-BIZ-03 | Create via modal: PR select (filtered to approved PRs only), Vendor select, Valid Until date, First Item section (item_id, quoted_rate required, lead_time_days) | View |
| BC-BIZ-04 | Store via QuotationService::create(): generates rfq_number via PurchaseOrderService::generateRfqNumber(), sets status=draft, creates nested items, redirects to show | Service |
| BC-BIZ-05 | Show page: RFQ header (number, vendor, PR reference, validity, status badge, notes) + Items table (item name, quoted rate, lead time) | View |
| BC-BIZ-06 | Edit: QuotationService::update() guards status=draft (DomainException if not draft). Updates header + replaces items (delete all + recreate) | Service |
| BC-BIZ-07 | Delete: QuotationService::delete() guards status=draft (DomainException if received). Only draft quotations can be deleted | Service |
| BC-BIZ-08 | Mark as Received (receive): sets status=received. Triggers conversion eligibility | Ctrl |
| BC-BIZ-09 | Convert to PO: creates PurchaseOrder from quotation data, links to PR + Quotation via pr_id + quotation_id | Ctrl |
| BC-BIZ-10 | Search: by rfq_number/vendor, filter by status (All/Draft/Sent/Received/Expired/Converted) | View |
| BC-BIZ-11 | Empty state: "No Quotations Found" with file-invoice icon | View |
| BC-BIZ-12 | Pagination: appends tab=quotations to pagination links | View |
| BC-BIZ-13 | Status lifecycle: draft → sent → received → converted. Or draft → expired | Service/Ctrl |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Edit received quotation → DomainException "Cannot modify received quotation" | Service |
| BC-EDG-02 | Delete received quotation → DomainException "Cannot delete received quotation" | Service |
| BC-EDG-03 | Convert to PO without `tenant.inventory.purchase-order.create` permission → 403 | Ctrl |
| BC-EDG-04 | Store with invalid pr_id → exists:inv_purchase_requisitions error | FR (cross-module) |
| BC-EDG-05 | Store with invalid vendor_id → exists:vnd_vendors error | FR (cross-module) |
| BC-EDG-06 | Zero quoted_rate → min:0 error | FR |
| BC-EDG-07 | Negative lead_time_days → min:0 error | FR |
| BC-EDG-08 | Duplicate rfq_number → unique DB constraint | DDL |
| BC-EDG-09 | Store with no items (empty array) → items required min:1 validation error | FR |

---

## 2. Test Case List

### Screen 1: Procurement Tab / Quotations List (GET /inventory/procurement?tab=quotations)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVQUOT-P10 | Positive | View | Quotations tab active via ?tab=quotations | Active | test_inv_quot_10 | Automated |
| TC-INVQUOT-P11 | Positive | View | Card list: rfq_number (link), vendor name, PR reference (linked), validity date formatted, status badge (draft/sent/received/expired/converted), items count, actions | Rendered | test_inv_quot_11 | Automated |
| TC-INVQUOT-P12 | Positive | View | Search by rfq_number/vendor, filter by status dropdown | Filters | test_inv_quot_12 | Automated |
| TC-INVQUOT-P13 | Positive | View | Create button opens modal with PR select (approved only), Vendor select, Valid Until, First Item section | Modal | test_inv_quot_13 | Automated |
| TC-INVQUOT-P14 | Positive | View | Empty state: "No Quotations Found" with file-invoice icon | Empty | test_inv_quot_14 | Automated |
| TC-INVQUOT-P15 | Positive | View | Pagination appends tab=quotations query param | Paginated | test_inv_quot_15 | Automated |

### Screen 2: Create (Modal) + Store

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVQUOT-P30 | Positive | View | Create modal: PR select (required, only approved PRs shown), Vendor select (required), Valid Until (optional), First Item section (item_id, quoted_rate required, lead_time_days optional) | Fields | test_inv_quot_30 | Automated |
| TC-INVQUOT-P31 | Positive | Ctrl | Valid store with 1 item: creates quotation with generated rfq_number, status=draft, items created, redirects to show | Created draft | test_inv_quot_31 | Automated |
| TC-INVQUOT-P32 | Positive | Ctrl | Store without PR (direct RFQ) — allowed since pr_id nullable | Created | test_inv_quot_32 | Automated |
| TC-INVQUOT-N33 | Negative | Val | Missing vendor_id → required error | Error | test_inv_quot_33 | Automated |
| TC-INVQUOT-N34 | Negative | Val | Invalid vendor_id → exists:vnd_vendors error | Error | test_inv_quot_34 | Automated |
| TC-INVQUOT-N35 | Negative | Val | Invalid pr_id → exists:inv_purchase_requisitions error | Error | test_inv_quot_35 | Automated |
| TC-INVQUOT-N36 | Negative | Val | No items (empty array) → items required min:1 error | Error | test_inv_quot_36 | Automated |
| TC-INVQUOT-N37 | Negative | Val | Invalid item_id → exists:inv_stock_items error | Error | test_inv_quot_37 | Automated |
| TC-INVQUOT-N38 | Negative | Val | Missing quoted_rate → required error | Error | test_inv_quot_38 | Automated |
| TC-INVQUOT-N39 | Negative | Val | Zero quoted_rate → min:0 error | Error | test_inv_quot_39 | Automated |
| TC-INVQUOT-N40 | Negative | Val | Negative lead_time_days → min:0 error | Error | test_inv_quot_40 | Automated |
| TC-INVQUOT-N41 | Negative | Val | Invalid validity_date → date error | Error | test_inv_quot_41 | Automated |

### Screen 3: Show (GET /inventory/quotations/{quotation})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVQUOT-P60 | Positive | View | Show: RFQ header — rfq_number, vendor name, PR reference (linked), validity date, status badge, notes | Layout | test_inv_quot_60 | Automated |
| TC-INVQUOT-P61 | Positive | View | Items table: Item Name/SKU, Quoted Rate (formatted ₹), Lead Time, remarks | Table | test_inv_quot_61 | Automated |
| TC-INVQUOT-P62 | Positive | View | Action buttons based on status: Edit/Delete (draft only), Mark Received (draft/sent), Convert to PO (received) | Conditional | test_inv_quot_62 | Automated |

### Screen 4: Edit + Update

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVQUOT-P80 | Positive | View | Edit page: form pre-populated with existing quotation data | Pre-filled | test_inv_quot_80 | Automated |
| TC-INVQUOT-P81 | Positive | Ctrl | Update draft quotation → updates header + replaces items (delete all + recreate), redirects with success | Updated | test_inv_quot_81 | Automated |
| TC-INVQUOT-N82 | Negative | Biz | Update received quotation → DomainException "Cannot modify received quotation" | Blocked | test_inv_quot_82 | Automated |

### Screen 5: Mark as Received

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVQUOT-P100 | Positive | View | Mark Received button visible on draft/sent quotation | Visible | test_inv_quot_100 | Automated |
| TC-INVQUOT-P101 | Positive | Ctrl | Mark draft quotation as received → status=received, redirects with success | Received | test_inv_quot_101 | Automated |

### Screen 6: Convert to PO

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVQUOT-P120 | Positive | View | Convert to PO button visible on received quotation | Visible | test_inv_quot_120 | Automated |
| TC-INVQUOT-P121 | Positive | Ctrl | Convert received quotation to PO → creates PO linked to quotation and PR, redirects to PO show | PO created | test_inv_quot_121 | Automated |
| TC-INVQUOT-N122 | Negative | Auth | Convert without `tenant.inventory.purchase-order.create` → 403 | 403 | test_inv_quot_122 | Automated |

### Screen 7: Delete (Guarded) + Soft Delete Lifecycle

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVQUOT-P140 | Positive | Ctrl | Delete draft quotation → soft-deleted, items cascade deleted | Deleted | test_inv_quot_140 | Automated |
| TC-INVQUOT-N141 | Negative | Biz | Delete received quotation → DomainException | Blocked | test_inv_quot_141 | Automated |
| TC-INVQUOT-P142 | Positive | View | Trash page with restore/force-delete | Table | test_inv_quot_142 | Automated |
| TC-INVQUOT-P143 | Positive | Ctrl | Restore from trash → success | Restored | test_inv_quot_143 | Automated |
| TC-INVQUOT-P144 | Positive | Ctrl | Force delete from trash → permanently deleted | Perm deleted | test_inv_quot_144 | Automated |

### Authorization Tests

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVQUOT-P200 | Positive | Auth | Quotation CRUD with correct permissions → 200 | 200 | test_inv_quot_200 | Automated |
| TC-INVQUOT-N201 | Negative | Auth | Without viewAny → 403 on tab | 403 | test_inv_quot_201 | Automated |
| TC-INVQUOT-N202 | Negative | Auth | Without create → 403 on store | 403 | test_inv_quot_202 | Automated |
| TC-INVQUOT-N203 | Negative | Auth | Without view → 403 on show | 403 | test_inv_quot_203 | Automated |
| TC-INVQUOT-N204 | Negative | Auth | Without edit → 403 on edit/update/markReceived | 403 | test_inv_quot_204 | Automated |
| TC-INVQUOT-N205 | Negative | Auth | Without delete → 403 on destroy/trashed/restore/forceDelete | 403 | test_inv_quot_205 | Automated |
