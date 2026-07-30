# inv_Asset — Test Case List & Business Conditions

**Module:** Inventory (CODE `INV`, prefix `inv_`) · **Feature:** Assets (Register + Lifecycle + Maintenance)
**DB scope:** TENANT-side (`inv_assets`, `inv_asset_maintenance`, `inv_asset_movements`) · **Test style:** Browser Dusk
**Primary table:** `inv_assets` · **Module URL prefix:** `/inventory/assets-page`
**Test file:** `inv_Asset_TestCas.php`
**Tabs:** Asset Register (default) + Maintenance Schedule

Controllers:
- `AssetController` — CRUD + transfer + dispose + maintenance + printTag
- `InvMenuController::assetsPage()` — loads assets + maintenances for tabbed page

Service:
- `AssetService` — create, update (guarded: disposed), transfer, dispose

Event/Listener:
- `GrnAccepted` → `CreateAssetFromGrn` (auto-create assets from GRN with item_type=asset)
- `AssetDisposed` → job to notify Accounting

Routes (`inventory.` prefix):
- `GET /inventory/assets-page` — tabbed assets page (register + maintenance)
- `GET /inventory/assets` — index (redirects to assets-page)
- `POST /inventory/assets` — store
- `GET /inventory/assets/{asset}` — show (details + movements + maintenance tabs)
- `GET /inventory/assets/{asset}/edit` — edit
- `PUT /inventory/assets/{asset}` — update
- `DELETE /inventory/assets/{asset}` — soft delete
- `POST /inventory/assets/{asset}/transfer` — transfer (godown/employee)
- `POST /inventory/assets/{asset}/dispose` — dispose (reason, date)
- `POST /inventory/assets/{asset}/maintenance` — add maintenance record
- `DELETE /inventory/assets/{asset}/maintenance/{maintenance}` — delete maintenance record
- `GET /inventory/assets/{asset}/print-tag` — printable tag view
- `GET /inventory/assets/trash/view` — trashed
- `GET /inventory/assets/{id}/restore` — restore
- `DELETE /inventory/assets/{id}/force-delete` — force delete

**DDL reference:** `inv_assets`, `inv_asset_maintenance`, `inv_asset_movements` (Layer 2, Inventory DDL)

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `inv_assets`: id (BIGINT PK AI), asset_tag (VARCHAR 50 UNIQUE NOT NULL), asset_name (VARCHAR 100 NOT NULL), asset_category_id (BIGINT UNSIGNED FK → inv_asset_categories), stock_item_id (BIGINT UNSIGNED FK → inv_stock_items), grn_item_id (BIGINT UNSIGNED NULL FK → inv_grn_items), supplier (VARCHAR 255 NULL), serial_no (VARCHAR 100 NULL), model_no (VARCHAR 100 NULL), purchase_date (DATE), purchase_cost (DECIMAL 15,2), current_book_value (DECIMAL 15,2 NULL), acc_fixed_asset_id (BIGINT UNSIGNED NULL FK → acc_fixed_assets), godown_id (BIGINT UNSIGNED NULL FK → inv_godowns), assigned_employee_id (INT UNSIGNED NULL FK → sch_employees), condition (ENUM('good','fair','poor','under_repair','disposed') DEFAULT 'good'), warranty_expiry_date (DATE NULL), disposed_at (DATETIME NULL), disposed_reason (TEXT NULL), is_active (TINYINT 1 DEFAULT 1), created_by, updated_by, created_at, updated_at, deleted_at. Indexes: uq_inv_asset_tag, idx_inv_ast_asset_category_id, idx_inv_ast_stock_item_id, idx_inv_ast_grn_item_id, idx_inv_ast_godown_id, idx_inv_ast_assigned_employee_id, idx_inv_ast_condition, idx_inv_ast_is_active | DDL |
| BC-DB-02 | Table `inv_asset_maintenance`: id (BIGINT PK AI), asset_id (BIGINT UNSIGNED FK → inv_assets ON DELETE CASCADE), maintenance_date (DATE NOT NULL), maintenance_type (ENUM('preventive','corrective','amc','calibration') NOT NULL), vendor_id (INT UNSIGNED NULL FK → vnd_vendors), cost (DECIMAL 15,2 NULL), notes (TEXT NULL), next_due_date (DATE NULL), status (ENUM('scheduled','completed','overdue') DEFAULT 'scheduled'), is_active, created_by, updated_by, created_at, updated_at, deleted_at. Indexes: idx_inv_amnt_asset_id, idx_inv_amnt_vendor_id, idx_inv_amnt_status, idx_inv_amnt_next_due_date, idx_inv_amnt_maint_date | DDL |
| BC-DB-03 | Table `inv_asset_movements`: id (BIGINT PK AI), asset_id (BIGINT UNSIGNED FK → inv_assets ON DELETE CASCADE), movement_date (DATE NOT NULL), from_godown_id (BIGINT UNSIGNED NULL FK → inv_godowns), to_godown_id (BIGINT UNSIGNED NULL FK → inv_godowns), from_employee_id (INT UNSIGNED NULL FK → sch_employees), to_employee_id (INT UNSIGNED NULL FK → sch_employees), reason (VARCHAR 500 NULL), moved_by (BIGINT UNSIGNED), is_active, created_by, updated_by, created_at, updated_at, deleted_at. Indexes: idx_inv_amov_asset_id, idx_inv_amov_from_godown_id, idx_inv_amov_to_godown_id, idx_inv_amov_from_employee_id, idx_inv_amov_to_employee_id, idx_inv_amov_moved_by, idx_inv_amov_movement_date | DDL |
| BC-DB-04 | Model `Asset`: table inv_assets, SoftDeletes, fillable 18 fields, casts: purchase_date→date, warranty_expiry→date, purchase_cost→decimal:12:2, disposed_at→datetime, is_active→boolean, condition→string. Relations: category() belongsTo AssetCategory, stockItem() belongsTo StockItem, grnItem() belongsTo GrnItem, godown() belongsTo Godown, employee() belongsTo Employee, movements() hasMany AssetMovement, maintenanceRecords() hasMany AssetMaintenance | Model |

### BC-VAL — Validation (StoreAssetRequest)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `asset_name` required string max:100 | FR |
| BC-VAL-02 | `asset_tag` nullable string max:50, unique:inv_assets,asset_tag | FR |
| BC-VAL-03 | `category_id` required integer exists:inv_asset_categories,id | FR |
| BC-VAL-04 | `stock_item_id` nullable integer exists:inv_stock_items,id | FR |
| BC-VAL-05 | `supplier` nullable string max:255 | FR |
| BC-VAL-06 | `serial_no` nullable string max:100 | FR |
| BC-VAL-07 | `model_no` nullable string max:100 | FR |
| BC-VAL-08 | `purchase_date` required date | FR |
| BC-VAL-09 | `purchase_cost` required numeric min:0 | FR |
| BC-VAL-10 | `warranty_expiry` nullable date | FR |
| BC-VAL-11 | `tag_color` nullable string max:20 | FR |
| BC-VAL-12 | `condition` required string in:good,fair,poor,under_repair,disposed | FR |
| BC-VAL-13 | `godown_id` nullable integer exists:inv_godowns,id | FR |

### BC-VAL — Validation (UpdateAssetRequest)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-20 | `asset_name` required string max:100 | FR |
| BC-VAL-21 | `asset_tag` nullable string max:50, unique:inv_assets,asset_tag (ignores own ID) | FR |
| BC-VAL-22 | `category_id` required integer exists:inv_asset_categories,id | FR |
| BC-VAL-23 | `condition` required string in:good,fair,poor,under_repair,disposed | FR |
| BC-VAL-24 | `purchase_date` required date | FR |
| BC-VAL-25 | `purchase_cost` required numeric min:0 | FR |
| BC-VAL-26 | `godown_id` nullable integer exists:inv_godowns,id | FR |
| BC-VAL-27 | `employee_id` nullable integer exists:sch_employees,id | FR |

### BC-AUTH — Authorization (AssetPolicy)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | index gate `tenant.inventory.asset.viewAny` | Policy |
| BC-AUTH-02 | create/store gate `tenant.inventory.asset.create` | Policy |
| BC-AUTH-03 | show gate `tenant.inventory.asset.view` | Policy |
| BC-AUTH-04 | edit/update/transfer/dispose gate `tenant.inventory.asset.update` | Policy |
| BC-AUTH-05 | destroy/restore/forceDelete gate `tenant.inventory.asset.delete` | Policy |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Assets page loads 2 tabs: Asset Register and Maintenance Schedule | MenuCtrl |
| BC-BIZ-02 | Asset Register: paginated 20, card list with asset tag, name, category, condition badge, godown/employee, serial, purchase cost | View |
| BC-BIZ-03 | Asset Register: search by asset_tag/asset_name/serial_no, filter by category (dropdown from assetCategories), filter by condition/status | View |
| BC-BIZ-04 | Maintenance Schedule: paginated 20, table with asset tag, type, vendor, cost, dates, status with status filter | View |
| BC-BIZ-05 | Store: if asset_tag null → auto-generate ASSET-YYYY-NNNNN via AssetService::generateAssetTag() | Service |
| BC-BIZ-06 | Store: creates via AssetService::create() with auth user, logs activity | Service |
| BC-BIZ-07 | Update: updates via AssetService::update(), logs activity | Service |
| BC-BIZ-08 | Update: blocked if disposed (condition=disposed) → DomainException | Service |
| BC-BIZ-09 | Show page: 3 tabs — Details (full info), Movements (table), Maintenance (table) | View |
| BC-BIZ-10 | Transfer: POST to /assets/{asset}/transfer, sets new godown/employee, logs AssetMovement, logs activity | Service |
| BC-BIZ-11 | Transfer: requires at least godown_id or employee_id to differ from current | Service |
| BC-BIZ-12 | Dispose: POST to /assets/{asset}/dispose, sets condition=disposed, disposed_at, disposed_reason, fires AssetDisposed event, dispatches accounting job | Service |
| BC-BIZ-13 | Maintenance: POST to /assets/{asset}/maintenance creates record, DELETE to /assets/{asset}/maintenance/{id} deletes it | Ctrl |
| BC-BIZ-14 | Print Tag: GET /assets/{asset}/print-tag renders printable label view | Ctrl |
| BC-BIZ-15 | GRN Auto-Creation: when GRN accepted and stockItem.item_type=asset, CreateAssetFromGrn listener creates 1 asset per integer unit | Event |
| BC-BIZ-16 | Soft delete lifecycle: trash view, restore, force delete | Ctrl |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Update disposed asset → DomainException (blocked) | Service |
| BC-EDG-02 | Transfer to same godown/employee → no movement created (or blocked) | Service |
| BC-EDG-03 | Duplicate asset_tag → unique validation error | FR |
| BC-EDG-04 | Auto-generated tag collision → generateAssetTag retries with next sequence | Service |
| BC-EDG-05 | GRN qty=3 with item_type=asset → creates 3 assets with sequential tags | Event |
| BC-EDG-06 | Delete maintenance record that doesn't belong to asset → 404 or auth error | Ctrl |
| BC-EDG-07 | purchase_cost negative → min:0 validation error | FR |
| BC-EDG-08 | condition not in enum → validation error | FR |

---

## 2. Test Case List

### Screen 1: Assets Page — Asset Register Tab (GET /inventory/assets-page)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVAS-P10 | Positive | View | Assets page renders 2 tabs: Asset Register (active) and Maintenance Schedule | Tabs visible | test_inv_as_10 | Automated |
| TC-INVAS-P11 | Positive | View | Asset Register: card list with asset tag, name, category, condition badge, godown/employee, serial, purchase cost | Rendered | test_inv_as_11 | Automated |
| TC-INVAS-P12 | Positive | View | Search by asset_tag/asset_name/serial_no, filter by category dropdown, filter by condition | Filters | test_inv_as_12 | Automated |
| TC-INVAS-P13 | Positive | View | Create asset button opens create form/page | Form | test_inv_as_13 | Automated |
| TC-INVAS-P14 | Positive | View | Empty state when no assets exist | Empty | test_inv_as_14 | Automated |

### Screen 2: Assets Page — Maintenance Schedule Tab

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVAS-P20 | Positive | View | Maintenance Schedule tab: table with asset tag, type, vendor, cost, maintenance_date, next_due_date, status | Table | test_inv_as_20 | Automated |
| TC-INVAS-P21 | Positive | View | Maintenance filter by status (All/Scheduled/Completed/Overdue) | Filter | test_inv_as_21 | Automated |
| TC-INVAS-P22 | Positive | View | Empty state when no maintenance records | Empty | test_inv_as_22 | Automated |

### Screen 3: Create + Store Asset

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVAS-P30 | Positive | View | Create form: all fields present (name, tag, category, serial, model, purchase date/cost, warranty, godown, employee, condition, color) | Fields | test_inv_as_30 | Automated |
| TC-INVAS-P31 | Positive | Ctrl | Valid store with auto-generated tag → creates, logs activity | Created | test_inv_as_31 | Automated |
| TC-INVAS-P32 | Positive | Ctrl | Valid store with manual tag → creates with provided tag | Created | test_inv_as_32 | Automated |
| TC-INVAS-N33 | Negative | Val | Missing asset_name → required error | Error | test_inv_as_33 | Automated |
| TC-INVAS-N34 | Negative | Val | asset_name > 100 chars → max error | Error | test_inv_as_34 | Automated |
| TC-INVAS-N35 | Negative | Val | Duplicate asset_tag → unique error | Error | test_inv_as_35 | Automated |
| TC-INVAS-N36 | Negative | Val | Missing category_id → required error | Error | test_inv_as_36 | Automated |
| TC-INVAS-N37 | Negative | Val | Invalid category_id → exists error | Error | test_inv_as_37 | Automated |
| TC-INVAS-N38 | Negative | Val | Missing purchase_date → required error | Error | test_inv_as_38 | Automated |
| TC-INVAS-N39 | Negative | Val | Missing purchase_cost → required error | Error | test_inv_as_39 | Automated |
| TC-INVAS-N40 | Negative | Val | purchase_cost negative → min:0 error | Error | test_inv_as_40 | Automated |
| TC-INVAS-N41 | Negative | Val | Invalid condition value → in:good,fair,poor,under_repair,disposed error | Error | test_inv_as_41 | Automated |

### Screen 4: Show Asset (GET /inventory/assets/{asset})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVAS-P50 | Positive | View | Show page: 3 tabs — Details, Movements, Maintenance | Tabs | test_inv_as_50 | Automated |
| TC-INVAS-P51 | Positive | View | Details tab: full asset info (tag, name, category, serial, model, purchase, warranty, condition, godown, employee) | Info | test_inv_as_51 | Automated |
| TC-INVAS-P52 | Positive | View | Movements tab: table with from/to godown/employee, reason, moved_by, moved_at | Table | test_inv_as_52 | Automated |
| TC-INVAS-P53 | Positive | View | Maintenance tab: table with type, vendor, cost, dates, status | Table | test_inv_as_53 | Automated |
| TC-INVAS-P54 | Positive | View | Show page has action buttons: Transfer, Dispose, Add Maintenance, Print Tag | Actions | test_inv_as_54 | Automated |

### Screen 5: Edit + Update Asset

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVAS-P70 | Positive | View | Edit page: form pre-populated with existing data | Pre-filled | test_inv_as_70 | Automated |
| TC-INVAS-P71 | Positive | Ctrl | Update changes fields, logs activity | Updated | test_inv_as_71 | Automated |
| TC-INVAS-P72 | Positive | Ctrl | Update with same asset_tag → allowed (unique ignore) | Allowed | test_inv_as_72 | Automated |
| TC-INVAS-N73 | Negative | Biz | Update disposed asset → DomainException blocked | Blocked | test_inv_as_73 | Automated |

### Screen 6: Transfer Asset

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVAS-P90 | Positive | View | Transfer modal: godown select, employee select, reason textarea | Modal | test_inv_as_90 | Automated |
| TC-INVAS-P91 | Positive | Ctrl | Transfer to new godown → godown_id updated, AssetMovement created, activity logged | Transferred | test_inv_as_91 | Automated |
| TC-INVAS-P92 | Positive | Ctrl | Transfer to new employee → employee_id updated, AssetMovement created | Transferred | test_inv_as_92 | Automated |
| TC-INVAS-P93 | Positive | Ctrl | Transfer both godown+employee → both updated | Transferred | test_inv_as_93 | Automated |
| TC-INVAS-N94 | Negative | Biz | Transfer with no changes → validation error or no movement created | Blocked | test_inv_as_94 | Automated |

### Screen 7: Dispose Asset

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVAS-P110 | Positive | View | Dispose modal: reason textarea, disposed_at date picker | Modal | test_inv_as_110 | Automated |
| TC-INVAS-P111 | Positive | Ctrl | Dispose with reason → condition=disposed, disposed_at set, AssetDisposed event fired, activity logged | Disposed | test_inv_as_111 | Automated |
| TC-INVAS-P112 | Positive | Ctrl | Disposed asset appears with "Disposed" badge and locked state | Locked | test_inv_as_112 | Automated |

### Screen 8: Maintenance CRUD

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVAS-P130 | Positive | View | Add Maintenance modal: type, vendor, cost, description, maintenance_date, next_due_date, status | Modal | test_inv_as_130 | Automated |
| TC-INVAS-P131 | Positive | Ctrl | Create maintenance record → appears on Maintenance tab and Maintenance Schedule page | Created | test_inv_as_131 | Automated |
| TC-INVAS-P132 | Positive | Ctrl | Delete maintenance record → removed | Deleted | test_inv_as_132 | Automated |

### Screen 9: Print Tag

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVAS-P150 | Positive | View | Print Tag renders printable label with asset tag, name, category, tag_color | Printable | test_inv_as_150 | Automated |

### Screen 10: GRN Auto-Creation

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVAS-P170 | Positive | Event | GRN accepted with stockItem.item_type=asset, qty=3 → 3 assets created with sequential tags | 3 assets | test_inv_as_170 | Automated |
| TC-INVAS-P171 | Positive | Event | GRN accepted with stockItem.item_type=consumable → no assets created | 0 assets | test_inv_as_171 | Automated |

### Screen 11: Soft Delete Lifecycle

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVAS-P190 | Positive | Ctrl | Delete asset → soft-deleted, appears in trash | Deleted | test_inv_as_190 | Automated |
| TC-INVAS-P191 | Positive | View | Trash page: deleted records with restore/force-delete actions | Table | test_inv_as_191 | Automated |
| TC-INVAS-P192 | Positive | Ctrl | Restore from trash, logs 'Restored' | Restored | test_inv_as_192 | Automated |
| TC-INVAS-P193 | Positive | Ctrl | Force delete from trash, logs 'Deleted' | Perm deleted | test_inv_as_193 | Automated |

### Authorization Tests

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-INVAS-P200 | Positive | Auth | CRUD with correct permissions → 200 | 200 | test_inv_as_200 | Automated |
| TC-INVAS-N201 | Negative | Auth | Without viewAny → 403 on assets page | 403 | test_inv_as_201 | Automated |
| TC-INVAS-N202 | Negative | Auth | Without create → 403 on store | 403 | test_inv_as_202 | Automated |
| TC-INVAS-N203 | Negative | Auth | Without update → 403 on update/transfer/dispose | 403 | test_inv_as_203 | Automated |
| TC-INVAS-N204 | Negative | Auth | Without delete → 403 on destroy/restore/forceDelete | 403 | test_inv_as_204 | Automated |
