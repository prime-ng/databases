# Complete Audit — Accounting (ACC) — 2026-06-29   (Mode X: A+B+C+G + scoped D)

**Module:** Accounting | **Code:** ACC (legacy FAC) | **Prefix:** `acc_` | **Type:** Tenant (`tenant_db`)
**App code:** `/Users/bkwork/Herd/prime_ai/Modules/Accounting`
**Baseline FRD:** `4-Requirement_Module_wise/0-FRD_Documents/ACC_FRD_Complete_2026-06-29.md` (22 REQ · 40 BR · 14 RPT)
**Schema source of truth:** `2-DDL_Tenant_Consolidated/Accounting_DDL_v3.sql` (28 tables) — **0 migrations** (schema applied via tenant DDL directly).
**Auditor:** Technical Auditor (AI_Brain) | Read-only. Evidence-based.

---

## Executive Summary

The Accounting module is broad and substantially built (21 controllers, 25 models, 7 services, 141 views, full tenancy stack, double-entry FormRequest balance check, row-locked voucher numbering). It is **not deploy-ready**. The worst finding is a **systemic schema-vs-code contradiction**: the DDL defines `status` as an `INT UNSIGNED` FK to `acc_accounting_status_masters` on five tables and `acc_ledgers` has **no `current_balance` column at all**, yet the models and every service read/write these as **string status values** and post running balances into the missing `current_balance` column. Under the DDL-as-shipped schema, voucher posting throws `Unknown column 'current_balance'` and all status filtering collapses — the core ledger engine cannot function. On top of that, **two core workflows are dead** because both `ExpenseClaimService` and `DepreciationService` look up voucher type code `'JRN'` while the seeder creates `'JNL'` (`firstOrFail()` → uncaught 500). **Health: 38/100 (capped at 40 — P0 present). DEPLOY: NO-GO.**

## Audit Mode(s) Run
Mode X = A (12-layer) + B (FRD gap) + C (business-rule enforcement) + G (deploy gate) + scoped D (systemic patterns). Single unified report. Each defect coded once.

## Health Score
Weighted layer index ≈ 58 before cap; **capped at 40 → reported 38/100** because P0 data-layer defects are present (DDL↔model↔code contradiction renders the posting path and status filtering non-functional under the schema of record). Cap rule applied per the scoring policy.

## Deploy Gate Verdict — **NO-GO**
Blocking items:
1. **DATA-ACC-002 (P0)** — `acc_ledgers.current_balance`/`current_balance_type` referenced by model + 2 services but absent from the DDL → every post/cancel throws `SQLSTATE 42S22`.
2. **DATA-ACC-001 (P0)** — `status` is INT FK in DDL on 5 tables; code uses string literals + `string` cast → status writes/filters break.
3. **BUG-ACC-003 (P1, escalates)** — Expense-claim approval and depreciation both 500 (`JRN` vs seeded `JNL`).
4. **BUG-ACC-004 (P1)** — Approving a voucher removes it from every financial report.

(No committed secrets, no `$request->all()`, no tenancy context leak, no unauth tenant route — those gates pass.)

---

## P0 Findings

### [DATA-ACC-001] P0 — `status` is an INT FK in the DDL but the code treats it as a string across the whole module
- **Location:**
  - DDL `Accounting_DDL_v3.sql:234` `` `status` INT UNSIGNED NOT NULL `` + `:252` `CONSTRAINT fk_acc_voucher_status FOREIGN KEY (status) REFERENCES acc_accounting_status_masters(id)` (same pattern at `:395/:405` recon, `:519/:535` expense claim, `:575/:586` tally log, `:789/:806` event log).
  - `app/Models/Voucher.php:50` `'status' => 'string'`; `:138-201` scopes/helpers compare `'draft'/'posted'/'approved'/'cancelled'`.
  - `app/Services/VoucherService.php:61,69,82,88` writes/compares `'draft'/'posted'/'cancelled'`.
  - `app/Services/RemoteEntryService.php:66,89,158,182,205` writes `'Skipped'/'Failed'/'posted'/'Processed'`.
  - `app/Services/ReconciliationService.php:18,156,163` `'Completed'`; `app/Services/ExpenseClaimService.php:61,74,82` `'Approved'/'Submitted'/'Rejected'`.
- **Evidence:**
    ```sql
    `status` INT UNSIGNED NOT NULL COMMENT 'Voucher Status', -- FK to `acc_accounting_status_masters`
    CONSTRAINT `fk_acc_voucher_status` FOREIGN KEY (`status`) REFERENCES `acc_accounting_status_masters` (`id`)
    ```
    ```php
    $voucher->update(['status' => 'posted']);              // VoucherService.php:69 — string into INT FK
    ->where('v.status', '=', 'posted')                     // ReportService.php:31 — INT col compared to string
    ```
- **Why it's a risk:** Under the DDL schema, writing `'posted'` into an `INT UNSIGNED` FK column either errors (strict mode) or coerces to `0` (which violates the FK to `acc_accounting_status_masters` → `errno 1452`), and `WHERE status = 'posted'` coerces the column to `0`, so every status filter matches the wrong rows. Draft/posted/cancelled separation — the backbone of BR-ACC-019/021 (report inclusion/exclusion) — silently fails.
- **Fix:** Decide one source of truth. Either (a) keep the FK design and refactor all models/services to resolve status IDs from `acc_accounting_status_masters` (add a `status_id` int + a string accessor), or (b) if the intended live schema is a VARCHAR/ENUM status, correct the DDL to match and document it. Do not ship the current contradiction.
- **Confidence:** High (mismatch is provable). **Severity:** P0 as schema-of-record; downgrade to **P1** only if the live tenant DB was hand-built with a VARCHAR `status` diverging from the DDL — which itself is a DDL-drift defect.
- **Systemic?:** D17 / D36-adjacent (DDL↔model↔code divergence); spans 5 tables.

### [DATA-ACC-002] P0 — `acc_ledgers.current_balance` is written by code but does not exist in the DDL
- **Location:** DDL `acc_ledgers` (lines ~132-180) defines `opening_balance`, `opening_balance_type` only — **no `current_balance`**. Yet:
  - `app/Models/Ledger.php:42-43` fillable `current_balance`, `current_balance_type`; `:49-50` casts them.
  - `app/Services/VoucherService.php:104-110` `DB::table('acc_ledgers')...->update(['current_balance' => DB::raw('current_balance + '.$delta)])`.
  - `app/Services/RemoteEntryService.php:191,193` `$ledger->increment('current_balance', $amount)` / `decrement(...)`.
- **Evidence:**
    ```php
    DB::table('acc_ledgers')->where('id', $item->ledger_id)->lockForUpdate()
      ->update(['current_balance' => DB::raw('current_balance + ' . $delta), 'updated_at' => now()]);
    ```
- **Why it's a risk:** If the DDL is the deployed schema, **every voucher post, cancel, and cross-module auto-post throws `SQLSTATE 42S22 Unknown column 'current_balance'`** inside the transaction → no voucher can ever be posted. The ledger engine is inoperable.
- **Fix:** Add `current_balance DECIMAL(15,2) NOT NULL DEFAULT 0` (+ optional `current_balance_type`) to the `acc_ledgers` DDL (DB Architect), OR remove the running-balance write and derive balances from `acc_voucher_items` as `ReportService` already does. Reconcile model fillable to the chosen schema.
- **Confidence:** High. **Severity:** P0 (downgrade to P1 only if the live tenant schema already carries `current_balance` outside the DDL — still a DDL-drift defect to fix).
- **Systemic?:** D17 (fillable/code references column the schema lacks).

---

## P1 Findings

### [BUG-ACC-003] P1 (escalates) — Expense-claim approval and depreciation both 500: code looks up voucher type `'JRN'` but the seeder creates `'JNL'`
- **Location:** `app/Services/ExpenseClaimService.php:32` `VoucherType::where('code', 'JRN')->firstOrFail();` · `app/Services/DepreciationService.php:32` `VoucherType::where('code', 'like', 'JRN%')->firstOrFail();` vs `database/seeders/AccountingSeeder.php:358` `['code' => 'JNL', 'name' => 'Journal', ...]`.
- **Evidence:**
    ```php
    // AccountingSeeder.php:358
    ['code' => 'JNL', 'name' => 'Journal', 'prefix' => 'JNL', 'category' => 'ACCOUNTING_GENERAL'],
    // ExpenseClaimService.php:32
    : VoucherType::where('code', 'JRN')->firstOrFail();
    ```
- **Why it's a risk:** No voucher type has code `JRN`, so `firstOrFail()` throws `ModelNotFoundException`. `ExpenseClaimController::approve()` (`:225`) only catches `\DomainException`, so it surfaces as a **500** and the claim→payment-voucher workflow (REQ-ACC-014, BR-ACC-041, WF3) never completes. `DepreciationService::runForAsset` (REQ-ACC-013, WF) is likewise fully broken.
- **Fix:** Change both lookups to `'JNL'` (or, better, resolve the journal type from a config/constant, and have controllers also catch `ModelNotFoundException`).
- **Confidence:** High. **Severity:** P1 (effectively P0 for these two REQs — core workflows dead with an unhandled 500).

### [BUG-ACC-004] P1 — Approving a voucher drops it from every financial report
- **Location:** `app/Http/Controllers/VoucherController.php:189` sets `status => 'approved'`; `app/Services/ReportService.php:31,65,104` filter `v.status = 'posted'` only.
- **Evidence:**
    ```php
    $voucher->update(['status' => 'approved', 'approved_by' => auth()->id()]);   // VoucherController.php:189
    ->where('v.status', '=', 'posted')                                            // ReportService.php:31 (TB)
    ```
- **Why it's a risk:** Once a posted voucher is approved its status is no longer `'posted'`, so Trial Balance, P&L, and Balance Sheet exclude it → the books understate every approved transaction. Violates BR-ACC-019 (posted vouchers must be included). (Compounded by DATA-ACC-001.)
- **Fix:** Treat `posted` and `approved` as "included" states (`whereIn('v.status', [...])` or an `is_posted`/`included_in_books` flag), and define inclusion against the status master rather than a single literal.
- **Confidence:** High. **Severity:** P1.

### [DATA-ACC-003] P1 — Depreciation is neither idempotent nor salvage-floored (BR-ACC-039, BR-ACC-038 MISSING)
- **Location:** `app/Services/DepreciationService.php:15-62`.
- **Evidence:** `runForAsset()` unconditionally `DepreciationEntry::create(...)` and `$asset->update(['current_value' => current_value - $monthly, 'accumulated_depreciation' => ... + $monthly])` with **no lookup of an existing entry for the same `fixed_asset_id`+`financial_year_id`** and **no `max(salvage_value)` floor**.
- **Why it's a risk:** Re-running depreciation for the same FY creates duplicate journals and decrements `current_value` again — the asset is double-depreciated and book value runs below salvage (RISK-ACC-007). Violates BR-ACC-039 (idempotent replace) and BR-ACC-038 (SLM floor at salvage).
- **Fix:** Before posting, find+reverse/replace any existing entry for `(fixed_asset_id, financial_year_id)`; clamp `current_value` so it never drops below `salvage_value`.
- **Confidence:** High. **Severity:** P1.

### [BUG-ACC-005] P1 — Cancel of a posted voucher mutates ledgers directly with no reversal voucher and no locked-year guard
- **Location:** `app/Services/VoucherService.php:73-93` (`cancel`); locked-year guard absent in `post()`/`cancel()`/`approve()` and in `VoucherController::destroy()` (`:115-130`).
- **Evidence:**
    ```php
    if ($voucher->status === 'posted') { $this->applyItemsToLedgers($voucher->items, direction: -1); }
    $voucher->update(['status' => 'cancelled', 'is_cancelled' => true, 'cancelled_reason' => $reason]);
    ```
- **Why it's a risk:** BR-ACC-020 requires cancellation of a posted voucher to **auto-create an equal-and-opposite reversal voucher** (audit trail / NFR-ACC-005 immutability); here the ledger is silently reversed and no reversal record exists. BR-ACC-016/022: `cancel()`, `post()`, `approve()` and `destroy()` never check `financialYear->isLocked()`, so a voucher in a **locked** year can still be cancelled/posted/deleted (store/update do guard the lock, but these paths do not).
- **Fix:** In `cancel()`, generate a reversal voucher (opposite Dr/Cr lines, new number) and post it instead of mutating balances; add `isLocked()` guards (reverse-only in a locked year) to `post`, `cancel`, `approve`, `destroy`.
- **Confidence:** High. **Severity:** P1.

### [BUG-ACC-006] P1 — Cross-module event engine has no duplicate-event guard (BR-ACC-043 MISSING)
- **Location:** `app/Services/RemoteEntryService.php:36-96` (`processEvent`).
- **Evidence:** After resolving the event+config it goes straight to `createVoucherFromConfig`; there is **no check for an existing `EventProcessingLog` with the same `module_event_id`+`source_id` already `Processed`** (the DDL even documents this guard at `acc_event_processing_log` comments).
- **Why it's a risk:** The same source event (e.g. a fee receipt re-fired/retried) creates a **second voucher** → double-posting to the books. FRD BR-ACC-043 requires duplicates to be logged `Skipped`, not processed.
- **Fix:** Before creating the voucher, `EventProcessingLog::where(module_event_id, source_id)->whereProcessed()->exists()` → log `Skipped` and return.
- **Confidence:** High. **Severity:** P1.

### [SEC-ACC-006] P1 — Cross-module event failure re-throws and can roll back / block the source module (NFR-ACC-006 / BR-ACC-044 violated)
- **Location:** `app/Services/RemoteEntryService.php:80-95`.
- **Evidence:**
    ```php
    } catch (\Throwable $e) {
        DB::rollBack();
        EventProcessingLog::create([... 'status' => 'Failed' ...]);
        throw $e;   // <-- propagates to the calling source module
    }
    ```
- **Why it's a risk:** If a source module (StudentFee, Transport, …) calls `processEvent()` synchronously inside its own transaction, the re-thrown exception rolls back / aborts the source operation — exactly what NFR-ACC-006 and BR-ACC-044 forbid ("processing failure never rolls back or blocks the source module").
- **Fix:** Log `Failed` (+ increment `retry_count`) and **return** the log without re-throwing; surface failures via the processing log / a retry job, not by propagating to the caller.
- **Confidence:** High. **Severity:** P1.

### [SEC-ACC-007] P1 — Expense-claim edit/submit lack ownership enforcement (BR-ACC-041 / IDOR)
- **Location:** `app/Http/Controllers/ExpenseClaimController.php:90-148,201-212` — `edit/update/submit` call `Gate::authorize('tenant.accounting.expense-claim.update')` (string ability), never `authorize($expenseClaim)` (model instance), so `ExpenseClaimPolicy`'s owner check (if any) is never invoked.
- **Evidence:** `Gate::authorize('tenant.accounting.expense-claim.update');` with no `$expenseClaim` argument; no `where('created_by', auth()->id())` scoping.
- **Why it's a risk:** Any user holding the generic expense-claim update permission can edit/submit **another staff member's** claim. BR-ACC-041 ("a claimant can only create/edit their own claims") is unenforced.
- **Fix:** Authorize the model instance (`$this->authorize('update', $expenseClaim)`) and implement the ownership rule in `ExpenseClaimPolicy::update()` (own claim, Draft state).
- **Confidence:** Medium (depends on policy body — but the controller does not pass the instance, so any ownership logic is bypassed). **Severity:** P1.

### [BUG-ACC-007] P1 — Financial-year lock does not block when Draft vouchers exist (BR-ACC-009 MISSING)
- **Location:** `app/Http/Controllers/FinancialYearController.php:91-100` (`lock`).
- **Evidence:** `$financialYear->update(['is_locked' => true]);` — no pre-check for draft vouchers in the year.
- **Why it's a risk:** BR-ACC-009 forbids locking a year that still contains Draft vouchers; here a year can be locked with drafts pending, leaving un-postable orphans in a frozen period.
- **Fix:** `abort_if($financialYear->vouchers()->where('status', draftId)->exists(), ...)` before locking; show the draft list.
- **Confidence:** High. **Severity:** P1.

---

## P2 Findings

### [BUG-ACC-008] P2 — Bank reconciliation completes on "no unmatched entries", not on zero difference (BR-ACC-034/035)
- `app/Services/ReconciliationService.php:154-164`: `complete()` only checks `is_matched=false` does-not-exist; it never compares book balance to `acc_bank_reconciliations.closing_balance` (the DDL has `closing_balance` but the service ignores it), and there is **no override path** (BR-ACC-035). FRD requires completion only when the difference is zero (or with a Finance-Officer override). **Fix:** compute book vs closing-balance difference and block unless zero or overridden.

### [VAL-ACC-001] P2 (systemic D30) — All 17 FormRequests `authorize()` return `true`
- `grep` confirms **17/17** FormRequests (`VoucherRequest.php:11-14`, etc.) hardcode `return true;`. Controllers do gate each action, so this is defense-in-depth only here, but it matches the platform-wide D30 pattern. **Fix:** return `Gate::allows('tenant.accounting.<entity>.<action>')`.

### [BUG-ACC-009] P2 — Expense-claim rejection reason is captured then silently discarded
- `app/Services/ExpenseClaimService.php:79-85`: `reject(ExpenseClaim $claim, string $reason)` only does `$claim->update(['status' => 'Rejected'])` — the `$reason` argument (validated in the controller at `:236`) is never persisted. BR-ACC-041 / WF3 require the rejection reason to be recorded. **Fix:** persist `rejection_reason` (and audit it).

### [PERF-ACC-006] P2 — Finance dashboard fires unbounded query chains + per-month loop (already logged)
- `app/Http/Controllers/AccDashboardController.php:47-99`. Confirmed still present (6 unbounded aggregate chains + 12-iteration monthly chart loop, no caching — NFR-ACC-009 wants ~30-min cache). Reference existing code PERF-ACC-006; no new code assigned.

### [ARCH-ACC-001] P2 — Two divergent ledger-posting implementations
- `VoucherService::applyItemsToLedgers` (`:99-112`, raw `DB::raw` arithmetic) vs `RemoteEntryService` (`:182-196`, Eloquent `increment/decrement`). Same business operation, two code paths → drift risk (and both depend on the missing `current_balance` — DATA-ACC-002). **Fix:** route all posting through one `VoucherService` method.

### [PERF-ACC-007] P2 — Auto-match has no confidence score / narration keyword (BR-ACC-033 PARTIAL)
- `app/Services/ReconciliationService.php:88-128` matches on ledger+amount+date(±3d) only; BR-ACC-033 specifies amount + date + **narration keyword + confidence score** (none stored). Functional but weaker than spec.

### [BUG-ACC-010] P2 — Budget approval workflow (WF4) and 90%-utilisation alert (BR-ACC-030) not implemented
- `BudgetController` has no `submit`/`approve` actions and no draft→submitted→active status handling; no over-budget notification wiring found. REQ-ACC-010 / WF4 are PARTIAL. (BR-ACC-027 uniqueness IS enforced — DDL `uq_acc_budget` + `BudgetRequest` `Rule::unique`.)

### [DATA-ACC-004] P2 — `acc_vouchers.source_module` is a BIGINT FK in the DDL, used as a string in code
- DDL `acc_vouchers.source_module BIGINT UNSIGNED NULL` FK → `acc_voucher_modules`; `Voucher.php:51` casts `'string'`, `VoucherRequest.php:28` validates `in:Fees,Library,...`, `RemoteEntryService.php:155` writes `$event->module_code` (string). Same class as DATA-ACC-001. **Fix:** store the `acc_voucher_modules.id`, not a label.

---

## P3 Findings
- **[DEAD-ACC-001]** `app/Http/Controllers/AccountingController.php:9-32` — all five REST methods `return response()->json([])` (empty stub), wired live via `routes/api.php:7` (`apiResource`, behind `auth:sanctum`). Harmless but dead API surface. Remove or implement.
- **[DEPLOY-ACC-01]** `AccountingServiceProvider.php:120-126` schedules `acc:run-recurring-templates` daily with no `withoutOverlapping()`/`onOneServer()`. (The command itself is correct — iterates `Tenant::all()` and uses `$tenant->run()`.)
- **[SCH-DDL-ACC-01]** DDL hygiene typos already catalogued in FRD §20.2 (`auto_numbering.` stray period; `acc_voucher_category` FK references `module_id` vs actual `voucher_module_id`; `idx_acc_vt_category` references removed `category` column). Route to DB Architect.
- **[ORM-ACC-001]** `ReportService` filters `ag.nature` with lowercase `'income'/'expense'/'asset'` vs DDL `ENUM('Asset',...)`; works only because `utf8mb4_unicode_ci` is case-insensitive — fragile if collation/`sql_mode` changes.
- `loadMigrationsFrom(module_path(...,'database/migrations'))` points at a non-existent dir (harmless; module has 0 migrations by design).

---

## Layer Health Summary (Mode A)

| Layer | Status | Key finding |
|-------|--------|-------------|
| 1 DDL Schema Integrity | Amber | Sound design (status master, FK-based natures, `uq_acc_budget`); minor typos (FRD §20.2). No ENUM-vs-dropdown (D29) violations beyond intentional `nature`/`type`. |
| 2 Migration↔Model↔DDL | **Red** | DATA-ACC-001/002/003 — status INT-vs-string, missing `current_balance`, source_module FK-vs-string. |
| 3 Model & ORM | Amber | Casts mostly present; `status`/`source_module` mis-cast to string (see L2). |
| 4 Code Quality | Green | No `dd/dump`, no `$request->all()`, thin controllers (largest = Dashboard 729). AccountingController dead stub (P3). |
| 5 Authorization | Amber | Every real controller gates each action; but expense-claim edit/submit bypass instance policy (SEC-ACC-006). |
| 6 Multi-Tenancy | **Green** | Full stack in RouteServiceProvider (`InitializeTenancyByDomain`+`PreventAccessFromCentralDomains`+`EnsureTenantIsActive`+`auth`+`verified`); no `initialize()` leak; command uses `$tenant->run()`. |
| 7 Validation/Mass-assign | Amber | Strong `VoucherRequest` (Dr=Cr in `withValidator`); D30 (17/17 `authorize()=true`). |
| 8 Data Integrity/Tx | **Red** | Transactions + `lockForUpdate` used well for numbering/ledgers, BUT non-idempotent depreciation, no reversal voucher, no duplicate-event guard, no locked-year guard on cancel/post. |
| 9 Performance | Amber | Dashboard unbounded chains + monthly loop (PERF-ACC-006); reports are set-based (good). |
| 10 Queue/Job/Scheduler | Green | `RunRecurringTemplatesCommand` is tenant-safe; no jobs. (Add overlap guard — P3.) |
| 11 Frontend/Output | Green | No hardcoded secrets in views; no obvious raw-output XSS found in scan. |
| 12 Deployment | Amber | No committed secrets / no `env()` outside config in module; schedule lacks overlap guard. Module-level gate clean — global blockers (queue/Horizon, `.env-original`) are platform-level, not ACC. |

---

## STEP 1 Reading-Discipline Output — three-way reconcile & snapshot corrections

**Three-way reconcile (DDL ↔ migration ↔ model):** migrations = 0 (confirmed), so reconcile is **DDL ↔ model/code**. Divergences found:

| Item | DDL (`Accounting_DDL_v3.sql`) | Model / Code | Verdict |
|------|------------------------------|--------------|---------|
| `acc_vouchers.status` (+4 sibling tables) | `INT UNSIGNED` FK → status master | `string` cast, `'draft'/'posted'/...` literals | **Contradiction — DATA-ACC-001 (P0)** |
| `acc_ledgers.current_balance` | **absent** | fillable + written by 2 services | **Contradiction — DATA-ACC-002 (P0)** |
| `acc_vouchers.source_module` | `BIGINT` FK → `acc_voucher_modules` | `string`, validated `in:Fees,...` | **Contradiction — DATA-ACC-003 (P2)** |
| `acc_voucher_items.type` | `ENUM('debit','credit')` | matches code | OK |
| `acc_account_groups.nature` | `ENUM('Asset',...)` | code uses lowercase (ci collation) | Fragile — ORM-ACC-001 (P3) |
| `acc_budgets` uniqueness | `uq_acc_budget(fy,cc,ledger)` | `BudgetRequest` `Rule::unique` | OK — BR-ACC-027 enforced |

**Snapshot corrections to `module-knowledge/ACC_Accounting.md`:**
- "0 job/command files; ENH-ACC-004 not built" → **WRONG.** `app/Console/Commands/RunRecurringTemplatesCommand.php` exists and is **scheduled daily 01:00** (tenant-safe). Recurring auto-posting IS built; monthly-depreciation and budget-breach jobs remain absent.
- "Status fields are FK → status master (clean implementation)" → the **DDL** defines the FK, but the **code does not honour it** (uses strings) — this is a defect (DATA-ACC-001), not a clean feature.
- D36 (GENERATED columns degraded): **N/A** — no `GENERATED ALWAYS` columns in the Accounting DDL.

---

## FRD Gap Summary (Mode B) — REQ → Code/Schema/Test status

| REQ | Status | Gap / linked finding |
|-----|--------|----------------------|
| REQ-ACC-001 Account Group | OK | Controller+model+views; nature/parenting present. |
| REQ-ACC-002 Ledger | PARTIAL | `current_balance` write broken — DATA-ACC-002. |
| REQ-ACC-003 Ledger Statement | OK | ReportService ledger movements. |
| REQ-ACC-004 Financial Year | PARTIAL | Lock skips draft check — BUG-ACC-007. |
| REQ-ACC-005 Voucher Type | OK | CRUD + system protection. |
| REQ-ACC-006 Voucher Entry/Engine | PARTIAL | Dr=Cr enforced (FormRequest); posting depends on DATA-ACC-001/002. |
| REQ-ACC-007 Lifecycle (cancel/reverse) | PARTIAL | No reversal voucher; locked-year guards missing — BUG-ACC-005. |
| REQ-ACC-008 Recurring Templates | OK | Service + scheduled command. |
| REQ-ACC-009 Cost Centre | OK | Hierarchy CRUD. |
| REQ-ACC-010 Budget & Variance | PARTIAL | No approval workflow / 90% alert — BUG-ACC-010. |
| REQ-ACC-011 Bank Reconciliation | PARTIAL | Completion ≠ zero-difference; no override; no confidence score — BUG-ACC-008/PERF-ACC-007. |
| REQ-ACC-012 Fixed Assets | OK | Register + categories. |
| REQ-ACC-013 Depreciation | **BROKEN** | `JRN` lookup 500 (BUG-ACC-003) + non-idempotent/no salvage floor (DATA-ACC-004). |
| REQ-ACC-014 Expense Claims | **BROKEN** | Approval 500 (BUG-ACC-003); reject reason lost (BUG-ACC-009); IDOR (SEC-ACC-006). |
| REQ-ACC-015 Tax Rate | OK | CRUD present. |
| REQ-ACC-016 Ledger Mappings | OK | CRUD present. |
| REQ-ACC-017 Event Engine | PARTIAL | No duplicate guard (BUG-ACC-006); re-throws to source (SEC-ACC-007); no retry job. |
| REQ-ACC-018 Tally Export | Not deep-audited | Logic in controller (no service); not a blocker this pass. |
| REQ-ACC-019 Financial Reporting | PARTIAL | Approved vouchers excluded (BUG-ACC-004); status filter depends on DATA-ACC-001. |
| REQ-ACC-020 Dashboard | PARTIAL | Works but unbounded/no cache (PERF-ACC-006). |
| REQ-ACC-021/022 Registry / Status Master | PARTIAL | Model-less infra tables; status master not consumed by code (DATA-ACC-001). |

Reports RPT-ACC-001/002/003 implemented (TB/P&L/BS set-based); RPT-ACC-011 (GST) & RPT-ACC-014 (TDS) correctly absent (ENH-ACC-001/002).

---

## Business-Rule Enforcement (Mode C)

| BR | Type | Location | Status | Link |
|----|------|----------|--------|------|
| BR-ACC-013 Dr=Cr | Calc | `VoucherRequest.php:64-77`, `RemoteEntryService.php:127` | ENFORCED | — |
| BR-ACC-014 ≥2 lines/≥1 Dr+Cr | Valid | `VoucherRequest.php:34` | PARTIAL (min:2; not ≥1 each side) | — |
| BR-ACC-016 No write in locked FY | Workflow | store/update guard; **post/cancel/approve/destroy do not** | PARTIAL | BUG-ACC-005 |
| BR-ACC-017 Bank/cash placement (RCT/PMT/CTR) | Valid | — | MISSING (not validated) | — |
| BR-ACC-018 Voucher number unique per type+FY | Calc/Concurrency | `VoucherService.php:150-171` (`lockForUpdate`) | ENFORCED | — |
| BR-ACC-019/021 Posted incl / cancelled+draft excl | Calc | `ReportService` status filter | PARTIAL (approved dropped) | BUG-ACC-004, DATA-ACC-001 |
| BR-ACC-020 Cancel → auto reversal | Workflow | `VoucherService::cancel` | MISSING | BUG-ACC-005 |
| BR-ACC-022 Locked → reverse-only | Workflow | — | MISSING | BUG-ACC-005 |
| BR-ACC-027 One budget per FY+CC+ledger | Valid | `uq_acc_budget` + `BudgetRequest` | ENFORCED | — |
| BR-ACC-028/029 Variance math | Calc | partial in dashboard | PARTIAL | BUG-ACC-010 |
| BR-ACC-030 90% alert | Workflow | — | MISSING | BUG-ACC-010 |
| BR-ACC-032 Recon only on reconcilable ledger | Valid | (verify in controller) | PARTIAL | — |
| BR-ACC-034 Complete only at diff=0 | Valid | `ReconciliationService::complete` checks unmatched, not diff | MISSING | BUG-ACC-008 |
| BR-ACC-035 Override | Perm | — | MISSING | BUG-ACC-008 |
| BR-ACC-038 SLM floor at salvage | Calc | `DepreciationService` | MISSING | DATA-ACC-004 |
| BR-ACC-039 Idempotent depreciation | Workflow | `DepreciationService` | MISSING | DATA-ACC-004 |
| BR-ACC-040 Balanced depreciation journal | Calc | `DepreciationService:41-43` | ENFORCED (when JNL fixed) | BUG-ACC-003 |
| BR-ACC-041 Own-claim edit / reason on reject | Perm/Workflow | `ExpenseClaimController` | MISSING (IDOR + reason lost) | SEC-ACC-006, BUG-ACC-009 |
| BR-ACC-043 Duplicate event → skip | Workflow | `RemoteEntryService` | MISSING | BUG-ACC-006 |
| BR-ACC-044 Failure never blocks source | Reliability | `RemoteEntryService` re-throws | MISSING | SEC-ACC-007 |

ENFORCED ≈ 6 · PARTIAL ≈ 8 · MISSING ≈ 11 (of the 25 enforceable BRs sampled).

---

## Systemic-Pattern Scorecard (Mode D — scoped to ACC)

| Pattern | Present? | Count | vs baseline |
|---------|----------|-------|-------------|
| D17 fillable/code references missing column | **Yes** | ≥2 (`current_balance`, status/source_module) | Worse than typical — affects core engine |
| D24 permission-prefix chaos/typos | No | gates consistently use `tenant.accounting.*` | Better than baseline |
| D25 `$request->all()` mass-assign | **No** | 0 | Better than baseline (24 platform sites) |
| D29 `->enum()` in migrations | N/A | 0 migrations | — |
| D30 FormRequest `authorize(){return true;}` | **Yes** | 17/17 (100%) | At/above baseline (90%) |
| L2.5 cross-DB / missing-FK target | Not in ACC FKs | 0 | — (status/ledger FKs are intra-tenant) |
| L3.3 privilege fields in `$fillable` | No | 0 | Clean |
| L6.2 `initialize()` without `end()` | **No** | 0 | Clean |
| L10.1 job without tenancy/retry | No | command uses `$tenant->run()` | Clean |
| D36 GENERATED columns degraded | N/A | 0 generated cols in DDL | — |
| TEN-RTG module-subscription middleware | Present | `EnsureTenantIsActive` in RSP | Compliant |

---

## vs Platform Baseline
- **Cleaner than norm:** no `$request->all()` (D25), no permission-prefix typos (D24), no tenancy leak (L6.2), tenant-safe scheduler. Uses `lockForUpdate` correctly for the contended voucher counter and ledger balances (a pattern many modules lack).
- **At/worse than norm:** D30 at 100% (vs 90%); D17 hits the *core* posting path (more damaging than a typical peripheral column mismatch).

## Recommended Fix Order (unblock-the-most-first)
1. **DATA-ACC-002** — add/derive `acc_ledgers.current_balance` (or compute from items). Unblocks all posting. *(DB Architect + Developer)*
2. **DATA-ACC-001 / DATA-ACC-003** — resolve status & source_module INT-FK-vs-string contradiction (one source of truth). Unblocks status filtering & reports.
3. **BUG-ACC-003** — `JRN`→`JNL` in `ExpenseClaimService` + `DepreciationService`; catch `ModelNotFoundException`. Unblocks expense approval + depreciation.
4. **BUG-ACC-004** — include `approved` in report inclusion set.
5. **DATA-ACC-004** — depreciation idempotency + salvage floor.
6. **BUG-ACC-005 / BUG-ACC-007** — reversal voucher + locked-year guards + draft check on lock.
7. **BUG-ACC-006 / SEC-ACC-007** — duplicate-event guard + stop re-throwing to source.
8. **SEC-ACC-006 / BUG-ACC-009** — expense-claim ownership + persist reject reason.
9. **BUG-ACC-008 / BUG-ACC-010 / PERF-ACC-006** — recon zero-diff completion; budget workflow+alert; dashboard caching.
10. **VAL-ACC-001** — harden FormRequest `authorize()`.

## Next Steps
```
Audit complete — Health 38/100 (capped: P0 present). DEPLOY: NO-GO.
1. Fix P0 schema↔code contradictions   → act as DB Architect + Developer
2. Fix P1 broken workflows (JNL, reports, depreciation, cancel) → act as Developer
3. Completeness score                  → act as Status_Analyzer
4. Test coverage (21 tests exist; verify they exercise posting) → act as Testing Architect
```

*Report end. Issue codes assigned here (DATA-ACC-001…004, BUG-ACC-003…010, SEC-ACC-006/007, VAL-ACC-001, PERF-ACC-007, ARCH-ACC-001, DEAD-ACC-001, ORM-ACC-001, DEPLOY-ACC-01, SCH-DDL-ACC-01) continue the existing ACC series (prior max: SEC-ACC-005, BUG-ACC-002, PERF-ACC-006) — none reused.*
