# Technical Audit — Library (LIB) — 2026-06-29

**Auditor:** Technical Auditor (AI_Brain agent) · **Mode:** A — Standard Deep 12-Layer Audit (read-only)
**Module dir:** `/Users/bkwork/Herd/prime_ai/Modules/Library/`
**Identifiers:** Module = Library · Code = **LIB** · Prefix = **lib_** (confirmed from `0-Prime_Ai_Detail/module_list.md`)
**FRD baseline cross-referenced:** `4-Requirement_Module_wise/0-FRD_Documents/LIB_FRD_2026-06-29.md` (v2.0 — 13 REQ / 60 BR)

---

## Executive Summary

The Library module is a large, mostly-built CRUD + circulation module (26 controllers, 35 models, 11 services, ~120 Blade views) with **tenancy isolation correctly wired** (full stancl middleware stack on every route) — that is its strongest layer. The worst finding is a **P0 `dd($e)` in the live `update()` catch block of `LibBookMasterController.php:481`**, which dumps a stack trace and halts the request on any book-update DB error. Combined with previously-registered open P0s (StaffLibraryController zero-auth SEC-LIB-010; 9 routed methods missing BUG-LIB-010; empty `LibraryController` stubs BUG-LIB-011), the module is **not production-safe**; health is hard-capped at **40/100**. New defects this pass concentrate in Layers 5/7/8: a fine-waiver permission that any Librarian can invoke (BR-LIB-048 violation), `$request->all()` mass-assignment into `lib_transactions`, an issue/checkout concurrency race with no row lock or transaction, and a fine-payment column-name bug that silently fails to reduce a member's outstanding balance.

## Audit Mode(s) Run
Mode A — full 12-layer scan, with FRD/BR cross-reference on the touched circulation and fine rules (Modes B/C spot-checks folded in where evidence was found).

## Health Score
**Capped at 40/100 (P0 present).** Uncapped weighted estimate ≈ 47/100 (Tenancy Green; Validation/Mass-assign, Data-Integrity, Authorization, Code-Quality Red). The cap is the governing number: a `dd()` in a live write path is a deploy blocker on its own, and three prior P0s remain open.

---

## P0 Findings

```
[BUG-LIB-012] Severity: P0 | dd($e) in live update() catch block
- Location: Modules/Library/app/Http/Controllers/LibBookMasterController.php:481
            (inside public function update(LibBookMasterRequest $request, $id), method starts :373)
- Evidence:
    } catch (\Exception $e) {
                dd($e);
        DB::rollBack();
        Log::error('Book update failed: ' . $e->getMessage());
- Why it's a risk: Any DB/QueryException during a book update (FK violation, deadlock, unknown column)
  triggers dd() — Laravel dumps a full stack trace (incl. SQL + bindings) to the browser and kills the
  request BEFORE DB::rollBack() runs, so the transaction is left to be rolled back only by connection
  teardown. Information disclosure + broken UX on a live, routed endpoint (route library.acquisitionIndex).
- Fix: Delete the dd($e); line. The catch already logs and redirects — that is the correct behaviour.
- Confidence: High
- Systemic?: Same class as BUG-TPT-NNN (Transport TripController:587). Library-local instance.
```

---

## P1 Findings

```
[SEC-LIB-012] Severity: P1 | Fine waiver gated by generic update permission, not Supervisor-only (BR-LIB-048)
- Location: Modules/Library/app/Http/Controllers/LibFineController.php:339 (waive), :321 (waivePage)
- Evidence:
    public function waive(LibFineWaiveRequest $request, $id)
    {
        Gate::authorize('tenant.lib-fines.update');   // same permission as markPaid()/payment()
        ...
        $fine->waive(Auth::id(), $request->waived_amount, $request->waived_reason);
- Why it's a risk: FRD BR-LIB-048 / Role-Access matrix: "Only a Library Supervisor may waive a fine. A
  Librarian cannot waive fines." The waiver shares the same 'tenant.lib-fines.update' permission used by
  pay/collect, so any Librarian who can record a payment can also forgive fine revenue — a financial
  segregation-of-duties breach. Note the LibFineWaiveRequest authorize() returns true (D30), so there is
  no FormRequest fallback either.
- Fix: Introduce a distinct permission (e.g. 'tenant.lib-fines.waive') assigned only to Library Supervisor;
  gate waive()/waivePage() on it. Mirror in LibFineWaiveRequest::authorize() via Gate::allows().
- Confidence: High
- Systemic?: D24 (permission taxonomy) — local manifestation: missing granularity, not a typo.
```

```
[SEC-LIB-013] Severity: P1 | $request->all() mass-assignment into lib_transactions (D25)
- Location: Modules/Library/app/Http/Controllers/LibTransactionController.php:314
            (+ LibInventoryAuditDetailController.php:437, LibFineSlabDetailController.php:50 & :94)
- Evidence:
    $transaction->update($request->all());
- Why it's a risk: LibTransaction::$fillable includes member_id, status, due_date, issue/return dates,
  renewal_count, received_by_id. update($request->all()) lets a crafted request rewrite a transaction's
  member, status, or due/return dates outside any validated rule set — re-pointing a checkout to another
  member or back-dating a return to dodge a fine. No privilege column on the model (so P1, not P0), but
  it is a circulation-integrity hole. LibTransactionRequest::authorize() returns true (D30), no fallback.
- Fix: Replace with $request->validated() at all 4 sites; ensure the FormRequest rules() whitelist only
  editable fields.
- Confidence: High
- Systemic?: D25 (24 sites platform-wide; Library named a heavy contributor).
```

```
[BUG-LIB-013] Severity: P1 | Fine payment decrements outstanding balance by a non-existent attribute
- Location: Modules/Library/app/Http/Controllers/LibFinePaymentController.php:46-47
- Evidence:
    $member->increment('total_fines_paid', $payment->amount);
    $member->decrement('outstanding_fines', $payment->amount);
  (LibFinePayment column is 'amount_paid' — confirmed: $fillable=['amount_paid'], cast decimal:2,
   migration 2026_06_15_151425_create_lib_fine_payments_table.php:16 -> decimal('amount_paid',10,2).
   No 'amount' column and no getAmountAttribute() accessor exists.)
- Why it's a risk: $payment->amount resolves to NULL. increment()/decrement() by NULL either no-ops or
  raises a QueryException (SET col = col + NULL). Either way the partial-payment path through
  LibFinePaymentController does NOT reduce the member's outstanding_fines or raise total_fines_paid —
  BR-LIB-047 silently broken; member balances drift and never clear via this screen.
- Fix: Use $payment->amount_paid at both lines. Add a regression test asserting outstanding_fines drops.
- Confidence: High
- Systemic?: Module-local (D17-adjacent: code references a column the model/table doesn't expose).
```

```
[DAT-LIB-001] Severity: P1 | Book issue (checkout) eligibility is an unlocked read-modify-write with no transaction
- Location: Modules/Library/app/Http/Controllers/LibTransactionController.php:94-224 (store())
            CHECK-1 copy availability :102-103 ; CHECK-4 max-books count :146-149 ; writes :173-196
- Evidence:
    if ($copy->status != $availableStatusId) { return back()->with('error', ...); }   // no lockForUpdate
    ...
    $currentIssuedCount = LibTransaction::where('member_id',$member->id)->whereIn('status',[...])->count();
    if ($currentIssuedCount >= $membershipType->max_books_allowed) { return back()...; }
    ...
    $transaction = LibTransaction::create([...]);          // then $copy->update(['status'=>issued]); then
    $member->increment('total_books_borrowed');            // — no surrounding DB::transaction in store()
- Why it's a risk: TOCTOU race (BR-LIB-019/021). Two concurrent checkouts of the SAME copy both read
  status='available' -> both create a transaction and both flip the copy to issued = one physical book
  issued twice. Two concurrent checkouts for a member one below their limit both read count<max -> member
  exceeds max_books_allowed. The three writes (transaction insert + copy update + member increment) are
  also not atomic, so a mid-sequence failure leaves a transaction row with the copy never marked issued.
- Fix: Wrap store() in DB::transaction() and SELECT the copy row FOR UPDATE
  (LibBookCopy::lockForUpdate()->find($copy_id)) and re-check status inside the lock; re-count issued
  books inside the same transaction. A DB UNIQUE on lib_book_copies.current_transaction_id also helps.
- Confidence: High (no lock present anywhere in module — confirmed grep: 0 lockForUpdate);
  Medium on the no-transaction point (store() body 94-224 shows no DB::transaction wrapper).
- Systemic?: Layer 8 locking-gap class (same as StudentFee/Inventory/Hostel balance paths).
```

```
[VAL-LIB-003] Severity: P1 | Fine payment amount not validated against remaining balance (BR-LIB-044); status not auto-settled (BR-LIB-046)
- Location: Modules/Library/app/Http/Requests/LibFinePaymentRequest.php:14-23
            Modules/Library/app/Http/Controllers/LibFinePaymentController.php:36-58 (store)
- Evidence:
    'amount_paid' => 'required|numeric|min:0.01',     // no max:remaining-balance, no cross-field rule
    ...
    $payment = LibFinePayment::create($request->validated());   // store() never re-reads the fine,
    // never compares sum(payments)+waived to fine.amount, never flips fine.status to Paid
- Why it's a risk: BR-LIB-044 ("payment cannot exceed remaining unpaid balance") is unenforced — a member
  can be over-collected / the fine driven negative. BR-LIB-046 ("when paid+waived = total, status -> Paid")
  is not applied on this path, so fully-paid fines remain Pending and re-collectible.
- Fix: Add a closure/`after` validation rule computing remaining = fine.amount - paid - waived and reject
  amount_paid > remaining; on store, recompute totals and transition fine.status to Paid when settled
  (ideally inside the same locked transaction as DAT-LIB-002).
- Confidence: High
- Systemic?: Mode-C business-rule gap (BR-LIB-044, BR-LIB-046).
```

---

## P2 Findings

```
[DAT-LIB-002] Severity: P2 | Fine collection/waiver balance updates are unlocked; two payment paths diverge
- Location: LibFine.php:143,176 (markPaid/waive decrement) ; LibFineController.php:196,220,261 ;
            LibFinePaymentController.php:46-47 ; FineCalculationService.php:199
- Evidence: every outstanding_fines mutation uses a bare ->decrement()/->increment() with no row lock and
  no surrounding lock on the fine row; the model path (LibFine::markPaid -> decrement payable_amount) and
  the controller path (LibFinePaymentController -> decrement payment amount) are independent and can both
  run for one fine.
- Why it's a risk: increment/decrement are atomic per-statement, but the Pending->Paid status check that
  precedes them is a read-modify-write; concurrent collect+waive on one Pending fine can both pass the
  status guard and double-reduce outstanding_fines. The two divergent paths make double-decrement reachable.
- Fix: Single fine-settlement service; SELECT fine FOR UPDATE, re-check Pending, apply payment/waiver,
  recompute status, all in one transaction. Retire the redundant path.
- Confidence: Medium
- Systemic?: Layer 8.2 locking-gap.
```

```
[SEC-LIB-014] Severity: P2 | Library route group lacks the module-subscription gate (EnsureTenantHasModule / tenant.module:Library)
- Location: Modules/Library/app/Providers/RouteServiceProvider.php:41-50
- Evidence: middleware stack = ['web', InitializeTenancyByDomain, PreventAccessFromCentralDomains,
  EnsureTenantIsActive, 'auth', 'verified'] — no 'tenant.module:Library'.
- Why it's a risk: Tenancy ISOLATION is intact (this is NOT a cross-tenant leak). But a tenant that has not
  subscribed to the Library module can still reach every /library/* route. Feature-entitlement bypass, not
  a data breach -> P2 (module-knowledge previously rated P0; downgraded after confirming full tenancy stack).
- Fix: Append 'tenant.module:Library' to the RSP middleware array.
- Confidence: High
- Systemic?: Module-entitlement convention (platform-wide pattern to verify).
```

```
[Reference] God controllers (Layer 4.4) — extract to services
- LibTransactionController.php 1396 ; LibInventoryAuditController.php 1384 ; StaffLibraryController.php 1122 ;
  LibExportController.php 1044 ; LibraryController.php 1039. All >1000 lines -> P1 decompose backlog
  (LibInventoryAuditController also carries ~260 lines of commented alternates = DEAD-LIB-002, already open).
- LibCirculationReportService uses in-memory collection iteration (module-knowledge perf note) — confirm at scale.
```

---

## P3 Findings

```
[DEAD-LIB-014] Severity: P3 | Unused Vendor model import in 18 controllers (copy-paste artifact)
- Location: 18 of 26 controllers carry `use Modules\Vendor\Models\Vendor;` — only LibBookCopyController
  (and the acquisition/purchase flow) legitimately needs it.
- Fix: Remove the unused import from the 17 controllers that never reference Vendor.
- Confidence: High  | Systemic?: hygiene.
```

```
[Layer 11 note] {!! $model->status_badge !!} in ~8 transaction/copy views and {!! $content !!} in the
PDF report layout. status_badge is a server-generated HTML badge from a controlled status string (not raw
user input) and staff-library/show.blade.php:398 correctly uses nl2br(e($summary)). No raw user-field XSS
found -> P3/clear. Re-verify status_badge accessors never interpolate unescaped member/book free-text.
```

---

## Layer Health Summary

| Layer | Status | Key finding |
|-------|--------|-------------|
| 1 DDL Schema | Amber | DDL v7 migration blockers already logged (DDL-001 lib_reservations rename in views/indexes; DDL-002 missing lib_background_services) — see module-knowledge. Not re-derived live this pass. |
| 2 Migration↔Model↔DDL | Amber | Code references column that doesn't exist (BUG-LIB-013: `amount` vs `amount_paid`). |
| 3 Model & ORM | Amber | Same column-ref defect; casts otherwise present. |
| 4 Code Quality | **Red** | P0 dd($e) live catch (BUG-LIB-012); 5 controllers >1000 lines; DEAD-LIB-002 commented alternates; DEAD-LIB-014 vendor imports. |
| 5 Authorization | **Red** | Waiver SoD breach (SEC-LIB-012, P1); StaffLibraryController zero-auth (SEC-LIB-010, prior P0, still open). |
| 6 Multi-Tenancy | **Green** | Full stancl stack on all routes; no initialize()-without-end(); no bare-string tenant cache keys found. |
| 7 Validation / Mass-assign | **Red** | D25 4 sites (SEC-LIB-013); D30 28/28 FormRequests return true (SEC-LIB-011, prior); BR-LIB-044 unvalidated (VAL-LIB-003). |
| 8 Data Integrity / Tx | **Red** | Checkout TOCTOU + non-atomic writes (DAT-LIB-001); unlocked fine settlement (DAT-LIB-002). |
| 9 Performance | Amber | User::all() in 7 controller methods (PERF-LIB-004 prior); with:get ratio 436:379 ≈ 1.15 (healthy). |
| 10 Queue/Job/Scheduler | Amber | No jobs/scheduled commands exist — BR-LIB-036 (expire reservations) & membership expiry are manual-only (FRD gap, not a broken job). |
| 11 Frontend/Output | Green | Only controlled status_badge HTML and escaped nl2br(e()); no raw user-field output. |
| 12 Deployment | Amber | No env() in module app, no route closures (clean); missing module-subscription gate (SEC-LIB-014, P2). |

## FRD / Business-Rule Cross-Reference (spot findings)
- **BR-LIB-048** (only Supervisor waives) — **VIOLATED** → SEC-LIB-012.
- **BR-LIB-044** (payment ≤ remaining balance) — **MISSING** → VAL-LIB-003.
- **BR-LIB-046** (auto-settle to Paid when paid+waived=total) — **MISSING on payment path** → VAL-LIB-003.
- **BR-LIB-047** (balance decreases on payment) — **BROKEN on partial-payment path** → BUG-LIB-013.
- **BR-LIB-019 / BR-LIB-021** (borrow-limit / copy-available) — enforced functionally but **race-exposed** → DAT-LIB-001.
- **BR-LIB-025** (grace-period in overdue days) — prior known gap (grace_period_days not deducted); unchanged.

## vs Platform Baseline
- D30: **28/28 FormRequests return `true`** — at/above the 90% platform norm (SEC-LIB-011, already open; count grew 27→28 with StoreLibBookPurchaseRequest).
- D25: 4 `$request->all()` write sites — consistent with Library being a "heaviest" contributor in the baseline.
- Tenancy: **better than baseline** — full stack present (no D23 gap), unlike the platform's several RSP gaps.
- Locking: **at the platform locking-gap norm** — 0 `lockForUpdate` in a module that mutates copy status, borrow counters, and fine balances.

## Recommended Fix Order
1. **BUG-LIB-012** — delete `dd($e)` (1 line; unblocks the cap driver). [Developer]
2. **SEC-LIB-010 (prior)** + **SEC-LIB-012** — add real gates to StaffLibraryController; split waiver permission. [Developer]
3. **BUG-LIB-013** — `amount` → `amount_paid` (silent balance corruption). [Developer]
4. **DAT-LIB-001 / DAT-LIB-002** — wrap checkout + fine settlement in transactions with `lockForUpdate`. [Developer]
5. **SEC-LIB-013 / VAL-LIB-003** — `$request->validated()` + BR-LIB-044/046 enforcement. [Developer]
6. **BUG-LIB-010 / BUG-LIB-011 (prior)** — implement the 9 missing routed methods and the empty LibraryController stubs (500s today). [Developer]
7. **SEC-LIB-014 / DEAD-LIB-014** — module gate + import cleanup. [Developer]

---

### New Issue Codes Assigned (this pass)
| Code | Title | Severity | File:Line |
|------|-------|----------|-----------|
| BUG-LIB-012 | dd($e) in live update() catch block | P0 | LibBookMasterController.php:481 |
| SEC-LIB-012 | Fine waiver gated by generic update perm, not Supervisor (BR-LIB-048) | P1 | LibFineController.php:339,321 |
| SEC-LIB-013 | $request->all() mass-assign into lib_transactions (D25) | P1 | LibTransactionController.php:314 (+437, +50, +94) |
| BUG-LIB-013 | Fine payment decrements by non-existent `amount` (col is amount_paid) | P1 | LibFinePaymentController.php:46-47 |
| DAT-LIB-001 | Checkout eligibility race — no lock/transaction (BR-LIB-019/021) | P1 | LibTransactionController.php:94-224 |
| VAL-LIB-003 | Fine payment not validated vs remaining balance; no auto-settle (BR-LIB-044/046) | P1 | LibFinePaymentRequest.php:14-23 + LibFinePaymentController.php:36-58 |
| DAT-LIB-002 | Unlocked fine-settlement; two divergent payment paths | P2 | LibFine.php:143,176; LibFineController.php:196-261; LibFinePaymentController.php:46-47 |
| SEC-LIB-014 | Library routes lack module-subscription gate (tenant.module:Library) | P2 | RouteServiceProvider.php:41-50 |
| DEAD-LIB-014 | Unused Vendor import in 18 controllers | P3 | Modules/Library/app/Http/Controllers/ (17 redundant) |

### False Positives Cleared (guardrails applied)
- **Layer 5.2 "commented gates in LibInventoryAuditController (5 sites)"** (350,458,511,545,729) — these `// Gate::authorize` lines sit inside **fully commented-out alternate method bodies**; the live methods immediately below (create() :367, edit() :560, etc.) all carry active `Gate::authorize`. NOT an authorization hole — it is dead code already captured by DEAD-LIB-002. No SEC code assigned.
- **Module-knowledge claim "LibFineController has zero Gate::authorize"** — STALE. Every LibFineController action (incl. waive :339, markPaid :293) now has a `Gate::authorize`. The residual issue is permission *granularity* (SEC-LIB-012), not absence.

---

## STEP 1 Reading-Discipline Output (D-pattern) — added 2026-06-29

### Three-Way Schema Reconciliation (DDL ↔ migration ↔ model)
| Subject | DDL spec | Live migration | Eloquent model / code | Verdict |
|---------|----------|----------------|-----------------------|---------|
| Fine payment amount | `amount_paid` column | migration confirms `amount_paid` (no `amount`) | code decrements by `$payment->amount` | **code↔migration column-name mismatch** → NULL decrement, `outstanding_fines` never reduced → BUG-LIB-013 (P1). Caught only by reading the migration, not the model. |
| `lib_transactions` | — | columns present | `$fillable` exposes `member_id/status/dates` | model + `update($request->all())` → mass-assignment → SEC-LIB-013 (D25). |

### Module-Knowledge Snapshot Corrections (hints vs live code)
- "Tenancy not fully wired / D23 gap" → **stale**: the full stancl stack is present on all Library routes — **not** a D23 offender.
- "LibFineController zero-auth" → **corrected**: it **is** gated; the real issue is permission **granularity** (waiver shares the pay permission → SEC-LIB-012), not absence of auth.
- The 5 "commented gates" in `LibInventoryAuditController` are **dead alternate method bodies** (the live methods below are gated) → false positive cleared (tracked as DEAD-LIB-002).
