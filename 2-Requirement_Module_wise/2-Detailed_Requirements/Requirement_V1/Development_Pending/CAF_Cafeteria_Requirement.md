# Cafeteria Module — Requirement Specification Document

**Version:** 1.0 | **Date:** 2026-03-25 | **Author:** Claude Code (Greenfield RBS-Only)
**Platform:** Prime-AI Academic Intelligence Platform
**Module Code:** CAF | **Module Path:** `Modules/Cafeteria`
**Module Type:** Tenant | **Database:** tenant_db
**Table Prefix:** `caf_*` | **Processing Mode:** RBS_ONLY (Greenfield)
**RBS Reference:** Module W — Cafeteria & Mess Management (lines 4280–4312)

> **GREENFIELD MODULE** — No code, no DDL, no tests exist. All features are 📐 Proposed. This document defines the complete functional specification to guide development from scratch.

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Module Overview](#2-module-overview)
3. [Stakeholders & Actors](#3-stakeholders--actors)
4. [Functional Requirements](#4-functional-requirements)
5. [Data Model](#5-data-model)
6. [Controller & Route Inventory](#6-controller--route-inventory)
7. [Form Request Validation Rules](#7-form-request-validation-rules)
8. [Business Rules](#8-business-rules)
9. [Permission & Authorization Model](#9-permission--authorization-model)
10. [Tests Inventory](#10-tests-inventory)
11. [Known Issues & Technical Debt](#11-known-issues--technical-debt)
12. [API Endpoints](#12-api-endpoints)
13. [Non-Functional Requirements](#13-non-functional-requirements)
14. [Integration Points](#14-integration-points)
15. [Pending Work & Gap Analysis](#15-pending-work--gap-analysis)

---

## 1. Executive Summary

### 1.1 Purpose

The Cafeteria module provides complete canteen and mess management for Indian K-12 schools on the Prime-AI platform. It covers digital menu planning, online meal pre-booking by students and parents, meal card (pre-paid wallet) management, dietary profile tracking (vegetarian/non-veg/Jain/allergy), kitchen headcount for preparation, and kitchen stock/inventory management with automatic reorder alerts.

### 1.2 Scope

This module covers:
- Menu category and menu item master management with nutritional and allergen information
- Weekly digital menu planning (Breakfast, Lunch, Snacks) with publish-and-notify workflow
- Online meal pre-ordering by students/parents through the portal with order cutoff enforcement
- Meal card (prepaid canteen wallet) issuance, top-up, and transaction ledger
- Dietary profile management per student (veg/non-veg/Jain/custom restrictions)
- Kitchen stock management: raw material register, reorder levels, purchase request generation
- Consumption tracking against planned meals and food-cost/wastage reports
- Hostel mess linkage (hostel students billed via mess plan)
- Revenue dashboard and reports

Out of scope for this version: POS hardware integration (physical terminal), integration with third-party food aggregators, allergen certification compliance reports.

### 1.3 Module Statistics

| Metric | Count |
|---|---|
| RBS Features (F.W*) | 3 (F.W1.1, F.W2.1, F.W3.1) |
| RBS Tasks | 6 (T.W1.1.1–T.W3.1.2) |
| RBS Sub-tasks | 12 (ST.W1.1.1.1–ST.W3.1.2.2) |
| Proposed DB Tables (caf_*) | 10 |
| Proposed Named Routes | ~52 |
| Proposed Blade Views | ~28 |
| Proposed Controllers | 8 |
| Proposed Models | 10 |
| Proposed Services | 3 |
| Proposed FormRequests | 8 |
| Proposed Policies | 8 |

### 1.4 Implementation Status

| Layer | Status | Notes |
|---|---|---|
| DB Schema / Migrations | ❌ Not Started | 10 tables to be created |
| Models | ❌ Not Started | 10 models |
| Controllers | ❌ Not Started | 8 controllers |
| Services | ❌ Not Started | MenuService, OrderService, StockService |
| Views | ❌ Not Started | ~28 blade views |
| Routes | ❌ Not Started | ~52 named routes |
| Tests | ❌ Not Started | Feature + Unit tests |

**Overall Implementation: 0%** (Greenfield)

---

## 2. Module Overview

### 2.1 Business Purpose

Indian schools — particularly those with boarding sections or large day-scholar populations — require structured canteen management. Without a digital system, menu planning is informal, food waste is high, stock management is manual, and revenue tracking is absent. Parents have no visibility into what their child is eating, dietary restrictions are forgotten, and school staff manage orders on paper.

The Cafeteria module solves:
1. **Digital menus** — weekly plans with nutritional details published to parent/student portals
2. **Pre-ordering** — students/parents order meals in advance; kitchen knows exact headcount
3. **Meal cards** — prepaid canteen wallet reduces cash handling; parents top up online
4. **Dietary safety** — each student has a dietary profile; kitchen sees flags on every order
5. **Stock management** — raw material inventory with auto reorder; food cost tracking
6. **Revenue reports** — daily/weekly/monthly revenue, average spend per student, wastage analysis

### 2.2 Key Features Summary

| Feature Area | Description | RBS Ref | Status |
|---|---|---|---|
| Menu Category Management | Categorise dishes (Breakfast, Lunch, Snacks, Tuck Shop) | F.W1.1 | 📐 Proposed |
| Menu Item Master | Dish library with price, nutrition, allergens, veg/non-veg/Jain flag | F.W1.1 | 📐 Proposed |
| Weekly Menu Planner | Assign dishes to day + meal-type slots; publish to portal | F.W1.1, T.W1.1.1 | 📐 Proposed |
| Menu Publish & Notify | Publish weekly menu; push notification/SMS to parents | T.W1.1.2, ST.W1.1.2.1 | 📐 Proposed |
| Dietary Profile per Student | Veg/non-veg/Jain/allergy flags linked to student | F.W2.1, ST.W2.1.1.2 | 📐 Proposed |
| Meal Pre-Ordering | Student/parent books meals for upcoming days | F.W2.1, T.W2.1.1 | 📐 Proposed |
| Order Cutoff Enforcement | Ordering window closes N hours before meal (configurable) | T.W2.1.2, ST.W2.1.2.2 | 📐 Proposed |
| Kitchen Order Consolidation | Consolidated order list per day + meal type for kitchen | ST.W2.1.2.1 | 📐 Proposed |
| Meal Card (Prepaid Wallet) | Issue card, top-up via Razorpay/cash, deduct on order | Beyond RBS | 📐 Proposed |
| Kitchen Stock Management | Raw material register, reorder alerts, purchase requests | F.W3.1, T.W3.1.1 | 📐 Proposed |
| Consumption & Wastage Tracking | Log actual vs planned, food cost, wastage reports | T.W3.1.2, ST.W3.1.2.1 | 📐 Proposed |
| Hostel Mess Link | Hostel students auto-enrolled in mess plan | Beyond RBS | 📐 Proposed |
| Revenue Dashboard & Reports | Daily revenue, top dishes, wastage, student spend analytics | Beyond RBS | 📐 Proposed |

### 2.3 Menu Navigation Path

```
School Admin Panel
└── Cafeteria [/cafeteria]
    ├── Dashboard              [/cafeteria/dashboard]
    ├── Setup
    │   ├── Menu Categories    [/cafeteria/menu-categories]
    │   ├── Menu Items         [/cafeteria/menu-items]
    │   └── Dietary Profiles   [/cafeteria/dietary-profiles]
    ├── Menu Planning
    │   ├── Weekly Menu        [/cafeteria/weekly-menus]
    │   └── Daily Menu View    [/cafeteria/daily-menus/{date}]
    ├── Orders
    │   ├── All Orders         [/cafeteria/orders]
    │   └── Kitchen View       [/cafeteria/kitchen-view]
    ├── Meal Cards
    │   ├── Card Management    [/cafeteria/meal-cards]
    │   └── Transactions       [/cafeteria/meal-card-transactions]
    ├── Stock
    │   ├── Raw Materials      [/cafeteria/stock-items]
    │   └── Consumption Log    [/cafeteria/consumption-log]
    └── Reports
        ├── Revenue Report     [/cafeteria/reports/revenue]
        ├── Order Summary      [/cafeteria/reports/orders]
        └── Wastage Report     [/cafeteria/reports/wastage]
```

### 2.4 Module Architecture

```
Modules/Cafeteria/
├── app/
│   ├── Http/Controllers/
│   │   ├── CafeteriaController.php          # Dashboard + module root
│   │   ├── MenuCategoryController.php       # Category CRUD
│   │   ├── MenuItemController.php           # Item CRUD
│   │   ├── WeeklyMenuController.php         # Plan + publish workflow
│   │   ├── OrderController.php              # Pre-order management
│   │   ├── MealCardController.php           # Card issuance + top-up
│   │   ├── StockController.php              # Raw material stock
│   │   └── CafeteriaReportController.php    # Revenue/wastage reports
│   ├── Models/
│   │   ├── MenuCategory.php
│   │   ├── MenuItem.php
│   │   ├── DailyMenu.php
│   │   ├── DailyMenuItemJnt.php
│   │   ├── DietaryProfile.php
│   │   ├── MealCard.php
│   │   ├── MealCardTransaction.php
│   │   ├── Order.php
│   │   ├── OrderItem.php
│   │   └── StockItem.php
│   ├── Services/
│   │   ├── MenuService.php                  # Publish, notify, cutoff checks
│   │   ├── OrderService.php                 # Order creation, consolidation
│   │   └── StockService.php                 # Reorder alerts, purchase requests
│   ├── Policies/ (8 policies)
│   └── Providers/
├── database/migrations/ (10 migrations)
├── resources/views/cafeteria/
│   ├── dashboard.blade.php
│   ├── menu-categories/   (create, edit, index, show, trash)
│   ├── menu-items/        (create, edit, index, show, trash)
│   ├── weekly-menus/      (create, edit, index, show)
│   ├── orders/            (index, show, kitchen-view)
│   ├── meal-cards/        (create, edit, index, show, topup)
│   ├── meal-card-transactions/ (index)
│   ├── stock/             (create, edit, index, show)
│   └── reports/           (revenue, orders, wastage)
└── routes/
    ├── api.php
    └── web.php
```

---

## 3. Stakeholders & Actors

| Actor | Role in Cafeteria Module | Permissions |
|---|---|---|
| School Admin | Full access: configure menus, view orders, manage stock, reports | All permissions |
| Cafeteria Manager | Day-to-day: plan menus, view kitchen orders, manage stock | manage menus, orders, stock |
| Kitchen Staff | View kitchen consolidated orders; update consumption | view kitchen-view, update stock |
| Accounts Staff | Manage meal card top-ups, view revenue reports | manage meal-cards, view reports |
| Student | Pre-order meals via portal; view own meal card balance | order (own), view own card |
| Parent | Pre-order on behalf of child; top-up meal card; view child dietary profile | order (child), topup, view |
| Hostel Warden | View mess plan enrolment for hostel students | view hostel mess reports |
| System | Auto-enforce order cutoff, generate reorder alerts, send publish notifications | system actor |

---

## 4. Functional Requirements

---

### FR-CAF-001: Menu Category Management (F.W1.1)

**RBS Reference:** F.W1.1 — Weekly Menu Planner (configuration prerequisite)
**Priority:** 🔴 Critical
**Status:** 📐 Proposed
**Table(s):** `caf_menu_categories`

#### Requirements

**REQ-CAF-001.1: Create Menu Category**
| Attribute | Detail |
|---|---|
| Description | Admin creates menu categories (e.g., Breakfast, Lunch, Snacks, Tuck Shop, Hostel Mess) |
| Actors | School Admin, Cafeteria Manager |
| Preconditions | Authenticated with `tenant.caf-menu-category.create` permission |
| Input | name (required, max 100, unique), code (optional, unique), description, meal_time (ENUM: Breakfast/Lunch/Snacks/Dinner/Tuck_Shop), display_order (integer), is_active |
| Processing | Validate uniqueness; create record; log activity |
| Output | Redirect to category list with success flash |
| Status | 📐 Proposed |

**REQ-CAF-001.2: Edit / Toggle / Delete Category**
| Attribute | Detail |
|---|---|
| Description | Full CRUD lifecycle including soft-delete, trash, restore, force-delete (blocked if items exist) |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] ST.W1.1.1.2 — Meals can be assigned to specific meal types (Breakfast, Lunch, Snacks)
- [ ] Category cannot be force-deleted if menu items exist under it
- [ ] Display order controls sort sequence in portal menu view

---

### FR-CAF-002: Menu Item Master (F.W1.1 — ST.W1.1.1.1)

**RBS Reference:** ST.W1.1.1.1 — Add dishes with nutritional info and allergen warnings
**Priority:** 🔴 Critical
**Status:** 📐 Proposed
**Table(s):** `caf_menu_items`

#### Requirements

**REQ-CAF-002.1: Create Menu Item**
| Attribute | Detail |
|---|---|
| Description | Admin creates a dish in the menu item library with full details for portal display |
| Actors | School Admin, Cafeteria Manager |
| Preconditions | Menu category exists; `tenant.caf-menu-item.create` permission |
| Input | name (required, max 150), category_id (FK caf_menu_categories), description (text), price (decimal 8,2 required), food_type (ENUM: Veg/Non-Veg/Egg/Jain), calories (integer nullable), protein_grams (decimal), carbs_grams (decimal), fat_grams (decimal), allergen_notes (text — free-form allergen warnings), photo (optional image via sys_media), is_available, is_active |
| Processing | Validate price > 0; validate food_type; create record; upload photo to sys_media if provided |
| Output | Redirect to item list with success flash |
| Status | 📐 Proposed |

**REQ-CAF-002.2: Toggle Availability (AJAX)**
| Attribute | Detail |
|---|---|
| Description | Toggle is_available in real-time (item sold out today without removing from menu) |
| Input | `is_available` boolean |
| Output | `{ success, is_available, message }` JSON |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] ST.W1.1.1.1 — Each dish has description, nutritional info, and allergen warnings
- [ ] food_type=Jain items appear with Jain badge in portal
- [ ] Unavailable items are greyed out in portal order screen

---

### FR-CAF-003: Weekly Menu Planning (F.W1.1 — T.W1.1.1)

**RBS Reference:** T.W1.1.1 — Create Meal Plan; T.W1.1.2 — Publish & Notify
**Priority:** 🔴 Critical
**Status:** 📐 Proposed
**Table(s):** `caf_daily_menus`, `caf_daily_menu_items_jnt`

#### Requirements

**REQ-CAF-003.1: Create Weekly Menu Plan**
| Attribute | Detail |
|---|---|
| Description | Cafeteria Manager plans the week's menu by assigning dishes to day+meal-type slots |
| Actors | School Admin, Cafeteria Manager |
| Preconditions | Menu items exist; `tenant.caf-daily-menu.create` permission |
| Input | week_start_date (Monday, required), For each day (Mon–Sun) × meal_type: array of menu_item_ids |
| Processing | Create `caf_daily_menus` record per day; create `caf_daily_menu_items_jnt` per item per day slot; validate no duplicate item in same day+meal combination; mark status = Draft |
| Output | Weekly grid view showing planned menus |
| Status | 📐 Proposed |

**REQ-CAF-003.2: Publish Weekly Menu (ST.W1.1.2.1)**
| Attribute | Detail |
|---|---|
| Description | Admin publishes draft weekly menu making it visible on parent/student portal |
| Actors | School Admin, Cafeteria Manager |
| Input | weekly_menu_id |
| Processing | Update `status = Published`; set `published_at`; trigger Notification module to send push/SMS to active parents and students: "This week's canteen menu is now available." |
| Output | Menu visible on portal; notification dispatched |
| Status | 📐 Proposed |

**REQ-CAF-003.3: Portal Menu View (ST.W1.1.2.1)**
| Attribute | Detail |
|---|---|
| Description | Students and parents can view this week's published menu from their portal |
| Actors | Student, Parent |
| Processing | Retrieve current week's published daily menus + items; display day-wise grid with nutritional info and food-type badges; highlight items matching student's dietary profile |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] ST.W1.1.1.2 — Meal plan assigned to specific days and meal types (Breakfast/Lunch/Snacks)
- [ ] ST.W1.1.2.1 — Published menu visible on parent/student portal
- [ ] ST.W1.1.2.2 — Push notification/SMS sent on publish

---

### FR-CAF-004: Student Dietary Profile (F.W2.1 — ST.W2.1.1.2)

**RBS Reference:** ST.W2.1.1.2 — Specify special dietary requirements
**Priority:** 🔴 Critical
**Status:** 📐 Proposed
**Table(s):** `caf_dietary_profiles`

#### Requirements

**REQ-CAF-004.1: Create/Update Dietary Profile**
| Attribute | Detail |
|---|---|
| Description | Admin or parent sets dietary preferences and restrictions for a student |
| Actors | School Admin, Parent (via portal) |
| Preconditions | Student exists in std_students; `tenant.caf-dietary-profile.manage` permission |
| Input | student_id (FK std_students), food_preference (ENUM: Veg/Non-Veg/Jain/Egg-only), is_no_onion_garlic TINYINT(1), is_gluten_free TINYINT(1), custom_restrictions (text — free-form notes e.g. "peanut allergy"), medical_dietary_note (text — doctor-recommended restrictions) |
| Processing | Upsert (one profile per student); log activity |
| Output | Profile saved; kitchen view will flag this student's orders |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] ST.W2.1.1.2 — Special dietary requirements (Jain, No onion-garlic) captured and shown on kitchen orders
- [ ] Kitchen view shows dietary flags prominently for safety
- [ ] Parent can update child's profile via ParentPortal integration

---

### FR-CAF-005: Meal Pre-Ordering (F.W2.1 — T.W2.1.1)

**RBS Reference:** T.W2.1.1 — Student/Parent Order Interface; T.W2.1.2 — Order Management
**Priority:** 🔴 Critical
**Status:** 📐 Proposed
**Table(s):** `caf_orders`, `caf_order_items`

#### Requirements

**REQ-CAF-005.1: Place Meal Pre-Order (ST.W2.1.1.1)**
| Attribute | Detail |
|---|---|
| Description | Student or parent browses published weekly menu and pre-books meals for upcoming days |
| Actors | Student (via portal), Parent (via Parent Portal) |
| Preconditions | Weekly menu is published; ordering window is open (before cutoff); student has sufficient meal card balance OR pay-later allowed |
| Input | student_id, For each selected day+meal_type: array of {menu_item_id, quantity} |
| Processing | 1) Validate each selected date is within published menu and ordering window is open; 2) Check dietary conflicts (warn if non-veg item selected by Jain student); 3) Calculate total amount; 4) Deduct from meal card balance (if prepaid mode) OR mark as pay-at-counter; 5) Create `caf_orders` record with status=Confirmed; 6) Create `caf_order_items` per item; 7) Attach student dietary flags |
| Output | Order confirmation with total; meal card balance updated |
| Status | 📐 Proposed |

**REQ-CAF-005.2: Order Cutoff Enforcement (ST.W2.1.2.2)**
| Attribute | Detail |
|---|---|
| Description | Orders close N hours before the meal (configurable per school via `sys_school_settings`) |
| Processing | System checks current time vs meal_time - cutoff_hours; rejects new orders after cutoff; banner shows "Ordering closed — next available: [date+meal]" |
| Status | 📐 Proposed |

**REQ-CAF-005.3: View/Cancel Own Order**
| Attribute | Detail |
|---|---|
| Description | Student/parent can view and cancel an order before the cutoff window |
| Processing | Cancel allowed only if `status=Confirmed` AND before cutoff; on cancel refund meal card balance if prepaid |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] ST.W2.1.1.1 — Student/parent can browse menu and select meals for upcoming days
- [ ] ST.W2.1.2.2 — Ordering window closes automatically N hours before meal time
- [ ] Dietary conflict warning shown (not blocked) when non-veg item ordered by Jain student

---

### FR-CAF-006: Kitchen Consolidated View (ST.W2.1.2.1)

**RBS Reference:** ST.W2.1.2.1 — View consolidated order list for kitchen preparation
**Priority:** 🔴 Critical
**Status:** 📐 Proposed
**Table(s):** `caf_orders`, `caf_order_items` (read aggregation)

#### Requirements

**REQ-CAF-006.1: Kitchen Order Dashboard**
| Attribute | Detail |
|---|---|
| Description | Kitchen staff views consolidated order summary for any given date and meal type |
| Actors | Kitchen Staff, Cafeteria Manager |
| Input | date, meal_type |
| Processing | Aggregate all confirmed orders for the date+meal_type; group by menu_item; show total quantity per item; show dietary-flag breakdown (Jain count, allergy count, No-onion count) |
| Output | Printable kitchen summary: item name | total qty | Jain | Non-veg | Special notes |
| Status | 📐 Proposed |

**REQ-CAF-006.2: Individual Order List for Serving**
| Attribute | Detail |
|---|---|
| Description | Staff can view order list by class/section for serving distribution |
| Processing | List: student name | class | section | items ordered | dietary flags |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] ST.W2.1.2.1 — Consolidated order list visible for kitchen preparation
- [ ] Dietary flags prominently visible for safety compliance
- [ ] PDF-printable kitchen preparation sheet (DomPDF)

---

### FR-CAF-007: Meal Card Management (Beyond RBS — Extended)

**RBS Reference:** Beyond explicit RBS — critical supporting feature for cashless canteen
**Priority:** 🟠 High
**Status:** 📐 Proposed
**Table(s):** `caf_meal_cards`, `caf_meal_card_transactions`

#### Requirements

**REQ-CAF-007.1: Issue Meal Card**
| Attribute | Detail |
|---|---|
| Description | Admin issues a meal card (prepaid canteen wallet) to a student |
| Actors | School Admin, Accounts Staff |
| Input | student_id (FK std_students, unique per student), card_number (system-generated unique), initial_balance (decimal 10,2, default 0), valid_from_date, valid_to_date |
| Processing | Check student does not already have active card; create card record; log transaction if initial_balance > 0 |
| Output | Meal card issued; QR code generated (SimpleSoftwareIO) for card number |
| Status | 📐 Proposed |

**REQ-CAF-007.2: Top-Up Meal Card Balance**
| Attribute | Detail |
|---|---|
| Description | Parent tops up child's meal card via Razorpay online payment or admin records cash top-up |
| Actors | Parent (online via portal), Admin/Accounts (cash) |
| Input | meal_card_id, amount (min 50, max 5000 per transaction), payment_mode (Online/Cash), razorpay_payment_id (if online) |
| Processing | Verify payment (Razorpay webhook or manual entry); create `caf_meal_card_transactions` record with transaction_type=Credit; update `caf_meal_cards.current_balance` |
| Output | Balance updated; receipt SMS to parent |
| Status | 📐 Proposed |

**REQ-CAF-007.3: Balance Deduction on Order**
| Attribute | Detail |
|---|---|
| Description | On order placement, deduct order total from meal card balance |
| Processing | Atomic: check balance >= order_total; deduct; create Debit transaction; if insufficient, block order (or allow if school settings permit counter payment) |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] Meal card balance never goes negative if prepaid-only mode is enforced
- [ ] Transaction ledger shows all credits (top-ups) and debits (orders) with running balance
- [ ] Parent can view child's meal card balance on Parent Portal

---

### FR-CAF-008: Kitchen Stock Management (F.W3.1)

**RBS Reference:** F.W3.1 — Stock Management (T.W3.1.1, T.W3.1.2)
**Priority:** 🟠 High
**Status:** 📐 Proposed
**Table(s):** `caf_stock_items`

#### Requirements

**REQ-CAF-008.1: Raw Material Register (ST.W3.1.1.1)**
| Attribute | Detail |
|---|---|
| Description | Admin maintains inventory of grains, pulses, vegetables, spices, and other raw materials |
| Actors | School Admin, Cafeteria Manager, Kitchen Staff |
| Input | name (required), category (ENUM: Grains/Pulses/Vegetables/Spices/Dairy/Beverages/Condiments/Other), unit (kg/litre/piece/dozen), current_quantity (decimal 10,3), reorder_level (decimal 10,3), reorder_quantity (decimal — suggested purchase qty), cost_per_unit (decimal 8,2), supplier_name, supplier_contact |
| Processing | Create stock item; validate current_quantity >= 0 |
| Output | Item in stock register |
| Status | 📐 Proposed |

**REQ-CAF-008.2: Reorder Alert & Purchase Request (ST.W3.1.1.2)**
| Attribute | Detail |
|---|---|
| Description | When current_quantity falls to/below reorder_level, system auto-generates purchase request and alerts Cafeteria Manager |
| Processing | Stock update trigger: if current_quantity <= reorder_level create sys_activity_log entry + send in-app notification to Cafeteria Manager role; purchase request record (can link to Inventory/Vendor module in future) |
| Status | 📐 Proposed |

**REQ-CAF-008.3: Consumption Tracking (ST.W3.1.2.1)**
| Attribute | Detail |
|---|---|
| Description | Kitchen staff logs actual consumption of raw materials against planned meals for the day |
| Input | date, stock_item_id, quantity_used, notes |
| Processing | Deduct from current_quantity; create consumption log entry; update `consumed_today` aggregate |
| Status | 📐 Proposed |

**REQ-CAF-008.4: Food Cost & Wastage Reports (ST.W3.1.2.2)**
| Attribute | Detail |
|---|---|
| Description | System calculates food cost per meal and identifies wastage (planned vs actual consumption) |
| Processing | Compare estimated consumption (from orders) vs actual logged consumption; calculate waste percentage; food cost per student per day |
| Output | Wastage report: item | planned qty | actual qty | wasted qty | waste % | cost of waste |
| Status | 📐 Proposed |

**Acceptance Criteria:**
- [ ] ST.W3.1.1.1 — Raw material inventory with grains, pulses, vegetables, spices
- [ ] ST.W3.1.1.2 — Reorder level alerts and auto purchase request generation
- [ ] ST.W3.1.2.1 — Actual consumption logged against planned meals
- [ ] ST.W3.1.2.2 — Food cost and wastage reports generated

---

### FR-CAF-009: Cafeteria Dashboard & Reports (Beyond RBS)

**Priority:** 🟡 Medium
**Status:** 📐 Proposed

#### Requirements

**REQ-CAF-009.1: Revenue Dashboard**
| Metric | Detail |
|---|---|
| Today's Revenue | Sum of confirmed orders for today (deducted from meal cards) |
| Weekly Revenue | Trend chart (7 days) |
| Top Dishes | Top 5 most ordered items this week |
| Meal Card Balances | Total outstanding balance across all active cards |
| Stock Alerts | Items at/below reorder level count |

**REQ-CAF-009.2: Standard Reports**
| Report | Description |
|---|---|
| Revenue Report | Date-range revenue by meal type; daily breakdown |
| Order Summary | Orders per class/section; per student spend analysis |
| Wastage Report | Raw material wastage percentage; cost of waste |
| Meal Card Statement | Per-student transaction ledger |
| Low Stock Report | Items below reorder level |

---

## 5. Data Model

### 5.1 Proposed Tables

> All tables use standard audit columns: `id`, `is_active TINYINT(1) DEFAULT 1`, `created_by BIGINT UNSIGNED NULL FK→sys_users`, `created_at`, `updated_at`, `deleted_at`.

---

#### 📐 `caf_menu_categories`

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| name | VARCHAR(100) | NOT NULL | Category name (e.g., Breakfast) |
| code | VARCHAR(20) | UNIQUE NULL | Short code |
| meal_time | ENUM('Breakfast','Lunch','Snacks','Dinner','Tuck_Shop') | NOT NULL | |
| description | TEXT | NULL | |
| display_order | TINYINT UNSIGNED | DEFAULT 0 | Sort order in portal |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |
| deleted_at | TIMESTAMP | NULL | Soft delete |

---

#### 📐 `caf_menu_items`

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| category_id | INT UNSIGNED | NOT NULL FK→caf_menu_categories | |
| name | VARCHAR(150) | NOT NULL | Dish name |
| description | TEXT | NULL | |
| price | DECIMAL(8,2) | NOT NULL | Per serving price |
| food_type | ENUM('Veg','Non_Veg','Egg','Jain') | NOT NULL DEFAULT 'Veg' | |
| calories | SMALLINT UNSIGNED | NULL | Kcal per serving |
| protein_grams | DECIMAL(5,2) | NULL | |
| carbs_grams | DECIMAL(5,2) | NULL | |
| fat_grams | DECIMAL(5,2) | NULL | |
| allergen_notes | TEXT | NULL | Free-form allergen info |
| photo_media_id | INT UNSIGNED | NULL FK→sys_media | Dish photo |
| is_available | TINYINT(1) | DEFAULT 1 | Real-time availability toggle |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |
| deleted_at | TIMESTAMP | NULL | |

---

#### 📐 `caf_daily_menus`

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| menu_date | DATE | NOT NULL | Specific date this menu is for |
| week_start_date | DATE | NOT NULL | ISO week start (Monday) |
| academic_term_id | INT UNSIGNED | NULL FK→sch_academic_terms | |
| status | ENUM('Draft','Published','Archived') | DEFAULT 'Draft' | |
| published_at | TIMESTAMP | NULL | When published |
| published_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| notes | TEXT | NULL | Kitchen notes for this day |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |
| deleted_at | TIMESTAMP | NULL | |

UNIQUE KEY `uq_caf_daily_menu_date` (`menu_date`)

---

#### 📐 `caf_daily_menu_items_jnt`

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| daily_menu_id | INT UNSIGNED | NOT NULL FK→caf_daily_menus | |
| menu_item_id | INT UNSIGNED | NOT NULL FK→caf_menu_items | |
| meal_category_id | INT UNSIGNED | NOT NULL FK→caf_menu_categories | Which meal slot (Breakfast/Lunch/etc) |
| serving_size_notes | VARCHAR(100) | NULL | e.g., "1 plate", "200ml" |
| display_order | TINYINT UNSIGNED | DEFAULT 0 | |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |

UNIQUE KEY `uq_caf_dmij` (`daily_menu_id`, `menu_item_id`, `meal_category_id`)

---

#### 📐 `caf_dietary_profiles`

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| student_id | INT UNSIGNED | NOT NULL FK→std_students | |
| food_preference | ENUM('Veg','Non_Veg','Egg','Jain') | NOT NULL DEFAULT 'Veg' | |
| is_no_onion_garlic | TINYINT(1) | DEFAULT 0 | |
| is_gluten_free | TINYINT(1) | DEFAULT 0 | |
| is_nut_allergy | TINYINT(1) | DEFAULT 0 | |
| custom_restrictions | TEXT | NULL | Free-form (e.g., "peanut allergy — severe") |
| medical_dietary_note | TEXT | NULL | Doctor-recommended restrictions |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |
| deleted_at | TIMESTAMP | NULL | |

UNIQUE KEY `uq_caf_dietary_student` (`student_id`)

---

#### 📐 `caf_meal_cards`

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| student_id | INT UNSIGNED | NOT NULL FK→std_students | |
| card_number | VARCHAR(20) | NOT NULL UNIQUE | System-generated (CAF-CARD-XXXXXXXX) |
| current_balance | DECIMAL(10,2) | DEFAULT 0.00 | Running balance |
| total_credited | DECIMAL(10,2) | DEFAULT 0.00 | Lifetime top-ups |
| total_debited | DECIMAL(10,2) | DEFAULT 0.00 | Lifetime spend |
| valid_from_date | DATE | NOT NULL | |
| valid_to_date | DATE | NULL | Auto: end of academic year |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |
| deleted_at | TIMESTAMP | NULL | |

UNIQUE KEY `uq_caf_mealcard_student` (`student_id`) — one active card per student

---

#### 📐 `caf_meal_card_transactions`

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| meal_card_id | INT UNSIGNED | NOT NULL FK→caf_meal_cards | |
| student_id | INT UNSIGNED | NOT NULL FK→std_students | Denormalised for fast query |
| transaction_type | ENUM('Credit','Debit','Refund') | NOT NULL | |
| amount | DECIMAL(10,2) | NOT NULL | |
| balance_after | DECIMAL(10,2) | NOT NULL | Snapshot balance after transaction |
| reference_type | VARCHAR(50) | NULL | e.g., 'TopUp', 'Order', 'Refund' |
| reference_id | INT UNSIGNED | NULL | FK to caf_orders.id or fin_payments.id |
| payment_mode | ENUM('Online','Cash','Wallet','Free') | NULL | For top-ups |
| razorpay_payment_id | VARCHAR(100) | NULL | For online top-ups |
| notes | TEXT | NULL | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |

INDEX on `(meal_card_id, created_at)` for statement queries

---

#### 📐 `caf_orders`

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| order_number | VARCHAR(30) | NOT NULL UNIQUE | Format: CAF-YYYY-XXXXXXXX |
| student_id | INT UNSIGNED | NOT NULL FK→std_students | |
| meal_card_id | INT UNSIGNED | NULL FK→caf_meal_cards | |
| order_date | DATE | NOT NULL | Which date the meal is for |
| meal_category_id | INT UNSIGNED | NOT NULL FK→caf_menu_categories | Which meal slot |
| total_amount | DECIMAL(10,2) | NOT NULL | |
| payment_mode | ENUM('MealCard','Cash','Counter') | DEFAULT 'MealCard' | |
| status | ENUM('Pending','Confirmed','Served','Cancelled') | DEFAULT 'Confirmed' | |
| cancelled_at | TIMESTAMP | NULL | |
| cancellation_reason | VARCHAR(255) | NULL | |
| notes | TEXT | NULL | Special instructions |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |
| deleted_at | TIMESTAMP | NULL | |

INDEX on `(student_id, order_date)`, `(order_date, meal_category_id, status)` for kitchen queries

---

#### 📐 `caf_order_items`

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| order_id | INT UNSIGNED | NOT NULL FK→caf_orders | |
| menu_item_id | INT UNSIGNED | NOT NULL FK→caf_menu_items | |
| quantity | TINYINT UNSIGNED | DEFAULT 1 NOT NULL | |
| unit_price | DECIMAL(8,2) | NOT NULL | Snapshot at time of order |
| line_total | DECIMAL(10,2) | NOT NULL | quantity × unit_price |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |

UNIQUE KEY `uq_caf_order_item` (`order_id`, `menu_item_id`)

---

#### 📐 `caf_stock_items`

| Column | Type | Constraints | Description |
|---|---|---|---|
| id | INT UNSIGNED | PK AUTO_INCREMENT | |
| name | VARCHAR(150) | NOT NULL | Raw material name |
| category | ENUM('Grains','Pulses','Vegetables','Fruits','Dairy','Spices','Beverages','Condiments','Cleaning','Other') | NOT NULL | |
| unit | VARCHAR(20) | NOT NULL | kg, litre, piece, dozen, packet |
| current_quantity | DECIMAL(10,3) | DEFAULT 0.000 NOT NULL | |
| reorder_level | DECIMAL(10,3) | NOT NULL | Alert threshold |
| reorder_quantity | DECIMAL(10,3) | NULL | Suggested purchase quantity |
| cost_per_unit | DECIMAL(8,2) | NULL | Latest unit cost |
| supplier_name | VARCHAR(150) | NULL | |
| supplier_contact | VARCHAR(20) | NULL | |
| is_active | TINYINT(1) | DEFAULT 1 | |
| created_by | BIGINT UNSIGNED | NULL FK→sys_users | |
| created_at | TIMESTAMP | | |
| updated_at | TIMESTAMP | | |
| deleted_at | TIMESTAMP | NULL | |

---

### 5.2 Entity Relationships

```
caf_menu_categories  ←──  caf_menu_items
                               │
caf_daily_menus ──── caf_daily_menu_items_jnt ──── caf_menu_items
                                                        │
std_students ──── caf_dietary_profiles               (ordered)
     │                                                  │
     └──── caf_meal_cards ──── caf_meal_card_transactions
     │
     └──── caf_orders ──── caf_order_items ──── caf_menu_items
                │
           caf_meal_cards (deduction)

caf_stock_items  (standalone; future link to Inventory module)
```

---

## 6. Controller & Route Inventory

| Controller | Route Prefix | Named Prefix | Key Methods |
|---|---|---|---|
| 📐 CafeteriaController | /cafeteria | cafeteria | dashboard, index |
| 📐 MenuCategoryController | /cafeteria/menu-categories | cafeteria.menu-categories | CRUD + toggleStatus |
| 📐 MenuItemController | /cafeteria/menu-items | cafeteria.menu-items | CRUD + toggleAvailability |
| 📐 WeeklyMenuController | /cafeteria/weekly-menus | cafeteria.weekly-menus | index, create, store, show, edit, update, publish, archive |
| 📐 OrderController | /cafeteria/orders | cafeteria.orders | index, show, kitchenView, updateStatus, cancel |
| 📐 MealCardController | /cafeteria/meal-cards | cafeteria.meal-cards | CRUD + topup, statement |
| 📐 StockController | /cafeteria/stock-items | cafeteria.stock | CRUD + updateQuantity, consumptionLog |
| 📐 CafeteriaReportController | /cafeteria/reports | cafeteria.reports | revenue, orders, wastage, mealCardStatement |

**Estimated total named routes:** ~52

---

## 7. Form Request Validation Rules

| FormRequest | Key Rules |
|---|---|
| 📐 StoreMenuCategoryRequest | name required\|max:100\|unique:caf_menu_categories,name; meal_time required\|in:Breakfast,Lunch,... |
| 📐 StoreMenuItemRequest | name required\|max:150; category_id required\|exists:caf_menu_categories,id; price required\|numeric\|min:0.01; food_type required\|in:Veg,Non_Veg,Egg,Jain |
| 📐 StoreDailyMenuRequest | week_start_date required\|date\|date_format:Y-m-d; items array validation (day_date, meal_category_id, menu_item_ids[]) |
| 📐 StoreDietaryProfileRequest | student_id required\|exists:std_students,id\|unique:caf_dietary_profiles,student_id; food_preference required\|in:Veg,Non_Veg,Egg,Jain |
| 📐 StoreOrderRequest | student_id required\|exists:std_students,id; order_date required\|date\|after:today; meal_category_id required; items required\|array\|min:1 |
| 📐 TopUpMealCardRequest | meal_card_id required\|exists:caf_meal_cards,id; amount required\|numeric\|min:50\|max:5000; payment_mode required\|in:Online,Cash |
| 📐 StoreStockItemRequest | name required\|max:150; category required\|in:Grains,...; unit required; reorder_level required\|numeric\|min:0 |
| 📐 UpdateStockQuantityRequest | stock_item_id required\|exists:caf_stock_items,id; quantity_change required\|numeric; operation required\|in:add,consume |

---

## 8. Business Rules

| Rule ID | Rule Description |
|---|---|
| BR-CAF-001 | Order cutoff time is configurable per school (default: 2 hours before meal time). Orders placed after cutoff are rejected. |
| BR-CAF-002 | If student food_preference=Jain and selected item food_type=Non_Veg/Egg, show warning (soft block — admin can override). |
| BR-CAF-003 | Meal card balance cannot go below zero in prepaid-only mode. School settings can permit counter payment for orders that exceed balance. |
| BR-CAF-004 | Each student has at most one active meal card at any time (UNIQUE on student_id in caf_meal_cards). |
| BR-CAF-005 | A menu can only be published if at least one menu item is assigned to at least one meal slot. |
| BR-CAF-006 | Published menus trigger a push notification to all active students and parents via the Notification module. |
| BR-CAF-007 | When stock current_quantity ≤ reorder_level, system fires a reorder alert to the Cafeteria Manager role. |
| BR-CAF-008 | Order cancellation is only allowed before the cutoff window. Meal card refund is immediate on cancellation. |
| BR-CAF-009 | Kitchen view only shows orders with status=Confirmed for the selected date+meal. |
| BR-CAF-010 | Hostel students enrolled in a mess plan are auto-confirmed for daily meals without individual pre-ordering. |

---

## 9. Permission & Authorization Model

| Permission Slug | Description |
|---|---|
| tenant.caf-menu-category.view | View menu categories |
| tenant.caf-menu-category.create | Create categories |
| tenant.caf-menu-category.update | Edit categories |
| tenant.caf-menu-category.delete | Delete categories |
| tenant.caf-menu-item.view | View menu items |
| tenant.caf-menu-item.create | Create menu items |
| tenant.caf-menu-item.update | Edit menu items |
| tenant.caf-menu-item.delete | Delete menu items |
| tenant.caf-daily-menu.manage | Create/publish/archive weekly menus |
| tenant.caf-order.view | View all orders |
| tenant.caf-order.manage | Update order status |
| tenant.caf-meal-card.manage | Issue and top-up meal cards |
| tenant.caf-stock.manage | Manage raw material stock |
| tenant.caf-report.view | View cafeteria reports |

**Role Assignments:**
- School Admin: all cafeteria permissions
- Cafeteria Manager: menu.manage, order.view, order.manage, stock.manage, report.view
- Kitchen Staff: order.view (kitchen-view only), stock.manage (consumption log)
- Accounts Staff: meal-card.manage, report.view
- Student: own orders only (via portal — separate gate)
- Parent: own child's orders only (via Parent Portal — separate gate)

---

## 10. Tests Inventory

| # | Test Class | Type | Scenario | Priority |
|---|---|---|---|---|
| 1 | 📐 MenuCategoryCrudTest | Browser | Create/edit/delete menu category | High |
| 2 | 📐 MenuItemCrudTest | Browser | Create item with food_type; toggle availability | High |
| 3 | 📐 WeeklyMenuPublishTest | Feature | Publish menu; verify notification dispatched | High |
| 4 | 📐 OrderPlacementTest | Feature | Place order; verify meal card deducted | Critical |
| 5 | 📐 OrderCutoffTest | Feature | Order rejected after cutoff time | Critical |
| 6 | 📐 DietaryConflictWarningTest | Feature | Non-veg order by Jain student triggers warning | High |
| 7 | 📐 MealCardTopUpTest | Feature | Top-up via cash; balance updated | High |
| 8 | 📐 KitchenConsolidationTest | Feature | Aggregate orders for date+meal produces correct totals | High |
| 9 | 📐 StockReorderAlertTest | Feature | Quantity update to below reorder_level fires alert | Medium |
| 10 | 📐 OrderCancellationRefundTest | Feature | Cancel order before cutoff; balance refunded | High |

---

## 11. Known Issues & Technical Debt

| ID | Issue | Severity | Notes |
|---|---|---|---|
| 📐 | Hostel mess auto-enrolment requires Hostel module FK | Medium | Link to hos_hostel_students when Hostel module is built |
| 📐 | Stock module does not yet link to Inventory/Vendor module | Low | Future: purchase request creates a Vendor module PO |
| 📐 | Razorpay top-up webhook needs to handle duplicate payment_id | High | Idempotency check required |
| 📐 | Order cutoff hours must be school-settings-driven, not hardcoded | High | Requires sys_school_settings entry for caf_order_cutoff_hours |

---

## 12. API Endpoints

| Method | URI | Name | Description |
|---|---|---|---|
| 📐 GET | /api/v1/cafeteria/menu/{date} | api.caf.menu.date | Get published menu for a date (portal) |
| 📐 GET | /api/v1/cafeteria/student/{studentId}/dietary-profile | api.caf.dietary | Get student dietary profile |
| 📐 POST | /api/v1/cafeteria/orders | api.caf.orders.store | Place meal order |
| 📐 GET | /api/v1/cafeteria/meal-card/{studentId}/balance | api.caf.mealcard.balance | Get meal card balance |
| 📐 GET | /api/v1/cafeteria/kitchen-view | api.caf.kitchen | Kitchen consolidated view |

All API endpoints: middleware `auth:sanctum`, prefix `/api/v1/cafeteria`

---

## 13. Non-Functional Requirements

| Category | Requirement |
|---|---|
| Performance | Kitchen view for 500+ orders must load in < 2 seconds (use query aggregation, not N+1) |
| Concurrency | Meal card balance deduction must be atomic (DB transaction + row-level lock) to prevent double-spend |
| Security | Students can only view/cancel their own orders; parents can only access their own child's data |
| Scalability | Indexed on (order_date, meal_category_id, status) for kitchen aggregation queries |
| Availability | Order cutoff enforcement must work even if notification dispatch fails (decouple via queue) |
| PDF Generation | Kitchen preparation sheet and meal card statement generated via DomPDF |
| QR Codes | Meal card QR codes generated via SimpleSoftwareIO/simple-qrcode |

---

## 14. Integration Points

| Module | Integration Type | Details |
|---|---|---|
| StudentProfile (std_*) | Read FK | `std_students.id` for dietary profiles, orders, meal cards |
| Notification (ntf_*) | Dispatch | Menu publish triggers push/SMS notification |
| StudentPortal (STP) | Read/Write | Students order meals via portal screens |
| ParentPortal (PPT) | Read/Write | Parents view menu, place orders, top-up meal card |
| Hostel (hos_*) | Read | Hostel students auto-enrolled in mess plan |
| Finance/Fees (fin_*) | Read | Razorpay payment flow mirrors fin_* pattern |
| Inventory/Vendor (vnd_*) | Future | Stock reorder requests become vendor purchase orders |
| sys_media | Write | Dish photos stored via sys_media |

---

## 15. Pending Work & Gap Analysis

### 15.1 Development Roadmap

| Phase | Tasks | Priority |
|---|---|---|
| Phase 1 — Setup | Migrations (10 tables), Models (10), Providers | Critical |
| Phase 2 — Menu Management | MenuCategory + MenuItem CRUD, WeeklyMenu + publish flow | Critical |
| Phase 3 — Ordering | DietaryProfile, Order placement + cutoff, Kitchen view | Critical |
| Phase 4 — Meal Cards | MealCard issuance + top-up, Razorpay integration, balance deduction | High |
| Phase 5 — Stock | StockItem CRUD, consumption logging, reorder alerts | High |
| Phase 6 — Reports & Dashboard | Revenue report, wastage report, meal card statement | Medium |
| Phase 7 — Portal Integration | Student Portal order screens, Parent Portal integration | Medium |
| Phase 8 — Hostel Mess | Mess plan enrolment, auto-confirmed orders for hostel students | Low |

### 15.2 Open Design Decisions

| Decision | Options | Recommendation |
|---|---|---|
| Order payment timing | Pre-deduct on order vs deduct on serving | Pre-deduct on order (simpler reconciliation) |
| Mess plan for hostel | Auto-confirmed flat daily deduction vs per-item ordering | Flat daily deduction from meal card |
| Stock: Inventory module link | Standalone vs shared with Inventory module | Standalone for now; FK bridge when Inventory built |
| Portal ordering UX | Date-picker per meal vs weekly calendar grid | Weekly calendar grid (mirrors admin planner) |

---

*RBS Reference: Module W — Cafeteria & Mess Management (ST.W1.1.1.1 – ST.W3.1.2.2)*
*Document generated: 2026-03-25 | Status: Greenfield — All features 📐 Proposed*
