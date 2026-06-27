# Module Knowledge Summary: Cafeteria (CAF)

**Date:** 2026-06-27
**Agent:** Business Analyst
**Source Files:**
- `4-Requirement_Module_wise/4-Initial_Requirements/V2/CAF_Cafeteria_Requirement.md` (V2, 16 FRs, 19 BRs)
- `2-DDL_Tenant_Consolidated/Cafeteria_DDL_v1.sql` (21 tables, 4 dependency layers)
- `Herd/prime_ai/Modules/Cafeteria/` (live filesystem verification — two passes: seeding + update on 2026-06-27)

**Knowledge File:** `AI_Brain/module-knowledge/CAF_Cafeteria.md`

---

## 1. Module Identity

| Item | Finding |
|------|---------|
| Module Code | `CAF` |
| Table Prefix | `caf_*` |
| Database | `tenant_db` (per-school, no `tenant_id` columns) |
| Laravel Path | `Modules/Cafeteria/` |
| DDL Version | v1 (4 dependency layers, 21 tables) |
| V2 Requirement | `CAF_Cafeteria_Requirement.md` (16 FRs, 19 BRs, 21 permissions) |
| FRD Status | Not yet generated |

**Key Discovery from this session:** Seeded in the same session as 0% Greenfield (no code verified at seeding time). Update pass immediately followed and corrected status to ~60–65%. This module exemplifies the systematic seeding error pattern found across multiple modules in this audit.

---

## 2. Actual vs. Proposed Comparison

CAF was seeded and updated on 2026-06-27 in the same session. The comparison is between the req-doc-based seeding estimate and actual filesystem counts.

| Metric | Seeded Estimate | Actual (Verified) | Change |
|--------|----------------|-------------------|--------|
| Controllers | 16 proposed | **16** | Exact match |
| Models | **17** (undercount) | **21** | +4 (corrected — see Section 4) |
| Services | 6 proposed | **6** | Exact match |
| FormRequests | **16** (undercount) | **19** | +3 (TopUpMealCard, UpdateMealCard, UpdateSubscriptionEnrollment) |
| Policies | 14 proposed | **14** | Exact match |
| Tests | 22 proposed | **1 file** | Critical gap |
| Blade Views | ~50 estimated | **95** | +45 (nearly double) |
| Route Lines | ~77 estimated | **147 lines** | +70 (nearly double) |
| Jobs | Proposed (several) | **0** | P1 gap |
| Migrations | Required | **0** | P1 gap |
| Events/Listeners | Required | **0 directories** | P2 gap |
| Completion % | 0% (seeded incorrectly) | **~60–65%** | Corrected |

**Pattern confirmed:** Controllers, services, and policies match proposed counts precisely. Models, FormRequests, views, and routes are all undercounted when estimated from requirement docs alone.

---

## 3. DDL Architecture: 4-Layer Dependency Chain (21 Tables)

| Layer | Tables | Role |
|-------|--------|------|
| 1 — Foundation | `caf_menu_categories`, `caf_suppliers`, `caf_fssai_records`, `caf_daily_menus`, `caf_subscription_plans`, `caf_meal_cards`, `caf_pos_sessions`, `caf_dietary_profiles` | Master/header records; no caf_* dependencies |
| 2 — Transactions | `caf_menu_items`, `caf_stock_items`, `caf_event_meals`, `caf_subscription_enrollments`, `caf_meal_card_transactions`, `caf_meal_attendance`, `caf_pos_transactions`, `caf_staff_meal_logs`, `caf_orders` | Core transaction records; depend on Layer 1 + cross-module |
| 3 — Line Items & Logs | `caf_daily_menu_items_jnt`, `caf_event_meal_items_jnt`, `caf_consumption_logs` | Junction and log tables; depend on Layer 2 |
| 4 — Order Detail | `caf_order_items` | Depends on Layer 3 (caf_orders) |

**Migration order must strictly follow layers 1→2→3→4.** 21 migrations needed — none exist.

---

## 4. The Model Count Correction: 17 → 21 (Critical Learning)

The seeding pass recorded 17 models based on the assumption that junction and log tables share parent models. The actual module had 21 — one dedicated Model class per DDL table, including:

| "Missing" Model | Table | Why It Exists |
|-----------------|-------|---------------|
| `DailyMenuItemJnt` | `caf_daily_menu_items_jnt` | Junction — but has its own model |
| `EventMealItemJnt` | `caf_event_meal_items_jnt` | Junction — but has its own model |
| `ConsumptionLog` | `caf_consumption_logs` | Log table — but has its own model |
| `OrderItem` | `caf_order_items` | Line item — has its own model |
| `StaffMealLog` | `caf_staff_meal_logs` | Log table — has its own model |

**Codebase rule established:** In this project, **every DDL table has a dedicated Model class** — including junction tables, log tables, line items, and transaction logs. Never estimate model count by subtracting junctions. This rule applies to all modules.

**Full model inventory (21):** `ConsumptionLog`, `DailyMenu`, `DailyMenuItemJnt`, `DietaryProfile`, `EventMeal`, `EventMealItemJnt`, `FssaiRecord`, `MealAttendance`, `MealCard`, `MealCardTransaction`, `MenuCategory`, `MenuItem`, `Order`, `OrderItem`, `PosSession`, `PosTransaction`, `StaffMealLog`, `StockItem`, `SubscriptionEnrollment`, `SubscriptionPlan`, `Supplier`

---

## 5. Immutable Records — Financial and Compliance Tables

CAF has the highest count of immutable tables in the audit to date. These tables have no `deleted_at`, no `updated_at`, or both — by design.

| Table | Immutability | Reason |
|-------|-------------|--------|
| `caf_fssai_records` | No `deleted_at` | FSSAI compliance records must never be deleted |
| `caf_meal_card_transactions` | No `deleted_at` | Financial ledger — immutable append-only |
| `caf_meal_attendance` | No `updated_at`, no `deleted_at` | Immutable QR scan record |
| `caf_pos_transactions` | No `deleted_at`, no `is_active` | Immutable after save |
| `caf_staff_meal_logs` | No `deleted_at`, no `is_active` | Transactional log |
| `caf_order_items` | No `deleted_at`, no `created_by`, no `is_active` | Line item — immutable |
| `caf_daily_menu_items_jnt` | No `deleted_at` | Junction — no soft delete |
| `caf_event_meal_items_jnt` | No `deleted_at` | Junction — no soft delete |
| `caf_consumption_logs` | No `deleted_at`, no `is_active` | Usage log |
| `caf_pos_sessions` | No `deleted_at`, no `created_by` | `opened_by` serves as creator context |

**Impact on code:** `SoftDeletes` trait must NOT be used on these models. Any attempt to call `->delete()` should either be blocked at the controller layer or documented as unsupported. Test coverage for immutability enforcement is currently 0.

---

## 6. Concurrency Safety: SELECT...FOR UPDATE on Meal Cards

**Design Decision D1:** `MealCardService` wraps every balance deduction in a DB transaction with a row-level lock:

```php
DB::transaction(function () use ($cardId, $amount) {
    $card = MealCard::lockForUpdate()->find($cardId);
    // balance check
    // deduction
    // MealCardTransaction insert
});
```

This pattern applies to:
- Order placement (pre-order deduction)
- POS counter transaction
- Subscription enrollment deduction

**Business Rule BR-CAF-012:** Balance deduction MUST use `SELECT ... FOR UPDATE` + single DB transaction. This is the anti-double-spend contract for the entire module.

**Current test coverage for this:** 0 — the only test file (`CafeteriaReportControllerTest`) covers reports, not concurrency. A concurrency bug here could cause double-spend on meal card balances — a financial correctness issue.

---

## 7. Key Architecture Decisions (12 Design Decisions Documented)

| Decision | Summary | Risk if Missed |
|----------|---------|---------------|
| D1 — Meal card SELECT...FOR UPDATE | Every deduction uses row-level lock in DB::transaction | Double-spend on concurrent requests |
| D2 — Price snapshot on order items | `caf_order_items.unit_price` set at order time; never re-read menu price | Price changes after ordering affect existing orders |
| D3 — UNIQUE on `menu_date` | One menu record per calendar date; planner edits existing record | Duplicate menu for same date |
| D4 — UNIQUE on `(student_id, meal_date, meal_category_id)` | QR scan is idempotent; duplicate scans return 200, not error | Duplicate scan records inflate headcount |
| D5 — Razorpay webhook idempotency at DB level | UNIQUE on `razorpay_payment_id` in `caf_meal_card_transactions` | Duplicate webhook credits card twice |
| D6 — POS session: `opened_by` = creator | No `created_by` column on `caf_pos_sessions`; `opened_by` serves both roles | Mismatched model factory |
| D7 — FSSAI polymorphic discriminator | `record_type ENUM('License','Audit')` discriminates two subtypes in one table; no `deleted_at` | Cannot soft-delete FSSAI records |
| D8 — Event meal free-text items | `caf_event_meal_items_jnt.menu_item_id` nullable when `free_text_item` used | Free-text items can duplicate dish-library entries; no UNIQUE guard |
| D9 — Dietary profile upsert | One profile per student; `store()` uses upsert/findOrCreate | Double profile if upsert logic broken |
| D10 — Kitchen view includes subscription students | Subscription enrollments pre-counted without explicit order record; requires union/left-join | Kitchen headcount is wrong if query only aggregates orders |
| D11 — Staff payroll deduction = flag only | `payroll_deduction_flag = 1` is a signal to PAY; CAF never writes to `pay_*` | If pay module misses the flag, staff meal is never deducted from salary |
| D12 — Hostel mess auto-enrollment bridge | HST module triggers CAF bridge service on hostel admission; creates subscription enrollment | Without HST bridge, hostel students must be manually enrolled in mess plan |

---

## 8. Five State Machines

| FSM | States | Key Trigger |
|-----|--------|------------|
| Weekly Menu | `Draft` → `Published` → `Archived` | Published triggers NTF; Archived by scheduler on week change |
| Event Meal | `Draft` → `Published` → `Archived` | Published triggers NTF to targeted class students |
| Pre-Order | `Confirmed` → `Served` / `Cancelled` | Cancelled before cutoff refunds meal card balance |
| POS Session | `Opened` → `Active` → `Closed` | Transactions only allowed in Active/Opened state |
| Subscription Enrollment | `Active` → `Paused` / `Cancelled` / `Expired` | Cancelled triggers pro-rata refund calc |

**Menu FSM NTF dependency (BR-CAF-005/006):** Publishing a menu dispatches push/SMS to ALL active students and parents. This is a high-volume notification event that should be queued. No `Jobs/` directory found — likely synchronous or missing.

---

## 9. Three DDL Deviations from Requirement

| Deviation | Req Doc Says | DDL Says | Impact |
|-----------|-------------|---------|--------|
| `sys_users` FK type | BIGINT UNSIGNED | **INT UNSIGNED** | Migration type mismatch — DDL is correct; `sys_users.id = INT UNSIGNED` |
| `billing_period` ENUM | Monthly/Termly/Annual | **Monthly/Quarterly/Termly/Annual** | DDL adds Quarterly; seeder must include this value |
| `academic_term_id` FK type | Not specified clearly | **SMALLINT UNSIGNED** | Matches `sch_academic_term.id = SMALLINT UNSIGNED` |

---

## 10. Seven School Settings Required

CAF is settings-heavy — 7 school-level config keys must be present before the module behaves correctly:

| Setting Key | Default | Controls |
|-------------|---------|---------|
| `caf_order_cutoff_hours` | 2.00 | How many hours before meal start ordering closes (BR-CAF-001) |
| `caf_allow_negative_balance` | false | Whether meal card can go below zero |
| `caf_low_balance_threshold` | ₹100.00 | Parent notification threshold (BR-CAF-017) |
| `caf_prepaid_only_mode` | true | Disallow counter payment; enforce prepaid card (BR-CAF-003) |
| `caf_parent_scan_notification` | false | Notify parent on child's QR scan at meal counter |
| `caf_hostel_auto_enroll` | true | Auto-enroll hostel students in hostel mess plan (BR-CAF-015) |
| `caf_inv_integration` | false | Create INV purchase requisition on stock reorder (BR-CAF-007) |

None of these are in a migration or seeder — they must be present in `sys_school_settings` before the module is usable.

---

## 11. Open Gaps & Recommended Actions

### P1 — Critical

| Gap | Recommended Action |
|-----|-------------------|
| **1 test file only** (22 proposed) | Priority tests: `MealCardService` concurrency + double-spend (SELECT...FOR UPDATE), order cutoff enforcement (`BR-CAF-001`), QR scan deduplication (`BR-CAF-010`), Razorpay webhook idempotency (`BR-CAF-011`), dietary conflict logic (`BR-CAF-002`) |
| **0 queued jobs** | Create: `MenuPublishNotificationJob`, `LowBalanceAlertJob`, `FssaiExpiryAlertJob` (30d/7d), `MenuArchiveJob`. All dispatched synchronously or missing — high-volume NTF on menu publish will block HTTP. |
| **0 migrations** | Create 21 migrations in 4-layer order. Verify `sys_users.id = INT UNSIGNED` before creating FK migrations. |

### P2 — Architecture Risk

| Gap | Recommended Action |
|-----|-------------------|
| No Events/Listeners directory | NTF dispatch on menu publish and HST bridge for mess auto-enrollment may be called directly from controllers. Technical Audit needed to confirm dispatch pattern. |
| Controller logic completeness unknown | 16 controllers present; cutoff enforcement, concurrency locks, FSM transitions unverified. Technical Audit (Mode A) needed. |
| Razorpay webhook not confirmed | `TopUpMealCardRequest` exists; webhook route and HMAC signature verification implementation unverified. Check: must be no-auth route in `api.php`. |

### P3 — Integration Dependencies

| Gap | Recommended Action |
|-----|-------------------|
| HST bridge service | `BR-CAF-015` requires HST module to trigger CAF auto-enrollment. No bridge service/listener found. Scope after HST module progresses. |
| INV bridge | Stock reorder → INV purchase requisition when `caf_inv_integration = true`. Not confirmed implemented. |

---

## 12. Cross-Module Integration Map

### CAF Reads From:
| Module | Integration |
|--------|-----------|
| StudentProfile (STD) | `std_students` — dietary profiles, orders, meal cards, attendance, POS transactions |
| SchoolSetup (SCH) | `sch_academic_terms` — daily menu and subscription plan scoping |
| System (SYS) | `sys_users`, `sys_media`, `sys_activity_logs` — auth, staff FKs, dish photos, FSSAI docs, audit trail |
| Notification (NTF) | Event dispatch — menu publish, low-balance, reorder, FSSAI expiry alerts |
| Hostel (HST) | Bridge event — hostel admission triggers CAF mess plan auto-enrollment |
| Inventory (INV) | Optional bridge — stock reorder creates INV purchase requisition |
| Finance (FIN) | Razorpay config pattern — online meal card top-up follows FIN gateway pattern |
| Payroll (PAY) | Signal only — `payroll_deduction_flag`; CAF never writes to `pay_*` tables |

### CAF Writes To / Serves:
| Module | What It Provides |
|--------|----------------|
| Student Portal (STP) | Published weekly menu, pre-order form, own orders, card balance |
| Parent Portal (PPT) | Published menu, order on behalf, card top-up, consumption history |
| Inventory (INV) | Purchase requisition trigger on reorder |
| Payroll (PAY) | `payroll_deduction_flag` in `caf_staff_meal_logs` |

---

## 13. Key Lessons Learned

1. **Every DDL table has a dedicated Model class in this codebase — no exceptions.** Junction tables (`DailyMenuItemJnt`, `EventMealItemJnt`), log tables (`ConsumptionLog`, `StaffMealLog`), and line items (`OrderItem`) all have their own Model. Never estimate model count by subtracting junctions. The rule is: table count = model count. Confirmed in CAF (21 tables → 21 models) and consistent with ADM (20/20).

2. **Views exceed screen count by 50–100% in every module.** CAF req doc described ~50 views; actual is 95. The pattern across all audited modules: screens in req docs count functional screens; blade files include partials, modals, print layouts, AJAX partials, PDF templates. Screen count is not a useful proxy for blade file count.

3. **FormRequests can exceed proposed count due to split Store/Update patterns.** CAF had 3 extra FormRequests not in the proposed list (`TopUpMealCard`, `UpdateMealCard`, `UpdateSubscriptionEnrollment`). These emerge during development when update validation differs from store validation. Always verify via `ls app/Http/Requests/`.

4. **Concurrency-critical code with 0 tests is the highest-risk code pattern.** CAF's `SELECT...FOR UPDATE` meal card balance deduction has no tests. A race condition here is a financial correctness bug — two simultaneous deductions could both pass the balance check before either commits. This is the highest-priority test to write in the entire module.

5. **Immutable-by-design tables must be explicitly identified before any code work.** CAF has 10 immutable tables (no `deleted_at` or no `updated_at`). If `SoftDeletes` is accidentally added to `MealCardTransaction`, `MealAttendance`, or `FssaiRecord`, compliance and financial integrity are violated. The knowledge file immutability table must be read before any model creation.

6. **"0 Greenfield" seeding without filesystem check always understates actual completion.** CAF was seeded as 0% Greenfield in the morning and immediately corrected to ~60–65% in the same session's update pass. The gap between seeding and reality was: 16 ctrl, 21 models, 6 services, 19 FormRequests, 14 policies, 95 views — none of which showed in the seeding record.

7. **Kitchen view correctness depends on a union/left-join — not just order aggregation.** Subscription-enrolled students are pre-counted in the kitchen headcount without an explicit `caf_orders` record. A query that only aggregates `caf_orders` will under-report kitchen preparation quantities. This is a non-obvious correctness requirement (D10) that cannot be derived from the schema alone.

---

## 14. Recommended Next Steps

| Priority | Action | Agent |
|----------|--------|-------|
| 1 | Add tests: `MealCardService` concurrency (SELECT...FOR UPDATE), order cutoff, QR deduplication, Razorpay webhook idempotency | Testing Architect |
| 2 | Create queued jobs: `MenuPublishNotificationJob`, `LowBalanceAlertJob`, `FssaiExpiryAlertJob`, `MenuArchiveJob` | Developer |
| 3 | Create 21 tenant migrations (4-layer order; verify `sys_users.id` type first) | Developer |
| 4 | Technical Audit (Mode A) — verify controller logic completeness, NTF dispatch pattern, Razorpay webhook route, HST bridge implementation | Technical Auditor |
| 5 | Generate FRD — use DDL v1 (3 deviations from req doc); both requirement formats not needed (single consolidated V2 req) | Business Analyst → "create an FRD for Cafeteria" |
| 6 | Seed `sys_school_settings` entries for all 7 CAF settings keys | Developer |
| 7 | Scope HST bridge service after HST module status is clarified | Business Analyst + Backend Developer |
