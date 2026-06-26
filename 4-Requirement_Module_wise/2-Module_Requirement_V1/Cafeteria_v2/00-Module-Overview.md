# Cafeteria Module — Business Requirements Overview

## Module Purpose

The Cafeteria Module enables a school to manage every aspect of its food service operations — from menu planning and meal pre-orders to POS counter sales, subscription meal plans, stock and inventory management, and FSSAI compliance tracking.

This module replaces manual coordination between the kitchen, cafeteria staff, students, parents, and administration by providing a structured, screen-wise digital workflow. It ensures accurate meal planning, real-time availability tracking, dietary compliance, atomic meal card wallet operations, and full audit trails for all transactions.

---

## Who Uses This Module

| Role | Primary Activities |
|------|-------------------|
| Cafeteria Admin / Manager | Menu planning, category and item setup, stock management, supplier management |
| Kitchen Staff | View daily menus, mark order status, log consumption, view dietary alerts |
| POS Staff / Cashier | Open/close sessions, process counter sales, record meal attendance via QR |
| Students | Pre-order meals, view menus, manage dietary profile, top up meal card |
| Parents | View student meal consumption, add funds to meal card, set dietary restrictions |
| Finance / Accounts | Subscription plan management, enrollment oversight, meal card ledger reports |
| Admin / Principal | FSSAI compliance monitoring, dashboard KPIs, report generation |

---

## Module Screens (Tab-wise)

The entire Cafeteria module is accessible through a single multi-tab interface at: `/cafeteria`

| Tab | Screen | Purpose |
|-----|--------|---------|
| Dashboard | Cafeteria Dashboard | KPI summary, quick links, recent orders, charts |
| Menu Planning | Menu Planning | Manage categories, menu items, daily/weekly menus, event meals |
| Orders & Attendance | Orders & Attendance | View/manage orders, meal attendance, dietary profiles, POS sessions |
| Meal Cards | Meal Cards | Issue meal cards, top-ups, subscription plans, enrollments |
| Stock & Compliance | Stock & Compliance | Manage suppliers, stock items, consumption logs, FSSAI records |

---

## Core Business Flow

```
Menu Categories & Items Setup (Dish Library)
        ↓
Weekly Menu Planning (Daily menus with dish assignments)
        ↓
[Optional] Event Meals (Festival/special meals with class targeting)
        ↓
Students Pre-order Meals (via portal/mobile app before cutoff)
        ↓
Kitchen Preparation (View confirmed orders, dietary alerts)
        ↓
POS Counter Service (QR scan → process transaction → record attendance)
        ↓
Meal Card Wallet (Auto-deduction for card payments, top-ups as needed)
        ↓
Attendance Recording (Idempotent per student per meal per day)
        ↓
Stock Consumption Logging (Deduct raw materials from inventory)
        ↓
Reorder Alerts (Notify when stock falls below threshold)
        ↓
Subscription Cycle (Monthly/termly/annual plan enrollments)
```

---

## Sub-Module Architecture

The module is organized into four logical layers:

**Layer 1 — Menu Planning (Setup):**
- Menu Categories (meal type definitions)
- Menu Items (dish library with nutritional info)
- Weekly/Daily Menus (date-wise menu with dish assignments)
- Event Meals (special festival meals with class targeting)

**Layer 2 — Orders & Attendance (Transactions):**
- Orders (student pre-orders with order items)
- Meal Attendance (QR/biometric/manual scan records)
- Dietary Profiles (per-student food preferences and allergies)
- POS Sessions (shift open/close with transactions)

**Layer 3 — Meal Cards & Subscriptions (Wallet):**
- Meal Cards (prepaid wallet — one per student)
- Meal Card Transactions (immutable credit/debit/refund ledger)
- Subscription Plans (monthly/termly/annual meal plan definitions)
- Subscription Enrollments (student/staff × plan enrollment)

**Layer 4 — Stock & Compliance (Inventory):**
- Suppliers (vendor registration with FSSAI expiry tracking)
- Stock Items (raw material inventory with reorder thresholds)
- Consumption Logs (daily usage with atomic stock deduction)
- FSSAI Records (license and hygiene audit compliance)
- Staff Meal Logs (staff meal tracking with payroll deduction signal)

---

## Document Index

| File | Screen | Description |
|------|--------|-------------|
| [01-Meal-Categories.md](./01-Meal-Categories.md) | Meal Categories | Meal-type category master (Breakfast, Lunch, Snacks, Dinner, Tuck Shop) |
| [02-Menu-Items.md](./02-Menu-Items.md) | Menu Items | Dish library with nutritional macros, food type, allergen notes |
| [03-Weekly-Menus.md](./03-Weekly-Menus.md) | Weekly Menus | Daily menu headers with Draft→Published→Archived lifecycle |
| [04-Event-Meals.md](./04-Event-Meals.md) | Event Meals | Special/festival meal management with class-group targeting |
| [05-Orders.md](./05-Orders.md) | Orders | Student meal pre-order system with lifecycle tracking |
| [06-Meal-Attendance.md](./06-Meal-Attendance.md) | Meal Attendance | QR/biometric/manual scan records — idempotent per student per meal |
| [07-Dietary-Profiles.md](./07-Dietary-Profiles.md) | Dietary Profiles | Per-student dietary preference and allergy profiles |
| [08-POS-Sessions.md](./08-POS-Sessions.md) | POS Sessions | Shift open/close model with counter transactions and staff meals |
| [09-Meal-Cards.md](./09-Meal-Cards.md) | Meal Cards | Prepaid student meal wallet with card management |
| [10-Subscription-Plans.md](./10-Subscription-Plans.md) | Subscription Plans | Meal plan definitions with billing periods and pricing |
| [11-Enrollments.md](./11-Enrollments.md) | Enrollments | Student/staff × plan enrollment with status lifecycle |
| [12-Stock-Items.md](./12-Stock-Items.md) | Stock Items | Raw material inventory with reorder levels |
| [13-Suppliers.md](./13-Suppliers.md) | Suppliers | Food and material supplier register with FSSAI expiry tracking |
| [14-FSSAI.md](./14-FSSAI.md) | FSSAI | License and hygiene audit compliance records |
| [15-Daily-Sales.md](./15-Daily-Sales.md) | Daily Sales | POS sales summary and daily revenue reports |
| [16-Stock-Consumption.md](./16-Stock-Consumption.md) | Stock Consumption | Daily ingredient usage logs with atomic stock deduction |
| [17-Meal-Card-Ledger.md](./17-Meal-Card-Ledger.md) | Meal Card Ledger | Immutable credit/debit/refund/adjustment transaction ledger |

---

## Key Dependencies Between Screens

- **Menu Categories** must exist before **Menu Items** can be created
- **Menu Items** must exist before **Daily Menus** can assign dishes
- **Menu Categories** feed into **Order** and **Attendance** records
- **Students** must be registered (StudentProfile module) before they can place **Orders** or get **Meal Cards**
- **Students** must have a **Meal Card** for wallet-based POS transactions
- **Meal Cards** are required for **Subscription Enrollment** fee deduction
- A **POS Session** must be active to process counter **POS Transactions**
- **POS Transactions** with MealCard mode auto-create **Attendance** records
- **Suppliers** must exist before **Stock Items** can reference them
- **Stock Items** are required for **Consumption Log** entries
- The **Dashboard** aggregates data from all tabs and shows real-time KPIs

---

## Data Tables Reference

| Table | Description |
|-------|-------------|
| `caf_menu_categories` | Meal-type category master |
| `caf_menu_items` | Dish library with nutritional information |
| `caf_daily_menus` | Daily menu headers — one per calendar date |
| `caf_daily_menu_items_jnt` | Day × meal-category × dish assignments |
| `caf_event_meals` | Special/festival meal headers |
| `caf_event_meal_items_jnt` | Event meal × dish assignments (supports free-text items) |
| `caf_suppliers` | Food and material supplier register |
| `caf_stock_items` | Raw material inventory with reorder threshold |
| `caf_consumption_logs` | Daily raw material usage log |
| `caf_fssai_records` | FSSAI license and hygiene audit records |
| `caf_dietary_profiles` | Per-student dietary preference and restriction profile |
| `caf_orders` | Meal pre-order headers |
| `caf_order_items` | Order line items with price snapshot |
| `caf_meal_attendance` | QR/biometric/manual scan records |
| `caf_meal_cards` | Student prepaid meal wallet |
| `caf_meal_card_transactions` | Credit/debit/refund ledger |
| `caf_subscription_plans` | Meal subscription plan definitions |
| `caf_subscription_enrollments` | Student/staff × plan enrollment records |
| `caf_pos_sessions` | POS shift sessions — open/close model |
| `caf_pos_transactions` | Individual POS counter sales |
| `caf_staff_meal_logs` | Staff meal tracking with payroll deduction signal |
