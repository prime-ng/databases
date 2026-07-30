# caf_Order — Test Case List & Business Conditions

**Module:** Cafeteria (CODE `CAF`, prefix `caf_`) · **Feature:** Orders (Pre-orders + Status FSM + Cutoff + Dietary Conflict + Kitchen View)
**DB scope:** TENANT-side (`caf_orders`, `caf_order_items`) · **Test style:** Browser Dusk + API
**Primary table:** `caf_orders` · **Module URL prefix:** `/cafeteria/orders-attendance?tab=orders`
**Test file:** `caf_Order_TestCas.php`
**Tab:** Orders (first tab of Orders & Attendance)

Controllers:
- `OrderController` — index, show, updateStatus, cancel, kitchenView, printKitchenSheet, apiStore, apiIndex, apiCancel, apiKitchenView
- `CafeteriaController::ordersAttendance()` — loads orders for tabbed page

Service:
- `OrderService` — placeOrder (8-step), updateStatus (FSM), cancelOrder (with refund), markServed, getKitchenView

Routes (`cafeteria.` prefix):
- `GET /cafeteria/orders-attendance` — tabbed page (orders tab default)
- `GET /cafeteria/orders` — index (redirects to orders-attendance?tab=orders)
- `GET /cafeteria/orders/{order}` — show
- `POST /cafeteria/orders/{order}/status` — updateStatus (Confirmed→Served)
- `POST /cafeteria/orders/{order}/cancel` — cancel (with refund)
- `GET /cafeteria/orders/kitchen` — kitchen view page
- `GET /cafeteria/orders/kitchen/print` — kitchen sheet PDF export
- API routes: POST store, GET index, POST cancel, GET kitchen

**DDL reference:** `caf_orders`, `caf_order_items` (Cafeteria DDL)

---

## 1. Business Conditions

### BC-DB — Schema
| ID | Condition | Source |
|----|-----------|--------|
| BC-DB-01 | Table `caf_orders`: id (INT UNSIGNED PK AI), order_number (VARCHAR 30 UNIQUE NOT NULL), student_id (INT UNSIGNED NOT NULL), meal_card_id (INT UNSIGNED NULL FK → caf_meal_cards.id ON DELETE SET NULL), order_date (DATE NOT NULL), meal_category_id (INT UNSIGNED NOT NULL FK → caf_menu_categories.id ON DELETE RESTRICT), total_amount (DECIMAL 10,2 NOT NULL), payment_mode (ENUM('MealCard','Cash','Counter','Subscription') DEFAULT 'MealCard'), status (ENUM('Pending','Confirmed','Served','Cancelled') DEFAULT 'Confirmed'), cancelled_at (TIMESTAMP NULL), cancellation_reason (VARCHAR 255 NULL), notes (TEXT NULL), is_active (TINYINT 1 DEFAULT 1), created_by, created_at, updated_at, deleted_at. Indexes: uq_caf_orders_number, idx_caf_ord_student, idx_caf_ord_meal_card, idx_caf_ord_category, idx_caf_ord_student_date, idx_caf_ord_date_cat_status | DDL |
| BC-DB-02 | Table `caf_order_items`: id (INT UNSIGNED PK AI), order_id (INT UNSIGNED FK → caf_orders.id ON DELETE CASCADE), menu_item_id (INT UNSIGNED FK → caf_menu_items.id ON DELETE RESTRICT), quantity (TINYINT UNSIGNED DEFAULT 1), unit_price (DECIMAL 8,2), line_total (DECIMAL 10,2), created_at, updated_at. Indexes: uq_caf_oi_order_item (order_id, menu_item_id) | DDL |
| BC-DB-03 | Model `Order`: table caf_orders, SoftDeletes, fillable 10 fields, casts: order_date→date, total_amount→decimal:2, cancelled_at→datetime, is_active→boolean. Constants: STATUSES, PAYMENT_MODES. Relations: student() belongsTo, mealCard() belongsTo, mealCategory() belongsTo, items() hasMany OrderItem, creator() belongsTo User. Scopes: active(), forKitchen($date,$categoryId) | Model |

### BC-VAL — Validation (StoreOrderRequest)
| ID | Condition | Source |
|----|-----------|--------|
| BC-VAL-01 | `student_id` required integer exists:std_students,id | FR |
| BC-VAL-02 | `order_date` required date | FR |
| BC-VAL-03 | `meal_category_id` required integer exists:caf_menu_categories,id | FR |
| BC-VAL-04 | `payment_mode` required in:MealCard,Cash,Counter,Subscription | FR |
| BC-VAL-05 | `items` required array min:1 | FR |
| BC-VAL-06 | `items.*.menu_item_id` required integer exists:caf_menu_items,id | FR |
| BC-VAL-07 | `items.*.quantity` required integer min:1 max:10 | FR |

### BC-AUTH — Authorization (OrderPolicy)
| ID | Condition | Source |
|----|-----------|--------|
| BC-AUTH-01 | Tab visible gate `cafeteria.orders` (viewAny) | View |
| BC-AUTH-02 | create/store gate `cafeteria.order.create` | Policy |
| BC-AUTH-03 | show gate `cafeteria.order.view` (or self if student) | Policy |
| BC-AUTH-04 | updateStatus/cancel gate `cafeteria.order.update` | Policy |
| BC-AUTH-05 | delete gate `cafeteria.order.delete` | Policy |

### BC-BIZ — Business Logic
| ID | Condition | Source |
|----|-----------|--------|
| BC-BIZ-01 | Orders tab: paginated 15, table with Order #, Student, Date, Items count, Total Amount (₹), Status badge, Actions | View |
| BC-BIZ-02 | Status filter: All/Confirmed/Served/Cancelled | View |
| BC-BIZ-03 | Search: by order_number or student_id | View |
| BC-BIZ-04 | Student column shows dietary icons (food preference + allergy flags) from $dietaryByStudent | View |
| BC-BIZ-05 | Actions: View (eye), Mark Served (Confirmed only), Cancel (Pending/Confirmed only) | View |
| BC-BIZ-06 | Cancel uses SweetAlert confirmation dialog | View |
| BC-BIZ-07 | Show page: order details with line items, allowed status transitions | Ctrl |
| BC-BIZ-08 | API store: 8-step atomic (validate menu, category, cutoff, items, dietary check, find card, create order, deduct card) | Service |
| BC-BIZ-09 | Status FSM: Pending→Confirmed, Pending→Cancelled, Confirmed→Served, Confirmed→Cancelled, Served/Cancelled terminal | Service |
| BC-BIZ-10 | Order cutoff: computed from meal_category.meal_start_time - caf_order_cutoff_hours (default 2h) (BR-CAF-001/008) | Service |
| BC-BIZ-11 | Dietary conflict: blocks incompatible food_type + allergen notes vs student profile (BR-CAF-002) | Service |
| BC-BIZ-12 | Staff override: users with cafeteria.orders.viewAny bypass dietary conflict check | Service |
| BC-BIZ-13 | MealCard deduction: atomic SELECT...FOR UPDATE deduct on order creation | Service |
| BC-BIZ-14 | Cancel + refund: lockForUpdate, set Cancelled, refund MealCard if applicable | Service |
| BC-BIZ-15 | Kitchen view: aggregates Confirmed orders by dish + subscription headcount (BR-CAF-010) | Service |
| BC-BIZ-16 | Kitchen PDF: DomPDF export of kitchen sheet | Ctrl |

### BC-EDG — Edge Cases
| ID | Condition | Source |
|----|-----------|--------|
| BC-EDG-01 | Order past cutoff → DomainException | Service |
| BC-EDG-02 | Dietary conflict (Veg student ordering Non_Veg) → DomainException | Service |
| BC-EDG-03 | Cancel after cutoff → DomainException | Service |
| BC-EDG-04 | Cancel already Served order → DomainException (FSM) | Service |
| BC-EDG-05 | Cancel already Cancelled order → DomainException (FSM) | Service |
| BC-EDG-06 | Mark Served on Cancelled order → DomainException (FSM) | Service |
| BC-EDG-07 | No active meal card for student → ModelNotFoundException | Service |
| BC-EDG-08 | No published menu for order_date → ModelNotFoundException | Service |
| BC-EDG-09 | Menu exists but has no items for requested category → DomainException | Service |
| BC-EDG-10 | quantity > 10 → max:10 validation error | FR |
| BC-EDG-11 | Empty items array → min:1 validation error | FR |

---

## 2. Test Case List

### Screen 1: Orders Tab (GET /cafeteria/orders-attendance?tab=orders)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFORD-P10 | Positive | View | Orders tab: table with Order #, Student, Date, Items count, Total Amount (₹), Status badge, Actions | Rendered | test_caf_ord_10 | Automated |
| TC-CAFORD-P11 | Positive | View | Status filter: All/Confirmed/Served/Cancelled | Filters | test_caf_ord_11 | Automated |
| TC-CAFORD-P12 | Positive | View | Search by order_number or student_id | Search | test_caf_ord_12 | Automated |
| TC-CAFORD-P13 | Positive | View | Student column shows dietary icons (food preference leaf/drumstick/egg + allergy icons) | Icons | test_caf_ord_13 | Automated |
| TC-CAFORD-P14 | Positive | View | Confirmed orders show "Mark Served" (green check) and "Cancel" (red X) buttons | Actions | test_caf_ord_14 | Automated |
| TC-CAFORD-P15 | Positive | View | Served/Cancelled orders show View only (no action buttons) | Read-only | test_caf_ord_15 | Automated |
| TC-CAFORD-P16 | Positive | View | Cancel triggers SweetAlert confirmation dialog | SweetAlert | test_caf_ord_16 | Automated |
| TC-CAFORD-P17 | Positive | View | Paginated 15 per page | Paginated | test_caf_ord_17 | Automated |
| TC-CAFORD-P18 | Positive | View | Empty state "No orders found" | Empty | test_caf_ord_18 | Automated |
| TC-CAFORD-P19 | Positive | View | Status badge colors: Confirmed=info, Served=success, Cancelled=danger, Pending=primary | Badges | test_caf_ord_19 | Automated |

### Screen 2: Show Order (GET /cafeteria/orders/{order})

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFORD-P30 | Positive | View | Show page: order number, student, date, category, payment mode, total, status, line items with qty+price | Details | test_caf_ord_30 | Automated |

### Screen 3: Update Status (Mark Served)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFORD-P50 | Positive | Ctrl | Mark Confirmed as Served → status=Served, redirect "Order status updated." | Served | test_caf_ord_50 | Automated |
| TC-CAFORD-N51 | Negative | Biz | Mark Cancelled as Served → DomainException (FSM) | Blocked | test_caf_ord_51 | Automated |
| TC-CAFORD-N52 | Negative | Biz | Mark Served as Served → DomainException (FSM) | Blocked | test_caf_ord_52 | Automated |

### Screen 4: Cancel Order

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFORD-P70 | Positive | Ctrl | Cancel Confirmed order → status=Cancelled, cancelled_at set, MealCard refunded, activity logged | Cancelled | test_caf_ord_70 | Automated |
| TC-CAFORD-N71 | Negative | Biz | Cancel Served order → DomainException (FSM) | Blocked | test_caf_ord_71 | Automated |
| TC-CAFORD-N72 | Negative | Biz | Cancel after cutoff → DomainException | Blocked | test_caf_ord_72 | Automated |

### Screen 5: API — Place Order (8-Step)

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFORD-P90 | Positive | API | Place valid order with MealCard → order created, card deducted, items created | Created | test_caf_ord_90 | Automated |
| TC-CAFORD-P91 | Positive | API | Place order with Cash payment → no card deduction | Created | test_caf_ord_91 | Automated |
| TC-CAFORD-N92 | Negative | Biz | Place order for date with no published menu → 422 error | Error | test_caf_ord_92 | Automated |
| TC-CAFORD-N93 | Negative | Biz | Place order past cutoff → 422 error | Error | test_caf_ord_93 | Automated |
| TC-CAFORD-N94 | Negative | Biz | Place order with dietary conflict → 422 error "Dietary conflict" | Error | test_caf_ord_94 | Automated |
| TC-CAFORD-N95 | Negative | Val | Missing items → validation error | Error | test_caf_ord_95 | Automated |
| TC-CAFORD-N96 | Negative | Val | quantity > 10 → max:10 error | Error | test_caf_ord_96 | Automated |

### Authorization Tests

| TC ID | Type | Source | Description | Expected | Method | Status |
|-------|------|--------|-------------|----------|--------|--------|
| TC-CAFORD-P200 | Positive | Auth | CRUD with correct permissions → 200 | 200 | test_caf_ord_200 | Automated |
| TC-CAFORD-N201 | Negative | Auth | Without viewAny → tab hidden, index 403 | 403 | test_caf_ord_201 | Automated |
| TC-CAFORD-N202 | Negative | Auth | Without create → 403 on API store | 403 | test_caf_ord_202 | Automated |
| TC-CAFORD-N203 | Negative | Auth | Without update → 403 on status update/cancel | 403 | test_caf_ord_203 | Automated |
