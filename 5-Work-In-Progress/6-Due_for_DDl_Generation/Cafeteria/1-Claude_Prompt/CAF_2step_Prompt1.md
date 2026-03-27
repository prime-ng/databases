# CAF — Cafeteria Module Development Lifecycle Prompt (v1)

**Purpose:** Consolidated prompt to build 3 output files for the **CAF (Cafeteria)** module using `CAF_Cafeteria_Requirement.md` as the single source of truth. Execute phases sequentially; Claude stops after each for your review.

**Output Files:**
1. `CAF_FeatureSpec.md` — Feature Specification
2. `CAF_DDL_v1.sql` + Migration + Seeders — Database Schema Design
3. `CAF_Dev_Plan.md` — Complete Development Plan

**Developer:** Brijesh
**Module:** Cafeteria — Complete cafeteria & mess management for Indian K-12 schools.
Tables: `caf_*` (21 tables across menu planning, orders, attendance, meal cards, POS, stock, and compliance).

---

## DEFAULT PATHS

Read `{AI_BRAIN}/config/paths.md` — resolve all path variables from this file.

## Rules
- All paths come from `paths.md` unless overridden in CONFIGURATION below.
- If a variable exists in both `paths.md` and CONFIGURATION, the CONFIGURATION value wins.

---

## Repositories

```
DB_REPO        = /Users/bkwork/WorkFolder/2-New_Primedb/pgdatabase
OLD_REPO       = /Users/bkwork/WorkFolder/1-Development/0-Git_Work/prime-ai_db/databases
AI_BRAIN       = {OLD_REPO}/AI_Brain
LARAVEL_REPO   = /Users/bkwork/Herd/prime_ai_tarun
LARAVEL_CLAUDE = {LARAVEL_REPO}/.claude/rules
```

## CONFIGURATION

```
MODULE_CODE       = CAF
MODULE            = Cafeteria
MODULE_DIR        = Modules/Cafeteria/
BRANCH            = Brijesh_Main
RBS_MODULE_CODE   = W                              # Welfare/Cafeteria in RBS v4.0
DB_TABLE_PREFIX   = caf_                           # Single prefix — all tables
DATABASE_NAME     = tenant_db

OUTPUT_DIR        = {OLD_REPO}/5-Work-In-Progress/Cafeteria/2-Claude_Plan
MIGRATION_DIR     = {LARAVEL_REPO}/database/migrations/tenant
TENANT_DDL        = {DB_REPO}/1-Master_DDLs/tenant_db_v2.sql
REQUIREMENT_FILE  = {OLD_REPO}/2-Requirement_Module_wise/2-Detailed_Requirements/V2/CAF_Cafeteria_Requirement.md

FEATURE_FILE      = CAF_FeatureSpec.md
DDL_FILE_NAME     = CAF_DDL_v1.sql
DEV_PLAN_FILE     = CAF_Dev_Plan.md
```

---

## HOW TO USE THIS PROMPT

1. Paste this entire document into a new Claude conversation
2. Say: **"Start Phase 1"**
3. Claude reads the required files, generates output, and **STOPS**
4. Review the output; give feedback or say: **"Approved. Proceed to Phase 2"**
5. Repeat for Phase 3

---

## KEY CONTEXT — CAF (CAFETERIA) MODULE

### What This Module Does

The Cafeteria module provides a **complete canteen and hostel mess management system** for Indian K-12 schools on the Prime-AI SaaS platform. It covers the full lifecycle from menu category setup and dish library through weekly menu planning and publishing (with portal notifications), student dietary profiling, cashless meal card wallet management (including Razorpay top-up), meal pre-ordering with cutoff enforcement, QR-based meal attendance scanning at counters, a touch-friendly POS interface for kitchen staff, raw material stock tracking with reorder alerts and optional INV module integration, FSSAI compliance log, staff meal tracking with payroll signalling, and comprehensive revenue and wastage analytics.

**L1 — Menu Planning:**
- Menu category master (Breakfast, Lunch, Snacks, Dinner, Tuck Shop) with meal_time and display order
- Dish library with full nutritional macros (calories, protein, carbs, fat), food type (Veg/Non-Veg/Egg/Jain), allergen notes, and dish photo via sys_media
- Weekly menu planner: 7-day × meal-category grid; Draft → Published → Archived lifecycle
- On publish: push/SMS notification dispatched to all active students and parents via NTF module
- Special/event meal management for festivals, sports days, excursions with class-group targeting

**L2 — Orders & Attendance:**
- Student dietary profile: food preference, specific restrictions (no onion-garlic, gluten-free, nut allergy, dairy-free), medical notes
- Meal subscription plans (monthly/termly/annual) with auto-kitchen headcount for enrolled students
- Pre-ordering portal: order window enforced via `caf_order_cutoff_hours` setting; balance deducted atomically
- QR-based meal attendance scanning at counter: UNIQUE per (student, date, meal_category) prevents duplicates
- Kitchen consolidated view: aggregated item totals with dietary flags; DomPDF kitchen sheet printout

**L3 — Meal Cards & POS:**
- Prepaid wallet: one active card per student (UNIQUE on student_id); `SELECT ... FOR UPDATE` prevents concurrent double-spend
- Razorpay top-up: idempotent via `razorpay_payment_id` UNIQUE; webhook outside auth middleware
- POS counter interface: touch-friendly item grid, QR student lookup, open/close session model
- All balance-affecting operations recorded in `caf_meal_card_transactions` with balance_after snapshot

**L4 — Stock & Compliance:**
- Raw material stock register with reorder alerts; optional INV purchase requisition via `caf_inv_integration` setting
- FSSAI license and audit log with 30-day / 7-day expiry alerts for suppliers; 60-day / 30-day for school license
- Staff meal tracking with `payroll_deduction_flag` as signal to PAY module (CAF never writes to pay_*)

### Architecture Decisions
- **Single Laravel module** (`Modules\Cafeteria`) — all 4 sub-modules in one module
- Stancl/tenancy v3.9 — dedicated DB per tenant — **NO `tenant_id` column** on any table
- Route prefix: `cafeteria/` | Route name prefix: `cafeteria.`
- **All `caf_*` PKs and intra-module FKs: `INT UNSIGNED`** (not BIGINT) — this module uses INT, unlike most other modules
  - Exception: `sys_users` refs remain `BIGINT UNSIGNED` (system convention)
  - `std_students` refs: `INT UNSIGNED` (consistent with STD module)
  - `sys_media` refs: `INT UNSIGNED`
- Atomic balance deduction: `SELECT ... FOR UPDATE` row-lock on `caf_meal_cards` inside DB::transaction — prevents concurrent double-spend (BR-CAF-012)
- Razorpay webhook: `MealCardController@apiRazorpayWebhook` route uses `->withoutMiddleware(['auth:sanctum'])` — public endpoint; idempotency via `razorpay_payment_id` UNIQUE (BR-CAF-011)
- HST bridge: hostel admission auto-triggers subscription enrollment in mess plan via `caf_hostel_auto_enroll` school setting; bridge called by HST module on hostel admission event
- INV bridge: when `caf_inv_integration=true` and stock hits reorder level, `StockService` creates a purchase requisition in INV module; graceful degradation when INV is not licensed
- QR code generation for meal cards: `SimpleSoftwareIO/simple-qrcode` package
- PDF generation: `barryvdh/laravel-dompdf` for kitchen sheet, meal card statement, FSSAI audit log

### Module Scale (v2)
| Artifact | Count |
|---|---|
| Controllers | 16 (from Section 2.4 file list) |
| Models | 21 |
| Services | 6 |
| FormRequests | 16 |
| Policies | 14 |
| caf_* tables | 21 (req Section 1 says 21 — confirmed by Section 5.1 data model) |
| Blade views (estimated) | ~50 |
| Seeders | 1 + 1 runner |

### Complete Table Inventory

**Menu Planning (5 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 1 | `caf_menu_categories` | Meal-type category master | UNIQUE `(code)` nullable |
| 2 | `caf_menu_items` | Dish library with nutrition | FK → caf_menu_categories + sys_media |
| 3 | `caf_daily_menus` | One record per menu date | UNIQUE `(menu_date)` |
| 4 | `caf_daily_menu_items_jnt` | Day × meal-category × dish | UNIQUE `(daily_menu_id, menu_item_id, meal_category_id)` |
| 5 | `caf_event_meals` | Special/festival meal headers | FK → caf_menu_categories |

**Dietary & Subscriptions (4 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 6 | `caf_event_meal_items_jnt` | Event meal × dish assignments | FK → caf_event_meals + caf_menu_items |
| 7 | `caf_dietary_profiles` | Per-student dietary flags | UNIQUE `(student_id)` |
| 8 | `caf_subscription_plans` | Fixed meal plan definitions | FK → sch_academic_terms |
| 9 | `caf_subscription_enrollments` | Student/staff × plan enrolment | FK → caf_subscription_plans + caf_meal_cards |

**Orders & Attendance (3 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 10 | `caf_orders` | Pre-order headers | UNIQUE `(order_number)` |
| 11 | `caf_order_items` | Pre-order line items | UNIQUE `(order_id, menu_item_id)` |
| 12 | `caf_meal_attendance` | QR scan records | UNIQUE `(student_id, meal_date, meal_category_id)` |

**Meal Cards & POS (4 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 13 | `caf_pos_sessions` | POS shift sessions | FK → sys_users |
| 14 | `caf_pos_transactions` | Individual POS sales | FK → caf_pos_sessions + caf_meal_cards |
| 15 | `caf_meal_cards` | Student prepaid wallet | UNIQUE `(student_id)`, UNIQUE `(card_number)` |
| 16 | `caf_meal_card_transactions` | Credit/Debit/Refund ledger | UNIQUE `(razorpay_payment_id)` nullable |

**Stock & Suppliers (3 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 17 | `caf_suppliers` | Food supplier register | FK → sys_users; FSSAI expiry tracked |
| 18 | `caf_stock_items` | Raw material inventory | FK → caf_suppliers; reorder_level threshold |
| 19 | `caf_consumption_logs` | Daily raw-material usage | Index `(stock_item_id, log_date)` |

**Compliance & Staff (2 tables):**
| # | Table | Domain | Key Constraints |
|---|---|---|---|
| 20 | `caf_fssai_records` | FSSAI license + audit log | FK → sys_media; covers both License and Audit record types |
| 21 | `caf_staff_meal_logs` | Staff meal tracking | FK → caf_menu_categories; `payroll_deduction_flag` for PAY module |

**Existing Tables REUSED (CAF reads from; never modifies schema):**
| Table | Source | CAF Usage |
|---|---|---|
| `std_students` | Student (STD) | dietary_profiles, meal_cards, orders, meal_attendance |
| `sch_academic_terms` | SchoolSetup (SCH) | daily_menus academic_term_id, subscription_plans |
| `sys_users` | System | All `created_by`, POS opened_by, staff meal logs, published_by |
| `sys_media` | System | Menu item photos, FSSAI license documents |
| `sys_activity_logs` | System | Audit trail (write-only) |
| `ntf_notifications` | Notification | Menu publish alerts, low balance, FSSAI expiry, reorder alerts |
| `inv_purchase_requisitions` | Inventory (INV) | Optional bridge: auto-PR on stock reorder (write if INV licensed) |

### Cross-Module Integration
```
On Menu Published:
  → NTF module: dispatches push/SMS to all active students and parents
  → Student Portal and Parent Portal: published menu becomes visible

On Pre-Order Placed:
  MealCardService::deductBalance() — SELECT...FOR UPDATE → DB transaction
  → deducts balance from caf_meal_cards
  → creates caf_meal_card_transactions (Debit)
  → order status → 'Confirmed'

On Razorpay Webhook:
  → idempotency check on razorpay_payment_id UNIQUE
  → MealCardService::creditBalance() inside DB transaction
  → creates caf_meal_card_transactions (Credit)
  → NTF: SMS confirmation to parent

On Stock Reorder Alert:
  → NTF: in-app notification to CAFETERIA_MGR
  → if caf_inv_integration=true: StockService creates inv_purchase_requisitions record

On Hostel Admission (HST bridge):
  → if caf_hostel_auto_enroll=true: auto-enrolls student in hostel mess subscription plan
  → creates caf_subscription_enrollments record; deducts plan fee from meal card

Staff Meal Payroll Signal:
  → payroll_deduction_flag=1 in caf_staff_meal_logs is a read signal for PAY module
  → CAF never writes to pay_* tables
```

---

## PHASE 1 — Feature Specification

### Phase 1 Input Files
Read ALL these files in order before generating any output:

1. `{REQUIREMENT_FILE}` — **Primary and complete source** — CAF v2 requirement (15+ FRs, Sections 1–16)
2. `{AI_BRAIN}/memory/project-context.md` — Project context and existing module list
3. `{AI_BRAIN}/memory/modules-map.md` — Existing module inventory (avoid duplication)
4. `{AI_BRAIN}/agents/business-analyst.md` — BA agent instructions (read if file exists)
5. `{TENANT_DDL}` — Verify actual column names for: std_students, sch_academic_terms, sys_users, sys_media (use exact column names in spec)

### Phase 1 Task — Generate `CAF_FeatureSpec.md`

Generate a comprehensive feature specification document. Organise it into these 11 sections:

---

#### Section 1 — Module Identity & Scope
- Module code, namespace, route prefix, DB prefix, module type
- In-scope sub-modules (L1 Menu Planning, L2 Orders & Attendance, L3 Meal Cards & POS, L4 Stock & Compliance — verbatim from req v2 Section 2.3)
- Out-of-scope items (payroll deduction computation delegated to PAY module; vendor PO creation delegated to VND/INV; depreciation, accounting ledgers not in CAF scope)
- Module scale table (controller / model / service / FormRequest / policy / table counts)

#### Section 2 — Entity Inventory (All 21 Tables)
For each `caf_*` table, provide:
- Table name, short description (one line)
- Full column list: column name | data type | nullable | default | constraints | comment
- Unique constraints
- Indexes (list ALL FKs that need indexes, plus any other frequently filtered columns)
- Cross-module FK references clearly noted

Group tables by domain:
- **Menu Planning** (caf_menu_categories, caf_menu_items, caf_daily_menus, caf_daily_menu_items_jnt, caf_event_meals)
- **Dietary & Subscriptions** (caf_event_meal_items_jnt, caf_dietary_profiles, caf_subscription_plans, caf_subscription_enrollments)
- **Orders & Attendance** (caf_orders, caf_order_items, caf_meal_attendance)
- **Meal Cards & POS** (caf_pos_sessions, caf_pos_transactions, caf_meal_cards, caf_meal_card_transactions)
- **Stock & Suppliers** (caf_suppliers, caf_stock_items, caf_consumption_logs)
- **Compliance & Staff** (caf_fssai_records, caf_staff_meal_logs)

#### Section 3 — Entity Relationship Diagram (text-based)
Show all 21 tables grouped by layer (caf_* vs cross-module reads from std_*/sch_*/sys_*).
Use `→` for FK direction (child → parent).

Critical cross-module FKs to highlight:
- `caf_menu_items.photo_media_id → sys_media.id` (nullable — dish photo)
- `caf_fssai_records.fssai_document_media_id → sys_media.id` (nullable — license document)
- `caf_daily_menus.academic_term_id → sch_academic_terms.id` (nullable)
- `caf_subscription_plans.academic_term_id → sch_academic_terms.id` (nullable)
- `caf_dietary_profiles.student_id → std_students.id` (UNIQUE — one profile per student)
- `caf_meal_cards.student_id → std_students.id` (UNIQUE — one active card per student)
- `caf_orders.student_id → std_students.id`
- `caf_meal_attendance.student_id → std_students.id`

#### Section 4 — Business Rules (19 rules)
For each rule, state:
- Rule ID (BR-CAF-001 to BR-CAF-019)
- Rule text (from req v2 Section 8)
- Which table/column it enforces
- Enforcement point: `service_layer` | `db_constraint` | `form_validation` | `model_event`

Critical rules to emphasise:
- BR-CAF-003: Meal card balance may not go negative in prepaid-only mode (`caf_allow_negative_balance=false`) — service_layer guard before deduction
- BR-CAF-004: One active meal card per student — `db_constraint` (UNIQUE on student_id) + service logic to deactivate old card before issuance
- BR-CAF-005: Weekly menu publish blocked if no items assigned — service_layer pre-condition check
- BR-CAF-011: Razorpay webhook idempotency — `db_constraint` UNIQUE `(razorpay_payment_id)` + application-level duplicate check
- BR-CAF-012: Balance deduction atomicity — `SELECT...FOR UPDATE` row-lock + DB transaction in MealCardService
- BR-CAF-013: POS transactions require open session — service_layer check: `caf_pos_sessions.closed_at IS NULL`
- BR-CAF-015: No `tenant_id` column — isolation at DB level via stancl/tenancy
- BR-CAF-018: UNIQUE on `caf_daily_menus.menu_date` — one menu record per calendar date — `db_constraint`

#### Section 5 — Workflow State Machines (5 FSMs)
For each FSM, provide:
- State diagram (ASCII/text format)
- Valid transitions with trigger condition
- Pre-conditions (checked before transition allowed)
- Side effects (DB writes, events fired, balance updates)

FSMs to document:
1. **Weekly Menu Lifecycle** — `Draft → (add items) → Draft → (publish) → Published → (scheduler: next week) → Archived`
   On publish: notification dispatched to all active students/parents; status + published_at recorded
   On archive: `caf:archive-old-menus` Artisan command runs daily; archived menus remain readable
2. **Pre-Order Lifecycle** — `Placed → Confirmed → Served → (terminal)`; `Confirmed → (cancel before cutoff) → Cancelled`
   On confirm: OrderService validates menu Published + cutoff window + dietary conflict; MealCardService::deductBalance() atomic
   On cancel: MealCardService::refundBalance(); balance refunded immediately; status → Cancelled
3. **Meal Card Top-Up (Razorpay)** — `Initiated → Gateway Redirect → Webhook Received → Credited`
   On webhook: verify Razorpay signature; idempotency check on razorpay_payment_id UNIQUE; credit balance; SMS to parent
4. **POS Session Lifecycle** — `(Staff opens) → Active → (Staff closes) → Closed → (scheduler) → Archived`
   All transactions must be linked to an Active session; no transactions allowed outside active session
5. **Stock Reorder Alert** — `Kitchen logs consumption → StockService.deductQuantity() → qty ≤ reorder_level? → Alert + optional INV PR`

#### Section 6 — Functional Requirements Summary (15 FRs)
For each FR-CAF-01 to FR-CAF-15:
| FR ID | Name | Sub-Module | Tables Used | Key Validations | Related BRs | Depends On |
|---|---|---|---|---|---|---|

Group by sub-module (L1 Menu Planning, L2 Orders & Attendance, L3 Meal Cards & POS, L4 Stock & Compliance per req v2 Section 4):
- FR-CAF-01: Menu Category Management → caf_menu_categories
- FR-CAF-02: Menu Item Master → caf_menu_items
- FR-CAF-03: Weekly Menu Planning & Publish → caf_daily_menus, caf_daily_menu_items_jnt
- FR-CAF-04: Special/Event Meal Management → caf_event_meals, caf_event_meal_items_jnt
- FR-CAF-05: Student Dietary Profile → caf_dietary_profiles
- FR-CAF-06: Meal Subscription Plans → caf_subscription_plans, caf_subscription_enrollments
- FR-CAF-07: Meal Pre-Ordering (Portal) → caf_orders, caf_order_items
- FR-CAF-08: Meal Card (Prepaid Wallet) → caf_meal_cards, caf_meal_card_transactions
- FR-CAF-09: QR-Based Meal Attendance → caf_meal_attendance
- FR-CAF-10: POS Counter Interface → caf_pos_sessions, caf_pos_transactions
- FR-CAF-11: Raw Material Stock Management → caf_stock_items, caf_consumption_logs, caf_suppliers
- FR-CAF-12: FSSAI Compliance Tracking → caf_fssai_records
- FR-CAF-13: Staff Meal Management → caf_staff_meal_logs
- FR-CAF-14: Kitchen Consolidation & Reports → (reads caf_orders, caf_meal_attendance, caf_subscription_enrollments)
- FR-CAF-15: Cross-Module Integration (HST bridge, INV bridge, PAY signal) → caf_subscription_enrollments, caf_stock_items

#### Section 7 — Permission Matrix
| Permission String | Admin | CafMgr | Kitchen | Accounts | Student | Parent |
|---|---|---|---|---|---|---|

Derive permissions from req v2 Section 15.2. Include:
- `cafeteria.menu-category.*` (CRUD for menu categories)
- `cafeteria.menu-item.*` (CRUD + availability toggle)
- `cafeteria.daily-menu.manage` (plan, publish, archive)
- `cafeteria.subscription.manage` (create plans, enroll students)
- `cafeteria.order.view` / `cafeteria.order.manage`
- `cafeteria.pos.operate` (open/close sessions, process transactions)
- `cafeteria.meal-attendance.view`
- `cafeteria.dietary-profile.manage`
- `cafeteria.meal-card.manage` (issue, top-up)
- `cafeteria.stock.manage`
- `cafeteria.supplier.manage`
- `cafeteria.fssai.manage`
- `cafeteria.report.view`
- `cafeteria.staff-meal.manage`
Which Policy class enforces each permission (14 policies from req v2 Section 2.4)

#### Section 8 — Service Architecture (6 services)
For each service:
```
Service:     ClassName
File:        app/Services/ClassName.php
Namespace:   Modules\Cafeteria\app\Services
Depends on:  [other services it calls]
Fires:       [events or notifications it dispatches]

Key Methods:
  methodName(TypeHint $param): ReturnType
    └── description of what it does
```

Services to document:
1. **MenuService** — publish weekly menu (pre-condition: ≥1 item assigned); archive old menus; notify students/parents via NTF; `caf:archive-old-menus` Artisan support; enforce UNIQUE menu_date; event meal publish
2. **OrderService** — place pre-order (validate menu Published + cutoff window + dietary conflict warning); cancel order with refund; kitchen view consolidation (aggregate by item, headcount from subscriptions + orders); mark Served; print kitchen sheet PDF (DomPDF)
3. **MealCardService** — issue card (deactivate previous if exists); `deductBalance()` atomic via `SELECT...FOR UPDATE` + DB transaction; `creditBalance()` for top-up and refund; Razorpay top-up initiation; webhook idempotency check on razorpay_payment_id; card statement PDF (DomPDF); low-balance notification trigger after every debit; QR code generation (SimpleSoftwareIO/simple-qrcode)
4. **PosService** — open/close session; process POS transaction (deduct from meal card or cash); student QR lookup with dietary flags; dietary conflict alert on POS scan; session summary reconciliation
5. **StockService** — log consumption (deduct current_quantity); reorder level check after each deduction; dispatch in-app notification to CAFETERIA_MGR; optional INV bridge (create inv_purchase_requisitions when `caf_inv_integration=true`); `caf:check-stock-reorder` Artisan support; supplier FSSAI expiry alert dispatch
6. **ReportService** — revenue report (orders + POS by date range); order summary (per-student, per-class); wastage report (planned from orders vs actual from attendance); meal card statements (all transactions for card); FSSAI audit log PDF (DomPDF); fputcsv for CSV exports; chunked queries for large date ranges

#### Section 9 — Integration Contracts
For each integration, provide:
| Integration | Triggered By | Target Module | Payload / Action |
|---|---|---|---|
- `MenuPublished` → NTF → Push/SMS to all active students and parents (weekly menu + event meal)
- `LowBalanceAlert` → NTF (queued) → Push/SMS to parent when balance < `caf_low_balance_threshold`
- `StockReorderAlert` → NTF → In-app to CAFETERIA_MGR; optional auto-PR to INV module
- `FssaiExpiryAlert` → NTF → Alert: supplier 30+7 days before; school 60+30 days before
- `HostelAdmission (HST)` → CAF → Auto-enroll in hostel mess subscription plan; deduct plan fee from meal card
- `StaffMealPayrollFlag` → PAY → `payroll_deduction_flag=1` on caf_staff_meal_logs is read-only signal; PAY module owns deduction

Document payload structure for `MealCardService::deductBalance()` as inline pseudocode:
```
deductBalance(MealCard $card, float $amount, string $referenceType, int $referenceId): MealCardTransaction
  Step 1: DB transaction begins
  Step 2: SELECT...FOR UPDATE on caf_meal_cards row
  Step 3: Check: balance sufficient? OR caf_allow_negative_balance=true
  Step 4: Compute new balance = current_balance − amount
  Step 5: UPDATE caf_meal_cards SET current_balance, total_debited
  Step 6: INSERT caf_meal_card_transactions (Debit, balance_after = new balance)
  Step 7: DB transaction commits
  Step 8: If new balance < caf_low_balance_threshold → dispatch LowBalanceNotificationJob
```

#### Section 10 — Non-Functional Requirements
From req v2 Section 10.
For each NFR, add an "Implementation Note" column explaining HOW it will be met in code:
- Kitchen view for 500+ orders: < 2s — composite index `(order_date, meal_category_id, status)` + eager load; no N+1
- Meal card balance deduction concurrency: `SELECT...FOR UPDATE` + single DB transaction in MealCardService
- Razorpay webhook idempotency: `razorpay_payment_id` UNIQUE constraint + application-level duplicate check before insert
- QR attendance scan idempotency: UNIQUE `(student_id, meal_date, meal_category_id)` — duplicate scan returns 200 gracefully
- PDF generation (kitchen sheet, statement, FSSAI): DomPDF — barryvdh/laravel-dompdf
- QR code generation: `SimpleSoftwareIO/simple-qrcode` for meal card QR
- Queue: Menu publish notification, low-balance alert, reorder alert dispatched via Laravel Queue (database driver default)
- Security: Students see only their own orders and card balance; parents see only their child's data; dietary profile read-only for kitchen staff

#### Section 11 — Test Plan Outline
From req v2 Section 12:

**Feature Tests (Pest) — 20 test files:**
| File | Key Scenarios |
|---|---|
(List all files from req v2 Section 12 with count and scenarios)

**Unit Tests (PHPUnit) — 2 test files:**
| File | Key Scenarios |
|---|---|
- `MealCardTransactionLedgerTest` — balance_after on each transaction equals prior balance ± amount
- `OrderNumberFormatTest` — order number matches regex `CAF-\d{4}-[A-Z0-9]{8}`

**Test Data:**
- Required seeders: CafMenuCategorySeeder (5 categories for test isolation)
- Required factories: MenuCategoryFactory, MenuItemFactory, DailyMenuFactory, MealCardFactory, OrderFactory, StudentFactory (or ref from STD)
- Mock strategy: `Notification::fake()` for menu publish and low-balance notifications; `Queue::fake()` for StockReorderAlertJob; `Event::fake()` where applicable; Razorpay webhook — test with known HMAC signature; `DB::transaction` and row-lock tests use in-memory SQLite (for unit) or real tenant DB (for feature)

---

### Phase 1 Output Files
| File | Location |
|---|---|
| `CAF_FeatureSpec.md` | `{OUTPUT_DIR}/CAF_FeatureSpec.md` |

### Phase 1 Quality Gate
- [ ] All 21 caf_* tables appear in Section 2 entity inventory
- [ ] All 15 FRs (CAF-01 to CAF-15) appear in Section 6
- [ ] All 19 business rules (BR-CAF-001 to BR-CAF-019) in Section 4 with enforcement point
- [ ] All 5 FSMs documented with ASCII state diagram and side effects
- [ ] All 6 services listed with key method signatures in Section 8
- [ ] All integration contracts documented (NTF, HST, INV, PAY) in Section 9
- [ ] `caf_meal_cards.student_id` noted as UNIQUE (one active card per student, BR-CAF-004)
- [ ] `caf_meal_card_transactions.razorpay_payment_id` noted as UNIQUE nullable (idempotency, BR-CAF-011)
- [ ] `caf_meal_attendance` UNIQUE on `(student_id, meal_date, meal_category_id)` documented
- [ ] `caf_daily_menus.menu_date` UNIQUE constraint noted (BR-CAF-018)
- [ ] `SELECT...FOR UPDATE` pattern documented in MealCardService::deductBalance() (BR-CAF-012)
- [ ] Razorpay webhook route as `withoutMiddleware(['auth:sanctum'])` noted
- [ ] **No `tenant_id` column** mentioned anywhere in any table definition
- [ ] INT UNSIGNED vs BIGINT UNSIGNED distinction documented: all caf_* PKs/FKs are INT UNSIGNED; sys_users refs are BIGINT UNSIGNED
- [ ] `SimpleSoftwareIO/simple-qrcode` noted for meal card QR generation
- [ ] DomPDF noted for kitchen sheet, card statement, and FSSAI audit PDF
- [ ] HST bridge (auto mess enrollment on hostel admission) documented with school setting `caf_hostel_auto_enroll`
- [ ] INV bridge (auto PR on reorder) documented with school setting `caf_inv_integration` and graceful degradation
- [ ] PAY module signal via `payroll_deduction_flag` documented — CAF does NOT write to pay_*
- [ ] Permission matrix covers Admin / CafMgr / Kitchen / Accounts / Student / Parent roles
- [ ] All cross-module column names verified against tenant_db_v2.sql (use EXACT names from DDL)

**After Phase 1, STOP and say:**
"Phase 1 (Feature Specification) complete. Output saved to `{OUTPUT_DIR}/CAF_FeatureSpec.md`. Please review and say 'Approved. Proceed to Phase 2' to continue."

---

## PHASE 2 — Database Schema Design (DDL + Seeders)

### Phase 2 Input Files
1. `{OUTPUT_DIR}/CAF_FeatureSpec.md` — Entity inventory (Section 2) from Phase 1
2. `{REQUIREMENT_FILE}` — Section 5 (canonical column definitions for all 21 tables)
3. `{AI_BRAIN}/agents/db-architect.md` — DB Architect agent instructions (read if exists)
4. `{TENANT_DDL}` — Existing schema: verify referenced table column names and data types; check no duplicate tables being created

### Phase 2A Task — Generate DDL (`CAF_DDL_v1.sql`)

Generate CREATE TABLE statements for all 21 tables. Produce one single SQL file.

**14 DDL Rules — all mandatory:**

1. Table prefix: `caf_` for all tables — no exceptions
2. Every table MUST include: `id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY`, `is_active TINYINT(1) NOT NULL DEFAULT 1 COMMENT 'Soft enable/disable'`, `created_by BIGINT UNSIGNED NULL COMMENT 'sys_users.id'`, `created_at TIMESTAMP NULL`, `updated_at TIMESTAMP NULL`, `deleted_at TIMESTAMP NULL COMMENT 'Soft delete'`
   - Note: `caf_meal_attendance`, `caf_daily_menu_items_jnt`, `caf_event_meal_items_jnt`, `caf_order_items`, `caf_consumption_logs`, `caf_pos_transactions`, `caf_staff_meal_logs`, `caf_meal_card_transactions` do NOT have `deleted_at` (no soft delete on transactional records — see req Section 5 per-table definitions)
3. Index ALL foreign key columns — every FK column must have a KEY entry
4. Junction/bridge tables: use suffix `_jnt` (e.g. `caf_daily_menu_items_jnt`, `caf_event_meal_items_jnt`)
5. JSON columns: suffix `_json` (e.g. `items_json`, `dietary_flags_json`, `target_class_ids_json`, `supply_categories_json`, `included_category_ids_json`)
6. Boolean flag columns: prefix `is_` or `has_`
7. **CRITICAL — ID types for this module:**
   - All `caf_*` table PKs: `INT UNSIGNED NOT NULL AUTO_INCREMENT`
   - All intra-module FK columns (caf_* → caf_*): `INT UNSIGNED`
   - Cross-module FK to `sys_users`: `BIGINT UNSIGNED` (sys_users.id is BIGINT)
   - Cross-module FK to `std_students`: `INT UNSIGNED`
   - Cross-module FK to `sys_media`: `INT UNSIGNED`
   - Cross-module FK to `sch_academic_terms`: `INT UNSIGNED`
8. Add COMMENT on every column — describe what it holds, valid values for ENUMs
9. Engine: `ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci`
10. Use `CREATE TABLE IF NOT EXISTS`
11. FK constraint naming: `fk_caf_{tableshort}_{column}` (e.g. `fk_caf_mitm_category_id`)
12. **Do NOT recreate std_*, sch_*, sys_*, ntf_* tables** — reference via FK only
13. **No `tenant_id` column** — stancl/tenancy v3.9 uses separate DB per tenant
14. `caf_meal_card_transactions.razorpay_payment_id`: `VARCHAR(100) NULL UNIQUE` — idempotency constraint; multiple NULLs are allowed (only non-null values are unique)

**DDL Table Order (dependency-safe — define referenced tables before referencing tables):**

Layer 1 — No caf_* dependencies (may reference sys_*/std_*/sch_* only):
  `caf_menu_categories` (no caf_* deps),
  `caf_suppliers` (no caf_* deps),
  `caf_fssai_records` (→ sys_media),
  `caf_daily_menus` (→ sch_academic_terms + sys_users),
  `caf_subscription_plans` (→ sch_academic_terms),
  `caf_meal_cards` (→ std_students + sys_users),
  `caf_pos_sessions` (→ sys_users),
  `caf_dietary_profiles` (→ std_students + sys_users)

Layer 2 — Depends on Layer 1 only:
  `caf_menu_items` (→ caf_menu_categories + sys_media),
  `caf_stock_items` (→ caf_suppliers),
  `caf_event_meals` (→ caf_menu_categories),
  `caf_subscription_enrollments` (→ caf_subscription_plans + caf_meal_cards),
  `caf_meal_card_transactions` (→ caf_meal_cards),
  `caf_meal_attendance` (→ caf_menu_categories + std_students),
  `caf_pos_transactions` (→ caf_pos_sessions + caf_meal_cards),
  `caf_staff_meal_logs` (→ caf_menu_categories),
  `caf_orders` (→ std_students + caf_meal_cards + caf_menu_categories)

Layer 3 — Depends on Layer 2:
  `caf_daily_menu_items_jnt` (→ caf_daily_menus + caf_menu_items + caf_menu_categories),
  `caf_event_meal_items_jnt` (→ caf_event_meals + caf_menu_items),
  `caf_consumption_logs` (→ caf_stock_items + caf_menu_categories)

Layer 4 — Depends on Layer 3:
  `caf_order_items` (→ caf_orders + caf_menu_items)

**Critical unique constraints to include:**
```sql
-- caf_menu_categories
UNIQUE KEY uq_caf_mc_code (code)           -- nullable, allows multiple NULLs

-- caf_daily_menus
UNIQUE KEY uq_caf_dm_menu_date (menu_date) -- one menu per calendar date (BR-CAF-018)

-- caf_daily_menu_items_jnt
UNIQUE KEY uq_caf_dmij (daily_menu_id, menu_item_id, meal_category_id)

-- caf_event_meal_items_jnt — no unique beyond PK (free-text items allowed)

-- caf_dietary_profiles
UNIQUE KEY uq_caf_dp_student (student_id)  -- one profile per student

-- caf_meal_cards
UNIQUE KEY uq_caf_mcard_student (student_id)     -- one active card per student (BR-CAF-004)
UNIQUE KEY uq_caf_mcard_number (card_number)     -- card number is globally unique within tenant

-- caf_meal_card_transactions
UNIQUE KEY uq_caf_mct_razorpay (razorpay_payment_id)  -- NULL values exempt (idempotency BR-CAF-011)

-- caf_meal_attendance
UNIQUE KEY uq_caf_ma (student_id, meal_date, meal_category_id)  -- idempotent QR scan

-- caf_order_items
UNIQUE KEY uq_caf_oi_order_item (order_id, menu_item_id)

-- caf_orders
UNIQUE KEY uq_caf_orders_number (order_number)
```

**ENUM values (exact, to match application code):**
```
caf_menu_categories.meal_time:              'Breakfast','Lunch','Snacks','Dinner','Tuck_Shop'
caf_menu_items.food_type:                   'Veg','Non_Veg','Egg','Jain'
caf_daily_menus.status:                     'Draft','Published','Archived'
caf_event_meals.status:                     'Draft','Published','Archived'
caf_dietary_profiles.food_preference:       'Veg','Non_Veg','Egg','Jain'
caf_subscription_plans.billing_period:      'Monthly','Termly','Annual'
caf_subscription_enrollments.status:        'Active','Paused','Cancelled','Expired'
caf_orders.payment_mode:                    'MealCard','Cash','Counter','Subscription'
caf_orders.status:                          'Pending','Confirmed','Served','Cancelled'
caf_meal_attendance.scan_method:            'QR','Biometric','Manual'
caf_pos_transactions.payment_mode:          'MealCard','Cash'
caf_meal_card_transactions.transaction_type:'Credit','Debit','Refund','Adjustment'
caf_meal_card_transactions.payment_mode:    'Online','Cash','Wallet','Free'
caf_stock_items.category:                   'Grains','Pulses','Vegetables','Fruits','Dairy','Spices','Beverages','Condiments','Cleaning','Other'
caf_fssai_records.record_type:              'License','Audit'
caf_fssai_records.license_type:             'Basic','State','Central'
caf_staff_meal_logs.payment_mode:           'Subscription','Cash','CardDeduction'
```

**Critical columns to get right:**
- `caf_meal_cards.current_balance`: `DECIMAL(10,2) DEFAULT 0.00` — updated atomically by MealCardService
- `caf_meal_cards.total_credited` / `total_debited`: `DECIMAL(10,2) DEFAULT 0.00` — running totals for ledger integrity
- `caf_meal_card_transactions.balance_after`: `DECIMAL(10,2) NOT NULL` — snapshot AFTER transaction (denormalised for ledger integrity)
- `caf_meal_card_transactions.razorpay_payment_id`: `VARCHAR(100) NULL UNIQUE` — UNIQUE allows NULLs, enforces uniqueness for non-null values only
- `caf_order_items.unit_price`: `DECIMAL(8,2) NOT NULL` — price snapshot at order time (NOT read from caf_menu_items.price later)
- `caf_order_items.line_total`: `DECIMAL(10,2) NOT NULL` — quantity × unit_price (populated at insert time, not GENERATED ALWAYS because unit_price is also stored)
- `caf_pos_transactions.items_json`: `JSON NOT NULL` — snapshot of items sold `[{menu_item_id, name, qty, price}]` — immutable after save
- `caf_pos_transactions.dietary_flags_json`: `JSON NULL` — snapshot of student dietary flags at scan time
- `caf_event_meal_items_jnt.menu_item_id`: `INT UNSIGNED NULL` — nullable when free-text item used
- `caf_subscription_enrollments.staff_id`: `BIGINT UNSIGNED NULL` — staff FK to sys_users; student_id and staff_id are mutually exclusive

**File header comment to include:**
```sql
-- =============================================================================
-- CAF — Cafeteria Module DDL
-- Module: Cafeteria (Modules\Cafeteria)
-- Table Prefix: caf_* (21 tables)
-- Database: tenant_db (one per tenant, no tenant_id columns)
-- Generated: [DATE]
-- Based on: CAF_Cafeteria_Requirement.md v2
-- Sub-Modules: L1 Menu Planning, L2 Orders & Attendance,
--              L3 Meal Cards & POS, L4 Stock & Compliance
-- NOTE: All caf_* PKs and intra-module FKs use INT UNSIGNED (not BIGINT).
--       sys_users references use BIGINT UNSIGNED.
-- =============================================================================
```

### Phase 2B Task — Generate Laravel Migration (`CAF_Migration.php`)

Single migration file for `database/migrations/tenant/YYYY_MM_DD_000000_create_caf_tables.php`.
- `up()`: creates all 21 tables in Layer 1 → Layer 4 dependency order using `Schema::create()`
- `down()`: drops all tables in reverse order (Layer 4 → Layer 1)
- Use `Blueprint` column helpers; match ENUM types with `->enum()`, decimal with `->decimal(10, 2)`, JSON with `->json()`
- All FK constraints added in `up()` using `$table->foreign()`
- Use `$table->unsignedInteger()` for all intra-module FKs (NOT `$table->unsignedBigInteger()`)
- Use `$table->unsignedBigInteger()` ONLY for `created_by`, `published_by`, `opened_by`, `scanned_by`, `staff_id` (all → sys_users)
- Use `$table->unsignedInteger()` for `student_id` (→ std_students), `photo_media_id` (→ sys_media), `fssai_document_media_id` (→ sys_media), `academic_term_id` (→ sch_academic_terms)

### Phase 2C Task — Generate Seeders (1 seeder + 1 runner)

Namespace: `Modules\Cafeteria\Database\Seeders`

**1. `CafMenuCategorySeeder.php`** — 5 seeded meal categories (`is_active=1`):
```
Breakfast  | code: BRK  | meal_time: Breakfast | meal_start_time: 08:00:00 | display_order: 1
Lunch      | code: LNC  | meal_time: Lunch      | meal_start_time: 13:00:00 | display_order: 2
Snacks     | code: SNK  | meal_time: Snacks     | meal_start_time: 16:00:00 | display_order: 3
Dinner     | code: DIN  | meal_time: Dinner     | meal_start_time: 19:30:00 | display_order: 4
Tuck Shop  | code: TUK  | meal_time: Tuck_Shop  | meal_start_time: 10:30:00 | display_order: 5
```

**2. `CafSeederRunner.php`** (Master seeder):
```php
$this->call([
    CafMenuCategorySeeder::class,  // no dependencies
]);
```

### Phase 2 Output Files
| File | Location |
|---|---|
| `CAF_DDL_v1.sql` | `{OUTPUT_DIR}/CAF_DDL_v1.sql` |
| `CAF_Migration.php` | `{OUTPUT_DIR}/CAF_Migration.php` |
| `CAF_TableSummary.md` | `{OUTPUT_DIR}/CAF_TableSummary.md` |
| `Seeders/CafMenuCategorySeeder.php` | `{OUTPUT_DIR}/Seeders/` |
| `Seeders/CafSeederRunner.php` | `{OUTPUT_DIR}/Seeders/` |

### Phase 2 Quality Gate
- [ ] All 21 caf_* tables exist in DDL (8 in Layer 1 + 9 in Layer 2 + 3 in Layer 3 + 1 in Layer 4 = 21 ✓)
- [ ] Standard columns (id, is_active, created_by, created_at, updated_at) on ALL 21 tables; `deleted_at` only on tables that support soft-delete (verify against req Section 5.2)
- [ ] ALL caf_* PKs are `INT UNSIGNED` — NOT `BIGINT UNSIGNED`
- [ ] ALL intra-module FK columns (caf_* → caf_*) are `INT UNSIGNED`
- [ ] `created_by`, `published_by`, `opened_by`, `scanned_by`, `staff_id` (→ sys_users) are `BIGINT UNSIGNED`
- [ ] `student_id` (→ std_students), `photo_media_id` (→ sys_media), `fssai_document_media_id` (→ sys_media), `academic_term_id` are `INT UNSIGNED`
- [ ] `caf_meal_cards.student_id` UNIQUE constraint present
- [ ] `caf_meal_cards.card_number` UNIQUE constraint present
- [ ] `caf_meal_card_transactions.razorpay_payment_id` UNIQUE constraint present (nullable UNIQUE)
- [ ] `caf_daily_menus.menu_date` UNIQUE constraint present
- [ ] `caf_meal_attendance` UNIQUE on `(student_id, meal_date, meal_category_id)` present
- [ ] `caf_daily_menu_items_jnt` UNIQUE on `(daily_menu_id, menu_item_id, meal_category_id)` present
- [ ] `caf_order_items` UNIQUE on `(order_id, menu_item_id)` present
- [ ] `caf_dietary_profiles.student_id` UNIQUE constraint present
- [ ] **No `tenant_id` column** on any table
- [ ] All ENUM columns use exact values from the ENUM list in Phase 2A instructions
- [ ] `caf_meal_card_transactions.balance_after` is `DECIMAL(10,2) NOT NULL` (snapshot, not nullable)
- [ ] `caf_order_items.unit_price` is NOT NULL (price snapshot at order time)
- [ ] `caf_event_meal_items_jnt.menu_item_id` is nullable INT UNSIGNED (free-text items allowed)
- [ ] All FK columns have corresponding KEY index
- [ ] FK naming follows `fk_caf_` convention throughout
- [ ] Migration uses `->unsignedInteger()` for caf_* FKs, `->unsignedBigInteger()` for sys_users refs only
- [ ] CafMenuCategorySeeder has all 5 categories with correct meal_time values
- [ ] `CafSeederRunner.php` calls CafMenuCategorySeeder
- [ ] `CAF_TableSummary.md` has one-line description for all 21 tables

**After Phase 2, STOP and say:**
"Phase 2 (Database Schema Design) complete. Output: `CAF_DDL_v1.sql` + Migration + 2 seeder files. Please review and say 'Approved. Proceed to Phase 3' to continue."

---

## PHASE 3 — Complete Development Plan

### Phase 3 Input Files
1. `{OUTPUT_DIR}/CAF_FeatureSpec.md` — Services (Section 8), permissions (Section 7), tests (Section 11)
2. `{REQUIREMENT_FILE}` — Section 6 (routes), Section 7 (UI screens), Section 12 (tests), Section 15 (module statistics)
3. `{AI_BRAIN}/memory/modules-map.md` — Patterns from completed modules (especially naming conventions)

### Phase 3 Task — Generate `CAF_Dev_Plan.md`

Generate the complete implementation blueprint. Organise into 8 sections:

---

#### Section 1 — Controller Inventory

For each controller, provide:
| Controller Class | File Path | Methods | FR Coverage |
|---|---|---|---|

Derive controllers from req v2 Section 6 (routes). For each controller list:
- All public methods with HTTP method + URI + route name
- Which FormRequest each write method uses
- Which Policy / Gate permission is checked

Controllers to define (16 total, from req v2 Section 2.4 file list):
1. `CafeteriaController` — dashboard (KPI widgets: today's orders, revenue, low-stock count, active card count)
2. `MenuCategoryController` — index, store, show, edit, update, destroy, toggle (is_active)
3. `MenuItemController` — index, store, show, edit, update, destroy, toggleAvailability (AJAX)
4. `WeeklyMenuController` — index, create, store, show, edit, update, publish, archive; `apiCurrentWeek` (API)
5. `EventMealController` — index, store, show, edit, update, publish; class-group filter on portal
6. `DietaryProfileController` — index, store, show, edit, update; `apiGet` + `apiUpdate` (API, parent portal)
7. `SubscriptionPlanController` — index, store, show, edit, update, toggleStatus
8. `SubscriptionEnrollmentController` — index, store, show, destroy (cancel enrollment)
9. `OrderController` — index, show, updateStatus, cancel, kitchenView, printKitchenSheet (DomPDF); `apiStore` + `apiIndex` + `apiCancel` + `apiKitchenView` (API)
10. `PosController` — index, openSession, closeSession, transact, studentLookup; `apiStudentLookup` + `apiTransact` (API)
11. `MealAttendanceController` — index; `apiScan` (API — no auth, idempotent)
12. `MealCardController` — index, store, topup, statement (DomPDF); `apiBalance` + `apiTransactions` + `apiRazorpayTopup` + `apiRazorpayWebhook` (API — webhook has no auth)
13. `StockController` — index, store, show, edit, update, destroy, logConsumption
14. `SupplierController` — index, store, show, edit, update, destroy
15. `FssaiController` — index, store, show; PDF download for license document
16. `CafeteriaReportController` — revenue, orderSummary, wastage, mealCardStatements; CSV/PDF export for each

#### Section 2 — Service Inventory (6 services)

For each service:
- Class name, file path, namespace
- Constructor dependencies (injected services/interfaces)
- All public methods with signature and 1-line description
- Notifications/events fired
- Other services called (dependency graph)

Include the pre-order placement sequence as inline pseudocode in `OrderService`:
```
placeOrder(Student $student, array $orderData): Order
  Step 1: Check menu Published for order_date
  Step 2: Check cutoff window: meal_start_time − caf_order_cutoff_hours > now()
  Step 3: Check dietary conflict (soft warning — student blocked, admin can override)
  Step 4: Compute total_amount from caf_menu_items.price × qty
  Step 5: If payment_mode == 'MealCard':
            MealCardService::deductBalance($card, $total, 'Order', $orderId)
  Step 6: Create caf_orders (status = 'Confirmed')
  Step 7: Create caf_order_items (with unit_price snapshot)
  Step 8: Return Order
```

Include the balance deduction sequence in `MealCardService`:
```
deductBalance(MealCard $card, float $amount, string $referenceType, int $referenceId): MealCardTransaction
  Step 1: DB transaction begins
  Step 2: SELECT...FOR UPDATE on caf_meal_cards row (prevents concurrent double-spend, BR-CAF-012)
  Step 3: If caf_allow_negative_balance=false AND (current_balance − amount) < 0: throw InsufficientBalanceException
  Step 4: Compute new_balance = current_balance − amount
  Step 5: UPDATE caf_meal_cards: current_balance = new_balance, total_debited += amount
  Step 6: INSERT caf_meal_card_transactions (transaction_type='Debit', amount, balance_after=new_balance, reference_type, reference_id)
  Step 7: DB transaction commits
  Step 8: If new_balance < caf_low_balance_threshold: dispatch LowBalanceNotificationJob (queued, BR-CAF-017)
  Step 9: Return MealCardTransaction
```

#### Section 3 — FormRequest Inventory (16 FormRequests)

For each FormRequest:
| Class | Controller Method | Key Validation Rules |
|---|---|---|

Group by controller. 16 total (from req v2 Section 15.4 + inferred):
- `StoreMenuCategoryRequest` — name required, meal_time valid ENUM, code unique if provided
- `StoreMenuItemRequest` — name required, category_id exists in caf_menu_categories, price > 0, food_type valid ENUM
- `StoreDailyMenuRequest` — week_start_date required date, items array with day_date + meal_category_id + menu_item_ids[]
- `StoreEventMealRequest` — name required, event_date required + after:today, meal_category_id exists
- `StoreDietaryProfileRequest` — student_id required + exists in std_students, food_preference valid ENUM
- `StoreOrderRequest` — student_id exists, order_date date + after_or_equal:today, items array min:1, cutoff rule via service
- `IssueMealCardRequest` — student_id exists + no active card (or previous card will be deactivated), card_number unique, valid_from_date required
- `TopUpMealCardRequest` — amount numeric min:50 max:5000, payment_mode in:Online,Cash, razorpay_payment_id nullable + unique
- `StorePosSessionRequest` — session_date required, no other open session for same date + staff
- `StorePosTransactionRequest` — pos_session_id exists + session is open (closed_at IS NULL), items array min:1, payment_mode in:MealCard,Cash
- `StoreSubscriptionPlanRequest` — name required, billing_period valid ENUM, price numeric min:0, included_category_ids_json array + each exists in caf_menu_categories
- `StoreSubscriptionEnrollmentRequest` — subscription_plan_id exists, student_id or staff_id required (not both), start_date required
- `StoreStockItemRequest` — name required, category valid ENUM, unit required, reorder_level numeric min:0
- `LogConsumptionRequest` — stock_item_id exists, quantity_used numeric min:0.001, log_date required date
- `StoreSupplierRequest` — name required, fssai_expiry_date nullable date after:today
- `StoreFssaiRecordRequest` — record_type in:License,Audit, expiry_date nullable date after:today (for License type), audit_score integer 1–10 (for Audit type)

#### Section 4 — Blade View Inventory (~50 views)

List all blade views grouped by sub-module. For each view:
| View File | Route Name | Controller Method | Description |
|---|---|---|---|

Sub-modules and screen counts (from req v2 Section 7 SCR-CAF-01 to SCR-CAF-30):
- Dashboard: 1 view (KPI widgets)
- Menu Planning (Categories, Items, Weekly Planner, Event Meals): ~8 views
- Dietary & Subscriptions (Profiles, Plans, Enrollments): ~6 views
- Orders & Kitchen (Order list, Kitchen view, Kitchen PDF): ~5 views
- POS (Counter interface, Session summary, Student lookup): ~4 views
- Meal Attendance: ~2 views
- Meal Cards (Card list, Top-up, Statement): ~4 views
- Stock & Suppliers (Stock list, Consumption log, Supplier list): ~5 views
- FSSAI Compliance: ~2 views
- Staff Meals: ~2 views
- Reports (Revenue, Orders, Wastage, Statements, FSSAI): ~5 views
- Shared partials: ~6 partials (pagination, export buttons, dietary flag chips, QR display, modal)

For key screens document:
- SCR-CAF-05 (Weekly Menu Planner) — 7-column × N-meal-category grid; Alpine.js drag to assign items; duplicate slot blocked client-side
- SCR-CAF-13 (Kitchen View) — aggregated item totals table; dietary flag chips per count; "Print Kitchen Sheet" → DomPDF PDF
- SCR-CAF-14 (POS Counter) — touch-friendly item grid; QR scan input field; real-time balance display; dietary conflict modal
- SCR-CAF-18 (Meal Card Top-Up) — cash top-up form; "Pay Online" button → Razorpay redirect; balance updated on return
- SCR-CAF-19 (Meal Card Statement) — paginated ledger with balance_after column; "Export PDF" → DomPDF

#### Section 5 — Complete Route List

Consolidate ALL routes from req v2 Section 6 into a single table:
| Method | URI | Route Name | Controller@method | Middleware | FR |
|---|---|---|---|---|---|

Group by section (6.1 Web Routes, 6.2 API Endpoints). Count total routes at the end (target ~62 web + 15 API = ~77).
Middleware on all web routes: `['auth', 'tenant', 'EnsureTenantHasModule:Cafeteria']`
Middleware on API routes: `['auth:sanctum', 'tenant']` except Razorpay webhook: `->withoutMiddleware(['auth:sanctum'])`

Special routes to call out:
- `POST /api/v1/cafeteria/meal-card/topup/webhook` — `->withoutMiddleware(['auth:sanctum'])` (public Razorpay webhook, BR-CAF-011)
- `POST /api/v1/cafeteria/meal-attendance/scan` — idempotent: duplicate scan returns 200 with existing record (BR on UNIQUE constraint)
- `GET /cafeteria/kitchen-view/print` — streams DomPDF PDF response

#### Section 6 — Implementation Phases (6 phases)

For each phase, provide a detailed sprint plan:

**Phase 1 — Menu Planning Masters** (no cross-module deps beyond sys_*):
FRs: CAF-01, CAF-02
Files to create:
- Controllers: CafeteriaController, MenuCategoryController, MenuItemController
- Services: MenuService (category + item CRUD; availability toggle)
- Models: MenuCategory, MenuItem
- FormRequests: StoreMenuCategoryRequest, StoreMenuItemRequest
- Seeders: CafMenuCategorySeeder, CafSeederRunner
- Views: Dashboard, Menu Category list/form, Menu Item list/form (~5 views)
- Tests: MenuCategoryCrudTest, MenuItemCrudTest

**Phase 2 — Weekly Menu & Event Meals** (requires Phase 1: caf_menu_categories, caf_menu_items):
FRs: CAF-03, CAF-04
Files to create:
- Controllers: WeeklyMenuController, EventMealController
- Services: MenuService (publish + archive + notify NTF + cutoff check)
- Models: DailyMenu, DailyMenuItemJnt, EventMeal, EventMealItemJnt
- FormRequests: StoreDailyMenuRequest, StoreEventMealRequest
- Events: MenuPublished
- Artisan: `caf:archive-old-menus` (daily)
- Views: Weekly planner grid, menu list, event meal planner (~5 views)
- Tests: WeeklyMenuPublishTest, MenuPublishBlockedTest, EventMealPublishTest

**Phase 3 — Orders, Dietary & Subscriptions** (requires Phase 2: daily_menus; requires STD: std_students):
FRs: CAF-05, CAF-06, CAF-07
Files to create:
- Controllers: DietaryProfileController, SubscriptionPlanController, SubscriptionEnrollmentController, OrderController
- Services: OrderService (place, cancel, kitchen consolidation, DomPDF kitchen sheet)
- Models: DietaryProfile, SubscriptionPlan, SubscriptionEnrollment, Order, OrderItem
- FormRequests: StoreDietaryProfileRequest, StoreSubscriptionPlanRequest, StoreSubscriptionEnrollmentRequest, StoreOrderRequest
- Views: Dietary profiles list/form, subscription plan list, enrollment list, order list, kitchen view, kitchen PDF (~10 views)
- API routes: apiStore, apiIndex, apiCancel (portal orders); apiCurrentWeek (menu); apiKitchenView
- Tests: OrderPlacementTest, OrderCutoffTest, DietaryConflictWarningTest, OrderCancellationRefundTest, KitchenConsolidationTest, SubscriptionEnrollmentTest

**Phase 4 — Meal Cards & POS** (requires Phase 3: caf_orders; requires Razorpay):
FRs: CAF-08, CAF-09, CAF-10
Files to create:
- Controllers: MealCardController, MealAttendanceController, PosController
- Services: MealCardService (deductBalance SELECT...FOR UPDATE, creditBalance, Razorpay, QR gen, DomPDF statement), PosService (session, transaction, student lookup, dietary alert)
- Jobs: LowBalanceNotificationJob
- Models: MealCard, MealCardTransaction, MealAttendance, PosSession, PosTransaction
- FormRequests: IssueMealCardRequest, TopUpMealCardRequest, StorePosSessionRequest, StorePosTransactionRequest
- Views: Card list, top-up form, statement (~4 views); POS interface, session summary, student lookup (~4 views); Attendance log
- API routes: apiBalance, apiTransactions, apiRazorpayTopup, apiRazorpayWebhook (no auth), apiScan, apiStudentLookup, apiTransact
- Tests: MealCardTopUpCashTest, RazorpayWebhookTest, MealCardNegativeBalanceTest, PosSessionTest, QrAttendanceScanTest, MealCardTransactionLedgerTest, OrderNumberFormatTest

**Phase 5 — Stock, Suppliers & FSSAI** (no new cross-module deps):
FRs: CAF-11, CAF-12
Files to create:
- Controllers: StockController, SupplierController, FssaiController
- Services: StockService (deduct qty, reorder alert, INV bridge, DomPDF FSSAI log)
- Jobs: StockReorderAlertJob
- Models: Supplier, StockItem, ConsumptionLog, FssaiRecord
- FormRequests: StoreStockItemRequest, LogConsumptionRequest, StoreSupplierRequest, StoreFssaiRecordRequest
- Events: StockReorderAlert
- Artisan: `caf:check-stock-reorder` (daily), `caf:send-fssai-alerts` (daily)
- Views: Stock list, consumption log, supplier list, FSSAI compliance (~5 views)
- Tests: StockReorderAlertTest, FssaiExpiryAlertTest

**Phase 6 — Staff Meals, Reports & Integration** (requires all prior phases):
FRs: CAF-13, CAF-14, CAF-15
Files to create:
- Controllers: CafeteriaReportController
- Services: ReportService (revenue, orders, wastage, statements; fputcsv + DomPDF)
- Models: StaffMealLog
- Views: Revenue, Order Summary, Wastage, Statements reports; Staff Meal Log (~7 views)
- Artisan: `caf:send-low-balance-alerts` (triggered per transaction, not scheduled)
- Portal views: SCR-CAF-27 (Menu View), SCR-CAF-28 (Order Screen), SCR-CAF-29 (Consumption History)
- HST bridge: ensure `HostelAdmissionListener` creates caf_subscription_enrollments when `caf_hostel_auto_enroll=true`
- Tests: StaffMealLogTest, RevenueReportTest

#### Section 7 — Seeder Execution Order

```
php artisan module:seed Cafeteria --class=CafSeederRunner
  ↓ CafMenuCategorySeeder   (no dependencies — 5 meal categories)
```

For test runs: use `CafMenuCategorySeeder` as minimum required seeder (meal_category_id FK required by almost all tables).
For Phase 3+ tests: add student factory from STD module.
For Phase 4 tests: add `MealCardFactory` (uses student from STD).

Artisan scheduled commands (register in `routes/console.php`):
```
caf:archive-old-menus       → daily midnight (archives published menus from prior week)
caf:send-fssai-alerts       → daily morning (30+7 day supplier; 60+30 day school)
caf:check-stock-reorder     → daily morning (or triggered per consumption log)
caf:send-low-balance-alerts → NOT scheduled — triggered by MealCardService::deductBalance() per transaction
```

#### Section 8 — Testing Strategy

**Framework:** Pest for Feature tests; PHPUnit for Unit tests.

**Feature Test Setup:**
```php
uses(Tests\TestCase::class, RefreshDatabase::class);
// All feature tests use tenant DB refresh
// Menu publish notifications: Notification::fake() in WeeklyMenuPublishTest
// Low balance notification: Queue::fake() in LowBalanceNotificationTest
// Reorder alert: Queue::fake() + Event::fake() in StockReorderAlertTest
// Razorpay webhook: test with known HMAC-SHA256 signature; duplicate payment_id must return 422 or 200 idempotent
// MealCard SELECT...FOR UPDATE: use real DB transaction test — cannot be mocked with SQLite (use tenant DB)
// Bus::fake() for Artisan command dispatch tests
```

**Minimum Test Coverage Targets:**
- BR-CAF-003 (negative balance prevention): explicitly tested in MealCardNegativeBalanceTest
- BR-CAF-004 (one card per student): UNIQUE constraint test in IssueMealCardTest
- BR-CAF-011 (Razorpay idempotency): duplicate webhook returns success without double-credit
- BR-CAF-012 (atomic deduction): concurrent order test with row-lock verification
- BR-CAF-018 (UNIQUE menu_date): duplicate daily menu insert rejected at DB level
- Order cutoff enforcement: order at T+1min past cutoff is rejected (BR-CAF-001)
- Dietary conflict: Jain student ordering Non-Veg shows warning; admin override works; student cannot override
- Kitchen view consolidation: subscription-enrolled students counted in headcount without explicit order
- QR attendance idempotency: duplicate scan returns success without creating duplicate record

**Feature Test File Summary (from req v2 Section 12):**
List all 22 test classes with file path, test count, and key scenarios covering all items in Section 12 test scenarios table.

**Unit Test File Summary:**
- `MealCardTransactionLedgerTest` — balance_after on each transaction equals prior balance ± amount (ledger integrity)
- `OrderNumberFormatTest` — order number matches regex `CAF-\d{4}-[A-Z0-9]{8}`

**Factory Requirements:**
```
MenuCategoryFactory     — creates category with meal_time, display_order; seeded set preferred over factory
MenuItemFactory         — generates item with food_type, price, is_available=1, linked to category
DailyMenuFactory        — generates menu_date (future date), status=Draft
MealCardFactory         — generates card_number (CAF-CARD-XXXXXXXX), current_balance=500.00, linked student
OrderFactory            — generates order_number (CAF-YYYY-XXXXXXXX), status=Confirmed, student + card + meal_category
```

---

### Phase 3 Output Files
| File | Location |
|---|---|
| `CAF_Dev_Plan.md` | `{OUTPUT_DIR}/CAF_Dev_Plan.md` |

### Phase 3 Quality Gate
- [ ] All 16 controllers listed with all methods (web + API methods on same controller)
- [ ] All 6 services listed with at least 3 key method signatures each
- [ ] `OrderService` pseudocode present (8-step pre-order placement sequence)
- [ ] `MealCardService::deductBalance()` pseudocode present (9-step atomic deduction sequence)
- [ ] All 16 FormRequests listed with their key validation rules
- [ ] All 15 FRs (CAF-01 to CAF-15) appear in at least one implementation phase
- [ ] All 6 implementation phases have: FRs covered, files to create, test count
- [ ] Seeder execution order documented (CafMenuCategorySeeder only; no dependencies)
- [ ] All 4 Artisan commands listed with schedule (note: low-balance alert is NOT scheduled)
- [ ] Route list consolidated with middleware and FR reference (~77 routes total)
- [ ] Razorpay webhook route explicitly marked `->withoutMiddleware(['auth:sanctum'])`
- [ ] View count per sub-module totals approximately 50
- [ ] Test strategy includes `Queue::fake()` for LowBalanceNotificationJob and StockReorderAlertJob
- [ ] Test strategy includes `Notification::fake()` for MenuPublished notification
- [ ] BR-CAF-003 (negative balance) test explicitly referenced
- [ ] BR-CAF-011 (Razorpay idempotency) test explicitly referenced
- [ ] BR-CAF-012 (atomic deduction via SELECT...FOR UPDATE) concurrency test noted
- [ ] `caf_meal_attendance` QR scan idempotency test explicitly referenced
- [ ] INT UNSIGNED migration helpers (`->unsignedInteger()`) verified vs BIGINT (`->unsignedBigInteger()`) throughout
- [ ] HST bridge enrollment flow documented in Phase 6 with school setting check
- [ ] INV bridge PR creation documented with graceful degradation when INV not licensed

**After Phase 3, STOP and say:**
"Phase 3 (Development Plan) complete. Output: `CAF_Dev_Plan.md`. All 3 output files are ready:
1. `{OUTPUT_DIR}/CAF_FeatureSpec.md`
2. `{OUTPUT_DIR}/CAF_DDL_v1.sql` + Migration + 2 Seeders
3. `{OUTPUT_DIR}/CAF_Dev_Plan.md`
Development lifecycle for CAF (Cafeteria) module is ready to begin."

---

## QUICK REFERENCE — CAF Module Tables vs Controllers vs Services

| Domain | caf_* Tables | Controller(s) | Service(s) |
|---|---|---|---|
| Menu Categories | caf_menu_categories | MenuCategoryController | MenuService |
| Menu Items | caf_menu_items | MenuItemController | MenuService |
| Menu Planning | caf_daily_menus, caf_daily_menu_items_jnt | WeeklyMenuController | MenuService |
| Event Meals | caf_event_meals, caf_event_meal_items_jnt | EventMealController | MenuService |
| Dietary Profiles | caf_dietary_profiles | DietaryProfileController | OrderService (conflict check) |
| Subscriptions | caf_subscription_plans, caf_subscription_enrollments | SubscriptionPlanController, SubscriptionEnrollmentController | — (direct in controller) |
| Orders | caf_orders, caf_order_items | OrderController | OrderService, MealCardService |
| Meal Attendance | caf_meal_attendance | MealAttendanceController | — (direct insert + idempotent) |
| POS | caf_pos_sessions, caf_pos_transactions | PosController | PosService, MealCardService |
| Meal Cards | caf_meal_cards, caf_meal_card_transactions | MealCardController | MealCardService |
| Stock & Suppliers | caf_suppliers, caf_stock_items, caf_consumption_logs | StockController, SupplierController | StockService |
| FSSAI | caf_fssai_records | FssaiController | StockService (expiry alerts) |
| Staff Meals | caf_staff_meal_logs | CafeteriaReportController | ReportService |
| Reports | (reads all caf_* tables) | CafeteriaReportController | ReportService |
| Dashboard | (aggregates) | CafeteriaController | — (direct queries) |
