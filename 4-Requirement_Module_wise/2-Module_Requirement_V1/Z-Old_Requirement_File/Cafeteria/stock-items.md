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

#### Item Identification & Classification

- Every stock item must be identified by name and must belong to a predefined category (Grains, Pulses, Vegetables, Fruits, Dairy, Spices, Beverages, Condiments, Cleaning, or Other).
- Each item must have a measurement unit (kg, litre, piece, dozen, etc.) that describes how it is quantified.

#### Stock Quantity & Reorder Rules

- Stock quantities are never entered manually — they are automatically updated whenever stock is consumed or added through system transactions.
- A reorder level must be set for each item (zero or greater). This is the minimum quantity that triggers a low-stock alert when current stock falls to or below it.
- A reorder quantity can optionally be provided (zero or greater) as the suggested amount to order when stock runs low.
- Cost per unit is optional and informational only; it does not affect any stock calculations.

#### How Stock Deduction Works

When stock is consumed, the system follows these steps to ensure accuracy:

1. Locks the stock record so that two people cannot use the same stock at the same time.
2. Calculates the remaining quantity after deducting the amount used.
3. Checks whether there is enough stock — if the new quantity would be negative, the transaction is rejected and the user sees: *"Insufficient stock. Available: {current_quantity}, Required: {quantity_used}."*
4. Deducts the quantity from the stock record.
5. Records a consumption log entry with details (which item, how much used, by whom, etc.).
6. Saves everything together so that partial updates never happen.

#### Low-Stock Reorder Alert

- Whenever stock is updated, the system automatically checks whether the current quantity has dropped to or below the reorder level.
- If it has, a notification is sent with the message: *"Stock item '{name}' has reached reorder level ({current_quantity} {unit}). Recommended reorder quantity: {reorder_quantity} {unit}."*
- If no reorder quantity was set for the item, the recommended amount is left out of the message.
- This check runs both during stock consumption and automatically every night.

#### Unit Consistency

- When adding stock items, the same item name should always use the same unit of measurement. This is a recommended practice and is not enforced by the system.

#### Deleting a Stock Item

- When a stock item is deleted, it is marked as inactive and hidden from the main list. It can be restored later if needed.

#### List View

- The stock list shows all items with their current quantities. A banner at the top highlights items that are below their reorder level.
- Columns shown: Name, Category, Unit, Current Quantity, Reorder Level, Supplier, Cost per Unit, Status, and Action buttons.
- Available actions: Edit item details, View item (with consumption log), Log Consumption (pop-up form), Delete.

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

- Consumption logs are permanent records. They cannot be edited or deleted once created.
- The quantity used must be greater than zero. If someone tries to log zero or negative usage, the system shows: *"Quantity used must be greater than zero."*
- Each consumption log is created within the same database transaction as the stock deduction, so the log and the deduction always happen together (or not at all).
- Corrections to logged consumption can only be made by an administrator, who can add a reversal entry that creates an audit trail.
- Consumption logs are shown on the Stock Item detail page — there is no separate list page for logs alone.

## Permissions

| Operation | Permission Key |
|---|---|
| CRUD | `tenant.cafeteria.stock-item.*` |
| Consumption — Create/View | `tenant.cafeteria.consumption-log.*` |
