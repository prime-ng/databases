# inv_StockIssue — Test Case List & Business Conditions

**Module:** Inventory (CODE `INV`, prefix `inv_`) · **Feature:** Stock Issues (Issue Execution + Direct Issue + Acknowledgment + Print Slip)
**DB scope:** TENANT-side (`inv_stock_issues`, `inv_stock_issue_items`) · **Test style:** Browser Dusk
**Primary table:** `inv_stock_issues` (Layer 7) · **Module URL prefix:** `/inventory/stock-movement?tab=stock-issues`
**Test file:** `inv_StockIssue_TestCas.php`
**Tab:** Stock Issues (second tab of Stock Movement page)

Controllers:
- `StockIssueController` — store (executeIssue / directIssue), show, acknowledge, printSlip
- `InvMenuController::stockMovement()` — loads stock issues + pending IRs for conversion

Service:
- `StockIssueService` — executeIssue, directIssue, generateIssueNumber, updateIssueRequestStatus
- `StockLedgerService` — postEntry (outward)
- `StockValuationService` — getIssueRate
- `ReorderAlertService` — checkAndDispatch

Routes (`inventory.` prefix):
- `GET /inventory/stock-movement` — combined tab page
- `GET /inventory/stock-issues` — index (redirects to stock-movement tab)
- `POST /inventory/stock-issues` — store (linked to IR or direct)
- `GET /inventory/stock-issues/{stockIssue}` — show
- `PATCH /inventory/stock-issues/{si}/acknowledge` — acknowledge receipt
- `GET /inventory/stock-issues/{si}/print-slip` — print issue slip
- `GET /inventory/stock-entries` — read-only stock ledger (tab 4)
- `GET /inventory/stock-entries/{stockEntry}` — show entry

**DDL reference:** `inv_stock_issues` (Layer 8), `inv_stock_issue_items` (Layer 9), `inv_stock_entries` (Layer 8)

---

## 1. Business Conditions

### BC-DB — Schema & Foreign Keys
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `inv_stock_issues`: id (BIGINT PK AI), issue_number (VARCHAR 50 NOT NULL UNIQUE), issue_request_id (BIGINT UNSIGNED NULL), godown_id (BIGINT UNSIGNED NOT NULL), issued_by (BIGINT UNSIGNED NOT NULL), issued_to_employee_id (INT UNSIGNED NULL), department_id (INT UNSIGNED NOT NULL), issue_date (DATE NOT NULL), voucher_id (BIGINT UNSIGNED NULL), acknowledged_by (BIGINT UNSIGNED NULL), acknowledged_at (TIMESTAMP NULL), is_active, created_by, updated_by, created_at, updated_at, deleted_at. FKs: issue_request_id → inv_issue_requests.id SET NULL, godown_id → inv_godowns.id | DDL |
| BC-DB-02 | Table `inv_stock_issue_items`: id (BIGINT PK AI), stock_issue_id (BIGINT UNSIGNED NOT NULL), item_id (BIGINT UNSIGNED NOT NULL), qty (DECIMAL 15,3 NOT NULL), unit_cost (DECIMAL 15,2 NOT NULL), batch_number (VARCHAR 50 NULL), is_active, created_by, updated_by, created_at, updated_at, deleted_at. FKs: stock_issue_id → inv_stock_issues.id CASCADE, item_id → inv_stock_items.id | DDL |
| BC-DB-03 | Table `inv_stock_entries`: id (BIGINT PK AI), stock_item_id (BIGINT UNSIGNED NOT NULL), godown_id (BIGINT UNSIGNED NOT NULL), voucher_id (BIGINT UNSIGNED NOT NULL), entry_type (ENUM inward/outward/transfer_in/transfer_out/adjustment), quantity (DECIMAL 15,3), rate (DECIMAL 15,2), amount (DECIMAL 15,2), batch_number, expiry_date, destination_godown_id, party_ledger_id, narration, is_active, created_by, updated_by, created_at, updated_at, deleted_at. IMMUTABLE — append-only (BR-INV-014) | DDL |
| BC-DB-04 | Model `StockIssue`: table inv_stock_issues, SoftDeletes. Relations: issueRequest() BelongsTo, godown() BelongsTo, issuedToEmployee() BelongsTo (User::class), items() HasMany (StockIssueItem) | Model |
| BC-DB-05 | Model `StockIssueItem`: table inv_stock_issue_items, SoftDeletes. Relations: stockIssue() BelongsTo, stockItem() BelongsTo (StockItem::class) | Model |

### BC-VAL — Validation (StoreStockIssueRequest)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `issue_request_id` nullable exists:inv_issue_requests,id | FR |
| BC-VAL-02 | `issued_to_employee_id` nullable | FR |
| BC-VAL-03 | `department_id` required integer | FR |
| BC-VAL-04 | `godown_id` required exists:inv_godowns,id | FR |
| BC-VAL-05 | `issue_date` required date | FR |
| BC-VAL-06 | `notes` nullable string | FR |
| BC-VAL-07 | `items` required array min:1 | FR |
| BC-VAL-08 | `items.*.stock_item_id` required integer exists:inv_stock_items,id | FR |
| BC-VAL-09 | `items.*.qty_issued` required numeric min:0.01 | FR |
| BC-VAL-10 | `items.*.unit_cost` required numeric min:0 | FR |
| BC-VAL-11 | `items.*.batch_number` nullable string max:50 | FR |
| BC-VAL-12 | `items.*.remarks` nullable string max:255 | FR |

### BC-VAL — Validation (BulkTransferRequest)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-TR-01 | `godown_from` required exists:inv_godowns,id | FR |
| BC-VAL-TR-02 | `godown_to` required exists:inv_godowns,id different:godown_from | FR |
| BC-VAL-TR-03 | `items` required array min:1 | FR |
| BC-VAL-TR-04 | `items.*.item_id` required exists:inv_stock_items,id | FR |
| BC-VAL-TR-05 | `items.*.qty` required numeric min:0.001 | FR |
| BC-VAL-TR-06 | `items.*.unit_cost` nullable numeric min:0 | FR |

### BC-AUTH — Authorization (StockIssuePolicy)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | index/viewAny gate `tenant.inventory.stock-issue.viewAny` | Policy |
| BC-AUTH-02 | create/store gate `tenant.inventory.stock-issue.create` | Policy |
| BC-AUTH-03 | show gate `tenant.inventory.stock-issue.view` | Policy |
| BC-AUTH-04 | edit/update/acknowledge gate `tenant.inventory.stock-issue.update` | Policy |
| BC-AUTH-05 | Bulk transfer create gate `tenant.inventory.stock-issue.create` (same permission) | Ctrl |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Stock Issues tab: table — issue_number (linked), status badge (issued/acknowledged), issued to, godown, issue date, items count, Print Slip action, View action | View |
| BC-BIZ-02 | Create: done via StockIssueService. Two paths: executeIssue (against approved IR) or directIssue (bypasses IR, requires direct permission). Store request decides via presence of issue_request_id | Ctrl |
| BC-BIZ-03 | Execute Issue (against IR): StockIssueService::executeIssue() guards IR status=approved (DomainException if not, BR-INV-010). In transaction: creates StockIssue with generated issue_number, creates items with unit_cost from StockValuationService, posts outward stock entry to ledger (BR-INV-003), increments IR item issued_qty, dispatches reorder alert (BR-INV-011), fires StockIssued event | Service |
| BC-BIZ-04 | Direct Issue: StockIssueService::directIssue() requires `tenant.inventory.stock-issue.direct` gate. Same transaction flow but without IR linkage | Service |
| BC-BIZ-05 | Acknowledge: records acknowledged_by + acknowledged_at on StockIssue. No status guard (status column not present in migration) | Ctrl |
| BC-BIZ-06 | Print Slip: renders print-friendly Material Issue Slip with header (school info), meta (issue number, date, to employee, godown), items table (qty, unit cost, total value), signature section, auto-print on load | View |
| BC-BIZ-07 | Show page: issue header (number, IR reference, godown, issued to, date, status) + items table (item, qty, unit cost, total value) + Acknowledge button + Print Slip | View |
| BC-BIZ-08 | Search: by issue_number/employee, filter by active/inactive status | View |
| BC-BIZ-09 | Empty state: "No Stock Issues Found" with dolly icon | View |
| BC-BIZ-10 | Pagination: appends tab=stock-issues to pagination links | View |
| BC-BIZ-11 | Voucher placeholders: voucher_id=0 until Accounting processes StockIssued event (D21) | Service |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Execute issue against non-approved IR → DomainException (BR-INV-010) | Service |
| BC-EDG-02 | Direct issue without `tenant.inventory.stock-issue.direct` permission → 403 | Service |
| BC-EDG-03 | Wrong godown_from = godown_to → different validation error | FR |
| BC-EDG-04 | Negative qty_issued → min:0.01 validation error | FR |
| BC-EDG-05 | Zero unit_cost → min:0 error | FR |
| BC-EDG-06 | Invalid godown_id → exists:inv_godowns error | FR |
| BC-EDG-07 | Negative stock prevention: StockLedgerService::postEntry with outward type when insufficient balance → BR-INV-003 guard | Service |

---

## 2. Test Case List

### Screen 1: Stock Issues List (GET /inventory/stock-movement?tab=stock-issues)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVSI-P10 | Positive | View | Stock Issues tab active via ?tab=stock-issues | Active | test_inv_si_10 | Automated |
| TC-INVSI-P11 | Positive | View | Table: issue_number (link), status badge (issued/acknowledged), issued to, godown, issue date, items count, Print Slip action, View action | Rendered | test_inv_si_11 | Automated |
| TC-INVSI-P12 | Positive | View | Filter by active/inactive status | Filters | test_inv_si_12 | Automated |
| TC-INVSI-P13 | Positive | View | Empty state: "No Stock Issues Found" with dolly icon | Empty | test_inv_si_13 | Automated |
| TC-INVSI-P14 | Positive | View | Pagination appends tab=stock-issues query param | Paginated | test_inv_si_14 | Automated |

### Screen 2: Execute Issue Against IR (Store)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVSI-P30 | Positive | Ctrl | Execute issue against approved IR → StockIssue created with generated issue_number (SI-YYYY-NNNN), items created with unit_cost from valuation, outward stock entry posted, IR issued_qty incremented, IR status updated to issued/partial, event fired | Created | test_inv_si_30 | Automated |
| TC-INVSI-P31 | Positive | Ctrl | Execute issue with batch_number → saved on issue items | Created | test_inv_si_31 | Automated |
| TC-INVSI-P32 | Positive | Ctrl | Partial issue (less than requested) → IR status becomes 'partial' | Partial | test_inv_si_32 | Automated |
| TC-INVSI-P33 | Positive | Ctrl | Full issue (all requested qty fulfilled) → IR status becomes 'issued' | Issued | test_inv_si_33 | Automated |
| TC-INVSI-N34 | Negative | Biz | Execute issue against non-approved IR (submitted/rejected) → DomainException (BR-INV-010) | Blocked | test_inv_si_34 | Automated |
| TC-INVSI-N35 | Negative | Biz | Execute issue with insufficient stock → ledger outward guard (BR-INV-003) | Blocked | test_inv_si_35 | Automated |

### Screen 3: Direct Issue (Store without IR)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVSI-P50 | Positive | Ctrl | Direct issue without IR → StockIssue created with issue_request_id=null, same ledger/event flow | Created | test_inv_si_50 | Automated |
| TC-INVSI-N51 | Negative | Auth | Direct issue without `tenant.inventory.stock-issue.direct` permission → 403 | 403 | test_inv_si_51 | Automated |

### Screen 4: Show (GET /inventory/stock-issues/{stockIssue})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVSI-P70 | Positive | View | Show: issue header — issue_number, IR reference (linked if exists), godown, issued to employee, issue date, status | Layout | test_inv_si_70 | Automated |
| TC-INVSI-P71 | Positive | View | Items table: Item Name/SKU, Qty, Unit Cost (formatted ₹), Total Value (qty×unit_cost), Batch Number | Table | test_inv_si_71 | Automated |
| TC-INVSI-P72 | Positive | View | Acknowledge button + Print Slip button + Back button | Actions | test_inv_si_72 | Automated |

### Screen 5: Acknowledge

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVSI-P90 | Positive | View | Acknowledge button on show page for issued stock | Visible | test_inv_si_90 | Automated |
| TC-INVSI-P91 | Positive | Ctrl | Acknowledge → acknowledged_by + acknowledged_at set, success message | Acknowledged | test_inv_si_91 | Automated |

### Screen 6: Print Slip

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVSI-P110 | Positive | View | Print Slip button on list (for issued status) and show page | Visible | test_inv_si_110 | Automated |
| TC-INVSI-P111 | Positive | View | Print view: school header, issue meta (number, date, to, godown), items table with totals, signature section, auto-print JS | Rendered | test_inv_si_111 | Automated |

### Authorization Tests

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVSI-P200 | Positive | Auth | Stock Issue operations with correct permissions → 200 | 200 | test_inv_si_200 | Automated |
| TC-INVSI-N201 | Negative | Auth | Without viewAny → 403 on tab | 403 | test_inv_si_201 | Automated |
| TC-INVSI-N202 | Negative | Auth | Without create → 403 on store | 403 | test_inv_si_202 | Automated |
| TC-INVSI-N203 | Negative | Auth | Without view → 403 on show | 403 | test_inv_si_203 | Automated |
| TC-INVSI-N204 | Negative | Auth | Without update → 403 on acknowledge | 403 | test_inv_si_204 | Automated |
