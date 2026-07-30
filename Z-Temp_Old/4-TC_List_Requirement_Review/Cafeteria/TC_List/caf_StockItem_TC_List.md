# caf_StockItem — Test Case List & Business Conditions

**Module:** Cafeteria (CODE `CAF`, prefix `caf_`) · **Feature:** Stock Items (Raw Material Inventory + Reorder + Consumption Logging)
**DB scope:** TENANT-side (`caf_stock_items`, `caf_consumption_logs`) · **Test style:** Browser Dusk + API
**Primary table:** `caf_stock_items` · **Module URL prefix:** `/cafeteria/stock-compliance?tab=stock`
**Test file:** `caf_StockItem_TestCas.php`
**Tab:** Stock Items (first tab of Stock & Compliance)

Controllers:
- `StockController` — index (redirect), create, store, show, edit, update, destroy, logConsumption, checkReorder, toggleStatus, trashed, restore, forceDelete
- `CafeteriaController::stockCompliance()` — loads stock items + low stock for tabbed page

Service:
- `StockService` — logConsumption (atomic deduction + reorder check), checkReorderLevels, dispatchReorderAlert

Routes (`cafeteria.` prefix):
- `GET /cafeteria/stock-compliance` — tabbed page (stock tab)
- `GET /cafeteria/stock/create` — create page
- `POST /cafeteria/stock` — store
- `GET /cafeteria/stock/{stockItem}` — show (with consumption logs)
- `GET /cafeteria/stock/{stockItem}/edit` — edit
- `PUT /cafeteria/stock/{stockItem}` — update
- `DELETE /cafeteria/stock/{stockItem}` — destroy
- `POST /cafeteria/stock/{stockItem}/consume` — log consumption
- `POST /cafeteria/stock/check-reorder` — check + dispatch reorder alerts
- `GET /cafeteria/stock/trashed` — trashed items
- `POST /cafeteria/stock/{stockItem}/toggle-status` — Ajax status toggle

**DDL reference:** `caf_stock_items`, `caf_consumption_logs` (Cafeteria DDL)

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `caf_stock_items`: id (INT UNSIGNED PK AI), supplier_id (INT UNSIGNED NULL FK → caf_suppliers.id ON DELETE SET NULL), name (VARCHAR 150 NOT NULL), category (ENUM('Grains','Pulses','Vegetables','Fruits','Dairy','Spices','Beverages','Condiments','Cleaning','Other') NOT NULL), unit (VARCHAR 20 NOT NULL), current_quantity (DECIMAL 12,3 DEFAULT 0), reorder_level (DECIMAL 12,3 NOT NULL DEFAULT 0), reorder_quantity (DECIMAL 12,3 NULL), cost_per_unit (DECIMAL 10,2 NULL), is_active (TINYINT 1 DEFAULT 1), created_by, created_at, updated_at, deleted_at. Index: idx_caf_si_supplier, idx_caf_si_category | DDL |
| BC-DB-02 | Table `caf_consumption_logs`: id (INT UNSIGNED PK AI), stock_item_id (INT UNSIGNED FK → caf_stock_items.id ON DELETE CASCADE), log_date (DATE NOT NULL), quantity_used (DECIMAL 12,3 NOT NULL), meal_category_id (INT UNSIGNED NULL FK → caf_menu_categories.id ON DELETE SET NULL), notes (VARCHAR 255 NULL), created_by, created_at, updated_at. No SoftDeletes. Index: idx_caf_cl_item, idx_caf_cl_date | DDL |
| BC-DB-03 | Model `StockItem`: table caf_stock_items, SoftDeletes, fillable 10 fields, casts: current_quantity→decimal:3, reorder_level→decimal:3, reorder_quantity→decimal:3, cost_per_unit→decimal:2, is_active→boolean. Scopes: active(), lowStock(). Relations: supplier() belongsTo, consumptionLogs() hasMany | Model |
| BC-DB-04 | Model `ConsumptionLog`: table caf_consumption_logs, no SoftDeletes, fillable 5 fields, casts: log_date→date, quantity_used→decimal:3. Relations: stockItem() belongsTo, mealCategory() belongsTo | Model |

### BC-VAL — Validation (StoreStockItemRequest)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `supplier_id` nullable integer exists:caf_suppliers,id | FR |
| BC-VAL-02 | `name` required string max:150 | FR |
| BC-VAL-03 | `category` required in:Grains,Pulses,Vegetables,Fruits,Dairy,Spices,Beverages,Condiments,Cleaning,Other | FR |
| BC-VAL-04 | `unit` required string max:20 | FR |
| BC-VAL-05 | `current_quantity` nullable numeric min:0 | FR |
| BC-VAL-06 | `reorder_level` required numeric min:0 | FR |
| BC-VAL-07 | `reorder_quantity` nullable numeric min:0 | FR |
| BC-VAL-08 | `cost_per_unit` nullable numeric min:0 | FR |
| BC-VAL-09 | `is_active` nullable boolean | FR |

### BC-VAL — Validation (LogConsumptionRequest)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-10 | `log_date` required date | FR |
| BC-VAL-11 | `quantity_used` required numeric min:0.001 | FR |
| BC-VAL-12 | `meal_category_id` nullable integer exists:caf_menu_categories,id | FR |
| BC-VAL-13 | `notes` nullable string max:255 | FR |

### BC-AUTH — Authorization (StockItemPolicy)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Tab visible gate `cafeteria.stock` (viewAny) — note: policy uses `cafeteria.stock.item.viewAny` | View |
| BC-AUTH-02 | create/store gate `cafeteria.stock.item.create` | Policy |
| BC-AUTH-03 | show/view gate `cafeteria.stock.item.view` | Policy |
| BC-AUTH-04 | update/consume/toggle-status gate `cafeteria.stock.item.update` | Policy |
| BC-AUTH-05 | delete gate `cafeteria.stock.item.delete` | Policy |
| BC-AUTH-06 | Status column visibility gate `cafeteria.stock.update` | View |
| BC-AUTH-07 | Action column visibility gate `cafeteria.stock.update` or `cafeteria.stock.delete` | View |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Stock tab: paginated table with Item Name, Category, Supplier, On Hand, Reorder Level, Status toggle, Actions | View |
| BC-BIZ-02 | Search: by item name | View |
| BC-BIZ-03 | Status filter: All / Active (1) / Inactive (0) | View |
| BC-BIZ-04 | On Hand column shows numeric qty with unit, turns red + warning icon if ≤ reorder_level | View |
| BC-BIZ-05 | Low-stock warning banner at top: count + item names + "Alert Procurement" button | View |
| BC-BIZ-06 | "Alert Procurement" button → POST /check-reorder → dispatches alerts for all low-stock items | Ctrl |
| BC-BIZ-07 | Consumption modal: quantity_used required, meal_category optional, date defaults today, notes optional | View |
| BC-BIZ-08 | Log consumption: atomic transaction — create ConsumptionLog + deduct current_quantity | Service |
| BC-BIZ-09 | If consumption reduces qty ≤ reorder_level → dispatchReorderAlert called automatically | Service |
| BC-BIZ-10 | Status toggle: Ajax POST → flips is_active, returns JSON {success, message} | Ctrl |
| BC-BIZ-11 | Soft delete: destroy() sets deleted_at | Ctrl |
| BC-BIZ-12 | Activity logged for: create, update, delete, consume, toggle status | Ctrl |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Consume quantity > current_quantity → qty set to 0 (floored at 0, not negative) | Service |
| BC-EDG-02 | Consume 0.001 (minimum valid) → min:0.001 validation | Val |
| BC-EDG-03 | No stock items → empty state "No stock items added." with icon | View |
| BC-EDG-04 | Delete already-deleted stock item → 404 (SoftDeletes) | Ctrl |
| BC-EDG-05 | Inactive item still shows in table (filtered by status select) | View |

---

## 2. Test Case List

### Screen 1: Stock Items Tab (GET /cafeteria/stock-compliance?tab=stock)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFSI-P10 | Positive | View | Stock tab: table with Item Name, Category, Supplier, On Hand, Reorder Level, Status toggle, Actions | Rendered | test_caf_si_10 | Automated |
| TC-CAFSI-P11 | Positive | View | Search filters by item name | Search | test_caf_si_11 | Automated |
| TC-CAFSI-P12 | Positive | View | Status filter: All / Active / Inactive | Filters | test_caf_si_12 | Automated |
| TC-CAFSI-P13 | Positive | View | Low-stock items show red quantity + warning icon | Low-stock indicator | test_caf_si_13 | Automated |
| TC-CAFSI-P14 | Positive | View | Empty state "No stock items added." when empty | Empty | test_caf_si_14 | Automated |
| TC-CAFSI-P15 | Positive | View | Paginated 15 per page | Paginated | test_caf_si_15 | Automated |

### Screen 2: Low-Stock Alert Banner

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFSI-P30 | Positive | Biz | Low-stock items exist → yellow alert with count + names + "Alert Procurement" button | Banner shown | test_caf_si_30 | Automated |
| TC-CAFSI-P31 | Positive | Biz | No low-stock items → no banner | Banner hidden | test_caf_si_31 | Automated |
| TC-CAFSI-P32 | Positive | Ctrl | Click "Alert Procurement" → POST /check-reorder → success message "Reorder check complete. N alert(s) dispatched." | Alerted | test_caf_si_32 | Automated |

### Screen 3: Consumption Logging (POST /cafeteria/stock/{stockItem}/consume)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFSI-P50 | Positive | Service | Log consumption → ConsumptionLog created, current_quantity deducted | Consumed | test_caf_si_50 | Automated |
| TC-CAFSI-P51 | Positive | Service | Consumption reduces qty ≤ reorder_level → dispatchReorderAlert triggered | Alerted | test_caf_si_51 | Automated |
| TC-CAFSI-P52 | Positive | Service | Consume with meal_category_id → logged, linked to category | Category linked | test_caf_si_52 | Automated |
| TC-CAFSI-P53 | Positive | Service | Consume 5 units when current=3 → new qty=0 (floored, not negative) | Floored to 0 | test_caf_si_53 | Automated |
| TC-CAFSI-N54 | Negative | Val | Consume with empty quantity → validation error | Error | test_caf_si_54 | Automated |
| TC-CAFSI-N55 | Negative | Val | Consume with invalid meal_category_id → validation error | Error | test_caf_si_55 | Automated |
| TC-CAFSI-N56 | Negative | Val | Consume with quantity = 0 → min:0.001 validation error | Error | test_caf_si_56 | Automated |

### Screen 4: CRUD + Status Toggle

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFSI-P70 | Positive | Ctrl | Create stock item → stored, redirect with "Stock item created." | Created | test_caf_si_70 | Automated |
| TC-CAFSI-P71 | Positive | Ctrl | Update stock item → updated, redirect with "Stock item updated." | Updated | test_caf_si_71 | Automated |
| TC-CAFSI-P72 | Positive | Ctrl | Soft delete stock item → deleted, trashed view | Deleted | test_caf_si_72 | Automated |
| TC-CAFSI-P73 | Positive | Ctrl | Toggle status active/inactive → Ajax JSON success | Toggled | test_caf_si_73 | Automated |

### Authorization Tests

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFSI-P200 | Positive | Auth | CRUD with correct permissions → 200 | 200 | test_caf_si_200 | Automated |
| TC-CAFSI-N201 | Negative | Auth | Without viewAny → tab hidden | Hidden | test_caf_si_201 | Automated |
| TC-CAFSI-N202 | Negative | Auth | Without create → 403 on store | 403 | test_caf_si_202 | Automated |
| TC-CAFSI-N203 | Negative | Auth | Without update → 403 on edit/consume/toggle | 403 | test_caf_si_203 | Automated |
| TC-CAFSI-N204 | Negative | Auth | Without delete → 403 on destroy | 403 | test_caf_si_204 | Automated |
