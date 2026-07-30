# inv_PurchaseRequisition — Test Case List & Business Conditions

**Module:** Inventory (CODE `INV`, prefix `inv_`) · **Feature:** Purchase Requisitions (CRUD + Status Lifecycle + Items)
**DB scope:** TENANT-side (`inv_purchase_requisitions`, `inv_purchase_requisition_items`) · **Test style:** Browser Dusk
**Primary table:** `inv_purchase_requisitions` (Layer 4) · **Module URL prefix:** `/inventory/procurement?tab=prs`
**Test file:** `inv_PurchaseRequisition_TestCas.php`
**Tab:** PRs (first tab of Procurement page)

Controllers:
- `PurchaseRequisitionController` — CRUD + submit/approve/reject + trashed lifecycle
- `InvMenuController::procurement()` — loads PRs + dropdowns for all 4 tabs

Service:
- `PurchaseRequisitionService` — create, update, delete, submit, approve, reject

Routes (`inventory.` prefix):
- `GET /inventory/procurement` — combined tab page (prs default)
- `GET /inventory/prs` — index (redirects to procurement tab)
- `POST /inventory/prs` — store (with nested items array)
- `GET /inventory/prs/{purchaseRequisition}` — show
- `GET /inventory/prs/{purchaseRequisition}/edit` — edit
- `PUT /inventory/prs/{purchaseRequisition}` — update
- `DELETE /inventory/prs/{purchaseRequisition}` — soft delete
- `PATCH /inventory/prs/{purchaseRequisition}/submit` — submit (draft→submitted)
- `PATCH /inventory/prs/{purchaseRequisition}/approve` — approve (submitted→approved)
- `PATCH /inventory/prs/{purchaseRequisition}/reject` — reject (submitted→rejected)
- `GET /inventory/prs/trash/view` — trashed
- `GET /inventory/prs/{id}/restore` — restore
- `DELETE /inventory/prs/{id}/force-delete` — force delete

**DDL reference:** `inv_purchase_requisitions` (Layer 4), `inv_purchase_requisition_items` (Layer 5)

---

## 1. Business Conditions

### BC-DB — Schema & Foreign Keys
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `inv_purchase_requisitions`: id (BIGINT PK AI), pr_number (VARCHAR 50 NOT NULL UNIQUE), requested_by (BIGINT UNSIGNED NOT NULL), department_id (INT UNSIGNED NULL), required_date (DATE NOT NULL), priority (ENUM low/normal/high/urgent DEFAULT normal), status (ENUM draft/submitted/approved/rejected/converted/cancelled DEFAULT draft), approved_by (BIGINT UNSIGNED NULL), approved_at (TIMESTAMP NULL), remarks (TEXT NULL), is_active, created_by, updated_by, created_at, updated_at, deleted_at. Indexes: uq_inv_pr_number, idx_inv_pr_requested_by/department_id/status/approved_by/is_active | DDL |
| BC-DB-02 | Table `inv_purchase_requisition_items`: id (BIGINT PK AI), pr_id (BIGINT UNSIGNED NOT NULL), item_id (BIGINT UNSIGNED NOT NULL), qty (DECIMAL 15,3 NOT NULL), uom_id (BIGINT UNSIGNED NOT NULL), estimated_rate (DECIMAL 15,2 NULL), remarks (VARCHAR 255 NULL), is_active, created_by, updated_by, created_at, updated_at, deleted_at. FKs: pr_id → inv_purchase_requisitions.id CASCADE, item_id → inv_stock_items.id, uom_id → inv_units_of_measure.id | DDL |
| BC-DB-03 | Model `PurchaseRequisition`: table inv_purchase_requisitions, SoftDeletes, fillable 9 fields, casts: required_date→date, approved_at→timestamp, is_active→boolean, status→string. Relations: requestedByEmployee() BelongsTo (Employee::class, 'requested_by'), department() BelongsTo (Department::class), items() HasMany (PurchaseRequisitionItem), approver() BelongsTo (Employee::class, 'approved_by') | Model |
| BC-DB-04 | Model `PurchaseRequisitionItem`: table inv_purchase_requisition_items, NO SoftDeletes. Casts: qty/estimated_rate→decimal. Relations: purchaseRequisition() BelongsTo, stockItem() BelongsTo (StockItem::class), uom() BelongsTo (UnitOfMeasure::class) | Model |

### BC-VAL — Validation (StorePurchaseRequisitionRequest)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `required_date` required date, on_or_after today | FR |
| BC-VAL-02 | `department_id` nullable integer exists:sch_departments,id | FR |
| BC-VAL-03 | `priority` required in:low,normal,high,urgent (default normal) | FR |
| BC-VAL-04 | `remarks` nullable string max:2000 | FR |
| BC-VAL-05 | `items` required array min:1 | FR |
| BC-VAL-06 | `items.*.item_id` required integer exists:inv_stock_items,id | FR |
| BC-VAL-07 | `items.*.qty` required numeric min:0.001 | FR |
| BC-VAL-08 | `items.*.uom_id` required integer exists:inv_units_of_measure,id | FR |
| BC-VAL-09 | `items.*.estimated_rate` nullable numeric min:0 | FR |
| BC-VAL-10 | `items.*.remarks` nullable string max:255 | FR |

### BC-AUTH — Authorization (PurchaseRequisitionPolicy)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | index gate `tenant.inventory.pr.viewAny` | Policy |
| BC-AUTH-02 | create/store gate `tenant.inventory.pr.create` | Policy |
| BC-AUTH-03 | show gate `tenant.inventory.pr.view` | Policy |
| BC-AUTH-04 | edit/update/submit gate `tenant.inventory.pr.update` | Policy |
| BC-AUTH-05 | destroy/trashed/restore/forceDelete gate `tenant.inventory.pr.delete` | Policy |
| BC-AUTH-06 | approve gate `tenant.inventory.pr.approve` (separate permission) | Policy |
| BC-AUTH-07 | reject gate `tenant.inventory.pr.approve` (same approval permission) | Policy |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Procurement page: 4 tabs — PRs (default), Quotations, POs, GRNs | MenuCtrl |
| BC-BIZ-02 | PRs tab: card list — pr_number (linked), status badge (draft/submitted/approved/rejected), priority badge (low/normal/high/urgent), requested by, required date, items count, actions | View |
| BC-BIZ-03 | Create via modal: Required By Date (required, min today), Department select, Priority select (default Normal), Remarks, First Item section (item_id, qty, uom_id, estimated_rate). Alert: "After creating, add more items on the PR detail page." | View |
| BC-BIZ-04 | Store via PurchaseRequisitionService::create(): generates pr_number via PurchaseOrderService::generatePrNumber(), sets status=draft, creates nested items with sequential ordering, redirects to show page | Service |
| BC-BIZ-05 | Show page: PR header (number, status badge, priority badge, requested by, department, required date, remarks) + Items table (item name/SKU, UOM, qty, estimated rate, total) | View |
| BC-BIZ-06 | Submit: PurchaseRequisitionService::submit() guards status=draft (InvalidArgumentException if not), guards items count > 0 (DomainException if none). Sets status=submitted. Redirects back with success | Service |
| BC-BIZ-07 | Approve: PurchaseRequisitionService::approve() guards status=submitted (InvalidArgumentException if not). Sets status=approved, approved_by=auth_id, approved_at=now. Redirects back with success | Service |
| BC-BIZ-08 | Reject: PurchaseRequisitionService::reject() guards status=submitted (InvalidArgumentException if not). Sets status=rejected. Redirects back with success | Service |
| BC-BIZ-09 | Actions dropdown: Edit (draft only), Submit (draft only), Approve (submitted only), Reject (submitted only), Delete (draft only) | View |
| BC-BIZ-10 | Search: by pr_number/requester, filter by status (All/Draft/Submitted/Approved/Rejected) | View |
| BC-BIZ-11 | Empty state: "No Purchase Requisitions Found" with file-pen icon | View |
| BC-BIZ-12 | Pagination: appends tab=prs to pagination links | View |
| BC-BIZ-13 | Status lifecycle: draft → submitted → approved → (auto converted when PO created) or rejected. Draft→cancelled also possible | Service |
| BC-BIZ-14 | Soft Delete: only draft PRs can be deleted; submitted/approved/rejected cannot be deleted (guarded in service) | Service |
| BC-BIZ-15 | Approve/Reject buttons visible only with `tenant.inventory.pr.approve` permission | View |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Submit PR with no items → DomainException "PR has no items. Add items before submitting." | Service |
| BC-EDG-02 | Submit already-submitted PR → InvalidArgumentException | Service |
| BC-EDG-03 | Approve already-approved PR → InvalidArgumentException | Service |
| BC-EDG-04 | Approve draft (not submitted) PR → InvalidArgumentException | Service |
| BC-EDG-05 | Reject already-rejected PR → InvalidArgumentException | Service |
| BC-EDG-06 | Reject draft PR → InvalidArgumentException | Service |
| BC-EDG-07 | Delete submitted/approved/rejected PR → guarded in service (no explicit check in code but status guarded) | Service |
| BC-EDG-08 | required_date before today → validation error (on_or_after) | FR |
| BC-EDG-09 | Duplicate pr_number → unique DB constraint | DDL |
| BC-EDG-10 | Delete draft PR with items → cascade delete items | DDL |
| BC-EDG-11 | Invalid item_id → exists:inv_stock_items validation error | FR (cross-module) |
| BC-EDG-12 | Invalid uom_id → exists:inv_units_of_measure validation error | FR (cross-module) |
| BC-EDG-13 | Invalid department_id → exists:sch_departments validation error | FR (cross-module) |
| BC-EDG-14 | Est. rate with negative value → min:0 validation error | FR |

---

## 2. Test Case List

### Screen 1: Procurement Tab / PRs List (GET /inventory/procurement)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVPR-P10 | Positive | View | Combined page: 4 tabs — PRs (default active), Quotations, POs, GRNs | Tabs | test_inv_pr_10 | Automated |
| TC-INVPR-P11 | Positive | View | PRs tab: card list — pr_number (link), status badge (draft/submitted/approved/rejected), priority badge (low/normal/high/urgent), requested by, required date formatted, items count, actions | Rendered | test_inv_pr_11 | Automated |
| TC-INVPR-P12 | Positive | View | Search by pr_number/requester, filter by status dropdown (All/Draft/Submitted/Approved/Rejected) | Filters | test_inv_pr_12 | Automated |
| TC-INVPR-P13 | Positive | View | Create button opens modal with all fields (Required By Date, Department, Priority, Remarks, First Item section) | Modal | test_inv_pr_13 | Automated |
| TC-INVPR-P14 | Positive | View | Create modal: info alert about adding more items on detail page | Alert | test_inv_pr_14 | Automated |
| TC-INVPR-P15 | Positive | View | Empty state: "No Purchase Requisitions Found" with file-pen icon | Empty | test_inv_pr_15 | Automated |
| TC-INVPR-P16 | Positive | View | Pagination appends tab=prs query param | Paginated | test_inv_pr_16 | Automated |

### Screen 2: Create (Modal) + Store

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVPR-P30 | Positive | View | Create modal: Required By Date (required, min=today), Department select, Priority select (default Normal), Remarks, First Item section (item_id, qty, uom_id, estimated_rate) | Fields | test_inv_pr_30 | Automated |
| TC-INVPR-P31 | Positive | Ctrl | Valid store with 1 item: creates PR with generated pr_number, status=draft, items created, redirects to show | Created draft | test_inv_pr_31 | Automated |
| TC-INVPR-P32 | Positive | Ctrl | Store with priority=urgent → saved as urgent | Created | test_inv_pr_32 | Automated |
| TC-INVPR-P33 | Positive | Ctrl | Store with department set → saved | Created | test_inv_pr_33 | Automated |
| TC-INVPR-N34 | Negative | Val | Missing required_date → required error | Error | test_inv_pr_34 | Automated |
| TC-INVPR-N35 | Negative | Val | required_date before today → on_or_after error | Error | test_inv_pr_35 | Automated |
| TC-INVPR-N36 | Negative | Val | Missing priority → required error | Error | test_inv_pr_36 | Automated |
| TC-INVPR-N37 | Negative | Val | Invalid priority (e.g. "critical") → in:low,normal,high,urgent error | Error | test_inv_pr_37 | Automated |
| TC-INVPR-N38 | Negative | Val | No items (empty array) → items required min:1 error | Error | test_inv_pr_38 | Automated |
| TC-INVPR-N39 | Negative | Val | Invalid item_id → exists:inv_stock_items error | Error | test_inv_pr_39 | Automated |
| TC-INVPR-N40 | Negative | Val | Missing item qty → required error | Error | test_inv_pr_40 | Automated |
| TC-INVPR-N41 | Negative | Val | Zero item qty → min:0.001 error | Error | test_inv_pr_41 | Automated |
| TC-INVPR-N42 | Negative | Val | Invalid uom_id → exists:inv_units_of_measure error | Error | test_inv_pr_42 | Automated |
| TC-INVPR-N43 | Negative | Val | Negative estimated_rate → min:0 error | Error | test_inv_pr_43 | Automated |
| TC-INVPR-N44 | Negative | Val | remarks > 2000 chars → max error | Error | test_inv_pr_44 | Automated |
| TC-INVPR-N45 | Negative | Val | Invalid department_id → exists:sch_departments error | Error | test_inv_pr_45 | Automated |

### Screen 3: Show (GET /inventory/prs/{purchaseRequisition})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVPR-P60 | Positive | View | Show: PR header — pr_number, status badge, priority badge, requested by name, department, required_date formatted, remarks | Layout | test_inv_pr_60 | Automated |
| TC-INVPR-P61 | Positive | View | Items table: Item Name/SKU, UOM symbol, Qty, Estimated Rate (formatted ₹), Line Total, remarks | Table | test_inv_pr_61 | Automated |
| TC-INVPR-P62 | Positive | View | Action buttons based on status: Submit (draft), Edit (draft), Approve/Reject (submitted if permission), Delete (draft) | Conditional | test_inv_pr_62 | Automated |
| TC-INVPR-P63 | Positive | View | Empty items state: appropriate message if no items (unlikely as store requires min:1) | Empty | test_inv_pr_63 | Automated |

### Screen 4: Edit + Update

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVPR-P80 | Positive | View | Edit page: form pre-populated with existing PR data | Pre-filled | test_inv_pr_80 | Automated |
| TC-INVPR-P81 | Positive | Ctrl | Update draft PR fields → redirects with success | Updated | test_inv_pr_81 | Automated |
| TC-INVPR-N82 | Negative | Val | Update with invalid data → validation errors | Error | test_inv_pr_82 | Automated |

### Screen 5: Submit

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVPR-P100 | Positive | View | Submit button visible on draft PR card and show page | Visible | test_inv_pr_100 | Automated |
| TC-INVPR-P101 | Positive | Ctrl | Submit draft PR with items → status=submitted, redirects with success | Submitted | test_inv_pr_101 | Automated |
| TC-INVPR-N102 | Negative | Biz | Submit draft PR with NO items → DomainException, redirect with error | Blocked | test_inv_pr_102 | Automated |
| TC-INVPR-N103 | Negative | Biz | Submit already-submitted PR → InvalidArgumentException | Blocked | test_inv_pr_103 | Automated |
| TC-INVPR-N104 | Negative | Biz | Submit approved PR → InvalidArgumentException | Blocked | test_inv_pr_104 | Automated |
| TC-INVPR-N105 | Negative | Biz | Submit rejected PR → InvalidArgumentException | Blocked | test_inv_pr_105 | Automated |

### Screen 6: Approve

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVPR-P120 | Positive | View | Approve button visible on submitted PR (with approve permission) | Visible | test_inv_pr_120 | Automated |
| TC-INVPR-P121 | Positive | Ctrl | Approve submitted PR → status=approved, approved_by set, approved_at set, redirects with success | Approved | test_inv_pr_121 | Automated |
| TC-INVPR-N122 | Negative | Biz | Approve draft PR → InvalidArgumentException | Blocked | test_inv_pr_122 | Automated |
| TC-INVPR-N123 | Negative | Biz | Approve already-approved PR → InvalidArgumentException | Blocked | test_inv_pr_123 | Automated |
| TC-INVPR-N124 | Negative | Biz | Approve rejected PR → InvalidArgumentException | Blocked | test_inv_pr_124 | Automated |
| TC-INVPR-N125 | Negative | Auth | Approve without `tenant.inventory.pr.approve` permission → 403 | 403 | test_inv_pr_125 | Automated |

### Screen 7: Reject

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVPR-P140 | Positive | View | Reject button visible on submitted PR (with approve permission) | Visible | test_inv_pr_140 | Automated |
| TC-INVPR-P141 | Positive | Ctrl | Reject submitted PR → status=rejected, redirects with success | Rejected | test_inv_pr_141 | Automated |
| TC-INVPR-N142 | Negative | Biz | Reject draft PR → InvalidArgumentException | Blocked | test_inv_pr_142 | Automated |
| TC-INVPR-N143 | Negative | Biz | Reject already-rejected PR → InvalidArgumentException | Blocked | test_inv_pr_143 | Automated |
| TC-INVPR-N144 | Negative | Biz | Reject approved PR → InvalidArgumentException | Blocked | test_inv_pr_144 | Automated |
| TC-INVPR-N145 | Negative | Auth | Reject without `tenant.inventory.pr.approve` permission → 403 | 403 | test_inv_pr_145 | Automated |

### Screen 8: Delete (Guarded) + Soft Delete Lifecycle

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVPR-P160 | Positive | Ctrl | Delete draft PR → soft-deleted, items cascade deleted, redirects with success | Deleted | test_inv_pr_160 | Automated |
| TC-INVPR-N161 | Negative | Biz | Delete submitted/approved/rejected PR → blocked (status guard in service) | Blocked | test_inv_pr_161 | Automated |
| TC-INVPR-P162 | Positive | View | Trash page: table with PR Number, Status, Requested By, Deleted At, restore/force-delete actions | Table | test_inv_pr_162 | Automated |
| TC-INVPR-P163 | Positive | Ctrl | Restore from trash → success | Restored | test_inv_pr_163 | Automated |
| TC-INVPR-P164 | Positive | Ctrl | Force delete from trash → permanently deleted | Perm deleted | test_inv_pr_164 | Automated |

### Authorization Tests

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVPR-P200 | Positive | Auth | PR CRUD with correct permissions → 200 | 200 | test_inv_pr_200 | Automated |
| TC-INVPR-N201 | Negative | Auth | Without viewAny → 403 on tab | 403 | test_inv_pr_201 | Automated |
| TC-INVPR-N202 | Negative | Auth | Without create → 403 on store | 403 | test_inv_pr_202 | Automated |
| TC-INVPR-N203 | Negative | Auth | Without view → 403 on show | 403 | test_inv_pr_203 | Automated |
| TC-INVPR-N204 | Negative | Auth | Without update → 403 on edit/update/submit | 403 | test_inv_pr_204 | Automated |
| TC-INVPR-N205 | Negative | Auth | Without delete → 403 on destroy/trashed/restore/forceDelete | 403 | test_inv_pr_205 | Automated |
| TC-INVPR-N206 | Negative | Auth | Without approve permission → 403 on approve/reject | 403 | test_inv_pr_206 | Automated |
