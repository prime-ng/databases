# Technical Audit — Cafeteria (CAF) — 2026-06-29

**Module:** Cafeteria | **Code:** CAF | **Prefix:** `caf_` | **Live path:** `/Users/bkwork/Herd/prime_ai/Modules/Cafeteria/`
**Auditor:** Technical Auditor (Mode A — Standard Deep 12-Layer, read-only)

## Executive Summary
Cafeteria is one of the better-engineered tenant modules: every controller method carries a `Gate::authorize()`, the wallet ledger uses correct `SELECT … FOR UPDATE` row locks, order line items snapshot price at order time (BR-CAF-023), QR attendance is idempotent (`firstOrCreate` + DB UNIQUE), and the module RouteServiceProvider applies the full tenancy stack to **both** web and API routes. The worst issues are **P1, not P0**: a write-side IDOR class on the sanctum API (arbitrary `student_id` lets a caller order/scan/overwrite a profile against another student — extends the already-registered SEC-CAF-001), a **double-refund race** in order cancellation (no row lock / conditional re-check on the order), scheduled commands that run in **central context without `tenants:run`**, and the platform-wide D30 pattern (all 19 FormRequests `authorize(){return true;}`). Notification dispatch for three business rules (reorder, FSSAI expiry, low-balance) is computed but **commented out / stubbed**, so those alerts never fire. **Health: 62/100 — no P0, not capped.**

## Audit Mode(s) Run
Mode A (full 12-layer). FRD (`CAF_FRD_2026-06-29.md`) cross-referenced for BR enforcement on the design decisions called out in the task (counter-session lifecycle, ledger/attendance immutability, order price snapshot, food-cost, staff/net revenue).

## Health Score
**62 / 100** (weighted index). No P0 → **no hard cap applied.**
Layer scores (G/A/R): L1 Amber, L2 Green, L3 Amber, L4 Amber, L5 Amber, L6 Green, L7 Amber, L8 Amber, L9 Green, L10 Red, L11 Amber, L12 Amber.

## Issue Counts
| Severity | Count | Codes |
|----------|-------|-------|
| P0 | 0 | — |
| P1 | 4 | SEC-CAF-002, SEC-CAF-003, DAT-CAF-001, JOB-CAF-001 |
| P2 | 5 | BUG-CAF-001, BUG-CAF-002, VAL-CAF-001, SCH-CAF-001, FE-CAF-001 |
| P3 | 3 | DEAD-CAF-001, DAT-CAF-002, BUG-CAF-003 |

> Code continuation: only **SEC-CAF-001** pre-existed in `lessons/known-issues.md` (apiIndex IDOR). All other CAF prefixes had no prior entries, so they begin at 001. SEC continues at 002.

---

## P1 Findings

### [SEC-CAF-002] P1 | Write-side IDOR — arbitrary `student_id` accepted on sanctum API (extends SEC-CAF-001)
- **Location:** `app/Http/Controllers/OrderController.php:83-93` (`apiStore`); `app/Http/Requests/StoreOrderRequest.php:12-27`; also `MealAttendanceController.php:24-50` (`apiScan`), `DietaryProfileController.php:112-121` (`apiUpdate`)
- **Evidence:**
  ```php
  // StoreOrderRequest::rules()
  'student_id' => ['required', 'integer', 'exists:std_students,id'],
  public function authorize(): bool { return true; }
  // OrderService::placeOrder() then deducts THAT student's wallet:
  $card = MealCard::where('student_id', $studentId)->active()->firstOrFail();
  $this->mealCardService->deductBalance($card, $total, 'Order', $order->id);
  ```
- **Why it's a risk:** The API group (`routes/api.php`) is `auth:sanctum` and described as the student/parent mobile app + counter tablet. `student_id` is validated only for existence, never for ownership by the authenticated caller. A student/parent holding `cafeteria.orders.create` can place orders that **debit another student's wallet**, overwrite another child's **dietary + confidential medical** profile (`apiUpdate`), or mark attendance for any pupil. Same root cause as the registered SEC-CAF-001 (`apiIndex`), but on **write/financial** paths.
- **Fix:** Resolve the target student from the authenticated principal (parent→child relationship / `auth()->user()->student_id`), or add an ownership check in a real `authorize()` / policy `before` hook. Do not trust `student_id` from the request body for portal callers.
- **Confidence:** Medium (High that ownership is unchecked; Medium on exploitability — depends on whether portal roles are granted `cafeteria.*` perms). **Systemic?** Extends SEC-CAF-001; IDOR family.

### [SEC-CAF-003] P1 | All 19 FormRequests `authorize(){ return true; }` (D30)
- **Location:** every file in `app/Http/Requests/` — confirmed verbatim on `StoreOrderRequest.php:12`, `DeductMealCardRequest.php`, `TopUpMealCardRequest.php`, `IssueMealCardRequest.php`, `UpdateMealCardRequest.php:11`, `StorePosTransactionRequest`, … (19/19)
- **Evidence:** `public function authorize(): bool { return true; }`
- **Why it's a risk:** Defense-in-depth collapses to the single controller `Gate::authorize()` layer. Controllers here currently all gate correctly, but any new/edited action that forgets the gate has **zero** fallback — the exact failure mode D30 documents. Financial requests (Order, Deduct, TopUp, IssueMealCard) are the highest-value.
- **Fix:** Each `authorize()` returns `Gate::allows('cafeteria.<entity>.<action>')` matching the route; keep controller gates too.
- **Confidence:** High. **Systemic?** D30 (platform 437/485) — CAF is fully inside the norm.

### [DAT-CAF-001] P1 | Order cancellation double-refund race (no row lock / conditional re-check)
- **Location:** `app/Services/OrderService.php:116-139` (`cancelOrder`)
- **Evidence:**
  ```php
  throw_unless(in_array($order->status, ['Pending', 'Confirmed']), new \DomainException(...));
  $this->assertCutoffNotPassed(...);
  DB::transaction(function () use ($order, $reason) {
      $order->update(['status' => 'Cancelled', ...]);
      if ($order->payment_mode === 'MealCard' && $order->meal_card_id) {
          $card = MealCard::find($order->meal_card_id);
          $this->mealCardService->refundBalance($card, (float) $order->total_amount, $order->id);
      }
  });
  ```
- **Why it's a risk:** The status guard reads `$order->status` **without** `lockForUpdate()` and the transaction does not re-assert "still Confirmed". Two concurrent cancels (double-tap, or portal + admin) both pass the guard and each call `refundBalance` → the wallet is credited **twice** for one order. `refundBalance` locks the *card* but that does not prevent two distinct refund rows. Money leaks to the school's disadvantage.
- **Fix:** `$order = Order::lockForUpdate()->find($order->id)` inside the transaction and re-check `status === 'Confirmed'` (or guard the update with `->where('status','Confirmed')` and refund only when 1 row was affected).
- **Confidence:** High. **Systemic?** Mirrors the locking-gap class (Layer 8.2) seen in StudentFee/Hostel/Payment.

### [JOB-CAF-001] P1 | Scheduled commands run in central context (no `tenants:run`)
- **Location:** `app/Providers/CafeteriaServiceProvider.php:111-117`
- **Evidence:**
  ```php
  $schedule->command('caf:archive-old-menus')->dailyAt('00:00');
  $schedule->command('caf:send-fssai-alerts')->weeklyOn(1, '08:00');
  $schedule->command('caf:check-stock-reorder')->dailyAt('07:00');
  ```
- **Why it's a risk:** The three commands (`SendFssaiAlertsCommand`, `CheckStockReorderCommand`, `ArchiveOldMenusCommand`) call services that query tenant tables (`caf_suppliers`, `caf_fssai_records`, `caf_stock_items`, `caf_daily_menus`) but contain **no** `tenancy()->initialize()` / `$tenant->run()`. Scheduled on the central scheduler they execute once against the **central DB** (which has no `caf_*` tables) → error or silent no-op; menus are never archived and expiry/reorder checks never run per school.
- **Fix:** Wrap with the multi-tenant runner, e.g. `$schedule->command('tenants:run caf:check-stock-reorder')…`, or iterate tenants inside `handle()`.
- **Confidence:** High. **Systemic?** Layer 10.2 (same as Hostel `hst:escalate-complaints`).

---

## P2 Findings

### [BUG-CAF-001] P2 | Dietary-conflict check (BR-CAF-002) not enforced on any order/POS write path
- **Location:** `app/Services/OrderService.php:29-91` (`placeOrder`), `app/Services/PosService.php:44-110` (`processTransaction`)
- **Evidence:** `placeOrder` computes totals and deducts with no reference to `DietaryProfile`; `processTransaction` only *snapshots* `dietary_flags_json` after the sale — no conflict warning/block.
- **Why it's a risk:** BR-CAF-002 / REQ-CAF-005 AC4 require a dietary-conflict warning (e.g. nut-allergic student ordering a conflicting dish; admin may override, student may not). This is a **child-safety** rule (allergy) and it is silently unenforced.
- **Fix:** Resolve the student's `DietaryProfile` in `placeOrder`/`processTransaction`, compare against each dish `food_type` / allergen notes, and require an explicit admin override flag for portal callers.
- **Confidence:** High (absence is provable). **Systemic?** Module-local BR gap.

### [BUG-CAF-002] P2 | Notification dispatch stubbed — BR-CAF-007 / 014 / 017 compute but never notify
- **Location:** `app/Services/StockService.php:60-71` (reorder), `:136-140` (FSSAI), `app/Services/MealCardService.php:101-104` (low balance)
- **Evidence:**
  ```php
  // StockService::dispatchReorderAlert
  // event(new StockReorderAlert($item));            // commented
  // StockService::checkFssaiExpiry
  // foreach ($supplier30 as $s) { dispatch(new FssaiExpiryAlertJob($s, 30)); }  // commented
  // MealCardService::deductBalance
  if ($newBalance < $threshold) {
      // dispatch(new LowBalanceNotificationJob($locked))->onQueue('notifications');  // commented
  }
  ```
- **Why it's a risk:** Three P1/P2 business rules silently do nothing — reorder alerts, FSSAI expiry reminders (60/30d school, 30/7d supplier), and low-balance parent alerts are all dead. `checkFssaiExpiry` even returns a count as if it acted. No `Jobs/` directory exists; nothing is queued.
- **Fix:** Implement the NTF dispatch (queued jobs `MenuPublishNotificationJob`, `LowBalanceAlertJob`, `FssaiExpiryAlertJob`, reorder alert) and wire the INV bridge placeholder.
- **Confidence:** High. **Systemic?** Module-local (interacts with NTF readiness).

### [VAL-CAF-001] P2 | BR-CAF-020 not enforced — multiple open POS sessions per day allowed
- **Location:** `app/Services/PosService.php:23-29` (`openSession`)
- **Evidence:**
  ```php
  public function openSession(array $data): PosSession {
      return PosSession::create(array_merge($data, ['opened_by' => auth()->id(), 'opened_at' => now()]));
  }
  ```
- **Why it's a risk:** No guard for an already-open session on `session_date`. BR-CAF-020 ("only one open counter session per day; a closed session cannot be reopened") is unenforced → split takings across concurrent sessions break end-of-day reconciliation. (Re-open is correctly blocked via `closeSession`'s `closed_at` check, but the "one open" half is missing.)
- **Fix:** Before create, `throw_if(PosSession::whereDate('session_date', …)->whereNull('closed_at')->exists(), …)`; ideally back with a partial/generated UNIQUE.
- **Confidence:** High. **Systemic?** Module-local BR gap.

### [SCH-CAF-001] P2 | D29 — ~15 `ENUM` columns in CAF DDL instead of `sys_dropdown_table` FKs
- **Location:** `2-DDL_Tenant_Consolidated/Cafeteria_DDL_v1.sql` — `meal_time` (:32), `record_type`/`license_type` (:81,83), `status` (:117,323,355,519), `billing_period` (:146), `food_type` (:225,258), stock `category` (:291), `transaction_type`/`payment_mode` (:386,392,452,486,517), `scan_method` (:423)
- **Evidence:** `meal_time ENUM('Breakfast','Lunch','Snacks','Dinner','Tuck_Shop')`, `billing_period ENUM('Monthly','Quarterly','Termly','Annual')`, …
- **Why it's a risk:** D29 — semi-open value sets locked at DDL level; schools/PG-Admin cannot extend statuses/categories without a per-tenant schema migration. The 22 generated central migrations carry the same ENUMs.
- **Fix:** Migrate pick-from-list columns to `_id` FKs → `sys_dropdown_table` with registered needs; keep truly code-gated binaries as `TINYINT(1)`.
- **Confidence:** High. **Systemic?** D29 (platform ~476 migration enums).

### [FE-CAF-001] P2 | `json_encode()` chart payloads without `JSON_HEX_*` flags (staff-entered strings)
- **Location:** `resources/views/reports-page/index.blade.php:123-283` (12 sites), `resources/views/pages/dashboard.blade.php:276-300`
- **Evidence:** `var barLabels = {!! json_encode(array_map(fn($d) => $d['category_name'], …)) !!};`
- **Why it's a risk:** Payloads embed **staff-entered** dish/category/item names. A name containing `</script>` (or `'`/`"`) breaks out of the inline `<script>` → stored XSS. Guardrail keeps this at P2 (not raw user field, but not a fixed constant either).
- **Fix:** Use Blade `@json($data)` or add `JSON_HEX_TAG|JSON_HEX_APOS|JSON_HEX_QUOT|JSON_HEX_AMP`.
- **Confidence:** Medium. **Systemic?** Common Blade/chart pattern platform-wide.

---

## P3 Findings

### [DEAD-CAF-001] P3 | Duplicate dead `CafeteriaServiceProvider` at module root `/Providers/`
- **Location:** `Modules/Cafeteria/Providers/CafeteriaServiceProvider.php` (29 lines) vs the live `Modules/Cafeteria/app/Providers/CafeteriaServiceProvider.php` (215 lines)
- **Evidence:** Both declare `namespace Modules\Cafeteria\Providers;` / `class CafeteriaServiceProvider`. `module.json` registers `Modules\Cafeteria\Providers\CafeteriaServiceProvider`, which PSR-4 resolves to the `app/Providers/` copy; the root-level file is outside the autoload path and unused.
- **Why it's a risk:** Same FQCN in two files is a maintenance/autoload trap; a future composer remap could load the wrong (stub) one and silently drop the scheduler/policy registration.
- **Fix:** Delete `Modules/Cafeteria/Providers/CafeteriaServiceProvider.php`.
- **Confidence:** High.

### [DAT-CAF-002] P3 | Wallet balance columns in `$fillable` (latent — ledger bypass)
- **Location:** `app/Models/MealCard.php:19-22`
- **Evidence:** `$fillable = ['student_id','card_number','current_balance','total_credited','total_debited', …]`
- **Why it's a risk:** `current_balance` / `total_credited` / `total_debited` are mass-assignable. The current `update()` path is safe (`UpdateMealCardRequest` does **not** expose them), so this is latent — but any future `update($request->all())` or new path could mutate balance outside the immutable ledger (BR-CAF-022).
- **Fix:** Remove balance/total columns from `$fillable`; mutate only via `MealCardService` (locked) paths.
- **Confidence:** Medium (latent, not currently reachable).

### [BUG-CAF-003] P3 | Order cutoff (BR-CAF-001) silently skipped when category has no `meal_start_time`
- **Location:** `app/Services/OrderService.php:212-216`
- **Evidence:** `if (! $category || ! $category->meal_start_time) { return; }`
- **Why it's a risk:** A category with a NULL serving time disables cutoff enforcement entirely (orders accepted any time). The default-2h intent (BR-CAF-001/026) is lost for mis-configured categories.
- **Fix:** Treat a missing serving time as a config error (block + flag) or fall back to a school-level default cutoff.
- **Confidence:** High.

---

## Layer Health Summary
| Layer | Score | Key finding |
|-------|-------|-------------|
| 1 DDL Schema | Amber | Solid FKs/indexes/UNIQUEs; D29 ENUMs (SCH-CAF-001) |
| 2 Mig↔Model↔DDL | **Green** | **22 `caf_*` migrations exist centrally** (`database/migrations/tenant/`, 2026-06-15) — knowledge file's "0 migrations" is stale; models align with DDL |
| 3 Model/ORM | Amber | Casts good; balance columns fillable (DAT-CAF-002) |
| 4 Code Quality | Amber | No god controllers (max 388 LOC), no `dd`/`env()`; dead dup provider + many commented placeholders |
| 5 Authorization | Amber | Every controller method gated; D30 (SEC-CAF-003) + write-IDOR (SEC-CAF-002) |
| 6 Multi-Tenancy | **Green** | Full tenancy stack on web **and** API RSP; `$tenant` context correct; no `initialize()`-without-`end()` |
| 7 Validation/Mass-assign | Amber | `validated()` everywhere, **no `$request->all()`**; authorize() true + ownership gap |
| 8 Data Integrity/Tx | Amber | Correct `lockForUpdate` on balance; cancel double-refund race (DAT-CAF-001); BR-CAF-020 (VAL-CAF-001) |
| 9 Performance | Green | Lists paginated; kitchen view eager-loads `items.menuItem`; no introspection in hot paths |
| 10 Queue/Job | **Red** | 0 queued jobs; NTF dispatch stubbed (BUG-CAF-002); commands scheduled central (JOB-CAF-001) |
| 11 Frontend | Amber | `json_encode` chart payloads w/o JSON_HEX (FE-CAF-001); `{!! config() !!}` benign |
| 12 Deployment | Amber | Secrets externalized to config (good); scheduler-central; NTF incomplete |

## Business-Rule Enforcement (spot-check of task-flagged decisions)
| Rule | Status | Evidence |
|------|--------|----------|
| BR-CAF-012 wallet deduction atomic (`SELECT…FOR UPDATE`) | **ENFORCED** | `MealCardService::deductBalance:80` |
| BR-CAF-023 order price snapshot | **ENFORCED** | `OrderService:50-58` stores `unit_price` at order time; never re-reads `menu_items.price` |
| BR-CAF-011 Razorpay idempotency | **ENFORCED** | `exists()` check `MealCardService:212` + DB `uq_caf_mct_razorpay` UNIQUE (backstop) |
| BR-CAF-021 attendance immutable/idempotent | **ENFORCED** | `firstOrCreate` + `uq_caf_ma` UNIQUE; table has no `updated_at`/`deleted_at` |
| BR-CAF-013 POS needs open session | **ENFORCED** | `PosService:46` |
| BR-CAF-022 ledger immutable | **PARTIAL** | ledger table has no `deleted_at`; but balance fillable (DAT-CAF-002) is a latent bypass |
| BR-CAF-020 one open session/day | **MISSING** | VAL-CAF-001 |
| BR-CAF-002 dietary conflict | **MISSING** | BUG-CAF-001 |
| BR-CAF-007 / 014 / 017 alerts | **MISSING** | BUG-CAF-002 (computed, not dispatched) |
| BR-CAF-008 refund on cancel | **ENFORCED but racy** | DAT-CAF-001 |
| BR-CAF-033 daily food cost | Not located in a service (reports compute on read) — verify in CafeteriaReportService if needed |

## vs Platform Baseline
- D30 (FormRequests `true`): 19/19 — fully typical (platform 90%).
- D25 (`$request->all()` into models): **0 sites** — better than baseline; controllers consistently use `validated()`.
- Tenancy RSP: full stack present (better than the D23 offenders).
- Locking: present on balance (unlike StudentFee/Hostel/Payment gaps) — but order-cancel path still races.
- ENUMs: in line with the ~476 platform total.

## Recommended Fix Order
1. **DAT-CAF-001** — add `lockForUpdate` + status re-check to `cancelOrder` (stops real money leak).
2. **SEC-CAF-002** — enforce student ownership on API write paths (`apiStore`/`apiScan`/`apiUpdate`).
3. **JOB-CAF-001** — wrap scheduled commands in `tenants:run` (otherwise compliance/stock automation is dead).
4. **BUG-CAF-002** — implement queued NTF jobs (reorder/FSSAI/low-balance) — closes 3 BRs at once.
5. **BUG-CAF-001 / VAL-CAF-001** — dietary-conflict check + one-open-session guard.
6. **SEC-CAF-003 / FE-CAF-001 / SCH-CAF-001** — D30 hardening, JSON_HEX, ENUM→dropdown.
7. **DEAD-CAF-001 / DAT-CAF-002 / BUG-CAF-003** — hygiene.

## Notes & Corrections for the Knowledge Base
- Knowledge file states **"0 migrations — module uses DDL directly"**; this is **stale** — 22 `create_caf_*` migrations exist in `database/migrations/tenant/` (dated 2026-06-15). Layer 2 is healthy.
- Knowledge file states **"0 jobs"**; still true for *queued* jobs, but **3 Artisan commands + a scheduler block now exist** (archive/FSSAI/reorder) — they are the JOB-CAF-001 finding, not absent.

---

## STEP 1 Reading-Discipline Output (D-pattern) — added 2026-06-29

### Three-Way Schema Reconciliation (DDL ↔ migration ↔ model)
| Subject | DDL spec | Live migration | Eloquent model | Verdict |
|---------|----------|----------------|----------------|---------|
| ~15 pick-list columns | declared `ENUM` | migration mirrors `ENUM` | n/a | DDL and migration **agree but both violate D29** → SCH-CAF-001 (P2). |
| `MealCard` wallet balance | ledger-derived (must not be mass-assigned) | columns present | balance columns in `$fillable` (DAT-CAF-002) | **Latent**, not active: `UpdateMealCardRequest` does **not** expose them → P3, not P1. The 3-way read prevented a false P1. |
| Wallet debit / order price | — | columns present | locked debit + price snapshot | Reconciled **clean** — no gap. |

### Module-Knowledge Snapshot Corrections (hints vs live code)
- "0 migrations / module uses DDL directly" → **stale**: 22 `create_caf_*` tenant migrations exist in `database/migrations/tenant/` → Layer 2 verified Green.
- Balance-in-`$fillable` re-checked against the consuming FormRequest → downgraded from a presumed active exploit to **latent (P3)**.
