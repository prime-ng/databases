# Stock Items — Business Requirements

## What This Screen Does

The Stock Items screen manages the cafeteria's raw material inventory. Every ingredient that the kitchen uses — rice, cooking oil, vegetables, spices, milk — is tracked with current quantity, reorder threshold, and cost per unit.

---

## When This Screen Is Used

- A new ingredient is introduced and needs to be added to inventory
- Admin wants to check current stock levels before planning the weekly menu
- Stock has fallen below reorder level and admin needs to place a purchase order
- An ingredient is no longer used and needs to be deactivated

---

## Key Fields at a Glance

**Item Name**
Raw material name — e.g., "Basmati Rice," "Sunflower Oil," "Tomatoes."

**Category**
Grains, Pulses, Vegetables, Fruits, Dairy, Spices, Beverages, Condiments, Cleaning, or Other.

**Unit of Measurement**
kg, litre, piece, dozen, etc.

**Preferred Supplier**
Optional reference to a registered supplier.

**Current Quantity**
Auto-managed by consumption logging. Never entered manually.

**Reorder Level**
Minimum quantity triggering an alert when stock falls below this level.

**Reorder Quantity**
Suggested purchase quantity when reordering.

**Cost Per Unit**
Informational — latest cost in INR.

**Status**
Active or Inactive.

---

## Business Rules and Conditions

**Atomic Stock Deduction**
When consumption is logged: LOCK record → calculate new quantity → guard insufficient → UPDATE → INSERT consumption log → COMMIT. Prevents race conditions.

**Reorder Alerts (BR-CAF-007)**
When current_quantity <= reorder_level after update → notification sent. Nightly cron also checks all items.

**Unit Consistency**
Same ingredient name should use same unit (operational practice).

---

## Workflow Steps

**Adding a Stock Item**
Enter name → select category and unit → optionally set supplier, reorder level, reorder quantity, and cost → submit.

**Viewing Stock Items**
List shows name, category, current quantity (colour-coded: green=OK, yellow=near reorder, red=below), unit, reorder level. Low-stock banner at top.

**Viewing Consumption History**
Each item's show page shows consumption entries with date, quantity, meal category, and who logged it.

---

## Example Scenario

**Basmati Rice:** 50 kg in stock, reorder at 20 kg.
- Monday: 8 kg used (42 kg remaining)
- Wednesday: 15 kg used (27 kg remaining)
- Friday: 10 kg used (17 kg remaining → below reorder level)

System sends alert: "Basmati Rice has reached reorder level (17 kg). Recommended reorder: 25 kg."

---

## Related Screens

- **Suppliers** — Each stock item can reference a preferred supplier
- **Stock Consumption** — Daily usage logged against stock items
- **Suppliers** — Supplier FSSAI expiry tracking in supplier master
