# Stock Items — Requirements

## Parent Tab: Stock & Compliance

## What It Does
Raw material inventory management with reorder threshold alerts and atomic consumption deduction. Materials are categorized by type (Grains, Vegetables, Dairy, etc.) with unit tracking.

## Tables Covered

1. `caf_stock_items` — Raw material inventory with reorder levels
2. `caf_consumption_logs` — Daily usage log with atomic stock deduction

---

## Entity: Stock Items (`caf_stock_items`)

### Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | INT UNSIGNED PK | Auto-increment. |
| `supplier_id` | INT UNSIGNED FK → caf_suppliers | Nullable. Preferred supplier. ON DELETE SET NULL. |
| `name` | VARCHAR(150) | Required. Raw material name. |
| `category` | ENUM('Grains','Pulses','Vegetables','Fruits','Dairy','Spices','Beverages','Condiments','Cleaning','Other') | Required. |
| `unit` | VARCHAR(20) | Required. kg, litre, piece, dozen. |
| `current_quantity` | DECIMAL(10,3) | Default 0.000. Updated by StockService. |
| `reorder_level` | DECIMAL(10,3) | Required. Alert threshold. |
| `reorder_quantity` | DECIMAL(10,3) | Nullable. Suggested purchase qty for INV bridge. |
| `cost_per_unit` | DECIMAL(8,2) | Nullable. Cost in INR. |
| `is_active` | TINYINT(1) | Default 1. |
| `created_by` | INT UNSIGNED FK → sys_users | Nullable. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |
| `deleted_at` | TIMESTAMP | Nullable. Soft delete. |

### Business Rules

#### Field-Level Validation

| Field | Rule | Error Message / Behavior |
|---|---|---|
| `name` | Required, string, max:150 | |
| `category` | Required, enum | |
| `unit` | Required, string, max:20 | |
| `current_quantity` | Read-only | Never accepted from user input. Updated by StockService only. |
| `reorder_level` | Required, numeric, min:0 | |
| `reorder_quantity` | Nullable, numeric, min:0 | |
| `cost_per_unit` | Nullable, numeric, min:0 | Informational. |

#### Atomic Stock Level Update

Consumption deduction flow:
1. `BEGIN TRANSACTION`
2. `SELECT * FROM caf_stock_items WHERE id = X FOR UPDATE`
3. `new_quantity = current_quantity - quantity_used`
4. Guard: new_quantity < 0: "Insufficient stock. Available: {current_quantity}, Required: {quantity_used}."
5. `UPDATE caf_stock_items SET current_quantity = new_quantity`
6. `INSERT INTO caf_consumption_logs` (stock_item_id, quantity_used, ...)
7. `COMMIT`

#### Reorder Alert (BR-CAF-007)

- When `current_quantity <= reorder_level` after an update: send notification via NTF module.
- Message: "Stock item '{name}' has reached reorder level ({current_quantity} {unit}). Recommended reorder quantity: {reorder_quantity} {unit}."
- If `reorder_quantity` is NULL, recommendation omitted.
- Check runs synchronously on consumption + nightly via `CheckStockReorderCommand`.

#### Unit Consistency

- Same `name` should use same `unit` (operational practice, not DB enforced).

#### Soft Delete

- Standard. Sets `is_active = 0`.

#### List View

- Controller: StockController@index. Gate: `tenant.cafeteria.stock.viewAny`.
- Low-stock alert banner at top when items below reorder level.
- Columns: Name, Category, Unit, Current Qty, Reorder Level, Supplier, Cost/Unit, Status, Actions.
- Actions: Edit, Show (with consumption log), Log Consumption (modal), Delete.

---

## Entity: Consumption Logs (`caf_consumption_logs`)

### Database Fields

| Field | Type | Conditions |
|---|---|---|
| `id` | INT UNSIGNED PK | Auto-increment. |
| `stock_item_id` | INT UNSIGNED FK → caf_stock_items | Required. ON DELETE RESTRICT. |
| `log_date` | DATE | Required. |
| `quantity_used` | DECIMAL(10,3) | Required. |
| `meal_category_id` | INT UNSIGNED FK → caf_menu_categories | Nullable. Which meal. ON DELETE SET NULL. |
| `notes` | VARCHAR(255) | Nullable. |
| `created_by` | INT UNSIGNED FK → sys_users | Nullable. |
| `created_at` / `updated_at` | TIMESTAMP | Laravel standard. |

### Business Rules

- No `is_active`, no `deleted_at`: immutable usage log.
- `quantity_used` must be > 0. Error: "Quantity used must be greater than zero."
- Created within same transaction as stock deduction.
- No DELETE or UPDATE. Corrections via admin-only reversal entry with audit trail.
- Embedded in Stock Item show page — no separate index view.

## Permissions

| Operation | Permission Key |
|---|---|
| CRUD | `tenant.cafeteria.stock-item.*` |
| Consumption — Create/View | `tenant.cafeteria.consumption-log.*` |
