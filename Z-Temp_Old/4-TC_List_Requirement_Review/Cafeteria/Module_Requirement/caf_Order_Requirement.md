# Orders — Business Requirements

## What This Screen Does

The Orders tab manages student meal pre-orders placed against published daily/weekly menus. Each order has an **order number** (auto-generated), links to a **student**, a **meal category**, a **payment mode**, and **line items** (dish + quantity + price snapshot). Orders appear as the default tab (`?tab=orders`) of the Orders & Attendance page at `/cafeteria/orders-attendance`.

Orders are created via an **API endpoint** (student portal/mobile) or manually by cafeteria staff. The system enforces **order cutoff times** (BR-CAF-001/008) based on the meal category's `meal_start_time` minus configurable cutoff hours, and **dietary conflict checks** (BR-CAF-002) against the student's dietary profile.

## When This Screen Is Used

- **Order Monitoring**: Viewing all student pre-orders with status tracking
- **Order Fulfillment**: Marking Confirmed orders as Served
- **Order Cancellation**: Cancelling Pending/Confirmed orders (with meal card refund)
- **Kitchen View**: Aggregated headcount by dish for kitchen preparation (dedicated page + PDF export)
- **Student Ordering**: API endpoint for students to place orders

## Key Fields

- **Order Number** (unique) — Auto-generated pattern: `CAF-YYYY-XXXXXXXX` (year + 8 random uppercase chars)
- **Student** (FK → `std_students`) — Who placed the order
- **Meal Card** (FK → `caf_meal_cards`, nullable) — Used for MealCard payment deductions
- **Order Date** (date) — Calendar date meal is ordered for
- **Meal Category** (FK → `caf_menu_categories`) — Which meal slot (Breakfast/Lunch/etc.)
- **Total Amount** (decimal 10,2) — Sum of line item totals
- **Payment Mode** (enum) — `MealCard`, `Cash`, `Counter`, `Subscription`
- **Status** (enum) — `Pending`, `Confirmed` (default), `Served`, `Cancelled`
- **Cancelled At** (timestamp, nullable) — When cancelled
- **Cancellation Reason** (varchar 255, nullable)

### Line Items (`caf_order_items`)
- **Menu Item** (FK → `caf_menu_items`) — The ordered dish
- **Quantity** (tinyint, min 1, max 10)
- **Unit Price** (decimal 8,2) — Price snapshot at order time
- **Line Total** (decimal 10,2) — quantity × unit_price

## Business Rules

**Order Status FSM:** `Pending → Confirmed → Served → (terminal)` and `Pending/Confirmed → Cancelled`. The `updateStatus()` method enforces valid transitions and throws `DomainException` for invalid ones.

**Order Cutoff (BR-CAF-001/008):** `OrderService::assertCutoffNotPassed()` computes cutoff as `meal_start_time - caf_order_cutoff_hours` (system setting, default 2h). Throws `DomainException` if current time is past cutoff.

**Dietary Conflict (BR-CAF-002):** `OrderService::assertNoDietaryConflict()` checks each ordered dish against the student's dietary profile:
- Veg: blocks Non_Veg and Egg dishes
- Jain: blocks Non_Veg and Egg dishes
- Egg: blocks Non_Veg dishes
- Allergen notes checked for nuts/dairy/gluten keywords against student flags
- Staff with `cafeteria.orders.viewAny` can override (skip check)

**Meal Card Deduction:** If payment mode is `MealCard`, the order creation atomically deducts the total from the student's meal card via `MealCardService::deductBalance()` (SELECT...FOR UPDATE).

**Order Cancellation + Refund:** `cancelOrder()`:
1. Validates order is Pending or Confirmed
2. Re-checks cutoff
3. Uses `lockForUpdate()` to prevent race conditions
4. Sets status=Cancelled + cancelled_at + cancellation_reason
5. Refunds meal card if payment was MealCard

**API Order Placement:** The `apiStore()` method is an 8-step atomic transaction: validate menu exists → validate category on menu → check cutoff → calc totals → check dietary → find meal card → create order → deduct balance → create items.

**Kitchen View:** Aggregates Confirmed orders' items by dish with headcount totals. Also includes subscription headcount (BR-CAF-010) — enrolled active subscriptions are counted as one serving per covered meal category.

**Activity Logging:**
- Status Update: `"Order {number} status updated to {status}."`
- Cancel: `"Order {number} cancelled."`

**No Soft Delete:** Orders index tab only shows active orders. The Order model uses SoftDeletes but the tab query does not filter trashed — it shows all. Trash routes exist but are not exposed in the tab UI.

## Workflow

1. Staff navigates to Cafeteria → Orders & Attendance → Orders tab
2. Staff sees paginated table with Order #, Student, Date, Items count, Total, Status badge, Action buttons
3. Each row shows dietary icons (food preference, allergies) next to student name from `$dietaryByStudent`
4. Staff can click View to see order detail page with line items
5. Staff can click "Mark Served" button on Confirmed orders
6. Staff can click "Cancel" on Pending/Confirmed orders (with SweetAlert confirmation)

## Related Screens

- **Meal Attendance** — Second tab; track physical meal attendance
- **Dietary Profiles** — Third tab; profiles drive conflict checks
- **POS Sessions** — Fourth tab; counter sales
- **Kitchen View** — Dedicated `/cafeteria/orders/kitchen` page + PDF export
- **Weekly Menus** — Published menus drive what can be ordered

## Requirements

- MUST display orders at `/cafeteria/orders-attendance?tab=orders` as a paginated table with search and status filter
- MUST authorize via `cafeteria.orders.*` policy gates (note: policy uses `cafeteria.order.*` permission keys)
- MUST validate API store with 6 rules (BC-VAL-01 through 06)
- MUST generate unique order number `CAF-YYYY-XXXXXXXX`
- MUST enforce order status FSM with DomainException on invalid transitions
- MUST enforce order cutoff (BR-CAF-001/008) based on meal_start_time - cutoff_hours
- MUST enforce dietary conflict check (BR-CAF-002) with staff overrides
- MUST support mark-as-served action (Confirmed → Served)
- MUST support order cancellation with meal card refund
- MUST show dietary icons on each order row (food preference + allergy flags)
- MUST aggregate kitchen view with headcount per dish + subscription counts
- MUST log status changes and cancellations via activityLog()
