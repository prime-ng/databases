# inv_IssueRequest — Test Case List & Business Conditions

**Module:** Inventory (CODE `INV`, prefix `inv_`) · **Feature:** Issue Requests (CRUD + Approval Lifecycle + Partial Fulfillment)
**DB scope:** TENANT-side (`inv_issue_requests`, `inv_issue_request_items`) · **Test style:** Browser Dusk
**Primary table:** `inv_issue_requests` (Layer 5) · **Module URL prefix:** `/inventory/stock-movement?tab=issue-requests`
**Test file:** `inv_IssueRequest_TestCas.php`
**Tab:** Issue Requests (first tab of Stock Movement page)

Controllers:
- `IssueRequestController` — CRUD + approve/reject + trashed lifecycle
- `InvMenuController::stockMovement()` — loads issue requests + dropdowns for all 4 tabs

Service:
- `StockIssueService` — generateRequestNumber, updateIssueRequestStatus

Routes (`inventory.` prefix):
- `GET /inventory/stock-movement` — combined tab page (issue-requests default)
- `GET /inventory/issue-requests` — index (redirects to stock-movement tab)
- `POST /inventory/issue-requests` — store (with nested items)
- `GET /inventory/issue-requests/{issueRequest}` — show
- `PUT /inventory/issue-requests/{issueRequest}` — update (when submitted or rejected)
- `DELETE /inventory/issue-requests/{issueRequest}` — soft delete (only submitted)
- `PATCH /inventory/issue-requests/{ir}/approve` — approve + set issued_qty per item
- `PATCH /inventory/issue-requests/{ir}/reject` — reject with required remarks
- `GET /inventory/issue-requests/trash/view` — trashed
- `GET /inventory/issue-requests/{id}/restore` — restore
- `DELETE /inventory/issue-requests/{id}/force-delete` — force delete

**DDL reference:** `inv_issue_requests` (Layer 5), `inv_issue_request_items` (Layer 6)

---

## 1. Business Conditions

### BC-DB — Schema & Foreign Keys
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `inv_issue_requests`: id (BIGINT PK AI), request_number (VARCHAR 50 NOT NULL UNIQUE), requested_by (BIGINT UNSIGNED NOT NULL), department_id (INT UNSIGNED NOT NULL), required_date (DATE NOT NULL), status (ENUM submitted/approved/issued/partial/rejected DEFAULT submitted), approved_by (BIGINT UNSIGNED NULL), remarks (TEXT NULL), is_active, created_by, updated_by, created_at, updated_at, deleted_at. Indexes: uq_inv_ir_number, idx_inv_ir_requested_by/department_id/status/approved_by/is_active | DDL |
| BC-DB-02 | Table `inv_issue_request_items`: id (BIGINT PK AI), issue_request_id (BIGINT UNSIGNED NOT NULL), item_id (BIGINT UNSIGNED NOT NULL), requested_qty (DECIMAL 15,3 NOT NULL), issued_qty (DECIMAL 15,3 NOT NULL DEFAULT 0), uom_id (BIGINT UNSIGNED NOT NULL), is_active, created_by, updated_by, created_at, updated_at, deleted_at. FKs: issue_request_id → inv_issue_requests.id CASCADE, item_id → inv_stock_items.id, uom_id → inv_units_of_measure.id | DDL |
| BC-DB-03 | Model `IssueRequest`: table inv_issue_requests, SoftDeletes, fillable 9 fields, casts: required_date→date, is_active→boolean, status→string. Relations: requestedByEmployee() BelongsTo (User::class, 'requested_by'), items() HasMany (IssueRequestItem), stockIssues() HasMany (StockIssue::class) | Model |
| BC-DB-04 | Model `IssueRequestItem`: table inv_issue_request_items. Relations: issueRequest() BelongsTo, stockItem() BelongsTo (StockItem::class), uom() BelongsTo (UnitOfMeasure::class). Accessors: getQtyRequestedAttribute, getQtyIssuedAttribute | Model |

### BC-VAL — Validation (StoreIssueRequestRequest)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `required_date` required date, after_or_equal:today | FR |
| BC-VAL-02 | `remarks` nullable string max:2000 | FR |
| BC-VAL-03 | `items` required array min:1 | FR |
| BC-VAL-04 | `items.*.item_id` required integer exists:inv_stock_items,id | FR |
| BC-VAL-05 | `items.*.requested_qty` required numeric min:0.001 | FR |
| BC-VAL-06 | `items.*.uom_id` required integer exists:inv_units_of_measure,id | FR |

### BC-AUTH — Authorization (IssueRequestPolicy)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | index/viewAny gate `tenant.inventory.stock-issue.viewAny` | Policy |
| BC-AUTH-02 | create/store gate `tenant.inventory.stock-issue.create` | Policy |
| BC-AUTH-03 | show gate `tenant.inventory.stock-issue.view` | Policy |
| BC-AUTH-04 | edit/update gate `tenant.inventory.stock-issue.update` | Policy |
| BC-AUTH-05 | destroy/trashed/restore/forceDelete gate `tenant.inventory.stock-issue.delete` | Policy |
| BC-AUTH-06 | approve/reject gate `tenant.inventory.stock-issue.approve` (separate permission) | Policy |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Stock Movement page: 4 tabs — Issue Requests (default), Stock Issues, Adjustments, Stock Ledger | MenuCtrl |
| BC-BIZ-02 | Issue Requests tab: table — request_number (linked), status badge (submitted/approved/issued/rejected), requested by, required date, items count, Approve/Reject inline actions, Edit/Delete dropdown (submitted only) | View |
| BC-BIZ-03 | Create via modal: Required By Date (required, min=today), Purpose/Remarks, First Item section (stock_item, qty, uom). Created as submitted by default | View |
| BC-BIZ-04 | Store: generates request_number via StockIssueService::generateRequestNumber() (IR-YYYY-NNNN), sets status=submitted, requested_by=auth user, creates items with issued_qty=0, redirects to tab | Ctrl |
| BC-BIZ-05 | Show page: IR header (number, status, requested by, required date, remarks) + Items table (item, qty, uom, issued_qty) + action panel | View |
| BC-BIZ-06 | Edit: update() allowed only when status=submitted or rejected (abort 422 if not). Replaces all items (delete + recreate) | Ctrl |
| BC-BIZ-07 | Approve: valid only for submitted IR. Requires items array with issued_qty per item (numeric min:0). Updates issued_qty on each item, sets IR status=approved, approved_by=auth user | Ctrl |
| BC-BIZ-08 | Reject: valid only for submitted IR. Requires remarks (required string max:500). Sets status=rejected | Ctrl |
| BC-BIZ-09 | Delete: only submitted IRs can be deleted (abort 422 if not). Items cascade deleted | Ctrl |
| BC-BIZ-10 | Search: by request_number/requester, filter by status (All/Submitted/Approved/Issued/Rejected) | View |
| BC-BIZ-11 | Empty state: "No Issue Requests Found" with hand-holding-box icon | View |
| BC-BIZ-12 | Pagination: appends tab=issue-requests to pagination links | View |
| BC-BIZ-13 | Status lifecycle: submitted → approved → issued/partial (auto by StockIssueService). submitted → rejected. Edit allowed on submitted and rejected | Ctrl/Service |
| BC-BIZ-14 | IR status auto-updated by StockIssueService::updateIssueRequestStatus() when stock is issued: if all items have issued_qty ≥ requested_qty → 'issued', else → 'partial' | Service |
| BC-BIZ-15 | Edit modal: JS function openEditIrModal pre-fills required_date and remarks | View |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | required_date before today → after_or_equal validation error | FR |
| BC-EDG-02 | Duplicate request_number → unique DB constraint | DDL |
| BC-EDG-03 | No items → items required min:1 error | FR |
| BC-EDG-04 | Invalid item_id → exists:inv_stock_items error | FR (cross-module) |
| BC-EDG-05 | Invalid uom_id → exists:inv_units_of_measure error | FR (cross-module) |
| BC-EDG-06 | Zero requested_qty → min:0.001 error | FR |
| BC-EDG-07 | Approve non-submitted IR (approved/issued/rejected) → abort 422 | Ctrl |
| BC-EDG-08 | Reject non-submitted IR → abort 422 | Ctrl |
| BC-EDG-09 | Reject without remarks → validation error (required) | FR |
| BC-EDG-10 | Delete non-submitted IR → abort 422 | Ctrl |
| BC-EDG-11 | Ir remarks > 2000 chars → max error | FR |
| BC-EDG-12 | Approve with negative issued_qty → min:0 validation error | Ctrl |

---

## 2. Test Case List

### Screen 1: Stock Movement Tab / Issue Requests List (GET /inventory/stock-movement)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVIR-P10 | Positive | View | Combined page: 4 tabs — Issue Requests (default), Stock Issues, Adjustments, Stock Ledger | Tabs | test_inv_ir_10 | Automated |
| TC-INVIR-P11 | Positive | View | Issue Requests tab: table — request_number (link), status badge (submitted/approved/issued/rejected), requested by, required date, items count, Approve/Reject inline actions, Edit/Delete actions dropdown (submitted only) | Rendered | test_inv_ir_11 | Automated |
| TC-INVIR-P12 | Positive | View | Search by request_number/requester, filter by status dropdown (All/Submitted/Approved/Issued/Rejected) | Filters | test_inv_ir_12 | Automated |
| TC-INVIR-P13 | Positive | View | Create button opens modal with Required By Date, Remarks, First Item section (item_id, qty, uom_id) | Modal | test_inv_ir_13 | Automated |
| TC-INVIR-P14 | Positive | View | Empty state: "No Issue Requests Found" with hand-holding-box icon | Empty | test_inv_ir_14 | Automated |
| TC-INVIR-P15 | Positive | View | Pagination appends tab=issue-requests query param | Paginated | test_inv_ir_15 | Automated |

### Screen 2: Create (Modal) + Store

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVIR-P30 | Positive | View | Create modal: Required By Date (required, min=today), Remarks, First Item (item_id, requested_qty, uom_id) | Fields | test_inv_ir_30 | Automated |
| TC-INVIR-P31 | Positive | Ctrl | Valid store with 1 item: creates IR with generated request_number (IR-YYYY-NNNN), status=submitted, requested_by=auth user, items with issued_qty=0, redirects to tab | Created | test_inv_ir_31 | Automated |
| TC-INVIR-P32 | Positive | Ctrl | Store with remarks → saved | Created | test_inv_ir_32 | Automated |
| TC-INVIR-N33 | Negative | Val | Missing required_date → required error | Error | test_inv_ir_33 | Automated |
| TC-INVIR-N34 | Negative | Val | required_date before today → after_or_equal error | Error | test_inv_ir_34 | Automated |
| TC-INVIR-N35 | Negative | Val | No items → items required min:1 error | Error | test_inv_ir_35 | Automated |
| TC-INVIR-N36 | Negative | Val | Invalid item_id → exists:inv_stock_items error | Error | test_inv_ir_36 | Automated |
| TC-INVIR-N37 | Negative | Val | Missing requested_qty → required error | Error | test_inv_ir_37 | Automated |
| TC-INVIR-N38 | Negative | Val | Zero requested_qty → min:0.001 error | Error | test_inv_ir_38 | Automated |
| TC-INVIR-N39 | Negative | Val | Invalid uom_id → exists:inv_units_of_measure error | Error | test_inv_ir_39 | Automated |
| TC-INVIR-N40 | Negative | Val | remarks > 2000 chars → max error | Error | test_inv_ir_40 | Automated |

### Screen 3: Show (GET /inventory/issue-requests/{issueRequest})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVIR-P60 | Positive | View | Show: IR header — request_number, status badge, requested by name, required_date formatted, remarks | Layout | test_inv_ir_60 | Automated |
| TC-INVIR-P61 | Positive | View | Items table: Item Name/SKU, UOM, Requested Qty, Issued Qty (auto-updated) | Table | test_inv_ir_61 | Automated |
| TC-INVIR-P62 | Positive | View | Action panel: Approve/Reject (submitted), Edit (submitted/rejected), Delete (submitted) | Conditional | test_inv_ir_62 | Automated |

### Screen 4: Edit + Update

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVIR-P80 | Positive | View | Edit modal: pre-filled with required_date and remarks via openEditIrModal JS | Pre-filled | test_inv_ir_80 | Automated |
| TC-INVIR-P81 | Positive | Ctrl | Update submitted IR → updates header, replaces items, redirects with success | Updated | test_inv_ir_81 | Automated |
| TC-INVIR-P82 | Positive | Ctrl | Update rejected IR → allowed (status check includes rejected) | Updated | test_inv_ir_82 | Automated |
| TC-INVIR-N83 | Negative | Biz | Update approved/issued IR → abort 422 "Cannot edit at this stage" | 422 | test_inv_ir_83 | Automated |

### Screen 5: Approve

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVIR-P100 | Positive | View | Approve button visible on submitted IR with inline confirm | Visible | test_inv_ir_100 | Automated |
| TC-INVIR-P101 | Positive | Ctrl | Approve submitted IR with valid items → updates issued_qty per item, status=approved, approved_by set, redirects back with success | Approved | test_inv_ir_101 | Automated |
| TC-INVIR-N102 | Negative | Biz | Approve non-submitted IR (approved/issued/rejected) → abort 422 | 422 | test_inv_ir_102 | Automated |
| TC-INVIR-N103 | Negative | Val | Approve with missing items array → validation error (required) | Error | test_inv_ir_103 | Automated |
| TC-INVIR-N104 | Negative | Val | Approve with negative issued_qty → min:0 validation error | Error | test_inv_ir_104 | Automated |
| TC-INVIR-N105 | Negative | Auth | Approve without `tenant.inventory.stock-issue.approve` permission → 403 | 403 | test_inv_ir_105 | Automated |

### Screen 6: Reject

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVIR-P120 | Positive | View | Reject button with inline text input for rejection reason on submitted IR | Visible | test_inv_ir_120 | Automated |
| TC-INVIR-P121 | Positive | Ctrl | Reject submitted IR with remarks → status=rejected, remarks saved, redirects with success | Rejected | test_inv_ir_121 | Automated |
| TC-INVIR-N122 | Negative | Biz | Reject non-submitted IR → abort 422 | 422 | test_inv_ir_122 | Automated |
| TC-INVIR-N123 | Negative | Val | Reject without remarks → validation error (required) | Error | test_inv_ir_123 | Automated |
| TC-INVIR-N124 | Negative | Val | Reject with remarks > 500 chars → max error | Error | test_inv_ir_124 | Automated |
| TC-INVIR-N125 | Negative | Auth | Reject without `tenant.inventory.stock-issue.approve` permission → 403 | 403 | test_inv_ir_125 | Automated |

### Screen 7: Delete + Soft Delete Lifecycle

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVIR-P140 | Positive | Ctrl | Delete submitted IR → soft-deleted, items cascade deleted | Deleted | test_inv_ir_140 | Automated |
| TC-INVIR-N141 | Negative | Biz | Delete approved/issued/rejected IR → abort 422 | 422 | test_inv_ir_141 | Automated |
| TC-INVIR-P142 | Positive | View | Trash page with restore/force-delete | Table | test_inv_ir_142 | Automated |
| TC-INVIR-P143 | Positive | Ctrl | Restore from trash → success | Restored | test_inv_ir_143 | Automated |
| TC-INVIR-P144 | Positive | Ctrl | Force delete from trash → permanently deleted | Perm deleted | test_inv_ir_144 | Automated |

### Authorization Tests

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVIR-P200 | Positive | Auth | Issue Request CRUD with correct permissions → 200 | 200 | test_inv_ir_200 | Automated |
| TC-INVIR-N201 | Negative | Auth | Without viewAny → 403 on tab | 403 | test_inv_ir_201 | Automated |
| TC-INVIR-N202 | Negative | Auth | Without create → 403 on store | 403 | test_inv_ir_202 | Automated |
| TC-INVIR-N203 | Negative | Auth | Without view → 403 on show | 403 | test_inv_ir_203 | Automated |
| TC-INVIR-N204 | Negative | Auth | Without update → 403 on edit/update | 403 | test_inv_ir_204 | Automated |
| TC-INVIR-N205 | Negative | Auth | Without delete → 403 on destroy/trashed/restore/forceDelete | 403 | test_inv_ir_205 | Automated |
| TC-INVIR-N206 | Negative | Auth | Without approve permission → 403 on approve/reject | 403 | test_inv_ir_206 | Automated |
