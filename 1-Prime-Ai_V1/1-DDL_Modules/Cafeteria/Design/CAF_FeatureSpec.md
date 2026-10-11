# CAF — Cafeteria Module Feature Specification
**Module:** CAF (Cafeteria & Mess Management) | **Version:** 1.0 | **Date:** 2026-03-27
**Source:** CAF_Cafeteria_Requirement.md v2 | **Status:** Phase 1 Output

---

## Section 1 — Module Identity & Scope

### 1.1 Identity

| Attribute | Value |
|-----------|-------|
| Module Code | CAF |
| Module Name | Cafeteria & Mess Management |
| Namespace | `Modules\Cafeteria` |
| Route Prefix | `cafeteria/` |
| Route Name Prefix | `cafeteria.` |
| API Route Prefix | `/api/v1/cafeteria/` |
| DB Table Prefix | `caf_` |
| Module Type | Tenant (per-school DB, no `tenant_id` column) |
| Branch | `Brijesh_Main` |
| RBS Code | W (Welfare/Cafeteria) |

### 1.2 In-Scope Sub-Modules

| Sub-Module | Description |
|-----------|-------------|
| **L1 — Menu Planning** | Menu category master, dish library (nutrition + allergens), weekly menu planner (Draft→Published→Archived lifecycle), special/event meals with class-group targeting |
| **L2 — Orders & Attendance** | Student dietary profiles, meal subscription plans, pre-order portal (cutoff enforced), QR-based meal attendance scanning (idempotent), kitchen headcount consolidation |
| **L3 — Meal Cards & POS** | Prepaid wallet (one per student), cashless top-up via Razorpay (idempotent webhook), atomic balance deduction (`SELECT...FOR UPDATE`), POS counter interface (touch-friendly, QR lookup, dietary alert), card statement PDF |
| **L4 — Stock & Compliance** | Raw material stock register with reorder alerts, optional INV purchase requisition bridge, FSSAI license + audit log with expiry alerts, staff meal tracking with PAY module payroll signal |

### 1.3 Out of Scope

- Payroll deduction computation — delegated to PAY module (CAF only sets `payroll_deduction_flag=1`)
- Vendor/supplier purchase order creation — delegated to VND/INV modules (CAF bridges via PR only)
- Depreciation, accounting ledgers — not in CAF scope
- Full medical dietary management — CAF stores dietary flags; clinical records are in HPC module
- Day-scholar canteen (standalone, school-level) vs hostel mess — distinction managed via `is_hostel_plan` flag on subscription plans
- Campus-wide visitor catering — managed by FrontDesk (fnt_*) module

### 1.4 Module Scale

| Artifact | Count |
|----------|-------|
| Controllers | 16 |
| Models | 21 |
| Services | 6 |
| FormRequests | 16 |
| Policies | 14 |
| caf_* Tables | 21 |
| Blade Views (est.) | ~50 |
| Seeders | 1 + 1 runner |
| Events / Notifications | 5 (MenuPublished, LowBalanceAlert, StockReorderAlert, FssaiExpiryAlert, HostelAdmission bridge) |
| Artisan Commands | 4 (archive-old-menus, send-fssai-alerts, check-stock-reorder, + LowBalance triggered per-transaction) |

### 1.5 FK Type Resolution (Critical — Verified Against tenant_db_v2.sql)

> **WARNING:** The requirement document lists `created_by` as `BIGINT UNSIGNED FK→sys_users`. The actual `tenant_db_v2.sql` shows `sys_users.id = INT UNSIGNED`. All cross-module FK columns must match their parent PK types exactly.

| Column Pattern | Actual Parent PK Type | Use In caf_* Tables |
|---------------|----------------------|---------------------|
| `created_by`, `published_by`, `opened_by`, `scanned_by` → `sys_users.id` | **INT UNSIGNED** | `INT UNSIGNED NULL` |
| `staff_id` → `sys_users.id` | **INT UNSIGNED** | `INT UNSIGNED NULL` |
| `student_id` → `std_students.id` | INT UNSIGNED | `INT UNSIGNED` |
| `photo_media_id`, `fssai_document_media_id` → `sys_media.id` | INT UNSIGNED | `INT UNSIGNED NULL` |
| `academic_term_id` → `sch_academic_term.id` | **SMALLINT UNSIGNED** | `SMALLINT UNSIGNED NULL` |
| All caf_* PKs | — | `INT UNSIGNED AUTO_INCREMENT` |
| All intra-module FKs (caf_* → caf_*) | INT UNSIGNED | `INT UNSIGNED` |

> **Table name:** `sch_academic_term` (singular) — NOT `sch_academic_terms` (plural as stated in requirement). Confirmed at line 2775 of tenant_db_v2.sql.

---

## Section 2 — Entity Inventory (All 21 Tables)

### Domain: Menu Planning (5 tables)

#### `caf_menu_categories`
Meal-type category master (Breakfast, Lunch, Snacks, Dinner, Tuck Shop) with serving time and display order.

| Column | Type | Nullable | Default | Constraints | Comment |
|--------|------|----------|---------|-------------|---------|
| id | INT UNSIGNED | NO | AUTO_INCREMENT | PK | |
| name | VARCHAR(100) | NO | | | e.g., Breakfast |
| code | VARCHAR(20) | YES | NULL | UNIQUE | Short code (BRK, LNC…) |
| meal_time | ENUM('Breakfast','Lunch','Snacks','Dinner','Tuck_Shop') | NO | | | Serving type |
| meal_start_time | TIME | YES | NULL | | Scheduled serving start |
| description | TEXT | YES | NULL | | |
| display_order | TINYINT UNSIGNED | NO | 0 | | Portal sort order |
| is_active | TINYINT(1) | NO | 1 | | Soft enable/disable |
| created_by | INT UNSIGNED | YES | NULL | FK→sys_users | |
| created_at | TIMESTAMP | YES | NULL | | |
| updated_at | TIMESTAMP | YES | NULL | | |
| deleted_at | TIMESTAMP | YES | NULL | | Soft delete |

**Unique:** `UNIQUE(code)` — nullable, multiple NULLs allowed
**Indexes:** `code`

---

#### `caf_menu_items`
Dish library with full nutritional macros, food type, allergen notes, and optional dish photo.

| Column | Type | Nullable | Default | Constraints | Comment |
|--------|------|----------|---------|-------------|---------|
| id | INT UNSIGNED | NO | AUTO_INCREMENT | PK | |
| category_id | INT UNSIGNED | NO | | FK→caf_menu_categories | |
| name | VARCHAR(150) | NO | | | Dish name |
| description | TEXT | YES | NULL | | |
| price | DECIMAL(8,2) | NO | | | Per serving price (INR) |
| food_type | ENUM('Veg','Non_Veg','Egg','Jain') | NO | 'Veg' | | For dietary conflict check |
| calories | SMALLINT UNSIGNED | YES | NULL | | Kcal per serving |
| protein_grams | DECIMAL(5,2) | YES | NULL | | |
| carbs_grams | DECIMAL(5,2) | YES | NULL | | |
| fat_grams | DECIMAL(5,2) | YES | NULL | | |
| allergen_notes | TEXT | YES | NULL | | Free-form allergen info |
| photo_media_id | INT UNSIGNED | YES | NULL | FK→sys_media | Dish photo |
| is_available | TINYINT(1) | NO | 1 | | Real-time availability toggle |
| is_active | TINYINT(1) | NO | 1 | | Soft enable/disable |
| created_by | INT UNSIGNED | YES | NULL | FK→sys_users | |
| created_at | TIMESTAMP | YES | NULL | | |
| updated_at | TIMESTAMP | YES | NULL | | |
| deleted_at | TIMESTAMP | YES | NULL | | Soft delete |

**Indexes:** `category_id`, `photo_media_id`, `food_type`, `is_available`

---

#### `caf_daily_menus`
One record per calendar date — menu header (Draft/Published/Archived).

| Column | Type | Nullable | Default | Constraints | Comment |
|--------|------|----------|---------|-------------|---------|
| id | INT UNSIGNED | NO | AUTO_INCREMENT | PK | |
| menu_date | DATE | NO | | UNIQUE | One menu per date (BR-CAF-018) |
| week_start_date | DATE | NO | | | ISO Monday of the week |
| academic_term_id | SMALLINT UNSIGNED | YES | NULL | FK→sch_academic_term | |
| status | ENUM('Draft','Published','Archived') | NO | 'Draft' | | |
| published_at | TIMESTAMP | YES | NULL | | |
| published_by | INT UNSIGNED | YES | NULL | FK→sys_users | |
| notes | TEXT | YES | NULL | | Kitchen notes |
| is_active | TINYINT(1) | NO | 1 | | |
| created_by | INT UNSIGNED | YES | NULL | FK→sys_users | |
| created_at | TIMESTAMP | YES | NULL | | |
| updated_at | TIMESTAMP | YES | NULL | | |
| deleted_at | TIMESTAMP | YES | NULL | | |

**Unique:** `UNIQUE(menu_date)` — BR-CAF-018
**Indexes:** `menu_date`, `week_start_date`, `academic_term_id`, `status`, `published_by`

---

#### `caf_daily_menu_items_jnt`
Day × meal-category × dish assignments — what is served at each meal on each day.

| Column | Type | Nullable | Default | Constraints | Comment |
|--------|------|----------|---------|-------------|---------|
| id | INT UNSIGNED | NO | AUTO_INCREMENT | PK | |
| daily_menu_id | INT UNSIGNED | NO | | FK→caf_daily_menus | |
| menu_item_id | INT UNSIGNED | NO | | FK→caf_menu_items | |
| meal_category_id | INT UNSIGNED | NO | | FK→caf_menu_categories | |
| serving_size_notes | VARCHAR(100) | YES | NULL | | e.g., "1 plate", "200ml" |
| display_order | TINYINT UNSIGNED | NO | 0 | | |
| is_active | TINYINT(1) | NO | 1 | | |
| created_by | INT UNSIGNED | YES | NULL | FK→sys_users | |
| created_at | TIMESTAMP | YES | NULL | | |
| updated_at | TIMESTAMP | YES | NULL | | |

> No `deleted_at` — junction table; no soft delete on transactional junction records.

**Unique:** `UNIQUE(daily_menu_id, menu_item_id, meal_category_id)`
**Indexes:** `daily_menu_id`, `menu_item_id`, `meal_category_id`

---

#### `caf_event_meals`
Special/festival meal headers with optional class-group targeting.

| Column | Type | Nullable | Default | Constraints | Comment |
|--------|------|----------|---------|-------------|---------|
| id | INT UNSIGNED | NO | AUTO_INCREMENT | PK | |
| name | VARCHAR(150) | NO | | | e.g., "Diwali Special Lunch" |
| event_date | DATE | NO | | | |
| meal_category_id | INT UNSIGNED | NO | | FK→caf_menu_categories | |
| target_class_ids_json | JSON | YES | NULL | | NULL = all students (BR-CAF-016) |
| status | ENUM('Draft','Published','Archived') | NO | 'Draft' | | |
| published_at | TIMESTAMP | YES | NULL | | |
| notes | TEXT | YES | NULL | | |
| is_active | TINYINT(1) | NO | 1 | | |
| created_by | INT UNSIGNED | YES | NULL | FK→sys_users | |
| created_at | TIMESTAMP | YES | NULL | | |
| updated_at | TIMESTAMP | YES | NULL | | |
| deleted_at | TIMESTAMP | YES | NULL | | |

**Indexes:** `event_date`, `meal_category_id`, `status`

---

### Domain: Dietary & Subscriptions (4 tables)

#### `caf_event_meal_items_jnt`
Event meal × menu item assignments (menu_item_id nullable for free-text items).

| Column | Type | Nullable | Default | Constraints | Comment |
|--------|------|----------|---------|-------------|---------|
| id | INT UNSIGNED | NO | AUTO_INCREMENT | PK | |
| event_meal_id | INT UNSIGNED | NO | | FK→caf_event_meals | |
| menu_item_id | INT UNSIGNED | YES | NULL | FK→caf_menu_items | **Nullable** — free-text items allowed |
| free_text_item | VARCHAR(150) | YES | NULL | | Used when not in dish library |
| quantity_per_student | DECIMAL(5,2) | YES | NULL | | |
| display_order | TINYINT UNSIGNED | NO | 0 | | |
| is_active | TINYINT(1) | NO | 1 | | |
| created_by | INT UNSIGNED | YES | NULL | FK→sys_users | |
| created_at | TIMESTAMP | YES | NULL | | |
| updated_at | TIMESTAMP | YES | NULL | | |

> No `deleted_at` — junction table.

**Indexes:** `event_meal_id`, `menu_item_id`

---

#### `caf_dietary_profiles`
Per-student dietary preference and restriction flags (one profile per student).

| Column | Type | Nullable | Default | Constraints | Comment |
|--------|------|----------|---------|-------------|---------|
| id | INT UNSIGNED | NO | AUTO_INCREMENT | PK | |
| student_id | INT UNSIGNED | NO | | UNIQUE FK→std_students | One profile per student |
| food_preference | ENUM('Veg','Non_Veg','Egg','Jain') | NO | 'Veg' | | Primary food preference |
| is_no_onion_garlic | TINYINT(1) | NO | 0 | | |
| is_gluten_free | TINYINT(1) | NO | 0 | | |
| is_nut_allergy | TINYINT(1) | NO | 0 | | Flagged on POS scan (BR-CAF-002) |
| is_dairy_free | TINYINT(1) | NO | 0 | | |
| custom_restrictions | TEXT | YES | NULL | | Free-form notes |
| medical_dietary_note | TEXT | YES | NULL | | Doctor-recommended diet |
| is_active | TINYINT(1) | NO | 1 | | |
| created_by | INT UNSIGNED | YES | NULL | FK→sys_users | |
| created_at | TIMESTAMP | YES | NULL | | |
| updated_at | TIMESTAMP | YES | NULL | | |
| deleted_at | TIMESTAMP | YES | NULL | | |

**Unique:** `UNIQUE(student_id)`
**Indexes:** `student_id`

---

#### `caf_subscription_plans`
Fixed meal plan definitions (monthly/termly/annual) linked to meal categories.

| Column | Type | Nullable | Default | Constraints | Comment |
|--------|------|----------|---------|-------------|---------|
| id | INT UNSIGNED | NO | AUTO_INCREMENT | PK | |
| name | VARCHAR(150) | NO | | | e.g., "Full Day Plan" |
| description | TEXT | YES | NULL | | |
| included_category_ids_json | JSON | NO | | | Array of caf_menu_categories.id |
| billing_period | ENUM('Monthly','Termly','Annual') | NO | 'Monthly' | | |
| price | DECIMAL(10,2) | NO | | | Plan price (INR) |
| academic_term_id | SMALLINT UNSIGNED | YES | NULL | FK→sch_academic_term | |
| is_hostel_plan | TINYINT(1) | NO | 0 | | Links to HST module (BR-CAF-015) |
| is_staff_plan | TINYINT(1) | NO | 0 | | For staff meal deductions |
| is_active | TINYINT(1) | NO | 1 | | |
| created_by | INT UNSIGNED | YES | NULL | FK→sys_users | |
| created_at | TIMESTAMP | YES | NULL | | |
| updated_at | TIMESTAMP | YES | NULL | | |
| deleted_at | TIMESTAMP | YES | NULL | | |

**Indexes:** `academic_term_id`, `is_hostel_plan`, `is_staff_plan`

---

#### `caf_subscription_enrollments`
Student/staff × plan enrollment records.

| Column | Type | Nullable | Default | Constraints | Comment |
|--------|------|----------|---------|-------------|---------|
| id | INT UNSIGNED | NO | AUTO_INCREMENT | PK | |
| subscription_plan_id | INT UNSIGNED | NO | | FK→caf_subscription_plans | |
| student_id | INT UNSIGNED | YES | NULL | FK→std_students | Mutually exclusive with staff_id |
| staff_id | INT UNSIGNED | YES | NULL | FK→sys_users | Mutually exclusive with student_id |
| meal_card_id | INT UNSIGNED | YES | NULL | FK→caf_meal_cards | Plan fee deducted from this card |
| start_date | DATE | NO | | | |
| end_date | DATE | YES | NULL | | |
| status | ENUM('Active','Paused','Cancelled','Expired') | NO | 'Active' | | |
| cancellation_reason | TEXT | YES | NULL | | |
| is_active | TINYINT(1) | NO | 1 | | |
| created_by | INT UNSIGNED | YES | NULL | FK→sys_users | |
| created_at | TIMESTAMP | YES | NULL | | |
| updated_at | TIMESTAMP | YES | NULL | | |
| deleted_at | TIMESTAMP | YES | NULL | | |

**Indexes:** `subscription_plan_id`, `student_id`, `staff_id`, `meal_card_id`, `status`

---

### Domain: Orders & Attendance (3 tables)

#### `caf_orders`
Pre-order headers — one record per student per meal category per order date.

| Column | Type | Nullable | Default | Constraints | Comment |
|--------|------|----------|---------|-------------|---------|
| id | INT UNSIGNED | NO | AUTO_INCREMENT | PK | |
| order_number | VARCHAR(30) | NO | | UNIQUE | CAF-YYYY-XXXXXXXX |
| student_id | INT UNSIGNED | NO | | FK→std_students | |
| meal_card_id | INT UNSIGNED | YES | NULL | FK→caf_meal_cards | NULL if cash/counter |
| order_date | DATE | NO | | | Meal date |
| meal_category_id | INT UNSIGNED | NO | | FK→caf_menu_categories | |
| total_amount | DECIMAL(10,2) | NO | | | Sum of line items |
| payment_mode | ENUM('MealCard','Cash','Counter','Subscription') | NO | 'MealCard' | | |
| status | ENUM('Pending','Confirmed','Served','Cancelled') | NO | 'Confirmed' | | |
| cancelled_at | TIMESTAMP | YES | NULL | | |
| cancellation_reason | VARCHAR(255) | YES | NULL | | |
| notes | TEXT | YES | NULL | | |
| is_active | TINYINT(1) | NO | 1 | | |
| created_by | INT UNSIGNED | YES | NULL | FK→sys_users | |
| created_at | TIMESTAMP | YES | NULL | | |
| updated_at | TIMESTAMP | YES | NULL | | |
| deleted_at | TIMESTAMP | YES | NULL | | |

**Unique:** `UNIQUE(order_number)`
**Indexes:** `order_number`, `student_id`, `meal_card_id`, `meal_category_id`, `(student_id, order_date)`, `(order_date, meal_category_id, status)`

---

#### `caf_order_items`
Pre-order line items with price snapshot at order time.

| Column | Type | Nullable | Default | Constraints | Comment |
|--------|------|----------|---------|-------------|---------|
| id | INT UNSIGNED | NO | AUTO_INCREMENT | PK | |
| order_id | INT UNSIGNED | NO | | FK→caf_orders | |
| menu_item_id | INT UNSIGNED | NO | | FK→caf_menu_items | |
| quantity | TINYINT UNSIGNED | NO | 1 | | |
| unit_price | DECIMAL(8,2) | NO | | NOT NULL | **Price snapshot** at order time — never re-read from menu_items |
| line_total | DECIMAL(10,2) | NO | | NOT NULL | quantity × unit_price (populated at insert) |
| created_at | TIMESTAMP | YES | NULL | | |
| updated_at | TIMESTAMP | YES | NULL | | |

> No `is_active`, no `deleted_at` — transactional record; no soft delete.

**Unique:** `UNIQUE(order_id, menu_item_id)`
**Indexes:** `order_id`, `menu_item_id`

---

#### `caf_meal_attendance`
QR/biometric scan records for actual meal serving — one record per student per meal per day.

| Column | Type | Nullable | Default | Constraints | Comment |
|--------|------|----------|---------|-------------|---------|
| id | INT UNSIGNED | NO | AUTO_INCREMENT | PK | |
| student_id | INT UNSIGNED | NO | | FK→std_students | |
| meal_date | DATE | NO | | | |
| meal_category_id | INT UNSIGNED | NO | | FK→caf_menu_categories | |
| scanned_at | TIMESTAMP | NO | CURRENT_TIMESTAMP | | |
| scan_method | ENUM('QR','Biometric','Manual') | NO | 'QR' | | |
| counter_name | VARCHAR(100) | YES | NULL | | Which POS counter scanned |
| scanned_by | INT UNSIGNED | YES | NULL | FK→sys_users | Staff who scanned manually |
| created_at | TIMESTAMP | YES | NULL | | |

> No `is_active`, no `deleted_at`, no `updated_at` — scan records are immutable.

**Unique:** `UNIQUE(student_id, meal_date, meal_category_id)` — idempotent QR scan
**Indexes:** `student_id`, `meal_date`, `meal_category_id`, `scanned_by`

---

### Domain: Meal Cards & POS (4 tables)

#### `caf_pos_sessions`
POS shift sessions — open/close model for each staff member per day.

| Column | Type | Nullable | Default | Constraints | Comment |
|--------|------|----------|---------|-------------|---------|
| id | INT UNSIGNED | NO | AUTO_INCREMENT | PK | |
| session_date | DATE | NO | | | |
| opened_by | INT UNSIGNED | NO | | FK→sys_users | Staff opening session |
| opened_at | TIMESTAMP | NO | | | |
| closed_at | TIMESTAMP | YES | NULL | | NULL = session still active |
| total_cash_collected | DECIMAL(10,2) | NO | 0.00 | | Reconciliation total |
| total_card_debited | DECIMAL(10,2) | NO | 0.00 | | |
| total_transactions | INT UNSIGNED | NO | 0 | | Running count |
| notes | TEXT | YES | NULL | | |
| is_active | TINYINT(1) | NO | 1 | | |
| created_at | TIMESTAMP | YES | NULL | | |
| updated_at | TIMESTAMP | YES | NULL | | |

**Indexes:** `session_date`, `opened_by`, `closed_at`

---

#### `caf_pos_transactions`
Individual POS counter sales — items_json snapshot; immutable after save.

| Column | Type | Nullable | Default | Constraints | Comment |
|--------|------|----------|---------|-------------|---------|
| id | INT UNSIGNED | NO | AUTO_INCREMENT | PK | |
| pos_session_id | INT UNSIGNED | NO | | FK→caf_pos_sessions | |
| student_id | INT UNSIGNED | YES | NULL | FK→std_students | NULL if anonymous |
| staff_id | INT UNSIGNED | YES | NULL | FK→sys_users | NULL if student |
| meal_card_id | INT UNSIGNED | YES | NULL | FK→caf_meal_cards | |
| items_json | JSON | NO | | NOT NULL | `[{menu_item_id, name, qty, price}]` — immutable snapshot |
| total_amount | DECIMAL(10,2) | NO | | | |
| payment_mode | ENUM('MealCard','Cash') | NO | | | |
| balance_after | DECIMAL(10,2) | YES | NULL | | Snapshot for MealCard mode |
| dietary_flags_json | JSON | YES | NULL | | Student dietary flags at scan time |
| receipt_sent | TINYINT(1) | NO | 0 | | |
| created_by | INT UNSIGNED | YES | NULL | FK→sys_users | |
| created_at | TIMESTAMP | YES | NULL | | |
| updated_at | TIMESTAMP | YES | NULL | | |

> No `deleted_at` — transactional record; no soft delete.

**Indexes:** `pos_session_id`, `student_id`, `staff_id`, `meal_card_id`

---

#### `caf_meal_cards`
Student prepaid wallet — one active card per student (UNIQUE on student_id).

| Column | Type | Nullable | Default | Constraints | Comment |
|--------|------|----------|---------|-------------|---------|
| id | INT UNSIGNED | NO | AUTO_INCREMENT | PK | |
| student_id | INT UNSIGNED | NO | | UNIQUE FK→std_students | **One active card per student** (BR-CAF-004) |
| card_number | VARCHAR(20) | NO | | UNIQUE | CAF-CARD-XXXXXXXX |
| current_balance | DECIMAL(10,2) | NO | 0.00 | | Updated atomically by MealCardService |
| total_credited | DECIMAL(10,2) | NO | 0.00 | | Lifetime top-up total |
| total_debited | DECIMAL(10,2) | NO | 0.00 | | Lifetime spend total |
| valid_from_date | DATE | NO | | | |
| valid_to_date | DATE | YES | NULL | | Auto: end of academic year |
| is_active | TINYINT(1) | NO | 1 | | |
| created_by | INT UNSIGNED | YES | NULL | FK→sys_users | |
| created_at | TIMESTAMP | YES | NULL | | |
| updated_at | TIMESTAMP | YES | NULL | | |
| deleted_at | TIMESTAMP | YES | NULL | | |

**Unique:** `UNIQUE(student_id)`, `UNIQUE(card_number)`
**Indexes:** `student_id`, `card_number`, `is_active`

---

#### `caf_meal_card_transactions`
Credit/Debit/Refund/Adjustment ledger with `balance_after` snapshot and Razorpay idempotency.

| Column | Type | Nullable | Default | Constraints | Comment |
|--------|------|----------|---------|-------------|---------|
| id | INT UNSIGNED | NO | AUTO_INCREMENT | PK | |
| meal_card_id | INT UNSIGNED | NO | | FK→caf_meal_cards | |
| student_id | INT UNSIGNED | NO | | FK→std_students | Denormalized for queries |
| transaction_type | ENUM('Credit','Debit','Refund','Adjustment') | NO | | | |
| amount | DECIMAL(10,2) | NO | | | |
| balance_after | DECIMAL(10,2) | NO | | NOT NULL | **Snapshot after transaction** — ledger integrity |
| reference_type | VARCHAR(50) | YES | NULL | | 'Order','POS','TopUp','Refund','Adjustment' |
| reference_id | INT UNSIGNED | YES | NULL | | FK to referenced record |
| payment_mode | ENUM('Online','Cash','Wallet','Free') | YES | NULL | | For top-ups |
| razorpay_payment_id | VARCHAR(100) | YES | NULL | UNIQUE | Idempotency (BR-CAF-011); NULLs exempt from UNIQUE |
| notes | TEXT | YES | NULL | | |
| created_by | INT UNSIGNED | YES | NULL | FK→sys_users | |
| created_at | TIMESTAMP | YES | NULL | | |
| updated_at | TIMESTAMP | YES | NULL | | |

> No `deleted_at` — financial ledger; immutable.

**Unique:** `UNIQUE(razorpay_payment_id)` — nullable UNIQUE; MySQL allows multiple NULLs
**Indexes:** `meal_card_id`, `student_id`, `transaction_type`, `razorpay_payment_id`, `(meal_card_id, created_at)`

---

### Domain: Stock & Suppliers (3 tables)

#### `caf_suppliers`
Food/material supplier register with FSSAI license tracking.

| Column | Type | Nullable | Default | Constraints | Comment |
|--------|------|----------|---------|-------------|---------|
| id | INT UNSIGNED | NO | AUTO_INCREMENT | PK | |
| name | VARCHAR(150) | NO | | | |
| contact_person | VARCHAR(100) | YES | NULL | | |
| phone | VARCHAR(20) | YES | NULL | | |
| email | VARCHAR(100) | YES | NULL | | |
| address | TEXT | YES | NULL | | |
| fssai_license_no | VARCHAR(50) | YES | NULL | | Supplier's own FSSAI license |
| fssai_expiry_date | DATE | YES | NULL | | Alert 30+7 days before (BR-CAF-014) |
| supply_categories_json | JSON | YES | NULL | | e.g., `["Vegetables","Grains"]` |
| is_active | TINYINT(1) | NO | 1 | | |
| created_by | INT UNSIGNED | YES | NULL | FK→sys_users | |
| created_at | TIMESTAMP | YES | NULL | | |
| updated_at | TIMESTAMP | YES | NULL | | |
| deleted_at | TIMESTAMP | YES | NULL | | |

**Indexes:** `fssai_expiry_date`, `is_active`

---

#### `caf_stock_items`
Raw material inventory with reorder threshold.

| Column | Type | Nullable | Default | Constraints | Comment |
|--------|------|----------|---------|-------------|---------|
| id | INT UNSIGNED | NO | AUTO_INCREMENT | PK | |
| supplier_id | INT UNSIGNED | YES | NULL | FK→caf_suppliers | |
| name | VARCHAR(150) | NO | | | |
| category | ENUM('Grains','Pulses','Vegetables','Fruits','Dairy','Spices','Beverages','Condiments','Cleaning','Other') | NO | | | |
| unit | VARCHAR(20) | NO | | | kg, litre, piece, dozen |
| current_quantity | DECIMAL(10,3) | NO | 0.000 | | Updated by StockService on consumption |
| reorder_level | DECIMAL(10,3) | NO | | | Alert threshold (BR-CAF-007) |
| reorder_quantity | DECIMAL(10,3) | YES | NULL | | Suggested purchase qty for INV bridge |
| cost_per_unit | DECIMAL(8,2) | YES | NULL | | |
| is_active | TINYINT(1) | NO | 1 | | |
| created_by | INT UNSIGNED | YES | NULL | FK→sys_users | |
| created_at | TIMESTAMP | YES | NULL | | |
| updated_at | TIMESTAMP | YES | NULL | | |
| deleted_at | TIMESTAMP | YES | NULL | | |

**Indexes:** `supplier_id`, `category`, `is_active`

---

#### `caf_consumption_logs`
Daily raw-material usage log — deducted from caf_stock_items.current_quantity.

| Column | Type | Nullable | Default | Constraints | Comment |
|--------|------|----------|---------|-------------|---------|
| id | INT UNSIGNED | NO | AUTO_INCREMENT | PK | |
| stock_item_id | INT UNSIGNED | NO | | FK→caf_stock_items | |
| log_date | DATE | NO | | | |
| quantity_used | DECIMAL(10,3) | NO | | | Amount consumed |
| meal_category_id | INT UNSIGNED | YES | NULL | FK→caf_menu_categories | Which meal |
| notes | VARCHAR(255) | YES | NULL | | |
| created_by | INT UNSIGNED | YES | NULL | FK→sys_users | |
| created_at | TIMESTAMP | YES | NULL | | |
| updated_at | TIMESTAMP | YES | NULL | | |

> No `is_active`, no `deleted_at` — consumption log; no soft delete.

**Indexes:** `stock_item_id`, `log_date`, `meal_category_id`, `(stock_item_id, log_date)`

---

### Domain: Compliance & Staff (2 tables)

#### `caf_fssai_records`
FSSAI license and hygiene audit log — covers both school license and periodic audits.

| Column | Type | Nullable | Default | Constraints | Comment |
|--------|------|----------|---------|-------------|---------|
| id | INT UNSIGNED | NO | AUTO_INCREMENT | PK | |
| record_type | ENUM('License','Audit') | NO | | | Discriminator |
| license_number | VARCHAR(50) | YES | NULL | | For License records |
| license_type | ENUM('Basic','State','Central') | YES | NULL | | For License records |
| issue_date | DATE | YES | NULL | | |
| expiry_date | DATE | YES | NULL | | Alert 60+30 days before (BR-CAF-014) |
| licensed_entity_name | VARCHAR(150) | YES | NULL | | School/unit name |
| fssai_document_media_id | INT UNSIGNED | YES | NULL | FK→sys_media | License document scan |
| audit_date | DATE | YES | NULL | | For Audit records |
| auditor_name | VARCHAR(100) | YES | NULL | | |
| audit_score | TINYINT UNSIGNED | YES | NULL | | 1–10 scale |
| audit_remarks | TEXT | YES | NULL | | |
| corrective_actions | TEXT | YES | NULL | | |
| next_audit_date | DATE | YES | NULL | | |
| is_active | TINYINT(1) | NO | 1 | | |
| created_by | INT UNSIGNED | YES | NULL | FK→sys_users | |
| created_at | TIMESTAMP | YES | NULL | | |
| updated_at | TIMESTAMP | YES | NULL | | |

> No `deleted_at` — compliance record; no soft delete.

**Indexes:** `record_type`, `expiry_date`, `fssai_document_media_id`

---

#### `caf_staff_meal_logs`
Staff meal tracking with payroll deduction signal to PAY module.

| Column | Type | Nullable | Default | Constraints | Comment |
|--------|------|----------|---------|-------------|---------|
| id | INT UNSIGNED | NO | AUTO_INCREMENT | PK | |
| staff_id | INT UNSIGNED | NO | | FK→sys_users | Staff member |
| meal_date | DATE | NO | | | |
| meal_category_id | INT UNSIGNED | NO | | FK→caf_menu_categories | |
| items_json | JSON | YES | NULL | | Items snapshot |
| amount | DECIMAL(8,2) | NO | 0.00 | | |
| payment_mode | ENUM('Subscription','Cash','CardDeduction') | NO | | | |
| payroll_deduction_flag | TINYINT(1) | NO | 0 | | **PAY module reads this** — CAF never writes to pay_* (BR-CAF-019) |
| created_by | INT UNSIGNED | YES | NULL | FK→sys_users | |
| created_at | TIMESTAMP | YES | NULL | | |
| updated_at | TIMESTAMP | YES | NULL | | |

> No `is_active`, no `deleted_at` — transactional log.

**Indexes:** `staff_id`, `meal_date`, `meal_category_id`, `payroll_deduction_flag`

---

## Section 3 — Entity Relationship Diagram

```
=== CAF Internal Tables ===

L1 (No caf_* deps):
  caf_menu_categories ←─── sys_media (none)
  caf_suppliers
  caf_fssai_records ────────────────────────→ sys_media.id (photo_media_id)
  caf_daily_menus ──────────────────────────→ sch_academic_term.id
                                           └─→ sys_users.id (published_by)
  caf_subscription_plans ──────────────────→ sch_academic_term.id
  caf_meal_cards ──────────────────────────→ std_students.id [UNIQUE]
  caf_pos_sessions ────────────────────────→ sys_users.id (opened_by)
  caf_dietary_profiles ────────────────────→ std_students.id [UNIQUE]

L2 (Depends on L1):
  caf_menu_items ──────────────────────────→ caf_menu_categories.id
                                           └─→ sys_media.id (photo_media_id)
  caf_stock_items ─────────────────────────→ caf_suppliers.id
  caf_event_meals ─────────────────────────→ caf_menu_categories.id
  caf_subscription_enrollments ────────────→ caf_subscription_plans.id
                                           └─→ caf_meal_cards.id
                                           └─→ std_students.id
                                           └─→ sys_users.id (staff_id)
  caf_meal_card_transactions ──────────────→ caf_meal_cards.id
  caf_meal_attendance ─────────────────────→ caf_menu_categories.id
                                           └─→ std_students.id
  caf_pos_transactions ────────────────────→ caf_pos_sessions.id
                                           └─→ caf_meal_cards.id
                                           └─→ std_students.id
  caf_staff_meal_logs ─────────────────────→ caf_menu_categories.id
                                           └─→ sys_users.id (staff_id)
  caf_orders ──────────────────────────────→ std_students.id
                                           └─→ caf_meal_cards.id
                                           └─→ caf_menu_categories.id

L3 (Depends on L2):
  caf_daily_menu_items_jnt ────────────────→ caf_daily_menus.id
                                           └─→ caf_menu_items.id
                                           └─→ caf_menu_categories.id
  caf_event_meal_items_jnt ────────────────→ caf_event_meals.id
                                           └─→ caf_menu_items.id [NULLABLE]
  caf_consumption_logs ────────────────────→ caf_stock_items.id
                                           └─→ caf_menu_categories.id

L4 (Depends on L3):
  caf_order_items ─────────────────────────→ caf_orders.id
                                           └─→ caf_menu_items.id

=== Cross-Module FKs (Critical) ===
  caf_menu_items.photo_media_id      → sys_media.id       (INT UNSIGNED, nullable)
  caf_fssai_records.fssai_document_media_id → sys_media.id (INT UNSIGNED, nullable)
  caf_daily_menus.academic_term_id   → sch_academic_term.id (SMALLINT UNSIGNED, nullable)
  caf_subscription_plans.academic_term_id → sch_academic_term.id (SMALLINT UNSIGNED, nullable)
  caf_dietary_profiles.student_id    → std_students.id    (INT UNSIGNED, UNIQUE)
  caf_meal_cards.student_id          → std_students.id    (INT UNSIGNED, UNIQUE)
  caf_orders.student_id              → std_students.id    (INT UNSIGNED)
  caf_meal_attendance.student_id     → std_students.id    (INT UNSIGNED)
  All created_by / published_by / opened_by / scanned_by → sys_users.id (INT UNSIGNED)

=== Special Notes ===
  caf_event_meal_items_jnt.menu_item_id     → NULLABLE (free-text items allowed)
  caf_meal_card_transactions.razorpay_payment_id → UNIQUE nullable (idempotency)
  caf_daily_menus.menu_date                 → UNIQUE (one menu per date)
  caf_meal_attendance                       → UNIQUE (student_id, meal_date, meal_category_id)
  INV bridge: caf_stock_items triggers inv_purchase_requisitions write when licensed (no FK)
  PAY bridge: caf_staff_meal_logs.payroll_deduction_flag read-only by PAY module (no FK to pay_*)
```

---

## Section 4 — Business Rules (19 Rules)

| Rule ID | Rule Text | Table/Column Enforced | Enforcement Point |
|---------|-----------|----------------------|------------------|
| BR-CAF-001 | Order cutoff = `meal_start_time − caf_order_cutoff_hours` (default 2h). Post-cutoff orders rejected. | `caf_menu_categories.meal_start_time`, sys_settings `caf_order_cutoff_hours` | `service_layer` (OrderService::placeOrder step 2) |
| BR-CAF-002 | Dietary conflict (Jain → Non_Veg/Egg; nut allergy → allergen item) shows warning. Soft block — admin can override; student cannot. | `caf_dietary_profiles`, `caf_menu_items.food_type/allergen_notes` | `service_layer` (OrderService + PosService) |
| BR-CAF-003 | Meal card balance may not go negative when `caf_allow_negative_balance=false` (prepaid-only mode). | `caf_meal_cards.current_balance` | `service_layer` (MealCardService::deductBalance step 3) |
| BR-CAF-004 | One active meal card per student. New card issuance deactivates previous card. | `caf_meal_cards.student_id` UNIQUE | `db_constraint` + `service_layer` (MealCardService::issueCard) |
| BR-CAF-005 | Weekly menu may only be published if ≥1 item assigned to ≥1 day-meal slot. | `caf_daily_menu_items_jnt` count > 0 | `service_layer` (MenuService::publishMenu pre-condition) |
| BR-CAF-006 | Publishing a weekly menu dispatches push/SMS to all active students and parents (NTF module). | `caf_daily_menus.status → Published` | `service_layer` (MenuService::publishMenu → dispatch MenuPublished notification) |
| BR-CAF-007 | When `caf_stock_items.current_quantity ≤ reorder_level`, dispatch in-app alert to CAFETERIA_MGR. If INV licensed, auto-create purchase requisition. | `caf_stock_items.current_quantity`, `reorder_level` | `service_layer` (StockService::logConsumption → reorder check) |
| BR-CAF-008 | Order cancellation allowed only before cutoff AND when status = Confirmed. Balance refunded immediately. | `caf_orders.status`, cutoff window | `service_layer` (OrderService::cancelOrder) + `form_validation` |
| BR-CAF-009 | Kitchen view shows only Confirmed orders for selected date + meal_category. | `caf_orders.status = 'Confirmed'`, `order_date`, `meal_category_id` | `service_layer` (OrderService::kitchenView query filter) |
| BR-CAF-010 | Subscription-enrolled students pre-counted in kitchen headcount for their plan's meal_categories (even without explicit order). | `caf_subscription_enrollments.status = 'Active'`, `included_category_ids_json` | `service_layer` (OrderService::getKitchenHeadcount includes subscription count) |
| BR-CAF-011 | Razorpay top-up webhook must be idempotent: duplicate `razorpay_payment_id` rejected (UNIQUE constraint + app check). | `caf_meal_card_transactions.razorpay_payment_id` UNIQUE | `db_constraint` + `service_layer` (MealCardService::creditBalance webhook) |
| BR-CAF-012 | Balance deduction uses `SELECT...FOR UPDATE` + DB transaction to prevent concurrent double-spend. | `caf_meal_cards.current_balance` | `service_layer` (MealCardService::deductBalance — row-lock pattern) |
| BR-CAF-013 | POS transactions must be linked to an open POS session (`closed_at IS NULL`). | `caf_pos_sessions.closed_at` | `service_layer` (PosService::processTransaction) + `form_validation` |
| BR-CAF-014 | Supplier FSSAI expiry alerts at 30d + 7d; school FSSAI alerts at 60d + 30d. | `caf_suppliers.fssai_expiry_date`, `caf_fssai_records.expiry_date` | `scheduled_command` (`caf:send-fssai-alerts` daily) |
| BR-CAF-015 | Hostel mess plan auto-enrollment triggered on hostel admission (HST bridge). Deducts plan fee from meal card. | `caf_subscription_enrollments`, `caf_meal_cards` | `service_layer` (HostelAdmissionListener when `caf_hostel_auto_enroll=true`) |
| BR-CAF-016 | Event meals with `target_class_ids_json` visible only to enrolled students in those classes. | `caf_event_meals.target_class_ids_json` | `service_layer` + `form_validation` (EventMealController portal filter) |
| BR-CAF-017 | Low balance notification (< `caf_low_balance_threshold`, default ₹100) sent to parent after every debit. | `caf_meal_cards.current_balance` | `service_layer` (MealCardService::deductBalance step 8 → dispatch LowBalanceNotificationJob) |
| BR-CAF-018 | `caf_daily_menus.menu_date` UNIQUE — only one menu record per calendar date. | `caf_daily_menus.menu_date` UNIQUE | `db_constraint` |
| BR-CAF-019 | Staff meal `payroll_deduction_flag=1` is a signal to PAY module; actual deduction is PAY's responsibility. CAF never writes to `pay_*` tables. | `caf_staff_meal_logs.payroll_deduction_flag` | `service_layer` (no FK to pay_*; flag-only pattern) |

---

## Section 5 — Workflow State Machines (5 FSMs)

### FSM 1 — Weekly Menu Lifecycle

```
[New Week]
    |
    v
 [DRAFT] ──── (add items to day-meal slots) ──→ [DRAFT]
    |
    | MenuService::publishMenu()
    | Pre-conditions:
    |   ✓ ≥1 item assigned to ≥1 day-meal slot (BR-CAF-005)
    |
    v
[PUBLISHED] ──── (caf:archive-old-menus Artisan, daily)
    |
    | Trigger: menu_date < today; ran by daily scheduler
    v
[ARCHIVED] (terminal; read-only)
```

**On Publish:**
- `caf_daily_menus.status → Published`
- `published_at = now()`, `published_by = auth()->id()`
- Dispatch `MenuPublished` notification → NTF module → push/SMS to all active students + parents

**On Archive:**
- `caf:archive-old-menus` runs at daily midnight
- All `Published` menus where `menu_date < CURDATE()` → `Archived`
- Archived menus remain readable (no delete)

---

### FSM 2 — Pre-Order Lifecycle

```
  [PLACED]
     |
     | OrderService::placeOrder()
     | Steps: menu Published + cutoff check + dietary warning + balance deduction
     v
[CONFIRMED] ──── (cancel before cutoff) ──→ [CANCELLED]
     |                                           ^
     |                                           | OrderService::cancelOrder()
     | Kitchen scan / POS                        | Pre: status=Confirmed + within cutoff
     v                                           | Side effect: MealCardService::refundBalance()
  [SERVED] (terminal)
```

**On Confirm (from Placed):**
- OrderService checks: menu Published + cutoff window + dietary conflict (soft warning)
- MealCardService::deductBalance() (atomic — SELECT...FOR UPDATE + DB transaction)
- caf_orders.status → Confirmed; caf_order_items inserted with unit_price snapshot

**On Cancel:**
- Only when status = Confirmed AND before cutoff (BR-CAF-008)
- MealCardService::refundBalance() → caf_meal_card_transactions (Refund)
- caf_orders.status → Cancelled; cancelled_at + cancellation_reason set

**On Serve:**
- Set by POS or kitchen view mark-served
- caf_orders.status → Served (terminal)

---

### FSM 3 — Meal Card Top-Up (Razorpay)

```
[INITIATE]
     |
     | MealCardController::apiRazorpayTopup()
     v
[GATEWAY_REDIRECT] ── Student redirected to Razorpay
     |
     | Razorpay webhook POST /api/v1/cafeteria/meal-card/topup/webhook
     | (withoutMiddleware auth:sanctum — public endpoint)
     v
[WEBHOOK_RECEIVED]
     |
     | Step 1: Verify Razorpay HMAC-SHA256 signature
     | Step 2: Idempotency check on razorpay_payment_id UNIQUE
     |         Duplicate → return 200 with existing transaction (no double-credit)
     | Step 3: MealCardService::creditBalance() inside DB::transaction()
     v
[CREDITED] (terminal)
     |
     | Side effects:
     | ─ caf_meal_cards.current_balance += amount
     | ─ total_credited += amount
     | ─ INSERT caf_meal_card_transactions (Credit, razorpay_payment_id stored)
     | ─ NTF: SMS to parent confirming top-up amount
```

---

### FSM 4 — POS Session Lifecycle

```
[Staff opens session]
          |
          | PosService::openSession()
          | Pre: no other open session for same staff on same date
          v
       [ACTIVE]
          |
          | PosService::processTransaction()
          | Pre: session.closed_at IS NULL (BR-CAF-013)
          | Each transaction: deduct from MealCard OR collect cash
          |
          | PosService::closeSession()
          v
       [CLOSED] ──── (daily scheduler) ──→ [ARCHIVED]

Side effects on close:
  - closed_at = now()
  - total_cash_collected + total_card_debited reconciled from linked transactions
  - Summary report available
```

---

### FSM 5 — Stock Reorder Alert

```
[Kitchen logs consumption]
          |
          | StockController → StockService::logConsumption()
          v
[INSERT caf_consumption_logs; UPDATE caf_stock_items.current_quantity -= quantity_used]
          |
          | StockService::checkReorderLevel(stockItem)
          |
          ├── current_quantity > reorder_level → [NO ACTION]
          |
          └── current_quantity ≤ reorder_level → [ALERT]
                    |
                    ├─ Dispatch StockReorderAlertJob (queued)
                    |   → NTF: in-app to CAFETERIA_MGR role
                    |
                    └─ if caf_inv_integration=true AND INV module licensed:
                        StockService::createInvPurchaseRequisition()
                        → INSERT inv_purchase_requisitions (if table exists)
                        → Graceful degradation: catch exception if INV not available
```

---

## Section 6 — Functional Requirements Summary (15 FRs)

| FR ID | Name | Sub-Module | Tables Used | Key Validations | Related BRs | Depends On |
|-------|------|-----------|------------|----------------|------------|-----------|
| FR-CAF-01 | Menu Category Management | L1 | `caf_menu_categories` | name required; code unique if provided; meal_time valid ENUM | — | — |
| FR-CAF-02 | Menu Item Master | L1 | `caf_menu_items` | name required; category_id exists; price > 0; food_type valid | BR-CAF-002 | FR-CAF-01 |
| FR-CAF-03 | Weekly Menu Planning & Publish | L1 | `caf_daily_menus`, `caf_daily_menu_items_jnt` | UNIQUE(menu_date); ≥1 item before publish; status FSM | BR-CAF-005, BR-CAF-006, BR-CAF-018 | FR-CAF-01, FR-CAF-02 |
| FR-CAF-04 | Special/Event Meal Management | L1 | `caf_event_meals`, `caf_event_meal_items_jnt` | event_date required; class-group filter; nullable menu_item_id | BR-CAF-016 | FR-CAF-01, FR-CAF-02 |
| FR-CAF-05 | Student Dietary Profile | L2 | `caf_dietary_profiles` | UNIQUE(student_id); food_preference valid ENUM | BR-CAF-002 | STD module (std_students) |
| FR-CAF-06 | Meal Subscription Plans | L2 | `caf_subscription_plans`, `caf_subscription_enrollments` | included_category_ids_json valid array; student_id XOR staff_id | BR-CAF-010, BR-CAF-015 | FR-CAF-01, FR-CAF-08 |
| FR-CAF-07 | Meal Pre-Ordering (Portal) | L2 | `caf_orders`, `caf_order_items` | menu Published + cutoff check + dietary conflict; order_number unique | BR-CAF-001, BR-CAF-002, BR-CAF-008, BR-CAF-009 | FR-CAF-03, FR-CAF-08 |
| FR-CAF-08 | Meal Card (Prepaid Wallet) | L3 | `caf_meal_cards`, `caf_meal_card_transactions` | UNIQUE(student_id); UNIQUE(card_number); balance ≥ 0 (prepaid); razorpay idempotency | BR-CAF-003, BR-CAF-004, BR-CAF-011, BR-CAF-012, BR-CAF-017 | STD module |
| FR-CAF-09 | QR-Based Meal Attendance | L2 | `caf_meal_attendance` | UNIQUE(student_id, meal_date, meal_category_id); idempotent scan returns 200 | — | FR-CAF-01 |
| FR-CAF-10 | POS Counter Interface | L3 | `caf_pos_sessions`, `caf_pos_transactions` | open session required; dietary alert on scan; balance deduction atomic | BR-CAF-002, BR-CAF-012, BR-CAF-013 | FR-CAF-08 |
| FR-CAF-11 | Raw Material Stock Management | L4 | `caf_stock_items`, `caf_consumption_logs`, `caf_suppliers` | reorder alert on deduction; optional INV bridge | BR-CAF-007 | FR-CAF-01 |
| FR-CAF-12 | FSSAI Compliance Tracking | L4 | `caf_fssai_records` | record_type discriminator; expiry alerts at 60+30 days (school), 30+7 days (supplier) | BR-CAF-014 | — |
| FR-CAF-13 | Staff Meal Management | L4 | `caf_staff_meal_logs` | payroll_deduction_flag signal only; CAF never writes to pay_* | BR-CAF-019 | FR-CAF-01 |
| FR-CAF-14 | Kitchen Consolidation & Reports | L2 | `caf_orders`, `caf_meal_attendance`, `caf_subscription_enrollments` | Confirmed orders + subscription headcount aggregated; DomPDF kitchen sheet | BR-CAF-009, BR-CAF-010 | FR-CAF-06, FR-CAF-07 |
| FR-CAF-15 | Cross-Module Integration | All | `caf_subscription_enrollments`, `caf_stock_items` | HST bridge: `caf_hostel_auto_enroll`; INV bridge: `caf_inv_integration`; PAY flag only | BR-CAF-007, BR-CAF-015, BR-CAF-019 | HST, INV, PAY modules |

---

## Section 7 — Permission Matrix

| Permission String | Admin | CafMgr | Kitchen | Accounts | Student | Parent |
|------------------|-------|--------|---------|----------|---------|--------|
| `cafeteria.menu-category.viewAny` | ✓ | ✓ | ✓ | — | — | — |
| `cafeteria.menu-category.create/update/delete` | ✓ | ✓ | — | — | — | — |
| `cafeteria.menu-item.viewAny` | ✓ | ✓ | ✓ | — | ✓ | ✓ |
| `cafeteria.menu-item.create/update/delete` | ✓ | ✓ | — | — | — | — |
| `cafeteria.menu-item.toggle-availability` | ✓ | ✓ | ✓ | — | — | — |
| `cafeteria.daily-menu.manage` (plan/publish/archive) | ✓ | ✓ | — | — | — | — |
| `cafeteria.daily-menu.view` (portal) | ✓ | ✓ | ✓ | — | ✓ | ✓ |
| `cafeteria.event-meal.manage` | ✓ | ✓ | — | — | — | — |
| `cafeteria.subscription.manage` | ✓ | ✓ | — | ✓ | — | — |
| `cafeteria.dietary-profile.manage` | ✓ | ✓ | — | — | ✓ (own) | ✓ (child) |
| `cafeteria.order.view` | ✓ | ✓ | ✓ | ✓ | ✓ (own) | ✓ (child) |
| `cafeteria.order.manage` | ✓ | ✓ | ✓ | — | ✓ (own, portal) | — |
| `cafeteria.pos.operate` | ✓ | ✓ | ✓ | — | — | — |
| `cafeteria.meal-attendance.view` | ✓ | ✓ | ✓ | — | — | — |
| `cafeteria.meal-card.viewAny` | ✓ | ✓ | — | ✓ | ✓ (own) | ✓ (child) |
| `cafeteria.meal-card.manage` (issue/top-up) | ✓ | ✓ | — | ✓ | — | ✓ (top-up only) |
| `cafeteria.stock.manage` | ✓ | ✓ | ✓ (consumption log) | — | — | — |
| `cafeteria.supplier.manage` | ✓ | ✓ | — | — | — | — |
| `cafeteria.fssai.manage` | ✓ | ✓ | — | — | — | — |
| `cafeteria.staff-meal.manage` | ✓ | ✓ | ✓ | — | — | — |
| `cafeteria.report.view` | ✓ | ✓ | — | ✓ | — | — |
| `cafeteria.report.export` | ✓ | ✓ | — | ✓ | — | — |

**Policies (14):**
`MenuCategoryPolicy`, `MenuItemPolicy`, `DailyMenuPolicy`, `EventMealPolicy`, `DietaryProfilePolicy`, `SubscriptionPlanPolicy`, `SubscriptionEnrollmentPolicy`, `OrderPolicy`, `MealAttendancePolicy`, `PosSessionPolicy`, `MealCardPolicy`, `StockItemPolicy`, `SupplierPolicy`, `FssaiRecordPolicy`

---

## Section 8 — Service Architecture (6 Services)

### 1. MenuService
**File:** `app/Services/MenuService.php`
**Namespace:** `Modules\Cafeteria\app\Services`
**Depends on:** *(none)*
**Fires:** `MenuPublished` notification

```
Key Methods:

  publishMenu(DailyMenu $menu, User $staff): void
    └── Pre-condition: ≥1 item in caf_daily_menu_items_jnt for this menu (BR-CAF-005)
        Sets status=Published, published_at, published_by;
        Dispatches MenuPublished → NTF → push/SMS all active students + parents (BR-CAF-006)

  archiveOldMenus(): int
    └── Sets status=Archived for all Published menus where menu_date < CURDATE()
        Called by caf:archive-old-menus Artisan command; returns count archived

  publishEventMeal(EventMeal $eventMeal, User $staff): void
    └── Sets status=Published; dispatches notification; respects target_class_ids_json (BR-CAF-016)

  canPublish(DailyMenu $menu): bool
    └── Returns true if ≥1 caf_daily_menu_items_jnt record exists for this menu_id

  toggleItemAvailability(MenuItem $item): bool
    └── Flips is_available; returns new value (AJAX endpoint support)
```

---

### 2. OrderService
**File:** `app/Services/OrderService.php`
**Depends on:** `MealCardService`
**Fires:** *(no events — uses MealCardService which fires LowBalanceNotificationJob)*

```
Key Methods:

  placeOrder(Student $student, array $orderData): Order
    └── 8-step pre-order sequence (see pseudocode below)

  cancelOrder(Order $order, User $actor, string $reason): void
    └── Validates: status=Confirmed + within cutoff (BR-CAF-008)
        MealCardService::refundBalance(); sets status=Cancelled + cancelled_at

  markServed(Order $order): void
    └── Sets status=Served

  getKitchenView(int $date, int $mealCategoryId): array
    └── Query Confirmed orders for date+meal_category; aggregate by menu_item_id;
        Add subscription headcount (BR-CAF-010); return array with dietary flag counts

  printKitchenSheetPdf(int $date, int $mealCategoryId): string
    └── DomPDF render of kitchen view; returns PDF response

  checkCutoff(MenuCategory $category): bool
    └── meal_start_time - caf_order_cutoff_hours > now() (BR-CAF-001)

  checkDietaryConflict(Student $student, array $menuItemIds): array
    └── Returns array of conflict warnings; does NOT block by default (BR-CAF-002)

  generateOrderNumber(): string
    └── Format: CAF-YYYY-XXXXXXXX (random 8-char alphanumeric)
```

**OrderService::placeOrder() — 8-step pseudocode:**
```
placeOrder(Student $student, array $orderData): Order
  Step 1: Load DailyMenu for $orderData['order_date']; verify status = Published
  Step 2: Check cutoff window: $category->meal_start_time - caf_order_cutoff_hours > now()
          If past cutoff → throw OrderCutoffException (BR-CAF-001)
  Step 3: Check dietary conflict (soft warning — log, flag on order; do NOT block unless student role)
          If $actor is student AND conflict exists → throw DietaryConflictException
          If $actor is admin → attach warning, allow
  Step 4: Compute total_amount = SUM(caf_menu_items.price × qty) for requested items
  Step 5: If payment_mode == 'MealCard':
            MealCardService::deductBalance($card, $total_amount, 'Order', $tempId)
  Step 6: INSERT caf_orders (status = 'Confirmed', order_number = generateOrderNumber())
  Step 7: INSERT caf_order_items with unit_price snapshot from caf_menu_items.price
          (unit_price captured NOW — not re-read later)
  Step 8: Return Order
```

---

### 3. MealCardService
**File:** `app/Services/MealCardService.php`
**Depends on:** *(none)*
**Fires:** `LowBalanceNotificationJob` (queued, per-transaction)

```
Key Methods:

  issueCard(Student $student, array $data): MealCard
    └── Deactivates previous card if exists (is_active=0); creates new card with
        generated card_number (CAF-CARD-XXXXXXXX); QR code generated via
        SimpleSoftwareIO/simple-qrcode

  deductBalance(MealCard $card, float $amount, string $refType, int $refId): MealCardTransaction
    └── 9-step atomic deduction (see pseudocode below)

  creditBalance(MealCard $card, float $amount, string $paymentMode,
                ?string $razorpayPaymentId = null): MealCardTransaction
    └── DB::transaction(); INSERT Credit transaction; UPDATE balance + total_credited;
        If razorpayPaymentId: idempotency check (UNIQUE constraint on insert) (BR-CAF-011)

  refundBalance(MealCard $card, float $amount, int $orderId): MealCardTransaction
    └── DB::transaction(); INSERT Refund transaction; UPDATE balance + total_credited

  initiateRazorpayTopup(MealCard $card, float $amount): array
    └── Creates Razorpay order; returns redirect URL + payment_id

  verifyRazorpayWebhook(array $payload, string $signature): bool
    └── HMAC-SHA256 signature verification using Razorpay webhook secret

  generateCardPdf(MealCard $card): string
    └── DomPDF card statement with paginated transaction history; balance_after column

  generateQrCode(MealCard $card): string
    └── SimpleSoftwareIO/simple-qrcode; returns SVG/PNG for printing
```

**MealCardService::deductBalance() — 9-step pseudocode:**
```
deductBalance(MealCard $card, float $amount, string $referenceType, int $referenceId): MealCardTransaction
  Step 1: DB::transaction() begins
  Step 2: SELECT...FOR UPDATE on caf_meal_cards WHERE id=$card->id
          (Prevents concurrent double-spend — BR-CAF-012)
  Step 3: If caf_allow_negative_balance=false AND (current_balance − amount) < 0:
            throw InsufficientBalanceException (BR-CAF-003)
  Step 4: Compute new_balance = current_balance − amount
  Step 5: UPDATE caf_meal_cards SET current_balance=new_balance, total_debited += amount
  Step 6: INSERT caf_meal_card_transactions (
            transaction_type='Debit', amount, balance_after=new_balance,
            reference_type, reference_id
          )
  Step 7: DB::transaction() commits
  Step 8: If new_balance < caf_low_balance_threshold (default ₹100):
            dispatch LowBalanceNotificationJob (queued — does NOT block response) (BR-CAF-017)
  Step 9: Return MealCardTransaction
```

---

### 4. PosService
**File:** `app/Services/PosService.php`
**Depends on:** `MealCardService`
**Fires:** *(no events — dietary conflict alert shown inline)*

```
Key Methods:

  openSession(array $data, User $staff): PosSession
    └── Checks no other open session for this staff on session_date;
        Creates caf_pos_sessions (closed_at = NULL)

  closeSession(PosSession $session, User $staff): void
    └── Sets closed_at = now(); reconciles total_cash_collected + total_card_debited
        from linked caf_pos_transactions

  processTransaction(PosSession $session, array $transactionData): PosTransaction
    └── BR-CAF-013: session.closed_at IS NULL check;
        If payment_mode = MealCard: MealCardService::deductBalance();
        Snapshot items_json + dietary_flags_json at transaction time;
        Updates session running totals

  lookupStudent(string $qrOrId): array
    └── Returns student + dietary profile + current meal card balance
        dietary_flags_json snapshot for dietary conflict alert

  getDietaryAlert(Student $student, array $itemIds): array
    └── Returns array of dietary conflict messages for POS display (BR-CAF-002)

  getSessionSummary(PosSession $session): array
    └── Aggregates transactions; returns reconciliation totals
```

---

### 5. StockService
**File:** `app/Services/StockService.php`
**Depends on:** *(INV module interface, injected optionally)*
**Fires:** `StockReorderAlertJob` (queued)

```
Key Methods:

  logConsumption(array $data): ConsumptionLog
    └── INSERT caf_consumption_logs;
        UPDATE caf_stock_items.current_quantity -= quantity_used;
        Calls checkReorderLevel() after update

  checkReorderLevel(StockItem $item): bool
    └── If current_quantity ≤ reorder_level:
          dispatch StockReorderAlertJob (BR-CAF-007);
          If caf_inv_integration=true: createInvPurchaseRequisition()
        Returns true if reorder triggered

  createInvPurchaseRequisition(StockItem $item): void
    └── Attempts INSERT inv_purchase_requisitions; wraps in try-catch;
        Graceful degradation: logs warning if INV module not available (BR-CAF-007)

  checkFssaiExpiry(): void
    └── Called by caf:send-fssai-alerts Artisan command;
        Supplier: alerts at 30d + 7d; School: alerts at 60d + 30d (BR-CAF-014)

  checkStockReorders(): int
    └── Called by caf:check-stock-reorder Artisan;
        Iterates all active stock items; dispatches alerts where needed; returns count
```

---

### 6. ReportService
**File:** `app/Services/ReportService.php`
**Depends on:** *(all caf_* models; DomPDF; no other services)*
**Fires:** *(none)*

```
Key Methods:

  getRevenueReport(array $filters): array
    └── Aggregates caf_orders (MealCard + Cash) + caf_pos_transactions by date range;
        Chunked queries for large ranges

  getOrderSummary(array $filters): array
    └── Per-student, per-class order counts + spend; dietary breakdown

  getWastageReport(Carbon $date, int $mealCategoryId): array
    └── Planned headcount (orders + subscriptions) vs actual (caf_meal_attendance count);
        Waste estimate = (planned - actual) × avg_item_cost

  getMealCardStatement(MealCard $card, ?Carbon $from, ?Carbon $to): array
    └── Paginated caf_meal_card_transactions with balance_after column

  exportCsv(string $reportType, array $filters): StreamedResponse
    └── Uses fputcsv to php://temp stream; no external package

  exportPdf(string $reportType, array $data): Response
    └── DomPDF render; returns file download response

  getFssaiAuditLogPdf(): Response
    └── DomPDF FSSAI audit history with compliance scores
```

---

## Section 9 — Integration Contracts

| Integration | Triggered By | Target Module | Payload / Action |
|-------------|-------------|--------------|-----------------|
| `MenuPublished` | `MenuService::publishMenu()` on daily menu or event meal publish | NTF (Notification) | Push/SMS to all active students and parents: menu_date, week_start_date, item count |
| `LowBalanceAlert` | `MealCardService::deductBalance()` when new_balance < `caf_low_balance_threshold` | NTF (queued job) | Push/SMS to parent: student name, current_balance, card_number last 4 |
| `StockReorderAlert` | `StockService::checkReorderLevel()` when current_quantity ≤ reorder_level | NTF (queued) → CAFETERIA_MGR in-app | Stock item name, current_quantity, reorder_level, reorder_quantity |
| `FssaiExpiryAlert` | `caf:send-fssai-alerts` Artisan (daily) | NTF → Admin + CafMgr | Entity name (supplier or school), expiry_date, days remaining |
| `HostelAdmission (HST bridge)` | `HostelAdmissionListener` (listens to HST module event) | CAF (inbound) | When `caf_hostel_auto_enroll=true`: auto-enrolls student in hostel mess plan; deducts plan fee from meal card via MealCardService::deductBalance() |
| `StaffMealPayrollFlag` | CAF sets `payroll_deduction_flag=1` in `caf_staff_meal_logs` | PAY (read-only signal) | PAY module reads this flag; CAF **never** writes to `pay_*` tables |
| **Direct service call:** `MealCardService::deductBalance()` | `OrderService::placeOrder()` / `PosService::processTransaction()` | Internal (same module) | Atomic balance deduction — SELECT...FOR UPDATE + DB transaction |

**`MealCardService::deductBalance()` payload:**
```php
deductBalance(
  MealCard   $card,           // row-locked via SELECT...FOR UPDATE
  float      $amount,         // amount to deduct
  string     $referenceType,  // 'Order' | 'POS' | 'TopUp' | 'Refund' | 'Adjustment'
  int        $referenceId     // PK of the referencing record
): MealCardTransaction
// Returns: inserted transaction row with balance_after snapshot
```

**`MenuPublished` payload (Laravel Notification):**
```php
// via NTF module dispatcher
[
  'type'           => 'MenuPublished',
  'menu_date'      => '2026-04-01',
  'week_start'     => '2026-03-30',
  'items_count'    => 12,
  'channels'       => ['push', 'sms'],
  'audience'       => 'all_active_students_and_parents',
]
```

---

## Section 10 — Non-Functional Requirements

| NFR | Requirement | Implementation Note |
|-----|-------------|---------------------|
| Kitchen view performance | < 2s for 500+ orders | Composite index `(order_date, meal_category_id, status)` on `caf_orders`; eager-load order items; subscription headcount counted in same query batch; no N+1 |
| Balance deduction concurrency | No double-spend under concurrent requests | `SELECT...FOR UPDATE` row-lock on `caf_meal_cards` inside `DB::transaction()` — single row lock prevents race condition |
| Razorpay webhook idempotency | Duplicate webhook must not double-credit | `razorpay_payment_id UNIQUE NULL` constraint + application-level `exists()` check before insert; returns 200 idempotently |
| QR attendance scan idempotency | Duplicate scan returns 200 gracefully | `UNIQUE(student_id, meal_date, meal_category_id)` — `upsert()` or catch DuplicateEntry; return existing record |
| PDF generation | Kitchen sheet, card statement, FSSAI log | `barryvdh/laravel-dompdf` (already in project); chunked data for large statements |
| QR code generation | Meal card QR for student scanning | `SimpleSoftwareIO/simple-qrcode` package; SVG/PNG output for printing and portal display |
| Queue / async | Menu publish notification, low-balance alert, reorder alert | Laravel Queue (database driver default); notifications dispatched as queued jobs — do NOT block HTTP response |
| Security — data isolation | Students see only their own orders + balance; parents see only their child | Policy-based authorization; all queries filtered by authenticated student/parent FK; dietary profile read-only for kitchen |
| Bulk order performance | 500 subscribed students kitchen headcount | Aggregate query on `caf_subscription_enrollments`; single COUNT GROUP BY rather than N+1 loop |
| No `tenant_id` | Isolation via stancl/tenancy v3.9 dedicated DB | No `tenant_id` column on any `caf_*` table |

---

## Section 11 — Test Plan Outline

### Feature Tests (Pest) — 20 test files

| File | Key Scenarios |
|------|--------------|
| `MenuCategoryCrudTest` | Create category; edit; toggle is_active; soft-delete; restore; invalid meal_time rejected |
| `MenuItemCrudTest` | Create item with food_type=Jain; toggle availability (AJAX response); price validation |
| `WeeklyMenuPublishTest` | Publish menu → `MenuPublished` notification dispatched (`Notification::fake()`); portal shows published menu; status persisted |
| `MenuPublishBlockedTest` | Publish blocked when no items assigned to daily_menu_id (BR-CAF-005); 422 returned |
| `OrderPlacementTest` | Place order; verify MealCard balance atomically deducted; `caf_order_items.unit_price` snapshot; status = Confirmed |
| `OrderCutoffTest` | Order rejected when past cutoff window (BR-CAF-001); allowed 1 min before cutoff |
| `DietaryConflictWarningTest` | Jain student ordering Non_Veg shows warning; admin can override; student gets 422 (BR-CAF-002) |
| `NutAllergyConflictTest` | Nut-allergy flag displayed on POS scan for matching student; dietary_flags_json snapshot saved |
| `MealCardTopUpCashTest` | Admin cash top-up; balance updated; `caf_meal_card_transactions` Credit record with balance_after |
| `RazorpayWebhookTest` | Valid webhook → balance credited + transaction created; duplicate `razorpay_payment_id` → 200 idempotent (no double-credit) (BR-CAF-011) |
| `MealCardNegativeBalanceTest` | Order rejected when balance < total in prepaid-only mode (`caf_allow_negative_balance=false`) (BR-CAF-003) |
| `OrderCancellationRefundTest` | Cancel before cutoff; balance refunded; status = Cancelled; cancellation after cutoff rejected (BR-CAF-008) |
| `KitchenConsolidationTest` | Aggregate orders for date+meal; correct per-item totals; dietary counts; subscription enrolled students counted in headcount (BR-CAF-010) |
| `SubscriptionEnrollmentTest` | Enroll student in plan; appears in kitchen headcount without explicit order; staff_id + student_id mutually exclusive |
| `StockReorderAlertTest` | Consumption log reduces qty to ≤ reorder_level; `StockReorderAlertJob` dispatched (`Queue::fake()`); INV bridge attempted when `caf_inv_integration=true` |
| `PosSessionTest` | Open session; transact MealCard; transact Cash; close session; totals reconcile; transaction outside open session rejected (BR-CAF-013) |
| `QrAttendanceScanTest` | QR scan records attendance; duplicate scan returns 200 with existing record (no duplicate) |
| `EventMealPublishTest` | Event meal published for specific class group; students in other classes cannot order |
| `FssaiExpiryAlertTest` | Mock scheduler fires `caf:send-fssai-alerts`; alert dispatched at 30d; at 7d for supplier; `Bus::fake()` for Artisan |
| `StaffMealLogTest` | Staff meal logged; `payroll_deduction_flag=1` set; revenue dashboard separates staff revenue; no writes to pay_* |

### Unit Tests (PHPUnit) — 2 test files

| File | Key Scenarios |
|------|--------------|
| `MealCardTransactionLedgerTest` | balance_after on each transaction = prior_balance ± amount (ledger integrity); Credit increases balance; Debit decreases; Refund increases; Adjustment can do either |
| `OrderNumberFormatTest` | Order number matches regex `CAF-\d{4}-[A-Z0-9]{8}` (year + 8 random alphanumeric) |

### Test Data Requirements
- **Seeder for test isolation:** `CafMenuCategorySeeder` — seeds 5 meal categories; required by almost every test (meal_category_id FK)
- **Factories required:**
  - `MenuCategoryFactory` — meal_time, display_order; prefer seeded set
  - `MenuItemFactory` — food_type, price, is_available=1, category_id
  - `DailyMenuFactory` — future menu_date, status=Draft
  - `MealCardFactory` — card_number (CAF-CARD-XXXXXXXX), current_balance=500.00, linked student
  - `OrderFactory` — order_number (CAF-YYYY-XXXXXXXX), status=Confirmed, student + card + meal_category
  - `StudentFactory` — reference from STD module factories

### Mock Strategy
- `Notification::fake()` — WeeklyMenuPublishTest (MenuPublished), FssaiExpiryAlertTest
- `Queue::fake()` — LowBalanceNotificationJob (MealCardNegativeBalanceTest), StockReorderAlertJob (StockReorderAlertTest)
- `Event::fake()` — where applicable
- `Bus::fake()` — Artisan command tests (caf:archive-old-menus, caf:send-fssai-alerts, caf:check-stock-reorder)
- **Razorpay webhook:** test with known HMAC-SHA256 signature; duplicate `payment_id` must return 200 idempotent
- **`SELECT...FOR UPDATE` concurrency:** must use real tenant DB (cannot be mocked with SQLite in-memory); use `RefreshDatabase` with actual MySQL
