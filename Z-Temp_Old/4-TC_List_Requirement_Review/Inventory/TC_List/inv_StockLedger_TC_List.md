# inv_StockLedger — Test Case List & Business Conditions

**Module:** Inventory (CODE `INV`, prefix `inv_`) · **Feature:** Stock Ledger (Read-Only Append-Only Movement Journal)
**DB scope:** TENANT-side (`inv_stock_entries`) · **Test style:** Browser Dusk
**Primary table:** `inv_stock_entries` (Layer 8) · **Module URL prefix:** `/inventory/stock-movement?tab=ledger`
**Test file:** `inv_StockLedger_TestCas.php`
**Tab:** Stock Ledger (fourth tab of Stock Movement page)

Controllers:
- `StockEntryController` — index, show (read-only)
- `InvMenuController::stockMovement()` — loads stock entries + dropdowns

Services (indirect):
- `StockLedgerService` — postEntry (called by GRN/Issue/Adjustment services)
- `StockValuationService` — rate calculation

Routes (`inventory.` prefix):
- `GET /inventory/stock-movement?tab=ledger` — combined tab page (ledger tab)
- `GET /inventory/stock-entries` — index (redirects to stock-movement tab)
- `GET /inventory/stock-entries/{stockEntry}` — show

**DDL reference:** `inv_stock_entries` (Layer 8)

---

## 1. Business Conditions

### BC-DB — Schema & Foreign Keys
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `inv_stock_entries`: id (BIGINT PK AI), stock_item_id (BIGINT UNSIGNED NOT NULL), godown_id (BIGINT UNSIGNED NOT NULL), voucher_id (BIGINT UNSIGNED NOT NULL), entry_type (ENUM inward/outward/transfer_in/transfer_out/adjustment NOT NULL), quantity (DECIMAL 15,3 NOT NULL), rate (DECIMAL 15,2 NOT NULL), amount (DECIMAL 15,2 NOT NULL), batch_number (VARCHAR 50 NULL), expiry_date (DATE NULL), destination_godown_id (BIGINT UNSIGNED NULL), party_ledger_id (BIGINT UNSIGNED NULL), narration (VARCHAR 500 NULL), is_active, created_by, updated_by, created_at, updated_at, deleted_at. IMMUTABLE — append-only (BR-INV-014). FKs: stock_item_id → inv_stock_items.id, godown_id → inv_godowns.id | DDL |
| BC-DB-02 | Model: StockEntry (likely read-only model). Relations: stockItem() BelongsTo, godown() BelongsTo | Model |

### BC-AUTH — Authorization
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | index/viewAny gate `tenant.inventory.stock-ledger.viewAny` (or similar) | Policy/Route |
| BC-AUTH-02 | show gate `tenant.inventory.stock-ledger.view` | Policy/Route |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Stock Ledger tab: table — date, entry type badge (inward/outward/transfer_in/transfer_out/adjustment_in/adjustment_out/opening), item name, quantity (signed: +green for inbound, −red for outbound), rate (formatted ₹), total value (formatted ₹), godown, narration | View |
| BC-BIZ-02 | Filters: search text, item select (All Items dropdown), godown select (All Godowns dropdown) | View |
| BC-BIZ-03 | Entry types displayed: Inward (GRN), Outward (Issue), Transfer In/Out, Adjustment In/Out, Opening | View |
| BC-BIZ-04 | Empty state: "No Ledger Entries Found" with book-open icon | View |
| BC-BIZ-05 | Pagination appends tab=ledger, item, godown params | View |
| BC-BIZ-06 | BR-INV-014: Stock entries are IMMUTABLE — append-only. Never UPDATE or DELETE after insert. Soft delete only via StockLedgerService guard | DDL |
| BC-BIZ-07 | BR-INV-001: voucher_id is MANDATORY (NOT NULL). No orphan entries allowed | DDL |
| BC-BIZ-08 | All modules post to this table: GRN acceptance (inward), Stock Issues (outward), Adjustments (adjustment), Transfers (transfer_in/out) | Multiple |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Read-only: no create/edit/delete operations from UI | Design |
| BC-EDG-02 | Filter by item and godown simultaneously → combined filtering | View |
| BC-EDG-03 | Entry types: mapping to display labels (inward→Inward, outward→Outward, transfer_in→Transfer In, etc.) | View |
| BC-EDG-04 | Quantity sign: inbound = green with + prefix, outbound = red with − prefix | View |

---

## 2. Test Case List

### Screen 1: Stock Ledger Tab (GET /inventory/stock-movement?tab=ledger)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVLED-P10 | Positive | View | Stock Ledger tab active via ?tab=ledger | Active | test_inv_led_10 | Automated |
| TC-INVLED-P11 | Positive | View | Table: date, entry type badge (color-coded: green=inbound, red=outbound, info=transfer, warning=adjustment), item name, quantity with +/- sign, rate, total value, godown, narration (truncated) | Rendered | test_inv_led_11 | Automated |
| TC-INVLED-P12 | Positive | View | Filter by item (dropdown), godown (dropdown), search text | Filters | test_inv_led_12 | Automated |
| TC-INVLED-P13 | Positive | View | All 7 entry type labels render correctly: Inward, Outward, Transfer In, Transfer Out, Adjustment In, Adjustment Out, Opening | Labels | test_inv_led_13 | Automated |
| TC-INVLED-P14 | Positive | View | Entry type badges: green theme for inward/opening, red for outward, info for transfer, warning for adjustment | Badges | test_inv_led_14 | Automated |
| TC-INVLED-P15 | Positive | View | Quantity signs: + for inbound, − for outbound, with color coding (green/red) | Signs | test_inv_led_15 | Automated |
| TC-INVLED-P16 | Positive | View | Narration column: truncated at 30 chars with title tooltip | Truncation | test_inv_led_16 | Automated |
| TC-INVLED-P17 | Positive | View | Empty state: "No Ledger Entries Found" with book-open icon | Empty | test_inv_led_17 | Automated |
| TC-INVLED-P18 | Positive | View | Pagination: appends tab=ledger, item, godown, entry_type, date_from, date_to params | Paginated | test_inv_led_18 | Automated |

### Authorization Tests

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVLED-P200 | Positive | Auth | View ledger with correct permissions → 200 | 200 | test_inv_led_200 | Automated |
| TC-INVLED-N201 | Negative | Auth | Without viewAny → 403 on tab | 403 | test_inv_led_201 | Automated |
