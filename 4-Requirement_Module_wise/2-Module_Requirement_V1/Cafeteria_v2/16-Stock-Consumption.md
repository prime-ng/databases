# Stock Consumption — Business Requirements

## What This Screen Does

The Stock Consumption screen records daily ingredient usage in the kitchen. Each entry logs what was used, how much, when, and for which meal category. Stock quantities are deducted atomically within the same transaction, ensuring inventory accuracy.

---

## When This Screen Is Used

- Kitchen staff finish preparing breakfast and log the ingredients used
- End-of-day stock reconciliation — what was consumed today?
- Admin needs to track ingredient usage trends for budgeting
- Investigating stock discrepancies — was consumption logged correctly?
- Planning purchase orders based on consumption patterns

---

## Key Fields at a Glance

**Stock Item**
Which ingredient was consumed (from the Stock Items library).

**Log Date**
Date of consumption. Multiple entries can exist for the same item on the same date.

**Quantity Used**
Amount consumed. Must be greater than zero. Deducted from the stock item's current quantity.

**Meal Category**
Optional — which meal this ingredient was used for (Breakfast, Lunch, etc.).

**Notes**
Optional context — e.g., "Used for biryani prep," "Extra oil used for deep frying."

**Logged By**
Staff member who recorded the consumption.

---

## Business Rules and Conditions

**Atomic Deduction**
Consumption is logged within a DB transaction: LOCK stock item → calculate new quantity → guard insufficient → UPDATE quantity → INSERT log → COMMIT. Prevents race conditions when multiple staff log simultaneously.

**Immutability**
Consumption logs cannot be modified or deleted after creation. Corrections via admin-only reversal entry with audit trail.

**Quantity Validation**
Quantity must be > 0. Error: "Quantity used must be greater than zero."

**Stock Level Guard**
If quantity would make stock negative, transaction rejected: "Insufficient stock. Available: X, Required: Y."

**Reorder Trigger**
After successful deduction, if new quantity <= reorder level, a reorder notification is automatically sent.

**No Separate List View**
Consumption logs are viewed within the Stock Item's show page — no standalone list view.

---

## Workflow Steps

**Logging Consumption**
From the Stock Item's action menu or show page → click "Log Consumption" → enter quantity used → optionally select meal category and add notes → submit. Stock is deducted atomically.

**Viewing Consumption History**
Open any Stock Item's show page to see all consumption entries with date, quantity, meal category, and staff member.

**Correcting an Error**
If a consumption entry was made in error, admin can create a reversal adjustment (increase stock by the same amount) with audit trail notes. The original log remains.

---

## Example Scenario

The kitchen is preparing lunch for 400 students. Staff logs the following consumption:

**Stock Item: Basmati Rice**
- Quantity: 8 kg, Meal Category: Lunch
- Before: 50 kg. After: 42 kg. Logged by: Kitchen Staff A.

**Stock Item: Cooking Oil**
- Quantity: 2 L, Meal Category: Lunch
- Before: 15 L. After: 13 L. Logged by: Kitchen Staff A.

**Stock Item: Tomatoes**
- Quantity: 5 kg, Meal Category: Lunch
- Before: 20 kg. After: 15 kg. Logged by: Kitchen Staff A.

At the end of the day, admin reviews total consumption: 25 kg rice, 6 L oil, 12 kg tomatoes used across all meals.

---

## Related Screens

- **Stock Items** — Consumption is logged against stock items
- **Suppliers** — Reorder alerts may trigger supplier purchase orders
- **Weekly Menus** — Menu planning helps predict consumption quantities
