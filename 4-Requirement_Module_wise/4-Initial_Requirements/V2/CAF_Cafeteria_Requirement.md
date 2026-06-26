# CAF — Cafeteria & Mess Management
## Module Requirement Document V2
**Version:** 2.0 | **Date:** 2026-03-26 | **Status:** Draft | **Mode:** RBS_ONLY
**Module Code:** CAF | **Table Prefix:** `caf_` | **Module Path:** `Modules/Cafeteria`
**Platform:** Laravel 12 + PHP 8.2 + MySQL 8.x | **DB Layer:** tenant_db (per-school)

> **GREENFIELD MODULE** — No code, DDL, or tests exist. All features are 📐 Proposed.
> This V2 document supersedes V1 (2026-03-25) with expanded scope: POS interface, FSSAI tracking, QR-based meal attendance, subscription plans, special-event meals, and INV module integration.

---

## 1. Executive Summary

The Cafeteria & Mess Management module delivers end-to-end digital management of school canteens and hostel messes on the Prime-AI platform. It handles menu planning with nutritional detail, online meal pre-ordering by students and parents, cashless meal card (prepaid wallet) payments, QR/biometric meal attendance, kitchen consolidation for preparation, raw material stock with reorder alerts, FSSAI compliance tracking, point-of-sale (POS) counter operations, wastage analytics, and integration with the Inventory and Finance modules.

**V2 scope additions over V1:**
- QR-code-based meal attendance scanning at counter
- Meal subscription plans (monthly fixed-menu enrollment)
- POS counter interface for kitchen staff
- Special/event meal management (festivals, sports day, excursions)
- FSSAI compliance log per cafeteria unit
- INV module integration for raw material purchase requests
- Vendor linkage for cafeteria suppliers
- Staff meal management (separate from student meals)
- Parent portal meal consumption history
- Diet restriction alert on POS scan

**Overall Implementation: 0%** (Greenfield — all items 📐 Proposed)

---

## 2. Module Overview

### 2.1 Business Context

Indian K-12 schools — particularly residential and semi-residential — require structured, hygienic, and accountable canteen management. Common pain points:

| Pain Point | Module Solution |
|---|---|
| Menu is verbal / whiteboard-based | Digital weekly menu with nutritional info published to portals |
| Kitchen prepares by guesswork | Pre-ordering gives exact headcount per item per meal |
| Cash handling at counter | Cashless meal card (prepaid wallet) + QR scan |
| Parents unaware of child's diet | Consumption history on Parent Portal |
| Dietary allergies ignored | Dietary profile flagged on POS scan and kitchen view |
| Food wastage untracked | Planned vs actual consumption report with waste cost |
| Stock managed on paper | Raw material register with reorder alerts and INV module link |
| FSSAI compliance informal | FSSAI unit registration and periodic audit log |

### 2.2 Feature Summary

| Feature Area | RBS Ref | Priority | Status |
|---|---|---|---|
| Menu Category Management | F.W1.1 | Critical | 📐 Proposed |
| Menu Item Master (with nutrition & allergens) | ST.W1.1.1.1 | Critical | 📐 Proposed |
| Weekly Menu Planning (day × meal-type grid) | T.W1.1.1 | Critical | 📐 Proposed |
| Menu Publish & Parent/Student Notification | T.W1.1.2, ST.W1.1.2.1 | Critical | 📐 Proposed |
| Special / Event Meal Management | Extended | High | 📐 Proposed |
| Student Dietary Profile (allergy & preference) | ST.W2.1.1.2 | Critical | 📐 Proposed |
| Meal Subscription Plans | Extended | High | 📐 Proposed |
| Meal Pre-Ordering (portal) | T.W2.1.1 | Critical | 📐 Proposed |
| Order Cutoff Enforcement | ST.W2.1.2.2 | Critical | 📐 Proposed |
| Meal Card (Prepaid Wallet) | Extended | High | 📐 Proposed |
| QR-Based Meal Attendance at Counter | Extended | High | 📐 Proposed |
| POS Counter Interface | Extended | High | 📐 Proposed |
| Kitchen Consolidated Order View | ST.W2.1.2.1 | Critical | 📐 Proposed |
| Staff Meal Management | Extended | Medium | 📐 Proposed |
| Raw Material Stock Register | T.W3.1.1, ST.W3.1.1.1 | High | 📐 Proposed |
| Reorder Alerts & INV Purchase Request | ST.W3.1.1.2 | High | 📐 Proposed |
| Consumption & Wastage Tracking | T.W3.1.2, ST.W3.1.2.1–2 | High | 📐 Proposed |
| Vendor / Supplier Management (CAF-side) | Extended | Medium | 📐 Proposed |
| FSSAI Compliance Tracking | Extended | Medium | 📐 Proposed |
| Revenue Dashboard & Reports | Extended | Medium | 📐 Proposed |
| Parent Portal Consumption History | Extended | Medium | 📐 Proposed |

### 2.3 Module Navigation

```
School Admin Panel
└── Cafeteria [/cafeteria]
    ├── Dashboard                    [/cafeteria/dashboard]
    ├── Setup
    │   ├── Menu Categories          [/cafeteria/menu-categories]
    │   ├── Menu Items               [/cafeteria/menu-items]
    │   ├── Meal Subscription Plans  [/cafeteria/subscription-plans]
    │   ├── Dietary Profiles         [/cafeteria/dietary-profiles]
    │   └── FSSAI Compliance         [/cafeteria/fssai]
    ├── Menu Planning
    │   ├── Weekly Menu Planner      [/cafeteria/weekly-menus]
    │   ├── Daily Menu View          [/cafeteria/daily-menus/{date}]
    │   └── Special Event Meals      [/cafeteria/event-meals]
    ├── Orders & Attendance
    │   ├── Pre-Orders               [/cafeteria/orders]
    │   ├── Kitchen View             [/cafeteria/kitchen-view]
    │   ├── POS Counter              [/cafeteria/pos]
    │   └── Meal Attendance          [/cafeteria/meal-attendance]
    ├── Meal Cards
    │   ├── Card Management          [/cafeteria/meal-cards]
    │   └── Transactions             [/cafeteria/meal-card-transactions]
    ├── Subscriptions
    │   └── Enrollments              [/cafeteria/subscription-enrollments]
    ├── Stock
    │   ├── Raw Materials            [/cafeteria/stock-items]
    │   ├── Consumption Log          [/cafeteria/consumption-log]
    │   └── Supplier / Vendor        [/cafeteria/suppliers]
    └── Reports
        ├── Revenue Report           [/cafeteria/reports/revenue]
        ├── Order Summary            [/cafeteria/reports/orders]
        ├── Wastage Report           [/cafeteria/reports/wastage]
        ├── Meal Card Statements     [/cafeteria/reports/meal-card-statements]
        └── FSSAI Audit Log          [/cafeteria/reports/fssai]
```

### 2.4 Module Architecture

```
Modules/Cafeteria/
├── app/Http/Controllers/
│   ├── CafeteriaController.php              # Dashboard
│   ├── MenuCategoryController.php           # Category CRUD
│   ├── MenuItemController.php               # Item CRUD
│   ├── WeeklyMenuController.php             # Plan + publish
│   ├── EventMealController.php              # Special/festival meals
│   ├── DietaryProfileController.php         # Per-student diet flags
│   ├── SubscriptionPlanController.php       # Meal subscription plans
│   ├── SubscriptionEnrollmentController.php # Student enrolment
│   ├── OrderController.php                  # Pre-order management
│   ├── PosController.php                    # Counter POS
│   ├── MealAttendanceController.php         # QR / biometric scan
│   ├── MealCardController.php               # Card issuance + top-up
│   ├── StockController.php                  # Raw material stock
│   ├── SupplierController.php               # Supplier register
│   ├── FssaiController.php                  # FSSAI compliance log
│   └── CafeteriaReportController.php        # Reports
├── app/Services/
│   ├── MenuService.php                      # Publish, notify, cutoff
│   ├── OrderService.php                     # Order create, consolidate
│   ├── MealCardService.php                  # Balance, top-up, refund
│   ├── PosService.php                       # POS scan, walk-in billing
│   ├── StockService.php                     # Reorder alerts, INV bridge
│   └── ReportService.php                    # Revenue, wastage, statements
├── app/Models/ (17 models)
├── app/Policies/ (14 policies)
├── app/Requests/ (16 FormRequest classes)
├── database/migrations/ (17 migrations)
├── resources/views/cafeteria/ (~50 blade views)
└── routes/ api.php + web.php
```

---

## 3. Stakeholders & Roles

| Actor | System Role | Key Permissions |
|---|---|---|
| School Admin | `SCHOOL_ADMIN` | All CAF permissions |
| Cafeteria Manager | `CAFETERIA_MGR` | Menu manage, orders view/manage, stock manage, reports view |
| Kitchen Staff | `KITCHEN_STAFF` | Kitchen view (read-only orders), consumption log, POS scan |
| Accounts Staff | `ACCOUNTS_STAFF` | Meal card manage, top-up, revenue reports |
| Student | `STUDENT` | Pre-order own meals via portal; view own card balance |
| Parent | `PARENT` | Pre-order child's meals; top-up child's card; view consumption history |
| Hostel Warden | `HOSTEL_WARDEN` | View mess enrolment; view hostel students' meal attendance |
| System / Scheduler | — | Cutoff enforcement, reorder alert dispatch, subscription billing |

---

## 4. Functional Requirements

---

### FR-CAF-01: Menu Category Management
**Status:** 📐 Proposed | **Priority:** Critical | **RBS Ref:** F.W1.1
**Tables:** `caf_menu_categories`

**Description:** Manage meal-type categories (Breakfast, Lunch, Snacks, Dinner, Tuck Shop) that organise menu items and weekly plans.

**Acceptance Criteria:**
- AC1: Admin can create, edit, toggle status, soft-delete and restore categories.
- AC2: Meal_time ENUM controls which portal order slots the category appears in.
- AC3: Force-delete is blocked if menu items are associated with the category.
- AC4: Display_order controls sort sequence on the portal meal selection screen.

---

### FR-CAF-02: Menu Item Master
**Status:** 📐 Proposed | **Priority:** Critical | **RBS Ref:** ST.W1.1.1.1
**Tables:** `caf_menu_items`

**Description:** Maintain a dish library with price, food type (Veg/Non-Veg/Egg/Jain), full nutritional macros (calories, protein, carbs, fat), free-form allergen notes, and a dish photo.

**Acceptance Criteria:**
- AC1: Each item stores food_type; Jain and Veg items display coloured badges on portal.
- AC2: AJAX toggle switches `is_available` in real-time (sold-out without removing from weekly plan).
- AC3: Unavailable items are greyed out on the portal order screen and hidden from POS selection.
- AC4: Nutritional macros are optional but displayed when provided.
- AC5: Photo uploaded via `sys_media`; thumbnail shown in kitchen view and portal.

---

### FR-CAF-03: Weekly Menu Planning & Publish
**Status:** 📐 Proposed | **Priority:** Critical | **RBS Ref:** T.W1.1.1, T.W1.1.2, ST.W1.1.2.1–2
**Tables:** `caf_daily_menus`, `caf_daily_menu_items_jnt`

**Description:** Cafeteria Manager plans the full week by assigning dishes to day × meal-type slots in a grid UI. Admin publishes the draft, making it visible on portals and triggering notifications.

**Acceptance Criteria:**
- AC1: Weekly grid covers Monday–Sunday × all active meal categories.
- AC2: Same item may appear in multiple days but not in duplicate slots (same day + meal category blocked).
- AC3: Publish is blocked if no items are assigned to any slot.
- AC4: On publish, `status = Published`, `published_at` recorded; Notification module dispatches push/SMS to all active students and parents.
- AC5: Published menu visible on Student Portal and Parent Portal as a day-wise grid.
- AC6: Archived menus remain readable for history but do not appear in the active order screen.

---

### FR-CAF-04: Special / Event Meal Management
**Status:** 📐 Proposed | **Priority:** High | **RBS Ref:** Extended (New in V2)
**Tables:** `caf_event_meals`, `caf_event_meal_items_jnt`

**Description:** Create one-off special menus for festivals (Diwali sweets, Eid biryani), sports days, or school excursions that overlay the regular weekly menu or stand alone.

**Acceptance Criteria:**
- AC1: Event meal has a name, event_date, meal_category, and list of items (may include items not in the regular library via a free-text override).
- AC2: Event meals are published separately with their own notification ("Special Diwali Lunch on 20 Oct — see menu").
- AC3: Pre-ordering for event meals follows the same cutoff rules as regular meals.
- AC4: Event meals appear distinctly badged on the portal and kitchen view.
- AC5: Event meals can be restricted to specific class groups (e.g., excursion lunch for Grade 10 only).

---

### FR-CAF-05: Student Dietary Profile
**Status:** 📐 Proposed | **Priority:** Critical | **RBS Ref:** ST.W2.1.1.2
**Tables:** `caf_dietary_profiles`

**Description:** One dietary profile per student recording food preference, specific restrictions (no onion-garlic, gluten-free, nut allergy), and medical dietary notes. Profile is visible on POS scan, kitchen order view, and dietary conflict warnings during ordering.

**Acceptance Criteria:**
- AC1: Upsert pattern — one profile per student (UNIQUE on student_id).
- AC2: Parent can update child's profile via Parent Portal; change is logged.
- AC3: On POS scan or kitchen order, dietary flags display prominently (coloured chips).
- AC4: Dietary conflict warning (soft block) shown when a student with food_preference=Jain or is_nut_allergy=1 orders a conflicting item.
- AC5: Medical dietary notes are visible to kitchen staff but not to other students.

---

### FR-CAF-06: Meal Subscription Plans
**Status:** 📐 Proposed | **Priority:** High | **RBS Ref:** Extended (New in V2)
**Tables:** `caf_subscription_plans`, `caf_subscription_enrollments`

**Description:** Schools offer fixed monthly or termly meal subscription plans (e.g., "Full Day Plan — Breakfast + Lunch + Snacks — ₹2,500/month"). Students enrolled in a plan are automatically confirmed for their plan's meal types each day without individual pre-ordering.

**Acceptance Criteria:**
- AC1: Plan defines included meal_categories, price per period, and valid academic_term.
- AC2: Student enrollment links to a meal card; plan amount is deducted from card at enrollment or monthly.
- AC3: Enrolled students appear pre-confirmed in kitchen view for their included meal types.
- AC4: Hostel mess plan is a subscription with auto-enrollment on hostel admission (HST module bridge).
- AC5: Subscription enrollment report shows active enrollments by plan, class, and section.
- AC6: Early exit from plan triggers a pro-rata refund calculation (manual approval by admin).

---

### FR-CAF-07: Meal Pre-Ordering (Portal)
**Status:** 📐 Proposed | **Priority:** Critical | **RBS Ref:** T.W2.1.1, T.W2.1.2, ST.W2.1.1.1–2, ST.W2.1.2.2
**Tables:** `caf_orders`, `caf_order_items`

**Description:** Students and parents browse the published weekly menu and pre-book meals for specific days and meal types. Orders are confirmed immediately on placement; payment is deducted from the meal card (prepaid mode) or marked pay-at-counter.

**Acceptance Criteria:**
- AC1: Order is only possible if the weekly menu for that date is Published.
- AC2: Ordering window closes `caf_order_cutoff_hours` before the meal's scheduled time (configurable in `sys_school_settings`; default 2 hours). Post-cutoff orders are rejected with a descriptive message.
- AC3: Dietary conflict warning shown (soft block) when item conflicts with student's profile; admin can override.
- AC4: Payment mode: MealCard (balance deducted atomically via DB transaction + row-level lock), Counter (deducted on serving), or Subscription (already included in plan).
- AC5: Meal card balance cannot go negative when school is in prepaid-only mode.
- AC6: Order confirmation email/push sent to parent with order summary and meal card balance.
- AC7: Student/parent can cancel before cutoff; meal card balance refunded immediately.
- AC8: Order number format: `CAF-YYYY-XXXXXXXX` (auto-generated, unique).

---

### FR-CAF-08: Kitchen Consolidated View
**Status:** 📐 Proposed | **Priority:** Critical | **RBS Ref:** ST.W2.1.2.1
**Tables:** `caf_orders`, `caf_order_items` (aggregated read)

**Description:** Kitchen staff view a consolidated preparation list for any date and meal type, grouped by menu item with dietary flag breakdowns. The view is printable as a PDF kitchen sheet (DomPDF).

**Acceptance Criteria:**
- AC1: Aggregate confirmed orders for selected date + meal_category; group by menu_item; show total quantity.
- AC2: Dietary breakdown per item: Jain count, No-onion count, Nut-allergy count.
- AC3: Class/section wise distribution view for serving logistics.
- AC4: PDF kitchen preparation sheet: item | total qty | Jain | Veg | Non-Veg | Allergy flags.
- AC5: Subscription-enrolled students (auto-confirmed) appear in kitchen count even without an explicit order record.
- AC6: View refreshes in real-time (or auto-refresh every 60 seconds) to capture late pre-orders before cutoff.

---

### FR-CAF-09: POS Counter Interface
**Status:** 📐 Proposed | **Priority:** High | **RBS Ref:** Extended (New in V2)
**Tables:** `caf_pos_sessions`, `caf_pos_transactions`

**Description:** A simplified touch-friendly interface for counter staff to process walk-in purchases, scan student QR codes to identify the student, verify dietary restrictions, and deduct from the meal card or accept cash payment. Operates independently of pre-orders for tuck-shop style purchases.

**Acceptance Criteria:**
- AC1: Staff opens a POS session (shift start); session tracks total cash and card collections.
- AC2: Student identified by QR code scan (meal card QR) or manual student ID lookup.
- AC3: On scan, dietary flags display prominently before items are added.
- AC4: Staff selects items from a grid of available menu items for the current meal type; quantities adjustable.
- AC5: Payment: MealCard deduction (atomic) or Cash (recorded manually).
- AC6: Receipt printable or SMS-able to parent on request.
- AC7: POS session closed at shift end; daily POS summary reconciles against meal card deductions and cash collected.
- AC8: POS transactions appear in meal card transaction ledger as Debit entries.

---

### FR-CAF-10: QR-Based Meal Attendance
**Status:** 📐 Proposed | **Priority:** High | **RBS Ref:** Extended (New in V2)
**Tables:** `caf_meal_attendance`

**Description:** Scan student meal card QR (or student ID card QR) at the counter to record meal attendance (who actually ate on a given day + meal type). Separate from pre-ordering — captures actual serving.

**Acceptance Criteria:**
- AC1: QR scan endpoint records `student_id`, `meal_date`, `meal_category_id`, `scanned_at`, and serving counter.
- AC2: Duplicate scan for same student + date + meal_category is idempotently ignored (returns "already recorded").
- AC3: Meal attendance feeds into the wastage report (pre-orders vs actual attendance).
- AC4: Parent receives a real-time push notification when their child is scanned at the cafeteria (optional, configurable per school).
- AC5: Attendance summary: per class/section meal attendance rate by date.

---

### FR-CAF-11: Meal Card Management
**Status:** 📐 Proposed | **Priority:** High | **RBS Ref:** Extended (cashless infra)
**Tables:** `caf_meal_cards`, `caf_meal_card_transactions`

**Description:** Issue a prepaid canteen wallet (meal card) to each student. Parents top up via Razorpay or cash. Balance deducted atomically on order placement or POS scan. Full transaction ledger maintained.

**Acceptance Criteria:**
- AC1: One active meal card per student (UNIQUE on student_id).
- AC2: Card number auto-generated: `CAF-CARD-XXXXXXXX` (8 random hex digits).
- AC3: QR code generated for card number via `SimpleSoftwareIO/simple-qrcode`.
- AC4: Top-up: Online via Razorpay (webhook with idempotency on `razorpay_payment_id`); Cash via admin entry.
- AC5: Balance deduction is atomic: `SELECT ... FOR UPDATE` + update + transaction record in a single DB transaction.
- AC6: Transaction types: Credit (top-up), Debit (order/POS), Refund (cancellation), Adjustment (admin manual).
- AC7: Running balance stored as `balance_after` on each transaction record.
- AC8: Parent can view child's card balance and last 30 transactions on Parent Portal.
- AC9: Low-balance notification sent to parent when balance falls below `caf_low_balance_threshold` (school setting, default ₹100).

---

### FR-CAF-12: Raw Material Stock Management
**Status:** 📐 Proposed | **Priority:** High | **RBS Ref:** F.W3.1, T.W3.1.1, ST.W3.1.1.1–2
**Tables:** `caf_stock_items`, `caf_consumption_logs`, `caf_suppliers`

**Description:** Maintain a raw material register (grains, pulses, vegetables, spices, dairy, etc.) with reorder levels. Kitchen staff log daily consumption. When stock hits reorder level, system auto-alerts the Cafeteria Manager and optionally raises a purchase request in the Inventory module.

**Acceptance Criteria:**
- AC1: Stock item captures name, category, unit, current_quantity, reorder_level, cost_per_unit, and linked supplier.
- AC2: When `current_quantity ≤ reorder_level`, system fires in-app notification to all users with `CAFETERIA_MGR` role.
- AC3: If INV module is licensed, system can auto-create a purchase requisition in the Inventory module (bridge service).
- AC4: Consumption log: date, stock_item_id, quantity_used, entered_by, notes; deducts from current_quantity.
- AC5: Bulk consumption import via CSV for kitchen staff convenience.
- AC6: Food cost per day = sum(quantity_used × cost_per_unit) for that date's consumption log.

---

### FR-CAF-13: Supplier Management (CAF-side)
**Status:** 📐 Proposed | **Priority:** Medium | **RBS Ref:** Extended (New in V2)
**Tables:** `caf_suppliers`

**Description:** Maintain a list of cafeteria-specific food and material suppliers with contact details, FSSAI registration numbers, and supply categories. Separate from the VND (Vendor) module but bridgeable.

**Acceptance Criteria:**
- AC1: Supplier record: name, contact_person, phone, email, fssai_license_no, supply_categories (JSON array), address, is_active.
- AC2: Supplier linked to stock items for traceability (supplier_id on caf_stock_items).
- AC3: FSSAI license expiry alert sent to Admin 30 days before `fssai_expiry_date`.
- AC4: Future bridge: when INV module PO is created, CAF supplier maps to VND vendor via shared phone/email lookup.

---

### FR-CAF-14: FSSAI Compliance Tracking
**Status:** 📐 Proposed | **Priority:** Medium | **RBS Ref:** Extended (New in V2)
**Tables:** `caf_fssai_records`

**Description:** Record the school cafeteria's FSSAI license details and log periodic hygiene audit results for compliance visibility.

**Acceptance Criteria:**
- AC1: FSSAI record: license_number, license_type (Basic/State/Central), issue_date, expiry_date, licensed_entity_name, fssai_document_media_id.
- AC2: Admin logs hygiene audit entries: audit_date, auditor_name, score (1–10), remarks, corrective_actions, next_audit_date.
- AC3: Alert dispatched 60 and 30 days before license expiry.
- AC4: FSSAI audit log exportable as PDF for inspection purposes.

---

### FR-CAF-15: Staff Meal Management
**Status:** 📐 Proposed | **Priority:** Medium | **RBS Ref:** Extended (New in V2)
**Tables:** `caf_staff_meal_logs`

**Description:** Track meals consumed by teaching and non-teaching staff. Staff either subscribe to a meal plan (deducted from salary via payroll) or pay at the counter. Staff meals are accounted separately from student revenue.

**Acceptance Criteria:**
- AC1: Staff meal log: staff_id (FK `sys_users`), meal_date, meal_category_id, items_json, amount, payment_mode (Subscription/Cash/CardDeduction).
- AC2: Staff meal subscription links to HR/Payroll module for salary deduction (flag; actual deduction is PAY module responsibility).
- AC3: Staff meals appear in a separate section of the revenue dashboard.
- AC4: Kitchen headcount includes both student and staff meal counts.

---

### FR-CAF-16: Cafeteria Dashboard & Reports
**Status:** 📐 Proposed | **Priority:** Medium | **RBS Ref:** Extended
**Tables:** aggregated reads

**Description:** Revenue dashboard with KPI widgets and exportable reports covering revenue, order summaries, wastage, meal card statements, and FSSAI audit log.

**Acceptance Criteria:**
- AC1: Dashboard widgets: Today's Revenue, Week's Revenue trend, Top 5 Dishes, Active Meal Cards count, Total Outstanding Balance, Low-Stock alert count.
- AC2: Revenue Report: filter by date range, meal type; export CSV/PDF.
- AC3: Order Summary: per student spend, per class/section breakdown.
- AC4: Wastage Report: planned (from orders) vs actual (from attendance scan / consumption log) per item per date; waste percentage and cost.
- AC5: Meal Card Statement: per-student ledger with all credits, debits, running balance; exportable PDF.
- AC6: FSSAI Audit Log: list of audit entries with scores and next audit dates.

---

## 5. Data Model

### 5.1 New Tables (`caf_*` prefix)

> All tables include standard audit columns unless noted: `id INT UNSIGNED PK`, `is_active TINYINT(1) DEFAULT 1`, `created_by BIGINT UNSIGNED NULL FK→sys_users`, `created_at TIMESTAMP`, `updated_at TIMESTAMP`, `deleted_at TIMESTAMP NULL`.

| Table | Description | Status |
|---|---|---|
| `caf_menu_categories` | Meal-type categories (Breakfast, Lunch, etc.) | 📐 New |
| `caf_menu_items` | Dish library with nutrition, allergens, food type | 📐 New |
| `caf_daily_menus` | One record per menu date (Draft/Published/Archived) | 📐 New |
| `caf_daily_menu_items_jnt` | Day × meal-category × menu-item assignments | 📐 New |
| `caf_event_meals` | Special/festival meal headers | 📐 New |
| `caf_event_meal_items_jnt` | Event meal × menu item assignments | 📐 New |
| `caf_dietary_profiles` | Per-student dietary preference and restriction flags | 📐 New |
| `caf_subscription_plans` | Fixed monthly/termly meal plan definitions | 📐 New |
| `caf_subscription_enrollments` | Student × plan enrolment records | 📐 New |
| `caf_orders` | Pre-order headers | 📐 New |
| `caf_order_items` | Pre-order line items | 📐 New |
| `caf_meal_attendance` | QR/biometric scan records (actual serving) | 📐 New |
| `caf_pos_sessions` | POS shift sessions | 📐 New |
| `caf_pos_transactions` | Individual POS counter transactions | 📐 New |
| `caf_meal_cards` | Student prepaid wallet | 📐 New |
| `caf_meal_card_transactions` | Credit/Debit/Refund ledger | 📐 New |
| `caf_suppliers` | Food/material supplier register | 📐 New |
| `caf_stock_items` | Raw material inventory | 📐 New |
| `caf_consumption_logs` | Daily raw-material usage log | 📐 New |
| `caf_fssai_records` | FSSAI license and hygiene audit log | 📐 New |
| `caf_staff_meal_logs` | Staff meal tracking | 📐 New |

**Total: 21 new tables**

### 5.2 Detailed Column Definitions

#### 📐 `caf_menu_categories`
| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| name | VARCHAR(100) | NOT NULL | e.g., Breakfast |
| code | VARCHAR(20) | UNIQUE NULL | Short code |
| meal_time | ENUM('Breakfast','Lunch','Snacks','Dinner','Tuck_Shop') | NOT NULL | |
| meal_start_time | TIME | NULL | Scheduled serving start time |
| description | TEXT | NULL | |
| display_order | TINYINT UNSIGNED | DEFAULT 0 | Portal sort order |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at / updated_at / deleted_at | TIMESTAMP | | |

#### 📐 `caf_menu_items`
| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| category_id | INT UNSIGNED | NOT NULL FK→caf_menu_categories | |
| name | VARCHAR(150) | NOT NULL | |
| description | TEXT | NULL | |
| price | DECIMAL(8,2) | NOT NULL | Per serving price |
| food_type | ENUM('Veg','Non_Veg','Egg','Jain') | NOT NULL DEFAULT 'Veg' | |
| calories | SMALLINT UNSIGNED | NULL | Kcal per serving |
| protein_grams | DECIMAL(5,2) | NULL | |
| carbs_grams | DECIMAL(5,2) | NULL | |
| fat_grams | DECIMAL(5,2) | NULL | |
| allergen_notes | TEXT | NULL | Free-form allergen info |
| photo_media_id | INT UNSIGNED | NULL FK→sys_media | |
| is_available | TINYINT(1) | DEFAULT 1 | Real-time toggle |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at / updated_at / deleted_at | TIMESTAMP | | |

#### 📐 `caf_daily_menus`
| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| menu_date | DATE | NOT NULL | UNIQUE |
| week_start_date | DATE | NOT NULL | ISO Monday |
| academic_term_id | INT UNSIGNED | NULL FK→sch_academic_terms | |
| status | ENUM('Draft','Published','Archived') | DEFAULT 'Draft' | |
| published_at | TIMESTAMP | NULL | |
| published_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| notes | TEXT | NULL | Kitchen notes |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at / updated_at / deleted_at | TIMESTAMP | | |

#### 📐 `caf_daily_menu_items_jnt`
| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| daily_menu_id | INT UNSIGNED | NOT NULL FK→caf_daily_menus | |
| menu_item_id | INT UNSIGNED | NOT NULL FK→caf_menu_items | |
| meal_category_id | INT UNSIGNED | NOT NULL FK→caf_menu_categories | |
| serving_size_notes | VARCHAR(100) | NULL | e.g., "1 plate", "200ml" |
| display_order | TINYINT UNSIGNED | DEFAULT 0 | |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at / updated_at | TIMESTAMP | | |
UNIQUE KEY `uq_caf_dmij` (`daily_menu_id`, `menu_item_id`, `meal_category_id`)

#### 📐 `caf_event_meals`
| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| name | VARCHAR(150) | NOT NULL | e.g., "Diwali Special Lunch" |
| event_date | DATE | NOT NULL | |
| meal_category_id | INT UNSIGNED | NOT NULL FK→caf_menu_categories | |
| target_class_ids_json | JSON | NULL | NULL = all students |
| status | ENUM('Draft','Published','Archived') | DEFAULT 'Draft' | |
| published_at | TIMESTAMP | NULL | |
| notes | TEXT | NULL | |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at / updated_at / deleted_at | TIMESTAMP | | |

#### 📐 `caf_event_meal_items_jnt`
| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| event_meal_id | INT UNSIGNED | NOT NULL FK→caf_event_meals | |
| menu_item_id | INT UNSIGNED | NULL FK→caf_menu_items | NULL if free-text item |
| free_text_item | VARCHAR(150) | NULL | Used when item not in library |
| quantity_per_student | DECIMAL(5,2) | NULL | |
| display_order | TINYINT UNSIGNED | DEFAULT 0 | |
| created_at / updated_at | TIMESTAMP | | |

#### 📐 `caf_dietary_profiles`
| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| student_id | INT UNSIGNED | NOT NULL FK→std_students | UNIQUE |
| food_preference | ENUM('Veg','Non_Veg','Egg','Jain') | NOT NULL DEFAULT 'Veg' | |
| is_no_onion_garlic | TINYINT(1) | DEFAULT 0 | |
| is_gluten_free | TINYINT(1) | DEFAULT 0 | |
| is_nut_allergy | TINYINT(1) | DEFAULT 0 | |
| is_dairy_free | TINYINT(1) | DEFAULT 0 | 🆕 New in V2 |
| custom_restrictions | TEXT | NULL | Free-form |
| medical_dietary_note | TEXT | NULL | Doctor-recommended |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at / updated_at / deleted_at | TIMESTAMP | | |

#### 📐 `caf_subscription_plans`
| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| name | VARCHAR(150) | NOT NULL | e.g., "Full Day Plan" |
| description | TEXT | NULL | |
| included_category_ids_json | JSON | NOT NULL | Array of caf_menu_categories.id |
| billing_period | ENUM('Monthly','Termly','Annual') | NOT NULL DEFAULT 'Monthly' | |
| price | DECIMAL(10,2) | NOT NULL | |
| academic_term_id | INT UNSIGNED | NULL FK→sch_academic_terms | |
| is_hostel_plan | TINYINT(1) | DEFAULT 0 | Links to HST module |
| is_staff_plan | TINYINT(1) | DEFAULT 0 | For staff meal deductions |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at / updated_at / deleted_at | TIMESTAMP | | |

#### 📐 `caf_subscription_enrollments`
| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| subscription_plan_id | INT UNSIGNED | NOT NULL FK→caf_subscription_plans | |
| student_id | INT UNSIGNED | NULL FK→std_students | NULL if staff |
| staff_id | BIGINT UNSIGNED | NULL FK→sys_users | NULL if student |
| meal_card_id | INT UNSIGNED | NULL FK→caf_meal_cards | |
| start_date | DATE | NOT NULL | |
| end_date | DATE | NULL | |
| status | ENUM('Active','Paused','Cancelled','Expired') | DEFAULT 'Active' | |
| cancellation_reason | TEXT | NULL | |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at / updated_at / deleted_at | TIMESTAMP | | |

#### 📐 `caf_orders`
| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| order_number | VARCHAR(30) | NOT NULL UNIQUE | CAF-YYYY-XXXXXXXX |
| student_id | INT UNSIGNED | NOT NULL FK→std_students | |
| meal_card_id | INT UNSIGNED | NULL FK→caf_meal_cards | |
| order_date | DATE | NOT NULL | Meal date |
| meal_category_id | INT UNSIGNED | NOT NULL FK→caf_menu_categories | |
| total_amount | DECIMAL(10,2) | NOT NULL | |
| payment_mode | ENUM('MealCard','Cash','Counter','Subscription') | DEFAULT 'MealCard' | |
| status | ENUM('Pending','Confirmed','Served','Cancelled') | DEFAULT 'Confirmed' | |
| cancelled_at | TIMESTAMP | NULL | |
| cancellation_reason | VARCHAR(255) | NULL | |
| notes | TEXT | NULL | |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at / updated_at / deleted_at | TIMESTAMP | | |
INDEX: `(student_id, order_date)`, `(order_date, meal_category_id, status)`

#### 📐 `caf_order_items`
| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| order_id | INT UNSIGNED | NOT NULL FK→caf_orders | |
| menu_item_id | INT UNSIGNED | NOT NULL FK→caf_menu_items | |
| quantity | TINYINT UNSIGNED | NOT NULL DEFAULT 1 | |
| unit_price | DECIMAL(8,2) | NOT NULL | Snapshot at order time |
| line_total | DECIMAL(10,2) | NOT NULL | quantity × unit_price |
| created_at / updated_at | TIMESTAMP | | |
UNIQUE KEY `uq_caf_order_item` (`order_id`, `menu_item_id`)

#### 📐 `caf_meal_attendance`
| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| student_id | INT UNSIGNED | NOT NULL FK→std_students | |
| meal_date | DATE | NOT NULL | |
| meal_category_id | INT UNSIGNED | NOT NULL FK→caf_menu_categories | |
| scanned_at | TIMESTAMP | NOT NULL DEFAULT CURRENT_TIMESTAMP | |
| scan_method | ENUM('QR','Biometric','Manual') | NOT NULL DEFAULT 'QR' | |
| counter_name | VARCHAR(100) | NULL | Which counter scanned |
| scanned_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at | TIMESTAMP | | |
UNIQUE KEY `uq_caf_meal_att` (`student_id`, `meal_date`, `meal_category_id`)

#### 📐 `caf_pos_sessions`
| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| session_date | DATE | NOT NULL | |
| opened_by | BIGINT UNSIGNED | NOT NULL FK→sys_users | |
| opened_at | TIMESTAMP | NOT NULL | |
| closed_at | TIMESTAMP | NULL | |
| total_cash_collected | DECIMAL(10,2) | DEFAULT 0.00 | |
| total_card_debited | DECIMAL(10,2) | DEFAULT 0.00 | |
| total_transactions | INT UNSIGNED | DEFAULT 0 | |
| notes | TEXT | NULL | |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_at / updated_at | TIMESTAMP | | |

#### 📐 `caf_pos_transactions`
| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| pos_session_id | INT UNSIGNED | NOT NULL FK→caf_pos_sessions | |
| student_id | INT UNSIGNED | NULL FK→std_students | NULL if anonymous |
| staff_id | BIGINT UNSIGNED | NULL FK→sys_users | NULL if student |
| meal_card_id | INT UNSIGNED | NULL FK→caf_meal_cards | |
| items_json | JSON | NOT NULL | Array of {menu_item_id, name, qty, price} |
| total_amount | DECIMAL(10,2) | NOT NULL | |
| payment_mode | ENUM('MealCard','Cash') | NOT NULL | |
| balance_after | DECIMAL(10,2) | NULL | For MealCard mode |
| dietary_flags_json | JSON | NULL | Snapshot of student dietary flags |
| receipt_sent | TINYINT(1) | DEFAULT 0 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at / updated_at | TIMESTAMP | | |

#### 📐 `caf_meal_cards`
| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| student_id | INT UNSIGNED | NOT NULL FK→std_students | UNIQUE (one active card) |
| card_number | VARCHAR(20) | NOT NULL UNIQUE | CAF-CARD-XXXXXXXX |
| current_balance | DECIMAL(10,2) | DEFAULT 0.00 | Running balance |
| total_credited | DECIMAL(10,2) | DEFAULT 0.00 | Lifetime top-ups |
| total_debited | DECIMAL(10,2) | DEFAULT 0.00 | Lifetime spend |
| valid_from_date | DATE | NOT NULL | |
| valid_to_date | DATE | NULL | Auto: end of academic year |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at / updated_at / deleted_at | TIMESTAMP | | |

#### 📐 `caf_meal_card_transactions`
| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| meal_card_id | INT UNSIGNED | NOT NULL FK→caf_meal_cards | |
| student_id | INT UNSIGNED | NOT NULL FK→std_students | Denormalised |
| transaction_type | ENUM('Credit','Debit','Refund','Adjustment') | NOT NULL | |
| amount | DECIMAL(10,2) | NOT NULL | |
| balance_after | DECIMAL(10,2) | NOT NULL | Snapshot after transaction |
| reference_type | VARCHAR(50) | NULL | 'Order','POS','TopUp','Refund','Adjustment' |
| reference_id | INT UNSIGNED | NULL | FK to reference table |
| payment_mode | ENUM('Online','Cash','Wallet','Free') | NULL | For top-ups |
| razorpay_payment_id | VARCHAR(100) | NULL UNIQUE | For online top-ups |
| notes | TEXT | NULL | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at / updated_at | TIMESTAMP | | |
INDEX: `(meal_card_id, created_at)`, `(razorpay_payment_id)` for idempotency

#### 📐 `caf_suppliers`
| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| name | VARCHAR(150) | NOT NULL | |
| contact_person | VARCHAR(100) | NULL | |
| phone | VARCHAR(20) | NULL | |
| email | VARCHAR(100) | NULL | |
| address | TEXT | NULL | |
| fssai_license_no | VARCHAR(50) | NULL | Supplier's FSSAI license |
| fssai_expiry_date | DATE | NULL | Alert 30 days before |
| supply_categories_json | JSON | NULL | e.g., ["Vegetables","Grains"] |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at / updated_at / deleted_at | TIMESTAMP | | |

#### 📐 `caf_stock_items`
| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| supplier_id | INT UNSIGNED | NULL FK→caf_suppliers | 🆕 New in V2 |
| name | VARCHAR(150) | NOT NULL | |
| category | ENUM('Grains','Pulses','Vegetables','Fruits','Dairy','Spices','Beverages','Condiments','Cleaning','Other') | NOT NULL | |
| unit | VARCHAR(20) | NOT NULL | kg, litre, piece, dozen |
| current_quantity | DECIMAL(10,3) | NOT NULL DEFAULT 0.000 | |
| reorder_level | DECIMAL(10,3) | NOT NULL | Alert threshold |
| reorder_quantity | DECIMAL(10,3) | NULL | Suggested purchase qty |
| cost_per_unit | DECIMAL(8,2) | NULL | |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at / updated_at / deleted_at | TIMESTAMP | | |

#### 📐 `caf_consumption_logs`
| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| stock_item_id | INT UNSIGNED | NOT NULL FK→caf_stock_items | |
| log_date | DATE | NOT NULL | |
| quantity_used | DECIMAL(10,3) | NOT NULL | |
| meal_category_id | INT UNSIGNED | NULL FK→caf_menu_categories | Which meal consumed for |
| notes | VARCHAR(255) | NULL | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at / updated_at | TIMESTAMP | | |
INDEX: `(stock_item_id, log_date)`

#### 📐 `caf_fssai_records`
| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| record_type | ENUM('License','Audit') | NOT NULL | |
| license_number | VARCHAR(50) | NULL | For License records |
| license_type | ENUM('Basic','State','Central') | NULL | |
| issue_date | DATE | NULL | |
| expiry_date | DATE | NULL | |
| licensed_entity_name | VARCHAR(150) | NULL | |
| fssai_document_media_id | INT UNSIGNED | NULL FK→sys_media | |
| audit_date | DATE | NULL | For Audit records |
| auditor_name | VARCHAR(100) | NULL | |
| audit_score | TINYINT UNSIGNED | NULL | 1–10 |
| audit_remarks | TEXT | NULL | |
| corrective_actions | TEXT | NULL | |
| next_audit_date | DATE | NULL | |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at / updated_at | TIMESTAMP | | |

#### 📐 `caf_staff_meal_logs`
| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| staff_id | BIGINT UNSIGNED | NOT NULL FK→sys_users | |
| meal_date | DATE | NOT NULL | |
| meal_category_id | INT UNSIGNED | NOT NULL FK→caf_menu_categories | |
| items_json | JSON | NULL | Snapshot of items |
| amount | DECIMAL(8,2) | NOT NULL DEFAULT 0.00 | |
| payment_mode | ENUM('Subscription','Cash','CardDeduction') | NOT NULL | |
| payroll_deduction_flag | TINYINT(1) | DEFAULT 0 | Flag for PAY module |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at / updated_at | TIMESTAMP | | |

### 5.3 Relationships

```
caf_menu_categories ←── caf_menu_items
                             │
caf_daily_menus ─── caf_daily_menu_items_jnt ─── caf_menu_items
caf_event_meals ─── caf_event_meal_items_jnt ─── caf_menu_items

std_students ─── caf_dietary_profiles
std_students ─── caf_meal_cards ─── caf_meal_card_transactions
std_students ─── caf_orders ─── caf_order_items ─── caf_menu_items
                      │
                caf_meal_cards (balance deducted on order)

caf_subscription_plans ─── caf_subscription_enrollments ─── std_students

caf_pos_sessions ─── caf_pos_transactions ─── caf_meal_cards
caf_meal_attendance (student + date + meal_category)

caf_suppliers ─── caf_stock_items ─── caf_consumption_logs

caf_fssai_records (standalone per cafeteria unit)
caf_staff_meal_logs (staff FK sys_users)
```

---

## 6. API Endpoints & Routes

### 6.1 Web Routes (tenant middleware group)

| Method | URI | Controller@Method | Auth | Description |
|---|---|---|---|---|
| GET | /cafeteria/dashboard | CafeteriaController@dashboard | Admin,CafMgr | Module dashboard |
| GET | /cafeteria/menu-categories | MenuCategoryController@index | Admin,CafMgr | List categories |
| POST | /cafeteria/menu-categories | MenuCategoryController@store | Admin,CafMgr | Create category |
| GET | /cafeteria/menu-categories/{id}/edit | MenuCategoryController@edit | Admin,CafMgr | Edit form |
| PUT | /cafeteria/menu-categories/{id} | MenuCategoryController@update | Admin,CafMgr | Update category |
| DELETE | /cafeteria/menu-categories/{id} | MenuCategoryController@destroy | Admin | Soft-delete |
| PATCH | /cafeteria/menu-categories/{id}/toggle | MenuCategoryController@toggle | Admin,CafMgr | Toggle is_active |
| GET | /cafeteria/menu-items | MenuItemController@index | Admin,CafMgr | List items |
| POST | /cafeteria/menu-items | MenuItemController@store | Admin,CafMgr | Create item |
| PUT | /cafeteria/menu-items/{id} | MenuItemController@update | Admin,CafMgr | Update item |
| DELETE | /cafeteria/menu-items/{id} | MenuItemController@destroy | Admin | Soft-delete |
| PATCH | /cafeteria/menu-items/{id}/availability | MenuItemController@toggleAvailability | Admin,CafMgr | AJAX availability |
| GET | /cafeteria/weekly-menus | WeeklyMenuController@index | Admin,CafMgr | List weekly plans |
| GET | /cafeteria/weekly-menus/create | WeeklyMenuController@create | Admin,CafMgr | Planner grid |
| POST | /cafeteria/weekly-menus | WeeklyMenuController@store | Admin,CafMgr | Save plan |
| GET | /cafeteria/weekly-menus/{id}/edit | WeeklyMenuController@edit | Admin,CafMgr | Edit plan |
| PUT | /cafeteria/weekly-menus/{id} | WeeklyMenuController@update | Admin,CafMgr | Update plan |
| POST | /cafeteria/weekly-menus/{id}/publish | WeeklyMenuController@publish | Admin,CafMgr | Publish + notify |
| POST | /cafeteria/weekly-menus/{id}/archive | WeeklyMenuController@archive | Admin,CafMgr | Archive plan |
| GET | /cafeteria/event-meals | EventMealController@index | Admin,CafMgr | List event meals |
| POST | /cafeteria/event-meals | EventMealController@store | Admin,CafMgr | Create event meal |
| PUT | /cafeteria/event-meals/{id} | EventMealController@update | Admin,CafMgr | Update event meal |
| POST | /cafeteria/event-meals/{id}/publish | EventMealController@publish | Admin,CafMgr | Publish event meal |
| GET | /cafeteria/dietary-profiles | DietaryProfileController@index | Admin,CafMgr | List profiles |
| POST | /cafeteria/dietary-profiles | DietaryProfileController@store | Admin,CafMgr | Create/upsert profile |
| PUT | /cafeteria/dietary-profiles/{id} | DietaryProfileController@update | Admin,CafMgr,Parent | Update profile |
| GET | /cafeteria/subscription-plans | SubscriptionPlanController@index | Admin | List plans |
| POST | /cafeteria/subscription-plans | SubscriptionPlanController@store | Admin | Create plan |
| PUT | /cafeteria/subscription-plans/{id} | SubscriptionPlanController@update | Admin | Update plan |
| GET | /cafeteria/subscription-enrollments | SubscriptionEnrollmentController@index | Admin,CafMgr | List enrollments |
| POST | /cafeteria/subscription-enrollments | SubscriptionEnrollmentController@store | Admin | Enroll student |
| DELETE | /cafeteria/subscription-enrollments/{id} | SubscriptionEnrollmentController@destroy | Admin | Cancel enrollment |
| GET | /cafeteria/orders | OrderController@index | Admin,CafMgr | All orders |
| GET | /cafeteria/orders/{id} | OrderController@show | Admin,CafMgr | Order detail |
| GET | /cafeteria/kitchen-view | OrderController@kitchenView | Kitchen,CafMgr | Kitchen summary |
| PATCH | /cafeteria/orders/{id}/status | OrderController@updateStatus | Admin,CafMgr | Update status |
| DELETE | /cafeteria/orders/{id} | OrderController@cancel | Admin,CafMgr | Cancel order |
| GET | /cafeteria/kitchen-view/print | OrderController@printKitchenSheet | Admin,CafMgr,Kitchen | PDF print |
| GET | /cafeteria/pos | PosController@index | Kitchen,CafMgr | POS interface |
| POST | /cafeteria/pos/sessions | PosController@openSession | Kitchen,CafMgr | Open POS session |
| POST | /cafeteria/pos/sessions/{id}/close | PosController@closeSession | Kitchen,CafMgr | Close session |
| POST | /cafeteria/pos/transactions | PosController@transact | Kitchen,CafMgr | Process sale |
| GET | /cafeteria/pos/student-lookup | PosController@studentLookup | Kitchen,CafMgr | Lookup by QR/ID |
| GET | /cafeteria/meal-attendance | MealAttendanceController@index | Admin,CafMgr | Attendance log |
| GET | /cafeteria/meal-cards | MealCardController@index | Admin,Accounts | Card list |
| POST | /cafeteria/meal-cards | MealCardController@store | Admin,Accounts | Issue card |
| POST | /cafeteria/meal-cards/{id}/topup | MealCardController@topup | Admin,Accounts | Top-up balance |
| GET | /cafeteria/meal-cards/{id}/statement | MealCardController@statement | Admin,Accounts | Transaction ledger PDF |
| GET | /cafeteria/stock-items | StockController@index | Admin,CafMgr | Raw material list |
| POST | /cafeteria/stock-items | StockController@store | Admin,CafMgr | Add stock item |
| PUT | /cafeteria/stock-items/{id} | StockController@update | Admin,CafMgr | Update item |
| POST | /cafeteria/stock-items/{id}/consume | StockController@logConsumption | Kitchen,CafMgr | Log consumption |
| GET | /cafeteria/suppliers | SupplierController@index | Admin,CafMgr | Supplier list |
| POST | /cafeteria/suppliers | SupplierController@store | Admin | Add supplier |
| PUT | /cafeteria/suppliers/{id} | SupplierController@update | Admin | Update supplier |
| GET | /cafeteria/fssai | FssaiController@index | Admin | FSSAI records |
| POST | /cafeteria/fssai | FssaiController@store | Admin | Add license/audit |
| GET | /cafeteria/reports/revenue | CafeteriaReportController@revenue | Admin,Accounts | Revenue report |
| GET | /cafeteria/reports/orders | CafeteriaReportController@orderSummary | Admin,CafMgr | Order summary |
| GET | /cafeteria/reports/wastage | CafeteriaReportController@wastage | Admin,CafMgr | Wastage report |
| GET | /cafeteria/reports/meal-card-statements | CafeteriaReportController@mealCardStatements | Admin,Accounts | Statements |

### 6.2 API Endpoints (auth:sanctum — for portals and POS scanner)

| Method | URI | Controller@Method | Description |
|---|---|---|---|
| GET | /api/v1/cafeteria/menu/{date} | MenuItemController@apiMenuForDate | Published menu for date (portal) |
| GET | /api/v1/cafeteria/menu/weekly | WeeklyMenuController@apiCurrentWeek | Current week's published plan |
| GET | /api/v1/cafeteria/student/{studentId}/dietary-profile | DietaryProfileController@apiGet | Student dietary profile |
| PUT | /api/v1/cafeteria/student/{studentId}/dietary-profile | DietaryProfileController@apiUpdate | Update dietary profile (parent) |
| POST | /api/v1/cafeteria/orders | OrderController@apiStore | Place pre-order (portal) |
| GET | /api/v1/cafeteria/orders | OrderController@apiIndex | Own orders list (student/parent) |
| DELETE | /api/v1/cafeteria/orders/{id} | OrderController@apiCancel | Cancel own order |
| GET | /api/v1/cafeteria/meal-card/balance | MealCardController@apiBalance | Own card balance |
| GET | /api/v1/cafeteria/meal-card/transactions | MealCardController@apiTransactions | Card statement (portal) |
| POST | /api/v1/cafeteria/meal-card/topup/razorpay | MealCardController@apiRazorpayTopup | Initiate Razorpay top-up |
| POST | /api/v1/cafeteria/meal-card/topup/webhook | MealCardController@apiRazorpayWebhook | Razorpay webhook (no auth) |
| POST | /api/v1/cafeteria/meal-attendance/scan | MealAttendanceController@apiScan | QR scan at counter |
| GET | /api/v1/cafeteria/kitchen-view | OrderController@apiKitchenView | Kitchen consolidated (POS device) |
| POST | /api/v1/cafeteria/pos/student-lookup | PosController@apiStudentLookup | QR code student lookup |
| POST | /api/v1/cafeteria/pos/transactions | PosController@apiTransact | POS transaction (tablet) |

---

## 7. UI Screens

| Screen ID | Screen Name | Route Name | Key Actors | Description |
|---|---|---|---|---|
| SCR-CAF-01 | Cafeteria Dashboard | cafeteria.dashboard | Admin, CafMgr | KPI widgets: revenue, orders, low-stock, card balances |
| SCR-CAF-02 | Menu Category List | cafeteria.menu-categories.index | Admin, CafMgr | CRUD table with drag-sort for display_order |
| SCR-CAF-03 | Menu Item List | cafeteria.menu-items.index | Admin, CafMgr | Filterable by category/food_type; availability toggle |
| SCR-CAF-04 | Menu Item Form | cafeteria.menu-items.create/edit | Admin, CafMgr | Nutrition macro inputs; photo upload; allergen notes |
| SCR-CAF-05 | Weekly Menu Planner | cafeteria.weekly-menus.create | Admin, CafMgr | 7-column × N-meal-category grid; drag items into slots |
| SCR-CAF-06 | Weekly Menu List | cafeteria.weekly-menus.index | Admin, CafMgr | Cards with status badge; Publish/Archive actions |
| SCR-CAF-07 | Event Meal Planner | cafeteria.event-meals.index | Admin, CafMgr | Create/publish special event meals; class filter |
| SCR-CAF-08 | Dietary Profile List | cafeteria.dietary-profiles.index | Admin, CafMgr | Table with flag chips; search by student |
| SCR-CAF-09 | Dietary Profile Form | cafeteria.dietary-profiles.create | Admin, CafMgr | Food preference + restriction checkboxes + notes |
| SCR-CAF-10 | Subscription Plan List | cafeteria.subscription-plans.index | Admin | Plan cards; enrolment count |
| SCR-CAF-11 | Subscription Enrolment List | cafeteria.subscription-enrollments.index | Admin, CafMgr | Active enrolments with status filter |
| SCR-CAF-12 | Order List | cafeteria.orders.index | Admin, CafMgr | Filterable by date, meal type, status; bulk mark Served |
| SCR-CAF-13 | Kitchen View | cafeteria.orders.kitchen | Kitchen, CafMgr | Date + meal_type filter; item totals; dietary flags; Print PDF |
| SCR-CAF-14 | POS Counter | cafeteria.pos.index | Kitchen, CafMgr | Touch-friendly item grid; QR scan; payment selection |
| SCR-CAF-15 | POS Session Summary | cafeteria.pos.session | Kitchen, CafMgr | Session total; cash vs card breakdown |
| SCR-CAF-16 | Meal Attendance Log | cafeteria.meal-attendance.index | Admin, CafMgr | Date + meal type filter; per-class attendance rate |
| SCR-CAF-17 | Meal Card List | cafeteria.meal-cards.index | Admin, Accounts | Cards with balance; issue new; top-up shortcut |
| SCR-CAF-18 | Meal Card Top-Up | cafeteria.meal-cards.topup | Admin, Accounts | Cash or Razorpay link; amount entry |
| SCR-CAF-19 | Meal Card Statement | cafeteria.meal-cards.statement | Admin, Accounts, Parent | Paginated ledger; Export PDF |
| SCR-CAF-20 | Raw Material Stock List | cafeteria.stock-items.index | Admin, CafMgr | Table with reorder-level warning badges |
| SCR-CAF-21 | Stock Consumption Log | cafeteria.stock-items.consume | Kitchen, CafMgr | Quick-log form; date + item + qty |
| SCR-CAF-22 | Supplier List | cafeteria.suppliers.index | Admin, CafMgr | FSSAI license expiry badges |
| SCR-CAF-23 | FSSAI Compliance | cafeteria.fssai.index | Admin | License details; audit log entries |
| SCR-CAF-24 | Revenue Report | cafeteria.reports.revenue | Admin, Accounts | Date-range filter; chart; Export CSV/PDF |
| SCR-CAF-25 | Order Summary Report | cafeteria.reports.orders | Admin, CafMgr | Per-student spend; per-class breakdown |
| SCR-CAF-26 | Wastage Report | cafeteria.reports.wastage | Admin, CafMgr | Planned vs actual; waste % and cost |
| SCR-CAF-27 | Portal Menu View | (Student/Parent Portal) | Student, Parent | Published weekly menu grid; day-wise nutritional info |
| SCR-CAF-28 | Portal Order Screen | (Student/Parent Portal) | Student, Parent | Select meal + items; cutoff timer; place order |
| SCR-CAF-29 | Portal Consumption History | (Parent Portal) | Parent | Child's meal attendance + order history |
| SCR-CAF-30 | Staff Meal Log | cafeteria.staff-meals.index | Admin, CafMgr | Staff meal entries; payroll flag |

---

## 8. Business Rules

| Rule ID | Rule | Scope |
|---|---|---|
| BR-CAF-001 | Order cutoff time = meal_start_time − caf_order_cutoff_hours (school setting, default 2 h). Post-cutoff orders are rejected. | Ordering |
| BR-CAF-002 | Dietary conflict (Jain student ordering Non-Veg/Egg; nut-allergy student ordering allergen item) shows a warning. Soft block — admin can override; student cannot. | Ordering, POS |
| BR-CAF-003 | Meal card balance may not go negative when school is in prepaid-only mode (sys_school_settings: caf_allow_negative_balance = false). | Meal Card |
| BR-CAF-004 | One active meal card per student (UNIQUE on student_id in caf_meal_cards). New card issuance requires deactivating the previous card. | Meal Card |
| BR-CAF-005 | Weekly menu may only be published if at least one menu item is assigned to at least one day-meal slot. | Menu Planning |
| BR-CAF-006 | Publishing a weekly menu dispatches a push/SMS notification to all active students and parents (via Notification module). | Notifications |
| BR-CAF-007 | When caf_stock_items.current_quantity ≤ reorder_level, system fires an in-app alert to all CAFETERIA_MGR users. If INV module is licensed, a purchase requisition is auto-created. | Stock |
| BR-CAF-008 | Order cancellation is allowed only before the cutoff window and when status = Confirmed. Meal card balance is refunded immediately on cancellation. | Ordering |
| BR-CAF-009 | Kitchen view displays only Confirmed orders for selected date + meal_category. | Kitchen |
| BR-CAF-010 | Subscription-enrolled students are pre-counted in kitchen headcount for their plan's meal_categories even without an explicit order record. | Subscriptions |
| BR-CAF-011 | Razorpay top-up webhook must be idempotent: duplicate razorpay_payment_id is rejected (UNIQUE constraint + check). | Payments |
| BR-CAF-012 | Balance deduction (order or POS) uses SELECT ... FOR UPDATE + DB transaction to prevent concurrent double-spend. | Concurrency |
| BR-CAF-013 | POS transactions must be linked to an open POS session. Staff cannot transact outside an active session. | POS |
| BR-CAF-014 | Supplier FSSAI license expiry alert fires at 30 days and 7 days before expiry_date. School FSSAI license alert fires at 60 and 30 days. | FSSAI |
| BR-CAF-015 | Hostel mess plan enrollment is triggered automatically on hostel admission (HST module bridge). Auto-enrollment deducts plan price from student meal card. | Hostel Mess |
| BR-CAF-016 | Event meals for specific class groups (target_class_ids_json) are only visible to enrolled students in those classes. | Event Meals |
| BR-CAF-017 | Low balance notification (< caf_low_balance_threshold, default ₹100) is sent to parent when balance drops after any debit transaction. | Notifications |
| BR-CAF-018 | Daily menu (caf_daily_menus) has a UNIQUE constraint on menu_date — only one menu record per calendar date. | Data Integrity |
| BR-CAF-019 | Staff meal payroll deduction flag (payroll_deduction_flag = 1) is a signal to the PAY module; the actual deduction is processed by Payroll, not CAF. | Integration |

---

## 9. Workflow Diagrams (FSM Descriptions)

### 9.1 Weekly Menu Lifecycle
```
[Draft] → (add items) → [Draft]
[Draft] → (publish) → [Published]  -- triggers notification
[Published] → (next week starts) → [Archived]  -- scheduler archives old menus
[Archived] → (read-only, no state change)
```

### 9.2 Pre-Order Lifecycle
```
[Placed by student/parent]
  → OrderService validates: menu Published? window open? dietary conflict?
  → MealCardService: balance sufficient? deduct atomically
  → [Confirmed]
  → Kitchen view shows on order_date
  → Staff marks [Served] via kitchen view or POS scan
  → [Served]

[Confirmed] → (cancel before cutoff) → [Cancelled]
  → MealCardService: refund to card balance
```

### 9.3 Meal Card Top-Up (Razorpay)
```
Parent initiates top-up on portal
  → POST /api/v1/cafeteria/meal-card/topup/razorpay
  → Razorpay order created; parent redirected to payment gateway
  → Payment success → Razorpay fires webhook → POST /cafeteria/topup/webhook
  → Webhook: verify signature; idempotency check on razorpay_payment_id
  → Create Credit transaction; update current_balance
  → SMS confirmation to parent
```

### 9.4 POS Session Lifecycle
```
[Session Opened] by Kitchen Staff
  → [Active] — transactions processed
  → [Closed] — session summary generated; cash reconciliation recorded
  → [Archived] — daily POS summary retained for reporting
```

### 9.5 Stock Reorder Alert
```
Kitchen logs consumption → StockService.deductQuantity()
  → current_quantity ≤ reorder_level?
    Yes → Fire in-app notification to CAFETERIA_MGR
        → INV module licensed? → Create purchase requisition via INV bridge
    No → Continue
```

---

## 10. Non-Functional Requirements

| Category | Requirement |
|---|---|
| Performance | Kitchen view for 500+ orders aggregated in < 2 s (composite index on `order_date, meal_category_id, status`; no N+1 queries). |
| Concurrency | Meal card balance deduction: `SELECT ... FOR UPDATE` + single DB transaction; prevents concurrent double-spend on simultaneous orders. |
| Scalability | All order and attendance tables indexed on `(student_id, date)` and `(date, meal_category_id)`. Partition large schools by academic year if row count > 1M. |
| Security | Students see only their own orders and card balance. Parents see only their child's data. Dietary profile is accessible to Kitchen staff (read-only). |
| Idempotency | Razorpay webhook: `razorpay_payment_id` UNIQUE constraint prevents duplicate credit. QR attendance scan: UNIQUE on `(student_id, meal_date, meal_category_id)`. |
| PDF Generation | Kitchen sheet, meal card statement, and FSSAI audit log generated via DomPDF. |
| QR Codes | Meal card QR code generated via `SimpleSoftwareIO/simple-qrcode`. |
| Availability | Order cutoff enforcement runs as a time-check in the service layer (no cron dependency); notification dispatch is queued (fails gracefully). |
| Audit Trail | All balance-affecting operations (debit, credit, refund, adjustment) recorded in `caf_meal_card_transactions` with `created_by` and timestamp. |
| Localization | Price displayed in INR (₹); nutritional values in grams/kcal. |
| Queue | Menu publish notification, low-balance alert, and reorder alert dispatched via Laravel Queue (database driver default). |

---

## 11. Module Dependencies

| Dependency | Module | Type | Detail |
|---|---|---|---|
| Student records | STD (std_students) | Read FK | dietary_profiles, orders, meal_cards all reference std_students.id |
| Academic term | SCH (sch_academic_terms) | Read FK | daily_menus and subscription_plans reference academic_term_id |
| User accounts | SYS (sys_users) | Read FK | created_by, published_by, staff meal logs, POS sessions |
| Media storage | SYS (sys_media) | Write | Dish photos, FSSAI license documents uploaded via sys_media |
| Activity log | SYS (sys_activity_logs) | Write | All state-change events logged for audit |
| Notifications | NTF | Dispatch | Menu publish, event meal publish, low balance, reorder alert, FSSAI expiry |
| Student Portal | STP | Integration | Portal order screen; meal card balance widget; menu view |
| Parent Portal | PPT | Integration | Order on behalf of child; top-up card; consumption history |
| Hostel | HST | Bridge | Hostel admission auto-triggers mess plan enrollment (caf_subscription_enrollments) |
| Inventory | INV | Bridge (optional) | Stock reorder triggers purchase requisition in INV module if licensed |
| Finance/Fees | FIN | Read pattern | Razorpay payment flow follows FIN module payment pattern (same gateway config) |
| Payroll | PAY | Signal | Staff meal payroll_deduction_flag signals PAY module; CAF does not deduct payroll |
| Vendor | VND | Future bridge | CAF suppliers may be mapped to VND vendors for PO creation |

---

## 12. Test Scenarios

| # | Test Class | Type | Scenario | Priority |
|---|---|---|---|---|
| 1 | MenuCategoryCrudTest | Browser | Create, edit, toggle, soft-delete, restore category | High |
| 2 | MenuItemCrudTest | Browser | Create item with food_type=Jain; toggle availability AJAX | High |
| 3 | WeeklyMenuPublishTest | Feature | Publish menu → notification dispatched; portal shows menu | Critical |
| 4 | MenuPublishBlockedTest | Feature | Publish blocked when no items assigned | High |
| 5 | OrderPlacementTest | Feature | Place order; verify meal card atomically deducted; Confirmed status | Critical |
| 6 | OrderCutoffTest | Feature | Order rejected after cutoff_hours threshold | Critical |
| 7 | DietaryConflictWarningTest | Feature | Non-Veg item ordered by Jain student returns warning; order still placeable by admin | High |
| 8 | NutAllergyConflictTest | Feature | Nut-allergy flag displayed on POS scan for matching student | High |
| 9 | MealCardTopUpCashTest | Feature | Admin cash top-up; balance updated; transaction record created | High |
| 10 | RazorpayWebhookTest | Feature | Webhook credit; duplicate payment_id rejected idempotently | Critical |
| 11 | MealCardNegativeBalanceTest | Feature | Order rejected when balance < total in prepaid-only mode | Critical |
| 12 | OrderCancellationRefundTest | Feature | Cancel before cutoff; balance refunded; status = Cancelled | High |
| 13 | KitchenConsolidationTest | Feature | Aggregate orders for date+meal; correct per-item totals and dietary counts | High |
| 14 | SubscriptionEnrollmentTest | Feature | Enroll student in plan; student appears in kitchen headcount without explicit order | High |
| 15 | StockReorderAlertTest | Feature | Consumption log reduces qty to ≤ reorder_level; notification fired | Medium |
| 16 | PosSessionTest | Feature | Open session; transact; close session; summary totals reconcile | High |
| 17 | QrAttendanceScanTest | Feature | QR scan records attendance; duplicate scan returns 200 idempotently | High |
| 18 | EventMealPublishTest | Feature | Event meal published for specific class group; other class students cannot order | Medium |
| 19 | FssaiExpiryAlertTest | Feature | Mock scheduler fires alert at 30 days before fssai_records.expiry_date | Low |
| 20 | StaffMealLogTest | Feature | Staff meal logged; payroll_deduction_flag set; revenue dashboard separates staff revenue | Medium |
| 21 | MealCardTransactionLedgerTest | Unit | Balance_after on each transaction equals prior balance ± amount | High |
| 22 | OrderNumberFormatTest | Unit | Order number matches regex CAF-\d{4}-[A-Z0-9]{8} | Low |

---

## 13. Glossary

| Term | Definition |
|---|---|
| Meal Card | Prepaid canteen wallet linked to a student; balance deducted on order or POS scan |
| Meal Category | A named meal slot in the day (Breakfast, Lunch, Snacks, Dinner, Tuck Shop) |
| Menu Item | A dish in the master library with price, food type, and nutritional data |
| Daily Menu | One day's planned set of menu items across all meal categories |
| Weekly Menu | A collection of daily menus for a Monday–Sunday week |
| Event Meal | A one-off special menu for a festival, sports day, or excursion |
| Subscription Plan | A fixed monthly/termly meal plan; enrolled students are auto-confirmed each day |
| Hostel Mess Plan | A subscription plan auto-assigned to hostel residents via HST module bridge |
| Order Cutoff | Configurable time window before which pre-ordering must be completed |
| Kitchen View | Consolidated preparation list showing item totals and dietary flags for kitchen staff |
| POS Session | A counter staff shift during which walk-in purchases are processed |
| Meal Attendance | Record of which students actually received a meal (QR scan at counter) |
| Wastage | Difference between planned (from orders) and actual (from attendance/consumption log) food usage |
| FSSAI | Food Safety and Standards Authority of India; governs food safety compliance for school canteens |
| Reorder Level | Minimum stock quantity threshold that triggers a purchase alert |
| Dietary Profile | Per-student record of food preference and allergy/restriction flags |
| food_type | Classification of a dish: Veg, Non-Veg, Egg, or Jain |
| Balance-After | Snapshot of meal card balance immediately after each transaction (denormalised for ledger integrity) |

---

## 14. Suggestions & Improvements

| ID | Suggestion | Rationale | Priority |
|---|---|---|---|
| SUG-CAF-01 | **Nutrition Summary on Portal** — Show student's estimated daily calorie and macro intake based on their orders. | Health-conscious parents and schools tracking student nutrition; differentiator feature. | Medium |
| SUG-CAF-02 | **Smart Menu Rotation Engine** — Auto-suggest next week's menu based on past popularity, season, and nutritional balance. | Reduces Cafeteria Manager planning effort; reduces repeated menu fatigue. | Low |
| SUG-CAF-03 | **Wastage ML Alert** — Flag days where order volume is historically over-estimated (e.g., exam weeks, holidays). | Reduces food waste and cost; requires 3–6 months of historical data. | Low |
| SUG-CAF-04 | **Allergen Badge System** — Use standardised EU allergen icons (14 major allergens) rather than free-text allergen_notes. | Standardised safety communication; reduces kitchen errors. | Medium |
| SUG-CAF-05 | **Multi-Counter POS** — Support multiple simultaneous POS sessions (breakfast counter, lunch counter) with per-counter reconciliation. | Large schools have multiple serving points; single session model is a bottleneck. | High |
| SUG-CAF-06 | **Parent Meal Budget Cap** — Allow parents to set a daily/weekly spend cap on the meal card; POS/order blocked when cap reached. | Parental control feature; reduces unexpected high spending. | Medium |
| SUG-CAF-07 | **Menu Photo Gallery** — Public-facing weekly menu with dish photos on the school website (SSG-friendly static page). | Marketing and parent engagement; schools can promote cafeteria quality. | Low |
| SUG-CAF-08 | **FSSAI Display Certificate** — Auto-generate a display certificate PDF from FSSAI record for physical display as per regulations. | Regulatory compliance; saves admin effort. | Medium |
| SUG-CAF-09 | **Barcode on Menu Items** — Add barcode field to caf_menu_items for POS scanner integration (external barcode readers). | Speeds up POS operations; enables tuck-shop style scanning. | Low |
| SUG-CAF-10 | **Canteen Feedback** — Post-meal rating by students (1–5 stars per dish per day); visible to Cafeteria Manager. | Quality feedback loop; identifies consistently poor-rated items. | Low |

---

## 15. Appendices

### 15.1 School Settings Required (`sys_school_settings`)

| Key | Type | Default | Description |
|---|---|---|---|
| caf_order_cutoff_hours | DECIMAL(4,2) | 2.00 | Hours before meal_start_time when ordering closes |
| caf_allow_negative_balance | BOOLEAN | false | Whether meal card can go below zero |
| caf_low_balance_threshold | DECIMAL(8,2) | 100.00 | INR threshold for low-balance parent notification |
| caf_prepaid_only_mode | BOOLEAN | true | Disallow counter payment; enforce prepaid meal card |
| caf_parent_scan_notification | BOOLEAN | false | Notify parent on child's QR scan at counter |
| caf_hostel_auto_enroll | BOOLEAN | true | Auto-enroll hostel students in hostel mess plan |
| caf_inv_integration | BOOLEAN | false | Create INV purchase requisition on stock reorder |

### 15.2 Permission Slugs

| Permission Slug | Description |
|---|---|
| tenant.caf-menu-category.view | View menu categories |
| tenant.caf-menu-category.create | Create categories |
| tenant.caf-menu-category.update | Edit categories |
| tenant.caf-menu-category.delete | Delete categories |
| tenant.caf-menu-item.view | View menu items |
| tenant.caf-menu-item.create | Create items |
| tenant.caf-menu-item.update | Edit items; toggle availability |
| tenant.caf-menu-item.delete | Delete items |
| tenant.caf-daily-menu.manage | Create/publish/archive weekly and event menus |
| tenant.caf-subscription.manage | Create plans and enroll students |
| tenant.caf-order.view | View all orders |
| tenant.caf-order.manage | Update order status; cancel orders |
| tenant.caf-pos.operate | Open/close POS sessions; process transactions |
| tenant.caf-meal-attendance.view | View meal attendance |
| tenant.caf-dietary-profile.manage | Create/update dietary profiles |
| tenant.caf-meal-card.manage | Issue cards, process top-ups |
| tenant.caf-stock.manage | Manage raw material stock and consumption log |
| tenant.caf-supplier.manage | Create/update suppliers |
| tenant.caf-fssai.manage | Manage FSSAI records and audits |
| tenant.caf-report.view | View all cafeteria reports |
| tenant.caf-staff-meal.manage | Log staff meals |

### 15.3 Module Statistics

| Metric | V1 Count | V2 Count | Delta |
|---|---|---|---|
| DB Tables | 10 | 21 | +11 |
| Named Web Routes | ~52 | ~62 | +10 |
| API Endpoints | 5 | 15 | +10 |
| Controllers | 8 | 16 | +8 |
| Services | 3 | 6 | +3 |
| Models | 10 | 21 | +11 |
| Blade Views | ~28 | ~50 | +22 |
| FormRequests | 8 | 16 | +8 |
| Policies | 8 | 14 | +6 |
| Test Classes | 10 | 22 | +12 |
| Permissions | 14 | 21 | +7 |

### 15.4 FormRequest Validation Rules (Key Rules)

| FormRequest | Key Rules |
|---|---|
| StoreMenuCategoryRequest | name: required\|max:100\|unique; meal_time: required\|in:Breakfast,Lunch,Snacks,Dinner,Tuck_Shop |
| StoreMenuItemRequest | name: required\|max:150; category_id: exists; price: numeric\|min:0.01; food_type: in:Veg,Non_Veg,Egg,Jain |
| StoreDailyMenuRequest | week_start_date: required\|date\|date_format:Y-m-d; items: array with day_date, meal_category_id, menu_item_ids[] |
| StoreEventMealRequest | name: required; event_date: required\|date\|after:today; meal_category_id: exists |
| StoreDietaryProfileRequest | student_id: required\|exists:std_students,id; food_preference: in:Veg,Non_Veg,Egg,Jain |
| StoreOrderRequest | student_id: exists; order_date: date\|after:today; items: array\|min:1; cutoff rule via service |
| TopUpMealCardRequest | amount: numeric\|min:50\|max:5000; payment_mode: in:Online,Cash; razorpay_payment_id: nullable\|unique |
| StoreStockItemRequest | name: required\|max:150; category: in:Grains,...; unit: required; reorder_level: numeric\|min:0 |
| LogConsumptionRequest | stock_item_id: exists; quantity_used: numeric\|min:0.001; log_date: date |
| StorePosTransactionRequest | pos_session_id: exists; items: array\|min:1; payment_mode: in:MealCard,Cash |
| StoreSubscriptionPlanRequest | name: required; billing_period: in:Monthly,Termly,Annual; price: numeric\|min:0 |
| StoreFssaiRecordRequest | record_type: in:License,Audit; expiry_date: nullable\|date\|after:today (for License type) |

---

## 16. V1 → V2 Delta

### 16.1 New Features Added in V2

| Feature | V1 Status | V2 Status | Notes |
|---|---|---|---|
| Special / Event Meal Management | Not in V1 | 📐 Proposed | Festival + excursion menus with class targeting |
| Meal Subscription Plans | Not in V1 | 📐 Proposed | Monthly/termly fixed plans; hostel mess plan bridge |
| Subscription Enrollments | Not in V1 | 📐 Proposed | Student ↔ plan enrollment with auto-kitchen headcount |
| QR-Based Meal Attendance | Not in V1 | 📐 Proposed | Scan at counter; feeds wastage report |
| POS Counter Interface | Not in V1 | 📐 Proposed | Touch POS; QR student lookup; session model |
| POS Sessions & Transactions | Not in V1 | 📐 Proposed | Shift-level reconciliation; 2 new tables |
| Supplier Management (CAF) | Not in V1 | 📐 Proposed | FSSAI license tracking per supplier |
| FSSAI Compliance Tracking | Not in V1 | 📐 Proposed | School license + audit log; expiry alerts |
| Staff Meal Management | Not in V1 | 📐 Proposed | Separate staff meal log; PAY module flag |
| INV Module Integration Bridge | Noted as future | 📐 Proposed | Auto purchase requisition on stock reorder |
| Meal Card Adjustment transaction type | Not in V1 | 📐 Proposed | Admin manual balance correction |
| is_dairy_free flag on dietary profile | Not in V1 | 📐 Proposed | Additional allergy restriction |
| Low Balance Notification | Not in V1 | 📐 Proposed | Push/SMS when card balance < threshold |
| supplier_id on caf_stock_items | Not in V1 | 📐 Proposed | Traceability: which supplier provided item |
| Multi-Counter POS suggestion | Not in V1 | SUG-CAF-05 | Noted for future iteration |

### 16.2 V1 Features Retained (Unchanged Scope)

| Feature | V1 Status | V2 Status |
|---|---|---|
| Menu Category Management | 📐 Proposed | 📐 Proposed |
| Menu Item Master | 📐 Proposed | 📐 Proposed |
| Weekly Menu Planning & Publish | 📐 Proposed | 📐 Proposed |
| Student Dietary Profile | 📐 Proposed | 📐 Proposed (+ is_dairy_free) |
| Meal Pre-Ordering (Portal) | 📐 Proposed | 📐 Proposed |
| Order Cutoff Enforcement | 📐 Proposed | 📐 Proposed |
| Kitchen Consolidated View | 📐 Proposed | 📐 Proposed |
| Meal Card Management | 📐 Proposed | 📐 Proposed (+ Adjustment type) |
| Raw Material Stock Register | 📐 Proposed | 📐 Proposed (+ supplier_id) |
| Reorder Alerts | 📐 Proposed | 📐 Proposed (+ INV bridge) |
| Consumption Tracking | 📐 Proposed | 📐 Proposed (moved to caf_consumption_logs) |
| Wastage Reports | 📐 Proposed | 📐 Proposed |
| Revenue Dashboard | 📐 Proposed | 📐 Proposed |

### 16.3 Schema Changes from V1 to V2

| Change Type | Detail |
|---|---|
| New tables (11) | caf_event_meals, caf_event_meal_items_jnt, caf_subscription_plans, caf_subscription_enrollments, caf_meal_attendance, caf_pos_sessions, caf_pos_transactions, caf_suppliers, caf_consumption_logs, caf_fssai_records, caf_staff_meal_logs |
| Modified: caf_dietary_profiles | Added `is_dairy_free TINYINT(1) DEFAULT 0` |
| Modified: caf_stock_items | Added `supplier_id INT UNSIGNED NULL FK→caf_suppliers` |
| Modified: caf_menu_categories | Added `meal_start_time TIME NULL` (for cutoff calculation) |
| Modified: caf_orders | Added payment_mode value `Subscription` to ENUM |
| Modified: caf_meal_card_transactions | Added transaction_type value `Adjustment`; added `razorpay_payment_id UNIQUE` |
| Renamed: V1 consumption tracking | V1 used caf_stock_items.consumed_today aggregate → V2 uses dedicated caf_consumption_logs table |

---

*RBS Reference: Module W — Cafeteria & Mess Management (ST.W1.1.1.1 – ST.W3.1.2.2)*
*V2 Document generated: 2026-03-26 | Status: Draft | Mode: RBS_ONLY | All features 📐 Proposed*

