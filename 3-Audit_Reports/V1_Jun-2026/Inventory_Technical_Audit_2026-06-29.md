# Technical Audit — Inventory (INV) — 2026-06-29

**Module:** Inventory · **Code:** INV · **Prefix:** `inv_` · **Path:** `/Users/bkwork/Herd/prime_ai/Modules/Inventory/`
**Auditor:** Technical Auditor (Mode A — Standard Deep 12-Layer, read-only)
**Verified against LIVE code** (the dated 2026-06-27 module-knowledge snapshot was NOT trusted; several of its claims are corrected below).

---

## Executive Summary

Inventory is a substantially-built module (26 controllers, 28 models, 14 services, 16 policies, 19 FormRequests, 28 tenant migrations) with genuinely good tenancy and authorization plumbing — but its **core data-integrity engine is broken**. The worst finding is **DAT-INV-001**: `StockAdjustmentService::approve()` has its entire ledger-posting loop commented out (FIXME), so approved physical-count variances flip the adjustment to `approved` and fire `StockAdjusted` **without ever posting to `inv_stock_entries`/`inv_stock_balances`** — stock balances silently and permanently diverge from physical reality. This is compounded by a sign contradiction and a transfer-reconstruction gap in `StockLedgerService` and a TOCTOU negative-stock race. **Health: 38/100 — P0 hard cap (≤40) applies.**

Two snapshot corrections matter for orchestration: (1) the module is **NOT "0 migrations"** — all 28 `inv_*` tenant migrations exist under the centralized `database/migrations/tenant/` (the snapshot looked only inside the module dir); (2) the misplaced `Events/`+`Listeners/` directories at module root are a real defect, not just untidy files.

## Audit Mode(s) Run
Mode A — Full 12-Layer Deep Audit (read-only). FRD (`INV_FRD_2026-06-29.md`) used as cross-reference only; full Mode B/C not run.

## Health Score
- Weighted layer index: **37.5 / 100**
- **P0 present (DAT-INV-001) → hard cap of 40 applies.** Effective health: **38/100 (capped)**.
- Counts: **P0 = 1 · P1 = 5 · P2 = 3 · P3 = 1**

---

## P0 Findings

```
[DAT-INV-001] Severity: P0 | Approved stock adjustments never post to the ledger — balances silently corrupt
- Location: app/Services/StockAdjustmentService.php:135-179 (FIXME block 138-163)
- Evidence:
    return DB::transaction(function () use ($adj, $userId): StockAdjustment {
        $adj->loadMissing('items');
        // FIXME: Stock entry posting is disabled because the ENUM in
        // inv_stock_entries.entry_type does not include 'adjustment_in'/'adjustment_out'.
        // ... (entire $this->ledger->postEntry(...) loop commented out) ...
        $adj->update(['status' => 'approved', 'approved_by' => $userId, 'approved_at' => now(), ...]);
        event(new StockAdjusted($adj));   // fires as if posted
- Why it's a risk: The physical-count → adjustment workflow is the system of record for reconciling
  inv_stock_balances to reality. With posting disabled, a fully-approved adjustment changes NOTHING in
  the ledger or the running balance, yet reports the variance as resolved and emits the Accounting event.
  Every audited variance is silently lost; balances drift permanently with no error surfaced to the user.
- Fix: Re-enable the posting loop. The ENUM excuse is partly false — `entry_type` already includes a
  generic 'adjustment' value (see migration line 17); post surplus/deficit using 'adjustment' with a
  signed quantity, OR extend the ENUM (better: migrate to a sys_dropdown FK per D29). Then post inside the
  existing transaction so status+ledger move atomically.
- Confidence: High
- Systemic? : Root cause is D29 (ENUM rigidity on entry_type). Matches the role-doc Layer 4.3/8.3 known
  pattern "Inventory FIXME:138 — silent accept-without-post = P0".
```

---

## P1 Findings

```
[DAT-INV-002] Severity: P1 | 'adjustment' sign contradiction + transfer balances cannot be rebuilt
- Location: app/Services/StockLedgerService.php:59 (postEntry) vs 92-102 & 147-185 (recalculateBalances)
- Evidence:
    // postEntry — treats 'adjustment' as OUTWARD (negative):
    $isOutward = in_array($data['entry_type'], ['outward', 'transfer_out', 'adjustment'], true) ...
    // recalculateBalances — treats 'adjustment' (and transfer_in) as INWARD (positive):
    SUM(CASE WHEN entry_type IN ('inward','transfer_in','adjustment') THEN quantity ELSE -quantity END)
- Why it's a risk: Two write paths disagree on the sign of an 'adjustment' entry, so a live balance and a
  rebuilt balance diverge for the same data. Worse, a transfer creates only ONE `transfer_out` row while
  crediting the destination godown via a direct updateBalance() write (lines 95-102); there is no
  `transfer_in` row, so `inventory:recalculate-balances` cannot reconstruct destination-godown stock —
  running the rebuild command (an explicitly supported operation) CORRUPTS balances rather than fixing them.
- Fix: Make 'adjustment' a single signed convention in both paths (or split into adjustment_in/out and
  post a real `transfer_in` row for the destination). Add a reconciliation test asserting
  recalculateBalances() == live balances for inward/outward/transfer/adjustment mixes.
- Confidence: High
- Systemic? : module-local (interacts with DAT-INV-001 / D29 entry_type ENUM).
```

```
[DAT-INV-003] Severity: P1 | Negative-stock guard runs outside the lock → TOCTOU oversell race
- Location: app/Services/StockLedgerService.php:63-65 (guard) vs 69 (transaction) / 116-119 (lock)
- Evidence:
    if ($isOutward) {
        $this->guardNegativeStock($data['stock_item_id'], $data['godown_id'], (float) $data['quantity']);
    }                                            // <-- reads balance UNLOCKED, before the transaction
    $amount = round(...);
    return DB::transaction(function () ... {
        ... $this->updateBalance(...);           // lockForUpdate() only here
    });
  // guardNegativeStock(): StockBalance::where(...)->first();  // no lockForUpdate
- Why it's a risk: Two concurrent issues for the same item/godown both read qty=10, both pass the guard,
  both proceed; BR-INV-003 (no negative stock) is defeated and physical goods are oversold. updateBalance()
  then clamps with max(0, …) (line 123), silently masking the loss instead of erroring.
- Fix: Move guardNegativeStock() INSIDE the transaction and read the balance row with lockForUpdate()
  (the same row updateBalance later locks). Remove the max(0,…) clamp or convert an attempted negative
  into a thrown exception so corruption is loud, not silent.
- Confidence: High  (escalate to P0 where oversell carries direct financial/physical exposure)
- Systemic? : Matches role-doc Layer 8.2 "Inventory stock decrement — no lockForUpdate on the read" hunt.
```

```
[BUG-INV-001] Severity: P1 | Events & Listeners placed outside PSR-4 root → event wiring fatals at runtime
- Location: Modules/Inventory/Events/MaintenanceOverdue.php, Events/AssetDisposed.php (dup),
            Listeners/WriteOffAssetInAccounting.php, Listeners/NotifyMaintenanceOverdue.php
            (all at module ROOT, not under app/) ; wired in app/Providers/EventServiceProvider.php:14-21
- Evidence:
    // composer.json:  "Modules\\Inventory\\": "app/"   (PSR-4 root is app/ ONLY)
    // EventServiceProvider:
    \Modules\Inventory\Events\AssetDisposed::class => [ \Modules\Inventory\Listeners\WriteOffAssetInAccounting::class ],
    \Modules\Inventory\Events\MaintenanceOverdue::class => [ \Modules\Inventory\Listeners\NotifyMaintenanceOverdue::class ],
- Why it's a risk: PSR-4 resolves Modules\Inventory\Listeners\* to app/Listeners/* (which does not exist).
  The four classes live at the module root and are NOT autoloadable. Consequences:
    (a) AssetService::dispose() fires AssetDisposed inside a DB::transaction (AssetService.php:133); the
        listener WriteOffAssetInAccounting cannot be resolved → Error → transaction rolls back → the live
        POST route assets.dispose (routes/web.php:207) 500s and the asset is never disposed.
    (b) The scheduled command inventory:maintenance-overdue (daily 06:00, InventoryServiceProvider:116)
        does `new MaintenanceOverdue(...)`; the only MaintenanceOverdue class is the non-autoloadable root
        copy → command fatals every night.
  There is ALSO a duplicate AssetDisposed (app/Events/AssetDisposed.php is the real one; the root copy is dead).
- Fix: Move Events/* → app/Events/ and Listeners/* → app/Listeners/ (delete the duplicate root AssetDisposed).
  Then `composer dump-autoload`. Verify dispose + the scheduled command run clean.
- Confidence: High
- Systemic? : module-local (file-placement); breaks D21 event-driven Accounting integration for INV.
```

```
[JOB-INV-001] Severity: P1 | ReorderAlertJob has no tenancy re-initialization
- Location: app/Jobs/ReorderAlertJob.php:25-67
- Evidence:
    public function __construct(public readonly int $itemId, public readonly int $godownId) {}
    public function handle(PurchaseOrderService $purchaseOrderService): void {
        $item = StockItem::find($this->itemId);                       // tenant table inv_stock_items
        $balance = StockBalance::where('stock_item_id', $this->itemId) // tenant table inv_stock_balances
        ... $purchaseOrderService->createAutoReorderPR($item);          // writes tenant inv_purchase_requisitions
- Why it's a risk: Constructor carries no tenant id and handle() never calls tenancy()->initialize() /
  $tenant->run(). On a queue worker running in central context, the job reads/writes the wrong DB (or fails).
  tries=3/backoff=60 are set, but reliability ≠ tenant correctness.
- Fix: Capture tenant()->id at dispatch, re-initialize tenancy at the top of handle() (or confirm
  QueueTenancyBootstrapper is enabled in config/tenancy.php — if it is, downgrade to P2 and add a test).
- Confidence: Medium (depends on global queue-tenancy config)
- Systemic? : role-doc Layer 10.1 baseline lists this exact job ("Inventory/ReorderAlertJob.php tenancy=0").
```

```
[DEPLOY-INV-01] Severity: P1 | Closure route breaks `php artisan route:cache` (whole-app deploy blocker)
- Location: routes/web.php:216
- Evidence:
    Route::get('/', fn () => view('inventory::reports.index'))->name('index');
- Why it's a risk: A Closure route cannot be serialized; `route:cache` (standard production step) throws
  "Unable to prepare route [...] for serialization. Uses Closure." and aborts caching for the ENTIRE app,
  not just this module.
- Fix: Point the route at a controller method (e.g. InvReportController@index) instead of a closure.
- Confidence: High
- Systemic? : role-doc Layer 12.4 (route closures break route:cache).
```

---

## P2 Findings

```
[MIG-INV-001] Severity: P2 | D29 ENUMs in migrations + variance_qty is plain-writable, not GENERATED
- Location: database/migrations/tenant/2026_06_15_151759_create_inv_stock_entries_table.php:17 (+14 more ENUMs in DDL);
            database/migrations/tenant/..._create_inv_stock_adjustment_items_table.php (variance_qty)
- Evidence:
    $table->enum('entry_type', ['adjustment','inward','outward','transfer_in','transfer_out']) ...
    $table->decimal('variance_qty', 15, 3)->comment('... DO NOT INSERT/UPDATE');   // plain column, NOT ->storedAs()
- Why it's a risk: (a) entry_type as a hard ENUM is the documented root cause of DAT-INV-001 (dev couldn't
  add adjustment values without a per-tenant migration) — violates D29 (should FK sys_dropdown_table).
  (b) The DDL design intent (D29 design-decision #6) is variance_qty GENERATED ALWAYS; the migration made
  it an ordinary writable column whose own comment says "DO NOT INSERT/UPDATE", yet StockAdjustmentService:47
  writes it. Integrity (physical−system) is not DB-enforced.
- Fix: Migrate entry_type (and the other 14 ENUMs) to sys_dropdown_table FKs per D29; make variance_qty a
  storedAs GENERATED column and stop writing it from the service.
- Confidence: High
- Systemic? : D29 (~476 platform migration ENUMs).
```

```
[PERF-INV-003] Severity: P2 | Report service runs ~10 unbounded ->get() over growing ledger tables
- Location: app/Services/InventoryReportService.php (lines 36, 60, 82, 106, 131, 155, 175, 199, 222, 247 …)
- Evidence: stock-ledger / consumption / valuation report builders end in `->get()` with no paginate()/chunk().
- Why it's a risk: inv_stock_entries and related ledger tables grow unbounded per tenant; loading a full
  ledger into memory for a report degrades and eventually OOMs at scale.
- Fix: Paginate or chunk report queries; push aggregation into SQL (GROUP BY) rather than PHP.
- Confidence: Medium
- Systemic? : extends known PERF-INV-001/002 (unbounded reference fetches).
```

```
[DAT-INV-004] Severity: P2 | Sequential document numbers generated with COUNT(*)+1 (no lock) → duplicates
- Location: GrnPostingService.php:26-32 (GRN), StockAdjustmentService.php:232-238 (ADJ),
            StockIssueService.php:25-42 (SI/IR), GrnPostingService.php:223-233 (asset tag)
- Evidence:
    $count = DB::table('inv_goods_receipt_notes')->whereYear('created_at', $year)->count();
    return sprintf('GRN-%d-%04d', $year, $count + 1);
- Why it's a risk: Two concurrent creates read the same count and mint the same GRN-/ADJ-/SI-/ASSET- number.
  No unique constraint or row lock guards the sequence.
- Fix: Use a locked per-year counter table (lockForUpdate) or a DB sequence, and add a UNIQUE index on the
  number column so a collision errors instead of duplicating.
- Confidence: High
- Systemic? : role-doc Layer 8.2 (voucher/serial generation must lock — see Accounting VoucherService pattern).
```

---

## P3 Findings

```
[DEAD-INV-003] Severity: P3 | Dead/stub remnants
- Location: routes/web.php:113 + PurchaseRequisitionController.php:158 (bulk import "coming soon" wired to
            live prs.import route); Modules/Inventory/Events/AssetDisposed.php (orphan duplicate of app/Events).
- Evidence:
    Route::post('purchase-requisitions/import', [PurchaseRequisitionController::class, 'import'])->name('prs.import');
    public function import(...) { return back()->with('info', 'Bulk import feature coming soon.'); }
- Why it's a risk: Live route advertises a feature that does nothing; orphan duplicate event file invites edits
  to the wrong copy (see BUG-INV-001).
- Fix: Hide the import route until implemented; delete the root Events/AssetDisposed.php duplicate.
- Confidence: High
- Systemic? : module-local.
```

---

## Layer Health Summary

| Layer | Status | Key finding |
|-------|--------|-------------|
| 1 DDL Schema | Amber | 15 ENUMs in DDL (D29); variance_qty intended GENERATED but plain (MIG-INV-001) |
| 2 Migration↔Model↔DDL | Amber | 28 tenant migrations DO exist (snapshot wrong); entry_type ENUM blocks adjustment posting |
| 3 Model & ORM | Green | Casts present; `$fillable` clean — no privilege fields; StockEntry documented immutable |
| 4 Code Quality | Amber | Misplaced Events/Listeners (BUG-INV-001); dead InventoryController stub (DEAD-INV-001); import stub |
| 5 Authorization | Amber | Controllers Gate-gated well; 16 policies registered; SEC-INV-002 reject uses grn.accept (known) |
| 6 Multi-Tenancy | Amber | RSP has full tenancy stack; no initialize-leak; ReorderAlertJob tenancy gap (JOB-INV-001) |
| 7 Validation/Mass-assign | Amber | All 19 FormRequests `authorize(){return true;}` (SEC-INV-001, D30); controllers use validated() |
| 8 Data Integrity/Tx | **Red** | DAT-INV-001 (P0) posting disabled; DAT-INV-002 sign/transfer; DAT-INV-003 race; DAT-INV-004 numbers |
| 9 Performance | Amber | PERF-INV-001/002 (known) + PERF-INV-003 unbounded report gets |
| 10 Queue/Job | **Red** | Job tenancy gap + broken listener wiring + scheduled command fatal (BUG-INV-001/JOB-INV-001) |
| 11 Frontend/Blade | Green | Only `{!! config('inventory.name') !!}` (scaffold, non-user); no client secrets |
| 12 Deployment | **Red** | Closure route breaks route:cache (DEPLOY-INV-01) |

---

## vs Platform Baseline
- **FormRequests `authorize(){return true}`:** 19/19 (100%) — worse than the 90% platform norm; already tracked as SEC-INV-001 (D30). Not re-registered.
- **ENUM in migrations (D29):** entry_type + DDL 15 — in line with the systemic ~476-call platform pattern.
- **Jobs missing tenancy:** ReorderAlertJob matches the role-doc baseline list (Vendor/Inventory/FrontOffice/Hostel).
- **Locking gaps:** Inventory was explicitly flagged in the baseline as "no lockForUpdate on stock decrement" — partially true: the balance WRITE is locked, but the negative-stock CHECK and the number generators are not (DAT-INV-003/004).
- **Better than baseline:** authorization coverage (controllers consistently `Gate::authorize`), clean `$fillable` (no privilege fields), and real transaction usage in GRN/Issue/Adjustment services.

## Snapshot Corrections (module-knowledge was stale)
1. **"0 migrations" is WRONG** — all 28 `inv_*` tenant migrations exist at `database/migrations/tenant/2026_06_15_*`. The module's own `database/migrations/` is empty (expected — migrations are centralized).
2. **`MaintenanceOverdue` event + 2 listeners exist** but are mis-located outside `app/` (BUG-INV-001) — the snapshot listed them as "missing"/"0 Listeners"; they are present-but-unwired.
3. FormRequest count is **19** (snapshot said 18) — `BulkTransferRequest` included.

## Recommended Fix Order
1. **DAT-INV-001** — re-enable adjustment posting (unblocks the entire physical-count integrity path). Pairs with MIG-INV-001 entry_type fix.
2. **DAT-INV-002 / DAT-INV-003** — unify adjustment/transfer signs and move the negative-stock guard inside the lock; add a balance-reconciliation test before trusting `recalculate-balances`.
3. **BUG-INV-001** — relocate Events/Listeners into `app/`, dump-autoload (restores dispose + scheduled command + D21 events).
4. **DEPLOY-INV-01** — de-closure the reports index route (unblocks route:cache).
5. **JOB-INV-001** — tenancy-init the reorder job (or confirm QueueTenancyBootstrapper).
6. **DAT-INV-004 / PERF-INV-003 / DEAD-INV-003** — sprint hygiene.

## Offer Next Steps
- Fix P0/P1 → act as **Developer**
- entry_type → sys_dropdown FK + variance_qty GENERATED → act as **DB Architect**
- Completeness score → act as **Status_Analyzer**
- Tests for posting/FIFO/concurrency → act as **Testing Architect**

---
*Read-only audit. No application code modified. Issue codes assigned continue from the current per-prefix maxima in `lessons/known-issues.md` (SEC-INV→002, VAL-INV→001, PERF-INV→002, DEAD-INV→002; DAT/BUG/JOB/MIG/DEPLOY-INV had none).*
