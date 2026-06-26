# Orders — Business Requirements

## What This Screen Does

The Orders screen is where student meal pre-orders are placed, tracked, and fulfilled. Students order meals via the student portal or mobile app before a cutoff time. The kitchen sees confirmed orders grouped by date and meal category to plan cooking quantities. POS staff process orders at the counter and update status.

---

## When This Screen Is Used

- A student wants to pre-order lunch for tomorrow via mobile app or portal
- A student orders at the counter via POS terminal
- The kitchen needs to see how many students ordered biryani for lunch
- An order is ready and needs to be marked as Served
- A student wants to cancel their order before the meal starts
- Admin needs to look up a specific order by order number

---

## Key Fields at a Glance

**Order Header**

**Order Number**
Auto-generated unique identifier: CAF-YYYY-XXXXXXXX (e.g., CAF-2026-00000001). Sequential per year with DB-level lock.

**Student**
The student who placed the order. Auto-selected when logged in (portal) or searched by cashier (POS).

**Order Date & Meal Category**
The date the meal is ordered for and which meal category. One order per (student, date, meal_category).

**Total Amount**
Sum of all line item totals.

**Payment Mode**
MealCard (prepaid wallet deduction), Cash (pay at counter), Counter (pay at POS), or Subscription (covered by plan).

**Status**
Pending → Confirmed → Served → Cancelled.

**Order Items**

Each item records: menu_item_id, quantity, unit_price (snapshot at order time), and line_total.

---

## Business Rules and Conditions

**Pre-Order Cutoff**
Default cutoff is 10:00 PM the day BEFORE the order date. Configurable per meal category.

**Duplicate Order Guard**
One order per (student, date, meal_category). "You already have an order for Lunch on this date."

**Price Snapshot**
Unit prices are copied from the dish library at order time. Subsequent price changes do NOT affect existing orders.

**Order Lifecycle:**
- Pending → Confirmed: Payment confirmed. Kitchen sees it.
- Confirmed → Served: Meal handed to student (on/after order date).
- Confirmed → Cancelled: Before meal start time. Refund issued if MealCard.
- Pending → Cancelled: Payment failed or student withdrew.
- Cancelled → (no transitions).

**Cancellation Side Effects:** If MealCard mode, full amount refunded to wallet. Refund transaction created in ledger.

---

## Workflow Steps

**Student Places Order (Portal/App):** Views published menu → selects dishes → chooses payment mode → submits. MealCard deducted immediately.

**Counter Order (POS):** Cashier searches student → adds items → processes payment. Order auto-created.

**Kitchen View:** Shows Confirmed orders grouped by date/meal category with total quantities per dish.

**Mark as Served:** Staff marks order as Served when student collects meal.

**Cancel Order:** Before meal start time, with required reason. MealCard refunded automatically.

---

## Example Scenario

Student Ravi pre-orders Wednesday lunch:
- 2 × Veg Biryani (₹40) = ₹80, 1 × Raita (₹10) = ₹10
- Total: ₹90, Payment: MealCard (₹500 → ₹410)
- Order: CAF-2026-0000042, Status: Confirmed

Wednesday morning, kitchen sees 42 students ordered biryani and prepares accordingly. If Ravi is sick, he cancels before noon, and ₹90 is refunded.

---

## Related Screens

- **Menu Items** — Order items reference the dish library with price snapshot
- **Weekly Menus** — Published menus drive what students can order
- **Meal Cards** — MealCard mode deducts from student's wallet
- **Meal Attendance** — Auto-created when order is served
