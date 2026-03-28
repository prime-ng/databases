# CAF — Cafeteria Module Table Summary
**Module:** CAF (Cafeteria & Mess Management) | **Version:** 1.0 | **Date:** 2026-03-27
**Tables:** 21 (`caf_*`) | **Database:** `tenant_db` (no `tenant_id` — stancl/tenancy v3.9)

---

## 1. Table Inventory (21 Tables)

| # | Table | Domain | Layer | One-Line Description |
|---|-------|--------|-------|----------------------|
| 1 | `caf_menu_categories` | Menu Planning | L1 | Meal-type category master (Breakfast, Lunch, Snacks, Dinner, Tuck Shop) with time and display order |
| 2 | `caf_suppliers` | Stock & Suppliers | L1 | Food/material supplier register with FSSAI license number and expiry tracking |
| 3 | `caf_fssai_records` | Compliance & Staff | L1 | FSSAI school license and hygiene audit log with expiry alerts |
| 4 | `caf_daily_menus` | Menu Planning | L1 | Daily menu header — one record per calendar date (Draft→Published→Archived) |
| 5 | `caf_subscription_plans` | Dietary & Subscriptions | L1 | Fixed meal plan definitions (Monthly/Termly/Annual) with category inclusions |
| 6 | `caf_meal_cards` | Meal Cards & POS | L1 | Student prepaid wallet — one card per student; balance updated atomically |
| 7 | `caf_pos_sessions` | Meal Cards & POS | L1 | POS shift sessions opened and closed by kitchen staff |
| 8 | `caf_dietary_profiles` | Dietary & Subscriptions | L1 | Per-student dietary preference and restriction flags (one profile per student) |
| 9 | `caf_menu_items` | Menu Planning | L2 | Dish library with nutritional macros, food type, allergen notes, and dish photo |
| 10 | `caf_stock_items` | Stock & Suppliers | L2 | Raw material inventory with reorder threshold and INV bridge support |
| 11 | `caf_event_meals` | Menu Planning | L2 | Special/festival meal headers with optional class-group targeting |
| 12 | `caf_subscription_enrollments` | Dietary & Subscriptions | L2 | Student/staff × plan enrollment records |
| 13 | `caf_meal_card_transactions` | Meal Cards & POS | L2 | Credit/Debit/Refund/Adjustment ledger with balance snapshot; Razorpay idempotency |
| 14 | `caf_meal_attendance` | Orders & Attendance | L2 | QR/biometric scan records — idempotent per student per meal per day |
| 15 | `caf_pos_transactions` | Meal Cards & POS | L2 | Individual POS counter sales with items_json snapshot |
| 16 | `caf_staff_meal_logs` | Compliance & Staff | L2 | Staff meal tracking with `payroll_deduction_flag` signal for PAY module |
| 17 | `caf_orders` | Orders & Attendance | L2 | Meal pre-order headers — student orders before cutoff |
| 18 | `caf_daily_menu_items_jnt` | Menu Planning | L3 | Day × meal-category × dish assignments (_jnt junction) |
| 19 | `caf_event_meal_items_jnt` | Menu Planning | L3 | Event meal × dish assignments — `menu_item_id` nullable for free-text items (_jnt junction) |
| 20 | `caf_consumption_logs` | Stock & Suppliers | L3 | Daily raw material consumption log — deducted from `caf_stock_items.current_quantity` |
| 21 | `caf_order_items` | Orders & Attendance | L4 | Pre-order line items with `unit_price` snapshot at order time |

---

## 2. Dependency Layers

```
LAYER 1 (8 tables) — No caf_* dependencies
  caf_menu_categories       (standalone master)
  caf_suppliers             (standalone master)
  caf_fssai_records         → sys_media (nullable)
  caf_daily_menus           → sch_academic_term (nullable), sys_users
  caf_subscription_plans    → sch_academic_term (nullable)
  caf_meal_cards            → std_students (UNIQUE), sys_users
  caf_pos_sessions          → sys_users
  caf_dietary_profiles      → std_students (UNIQUE), sys_users

LAYER 2 (9 tables) — Depends on Layer 1
  caf_menu_items            → caf_menu_categories, sys_media (nullable)
  caf_stock_items           → caf_suppliers (nullable)
  caf_event_meals           → caf_menu_categories
  caf_subscription_enrollments → caf_subscription_plans, caf_meal_cards (nullable)
  caf_meal_card_transactions → caf_meal_cards
  caf_meal_attendance       → caf_menu_categories, std_students
  caf_pos_transactions      → caf_pos_sessions, caf_meal_cards (nullable)
  caf_staff_meal_logs       → caf_menu_categories
  caf_orders                → caf_meal_cards (nullable), caf_menu_categories, std_students

LAYER 3 (3 tables) — Depends on Layer 2
  caf_daily_menu_items_jnt  → caf_daily_menus, caf_menu_items, caf_menu_categories
  caf_event_meal_items_jnt  → caf_event_meals, caf_menu_items (nullable)
  caf_consumption_logs      → caf_stock_items, caf_menu_categories (nullable)

LAYER 4 (1 table) — Depends on Layer 3
  caf_order_items           → caf_orders, caf_menu_items
```

---

## 3. Audit Column Matrix

> `id` and standard PKs are omitted (present on all 21 tables).

| Table | `is_active` | `created_by` | `created_at` | `updated_at` | `deleted_at` | Notes |
|-------|:-----------:|:------------:|:------------:|:------------:|:------------:|-------|
| caf_menu_categories | ✓ | ✓ | ✓ | ✓ | ✓ | Full soft-delete |
| caf_suppliers | ✓ | ✓ | ✓ | ✓ | ✓ | Full soft-delete |
| caf_fssai_records | ✓ | ✓ | ✓ | ✓ | — | Compliance record; no delete |
| caf_daily_menus | ✓ | ✓ | ✓ | ✓ | ✓ | Full soft-delete |
| caf_subscription_plans | ✓ | ✓ | ✓ | ✓ | ✓ | Full soft-delete |
| caf_meal_cards | ✓ | ✓ | ✓ | ✓ | ✓ | Full soft-delete |
| caf_pos_sessions | ✓ | — | ✓ | ✓ | — | `opened_by` serves as creator |
| caf_dietary_profiles | ✓ | ✓ | ✓ | ✓ | ✓ | Full soft-delete |
| caf_menu_items | ✓ | ✓ | ✓ | ✓ | ✓ | Full soft-delete |
| caf_stock_items | ✓ | ✓ | ✓ | ✓ | ✓ | Full soft-delete |
| caf_event_meals | ✓ | ✓ | ✓ | ✓ | ✓ | Full soft-delete |
| caf_subscription_enrollments | ✓ | ✓ | ✓ | ✓ | ✓ | Full soft-delete |
| caf_meal_card_transactions | — | ✓ | ✓ | ✓ | — | Financial ledger; immutable |
| caf_meal_attendance | — | — | ✓ | — | — | Immutable scan; `scanned_by` is user ref |
| caf_pos_transactions | — | ✓ | ✓ | ✓ | — | Transactional; immutable after save |
| caf_staff_meal_logs | — | ✓ | ✓ | ✓ | — | Transactional log |
| caf_orders | ✓ | ✓ | ✓ | ✓ | ✓ | Full soft-delete |
| caf_daily_menu_items_jnt | ✓ | ✓ | ✓ | ✓ | — | Junction; no soft-delete |
| caf_event_meal_items_jnt | ✓ | ✓ | ✓ | ✓ | — | Junction; no soft-delete |
| caf_consumption_logs | — | ✓ | ✓ | ✓ | — | Usage log; no soft-delete |
| caf_order_items | — | — | ✓ | ✓ | — | Transactional line item |

**Totals:**
- Tables with `deleted_at` (soft-delete): **11** (menu_categories, suppliers, daily_menus, subscription_plans, meal_cards, dietary_profiles, menu_items, stock_items, event_meals, subscription_enrollments, orders)
- Tables WITHOUT `deleted_at`: **10** (fssai_records, pos_sessions, meal_card_transactions, meal_attendance, pos_transactions, staff_meal_logs, daily_menu_items_jnt, event_meal_items_jnt, consumption_logs, order_items)

---

## 4. Cross-Module FK Summary

> **CRITICAL TYPE CORRECTION**: The requirement doc states `sys_users` refs = `BIGINT UNSIGNED`.
> Verified against `tenant_db_v2.sql`: `sys_users.id = INT UNSIGNED`. All cross-module refs corrected.

| Column Pattern | Referenced Table | Type Used | Table(s) |
|----------------|-----------------|-----------|----------|
| `student_id` | `std_students.id` | `INT UNSIGNED` | caf_dietary_profiles, caf_meal_cards, caf_subscription_enrollments, caf_meal_card_transactions, caf_meal_attendance, caf_pos_transactions, caf_orders |
| `academic_term_id` | `sch_academic_term.id` *(singular)* | `SMALLINT UNSIGNED` | caf_daily_menus, caf_subscription_plans |
| `photo_media_id` | `sys_media.id` | `INT UNSIGNED NULL` | caf_menu_items |
| `fssai_document_media_id` | `sys_media.id` | `INT UNSIGNED NULL` | caf_fssai_records |
| `created_by` | `sys_users.id` | `INT UNSIGNED NULL` | All 19 tables that have it |
| `published_by` | `sys_users.id` | `INT UNSIGNED NULL` | caf_daily_menus |
| `opened_by` | `sys_users.id` | `INT UNSIGNED NOT NULL` | caf_pos_sessions |
| `scanned_by` | `sys_users.id` | `INT UNSIGNED NULL` | caf_meal_attendance |
| `staff_id` | `sys_users.id` | `INT UNSIGNED NULL` | caf_subscription_enrollments, caf_pos_transactions, caf_staff_meal_logs |

**No FK constraints to cross-module tables** — only KEY indexes. FK constraints are defined only for intra-module (caf_* → caf_*) references to avoid tight coupling during migrations.

---

## 5. Critical UNIQUE Constraints

| Table | Unique Key Name | Columns | Purpose |
|-------|----------------|---------|---------|
| `caf_menu_categories` | `uq_caf_mc_code` | `(code)` | Nullable unique — multiple NULLs allowed |
| `caf_daily_menus` | `uq_caf_dm_menu_date` | `(menu_date)` | One menu per calendar date (BR-CAF-018) |
| `caf_meal_cards` | `uq_caf_mcard_student` | `(student_id)` | One active card per student (BR-CAF-004) |
| `caf_meal_cards` | `uq_caf_mcard_number` | `(card_number)` | Card number globally unique within tenant |
| `caf_meal_card_transactions` | `uq_caf_mct_razorpay` | `(razorpay_payment_id)` | Razorpay webhook idempotency (BR-CAF-011) |
| `caf_dietary_profiles` | `uq_caf_dp_student` | `(student_id)` | One dietary profile per student |
| `caf_meal_attendance` | `uq_caf_ma` | `(student_id, meal_date, meal_category_id)` | Idempotent QR scan — duplicate returns 200 |
| `caf_daily_menu_items_jnt` | `uq_caf_dmij` | `(daily_menu_id, menu_item_id, meal_category_id)` | No duplicate dish assignments per day/meal |
| `caf_order_items` | `uq_caf_oi_order_item` | `(order_id, menu_item_id)` | No duplicate dishes in same order |
| `caf_orders` | `uq_caf_orders_number` | `(order_number)` | Order number globally unique |

---

## 6. ENUM Reference

| Table | Column | ENUM Values |
|-------|--------|-------------|
| `caf_menu_categories` | `meal_time` | `'Breakfast','Lunch','Snacks','Dinner','Tuck_Shop'` |
| `caf_menu_items` | `food_type` | `'Veg','Non_Veg','Egg','Jain'` |
| `caf_daily_menus` | `status` | `'Draft','Published','Archived'` |
| `caf_event_meals` | `status` | `'Draft','Published','Archived'` |
| `caf_dietary_profiles` | `food_preference` | `'Veg','Non_Veg','Egg','Jain'` |
| `caf_subscription_plans` | `billing_period` | `'Monthly','Termly','Annual'` |
| `caf_subscription_enrollments` | `status` | `'Active','Paused','Cancelled','Expired'` |
| `caf_orders` | `payment_mode` | `'MealCard','Cash','Counter','Subscription'` |
| `caf_orders` | `status` | `'Pending','Confirmed','Served','Cancelled'` |
| `caf_meal_attendance` | `scan_method` | `'QR','Biometric','Manual'` |
| `caf_pos_transactions` | `payment_mode` | `'MealCard','Cash'` |
| `caf_meal_card_transactions` | `transaction_type` | `'Credit','Debit','Refund','Adjustment'` |
| `caf_meal_card_transactions` | `payment_mode` | `'Online','Cash','Wallet','Free'` |
| `caf_stock_items` | `category` | `'Grains','Pulses','Vegetables','Fruits','Dairy','Spices','Beverages','Condiments','Cleaning','Other'` |
| `caf_fssai_records` | `record_type` | `'License','Audit'` |
| `caf_fssai_records` | `license_type` | `'Basic','State','Central'` |
| `caf_staff_meal_logs` | `payment_mode` | `'Subscription','Cash','CardDeduction'` |

---

## 7. Notable Column Details

| Table | Column | Type | Special Note |
|-------|--------|------|-------------|
| `caf_meal_cards` | `current_balance` | `DECIMAL(10,2) DEFAULT 0.00` | Updated atomically via `SELECT...FOR UPDATE` (BR-CAF-012) |
| `caf_meal_cards` | `total_credited` / `total_debited` | `DECIMAL(10,2) DEFAULT 0.00` | Running totals for ledger integrity |
| `caf_meal_card_transactions` | `balance_after` | `DECIMAL(10,2) NOT NULL` | Snapshot after transaction — critical for ledger audit |
| `caf_meal_card_transactions` | `razorpay_payment_id` | `VARCHAR(100) NULL UNIQUE` | MySQL nullable UNIQUE allows multiple NULLs; unique for non-null |
| `caf_order_items` | `unit_price` | `DECIMAL(8,2) NOT NULL` | Price snapshot at order time; never re-read from `caf_menu_items.price` |
| `caf_order_items` | `line_total` | `DECIMAL(10,2) NOT NULL` | `quantity × unit_price` — populated at insert (not GENERATED) |
| `caf_pos_transactions` | `items_json` | `JSON NOT NULL` | Immutable snapshot `[{menu_item_id, name, qty, price}]` |
| `caf_event_meal_items_jnt` | `menu_item_id` | `INT UNSIGNED NULL` | Nullable — free-text festival items allowed |
| `caf_subscription_enrollments` | `student_id` / `staff_id` | Both nullable | Mutually exclusive — either student or staff enrollment |
| `caf_staff_meal_logs` | `payroll_deduction_flag` | `TINYINT(1) DEFAULT 0` | Read-only signal for PAY module; CAF never writes to `pay_*` |
| `caf_subscription_plans` | `is_hostel_plan` | `TINYINT(1) DEFAULT 0` | HST bridge flag — auto-enroll on hostel admission |
| `caf_event_meals` | `target_class_ids_json` | `JSON NULL` | `NULL` = applies to all students (BR-CAF-016) |

---

## 8. FK Constraint Summary (Intra-Module Only)

| Constraint Name | Child Table | Column | Parent Table | On Delete |
|----------------|------------|--------|-------------|-----------|
| `fk_caf_mi_category_id` | caf_menu_items | category_id | caf_menu_categories | RESTRICT |
| `fk_caf_si_supplier_id` | caf_stock_items | supplier_id | caf_suppliers | SET NULL |
| `fk_caf_em_meal_category_id` | caf_event_meals | meal_category_id | caf_menu_categories | RESTRICT |
| `fk_caf_se_plan_id` | caf_subscription_enrollments | subscription_plan_id | caf_subscription_plans | RESTRICT |
| `fk_caf_se_meal_card_id` | caf_subscription_enrollments | meal_card_id | caf_meal_cards | SET NULL |
| `fk_caf_mct_meal_card_id` | caf_meal_card_transactions | meal_card_id | caf_meal_cards | RESTRICT |
| `fk_caf_ma_meal_category_id` | caf_meal_attendance | meal_category_id | caf_menu_categories | RESTRICT |
| `fk_caf_pt_session_id` | caf_pos_transactions | pos_session_id | caf_pos_sessions | RESTRICT |
| `fk_caf_pt_meal_card_id` | caf_pos_transactions | meal_card_id | caf_meal_cards | SET NULL |
| `fk_caf_sml_meal_category_id` | caf_staff_meal_logs | meal_category_id | caf_menu_categories | RESTRICT |
| `fk_caf_ord_meal_card_id` | caf_orders | meal_card_id | caf_meal_cards | SET NULL |
| `fk_caf_ord_meal_category_id` | caf_orders | meal_category_id | caf_menu_categories | RESTRICT |
| `fk_caf_dmij_daily_menu_id` | caf_daily_menu_items_jnt | daily_menu_id | caf_daily_menus | CASCADE |
| `fk_caf_dmij_menu_item_id` | caf_daily_menu_items_jnt | menu_item_id | caf_menu_items | CASCADE |
| `fk_caf_dmij_meal_category_id` | caf_daily_menu_items_jnt | meal_category_id | caf_menu_categories | RESTRICT |
| `fk_caf_emij_event_meal_id` | caf_event_meal_items_jnt | event_meal_id | caf_event_meals | CASCADE |
| `fk_caf_emij_menu_item_id` | caf_event_meal_items_jnt | menu_item_id | caf_menu_items | SET NULL |
| `fk_caf_cl_stock_item_id` | caf_consumption_logs | stock_item_id | caf_stock_items | RESTRICT |
| `fk_caf_cl_meal_category_id` | caf_consumption_logs | meal_category_id | caf_menu_categories | SET NULL |
| `fk_caf_oi_order_id` | caf_order_items | order_id | caf_orders | CASCADE |
| `fk_caf_oi_menu_item_id` | caf_order_items | menu_item_id | caf_menu_items | RESTRICT |

**Total intra-module FK constraints: 21**

---

## 9. Composite Index Summary

| Table | Index Name | Columns | Purpose |
|-------|-----------|---------|---------|
| `caf_meal_card_transactions` | `idx_caf_mct_card_created` | `(meal_card_id, created_at)` | Card statement queries ordered by date |
| `caf_meal_attendance` | `uq_caf_ma` *(unique)* | `(student_id, meal_date, meal_category_id)` | Idempotent QR scan lookup |
| `caf_orders` | `idx_caf_ord_student_date` | `(student_id, order_date)` | Student order history by date |
| `caf_orders` | `idx_caf_ord_date_cat_status` | `(order_date, meal_category_id, status)` | Kitchen view: 500+ orders < 2s (NFR) |
| `caf_consumption_logs` | `idx_caf_cl_item_date` | `(stock_item_id, log_date)` | Stock usage history per item per date |
| `caf_daily_menu_items_jnt` | `uq_caf_dmij` *(unique)* | `(daily_menu_id, menu_item_id, meal_category_id)` | Prevent duplicate dish assignments |

---

## 10. Artisan Commands

| Command | Schedule | Purpose |
|---------|----------|---------|
| `caf:archive-old-menus` | Daily | Archive `Published` menus older than 7 days |
| `caf:send-fssai-alerts` | Daily | Check supplier (30+7 day) and school (60+30 day) FSSAI expiry |
| `caf:check-stock-reorder` | Every 6 hours | Check stock levels; dispatch alerts; optional INV bridge |

*(Low-balance notification is triggered per-transaction by `MealCardService::deductBalance()` — not a scheduled command)*
