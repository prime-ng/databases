# inv_StockAdjustment — Test Case List & Business Conditions

**Module:** Inventory (CODE `INV`, prefix `inv_`) · **Feature:** Stock Adjustments (Physical Count + Variance Threshold + Ledger Posting)
**DB scope:** TENANT-side (`inv_stock_adjustments`, `inv_stock_adjustment_items`) · **Test style:** Browser Dusk
**Primary table:** `inv_stock_adjustments` (Layer 4) · **Module URL prefix:** `/inventory/stock-movement?tab=adjustments`
**Test file:** `inv_StockAdjustment_TestCas.php`
**Tab:** Adjustments (third tab of Stock Movement page)

Controllers:
- `StockAdjustmentController` — CRUD + submit/approve/reject + trashed lifecycle
- `InvMenuController::stockMovement()` — loads adjustments + dropdowns

Service:
- `StockAdjustmentService` — create, submit, approve, reject, delete, generateAdjustmentNumber
- `StockLedgerService` — postEntry (inward/outward for variance posting)

Routes (`inventory.` prefix):
- `GET /inventory/stock-movement` — combined tab page
- `GET /inventory/stock-adjustments` — index (redirects to stock-movement tab)
- `POST /inventory/stock-adjustments` — store (with nested items)
- `GET /inventory/stock-adjustments/{adjustment}` — show
- `PUT /inventory/stock-adjustments/{adjustment}` — update (only draft)
- `DELETE /inventory/stock-adjustments/{adjustment}` — soft delete (only draft)
- `PATCH /inventory/stock-adjustments/{adj}/submit` — submit for approval
- `PATCH /inventory/stock-adjustments/{adj}/approve` — approve + post ledger
- `PATCH /inventory/stock-adjustments/{adj}/reject` — reject
- `GET /inventory/stock-adjustments/trash/view` — trashed
- `GET /inventory/stock-adjustments/{id}/restore` — restore
- `DELETE /inventory/stock-adjustments/{id}/force-delete` — force delete

**DDL reference:** `inv_stock_adjustments` (Layer 4), `inv_stock_adjustment_items` (Layer 6)

---

## 1. Business Conditions

### BC-DB — Schema & Foreign Keys
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `inv_stock_adjustments`: id (BIGINT PK AI), adjustment_number (VARCHAR 50 NOT NULL UNIQUE), adjustment_date (DATE NOT NULL), godown_id (BIGINT UNSIGNED NOT NULL), reason (VARCHAR 500 NULL), status (ENUM draft/submitted/approved/rejected/posted DEFAULT draft), approved_by (BIGINT UNSIGNED NULL), approved_at (TIMESTAMP NULL), is_active, created_by, updated_by, created_at, updated_at, deleted_at. FK: godown_id → inv_godowns.id | DDL |
| BC-DB-02 | Table `inv_stock_adjustment_items`: id (BIGINT PK AI), adjustment_id (BIGINT UNSIGNED NOT NULL), item_id (BIGINT UNSIGNED NOT NULL), system_qty (DECIMAL 15,3 NOT NULL), physical_qty (DECIMAL 15,3 NOT NULL), variance_qty (DECIMAL 15,3 GENERATED ALWAYS AS (physical_qty - system_qty) STORED), unit_cost (DECIMAL 15,2 NOT NULL), is_active, created_by, updated_by, created_at, updated_at, deleted_at. FKs: adjustment_id → inv_stock_adjustments.id CASCADE, item_id → inv_stock_items.id | DDL |
| BC-DB-03 | Model `StockAdjustment`: table inv_stock_adjustments, SoftDeletes. Casts: adjustment_date→date, approved_at→datetime, is_active→boolean, status→string. Relations: godown() BelongsTo, items() HasMany (StockAdjustmentItem) | Model |
| BC-DB-04 | Model `StockAdjustmentItem`: table inv_stock_adjustment_items, NO SoftDeletes. Relations: stockAdjustment() BelongsTo, stockItem() BelongsTo (StockItem::class) | Model |

### BC-VAL — Validation (StoreStockAdjustmentRequest)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `adjustment_number` nullable string max:50 unique:inv_stock_adjustments,adjustment_number | FR |
| BC-VAL-02 | `adjustment_date` required date | FR |
| BC-VAL-03 | `godown_id` required integer exists:inv_godowns,id | FR |
| BC-VAL-04 | `reason` required in:periodic_count,damage,expiry,theft,correction,opening_balance | FR |
| BC-VAL-05 | `items` required array min:1 | FR |
| BC-VAL-06 | `items.*.stock_item_id` required integer exists:inv_stock_items,id | FR |
| BC-VAL-07 | `items.*.system_qty` nullable numeric min:0 | FR |
| BC-VAL-08 | `items.*.physical_qty` required numeric min:0 | FR |
| BC-VAL-09 | `items.*.unit_cost` nullable numeric min:0 | FR |

### BC-AUTH — Authorization (StockAdjustmentPolicy)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | index/viewAny gate `tenant.inventory.stock-adjustment.viewAny` | Policy |
| BC-AUTH-02 | create/store gate `tenant.inventory.stock-adjustment.create` | Policy |
| BC-AUTH-03 | show gate `tenant.inventory.stock-adjustment.view` | Policy |
| BC-AUTH-04 | edit/update/submit gate `tenant.inventory.stock-adjustment.update` | Policy |
| BC-AUTH-05 | destroy/trashed/restore/forceDelete gate `tenant.inventory.stock-adjustment.delete` | Policy |
| BC-AUTH-06 | approve/reject gate `tenant.inventory.stock-adjustment.approve` (separate permission) | Policy |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Adjustments tab: table — adjustment_number (linked), status badge (draft/submitted/approved/rejected), godown, date, reason badge (periodic_count/damage/expiry/theft/correction/opening_balance), items count, Submit inline button (draft), Approve inline button (submitted), Edit/Delete actions (draft only) | View |
| BC-BIZ-02 | Create via modal: Adjustment Date (required, default today), Godown (required), Reason (required — periodic_count/damage/expiry/theft/correction/opening_balance), First Item section (item_id, system_qty, physical_qty, unit_cost optional) | View |
| BC-BIZ-03 | Store via StockAdjustmentService::create(): generates adjustment_number, sets status=draft, creates items with variance_qty calculated as physical_qty - system_qty (also stored explicitly despite generated column), logs activity | Service |
| BC-BIZ-04 | Show page: adjustment header (number, date, godown, reason, status, approved info) + Items table (item, system_qty, physical_qty, variance_qty with +/- sign, unit_cost, value impact) + action panel | View |
| BC-BIZ-05 | Update: only allowed when status=draft (abort 422 if not). Replaces all items (delete + recreate) | Ctrl |
| BC-BIZ-06 | Submit: StockAdjustmentService::submit() guards status=draft+items>0. Auto-approves if all item variances are within stockItem.variance_threshold; otherwise leaves as 'submitted' for manual approval | Service |
| BC-BIZ-07 | Approve: StockAdjustmentService::approve() guards status=submitted. In transaction: posts ledger entries (inward for surplus, outward for deficit), sets status=approved, approved_by, approved_at, fires StockAdjusted event | Service |
| BC-BIZ-08 | Reject: StockAdjustmentService::reject() guards status=submitted. Requires reason (required string max:500), sets status=rejected | Ctrl |
| BC-BIZ-09 | Delete: StockAdjustmentService::delete() guards status=draft (DomainException if not). Soft-deletes adjustment + items | Service |
| BC-BIZ-10 | Variance Quantity: GENERATED ALWAYS AS (physical_qty - system_qty) STORED — DB computed, never inserted/updated manually | DDL |
| BC-BIZ-11 | Search: by adjustment_number/godown, filter by status (All/Draft/Submitted/Approved/Rejected) | View |
| BC-BIZ-12 | Empty state: "No Adjustments Found" with sliders icon | View |
| BC-BIZ-13 | Pagination: appends tab=adjustments to pagination links | View |
| BC-BIZ-14 | Edit modal: JS function openEditAdjModal pre-fills date, godown select, reason select | View |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Submit adjustment with no items → DomainException | Service |
| BC-EDG-02 | Submit non-draft adjustment → InvalidArgumentException | Service |
| BC-EDG-03 | Approve non-submitted adjustment → InvalidArgumentException | Service |
| BC-EDG-04 | Reject non-submitted adjustment → InvalidArgumentException | Service |
| BC-EDG-05 | Delete non-draft adjustment → DomainException | Service |
| BC-EDG-06 | Variance within threshold on submit → auto-approved (skips manual approval) | Service |
| BC-EDG-07 | Variance exceeds threshold on submit → status=submitted, needs manual approval | Service |
| BC-EDG-08 | Zero variance (physical_qty = system_qty) → no ledger entry posted (skipped with abs(variance) < 0.001) | Service |
| BC-EDG-09 | Duplicate adjustment_number → unique validation error | FR |
| BC-EDG-10 | Invalid godown_id → exists:inv_godowns error | FR |
| BC-EDG-11 | Invalid stock_item_id → exists:inv_stock_items error | FR |
| BC-EDG-12 | Negative physical_qty → min:0 error | FR |
| BC-EDG-13 | Negative unit_cost → min:0 error | FR |

---

## 2. Test Case List

### Screen 1: Adjustments List (GET /inventory/stock-movement?tab=adjustments)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVADJ-P10 | Positive | View | Adjustments tab active via ?tab=adjustments | Active | test_inv_adj_10 | Automated |
| TC-INVADJ-P11 | Positive | View | Table: adjustment_number (link), status badge (draft/submitted/approved/rejected), godown, date, reason badge, items count, Submit (draft) / Approve (submitted) inline buttons, Edit/Delete actions (draft only) | Rendered | test_inv_adj_11 | Automated |
| TC-INVADJ-P12 | Positive | View | Search, filter by status dropdown (All/Draft/Submitted/Approved/Rejected) | Filters | test_inv_adj_12 | Automated |
| TC-INVADJ-P13 | Positive | View | Create button opens modal with all fields | Modal | test_inv_adj_13 | Automated |
| TC-INVADJ-P14 | Positive | View | Empty state: "No Adjustments Found" with sliders icon | Empty | test_inv_adj_14 | Automated |
| TC-INVADJ-P15 | Positive | View | Pagination appends tab=adjustments query param | Paginated | test_inv_adj_15 | Automated |

### Screen 2: Create (Modal) + Store

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVADJ-P30 | Positive | View | Create modal: Adjustment Date (default today), Godown select (required), Reason select (required — 6 options), First Item section (item_id, system_qty, physical_qty required, unit_cost optional) | Fields | test_inv_adj_30 | Automated |
| TC-INVADJ-P31 | Positive | Ctrl | Valid store with 1 item: creates adjustment with generated number (ADJ-YYYY-NNNN), status=draft, items with variance calculated, redirects to show | Created | test_inv_adj_31 | Automated |
| TC-INVADJ-P32 | Positive | Ctrl | Store with all 6 reasons → each saves correctly | Created | test_inv_adj_32 | Automated |
| TC-INVADJ-N33 | Negative | Val | Missing adjustment_date → required error | Error | test_inv_adj_33 | Automated |
| TC-INVADJ-N34 | Negative | Val | Missing godown_id → required error | Error | test_inv_adj_34 | Automated |
| TC-INVADJ-N35 | Negative | Val | Invalid godown_id → exists:inv_godowns error | Error | test_inv_adj_35 | Automated |
| TC-INVADJ-N36 | Negative | Val | Missing reason → required error | Error | test_inv_adj_36 | Automated |
| TC-INVADJ-N37 | Negative | Val | Invalid reason → in: array error | Error | test_inv_adj_37 | Automated |
| TC-INVADJ-N38 | Negative | Val | No items → items required min:1 error | Error | test_inv_adj_38 | Automated |
| TC-INVADJ-N39 | Negative | Val | Invalid stock_item_id → exists:inv_stock_items error | Error | test_inv_adj_39 | Automated |
| TC-INVADJ-N40 | Negative | Val | Missing physical_qty → required error | Error | test_inv_adj_40 | Automated |
| TC-INVADJ-N41 | Negative | Val | Negative physical_qty → min:0 error | Error | test_inv_adj_41 | Automated |
| TC-INVADJ-N42 | Negative | Val | Negative unit_cost → min:0 error | Error | test_inv_adj_42 | Automated |

### Screen 3: Show (GET /inventory/stock-adjustments/{adjustment})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVADJ-P70 | Positive | View | Show: adjustment header — number, date, godown, reason badge, status badge, approved_by/at if approved | Layout | test_inv_adj_70 | Automated |
| TC-INVADJ-P71 | Positive | View | Items table: Item Name/SKU, System Qty, Physical Qty, Variance (with +/- sign), Unit Cost (formatted ₹), Value Impact | Table | test_inv_adj_71 | Automated |
| TC-INVADJ-P72 | Positive | View | Actions: Submit (draft), Approve (submitted), Edit (draft), Delete (draft), Reject (submitted) | Conditional | test_inv_adj_72 | Automated |

### Screen 4: Submit (with Auto-Approve)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVADJ-P90 | Positive | View | Submit button on draft adjustment | Visible | test_inv_adj_90 | Automated |
| TC-INVADJ-P91 | Positive | Ctrl | Submit draft with all variances within threshold → auto-approved (status=approved, ledger updated) | Auto-approved | test_inv_adj_91 | Automated |
| TC-INVADJ-P92 | Positive | Ctrl | Submit draft with variance exceeding threshold → status=submitted (needs manual approval) | Submitted | test_inv_adj_92 | Automated |
| TC-INVADJ-N93 | Negative | Biz | Submit non-draft adjustment → InvalidArgumentException | Blocked | test_inv_adj_93 | Automated |
| TC-INVADJ-N94 | Negative | Biz | Submit adjustment with no items → DomainException | Blocked | test_inv_adj_94 | Automated |

### Screen 5: Approve (with Ledger Posting)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVADJ-P110 | Positive | Ctrl | Approve submitted adjustment → inward entries for surplus (positive variance), outward entries for deficit (negative variance), status=approved, approved_by+approved_at set, event fired | Approved | test_inv_adj_110 | Automated |
| TC-INVADJ-P111 | Positive | Ctrl | Approve with zero-variance items → skipped (no ledger entry) | Skipped | test_inv_adj_111 | Automated |
| TC-INVADJ-N112 | Negative | Biz | Approve non-submitted (draft/approved/rejected) → InvalidArgumentException | Blocked | test_inv_adj_112 | Automated |
| TC-INVADJ-N113 | Negative | Auth | Approve without `tenant.inventory.stock-adjustment.approve` permission → 403 | 403 | test_inv_adj_113 | Automated |

### Screen 6: Reject

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVADJ-P130 | Positive | Ctrl | Reject submitted adjustment with reason → status=rejected, reason saved | Rejected | test_inv_adj_130 | Automated |
| TC-INVADJ-N131 | Negative | Biz | Reject non-submitted adjustment → InvalidArgumentException | Blocked | test_inv_adj_131 | Automated |
| TC-INVADJ-N132 | Negative | Auth | Reject without `tenant.inventory.stock-adjustment.approve` permission → 403 | 403 | test_inv_adj_132 | Automated |

### Screen 7: Update + Delete

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVADJ-P150 | Positive | Ctrl | Update draft adjustment → replaces items, redirects with success | Updated | test_inv_adj_150 | Automated |
| TC-INVADJ-N151 | Negative | Biz | Update non-draft adjustment → abort 422 | 422 | test_inv_adj_151 | Automated |
| TC-INVADJ-P152 | Positive | Ctrl | Delete draft adjustment → soft-deleted, items deleted | Deleted | test_inv_adj_152 | Automated |
| TC-INVADJ-N153 | Negative | Biz | Delete non-draft adjustment → DomainException | Blocked | test_inv_adj_153 | Automated |
| TC-INVADJ-P154 | Positive | View | Trash page with restore/force-delete | Table | test_inv_adj_154 | Automated |
| TC-INVADJ-P155 | Positive | Ctrl | Restore from trash → success | Restored | test_inv_adj_155 | Automated |
| TC-INVADJ-P156 | Positive | Ctrl | Force delete from trash → permanently deleted | Perm deleted | test_inv_adj_156 | Automated |

### Authorization Tests

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVADJ-P200 | Positive | Auth | Adjustment CRUD with correct permissions → 200 | 200 | test_inv_adj_200 | Automated |
| TC-INVADJ-N201 | Negative | Auth | Without viewAny → 403 on tab | 403 | test_inv_adj_201 | Automated |
| TC-INVADJ-N202 | Negative | Auth | Without create → 403 on store | 403 | test_inv_adj_202 | Automated |
| TC-INVADJ-N203 | Negative | Auth | Without view → 403 on show | 403 | test_inv_adj_203 | Automated |
| TC-INVADJ-N204 | Negative | Auth | Without update → 403 on edit/update/submit | 403 | test_inv_adj_204 | Automated |
| TC-INVADJ-N205 | Negative | Auth | Without delete → 403 on destroy/trashed/restore/forceDelete | 403 | test_inv_adj_205 | Automated |
| TC-INVADJ-N206 | Negative | Auth | Without approve permission → 403 on approve/reject | 403 | test_inv_adj_206 | Automated |
