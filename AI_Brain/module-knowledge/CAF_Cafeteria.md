# Module Knowledge: Cafeteria (CAF)
# Last Updated: 2026-06-27 (update pass — file counts verified against Herd/prime_ai)
# Completion Status: ~60–65% (all controllers/services/policies present; 95 views; 21 models; 1 test only — critical gap; 0 jobs)

---

## Module Facts

| Item | Value |
|------|-------|
| Table prefix | `caf_*` |
| DDL (canonical) | `2-DDL_Tenant_Consolidated/Cafeteria_DDL_v1.sql` — 21 tables |
| V2 Requirement | `4-Requirement_Module_wise/4-Initial_Requirements/V2/CAF_Cafeteria_Requirement.md` |
| Routes | **147 lines** in `Modules/Cafeteria/routes/web.php` (re-verified 2026-06-27; prior estimate was ~77) |
| Controllers | **16** actual (re-verified — matches proposed exactly) |
| Models | **21** actual (re-verified — **corrected from 17**; all DDL tables have dedicated models including junctions/logs) |
| Services | **6** actual (re-verified — matches proposed exactly): CafeteriaReportService, MealCardService, MenuService, OrderService, PosService, StockService |
| FormRequests | **19** actual (re-verified — **corrected from 16**; 3 extra: TopUpMealCardRequest, UpdateMealCardRequest, UpdateSubscriptionEnrollmentRequest) |
| Policies | **14** actual (re-verified — matches proposed exactly) |
| Blade Views | **95** actual (re-verified — **corrected from ~50**; nearly double the proposed count) |
| Tests | **1 file** actual (`tests/Feature/CafeteriaReportControllerTest.php` — **22 proposed, only 1 exists**) |
| Jobs | **0** actual — no queued jobs created (NTF alerts, FSSAI expiry, menu archive all unqueued) |
| Migrations | **0** — module uses DDL directly |
| Business Rules | 36 in FRD (BR-CAF-001..019 preserved from V2; BR-CAF-020..036 added) |
| Permissions | 21 permission slugs |
| FRD | Generated 2026-06-29 → `0-FRD_Documents/CAF_FRD_2026-06-29.md` (v1.0) |

---

## FRD Summary

| Item | Value |
|------|-------|
| FRD file | `4-Requirement_Module_wise/0-FRD_Documents/CAF_FRD_2026-06-29.md` (flat location) |
| Date / Version | 2026-06-29 / v1.0 (fresh — no prior FRD existed) |
| Functional Requirements (REQ-) | 16 (REQ-CAF-001..016, mapping 1:1 to the 16 feature groups) |
| Business Rules (BR-) | 36 (BR-CAF-001..019 preserved from V2/knowledge; 020..036 added for counter-session, immutability, price-snapshot, category-delete, profile-upsert, food-cost, staff/net-revenue rules) |
| Workflows | 9 (Menu Publish, Pre-Order, Cancel/Refund, Wallet Top-Up, Counter Sale, QR Attendance, Stock Reorder, Hostel Mess Auto-Enrol, FSSAI Expiry) |
| Reports (RPT-) | 9 (Revenue, Daily Sales, Order Summary, Wastage, Wallet Statement, FSSAI Audit, Subscription Enrolment, Attendance Summary, Kitchen Prep Sheet) |
| Enhancements (ENH-) | 10 (ENH-CAF-001..010, from V2 SUG-CAF-01..10) |
| Priority split | P0=6, P1=6, P2=4 |
| Section 10.4 | Reconciled: 16 REQ / 36 BR / 9 WF / 9 RPT / 10 ENH |
| Note | BR IDs in FRD are the new downstream contract; BR-CAF-014 in FRD merges school (60/30d) + supplier (30/7d) FSSAI reminders into one shared rule referenced by REQ-CAF-013 & 014. |

**Model inventory (all 21):**
`ConsumptionLog`, `DailyMenu`, `DailyMenuItemJnt`, `DietaryProfile`, `EventMeal`, `EventMealItemJnt`, `FssaiRecord`, `MealAttendance`, `MealCard`, `MealCardTransaction`, `MenuCategory`, `MenuItem`, `Order`, `OrderItem`, `PosSession`, `PosTransaction`, `StaffMealLog`, `StockItem`, `SubscriptionEnrollment`, `SubscriptionPlan`, `Supplier`

**FormRequest inventory (all 19):**
Store: MenuCategory, MenuItem, DailyMenu, EventMeal, DietaryProfile, FssaiRecord, SubscriptionPlan, SubscriptionEnrollment *(+Update)*, Order, StockItem, PosSession, PosTransaction, Supplier; MealCard specific: IssueMealCard, UpdateMealCard, DeductMealCard, TopUpMealCard; Consumption: LogConsumption

---

## DDL Layer Structure (21 tables)

| Layer | Tables |
|-------|--------|
| Layer 1 (no caf_* deps) | `caf_menu_categories`, `caf_suppliers`, `caf_fssai_records`, `caf_daily_menus`, `caf_subscription_plans`, `caf_meal_cards`, `caf_pos_sessions`, `caf_dietary_profiles` |
| Layer 2 (deps Layer 1 + cross-module) | `caf_menu_items`, `caf_stock_items`, `caf_event_meals`, `caf_subscription_enrollments`, `caf_meal_card_transactions`, `caf_meal_attendance`, `caf_pos_transactions`, `caf_staff_meal_logs`, `caf_orders` |
| Layer 3 (deps Layer 2) | `caf_daily_menu_items_jnt`, `caf_event_meal_items_jnt`, `caf_consumption_logs` |
| Layer 4 (deps Layer 3) | `caf_order_items` |

---

## Feature Groups

| FR | Feature | Tables | Priority |
|----|---------|--------|----------|
| FR-CAF-01 | Menu Category Management | `caf_menu_categories` | Critical |
| FR-CAF-02 | Menu Item Master (nutrition + allergens) | `caf_menu_items` | Critical |
| FR-CAF-03 | Weekly Menu Planning & Publish | `caf_daily_menus`, `caf_daily_menu_items_jnt` | Critical |
| FR-CAF-04 | Special / Event Meal Management | `caf_event_meals`, `caf_event_meal_items_jnt` | High |
| FR-CAF-05 | Student Dietary Profile | `caf_dietary_profiles` | Critical |
| FR-CAF-06 | Meal Subscription Plans | `caf_subscription_plans`, `caf_subscription_enrollments` | High |
| FR-CAF-07 | Meal Pre-Ordering (Portal) | `caf_orders`, `caf_order_items` | Critical |
| FR-CAF-08 | Kitchen Consolidated View | `caf_orders`, `caf_order_items` (aggregated read) | Critical |
| FR-CAF-09 | POS Counter Interface | `caf_pos_sessions`, `caf_pos_transactions` | High |
| FR-CAF-10 | QR-Based Meal Attendance | `caf_meal_attendance` | High |
| FR-CAF-11 | Meal Card Management | `caf_meal_cards`, `caf_meal_card_transactions` | High |
| FR-CAF-12 | Raw Material Stock Management | `caf_stock_items`, `caf_consumption_logs`, `caf_suppliers` | High |
| FR-CAF-13 | Supplier Management (CAF-side) | `caf_suppliers` | Medium |
| FR-CAF-14 | FSSAI Compliance Tracking | `caf_fssai_records` | Medium |
| FR-CAF-15 | Staff Meal Management | `caf_staff_meal_logs` | Medium |
| FR-CAF-16 | Cafeteria Dashboard & Reports | aggregated reads | Medium |

---

## Known Gaps & Open Issues

### Implementation Blockers (Prerequisites)

| # | Prerequisite | Owner Module | Blocks |
|---|-------------|-------------|--------|
| P1 | `std_students` table complete | StudentProfile (STD) | dietary_profiles, orders, meal_cards, meal_attendance |
| P2 | `sch_academic_terms` table complete | SchoolSetup (SCH) | daily_menus, subscription_plans |
| P3 | `sys_users`, `sys_media` complete | System (SYS) | All created_by columns, dish photos, FSSAI documents |
| P4 | NTF module complete | Notification (NTF) | Menu publish notify, low-balance alert, reorder alert, FSSAI expiry alert |
| P5 | HST module complete | Hostel (HST) | Auto-enrollment in hostel mess plan on hostel admission (BR-CAF-015) |
| P6 | INV module licensed | Inventory (INV) | Optional: auto purchase requisition on stock reorder (BR-CAF-007) |
| P7 | Razorpay gateway configured | System Config | Online meal card top-up (FR-CAF-11); follows FIN module payment pattern |

### DDL vs Requirement Differences

1. **`sys_users` type correction**: Requirement doc claims `BIGINT UNSIGNED` for sys_users FKs. DDL corrects to `INT UNSIGNED` (verified: `sys_users.id = INT UNSIGNED` in tenant_db). All `created_by`, `opened_by`, `staff_id`, `scanned_by`, `published_by` columns are `INT UNSIGNED`.

2. **`billing_period` ENUM expanded**: `caf_subscription_plans.billing_period` DDL adds `'Quarterly'` (enum: Monthly/Quarterly/Termly/Annual). Requirement doc only lists Monthly/Termly/Annual. DDL is authoritative.

3. **`sch_academic_terms` type**: `academic_term_id` columns use `SMALLINT UNSIGNED` (verified: `sch_academic_term.id = SMALLINT UNSIGNED`).

### Immutable Records (No deleted_at)

| Table | Reason |
|-------|--------|
| `caf_fssai_records` | Compliance records — must never be deleted |
| `caf_meal_card_transactions` | Financial ledger — immutable; no deleted_at |
| `caf_meal_attendance` | Immutable scan record; also no updated_at, no is_active |
| `caf_pos_transactions` | Transactional; immutable after save; no is_active, no deleted_at |
| `caf_staff_meal_logs` | Transactional log; no is_active, no deleted_at |
| `caf_order_items` | Line item; no is_active, no created_by, no deleted_at |
| `caf_daily_menu_items_jnt` | Junction table; no deleted_at |
| `caf_event_meal_items_jnt` | Junction table; no deleted_at |
| `caf_consumption_logs` | Usage log; no is_active, no deleted_at |
| `caf_pos_sessions` | No deleted_at; no created_by (opened_by serves as creator) |

---

## Design Decisions Made

1. **Meal card balance deduction uses SELECT...FOR UPDATE**: `MealCardService` wraps every deduction (order placement, POS transaction) in a DB transaction with row-level lock (`SELECT ... FOR UPDATE`) to prevent concurrent double-spend. This is the concurrency safety contract — do not bypass it.

2. **`caf_order_items.unit_price` is a price snapshot**: The unit price at order time is stored in `unit_price` column. **Never re-read `caf_menu_items.price` after order placement.** Price changes after ordering do not affect existing orders.

3. **`caf_daily_menus` has UNIQUE on `menu_date` (BR-CAF-018)**: Only one menu record per calendar date. The planner grid edits the existing record, not creates new ones per edit.

4. **`caf_meal_attendance` UNIQUE on `(student_id, meal_date, meal_category_id)` (BR-CAF-010)**: QR scan is idempotent — duplicate scans silently return "already recorded" (HTTP 200) without error.

5. **`caf_meal_card_transactions.razorpay_payment_id` UNIQUE (BR-CAF-011)**: Webhook idempotency enforced at DB level. Duplicate Razorpay payment IDs are rejected by UNIQUE constraint before any balance update occurs.

6. **POS session model — no created_by**: `caf_pos_sessions.opened_by` serves as both the session owner and creator context. No separate `created_by` column exists on this table.

7. **`caf_fssai_records` is a polymorphic single table**: `record_type ENUM('License','Audit')` discriminates license records (with license_number, expiry_date) from audit records (with audit_date, audit_score). No deleted_at — compliance records are never soft-deleted.

8. **`caf_event_meal_items_jnt.menu_item_id` is nullable**: Event meals can include free-text items not in the dish library (`free_text_item VARCHAR(150)`). `menu_item_id` is NULL when a free-text item is used. No UNIQUE key beyond PK — free-text items can "duplicate" a dish-library entry.

9. **`caf_dietary_profiles` UNIQUE on `student_id` — upsert pattern**: One profile per student; `DietaryProfileController::store()` uses upsert / findOrCreate logic. Parent can update child's profile via Parent Portal; change is logged.

10. **Subscription headcount included in kitchen view (BR-CAF-010)**: Kitchen consolidated view must include subscription-enrolled students as pre-confirmed even when no explicit `caf_orders` record exists for that day. This requires a union/left-join query, not just aggregate of orders.

11. **Staff payroll deduction is a flag only (BR-CAF-019)**: `caf_staff_meal_logs.payroll_deduction_flag = 1` signals the PAY module. CAF never writes to `pay_*` tables. The actual deduction is processed by Payroll.

12. **Hostel mess plan auto-enrollment bridge (BR-CAF-015)**: When a student is admitted to the hostel, the HST module triggers a CAF bridge service that creates a `caf_subscription_enrollments` record linked to the active hostel mess plan. Deducts plan price from the student's meal card.

---

## State Machine Summaries

| FSM | States |
|-----|--------|
| Weekly Menu | `Draft` → `Published` (triggers NTF notification) → `Archived` (scheduler on week change) |
| Event Meal | `Draft` → `Published` (triggers NTF notification) → `Archived` |
| Pre-Order | `Confirmed` (placed) → `Served` (kitchen marks) / `Cancelled` (before cutoff; meal card refunded) |
| POS Session | `Opened` → `Active` (transactions) → `Closed` (daily summary) |
| Subscription Enrollment | `Active` → `Paused` / `Cancelled` (pro-rata refund calc) / `Expired` |

---

## Key Business Rules

| Rule | Summary |
|------|---------|
| BR-CAF-001 | Order cutoff = `meal_start_time` − `caf_order_cutoff_hours` (school setting, default 2h) |
| BR-CAF-002 | Dietary conflict (Jain/nut-allergy vs food type) = soft block; admin can override; student cannot |
| BR-CAF-003 | Balance cannot go negative when `caf_prepaid_only_mode = true` |
| BR-CAF-004 | One active meal card per student — UNIQUE on `student_id` in `caf_meal_cards` |
| BR-CAF-005 | Weekly menu publish blocked if no items assigned to any slot |
| BR-CAF-006 | Publishing weekly/event menu dispatches push/SMS to all active students and parents |
| BR-CAF-007 | `current_quantity ≤ reorder_level` → in-app alert to CAFETERIA_MGR; INV bridge if licensed |
| BR-CAF-008 | Order cancellation: before cutoff only + status = Confirmed; meal card refunded immediately |
| BR-CAF-009 | Kitchen view shows only Confirmed orders for selected date + meal_category |
| BR-CAF-010 | Subscription students pre-counted in kitchen headcount without explicit order record |
| BR-CAF-011 | Razorpay webhook idempotency: duplicate `razorpay_payment_id` rejected by UNIQUE constraint |
| BR-CAF-012 | Balance deduction: `SELECT ... FOR UPDATE` + single DB transaction (anti-double-spend) |
| BR-CAF-013 | POS transactions require an open (not closed) POS session |
| BR-CAF-014 | Supplier FSSAI alert at 30d + 7d before expiry; School FSSAI alert at 60d + 30d before expiry |
| BR-CAF-015 | Hostel admission auto-creates `caf_subscription_enrollments` for hostel mess plan |
| BR-CAF-016 | Event meals with `target_class_ids_json` visible only to targeted class students |
| BR-CAF-017 | Low balance notification to parent when balance < `caf_low_balance_threshold` (default ₹100) |
| BR-CAF-018 | UNIQUE on `caf_daily_menus.menu_date` — one menu record per calendar date |
| BR-CAF-019 | `payroll_deduction_flag = 1` is a signal to PAY; CAF never writes to pay_* tables |

---

## Cross-Module Dependencies

### Inbound (CAF reads from / integrates with)

| Module | Tables / Channels | Integration Point |
|--------|------------------|-------------------|
| StudentProfile (STD) | `std_students` | dietary_profiles, orders, meal_cards, meal_attendance, pos_transactions, subscription_enrollments |
| SchoolSetup (SCH) | `sch_academic_terms` | daily_menus, subscription_plans |
| System (SYS) | `sys_users`, `sys_media`, `sys_activity_logs` | Auth, staff FKs, dish photo + FSSAI doc uploads, audit trail |
| Notification (NTF) | NTF dispatch | Menu publish, event meal publish, low-balance, reorder, FSSAI expiry alerts |
| Hostel (HST) | Bridge event | Hostel admission event triggers CAF mess plan auto-enrollment |
| Inventory (INV) | Bridge service (optional) | Stock reorder triggers INV purchase requisition if `caf_inv_integration = true` |
| Finance (FIN) | Razorpay config pattern | Online meal card top-up follows FIN gateway config |
| Payroll (PAY) | Signal only | `payroll_deduction_flag`; CAF never writes to pay_* |

### Outbound (Modules that depend on CAF)

| Module | What It Reads |
|--------|--------------|
| STP (Student Portal) | Published weekly menu, pre-order form, own orders, card balance |
| PPT (Parent Portal) | Published weekly menu, order on behalf, card top-up, consumption history |
| INV (Inventory) | Receives purchase requisition when stock reorder triggered |
| PAY (Payroll) | Reads `payroll_deduction_flag` from `caf_staff_meal_logs` |

---

## Technology Stack Notes

- **QR Codes**: `SimpleSoftwareIO/simple-qrcode` — used for meal card QR code generation
- **PDF Generation**: DomPDF — kitchen preparation sheet, meal card statement, FSSAI audit log
- **Concurrency**: `SELECT ... FOR UPDATE` on `caf_meal_cards` for all balance deductions
- **Queues**: Laravel Queue (database driver) — menu publish notification, low-balance alert, reorder alert, FSSAI expiry alert
- **Razorpay**: Webhook endpoint `/api/v1/cafeteria/meal-card/topup/webhook` requires no auth; signature verification in service layer

---

## School Settings Required (`sys_school_settings`)

| Key | Default | Description |
|-----|---------|-------------|
| `caf_order_cutoff_hours` | 2.00 | Hours before meal_start_time when ordering closes |
| `caf_allow_negative_balance` | false | Whether meal card can go below zero |
| `caf_low_balance_threshold` | 100.00 | INR threshold for low-balance parent notification |
| `caf_prepaid_only_mode` | true | Disallow counter payment; enforce prepaid meal card |
| `caf_parent_scan_notification` | false | Notify parent on child's QR scan at counter |
| `caf_hostel_auto_enroll` | true | Auto-enroll hostel students in hostel mess plan |
| `caf_inv_integration` | false | Create INV purchase requisition on stock reorder |

---

## Implementation Sequence (Recommended)

| Phase | Components |
|-------|-----------|
| Prerequisites | SYS + SCH + STD complete; NTF ready |
| CAF Phase 1 | Masters: Menu Categories + Menu Items + Dietary Profiles |
| CAF Phase 2 | Menu Planning: Weekly Menus + Event Meals + Publish workflow |
| CAF Phase 3 | Meal Cards: Issuance + Top-up + Transaction ledger + Razorpay webhook |
| CAF Phase 4 | Orders: Pre-ordering + Cutoff enforcement + Kitchen View + Order cancellation |
| CAF Phase 5 | POS: Sessions + Counter interface + QR scan + Meal Attendance |
| CAF Phase 6 | Subscriptions: Plans + Enrollment + HST bridge (requires HST) |
| CAF Phase 7 | Stock & Compliance: Raw material stock + Consumption logs + Suppliers + FSSAI records |
| CAF Phase 8 | Staff Meals + Reports + Dashboard KPIs |

---

## Known Gaps & Open Issues (as of 2026-06-27)

| Priority | Gap | Detail |
|----------|-----|--------|
| P1 | **1 test file only** | 22 test classes proposed; only `CafeteriaReportControllerTest` exists. Meal card balance deduction (`SELECT...FOR UPDATE` concurrency), order cutoff enforcement, dietary conflict logic, webhook idempotency, and QR scan deduplication are all high-risk without tests. |
| P1 | **0 queued jobs** | Menu publish notification, low-balance parent alert, FSSAI expiry alert (30d/7d), and menu auto-archive were specified as queued operations. No `Jobs/` directory exists — these are likely fired synchronously from controllers or not implemented. |
| P1 | **0 migrations** | Module uses DDL directly; tenant migrations directory empty. Cannot bootstrap a fresh tenant via `artisan migrate`. |
| P2 | **No Events/Listeners** | No `Events/` or `Listeners/` directory. NTF dispatch on menu publish (BR-CAF-005/006) and hostel mess plan auto-enrollment (BR-CAF-015) may be called directly from controllers rather than via Laravel events — needs audit. |
| P2 | **Controller logic completeness unknown** | 16 controllers present but internal logic (cutoff enforcement, concurrency locks, FSM transitions) unverified. Technical Audit needed. |
| P2 | **Razorpay webhook not confirmed** | Meal card top-up via Razorpay (`TopUpMealCardRequest` exists) — webhook route and signature verification implementation unverified. |
| P3 | **HST bridge service** | `BR-CAF-015` requires HST module to trigger CAF auto-enrollment on hostel admission. No bridge service or listener found; depends on HST module completion status. |
| P3 | **INV bridge** | Stock reorder → INV purchase requisition bridge (when `caf_inv_integration = true`) — not confirmed implemented. |

---

## Known Gaps & Open Issues (Technical Audit 2026-06-29)

> Full report: `3-Audit_Reports/V1_Jun-2026/Cafeteria_Technical_Audit_2026-06-29.md`. Health 62/100, no P0 (not capped). Codes continue from prior max (only SEC-CAF-001 pre-existed → SEC starts 002).

| Code | Severity | Title | Location |
|------|----------|-------|----------|
| SEC-CAF-002 | P1 | Write-side IDOR — arbitrary `student_id` on sanctum API (order/scan/dietary) — extends SEC-CAF-001 | `OrderController.php:83-93`, `StoreOrderRequest.php:20`, `MealAttendanceController.php:24`, `DietaryProfileController.php:112` |
| SEC-CAF-003 | P1 | All 19 FormRequests `authorize(){ return true; }` (D30) | `app/Http/Requests/*` |
| DAT-CAF-001 | P1 | Order-cancel double-refund race (no `lockForUpdate`/re-check on order) | `OrderService.php:116-139` |
| JOB-CAF-001 | P1 | Scheduled commands run central — no `tenants:run` | `app/Providers/CafeteriaServiceProvider.php:111-117` |
| BUG-CAF-001 | P2 | Dietary-conflict (BR-CAF-002) not enforced in order/POS write path (child-safety) | `OrderService.php:29`, `PosService.php:44` |
| BUG-CAF-002 | P2 | NTF dispatch stubbed — BR-CAF-007/014/017 compute but never notify | `StockService.php:60,136`, `MealCardService.php:101-104` |
| VAL-CAF-001 | P2 | BR-CAF-020 unenforced — multiple open POS sessions/day allowed | `PosService.php:23-29` |
| SCH-CAF-001 | P2 | D29 — ~15 ENUM columns in CAF DDL instead of `sys_dropdown_table` FKs | `Cafeteria_DDL_v1.sql` (multiple) |
| FE-CAF-001 | P2 | `json_encode()` chart payloads w/o `JSON_HEX_*` (staff-entered names) | `reports-page/index.blade.php:123-283`, `pages/dashboard.blade.php:276` |
| DEAD-CAF-001 | P3 | Duplicate dead `CafeteriaServiceProvider` at module root `/Providers/` | `Modules/Cafeteria/Providers/CafeteriaServiceProvider.php` |
| DAT-CAF-002 | P3 | Wallet balance columns in `$fillable` (latent ledger bypass; not currently reachable) | `MealCard.php:19-22` |
| BUG-CAF-003 | P3 | Order cutoff silently skipped when category `meal_start_time` is NULL | `OrderService.php:212-216` |

**Strengths confirmed (do not regress):** full tenancy stack on web+API RSP; `SELECT…FOR UPDATE` on wallet debit/credit/refund; order price snapshot (`unit_price`); idempotent QR attendance (`firstOrCreate`+`uq_caf_ma`); Razorpay idempotency (`exists()`+`uq_caf_mct_razorpay`); **zero `$request->all()` sites** (uses `validated()` everywhere); every controller method gated.

## Lessons Learned

- [2026-06-29 | Technical Auditor] **"0 migrations" claim is STALE.** 22 `create_caf_*` migrations exist in `database/migrations/tenant/` (dated 2026-06-15). Tenant migrations are CENTRALIZED, not per-module — an empty `Modules/Cafeteria/database/migrations/` (only `.gitkeep`) is the expected architecture, NOT a gap. Always check `database/migrations/tenant/` before flagging missing migrations. Layer 2 is Green.
- [2026-06-29 | Technical Auditor] **"0 jobs" is half-true.** No *queued* jobs, but 3 Artisan commands (`caf:archive-old-menus`, `caf:send-fssai-alerts`, `caf:check-stock-reorder`) + a scheduler block now exist. They are the JOB-CAF-001 defect (scheduled in **central** context without `tenants:run`), not absent. The NTF `dispatch(...)` calls inside the services are commented out — alerts compute counts but never send (BUG-CAF-002).
- [2026-06-29 | Technical Auditor] Wallet concurrency is genuinely safe on the *debit* path (locked), but the *cancel/refund* path is not — guard reads order status without a row lock or conditional update, so concurrent cancels double-refund (DAT-CAF-001). Pattern reminder: locking the child (card) does not serialize the parent (order) state transition.
- [2026-06-29 | Technical Auditor] CAF is a strong counter-example to D25 — it consistently uses `$request->validated()` and has **zero** `$request->all()` into models. The residual mass-assignment risk is narrow: balance columns in `MealCard::$fillable` (latent only — `UpdateMealCardRequest` doesn't expose them).

- [2026-06-27 | Update] Seeding recorded models as "17" based on req doc assumption that jnt/log tables share parent models. Actual is 21 — every DDL table has its own dedicated model class (including `DailyMenuItemJnt`, `EventMealItemJnt`, `ConsumptionLog`, `OrderItem`, `StaffMealLog`). In this codebase, junction and log tables always get their own Model.
- [2026-06-27 | Update] View count in seeding (50 proposed) was a large undercount — 95 blade files found. Seeded view estimates from req docs are typically 50–100% lower than actuals because req docs count screens, not individual blade partials.

---

## Pending Next Steps

- [x] Generate FRD → done 2026-06-29 → `0-FRD_Documents/CAF_FRD_2026-06-29.md` (16 REQ / 36 BR / 9 WF / 9 RPT / 10 ENH)
- [ ] DDL Schema Gap Analysis → `act as DB Architect / Technical Auditor` — for each REQ with "DDL Entity Needed = Yes" (15 of 16; only REQ-CAF-016 is aggregated reads), confirm tables/columns vs `Cafeteria_DDL_v1.sql`
- [ ] Code Gap Analysis → `act as Technical Auditor` — verify controller logic completeness, job implementations (or lack thereof), NTF dispatch pattern, Razorpay webhook, HST/INV bridge services
- [ ] Create queued jobs: MenuPublishNotificationJob, LowBalanceAlertJob, FssaiExpiryAlertJob, MenuArchiveJob
- [ ] Expand test coverage: MealCardService (concurrency + double-spend), OrderService (cutoff enforcement), QR scan deduplication, Razorpay webhook idempotency
- [ ] Create migrations for all 21 CAF tables
- [ ] Verify `sys_users.id` type = INT UNSIGNED before migration (DDL corrects req doc's BIGINT claim)

---

## Version History

| Date | Agent | Work Done |
|------|-------|-----------|
| 2026-06-27 | Business Analyst | Knowledge file seeded from V2 requirement doc (CAF_Cafeteria_Requirement.md v2) + DDL (Cafeteria_DDL_v1.sql). Status incorrectly recorded as 0% Greenfield — actual code not checked at seeding. Models recorded as 17 (undercount). |
| 2026-06-27 | Business Analyst | Update pass: verified actual file counts against prime_ai/Modules/Cafeteria/. Status corrected to ~60–65%. Corrections: models 17→21 (all tables have dedicated models), FormRequests 16→19 (TopUp/Update/UpdateEnrollment added), views ~50→95, routes ~77→147 lines. Confirmed: 16 ctrl, 6 services, 14 policies all match proposed. Gaps: 1 test file only (22 proposed), 0 jobs, 0 migrations, Events/Listeners missing. |
| 2026-06-29 | Technical Auditor | Mode A 12-layer deep audit (read-only) → `3-Audit_Reports/V1_Jun-2026/Cafeteria_Technical_Audit_2026-06-29.md`. Health 62/100, no P0. 4 P1 (SEC-CAF-002 write-IDOR, SEC-CAF-003 D30, DAT-CAF-001 cancel double-refund race, JOB-CAF-001 scheduler-central), 5 P2, 3 P3. Corrected stale knowledge: 22 caf_ migrations exist centrally (Layer 2 Green); 3 Artisan commands + scheduler exist (not "0 jobs"); NTF dispatch stubbed. Confirmed strengths: full tenancy stack web+API, locked wallet debit, price snapshot, idempotent attendance, no `$request->all()`. |
| 2026-06-29 | Business Analyst | Generated FRD v1.0 (fresh; no prior FRD) → `CAF_FRD_2026-06-29.md`. 16 REQ (1:1 with feature groups), 36 BR (001-019 preserved, 020-036 added), 9 workflows, 9 reports, 10 ENH. P0=6/P1=6/P2=4. Sources: V2 req + V1 Cafeteria_v2 (17 screen specs + data-flow) + DDL + Laravel module + this knowledge file. Section 10.4 reconciled. Daily Sales (RPT-CAF-002) and Kitchen Prep Sheet (RPT-CAF-009) surfaced from V1; one-open-session-per-day (BR-CAF-020) from V1 data-flow. |
