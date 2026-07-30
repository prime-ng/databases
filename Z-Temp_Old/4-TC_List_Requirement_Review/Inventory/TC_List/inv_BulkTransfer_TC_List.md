# inv_BulkTransfer — Test Case List & Business Conditions

**Module:** Inventory (CODE `INV`, prefix `inv_`) · **Feature:** Bulk Transfer (Godown-to-Godown Stock Transfer)
**DB scope:** TENANT-side (`inv_stock_entries`) · **Test style:** Browser Dusk
**Module URL prefix:** `/inventory/bulk-transfer`
**Test file:** `inv_BulkTransfer_TestCas.php`
**Page:** Standalone page outside the Stock Movement tabs

Controllers:
- `StockTransferController` — create (show form), bulkTransfer (execute)
- `StockLedgerService` — postEntry (transfer_out + transfer_in)

Services:
- `StockIssueService` — injected but not directly used
- `StockLedgerService` — postEntry for transfer entries

Routes (`inventory.` prefix):
- `GET /inventory/bulk-transfer` — create form
- `POST /inventory/bulk-transfer` — execute bulk transfer

---

## 1. Business Conditions

### BC-DB — Schema & Foreign Keys
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Bulk Transfer uses `inv_stock_entries` table: posts transfer_out from source godown and transfer_in to destination godown (no dedicated transfer table). entry_type ENUM includes transfer_in/transfer_out. destination_godown_id column stores destination for transfer_out entries | DDL |

### BC-VAL — Validation (BulkTransferRequest)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `godown_from` required integer exists:inv_godowns,id | FR |
| BC-VAL-02 | `godown_to` required integer exists:inv_godowns,id different:godown_from | FR |
| BC-VAL-03 | `items` required array min:1 | FR |
| BC-VAL-04 | `items.*.item_id` required integer exists:inv_stock_items,id | FR |
| BC-VAL-05 | `items.*.qty` required numeric min:0.001 | FR |
| BC-VAL-06 | `items.*.unit_cost` nullable numeric min:0 | FR |

### BC-AUTH — Authorization
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | create (GET form + POST execute) gate `tenant.inventory.stock-issue.create` (uses same permission) | Ctrl |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Bulk Transfer form: two godown selects (From/To, must differ), dynamic item rows with item select, qty, unit_cost | View |
| BC-BIZ-02 | Execute: StockTransferController::bulkTransfer() runs in DB transaction. For each item: posts transfer_out entry from source godown (with destination_godown_id set), and transfer_in entry to destination godown | Ctrl |
| BC-BIZ-03 | Reference number: auto-generated as 'Bulk Transfer #' + strtoupper(uniqid()) — no sequential format | Ctrl |
| BC-BIZ-04 | Redirects to stock-movement?tab=transfers with success message showing item count | Ctrl |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | godown_from = godown_to → different validation error (same godown) | FR |
| BC-EDG-02 | Invalid godown_from → exists:inv_godowns error | FR |
| BC-EDG-03 | Invalid item_id → exists:inv_stock_items error | FR |
| BC-EDG-04 | Zero qty → min:0.001 error | FR |
| BC-EDG-05 | Negative unit_cost → min:0 error | FR |
| BC-EDG-06 | Insufficient stock in source godown → outward guard in StockLedgerService (BR-INV-003) | Service |

---

## 2. Test Case List

### Screen 1: Bulk Transfer Form (GET /inventory/bulk-transfer)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVTRF-P10 | Positive | View | Bulk Transfer page: From Godown select, To Godown select (different constraint), dynamic item rows (item_id, qty, unit_cost) | Rendered | test_inv_trf_10 | Automated |

### Screen 2: Execute Bulk Transfer (POST /inventory/bulk-transfer)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVTRF-P30 | Positive | Ctrl | Valid transfer with 1 item → transfer_out entry posted from source, transfer_in posted to destination, reference generated, redirects with success | Transferred | test_inv_trf_30 | Automated |
| TC-INVTRF-P31 | Positive | Ctrl | Transfer with multiple items → all items processed in transaction | All transferred | test_inv_trf_31 | Automated |
| TC-INVTRF-N32 | Negative | Val | godown_from = godown_to → different validation error | Error | test_inv_trf_32 | Automated |
| TC-INVTRF-N33 | Negative | Val | Missing godown_from → required error | Error | test_inv_trf_33 | Automated |
| TC-INVTRF-N34 | Negative | Val | Invalid godown_from → exists:inv_godowns error | Error | test_inv_trf_34 | Automated |
| TC-INVTRF-N35 | Negative | Val | Missing godown_to → required error | Error | test_inv_trf_35 | Automated |
| TC-INVTRF-N36 | Negative | Val | No items → items required min:1 error | Error | test_inv_trf_36 | Automated |
| TC-INVTRF-N37 | Negative | Val | Invalid item_id → exists:inv_stock_items error | Error | test_inv_trf_37 | Automated |
| TC-INVTRF-N38 | Negative | Val | Zero qty → min:0.001 error | Error | test_inv_trf_38 | Automated |
| TC-INVTRF-N39 | Negative | Val | Negative unit_cost → min:0 error | Error | test_inv_trf_39 | Automated |
| TC-INVTRF-N40 | Negative | Auth | Without `tenant.inventory.stock-issue.create` permission → 403 | 403 | test_inv_trf_40 | Automated |
| TC-INVTRF-N41 | Negative | Biz | Insufficient stock in source godown → ledger guard blocks (BR-INV-003) | Blocked | test_inv_trf_41 | Automated |
