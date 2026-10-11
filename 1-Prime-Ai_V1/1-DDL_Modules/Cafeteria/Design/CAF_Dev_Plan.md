# CAF — Cafeteria Module Development Plan
**Module:** CAF (Cafeteria & Mess Management) | **Version:** 1.0 | **Date:** 2026-03-27
**Namespace:** `Modules\Cafeteria` | **Route Prefix:** `cafeteria/` | **DB Prefix:** `caf_*`
**Source:** CAF_FeatureSpec.md + CAF_Cafeteria_Requirement.md v2 | **Status:** Phase 3 Output

---

## Section 1 — Controller Inventory (16 Controllers)

**Base middleware (all web routes):** `['auth', 'tenant', 'EnsureTenantHasModule:Cafeteria']`
**Base API middleware:** `['auth:sanctum', 'tenant']`
**File path pattern:** `Modules/Cafeteria/app/Http/Controllers/`

---

### 1. `CafeteriaController`
**File:** `CafeteriaController.php` | **FR:** CAF-14

| HTTP | URI | Route Name | FormRequest | Policy |
|------|-----|-----------|-------------|--------|
| GET | `/cafeteria` | `cafeteria.dashboard` | — | `cafeteria.dashboard.view` |

**Methods:**
- `dashboard()` — KPI widgets: today's orders, today's revenue, low-stock count, active card count; reads from `caf_orders`, `caf_meal_cards`, `caf_stock_items`

---

### 2. `MenuCategoryController`
**File:** `MenuCategoryController.php` | **FR:** CAF-01

| HTTP | URI | Route Name | FormRequest | Policy |
|------|-----|-----------|-------------|--------|
| GET | `/cafeteria/menu-categories` | `cafeteria.menu-categories.index` | — | `cafeteria.menu-category.view` |
| GET | `/cafeteria/menu-categories/create` | `cafeteria.menu-categories.create` | — | `cafeteria.menu-category.create` |
| POST | `/cafeteria/menu-categories` | `cafeteria.menu-categories.store` | `StoreMenuCategoryRequest` | `cafeteria.menu-category.create` |
| GET | `/cafeteria/menu-categories/{category}` | `cafeteria.menu-categories.show` | — | `cafeteria.menu-category.view` |
| GET | `/cafeteria/menu-categories/{category}/edit` | `cafeteria.menu-categories.edit` | — | `cafeteria.menu-category.update` |
| PUT | `/cafeteria/menu-categories/{category}` | `cafeteria.menu-categories.update` | `StoreMenuCategoryRequest` | `cafeteria.menu-category.update` |
| DELETE | `/cafeteria/menu-categories/{category}` | `cafeteria.menu-categories.destroy` | — | `cafeteria.menu-category.delete` |
| PATCH | `/cafeteria/menu-categories/{category}/toggle` | `cafeteria.menu-categories.toggle` | — | `cafeteria.menu-category.update` |

**Methods:** `index`, `create`, `store`, `show`, `edit`, `update`, `destroy`, `toggle`

---

### 3. `MenuItemController`
**File:** `MenuItemController.php` | **FR:** CAF-02

| HTTP | URI | Route Name | FormRequest | Policy |
|------|-----|-----------|-------------|--------|
| GET | `/cafeteria/menu-items` | `cafeteria.menu-items.index` | — | `cafeteria.menu-item.view` |
| GET | `/cafeteria/menu-items/create` | `cafeteria.menu-items.create` | — | `cafeteria.menu-item.create` |
| POST | `/cafeteria/menu-items` | `cafeteria.menu-items.store` | `StoreMenuItemRequest` | `cafeteria.menu-item.create` |
| GET | `/cafeteria/menu-items/{item}` | `cafeteria.menu-items.show` | — | `cafeteria.menu-item.view` |
| GET | `/cafeteria/menu-items/{item}/edit` | `cafeteria.menu-items.edit` | — | `cafeteria.menu-item.update` |
| PUT | `/cafeteria/menu-items/{item}` | `cafeteria.menu-items.update` | `StoreMenuItemRequest` | `cafeteria.menu-item.update` |
| DELETE | `/cafeteria/menu-items/{item}` | `cafeteria.menu-items.destroy` | — | `cafeteria.menu-item.delete` |
| PATCH | `/cafeteria/menu-items/{item}/toggle-availability` | `cafeteria.menu-items.toggle-availability` | — | `cafeteria.menu-item.update` |

**Methods:** `index`, `create`, `store`, `show`, `edit`, `update`, `destroy`, `toggleAvailability` (returns JSON for AJAX)

---

### 4. `WeeklyMenuController`
**File:** `WeeklyMenuController.php` | **FR:** CAF-03

| HTTP | URI | Route Name | FormRequest | Policy |
|------|-----|-----------|-------------|--------|
| GET | `/cafeteria/weekly-menu` | `cafeteria.weekly-menu.index` | — | `cafeteria.daily-menu.manage` |
| GET | `/cafeteria/weekly-menu/create` | `cafeteria.weekly-menu.create` | — | `cafeteria.daily-menu.manage` |
| POST | `/cafeteria/weekly-menu` | `cafeteria.weekly-menu.store` | `StoreDailyMenuRequest` | `cafeteria.daily-menu.manage` |
| GET | `/cafeteria/weekly-menu/{menu}` | `cafeteria.weekly-menu.show` | — | `cafeteria.daily-menu.manage` |
| GET | `/cafeteria/weekly-menu/{menu}/edit` | `cafeteria.weekly-menu.edit` | — | `cafeteria.daily-menu.manage` |
| PUT | `/cafeteria/weekly-menu/{menu}` | `cafeteria.weekly-menu.update` | `StoreDailyMenuRequest` | `cafeteria.daily-menu.manage` |
| PATCH | `/cafeteria/weekly-menu/{menu}/publish` | `cafeteria.weekly-menu.publish` | — | `cafeteria.daily-menu.manage` |
| PATCH | `/cafeteria/weekly-menu/{menu}/archive` | `cafeteria.weekly-menu.archive` | — | `cafeteria.daily-menu.manage` |
| GET | `/api/v1/cafeteria/weekly-menu/current` | `cafeteria.api.weekly-menu.current` | — | — *(Student/Parent portal)* |

**Methods:** `index`, `create`, `store`, `show`, `edit`, `update`, `publish`, `archive`, `apiCurrentWeek`

---

### 5. `EventMealController`
**File:** `EventMealController.php` | **FR:** CAF-04

| HTTP | URI | Route Name | FormRequest | Policy |
|------|-----|-----------|-------------|--------|
| GET | `/cafeteria/event-meals` | `cafeteria.event-meals.index` | — | `cafeteria.daily-menu.manage` |
| GET | `/cafeteria/event-meals/create` | `cafeteria.event-meals.create` | — | `cafeteria.daily-menu.manage` |
| POST | `/cafeteria/event-meals` | `cafeteria.event-meals.store` | `StoreEventMealRequest` | `cafeteria.daily-menu.manage` |
| GET | `/cafeteria/event-meals/{meal}` | `cafeteria.event-meals.show` | — | `cafeteria.daily-menu.manage` |
| GET | `/cafeteria/event-meals/{meal}/edit` | `cafeteria.event-meals.edit` | — | `cafeteria.daily-menu.manage` |
| PUT | `/cafeteria/event-meals/{meal}` | `cafeteria.event-meals.update` | `StoreEventMealRequest` | `cafeteria.daily-menu.manage` |
| PATCH | `/cafeteria/event-meals/{meal}/publish` | `cafeteria.event-meals.publish` | — | `cafeteria.daily-menu.manage` |

**Methods:** `index`, `create`, `store`, `show`, `edit`, `update`, `publish`

---

### 6. `DietaryProfileController`
**File:** `DietaryProfileController.php` | **FR:** CAF-05

| HTTP | URI | Route Name | FormRequest | Policy |
|------|-----|-----------|-------------|--------|
| GET | `/cafeteria/dietary-profiles` | `cafeteria.dietary-profiles.index` | — | `cafeteria.dietary-profile.manage` |
| POST | `/cafeteria/dietary-profiles` | `cafeteria.dietary-profiles.store` | `StoreDietaryProfileRequest` | `cafeteria.dietary-profile.manage` |
| GET | `/cafeteria/dietary-profiles/{profile}` | `cafeteria.dietary-profiles.show` | — | `cafeteria.dietary-profile.manage` |
| GET | `/cafeteria/dietary-profiles/{profile}/edit` | `cafeteria.dietary-profiles.edit` | — | `cafeteria.dietary-profile.manage` |
| PUT | `/cafeteria/dietary-profiles/{profile}` | `cafeteria.dietary-profiles.update` | `StoreDietaryProfileRequest` | `cafeteria.dietary-profile.manage` |
| GET | `/api/v1/cafeteria/dietary-profiles/{student}` | `cafeteria.api.dietary-profiles.get` | — | *(Parent portal)* |
| PUT | `/api/v1/cafeteria/dietary-profiles/{student}` | `cafeteria.api.dietary-profiles.update` | `StoreDietaryProfileRequest` | *(Parent portal)* |

**Methods:** `index`, `store`, `show`, `edit`, `update`, `apiGet`, `apiUpdate`

---

### 7. `SubscriptionPlanController`
**File:** `SubscriptionPlanController.php` | **FR:** CAF-06

| HTTP | URI | Route Name | FormRequest | Policy |
|------|-----|-----------|-------------|--------|
| GET | `/cafeteria/subscription-plans` | `cafeteria.subscription-plans.index` | — | `cafeteria.subscription.manage` |
| GET | `/cafeteria/subscription-plans/create` | `cafeteria.subscription-plans.create` | — | `cafeteria.subscription.manage` |
| POST | `/cafeteria/subscription-plans` | `cafeteria.subscription-plans.store` | `StoreSubscriptionPlanRequest` | `cafeteria.subscription.manage` |
| GET | `/cafeteria/subscription-plans/{plan}` | `cafeteria.subscription-plans.show` | — | `cafeteria.subscription.manage` |
| GET | `/cafeteria/subscription-plans/{plan}/edit` | `cafeteria.subscription-plans.edit` | — | `cafeteria.subscription.manage` |
| PUT | `/cafeteria/subscription-plans/{plan}` | `cafeteria.subscription-plans.update` | `StoreSubscriptionPlanRequest` | `cafeteria.subscription.manage` |
| PATCH | `/cafeteria/subscription-plans/{plan}/toggle-status` | `cafeteria.subscription-plans.toggle-status` | — | `cafeteria.subscription.manage` |

**Methods:** `index`, `create`, `store`, `show`, `edit`, `update`, `toggleStatus`

---

### 8. `SubscriptionEnrollmentController`
**File:** `SubscriptionEnrollmentController.php` | **FR:** CAF-06

| HTTP | URI | Route Name | FormRequest | Policy |
|------|-----|-----------|-------------|--------|
| GET | `/cafeteria/subscription-enrollments` | `cafeteria.subscription-enrollments.index` | — | `cafeteria.subscription.manage` |
| POST | `/cafeteria/subscription-enrollments` | `cafeteria.subscription-enrollments.store` | `StoreSubscriptionEnrollmentRequest` | `cafeteria.subscription.manage` |
| GET | `/cafeteria/subscription-enrollments/{enrollment}` | `cafeteria.subscription-enrollments.show` | — | `cafeteria.subscription.manage` |
| DELETE | `/cafeteria/subscription-enrollments/{enrollment}` | `cafeteria.subscription-enrollments.destroy` | — | `cafeteria.subscription.manage` |

**Methods:** `index`, `store`, `show`, `destroy` (cancel enrollment)

---

### 9. `OrderController`
**File:** `OrderController.php` | **FR:** CAF-07, CAF-14

| HTTP | URI | Route Name | FormRequest | Policy |
|------|-----|-----------|-------------|--------|
| GET | `/cafeteria/orders` | `cafeteria.orders.index` | — | `cafeteria.order.view` |
| GET | `/cafeteria/orders/{order}` | `cafeteria.orders.show` | — | `cafeteria.order.view` |
| PATCH | `/cafeteria/orders/{order}/status` | `cafeteria.orders.update-status` | — | `cafeteria.order.manage` |
| PATCH | `/cafeteria/orders/{order}/cancel` | `cafeteria.orders.cancel` | — | `cafeteria.order.manage` |
| GET | `/cafeteria/kitchen-view` | `cafeteria.kitchen-view` | — | `cafeteria.order.view` |
| GET | `/cafeteria/kitchen-view/print` | `cafeteria.kitchen-view.print` | — | `cafeteria.order.view` |
| POST | `/api/v1/cafeteria/orders` | `cafeteria.api.orders.store` | `StoreOrderRequest` | *(Student portal)* |
| GET | `/api/v1/cafeteria/orders` | `cafeteria.api.orders.index` | — | *(Student portal)* |
| PATCH | `/api/v1/cafeteria/orders/{order}/cancel` | `cafeteria.api.orders.cancel` | — | *(Student portal)* |
| GET | `/api/v1/cafeteria/kitchen-view` | `cafeteria.api.kitchen-view` | — | *(Kitchen staff)* |

**Methods:** `index`, `show`, `updateStatus`, `cancel`, `kitchenView`, `printKitchenSheet` (DomPDF stream), `apiStore`, `apiIndex`, `apiCancel`, `apiKitchenView`

---

### 10. `PosController`
**File:** `PosController.php` | **FR:** CAF-10

| HTTP | URI | Route Name | FormRequest | Policy |
|------|-----|-----------|-------------|--------|
| GET | `/cafeteria/pos` | `cafeteria.pos.index` | — | `cafeteria.pos.operate` |
| POST | `/cafeteria/pos/sessions` | `cafeteria.pos.sessions.open` | `StorePosSessionRequest` | `cafeteria.pos.operate` |
| PATCH | `/cafeteria/pos/sessions/{session}/close` | `cafeteria.pos.sessions.close` | — | `cafeteria.pos.operate` |
| GET | `/cafeteria/pos/sessions/{session}` | `cafeteria.pos.sessions.show` | — | `cafeteria.pos.operate` |
| POST | `/cafeteria/pos/transact` | `cafeteria.pos.transact` | `StorePosTransactionRequest` | `cafeteria.pos.operate` |
| GET | `/api/v1/cafeteria/pos/student-lookup` | `cafeteria.api.pos.student-lookup` | — | `cafeteria.pos.operate` |
| POST | `/api/v1/cafeteria/pos/transact` | `cafeteria.api.pos.transact` | `StorePosTransactionRequest` | `cafeteria.pos.operate` |

**Methods:** `index`, `openSession`, `closeSession`, `showSession`, `transact`, `apiStudentLookup` (returns dietary flags + balance JSON), `apiTransact`

---

### 11. `MealAttendanceController`
**File:** `MealAttendanceController.php` | **FR:** CAF-09

| HTTP | URI | Route Name | FormRequest | Policy |
|------|-----|-----------|-------------|--------|
| GET | `/cafeteria/meal-attendance` | `cafeteria.meal-attendance.index` | — | `cafeteria.meal-attendance.view` |
| POST | `/api/v1/cafeteria/meal-attendance/scan` | `cafeteria.api.meal-attendance.scan` | — | *(No auth — QR scanner)* |

**Methods:** `index`, `apiScan` (idempotent — duplicate scan returns `200` with existing record via UNIQUE constraint)

---

### 12. `MealCardController`
**File:** `MealCardController.php` | **FR:** CAF-08

| HTTP | URI | Route Name | FormRequest | Policy |
|------|-----|-----------|-------------|--------|
| GET | `/cafeteria/meal-cards` | `cafeteria.meal-cards.index` | — | `cafeteria.meal-card.manage` |
| POST | `/cafeteria/meal-cards` | `cafeteria.meal-cards.store` | `IssueMealCardRequest` | `cafeteria.meal-card.manage` |
| POST | `/cafeteria/meal-cards/{card}/topup` | `cafeteria.meal-cards.topup` | `TopUpMealCardRequest` | `cafeteria.meal-card.manage` |
| GET | `/cafeteria/meal-cards/{card}/statement` | `cafeteria.meal-cards.statement` | — | `cafeteria.meal-card.manage` |
| GET | `/api/v1/cafeteria/meal-cards/{card}/balance` | `cafeteria.api.meal-cards.balance` | — | *(Student/Parent portal)* |
| GET | `/api/v1/cafeteria/meal-cards/{card}/transactions` | `cafeteria.api.meal-cards.transactions` | — | *(Student/Parent portal)* |
| POST | `/api/v1/cafeteria/meal-cards/{card}/topup` | `cafeteria.api.meal-cards.topup` | `TopUpMealCardRequest` | *(Razorpay redirect)* |
| POST | `/api/v1/cafeteria/meal-card/topup/webhook` | `cafeteria.api.meal-cards.webhook` | — | **withoutMiddleware(['auth:sanctum'])** |

**Methods:** `index`, `store`, `topup`, `statement` (DomPDF stream), `apiBalance`, `apiTransactions`, `apiRazorpayTopup`, `apiRazorpayWebhook`

> **Critical:** `apiRazorpayWebhook` uses `->withoutMiddleware(['auth:sanctum'])` — public endpoint; idempotency enforced via `razorpay_payment_id` UNIQUE (BR-CAF-011)

---

### 13. `StockController`
**File:** `StockController.php` | **FR:** CAF-11

| HTTP | URI | Route Name | FormRequest | Policy |
|------|-----|-----------|-------------|--------|
| GET | `/cafeteria/stock` | `cafeteria.stock.index` | — | `cafeteria.stock.manage` |
| GET | `/cafeteria/stock/create` | `cafeteria.stock.create` | — | `cafeteria.stock.manage` |
| POST | `/cafeteria/stock` | `cafeteria.stock.store` | `StoreStockItemRequest` | `cafeteria.stock.manage` |
| GET | `/cafeteria/stock/{item}` | `cafeteria.stock.show` | — | `cafeteria.stock.manage` |
| GET | `/cafeteria/stock/{item}/edit` | `cafeteria.stock.edit` | — | `cafeteria.stock.manage` |
| PUT | `/cafeteria/stock/{item}` | `cafeteria.stock.update` | `StoreStockItemRequest` | `cafeteria.stock.manage` |
| DELETE | `/cafeteria/stock/{item}` | `cafeteria.stock.destroy` | — | `cafeteria.stock.manage` |
| POST | `/cafeteria/stock/{item}/consumption` | `cafeteria.stock.log-consumption` | `LogConsumptionRequest` | `cafeteria.stock.manage` |

**Methods:** `index`, `create`, `store`, `show`, `edit`, `update`, `destroy`, `logConsumption`

---

### 14. `SupplierController`
**File:** `SupplierController.php` | **FR:** CAF-11

| HTTP | URI | Route Name | FormRequest | Policy |
|------|-----|-----------|-------------|--------|
| GET | `/cafeteria/suppliers` | `cafeteria.suppliers.index` | — | `cafeteria.supplier.manage` |
| GET | `/cafeteria/suppliers/create` | `cafeteria.suppliers.create` | — | `cafeteria.supplier.manage` |
| POST | `/cafeteria/suppliers` | `cafeteria.suppliers.store` | `StoreSupplierRequest` | `cafeteria.supplier.manage` |
| GET | `/cafeteria/suppliers/{supplier}` | `cafeteria.suppliers.show` | — | `cafeteria.supplier.manage` |
| GET | `/cafeteria/suppliers/{supplier}/edit` | `cafeteria.suppliers.edit` | — | `cafeteria.supplier.manage` |
| PUT | `/cafeteria/suppliers/{supplier}` | `cafeteria.suppliers.update` | `StoreSupplierRequest` | `cafeteria.supplier.manage` |
| DELETE | `/cafeteria/suppliers/{supplier}` | `cafeteria.suppliers.destroy` | — | `cafeteria.supplier.manage` |

**Methods:** `index`, `create`, `store`, `show`, `edit`, `update`, `destroy`

---

### 15. `FssaiController`
**File:** `FssaiController.php` | **FR:** CAF-12

| HTTP | URI | Route Name | FormRequest | Policy |
|------|-----|-----------|-------------|--------|
| GET | `/cafeteria/fssai` | `cafeteria.fssai.index` | — | `cafeteria.fssai.manage` |
| POST | `/cafeteria/fssai` | `cafeteria.fssai.store` | `StoreFssaiRecordRequest` | `cafeteria.fssai.manage` |
| GET | `/cafeteria/fssai/{record}` | `cafeteria.fssai.show` | — | `cafeteria.fssai.manage` |
| GET | `/cafeteria/fssai/{record}/document` | `cafeteria.fssai.document` | — | `cafeteria.fssai.manage` |

**Methods:** `index`, `store`, `show`, `download` (streams license document from `sys_media`)

---

### 16. `CafeteriaReportController`
**File:** `CafeteriaReportController.php` | **FR:** CAF-14

| HTTP | URI | Route Name | FormRequest | Policy |
|------|-----|-----------|-------------|--------|
| GET | `/cafeteria/reports/revenue` | `cafeteria.reports.revenue` | — | `cafeteria.report.view` |
| GET | `/cafeteria/reports/orders` | `cafeteria.reports.orders` | — | `cafeteria.report.view` |
| GET | `/cafeteria/reports/wastage` | `cafeteria.reports.wastage` | — | `cafeteria.report.view` |
| GET | `/cafeteria/reports/meal-card-statements` | `cafeteria.reports.statements` | — | `cafeteria.report.view` |
| GET | `/cafeteria/reports/revenue/export` | `cafeteria.reports.revenue.export` | — | `cafeteria.report.view` |
| GET | `/cafeteria/reports/orders/export` | `cafeteria.reports.orders.export` | — | `cafeteria.report.view` |
| GET | `/cafeteria/reports/wastage/export` | `cafeteria.reports.wastage.export` | — | `cafeteria.report.view` |
| GET | `/cafeteria/reports/statements/export` | `cafeteria.reports.statements.export` | — | `cafeteria.report.view` |

**Methods:** `revenue`, `orderSummary`, `wastage`, `mealCardStatements`, `exportRevenue`, `exportOrders`, `exportWastage`, `exportStatements` (CSV via `fputcsv`; PDF via DomPDF)

---

## Section 2 — Service Inventory (6 Services)

**Namespace:** `Modules\Cafeteria\app\Services`
**File path:** `Modules/Cafeteria/app/Services/`

---

### 1. `MenuService`

```
Service:    MenuService
File:       app/Services/MenuService.php
Depends on: — (standalone)
Fires:      MenuPublished (on publish — dispatches NTF push/SMS to all active students/parents)
```

**Key Methods:**
```
createCategory(array $data): MenuCategory
  └── Creates caf_menu_categories record

updateCategory(MenuCategory $cat, array $data): MenuCategory
  └── Updates category; clears is_available cache

createItem(array $data): MenuItem
  └── Creates caf_menu_items; handles photo_media_id attachment

toggleItemAvailability(MenuItem $item): bool
  └── Flips is_available; returns new state for AJAX response

createDailyMenu(array $data): DailyMenu
  └── Validates UNIQUE menu_date; creates header + assigns items from payload array

publishMenu(DailyMenu $menu): void
  └── Pre-condition: ≥1 item assigned (BR-CAF-005); sets status=Published, published_at, published_by
  └── Dispatches MenuPublishedNotification (queued) to all active students + parents via NTF

archiveMenu(DailyMenu $menu): void
  └── Sets status=Archived; called by caf:archive-old-menus Artisan command

archiveOldMenus(): int
  └── Archives all Published menus with menu_date < today − 7 days; returns count

createEventMeal(array $data): EventMeal
  └── Creates event meal header + assigns items (nullable menu_item_id for free-text)

publishEventMeal(EventMeal $meal): void
  └── Sets status=Published; dispatches notification to target class IDs (or all if null)
```

---

### 2. `OrderService`

```
Service:    OrderService
File:       app/Services/OrderService.php
Depends on: MealCardService (for deductBalance on MealCard payment)
Fires:      — (no events; notifications via MealCardService on balance)
```

**Key Methods:**
```
placeOrder(Student $student, array $orderData): Order
  └── 8-step atomic pre-order placement (see pseudocode below)

cancelOrder(Order $order, string $reason): void
  └── Validates status is Confirmed; if MealCard payment: MealCardService::refundBalance()
  └── Sets status=Cancelled, cancelled_at, cancellation_reason

markServed(Order $order): void
  └── Sets status=Served; called from kitchenView or POS scan

getKitchenView(Date $date, int $mealCategoryId): array
  └── Aggregates caf_order_items by menu_item_id + food_type; adds headcount from subscriptions
  └── Composite index idx_caf_ord_date_cat_status ensures < 2s for 500+ orders (NFR)

printKitchenSheet(Date $date, int $categoryId): \Illuminate\Http\Response
  └── Generates DomPDF PDF; streams response with kitchen-sheet.blade.php template

generateOrderNumber(): string
  └── Returns unique string matching CAF-{YYYY}-{8CHAR_ALPHANUM}
```

**`placeOrder()` Pseudocode:**
```
placeOrder(Student $student, array $orderData): Order
  Step 1: Load DailyMenu for order_date — throw MenuNotPublishedException if status ≠ 'Published'
  Step 2: Check cutoff window: if meal_start_time − caf_order_cutoff_hours ≤ now() → throw OrderCutoffPassedException
  Step 3: Load student DietaryProfile; check food_type conflict for each ordered item
           → soft warning only; admin can override; student role cannot override (BR-CAF-002)
  Step 4: Compute total_amount = Σ (caf_menu_items.price × quantity) for each item in orderData
  Step 5: If payment_mode == 'MealCard':
            $card = MealCard::where('student_id', $student->id)->active()->firstOrFail()
            MealCardService::deductBalance($card, $total, 'Order', $tempOrderId)
  Step 6: INSERT caf_orders (order_number, student_id, meal_card_id, order_date, meal_category_id,
                              total_amount, payment_mode, status='Confirmed')
  Step 7: INSERT caf_order_items for each item with unit_price snapshot (NOT read from DB later)
  Step 8: Return Order
```

---

### 3. `MealCardService`

```
Service:    MealCardService
File:       app/Services/MealCardService.php
Depends on: — (standalone; called BY OrderService and PosService)
Fires:      LowBalanceNotificationJob (queued after every debit when balance < threshold)
```

**Key Methods:**
```
issueCard(Student $student, array $data): MealCard
  └── Deactivates any existing active card (soft-delete); creates new card with card_number

deductBalance(MealCard $card, float $amount, string $refType, int $refId): MealCardTransaction
  └── 9-step atomic deduction via SELECT...FOR UPDATE (see pseudocode below)

creditBalance(MealCard $card, float $amount, string $refType, ?string $razorpayId = null): MealCardTransaction
  └── DB transaction → UPDATE balance → INSERT transaction (Credit) → commit

refundBalance(MealCard $card, float $amount, int $orderId): MealCardTransaction
  └── Calls creditBalance with refType='Refund', reference_id=orderId

initiateRazorpayTopup(MealCard $card, float $amount): array
  └── Creates Razorpay order via SDK; returns [order_id, key_id] for frontend redirect

handleWebhook(array $payload, string $signature): MealCardTransaction
  └── Verifies HMAC-SHA256 signature against Razorpay webhook secret
  └── Idempotency: checks razorpay_payment_id UNIQUE before insert (BR-CAF-011)
  └── Calls creditBalance on success; dispatches SMS to parent via NTF

generateCardQr(MealCard $card): string
  └── Generates QR code SVG via SimpleSoftwareIO/simple-qrcode encoding card_number

generateStatement(MealCard $card, Carbon $from, Carbon $to): \Illuminate\Http\Response
  └── DomPDF PDF of caf_meal_card_transactions ordered by created_at
```

**`deductBalance()` Pseudocode:**
```
deductBalance(MealCard $card, float $amount, string $referenceType, int $referenceId): MealCardTransaction
  Step 1: DB::transaction() begins
  Step 2: SELECT...FOR UPDATE on caf_meal_cards row (prevents concurrent double-spend, BR-CAF-012)
  Step 3: If caf_allow_negative_balance=false AND (current_balance − amount) < 0:
            throw InsufficientBalanceException (rollback)
  Step 4: Compute new_balance = current_balance − amount
  Step 5: UPDATE caf_meal_cards SET current_balance = new_balance, total_debited += amount, updated_at = now()
  Step 6: INSERT caf_meal_card_transactions (
            meal_card_id, student_id, transaction_type='Debit', amount, balance_after=new_balance,
            reference_type=$referenceType, reference_id=$referenceId, created_at=now())
  Step 7: DB transaction commits
  Step 8: If new_balance < sys_settings('caf_low_balance_threshold'):
            dispatch(new LowBalanceNotificationJob($card))->onQueue('notifications')
  Step 9: Return MealCardTransaction
```

---

### 4. `PosService`

```
Service:    PosService
File:       app/Services/PosService.php
Depends on: MealCardService (for deductBalance on MealCard POS transactions)
Fires:      — (dietary conflict is a soft alert in apiStudentLookup response)
```

**Key Methods:**
```
openSession(array $data): PosSession
  └── Creates caf_pos_sessions record with opened_at = now(), closed_at = null

closeSession(PosSession $session): PosSession
  └── Sets closed_at = now(); computes reconciliation totals; marks is_active=0

processTransaction(PosSession $session, array $data): PosTransaction
  └── Validates session is active (closed_at IS NULL — BR-CAF-013)
  └── Snapshots items_json + dietary_flags_json at transaction time
  └── If MealCard: MealCardService::deductBalance(); sets balance_after
  └── Increments session total_transactions + total_card_debited or total_cash_collected

studentLookup(string $qrCode): array
  └── Decodes QR → card_number → MealCard → student; returns balance + dietary flags JSON

checkDietaryConflict(Student $student, array $itemIds): array
  └── Returns array of conflicting items based on student DietaryProfile food_preference

getSessionSummary(PosSession $session): array
  └── Returns session totals, transaction list, and reconciliation breakdown
```

---

### 5. `StockService`

```
Service:    StockService
File:       app/Services/StockService.php
Depends on: — (standalone; optional INV bridge via config check)
Fires:      StockReorderAlertJob (queued when qty ≤ reorder_level)
            FssaiExpiryAlertJob (triggered by caf:send-fssai-alerts Artisan)
```

**Key Methods:**
```
logConsumption(StockItem $item, array $data): ConsumptionLog
  └── DB transaction: INSERT consumption_log → UPDATE stock_items.current_quantity -= qty_used
  └── Post-commit: if current_quantity ≤ reorder_level → dispatchReorderAlert()

dispatchReorderAlert(StockItem $item): void
  └── Dispatch in-app notification to CAFETERIA_MGR via NTF
  └── If sys_settings('caf_inv_integration') = true AND INV module licensed:
         create inv_purchase_requisitions record (graceful degradation if INV not licensed)

checkFssaiExpiry(): void
  └── Supplier licenses: alert at 30 days + 7 days before fssai_expiry_date
  └── School FSSAI (caf_fssai_records): alert at 60 days + 30 days before expiry_date
  └── Dispatches FssaiExpiryAlertNotification via NTF module

generateFssaiAuditPdf(): \Illuminate\Http\Response
  └── DomPDF PDF of all caf_fssai_records ordered by audit_date DESC
```

---

### 6. `ReportService`

```
Service:    ReportService
File:       app/Services/ReportService.php
Depends on: — (reads from multiple caf_* tables; no service dependencies)
Fires:      — (no events)
```

**Key Methods:**
```
revenueReport(Carbon $from, Carbon $to): array
  └── Aggregates caf_orders + caf_pos_transactions by date; chunked for large ranges

orderSummaryReport(Carbon $from, Carbon $to, ?int $classId = null): array
  └── Per-student, per-class order counts and spend totals

wastageReport(Carbon $from, Carbon $to): array
  └── Planned headcount (orders + subscriptions) vs actual attendance (caf_meal_attendance)

getMealCardStatement(MealCard $card, Carbon $from, Carbon $to): Collection
  └── Returns caf_meal_card_transactions with balance_after column

exportCsv(array $data, array $headers, string $filename): \Symfony\Component\HttpFoundation\StreamedResponse
  └── Uses fputcsv() on php://temp; no external package

exportPdf(string $view, array $data, string $filename): \Illuminate\Http\Response
  └── DomPDF via barryvdh/laravel-dompdf; streams PDF response
```

---

## Section 3 — FormRequest Inventory (16 FormRequests)

**Namespace:** `Modules\Cafeteria\app\Http\Requests`
**File path:** `Modules/Cafeteria/app/Http/Requests/`

| # | Class | Controller Method(s) | Key Validation Rules |
|---|-------|---------------------|----------------------|
| 1 | `StoreMenuCategoryRequest` | MenuCategoryController@store,update | `name` required string max:100; `meal_time` required in:Breakfast,Lunch,Snacks,Dinner,Tuck_Shop; `code` nullable string max:20 unique:caf_menu_categories,code,{id}; `display_order` integer min:0 |
| 2 | `StoreMenuItemRequest` | MenuItemController@store,update | `name` required string max:150; `category_id` required exists:caf_menu_categories,id; `price` required numeric min:0.01; `food_type` required in:Veg,Non_Veg,Egg,Jain; `calories` nullable integer min:1; `photo_media_id` nullable exists:sys_media,id |
| 3 | `StoreDailyMenuRequest` | WeeklyMenuController@store,update | `week_start_date` required date; `items` array min:1; `items.*.menu_date` required date; `items.*.meal_category_id` required exists:caf_menu_categories,id; `items.*.menu_item_ids` array min:1; `items.*.menu_item_ids.*` exists:caf_menu_items,id |
| 4 | `StoreEventMealRequest` | EventMealController@store,update | `name` required string max:150; `event_date` required date after:today; `meal_category_id` required exists:caf_menu_categories,id; `target_class_ids_json` nullable array; `items` array; `items.*.menu_item_id` nullable exists:caf_menu_items,id; `items.*.free_text_item` required_without:items.*.menu_item_id |
| 5 | `StoreDietaryProfileRequest` | DietaryProfileController@store,update + apiUpdate | `student_id` required exists:std_students,id; `food_preference` required in:Veg,Non_Veg,Egg,Jain; `is_no_onion_garlic` boolean; `is_gluten_free` boolean; `is_nut_allergy` boolean; `is_dairy_free` boolean |
| 6 | `StoreOrderRequest` | OrderController@apiStore | `student_id` required exists:std_students,id; `order_date` required date after_or_equal:today; `meal_category_id` required exists:caf_menu_categories,id; `items` array min:1; `items.*.menu_item_id` required exists:caf_menu_items,id; `items.*.quantity` required integer min:1 max:10; `payment_mode` required in:MealCard,Cash,Counter,Subscription; cutoff window validated in OrderService (not FormRequest) |
| 7 | `IssueMealCardRequest` | MealCardController@store | `student_id` required exists:std_students,id; `card_number` required string max:20 unique:caf_meal_cards,card_number; `valid_from_date` required date; `valid_to_date` nullable date after:valid_from_date |
| 8 | `TopUpMealCardRequest` | MealCardController@topup + apiRazorpayTopup | `amount` required numeric min:50 max:5000; `payment_mode` required in:Online,Cash; `razorpay_payment_id` nullable string max:100 unique:caf_meal_card_transactions,razorpay_payment_id |
| 9 | `StorePosSessionRequest` | PosController@openSession | `session_date` required date; custom rule: no open session exists for same opened_by + session_date (closed_at IS NULL check) |
| 10 | `StorePosTransactionRequest` | PosController@transact + apiTransact | `pos_session_id` required exists:caf_pos_sessions,id; custom rule: session must be active (closed_at IS NULL — BR-CAF-013); `items` array min:1; `items.*.menu_item_id` required exists:caf_menu_items,id; `items.*.quantity` integer min:1; `payment_mode` required in:MealCard,Cash; `meal_card_id` required_if:payment_mode,MealCard |
| 11 | `StoreSubscriptionPlanRequest` | SubscriptionPlanController@store,update | `name` required string max:150; `billing_period` required in:Monthly,Termly,Annual; `price` required numeric min:0; `included_category_ids_json` required array min:1; `included_category_ids_json.*` exists:caf_menu_categories,id; `academic_term_id` nullable exists:sch_academic_term,id |
| 12 | `StoreSubscriptionEnrollmentRequest` | SubscriptionEnrollmentController@store | `subscription_plan_id` required exists:caf_subscription_plans,id; `student_id` nullable exists:std_students,id; `staff_id` nullable exists:sys_users,id; custom rule: exactly one of student_id or staff_id required; `start_date` required date; `end_date` nullable date after:start_date; `meal_card_id` nullable exists:caf_meal_cards,id |
| 13 | `StoreStockItemRequest` | StockController@store,update | `name` required string max:150; `category` required in:Grains,Pulses,Vegetables,Fruits,Dairy,Spices,Beverages,Condiments,Cleaning,Other; `unit` required string max:20; `reorder_level` required numeric min:0; `supplier_id` nullable exists:caf_suppliers,id; `cost_per_unit` nullable numeric min:0 |
| 14 | `LogConsumptionRequest` | StockController@logConsumption | `stock_item_id` required exists:caf_stock_items,id; `quantity_used` required numeric min:0.001; `log_date` required date before_or_equal:today; `meal_category_id` nullable exists:caf_menu_categories,id |
| 15 | `StoreSupplierRequest` | SupplierController@store,update | `name` required string max:150; `phone` nullable string max:20; `email` nullable email max:100; `fssai_license_no` nullable string max:50; `fssai_expiry_date` nullable date after:today; `supply_categories_json` nullable array; `supply_categories_json.*` in:Grains,Pulses,Vegetables,Fruits,Dairy,Spices,Beverages,Condiments,Cleaning,Other |
| 16 | `StoreFssaiRecordRequest` | FssaiController@store | `record_type` required in:License,Audit; `license_number` required_if:record_type,License string max:50; `license_type` required_if:record_type,License in:Basic,State,Central; `expiry_date` nullable date after:today (required for License type); `audit_date` required_if:record_type,Audit date; `audit_score` required_if:record_type,Audit integer min:1 max:10; `fssai_document_media_id` nullable exists:sys_media,id |

---

## Section 4 — Blade View Inventory (~50 Views)

**Base path:** `Modules/Cafeteria/resources/views/`
**Layout:** `layouts.cafeteria` (extends main tenant layout)

### Dashboard (1 view)

| View File | Route Name | Controller@Method | Description |
|-----------|-----------|-------------------|-------------|
| `dashboard.blade.php` | `cafeteria.dashboard` | CafeteriaController@dashboard | KPI cards: today's confirmed orders, today's revenue (INR), low-stock items count, active meal cards count |

---

### Menu Planning (~10 views)

| View File | Route Name | Controller@Method | Description |
|-----------|-----------|-------------------|-------------|
| `menu-categories/index.blade.php` | `cafeteria.menu-categories.index` | MenuCategoryController@index | Category list with meal_time badge, display_order, active toggle |
| `menu-categories/form.blade.php` | `cafeteria.menu-categories.create/edit` | @create/@edit | Shared create/edit form; ENUM select for meal_time |
| `menu-items/index.blade.php` | `cafeteria.menu-items.index` | MenuItemController@index | Item list with food_type chip, price, availability toggle (AJAX) |
| `menu-items/form.blade.php` | `cafeteria.menu-items.create/edit` | @create/@edit | Shared form; nutrition fields; photo upload; allergen textarea |
| `menu-items/show.blade.php` | `cafeteria.menu-items.show` | @show | Item detail with nutritional panel |
| `weekly-menu/index.blade.php` | `cafeteria.weekly-menu.index` | WeeklyMenuController@index | List of weekly menus with status badge; Publish/Archive buttons |
| `weekly-menu/planner.blade.php` | `cafeteria.weekly-menu.create/edit` | @create/@edit | **SCR-CAF-05** — 7-column × N-meal-category grid; Alpine.js drag-to-assign; UNIQUE slot blocked client-side; dish search sidebar |
| `weekly-menu/show.blade.php` | `cafeteria.weekly-menu.show` | @show | Read-only weekly grid; shows Published/Draft badge |
| `event-meals/index.blade.php` | `cafeteria.event-meals.index` | EventMealController@index | Event meal list with event_date, target classes, status |
| `event-meals/form.blade.php` | `cafeteria.event-meals.create/edit` | @create/@edit | Event form with class-group multi-select; item assignment with free-text fallback |

---

### Dietary & Subscriptions (~6 views)

| View File | Route Name | Controller@Method | Description |
|-----------|-----------|-------------------|-------------|
| `dietary-profiles/index.blade.php` | `cafeteria.dietary-profiles.index` | DietaryProfileController@index | Searchable list of student dietary profiles with flag chips |
| `dietary-profiles/edit.blade.php` | `cafeteria.dietary-profiles.edit` | @edit | Toggle checkboxes for all restriction flags; food_preference dropdown |
| `subscription-plans/index.blade.php` | `cafeteria.subscription-plans.index` | SubscriptionPlanController@index | Plan cards with billing_period, price, included categories |
| `subscription-plans/form.blade.php` | `cafeteria.subscription-plans.create/edit` | @create/@edit | Plan form with multi-select for included categories and hostel/staff flags |
| `subscription-enrollments/index.blade.php` | `cafeteria.subscription-enrollments.index` | SubscriptionEnrollmentController@index | Enrollment list filtered by plan; status badge; Cancel button |
| `subscription-enrollments/create.blade.php` | `cafeteria.subscription-enrollments.store` *(form)* | SubscriptionEnrollmentController@store | Student/staff search and plan selection |

---

### Orders & Kitchen (~5 views)

| View File | Route Name | Controller@Method | Description |
|-----------|-----------|-------------------|-------------|
| `orders/index.blade.php` | `cafeteria.orders.index` | OrderController@index | Filterable order list by date, meal category, status; bulk mark-served |
| `orders/show.blade.php` | `cafeteria.orders.show` | @show | Order detail with line items, dietary conflict flags, status timeline |
| `orders/kitchen-view.blade.php` | `cafeteria.kitchen-view` | @kitchenView | **SCR-CAF-13** — Aggregated item totals; dietary flag counts per item; subscription headcount; Print button |
| `orders/kitchen-sheet-pdf.blade.php` | *(PDF template)* | @printKitchenSheet | DomPDF print-optimised kitchen preparation sheet |
| `orders/staff-meal-log.blade.php` | `cafeteria.staff-meals.index` | *(StaffMealLog via OrderController view)* | Staff meal log table with payroll_deduction_flag indicator |

---

### POS (~4 views)

| View File | Route Name | Controller@Method | Description |
|-----------|-----------|-------------------|-------------|
| `pos/index.blade.php` | `cafeteria.pos.index` | PosController@index | **SCR-CAF-14** — Touch-friendly item grid (large tiles); QR scan input; real-time balance chip; dietary conflict alert modal (Alpine.js) |
| `pos/session-summary.blade.php` | `cafeteria.pos.sessions.show` | @showSession | Session reconciliation: cash collected, card debited, transaction count; Close Session button |
| `pos/partials/_dietary-alert.blade.php` | *(partial)* | — | Dietary conflict modal: lists conflicting items; admin-override button |
| `pos/partials/_balance-chip.blade.php` | *(partial)* | — | Inline balance display with colour: green ≥ threshold, amber < threshold |

---

### Meal Attendance (~2 views)

| View File | Route Name | Controller@Method | Description |
|-----------|-----------|-------------------|-------------|
| `meal-attendance/index.blade.php` | `cafeteria.meal-attendance.index` | MealAttendanceController@index | Date-filtered attendance log with scan_method badge; export CSV |
| `meal-attendance/partials/_scan-result.blade.php` | *(partial)* | — | AJAX QR scan result — success chip or "already scanned" warning |

---

### Meal Cards (~4 views)

| View File | Route Name | Controller@Method | Description |
|-----------|-----------|-------------------|-------------|
| `meal-cards/index.blade.php` | `cafeteria.meal-cards.index` | MealCardController@index | Card list with current_balance, student name, validity; Issue New Card button |
| `meal-cards/issue.blade.php` | `cafeteria.meal-cards.store` *(form)* | @store | **SCR-CAF-18 (partial)** — Issue card form; student lookup |
| `meal-cards/topup.blade.php` | `cafeteria.meal-cards.topup` | @topup | **SCR-CAF-18** — Cash top-up form; "Pay Online" → Razorpay redirect; balance shown after return |
| `meal-cards/statement.blade.php` | `cafeteria.meal-cards.statement` | @statement | **SCR-CAF-19** — Paginated ledger with `balance_after` column; Export PDF (DomPDF); date range filter |

---

### Stock & Suppliers (~6 views)

| View File | Route Name | Controller@Method | Description |
|-----------|-----------|-------------------|-------------|
| `stock/index.blade.php` | `cafeteria.stock.index` | StockController@index | Stock list with current_quantity vs reorder_level; alert badge when below threshold |
| `stock/form.blade.php` | `cafeteria.stock.create/edit` | @create/@edit | Stock item form with category ENUM, unit, reorder fields |
| `stock/show.blade.php` | `cafeteria.stock.show` | @show | Item detail with consumption history log; Log Consumption button |
| `stock/log-consumption.blade.php` | *(modal/partial)* | @logConsumption | Inline consumption log form (quantity, date, notes) |
| `suppliers/index.blade.php` | `cafeteria.suppliers.index` | SupplierController@index | Supplier list with FSSAI expiry badge (red if < 30 days) |
| `suppliers/form.blade.php` | `cafeteria.suppliers.create/edit` | @create/@edit | Supplier form with FSSAI fields; supply_categories multi-select |

---

### FSSAI Compliance (~2 views)

| View File | Route Name | Controller@Method | Description |
|-----------|-----------|-------------------|-------------|
| `fssai/index.blade.php` | `cafeteria.fssai.index` | FssaiController@index | License and Audit records list; expiry alerts highlighted |
| `fssai/form.blade.php` | `cafeteria.fssai.store` *(form)* | @store | Conditional form: License fields vs Audit fields based on record_type |

---

### Reports (~5 views)

| View File | Route Name | Controller@Method | Description |
|-----------|-----------|-------------------|-------------|
| `reports/revenue.blade.php` | `cafeteria.reports.revenue` | CafeteriaReportController@revenue | Revenue by date range; breakdown by payment_mode; CSV/PDF export |
| `reports/order-summary.blade.php` | `cafeteria.reports.orders` | @orderSummary | Per-student, per-class order count and spend; class filter |
| `reports/wastage.blade.php` | `cafeteria.reports.wastage` | @wastage | Planned headcount vs actual attendance; wastage % per item |
| `reports/meal-card-statements.blade.php` | `cafeteria.reports.statements` | @mealCardStatements | Searchable student card statement with balance_after column |
| `reports/fssai-audit-pdf.blade.php` | *(PDF template)* | FssaiController (DomPDF) | Print-ready FSSAI audit log |

---

### Shared Partials (~6 partials)

| Partial File | Used In | Description |
|-------------|---------|-------------|
| `partials/_pagination.blade.php` | All list views | Standard pagination with per-page selector |
| `partials/_export-buttons.blade.php` | All report views | CSV and PDF export button group |
| `partials/_dietary-flags.blade.php` | Kitchen view, POS, orders | Renders dietary restriction chips (Veg/Jain/Nut-free etc.) |
| `partials/_qr-display.blade.php` | Meal card statement | Renders SVG QR code via SimpleSoftwareIO/simple-qrcode |
| `partials/_modal-confirm.blade.php` | Destroy, cancel, publish actions | Generic Alpine.js confirmation modal |
| `partials/_balance-chip.blade.php` | POS, card list | Colour-coded balance display chip |

**Total views: ~51** (1 + 10 + 6 + 5 + 4 + 2 + 4 + 6 + 2 + 5 + 6 = 51)

---

## Section 5 — Complete Route List

**Web middleware (all):** `['auth', 'tenant', 'EnsureTenantHasModule:Cafeteria']`
**API middleware (all):** `['auth:sanctum', 'tenant']` (exceptions noted)

### 5.1 Web Routes (63 routes)

| # | Method | URI | Route Name | Controller@Method | FR |
|---|--------|-----|-----------|-------------------|----|
| 1 | GET | `/cafeteria` | `cafeteria.dashboard` | CafeteriaController@dashboard | CAF-14 |
| 2 | GET | `/cafeteria/menu-categories` | `cafeteria.menu-categories.index` | MenuCategoryController@index | CAF-01 |
| 3 | GET | `/cafeteria/menu-categories/create` | `cafeteria.menu-categories.create` | @create | CAF-01 |
| 4 | POST | `/cafeteria/menu-categories` | `cafeteria.menu-categories.store` | @store | CAF-01 |
| 5 | GET | `/cafeteria/menu-categories/{category}` | `cafeteria.menu-categories.show` | @show | CAF-01 |
| 6 | GET | `/cafeteria/menu-categories/{category}/edit` | `cafeteria.menu-categories.edit` | @edit | CAF-01 |
| 7 | PUT | `/cafeteria/menu-categories/{category}` | `cafeteria.menu-categories.update` | @update | CAF-01 |
| 8 | DELETE | `/cafeteria/menu-categories/{category}` | `cafeteria.menu-categories.destroy` | @destroy | CAF-01 |
| 9 | PATCH | `/cafeteria/menu-categories/{category}/toggle` | `cafeteria.menu-categories.toggle` | @toggle | CAF-01 |
| 10 | GET | `/cafeteria/menu-items` | `cafeteria.menu-items.index` | MenuItemController@index | CAF-02 |
| 11 | GET | `/cafeteria/menu-items/create` | `cafeteria.menu-items.create` | @create | CAF-02 |
| 12 | POST | `/cafeteria/menu-items` | `cafeteria.menu-items.store` | @store | CAF-02 |
| 13 | GET | `/cafeteria/menu-items/{item}` | `cafeteria.menu-items.show` | @show | CAF-02 |
| 14 | GET | `/cafeteria/menu-items/{item}/edit` | `cafeteria.menu-items.edit` | @edit | CAF-02 |
| 15 | PUT | `/cafeteria/menu-items/{item}` | `cafeteria.menu-items.update` | @update | CAF-02 |
| 16 | DELETE | `/cafeteria/menu-items/{item}` | `cafeteria.menu-items.destroy` | @destroy | CAF-02 |
| 17 | PATCH | `/cafeteria/menu-items/{item}/toggle-availability` | `cafeteria.menu-items.toggle-availability` | @toggleAvailability | CAF-02 |
| 18 | GET | `/cafeteria/weekly-menu` | `cafeteria.weekly-menu.index` | WeeklyMenuController@index | CAF-03 |
| 19 | GET | `/cafeteria/weekly-menu/create` | `cafeteria.weekly-menu.create` | @create | CAF-03 |
| 20 | POST | `/cafeteria/weekly-menu` | `cafeteria.weekly-menu.store` | @store | CAF-03 |
| 21 | GET | `/cafeteria/weekly-menu/{menu}` | `cafeteria.weekly-menu.show` | @show | CAF-03 |
| 22 | GET | `/cafeteria/weekly-menu/{menu}/edit` | `cafeteria.weekly-menu.edit` | @edit | CAF-03 |
| 23 | PUT | `/cafeteria/weekly-menu/{menu}` | `cafeteria.weekly-menu.update` | @update | CAF-03 |
| 24 | PATCH | `/cafeteria/weekly-menu/{menu}/publish` | `cafeteria.weekly-menu.publish` | @publish | CAF-03 |
| 25 | PATCH | `/cafeteria/weekly-menu/{menu}/archive` | `cafeteria.weekly-menu.archive` | @archive | CAF-03 |
| 26 | GET | `/cafeteria/event-meals` | `cafeteria.event-meals.index` | EventMealController@index | CAF-04 |
| 27 | GET | `/cafeteria/event-meals/create` | `cafeteria.event-meals.create` | @create | CAF-04 |
| 28 | POST | `/cafeteria/event-meals` | `cafeteria.event-meals.store` | @store | CAF-04 |
| 29 | GET | `/cafeteria/event-meals/{meal}` | `cafeteria.event-meals.show` | @show | CAF-04 |
| 30 | GET | `/cafeteria/event-meals/{meal}/edit` | `cafeteria.event-meals.edit` | @edit | CAF-04 |
| 31 | PUT | `/cafeteria/event-meals/{meal}` | `cafeteria.event-meals.update` | @update | CAF-04 |
| 32 | PATCH | `/cafeteria/event-meals/{meal}/publish` | `cafeteria.event-meals.publish` | @publish | CAF-04 |
| 33 | GET | `/cafeteria/dietary-profiles` | `cafeteria.dietary-profiles.index` | DietaryProfileController@index | CAF-05 |
| 34 | POST | `/cafeteria/dietary-profiles` | `cafeteria.dietary-profiles.store` | @store | CAF-05 |
| 35 | GET | `/cafeteria/dietary-profiles/{profile}` | `cafeteria.dietary-profiles.show` | @show | CAF-05 |
| 36 | GET | `/cafeteria/dietary-profiles/{profile}/edit` | `cafeteria.dietary-profiles.edit` | @edit | CAF-05 |
| 37 | PUT | `/cafeteria/dietary-profiles/{profile}` | `cafeteria.dietary-profiles.update` | @update | CAF-05 |
| 38 | GET | `/cafeteria/subscription-plans` | `cafeteria.subscription-plans.index` | SubscriptionPlanController@index | CAF-06 |
| 39 | GET | `/cafeteria/subscription-plans/create` | `cafeteria.subscription-plans.create` | @create | CAF-06 |
| 40 | POST | `/cafeteria/subscription-plans` | `cafeteria.subscription-plans.store` | @store | CAF-06 |
| 41 | GET | `/cafeteria/subscription-plans/{plan}` | `cafeteria.subscription-plans.show` | @show | CAF-06 |
| 42 | GET | `/cafeteria/subscription-plans/{plan}/edit` | `cafeteria.subscription-plans.edit` | @edit | CAF-06 |
| 43 | PUT | `/cafeteria/subscription-plans/{plan}` | `cafeteria.subscription-plans.update` | @update | CAF-06 |
| 44 | PATCH | `/cafeteria/subscription-plans/{plan}/toggle-status` | `cafeteria.subscription-plans.toggle-status` | @toggleStatus | CAF-06 |
| 45 | GET | `/cafeteria/subscription-enrollments` | `cafeteria.subscription-enrollments.index` | SubscriptionEnrollmentController@index | CAF-06 |
| 46 | POST | `/cafeteria/subscription-enrollments` | `cafeteria.subscription-enrollments.store` | @store | CAF-06 |
| 47 | GET | `/cafeteria/subscription-enrollments/{enrollment}` | `cafeteria.subscription-enrollments.show` | @show | CAF-06 |
| 48 | DELETE | `/cafeteria/subscription-enrollments/{enrollment}` | `cafeteria.subscription-enrollments.destroy` | @destroy | CAF-06 |
| 49 | GET | `/cafeteria/orders` | `cafeteria.orders.index` | OrderController@index | CAF-07 |
| 50 | GET | `/cafeteria/orders/{order}` | `cafeteria.orders.show` | @show | CAF-07 |
| 51 | PATCH | `/cafeteria/orders/{order}/status` | `cafeteria.orders.update-status` | @updateStatus | CAF-07 |
| 52 | PATCH | `/cafeteria/orders/{order}/cancel` | `cafeteria.orders.cancel` | @cancel | CAF-07 |
| 53 | GET | `/cafeteria/kitchen-view` | `cafeteria.kitchen-view` | @kitchenView | CAF-14 |
| 54 | GET | `/cafeteria/kitchen-view/print` | `cafeteria.kitchen-view.print` | @printKitchenSheet | CAF-14 |
| 55 | GET | `/cafeteria/meal-cards` | `cafeteria.meal-cards.index` | MealCardController@index | CAF-08 |
| 56 | POST | `/cafeteria/meal-cards` | `cafeteria.meal-cards.store` | @store | CAF-08 |
| 57 | POST | `/cafeteria/meal-cards/{card}/topup` | `cafeteria.meal-cards.topup` | @topup | CAF-08 |
| 58 | GET | `/cafeteria/meal-cards/{card}/statement` | `cafeteria.meal-cards.statement` | @statement | CAF-08 |
| 59 | GET | `/cafeteria/meal-attendance` | `cafeteria.meal-attendance.index` | MealAttendanceController@index | CAF-09 |
| 60 | GET | `/cafeteria/pos` | `cafeteria.pos.index` | PosController@index | CAF-10 |
| 61 | POST | `/cafeteria/pos/sessions` | `cafeteria.pos.sessions.open` | @openSession | CAF-10 |
| 62 | PATCH | `/cafeteria/pos/sessions/{session}/close` | `cafeteria.pos.sessions.close` | @closeSession | CAF-10 |
| 63 | GET | `/cafeteria/pos/sessions/{session}` | `cafeteria.pos.sessions.show` | @showSession | CAF-10 |
| 64 | POST | `/cafeteria/pos/transact` | `cafeteria.pos.transact` | @transact | CAF-10 |
| 65 | GET | `/cafeteria/stock` | `cafeteria.stock.index` | StockController@index | CAF-11 |
| 66 | GET | `/cafeteria/stock/create` | `cafeteria.stock.create` | @create | CAF-11 |
| 67 | POST | `/cafeteria/stock` | `cafeteria.stock.store` | @store | CAF-11 |
| 68 | GET | `/cafeteria/stock/{item}` | `cafeteria.stock.show` | @show | CAF-11 |
| 69 | GET | `/cafeteria/stock/{item}/edit` | `cafeteria.stock.edit` | @edit | CAF-11 |
| 70 | PUT | `/cafeteria/stock/{item}` | `cafeteria.stock.update` | @update | CAF-11 |
| 71 | DELETE | `/cafeteria/stock/{item}` | `cafeteria.stock.destroy` | @destroy | CAF-11 |
| 72 | POST | `/cafeteria/stock/{item}/consumption` | `cafeteria.stock.log-consumption` | @logConsumption | CAF-11 |
| 73 | GET | `/cafeteria/suppliers` | `cafeteria.suppliers.index` | SupplierController@index | CAF-11 |
| 74 | GET | `/cafeteria/suppliers/create` | `cafeteria.suppliers.create` | @create | CAF-11 |
| 75 | POST | `/cafeteria/suppliers` | `cafeteria.suppliers.store` | @store | CAF-11 |
| 76 | GET | `/cafeteria/suppliers/{supplier}` | `cafeteria.suppliers.show` | @show | CAF-11 |
| 77 | GET | `/cafeteria/suppliers/{supplier}/edit` | `cafeteria.suppliers.edit` | @edit | CAF-11 |
| 78 | PUT | `/cafeteria/suppliers/{supplier}` | `cafeteria.suppliers.update` | @update | CAF-11 |
| 79 | DELETE | `/cafeteria/suppliers/{supplier}` | `cafeteria.suppliers.destroy` | @destroy | CAF-11 |
| 80 | GET | `/cafeteria/fssai` | `cafeteria.fssai.index` | FssaiController@index | CAF-12 |
| 81 | POST | `/cafeteria/fssai` | `cafeteria.fssai.store` | @store | CAF-12 |
| 82 | GET | `/cafeteria/fssai/{record}` | `cafeteria.fssai.show` | @show | CAF-12 |
| 83 | GET | `/cafeteria/fssai/{record}/document` | `cafeteria.fssai.document` | @download | CAF-12 |
| 84 | GET | `/cafeteria/reports/revenue` | `cafeteria.reports.revenue` | CafeteriaReportController@revenue | CAF-14 |
| 85 | GET | `/cafeteria/reports/orders` | `cafeteria.reports.orders` | @orderSummary | CAF-14 |
| 86 | GET | `/cafeteria/reports/wastage` | `cafeteria.reports.wastage` | @wastage | CAF-14 |
| 87 | GET | `/cafeteria/reports/statements` | `cafeteria.reports.statements` | @mealCardStatements | CAF-14 |
| 88 | GET | `/cafeteria/reports/revenue/export` | `cafeteria.reports.revenue.export` | @exportRevenue | CAF-14 |
| 89 | GET | `/cafeteria/reports/orders/export` | `cafeteria.reports.orders.export` | @exportOrders | CAF-14 |
| 90 | GET | `/cafeteria/reports/wastage/export` | `cafeteria.reports.wastage.export` | @exportWastage | CAF-14 |
| 91 | GET | `/cafeteria/reports/statements/export` | `cafeteria.reports.statements.export` | @exportStatements | CAF-14 |

**Web total: 91 routes**

### 5.2 API Routes (15 routes)

| # | Method | URI | Route Name | Controller@Method | Middleware | FR |
|---|--------|-----|-----------|-------------------|------------|-----|
| 1 | GET | `/api/v1/cafeteria/weekly-menu/current` | `cafeteria.api.weekly-menu.current` | WeeklyMenuController@apiCurrentWeek | auth:sanctum,tenant | CAF-03 |
| 2 | GET | `/api/v1/cafeteria/dietary-profiles/{student}` | `cafeteria.api.dietary-profiles.get` | DietaryProfileController@apiGet | auth:sanctum,tenant | CAF-05 |
| 3 | PUT | `/api/v1/cafeteria/dietary-profiles/{student}` | `cafeteria.api.dietary-profiles.update` | DietaryProfileController@apiUpdate | auth:sanctum,tenant | CAF-05 |
| 4 | POST | `/api/v1/cafeteria/orders` | `cafeteria.api.orders.store` | OrderController@apiStore | auth:sanctum,tenant | CAF-07 |
| 5 | GET | `/api/v1/cafeteria/orders` | `cafeteria.api.orders.index` | OrderController@apiIndex | auth:sanctum,tenant | CAF-07 |
| 6 | PATCH | `/api/v1/cafeteria/orders/{order}/cancel` | `cafeteria.api.orders.cancel` | OrderController@apiCancel | auth:sanctum,tenant | CAF-07 |
| 7 | GET | `/api/v1/cafeteria/kitchen-view` | `cafeteria.api.kitchen-view` | OrderController@apiKitchenView | auth:sanctum,tenant | CAF-14 |
| 8 | GET | `/api/v1/cafeteria/meal-cards/{card}/balance` | `cafeteria.api.meal-cards.balance` | MealCardController@apiBalance | auth:sanctum,tenant | CAF-08 |
| 9 | GET | `/api/v1/cafeteria/meal-cards/{card}/transactions` | `cafeteria.api.meal-cards.transactions` | MealCardController@apiTransactions | auth:sanctum,tenant | CAF-08 |
| 10 | POST | `/api/v1/cafeteria/meal-cards/{card}/topup` | `cafeteria.api.meal-cards.topup` | MealCardController@apiRazorpayTopup | auth:sanctum,tenant | CAF-08 |
| 11 | POST | `/api/v1/cafeteria/meal-card/topup/webhook` | `cafeteria.api.meal-cards.webhook` | MealCardController@apiRazorpayWebhook | **withoutMiddleware(['auth:sanctum'])** | CAF-08 |
| 12 | POST | `/api/v1/cafeteria/meal-attendance/scan` | `cafeteria.api.meal-attendance.scan` | MealAttendanceController@apiScan | auth:sanctum,tenant | CAF-09 |
| 13 | GET | `/api/v1/cafeteria/pos/student-lookup` | `cafeteria.api.pos.student-lookup` | PosController@apiStudentLookup | auth:sanctum,tenant | CAF-10 |
| 14 | POST | `/api/v1/cafeteria/pos/transact` | `cafeteria.api.pos.transact` | PosController@apiTransact | auth:sanctum,tenant | CAF-10 |
| 15 | GET | `/api/v1/cafeteria/staff-meals` | `cafeteria.api.staff-meals.index` | *(via OrderController)* | auth:sanctum,tenant | CAF-13 |

**API total: 15 routes | Grand total: ~106 routes**

> **Special routes:**
> - Route #11 (Razorpay webhook): `->withoutMiddleware(['auth:sanctum'])` — public endpoint; idempotency via `razorpay_payment_id` UNIQUE (BR-CAF-011)
> - Route #12 (QR attendance scan): Duplicate scan returns `200 OK` with existing record — UNIQUE constraint prevents duplicate insert; application handles `UniqueConstraintViolationException` gracefully
> - Route #54 (kitchen print): Streams DomPDF PDF via `return response()->streamDownload()`

---

## Section 6 — Implementation Phases (6 Phases)

All phases follow the pattern: Models → Service → FormRequests → Controllers → Views → Tests.

---

### Phase 1 — Menu Planning Masters
**FRs:** CAF-01, CAF-02
**Pre-requisites:** None (only sys_* cross-module deps)
**Estimated tests:** 4

**Files to create:**
```
Controllers:
  CafeteriaController.php
  MenuCategoryController.php
  MenuItemController.php

Services:
  MenuService.php  (category CRUD, item CRUD, availability toggle)

Models:
  MenuCategory.php   ($fillable, softDeletes, belongsToMany menuItems)
  MenuItem.php       ($fillable, softDeletes, belongsTo MenuCategory, belongsTo Media)

FormRequests:
  StoreMenuCategoryRequest.php
  StoreMenuItemRequest.php

Seeders:
  CafMenuCategorySeeder.php    (already created in Phase 2)
  CafSeederRunner.php          (already created in Phase 2)

Views:
  dashboard.blade.php
  menu-categories/index.blade.php
  menu-categories/form.blade.php
  menu-items/index.blade.php
  menu-items/form.blade.php
  menu-items/show.blade.php

Policies:
  MenuCategoryPolicy.php
  MenuItemPolicy.php
```

**Tests:**
| File | Tests | Key Scenarios |
|------|-------|--------------|
| `MenuCategoryCrudTest.php` | 5 | Create/read/update/delete; `code` unique; `is_active` toggle |
| `MenuItemCrudTest.php` | 5 | Create with nutrition; photo_media_id nullable; food_type ENUM; `toggleAvailability` AJAX response |

---

### Phase 2 — Weekly Menu & Event Meals
**FRs:** CAF-03, CAF-04
**Pre-requisites:** Phase 1 (caf_menu_categories, caf_menu_items)

**Files to create:**
```
Controllers:
  WeeklyMenuController.php
  EventMealController.php

Services:
  MenuService.php  (extend: publish, archive, publishEventMeal, archiveOldMenus)

Models:
  DailyMenu.php           (softDeletes, hasMany DailyMenuItemJnt, status casting)
  DailyMenuItemJnt.php    (belongsTo DailyMenu, belongsTo MenuItem, belongsTo MenuCategory)
  EventMeal.php           (softDeletes, hasMany EventMealItemJnt)
  EventMealItemJnt.php    (belongsTo EventMeal, nullable belongsTo MenuItem)

FormRequests:
  StoreDailyMenuRequest.php
  StoreEventMealRequest.php

Events / Listeners:
  MenuPublished.php   (event payload: DailyMenu or EventMeal)
  MenuPublishedListener.php  (dispatches NTF push + SMS to all active students + parents)

Artisan Commands:
  ArchiveOldMenusCommand.php  (caf:archive-old-menus — daily midnight)

Views:
  weekly-menu/index.blade.php
  weekly-menu/planner.blade.php   (Alpine.js 7-day grid — SCR-CAF-05)
  weekly-menu/show.blade.php
  event-meals/index.blade.php
  event-meals/form.blade.php

Policies:
  DailyMenuPolicy.php
  EventMealPolicy.php
```

**Tests:**
| File | Tests | Key Scenarios |
|------|-------|--------------|
| `WeeklyMenuPublishTest.php` | 6 | Publish fires MenuPublished event; `Notification::fake()` verifies NTF dispatch; publish blocked if no items (BR-CAF-005) |
| `MenuPublishBlockedTest.php` | 3 | Cannot publish Draft with 0 items; UNIQUE menu_date rejects duplicate (BR-CAF-018) |
| `EventMealPublishTest.php` | 4 | Publish event meal; null target_class_ids sends to all; free-text items allowed (menu_item_id = null) |

---

### Phase 3 — Orders, Dietary & Subscriptions
**FRs:** CAF-05, CAF-06, CAF-07
**Pre-requisites:** Phase 2 (caf_daily_menus); STD module (std_students)

**Files to create:**
```
Controllers:
  DietaryProfileController.php
  SubscriptionPlanController.php
  SubscriptionEnrollmentController.php
  OrderController.php

Services:
  OrderService.php   (placeOrder, cancelOrder, markServed, getKitchenView, printKitchenSheet, generateOrderNumber)

Models:
  DietaryProfile.php          (softDeletes, belongsTo Student, UNIQUE student_id)
  SubscriptionPlan.php        (softDeletes, hasMany SubscriptionEnrollment)
  SubscriptionEnrollment.php  (softDeletes, belongsTo Plan, nullable student, nullable staff)
  Order.php                   (softDeletes, hasMany OrderItem, belongsTo MealCard, belongsTo Student)
  OrderItem.php               (belongsTo Order, belongsTo MenuItem; NO softDeletes)

FormRequests:
  StoreDietaryProfileRequest.php
  StoreSubscriptionPlanRequest.php
  StoreSubscriptionEnrollmentRequest.php
  StoreOrderRequest.php

Views:
  dietary-profiles/index.blade.php
  dietary-profiles/edit.blade.php
  subscription-plans/index.blade.php
  subscription-plans/form.blade.php
  subscription-enrollments/index.blade.php
  subscription-enrollments/create.blade.php
  orders/index.blade.php
  orders/show.blade.php
  orders/kitchen-view.blade.php   (SCR-CAF-13)
  orders/kitchen-sheet-pdf.blade.php

Policies:
  DietaryProfilePolicy.php
  SubscriptionPlanPolicy.php
  SubscriptionEnrollmentPolicy.php
  OrderPolicy.php
```

**Tests:**
| File | Tests | Key Scenarios |
|------|-------|--------------|
| `OrderPlacementTest.php` | 6 | Happy path; balance deducted; unit_price snapshot not live price |
| `OrderCutoffTest.php` | 3 | Order rejected 1 min past cutoff; accepted 1 min before |
| `DietaryConflictWarningTest.php` | 4 | Jain student + Non-Veg item → warning; admin override; student cannot override |
| `OrderCancellationRefundTest.php` | 3 | Cancel refunds balance; Served order cannot be cancelled |
| `KitchenConsolidationTest.php` | 4 | Subscription headcount included; composite index used; no N+1 |
| `SubscriptionEnrollmentTest.php` | 3 | Enroll student; cancel; exactly one of student_id/staff_id required |

---

### Phase 4 — Meal Cards & POS
**FRs:** CAF-08, CAF-09, CAF-10
**Pre-requisites:** Phase 3 (caf_orders); Razorpay SDK configured

**Files to create:**
```
Controllers:
  MealCardController.php
  MealAttendanceController.php
  PosController.php

Services:
  MealCardService.php  (issueCard, deductBalance, creditBalance, refundBalance,
                        initiateRazorpayTopup, handleWebhook, generateCardQr, generateStatement)
  PosService.php       (openSession, closeSession, processTransaction, studentLookup,
                        checkDietaryConflict, getSessionSummary)

Jobs:
  LowBalanceNotificationJob.php   (queued — dispatched by MealCardService after every debit)

Models:
  MealCard.php              (softDeletes, UNIQUE student_id + card_number; hasMany Transactions)
  MealCardTransaction.php   (NO softDeletes; razorpay_payment_id nullable UNIQUE)
  MealAttendance.php        (NO is_active/updated_at/softDeletes; immutable scan)
  PosSession.php            (NO softDeletes; hasMany PosTransactions)
  PosTransaction.php        (NO softDeletes; items_json cast as array)

FormRequests:
  IssueMealCardRequest.php
  TopUpMealCardRequest.php
  StorePosSessionRequest.php
  StorePosTransactionRequest.php

Views:
  meal-cards/index.blade.php
  meal-cards/issue.blade.php
  meal-cards/topup.blade.php      (SCR-CAF-18)
  meal-cards/statement.blade.php  (SCR-CAF-19)
  meal-attendance/index.blade.php
  pos/index.blade.php             (SCR-CAF-14)
  pos/session-summary.blade.php
  pos/partials/_dietary-alert.blade.php
  pos/partials/_balance-chip.blade.php

Policies:
  MealCardPolicy.php
  MealAttendancePolicy.php
  PosSessionPolicy.php
```

**Tests:**
| File | Tests | Key Scenarios |
|------|-------|--------------|
| `MealCardTopUpCashTest.php` | 4 | Cash top-up credits balance; balance_after snapshot correct |
| `RazorpayWebhookTest.php` | 5 | Valid HMAC accepted; invalid HMAC rejected 401; duplicate payment_id → idempotent 200 no double-credit (BR-CAF-011) |
| `MealCardNegativeBalanceTest.php` | 3 | Deduct below zero blocked when caf_allow_negative_balance=false (BR-CAF-003); allowed when true |
| `PosSessionTest.php` | 4 | Open session; transaction on active session; transaction blocked when session closed (BR-CAF-013) |
| `QrAttendanceScanTest.php` | 3 | First scan inserts record; duplicate scan returns 200 with existing record (UNIQUE idempotency) |
| `MealCardTransactionLedgerTest.php` | 4 | balance_after = prior_balance ± amount on each transaction *(Unit test)* |
| `OrderNumberFormatTest.php` | 2 | Order number matches `CAF-\d{4}-[A-Z0-9]{8}` *(Unit test)* |

> **Note on `SELECT...FOR UPDATE` test:** Concurrent deduction test must use real tenant DB (not SQLite in-memory) to verify row-lock behaviour. Use `DB::transaction()` in test with two sequential deductions to verify balance integrity.

---

### Phase 5 — Stock, Suppliers & FSSAI
**FRs:** CAF-11, CAF-12
**Pre-requisites:** None beyond Phase 1 (caf_menu_categories for meal_category_id)

**Files to create:**
```
Controllers:
  StockController.php
  SupplierController.php
  FssaiController.php

Services:
  StockService.php  (logConsumption, dispatchReorderAlert, checkFssaiExpiry, generateFssaiAuditPdf)

Jobs:
  StockReorderAlertJob.php    (queued — dispatched by StockService after consumption log)

Events:
  StockReorderAlert.php

Models:
  Supplier.php         (softDeletes, hasMany StockItem)
  StockItem.php        (softDeletes, belongsTo Supplier, hasMany ConsumptionLog)
  ConsumptionLog.php   (NO is_active/softDeletes; belongsTo StockItem)
  FssaiRecord.php      (NO softDeletes; nullable belongsTo Media)

FormRequests:
  StoreStockItemRequest.php
  LogConsumptionRequest.php
  StoreSupplierRequest.php
  StoreFssaiRecordRequest.php

Artisan Commands:
  CheckStockReorderCommand.php    (caf:check-stock-reorder — daily morning)
  SendFssaiAlertsCommand.php      (caf:send-fssai-alerts — daily morning)

Views:
  stock/index.blade.php
  stock/form.blade.php
  stock/show.blade.php
  stock/log-consumption.blade.php
  suppliers/index.blade.php
  suppliers/form.blade.php
  fssai/index.blade.php
  fssai/form.blade.php
  reports/fssai-audit-pdf.blade.php   (DomPDF template)

Policies:
  StockItemPolicy.php
  SupplierPolicy.php
  FssaiRecordPolicy.php
```

**Tests:**
| File | Tests | Key Scenarios |
|------|-------|--------------|
| `StockReorderAlertTest.php` | 5 | Consumption deducts qty; `Queue::fake()` verifies StockReorderAlertJob dispatched when qty ≤ reorder_level; INV bridge creates PR when caf_inv_integration=true; graceful skip when INV not licensed |
| `FssaiExpiryAlertTest.php` | 4 | Supplier 30-day alert; supplier 7-day alert; school license 60-day + 30-day alerts |

---

### Phase 6 — Staff Meals, Reports & Cross-Module Integration
**FRs:** CAF-13, CAF-14, CAF-15
**Pre-requisites:** All prior phases

**Files to create:**
```
Controllers:
  CafeteriaReportController.php

Services:
  ReportService.php   (revenueReport, orderSummaryReport, wastageReport,
                       getMealCardStatement, exportCsv, exportPdf)

Models:
  StaffMealLog.php   (NO is_active/softDeletes; belongsTo sys_users as staff)

Views:
  orders/staff-meal-log.blade.php
  reports/revenue.blade.php
  reports/order-summary.blade.php
  reports/wastage.blade.php
  reports/meal-card-statements.blade.php

Cross-Module Integration:
  HST Bridge:
    → Listen for HostelAdmissionEvent (dispatched by HST module)
    → HostelAdmissionListener checks sys_settings('caf_hostel_auto_enroll')
    → If true: SubscriptionPlan::where('is_hostel_plan',1)->active()->first()
    → Creates caf_subscription_enrollments record
    → Deducts plan fee from student meal card via MealCardService::deductBalance()

  INV Bridge (in StockService — already built in Phase 5):
    → Checks sys_settings('caf_inv_integration')
    → If true AND INV module licensed: creates inv_purchase_requisitions record
    → Graceful degradation: if InvServiceInterface not resolved → log warning, skip PR creation

  PAY Signal (read-only — already built in Phase 4):
    → caf_staff_meal_logs.payroll_deduction_flag = 1 is a read signal
    → CAF never writes to pay_* tables; PAY module queries caf_staff_meal_logs directly

Artisan Commands (none new — LowBalanceNotificationJob is per-transaction, not scheduled):
  Register in routes/console.php:
    Schedule::command('caf:archive-old-menus')->daily()->at('00:00');
    Schedule::command('caf:send-fssai-alerts')->daily()->at('07:00');
    Schedule::command('caf:check-stock-reorder')->daily()->at('07:30');
```

**Tests:**
| File | Tests | Key Scenarios |
|------|-------|--------------|
| `StaffMealLogTest.php` | 4 | Create staff meal log; payroll_deduction_flag=1 readable by PAY; no soft-delete |
| `RevenueReportTest.php` | 3 | Revenue aggregates orders + POS; CSV export matches headers; PDF renders |
| `HostelBridgeEnrollmentTest.php` | 3 | HostelAdmissionEvent → enrollment created when caf_hostel_auto_enroll=true; skipped when false; plan fee deducted |

---

## Section 7 — Seeder Execution Order

```
php artisan tenants:artisan "db:seed --class=Modules\\Cafeteria\\Database\\Seeders\\CafSeederRunner"

CafSeederRunner
  └── CafMenuCategorySeeder   (L1 — 5 categories: BRK, LNC, SNK, DIN, TUK)
      Dependencies: none
      Uses: DB::table('caf_menu_categories')->upsert() — safe to re-run
```

**Minimum seeder for tests:** `CafMenuCategorySeeder` — required by almost all tables via `meal_category_id` FK.

**Additional test prerequisites by phase:**
| Phase | Additional Factory/Seeder Needed |
|-------|----------------------------------|
| Phase 1 | `MenuCategoryFactory`, `MenuItemFactory` |
| Phase 2 | `DailyMenuFactory` |
| Phase 3 | `StudentFactory` (from STD module or fake), `SubscriptionPlanFactory`, `OrderFactory` |
| Phase 4 | `MealCardFactory` (`card_number: CAF-CARD-XXXXXXXX`, `current_balance: 500.00`) |
| Phase 5 | `SupplierFactory`, `StockItemFactory` |
| Phase 6 | All prior factories |

### Artisan Commands (register in `routes/console.php`)

| Command | Schedule | Trigger | Purpose |
|---------|----------|---------|---------|
| `caf:archive-old-menus` | `daily()->at('00:00')` | Scheduler | Archives Published menus with menu_date < today − 7 days |
| `caf:send-fssai-alerts` | `daily()->at('07:00')` | Scheduler | Checks supplier (30+7 day) and school FSSAI (60+30 day) expiry |
| `caf:check-stock-reorder` | `daily()->at('07:30')` | Scheduler | Checks all stock levels; dispatches alerts; optional INV bridge |
| *(LowBalance)* | **NOT scheduled** | Per-transaction | Dispatched by `MealCardService::deductBalance()` after every debit as `LowBalanceNotificationJob` |

---

## Section 8 — Testing Strategy

**Framework:** Pest (Feature tests) + PHPUnit (Unit tests)
**Tenant DB:** All Feature tests use real tenant DB via `RefreshDatabase` — do not use SQLite for tests involving `SELECT...FOR UPDATE`

### 8.1 Feature Test Setup

```php
// All Feature tests:
uses(Tests\TestCase::class, RefreshDatabase::class);

// Menu publish notifications:
Notification::fake();  // in WeeklyMenuPublishTest, EventMealPublishTest

// Low balance notification:
Queue::fake();  // in MealCardNegativeBalanceTest, LowBalanceNotificationTest
// Assert: Queue::assertPushed(LowBalanceNotificationJob::class)

// Stock reorder alert:
Queue::fake();
Event::fake();  // in StockReorderAlertTest
// Assert: Queue::assertPushed(StockReorderAlertJob::class)

// Razorpay webhook:
// Use known HMAC-SHA256 signature generated with test secret
// POST to /api/v1/cafeteria/meal-card/topup/webhook with X-Razorpay-Signature header

// SELECT...FOR UPDATE concurrency:
// Two DB::transaction() calls in sequence on same tenant DB (not mocked)

// INV bridge graceful degradation:
// Mock InvServiceInterface to throw exception; assert StockService catches and logs
```

### 8.2 Feature Test File Summary (22 test files)

| File | Path | Tests | Key Scenarios |
|------|------|-------|--------------|
| `MenuCategoryCrudTest` | `tests/Feature/Cafeteria/` | 5 | CRUD; code uniqueness; toggle is_active |
| `MenuItemCrudTest` | — | 5 | CRUD; photo_media_id nullable; food_type validation |
| `WeeklyMenuPublishTest` | — | 6 | Publish fires event; `Notification::fake()`; publish blocked if no items (BR-CAF-005) |
| `MenuPublishBlockedTest` | — | 3 | 0 items blocks publish; UNIQUE menu_date rejected (BR-CAF-018) |
| `EventMealPublishTest` | — | 4 | Publish event; null target = all students; free-text items |
| `OrderPlacementTest` | — | 6 | Full happy path; unit_price snapshot; MealCard balance deducted |
| `OrderCutoffTest` | — | 3 | Cutoff enforcement; 1 min before OK; 1 min after rejected |
| `DietaryConflictWarningTest` | — | 4 | Jain + Non-Veg warning; admin override; student blocked |
| `OrderCancellationRefundTest` | — | 3 | Cancel refunds balance; Served order cannot cancel |
| `KitchenConsolidationTest` | — | 4 | Subscription headcount; composite index prevents N+1 |
| `SubscriptionEnrollmentTest` | — | 3 | Enroll; cancel; mutual-exclusion student/staff |
| `MealCardTopUpCashTest` | — | 4 | Cash credit; balance_after snapshot; total_credited increments |
| `RazorpayWebhookTest` | — | 5 | Valid HMAC; invalid HMAC 401; duplicate payment_id idempotent 200 (BR-CAF-011) |
| `MealCardNegativeBalanceTest` | — | 3 | Reject below-zero (BR-CAF-003); `Queue::fake()` LowBalance job |
| `IssueMealCardTest` | — | 3 | Issue card; UNIQUE student_id enforced (BR-CAF-004); previous card deactivated |
| `PosSessionTest` | — | 4 | Open; transact on open; blocked on closed (BR-CAF-013); reconciliation totals |
| `QrAttendanceScanTest` | — | 3 | First scan inserts; duplicate scan → 200 with existing record (idempotency) |
| `StockReorderAlertTest` | — | 5 | Deduction; reorder trigger; `Queue::fake()`; INV bridge; graceful degradation |
| `FssaiExpiryAlertTest` | — | 4 | 30-day; 7-day; 60-day; 30-day alerts for correct record types |
| `StaffMealLogTest` | — | 4 | Create log; payroll_deduction_flag readable; no soft-delete |
| `RevenueReportTest` | — | 3 | Aggregation; CSV export; DomPDF render |
| `HostelBridgeEnrollmentTest` | — | 3 | caf_hostel_auto_enroll=true enrolls; false skips; fee deducted |

**Feature test total: 22 files, ~84 test cases**

### 8.3 Unit Test File Summary (2 files)

| File | Path | Tests | Key Scenarios |
|------|------|-------|--------------|
| `MealCardTransactionLedgerTest` | `tests/Unit/Cafeteria/` | 4 | `balance_after` = prior balance ± amount on Credit, Debit, Refund, Adjustment; ledger integrity over chain of 10 transactions |
| `OrderNumberFormatTest` | — | 2 | Generated order number matches regex `CAF-\d{4}-[A-Z0-9]{8}`; no duplicates in 1000 iterations |

**Unit test total: 2 files, 6 test cases**

### 8.4 Critical Business Rule Test Coverage

| BR | Rule | Test File | Test Method |
|----|------|-----------|-------------|
| BR-CAF-003 | Balance may not go negative (prepaid-only mode) | `MealCardNegativeBalanceTest` | `test_deduct_below_zero_throws_exception_when_setting_false` |
| BR-CAF-004 | One active card per student | `IssueMealCardTest` | `test_second_card_deactivates_first` |
| BR-CAF-005 | Publish blocked if no items assigned | `MenuPublishBlockedTest` | `test_cannot_publish_menu_with_no_items` |
| BR-CAF-011 | Razorpay webhook idempotency | `RazorpayWebhookTest` | `test_duplicate_payment_id_returns_success_without_double_credit` |
| BR-CAF-012 | Atomic balance deduction (SELECT...FOR UPDATE) | `MealCardTopUpCashTest` | `test_concurrent_deductions_do_not_overdraft` *(real DB, sequential transactions)* |
| BR-CAF-013 | POS transactions require open session | `PosSessionTest` | `test_transaction_rejected_when_session_closed` |
| BR-CAF-018 | UNIQUE menu_date | `MenuPublishBlockedTest` | `test_duplicate_menu_date_rejected_at_db_level` |

### 8.5 Factory Definitions

```php
// MenuCategoryFactory — preferred to use seeded data in tests (CafMenuCategorySeeder)
// Only create factory instances for tests that need non-standard categories

MenuItemFactory::new()->create([
    'category_id'  => MenuCategory::first()->id,  // use seeded BRK category
    'food_type'    => 'Veg',
    'price'        => 50.00,
    'is_available' => 1,
]);

DailyMenuFactory::new()->create([
    'menu_date'       => today()->addDays(2),
    'week_start_date' => today()->startOfWeek(),
    'status'          => 'Draft',
]);

MealCardFactory::new()->create([
    'student_id'      => $student->id,
    'card_number'     => 'CAF-CARD-' . strtoupper(Str::random(8)),
    'current_balance' => 500.00,
    'valid_from_date' => today(),
]);

OrderFactory::new()->create([
    'order_number'     => 'CAF-' . now()->year . '-' . strtoupper(Str::random(8)),
    'student_id'       => $student->id,
    'meal_card_id'     => $card->id,
    'order_date'       => today()->addDay(),
    'status'           => 'Confirmed',
]);
```

### 8.6 Mock Strategy Summary

| Dependency | Mock Strategy | Test Files |
|-----------|--------------|-----------|
| NTF notifications (MenuPublished, LowBalance) | `Notification::fake()` | WeeklyMenuPublishTest, MealCardNegativeBalanceTest |
| Queue jobs (LowBalanceNotificationJob, StockReorderAlertJob) | `Queue::fake()` | MealCardNegativeBalanceTest, StockReorderAlertTest |
| Events (StockReorderAlert) | `Event::fake()` | StockReorderAlertTest |
| Razorpay SDK | Known test key + HMAC signature; no HTTP mock needed | RazorpayWebhookTest |
| INV module bridge | `$this->mock(InvServiceInterface::class)` | StockReorderAlertTest |
| DomPDF rendering | Assert response headers only (`Content-Type: application/pdf`) | KitchenConsolidationTest, RevenueReportTest |
| SELECT...FOR UPDATE | **Real tenant DB only** — do not mock; use RefreshDatabase | MealCardTopUpCashTest |
