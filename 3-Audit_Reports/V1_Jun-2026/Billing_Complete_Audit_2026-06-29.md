## Complete Audit — Billing (BIL) — 2026-06-29      (Mode X: A+B+C+G + scoped D)

| Field | Value |
|-------|-------|
| Module | Billing (BIL) | 
| Layer | **prime_db** (central / Prime-layer — NOT tenant) |
| Prefix | `bil_*` (+ shared `prm_billing_cycles`) |
| App code | `Modules/Billing/` |
| Schema authority | `0-DDL_Masters/prime_db_v4.sql` (0 migrations) |
| FRD baseline | `BIL_FRD_Complete_2026-06-29.md` (17 REQ · 43 BR · 7 RPT) |
| Auditor | Technical Auditor (pa-technical-auditor, Mode X) |
| Health | **37 / 100 — P0 cap applies (multiple P0)** |
| Deploy | **NO-GO** |

---

### Executive Summary
Billing is a central Super-Admin SaaS-invoicing module that is **functionally ~60% complete but structurally fragile**: against the authoritative DDL (`prime_db_v4.sql`, 0 migrations) **every Billing model declares `SoftDeletes` and default timestamps, yet not one of the six tables carries the matching `deleted_at`/`updated_at` columns** — so on a clean prime_db built from the DDL, billing-cycle CRUD, invoice reads, payment writes and audit inserts all throw `SQLSTATE 42S22 Unknown column`. The worst finding class is therefore Layer-2 schema↔model divergence (audit-log FK column mismatch, phantom `invoice_amount` in `$fillable`, SoftDeletes-without-column), compounded by Layer-8 data-integrity holes (payment posting opens a `DB::beginTransaction()` with **no rollback** and an early `return` while the transaction is still open). Authorization is genuinely **not** "fully bypassed" (a Spatie/super-admin `Gate::before` resolves the dotted abilities), but nine routed methods — including a note-edit **write** — carry no permission check, and `$request->all()` is persisted into the audit `event_info` JSON (BR-BIL-022 violation). With several P0s present the module health is capped; **deploy verdict is NO-GO.**

### Audit Mode(s) Run
Mode A (12-layer) + Mode B (FRD gap, 17 REQ) + Mode C (43 BR enforcement) + Mode G (deploy gate) + Mode D scoped (systemic patterns for BIL). One unified report; each defect coded once.

### Health Score
Weighted index = **37/100** (L2 Red, L4 Red, L8 Red; L5/L6/L7/L9/L10/L12 Amber). **Hard P0 cap = 40** — applies (weighted already below cap). A central module that cannot complete its core CRUD against its own authoritative schema is "not healthy", period.

### Deploy Gate Verdict — **NO-GO**
Blocking items:
- **MIG-BIL-001 (P0)** — SoftDeletes + default timestamps across all models vs DDL tables with no `deleted_at`/`updated_at` → core CRUD throws on a schema-correct DB.
- **DATA-BIL-001 (P0)** — audit-log column-name mismatch → every audit insert fails on a correct DB.
- **DATA-BIL-002 (P0)** — `$fillable` phantom `invoice_amount` (not in DDL) → invoice persist path references a non-existent column.
- **ERR / SEC-BIL-001 + SEC-BIL-002 (P0, pre-existing codes)** — payment `store()` / `consolidatedStore()` open a transaction with no rollback and an early return inside the open transaction.

(No committed secret, no anonymous-write route, no cross-tenant data path in the deploy sense — but the schema/data-integrity P0s are independently disqualifying.)

---

## P0 Findings

```
[MIG-BIL-001] Severity: P0 | SoftDeletes + default timestamps on every model, but the DDL tables have no deleted_at / updated_at
- Location:
    Modules/Billing/app/Models/BillingCycle.php:15      (use SoftDeletes; table prm_billing_cycles)
    Modules/Billing/app/Models/BilTenantInvoice.php:16
    Modules/Billing/app/Models/InvoicingPayment.php:12
    Modules/Billing/app/Models/InvoicingAuditLog.php:12
    Modules/Billing/app/Models/BillTenatEmailSchedule.php (no SoftDeletes, default timestamps)
    DDL: prime_db_v4.sql:405 prm_billing_cycles (NO created_at/updated_at/deleted_at),
         :545 bil_tenant_invoices (created_at/updated_at, NO deleted_at),
         :603 bil_tenant_invoicing_payments (NO deleted_at),
         :623 bil_tenant_invoicing_audit_logs (created_at only — NO updated_at, NO deleted_at)
- Evidence:
    // BillingCycle.php
    use HasFactory, SoftDeletes;            protected $table = 'prm_billing_cycles';
    // prm_billing_cycles DDL — columns end at is_active; NO deleted_at, NO created_at/updated_at
- Why it's a risk: SoftDeletes silently appends `WHERE deleted_at IS NULL` to every query and default
    $timestamps writes created_at/updated_at on insert/update. On a prime_db built from this DDL, EVERY
    billing-cycle read/write, invoice soft-delete query, payment write and audit insert raises
    SQLSTATE[42S22] Unknown column. This makes the BA "Built/clean" status for REQ-BIL-001 incorrect
    against the schema authority.
- Fix: add `deleted_at TIMESTAMP NULL` + standard `created_at/updated_at` to all five bil_/prm_billing_cycles
    tables via migration, OR remove SoftDeletes/disable $timestamps where the table genuinely has none.
    Reconcile model↔DDL before any other Billing fix.
- Confidence: High (DDL + model both read).
- Systemic?: D17 / Layer-2 three-way divergence (same class as HST/INV/CMP 2026-06-29).
- Condition: degrade to P1 only if the LIVE prime_db was hand-patched with these columns out-of-band
    (likely in dev, since the app runs) — but per the stated schema authority (DDL, 0 migrations) it is P0.
```

```
[DATA-BIL-001] Severity: P0 | Audit-log model/inserts use `tenant_invoicing_id`; DDL column is `tenant_invoice_id` (+ updated_at missing)
- Location:
    Modules/Billing/app/Models/InvoicingAuditLog.php:17 ($fillable), :32 (invoice() relation)
    Modules/Billing/app/Models/BilTenantInvoice.php:105 (auditLogs() relation: 'tenant_invoicing_id')
    Inserts: InvoicingPaymentController.php:79, :221 ; BillingManagementController.php:500,564,795,923 ; SendInvoiceEmailJob.php:38
    DDL: prime_db_v4.sql:625  `tenant_invoice_id INT UNSIGNED NOT NULL`
- Evidence:
    // InvoicingAuditLog.php
    protected $fillable = ['tenant_invoicing_id', 'action_type', ...];
    public function invoice(){ return $this->belongsTo(BilTenantInvoice::class, 'tenant_invoicing_id'); }
    // DDL bil_tenant_invoicing_audit_logs
    `tenant_invoice_id` INT UNSIGNED NOT NULL,   -- fk to (bil_tenant_invoices)
- Why it's a risk: every audit insert and every audit-log read/relationship targets a column the table does
    not have → audit trail (REQ-BIL-011, BR-BIL-031/034/035) silently fails on a correct DB. Compounded by
    the table having `created_at` only while the model uses default timestamps (writes a non-existent
    `updated_at` on every insert/`save()`, e.g. auditAddNoteUpdate).
- Fix: rename model `$fillable`, both relations, and all six insert sites to `tenant_invoice_id` (DDL is the
    correct side); set `public $timestamps` appropriately or add `updated_at` to the table.
- Confidence: High.
- Systemic?: D17 / Layer-2.
```

```
[DATA-BIL-002] Severity: P0 | BilTenantInvoice $fillable contains phantom `invoice_amount` and duplicates 8 fields
- Location: Modules/Billing/app/Models/BilTenantInvoice.php:20–69
- Evidence:
    'invoice_amount',                 // line 30 — NOT a column in bil_tenant_invoices
    ... 'paid_amount','currency','status','credit_days','payment_due_date',
        'is_recurring','auto_renew','remarks'   // declared twice (lines 31-38 AND 61-68)
    // DDL has sub_total / net_payable_amount — there is no invoice_amount column
- Why it's a risk: any code path that mass-assigns `invoice_amount` errors with Unknown column; the duplicated
    block is a maintenance trap. (The generate path does not currently set invoice_amount, which is the only
    reason it has not surfaced yet.)
- Fix: remove `invoice_amount` and the duplicated 8-field block; keep one clean fillable.
- Confidence: High (DDL + model read).
- Systemic?: D17.
```

> **Pre-existing P0 codes reused (data integrity):**
```
[SEC-BIL-001] Severity: P0 | InvoicingPaymentController::store() — DB::beginTransaction() with NO try/catch/rollBack
[SEC-BIL-002] Severity: P0 | InvoicingPaymentController::consolidatedStore() — same; PLUS early return inside open transaction
- Location: InvoicingPaymentController.php:52 (begin) → :100 (commit), no rollback;
            :158 (begin) → :247 (commit); early `return response()->json(...)` at :164 while tx is OPEN
- Evidence:
    DB::beginTransaction();
    if (!$request->invoice_ids || count($request->invoice_ids) == 0) {
        return response()->json([...]);     // returns with transaction still open, no rollBack/commit
    }
- Why it's a risk: an exception between begin and commit leaves the connection with a dangling transaction
    (only PDO's end-of-request rollback saves the data); the empty-invoice early return is a guaranteed
    open-transaction leak per request. Violates BR-BIL-021 / BR-BIL-026 (atomic posting).
- Fix: wrap both in `DB::transaction(function(){...})` (as generateInvoiceForOrganization already does), or add
    try/catch with DB::rollBack(); move the empty-selection guard BEFORE beginTransaction().
- Confidence: High.   Systemic?: module-local (mirrors Payment-module pattern).
```

---

## P1 Findings

```
[SEC-BIL-010] Severity: P1 | Nine routed methods have no Gate::authorize (one is a write)
- Location:
    InvoicingPaymentController.php:108 paymentDetails(), :257 downloadConsolidatedPdf(), :307 downloadSelectedPdf()
    InvoicingAuditLogController.php:78 auditAddNote(), :87 auditAddNoteUpdate() [WRITE], :101 auditEventInfo(), :113 downloadAuditNotePdf()
    SubscriptionController.php:92 pricingDetails(), :105 billingDetails()
- Evidence:
    public function auditAddNoteUpdate(Request $request){
        $log = InvoicingAuditLog::findOrFail($request->id);
        $log->notes = $request->notes; $log->save();   // edits an audit note — no permission check
    }
- Why it's a risk: all billing routes sit behind ['auth','verified'] (routes/web.php:312), so this is NOT
    anonymous access — but ANY authenticated central user (e.g. a read-only Prime Manager) can read payment
    detail / financial PDFs and EDIT audit notes without the matching billing permission. Violates NFR-BIL-004
    and the append-only spirit of BR-BIL-034.
- Fix: add the appropriate `Gate::authorize('prime.<entity>.<action>')` to each (the sibling methods already do).
- Confidence: High.   Systemic?: module-local (subset of the seed-era SEC list; most others already fixed).
```

```
[SEC-BIL-011] Severity: P1 | Raw $request->all() persisted into audit event_info (BR-BIL-022 violation)
- Location: InvoicingPaymentController.php:94
- Evidence:
    'event_info' => json_encode([ ... 'request_data' => $request->all(), ]),
- Why it's a risk: the entire payment request (incl. gateway_resp and any future sensitive fields) is stored
    verbatim in the audit JSON. Directly violates BR-BIL-022 / NFR-BIL-005 ("whitelist only; no raw data").
    Note consolidatedStore() does NOT do this — it is the cleaner template.
- Fix: drop the 'request_data' key; keep only the already-listed whitelist of payment fields.
- Confidence: High.   Systemic?: D25-adjacent (mass-data into a column).
```

```
[BUG-BIL-010] Severity: P1 | Invoice status is taken from request input, never derived from cumulative paid (BR-BIL-023 not enforced)
- Location: InvoicingPaymentController.php:75 (store), :211-213 (consolidatedStore); generate sets ordinal-1 PENDING (BillingManagementController.php:712,761)
- Evidence:
    $invoice->paid_amount = $invoice->paid_amount + $request->amount_paid;
    $invoice->status = $request->payment_status;     // not computed from paid >= net_payable_amount
- Why it's a risk: BR-BIL-023 requires status = Paid when cumulative paid >= net payable, else Partially Paid.
    Here the client supplies the status, so an invoice can be marked Paid with paid_amount < net_payable (or
    left Pending after full payment). Status integrity depends on the UI, not the server.
- Fix: compute status server-side from (paid_amount >= net_payable_amount) using the configured Paid/Partial
    dropdown ids; ignore client-supplied status.
- Confidence: High.   Systemic?: module-local.
```

```
[BUG-BIL-015] Severity: P1 | Invoice-number generation is not concurrency-safe (BR-BIL-006)
- Location: BillingManagementController.php:660-662
- Evidence:
    $todayInvoiceCount = BilTenantInvoice::whereDate('created_at', $today)->count() + 1;
    $invoiceNo = 'INV-' . date('Ymd') . '-' . str_pad($todayInvoiceCount, 3, '0', STR_PAD_LEFT);
- Why it's a risk: two generations in the same day/instant read the same count → identical invoice_no →
    the DDL UNIQUE key (uq_tenantInvoices_invoiceNo) rejects the second insert and rolls back the whole
    invoice (the txn is atomic, so no corruption — but the second generate fails confusingly). Race on the
    counter, not just a uniqueness guarantee.
- Fix: derive NNN inside the transaction with a row lock on a sequence/last-invoice, or catch the unique
    violation and retry; or use a dedicated daily counter table with lockForUpdate.
- Confidence: High.   Systemic?: Layer 8.2 (counter without lock).
```

```
[BUG-BIL-011] Severity: P1 | generateInvoiceForOrganization() returns bool `false`, but store() reads it as an array
- Location: BillingManagementController.php:646 (return false) vs :612-617 (store reads $result['status']/$result['message'])
- Evidence:
    if (!$planRate) { return false; }                       // line 646
    ...
    if ($result['status'] === true) {...} else { 'reason' => $result['message'] }   // null-access on bool
- Why it's a risk: when the plan rate is missing, the method returns a bool; `$result['status']` and
    `$result['message']` on a bool yield null (PHP 8 warning), so the "failed" report shows a null reason and
    the operator gets no actionable error. Inconsistent contract (other paths return ['status'=>true]).
- Fix: return ['status'=>false,'message'=>'No applicable plan rate'] instead of false.
- Confidence: High.   Systemic?: module-local.
```

> **Pre-existing P1 code reused:**
```
[SEC-BIL-005] Severity: P1 | Tenancy::initialize() / end() without try/finally (cross-context leak risk, BR-BIL-008)
- Location: BillingManagementController.php:670-674 (inside the DB::transaction closure)
- Evidence:
    Tenancy::initialize($tenant);
    $totalUserQty = Student::where('is_active','1')->whereBetween('created_at',[...])->count();
    Tenancy::end();
- Why it's a risk: if the Student count query throws, Tenancy::end() never runs → the default connection stays
    pointed at the tenant DB for the rest of the request (Layer 6.2). It is also invoked mid prime-transaction,
    swapping the active connection while a prime transaction is open.
- Fix: use `$tenant->run(fn() => Student::...->count())` (auto-reverts), or wrap in try/finally with end() in finally;
    perform the count BEFORE opening the prime transaction.
- Confidence: High.   Systemic?: Layer 6.2.
```

---

## P2 Findings

```
[BUG-BIL-005] Severity: P2 | Consolidated-payment print path crashes (getCollection() on a Collection + isNotEmpty() on a float)
- Location: BillingManagementController.php:171-173 (printData, type=consolidated-payment)
- Evidence:
    $recordPayment = $this->buildConsolidatedPaymentQuery()->get();      // returns a Collection
    $totalPayable  = $recordPayment->getCollection()->sum('net_payable_amount');  // getCollection() not on Collection
    if ($totalPayable->isNotEmpty()) {                                   // isNotEmpty() on a float → fatal
- Why it's a risk: RPT-BIL-003 consolidated-payment Print view throws a fatal error every time. (Pre-existing
    code BUG-BIL-005 was logged for the float ->isNotEmpty(); the getCollection() misuse is the same branch.)
- Fix: $totalPayable = $recordPayment->sum('net_payable_amount'); drop the ->isNotEmpty() guard or use count().
- Confidence: High.   Systemic?: module-local.
```

```
[BUG-BIL-013] Severity: P2 | Broken route billing-management.view → @view (method does not exist) — RT-03
- Location: routes/web.php:332 (and dup :579, :~889) → BillingManagementController has no view() method
- Evidence:
    Route::get('/billing-management/view/{id}', [BillingManagementController::class, 'view'])->name('billing-management.view');
    // grep "function view" in the controller → none (subscriptionDetails uses the .view permission instead)
- Fix: remove the route or add the method; the detail panels already use subscriptionDetails/invoiceDetails.
- Confidence: High.   Systemic?: Layer 4.1.
```

```
[BUG-BIL-014] Severity: P2 | Central billing route block registered 3× (RT-04)
- Location: routes/web.php:312-414, :559-661, :889+ (system-config/scheduler/billing/global-master all triplicated inside one central. domain group)
- Why it's a risk: duplicate route-name registration (last wins) — functionally tolerated by Laravel but a real
    merge/maintenance hazard; ~75 'billing-management' route lines across three copies.
- Fix: keep one billing group; delete the two duplicate central-domain bodies.
- Confidence: High.   Systemic?: platform routing hygiene (also affects SystemConfig/Scheduler/GlobalMaster).
```

```
[DATA-BIL-003] Severity: P2 | Missing standard columns / FK / index on the bil_ tables
- Location: prime_db_v4.sql:545,594,603,623,636
- Evidence: bil_tenant_invoices/payments/audit_logs/modules_jnt lack created_by, is_active; modules_jnt FK
    `module_id` → `glb_modules` which the DDL comment itself flags as "a VIEW in prime_db" (FK to a VIEW is
    invalid in MySQL); bil_tenant_email_schedules has NO FK on invoice_id; audit_logs has no index on action_date.
- Fix: M-01..M-10 per FRD §I.4 — add created_by/is_active, fix modules_jnt FK to reference global_master.glb_modules,
    add email-schedule FK + index on action_date.
- Confidence: High.   Systemic?: convention compliance (Layer 1/2.5).
```

```
[VAL-BIL-001] Severity: P2 | Thin validation + D30 authorize()=true on both payment FormRequests
- Location: ConsolidatedPaymentRequest.php:9 (authorize returns true), rules() has NO invoice_ids/new_payment/payment_status array rules;
            StoreInvoicePaymentRequest.php:12 (authorize returns true)
- Why it's a risk: consolidatedStore() trusts $request->invoice_ids / new_payment[] / payment_status[] with no
    rules — allocation amounts and per-invoice status are unvalidated (BR-BIL-024/025 thin). authorize()=true is
    the platform-systemic D30 pattern (defense-in-depth gap; controller gates still present, so not a breach).
- Fix: add array rules ('invoice_ids'=>'array','new_payment.*'=>'numeric|min:0', ...); make authorize() return
    Gate::allows('prime.invoicing-payment.create').
- Confidence: High.   Systemic?: D30.
```

```
[JOB-BIL-001] Severity: P2 | SendInvoiceEmailJob has no $tries/$backoff/$timeout/failed(); auth()->id() null on worker
- Location: Modules/Billing/app/Jobs/SendInvoiceEmailJob.php:17-52
- Evidence: class declares no reliability props; handle() writes audit `performed_by => auth()->id() ?? null`
    (always null in queue context); no failed() to mark the email schedule 'failed' (BR-BIL-030 / state C.3).
- Why it's a risk: a transient mail/PDF failure is lost with no retry and the scheduled-email row stays 'pending'
    forever. (No tenancy re-init needed — it reads prime_db bil_* + central Tenant only.)
- Fix: add public $tries=3, $backoff=[60,300], $timeout=120 and a failed() that sets the schedule to 'failed';
    pass the acting user id into the constructor instead of relying on auth().
- Confidence: High.   Systemic?: Layer 10.1.
```

```
[PERF-BIL-001] Severity: P2 | Synchronous ZIP generation, leaked temp PDFs, and unbounded dropdown loads
- Location: BillingManagementController.php:489-516 (downloadPDF temp files), SubscriptionController.php:74-84 (temp PDFs),
            BillingManagementController.php:118-119 (Tenant::get() + User::get())
- Evidence:
    $tempFile = storage_path('app/'.Str::random(10).'.pdf'); file_put_contents($tempFile,$pdf->output());
    $zip->addFile($tempFile,$fileName);  ... $zip->close(); @unlink($zipPath);   // tempFile never unlinked
    $tenantData = Tenant::get(); $superadminData = User::get();                   // unbounded, every dashboard load
- Why it's a risk: temp PDFs accumulate in storage/app indefinitely; ZIP is built synchronously (NFR-BIL-003
    timeout risk for 50+ invoices, ENH-BIL-009); the index loads the full tenant + user roster on every page
    (NFR-BIL-002). 
- Fix: unlink each temp file after $zip->close(); move bulk ZIP to a queued job; paginate/filter the tenant/user
    selectors.
- Confidence: High.   Systemic?: Layer 9.3 / NFR.
```

```
[DEAD-BIL-001] Severity: P2 | Dead policies, last-wins duplicate registration, and imports of non-existent models
- Location: BillingServiceProvider.php:64-70; ConsolidatedPaymentPolicy.php:6 (use App\Models\ConsolidatedPayment),
            PaymentReconciliationPolicy.php:6 (use App\Models\PaymentReconciliation)
- Evidence:
    Gate::policy(BilTenantInvoice::class, BillingManagementPolicy::class);
    Gate::policy(BilTenantInvoice::class, InvoicingPolicy::class);          // last wins → BillingManagementPolicy dead
    Gate::policy(InvoicingPayment::class, ConsolidatedPaymentPolicy::class);
    ...Gate::policy(InvoicingPayment::class, InvoicingPaymentPolicy::class); // last wins → first 3 dead
    // ConsolidatedPaymentPolicy type-hints App\Models\ConsolidatedPayment — class does not exist
- Why it's a risk: NOT an auth bypass (dotted abilities resolve via the Spatie/super-admin Gate::before in
    app/Providers/AppServiceProvider.php:65-74, confirmed) — but BillingManagementPolicy + 3 InvoicingPayment
    policies are dead code, and two policies import classes that do not exist (would fatal if ever instantiated).
- Fix: register one policy per model (or delete the unused policy classes); remove the non-existent imports.
- Confidence: High.   Systemic?: module-local. (Verify the Spatie permission rows `prime.billing-*` exist in prime_db.)
```

---

## P3 Findings
- **DEAD-BIL stub controller:** `InvoicingController.php` (69 ln) — every method is an empty Gate-only stub and it is **not routed** (BUG-BIL-001-004 family). P3 (unrouted).
- **ORM casts missing:** `InvoicingAuditLog` has no cast for `event_info`→array or `action_date`→datetime; `BilTenantInvoice` money fields uncast. Minor.
- **Audit action_type mislabels:** `downloadPDF()`/`scheduleEmail()` write `'Notice Sent'` for a PDF download/schedule; `updateInvoiceRemarks()` writes `'Not Billed'`; `store()` hardcodes `'Partially Paid'` regardless of outcome. Inconsistent vs the DDL enum comment ('Bill Generated','Overdue','Notice Sent','Fully Paid').
- **index() Gate::any duplicate entry:** `prime.invoicing-payment.viewAny` listed twice (BillingManagementController.php:56,58).
- **Class-name typo:** `BillTenatEmailSchedule` (missing 'n') retained.
- **D37:** `bil_tenant_invoices.status` is `VARCHAR(20) DEFAULT 'PENDING'` but the code stores a Dropdown **id** into it (no real FK, no `_id` naming) — string-status-holding-FK pattern.

---

### Layer Health Summary

| # | Layer | Status | Key finding |
|---|-------|:---:|-------------|
| 1 | DDL Schema | 🟡 Amber | No created_by/is_active/deleted_at on most tables; modules_jnt FK→glb_modules VIEW; D37 string status |
| 2 | Migration↔Model↔DDL | 🔴 Red | MIG-BIL-001 SoftDeletes/timestamps mismatch; DATA-BIL-001 audit col; DATA-BIL-002 phantom fillable |
| 3 | Model/ORM | 🟡 Amber | Missing casts (event_info, action_date, money) |
| 4 | Code Quality | 🔴 Red | 1036-ln GOD controller; dead stub controller; bool/array contract bug; broken print branch |
| 5 | Authorization | 🟡 Amber | 9 unprotected methods incl. a write; dead policies (NOT a bypass — Gate::before resolves) |
| 6 | Tenancy | 🟡 Amber | Central module (correct); initialize()/end() without try/finally (SEC-BIL-005) |
| 7 | Validation/Mass-assign | 🟡 Amber | $request->all() into audit (SEC-BIL-011); D30 authorize()=true; thin array rules |
| 8 | Data Integrity/Tx | 🔴 Red | Payment no-rollback + open-tx early return; invoice-number race; status not derived |
| 9 | Performance | 🟡 Amber | Sync ZIP, leaked temp PDFs, unbounded Tenant::get()/User::get() |
| 10 | Queue/Job | 🟡 Amber | Email job no retry/failed(); auth()->id() null on worker |
| 11 | Frontend/Blade | 🟢 Green* | Not deeply audited; no obvious raw-output XSS in scanned partials (*low confidence) |
| 12 | Deployment | 🟡 Amber | Central, no route closures, no secrets — but 3× route dup + broken route |

### STEP 1 Reading-Discipline Output — three-way reconcile (model ↔ DDL ↔ migration)
Migrations = **0** (DDL `prime_db_v4.sql` is the sole schema authority). Reconcile is therefore model ↔ DDL:

| Table | DDL has | Model declares | Verdict |
|-------|---------|----------------|---------|
| prm_billing_cycles | no deleted_at, no timestamps | SoftDeletes + default timestamps | **MISMATCH (P0)** |
| bil_tenant_invoices | created_at/updated_at, no deleted_at; no `invoice_amount` | SoftDeletes; `$fillable` has phantom `invoice_amount` + dup block | **MISMATCH (P0)** |
| bil_tenant_invoicing_payments | created_at/updated_at, no deleted_at | SoftDeletes | **MISMATCH (P0)** |
| bil_tenant_invoicing_audit_logs | `tenant_invoice_id`; created_at only (no updated_at/deleted_at) | `tenant_invoicing_id`; SoftDeletes + default timestamps | **MISMATCH (P0)** |
| bil_tenant_email_schedules | no FK on invoice_id; no deleted_at | default timestamps (no SoftDeletes) | **MISMATCH (P2)** |

**Snapshot corrections to module-knowledge:** (1) REQ-BIL-001 Billing Cycle is **not "clean"** — `prm_billing_cycles` has neither timestamps nor `deleted_at`, so the SoftDeletes+timestamps model breaks CRUD against the DDL. (2) The audit-log mismatch is broader than the column name — the table also lacks `updated_at` while the model uses default timestamps. (3) BA "no index on payments.tenant_invoice_id" — InnoDB auto-creates an index for the FK `fk_tenantInvPayment_tenantInvId`, so a query index exists; an explicit composite may still help reconciliation filters. Confirmed: route 3× duplication, broken `view()` route, Spatie/super-admin `Gate::before` (auth NOT bypassed).

### FRD Gap Summary (Mode B) — REQ → Code/DDL/Test

| REQ | Feature | Code | DDL | Test | Status |
|-----|---------|------|-----|------|--------|
| REQ-BIL-001 | Billing Cycle Mgmt | Built | **Broken vs DDL (MIG-BIL-001)** | unit only | **Partial** (was "Built") |
| REQ-BIL-002 | Subscription view/PDF | Built (read-only) | n/a | none | Partial (lifecycle future) |
| REQ-BIL-003 | Invoice Generation | Built; atomic (DB::transaction) | OK | unit | Partial (tenancy try/finally, INR via plan, no scheduler) |
| REQ-BIL-004 | Invoice Listing & Detail | Built | OK | none | Built |
| REQ-BIL-005 | Invoice Remarks | Built (gated) | OK | none | Built |
| REQ-BIL-006 | Individual Payment | Built | **audit FK + no-rollback + status not derived** | none | **Partial (P0)** |
| REQ-BIL-007 | Consolidated Payment | Built | no-rollback; thin validation | none | Partial |
| REQ-BIL-008 | Payment Reconciliation | Built (toggleStatus) | OK | none | Built |
| REQ-BIL-009 | Invoice Email | Built (job) | no FK on schedule | none | Partial (no retry/failed) |
| REQ-BIL-010 | PDF/ZIP/Print | Built | n/a | none | Partial (sync ZIP, temp leak, consolidated print crash) |
| REQ-BIL-011 | Audit Trail & Notes | Built | **FK mismatch + note-edit unprotected** | none | **Partial (P0)** |
| REQ-BIL-012..017 | Scheduler/Overdue/Metering/Gateway/Portal/GST | — | — | — | Not started (future) |

**Reports:** RPT-BIL-001 invoice PDF/ZIP ✔ (temp leak); RPT-BIL-002 subscription PDF/ZIP ✔; **RPT-BIL-003 consolidated print = BROKEN (BUG-BIL-005)**; RPT-BIL-004 reconciliation ✔; RPT-BIL-005 audit PDF ✔ (depends on the audit FK fix); RPT-BIL-006/007 not started. **Tests:** 1 unit file, 0 feature/browser — every "Test Needed=Yes" REQ lacks feature coverage.

### Business-Rule Enforcement (Mode C)

| BR | Type | Location | Status | Link |
|----|------|----------|--------|------|
| BR-BIL-001 unique cycle code | Validation | DDL uq_billingCycles_code + request | ENFORCED | — |
| BR-BIL-002 months 1–255 | Validation | request (verify) | PARTIAL | DDL TINYINT caps at 255 |
| BR-BIL-003 delete guard | Workflow | controller | PARTIAL | FK ON DELETE RESTRICT on invoices.cycle |
| BR-BIL-006 invoice # unique/format | Calc/Valid | BillingMgmt:660-662 | PARTIAL | race — BUG-BIL-015 |
| BR-BIL-007 qty=max(min,count) | Calc | BillingMgmt:690 | ENFORCED | `max($planRate->min_billing_qty,$totalUserQty)` |
| BR-BIL-008 close tenant conn | Concurrency | BillingMgmt:670-674 | PARTIAL | no try/finally — SEC-BIL-005 |
| BR-BIL-009 sub-total | Calc | :692 | ENFORCED | — |
| BR-BIL-010 tax base/lines | Calc | :698-705 | ENFORCED | — |
| BR-BIL-011 net payable | Calc | :707 | ENFORCED | matches FRD |
| BR-BIL-012 due date | Calc | :664-666 | ENFORCED | invoice_date + credit_days |
| BR-BIL-013 bill once | Workflow | :770-773 (bill_generated=1) + buildMainBillingQuery | ENFORCED | — |
| BR-BIL-014 atomic generation | Concurrency | DB::transaction :636 | ENFORCED | closure auto-rollback |
| BR-BIL-015 new=Pending, 0 paid | Workflow | :761 ordinal-1 status; paid_amount DDL default 0 | ENFORCED | — |
| BR-BIL-016 default INR | Validation | from plan rate currency | PARTIAL | currency taken from planRate, not forced INR |
| BR-BIL-017/018 list filter/paging/today | Workflow | index + parseDateRange | ENFORCED | paginate(10); today default |
| BR-BIL-019 remark permission | Permission | invoiceRemarks gated | ENFORCED | prime.billing-management.remark |
| BR-BIL-020 paid cumulative | Calc | store:74 / consolidated:209 | ENFORCED | add-only |
| BR-BIL-021/026 atomic payment | Concurrency | store/consolidatedStore | **MISSING** | SEC-BIL-001/002 (no rollback) |
| BR-BIL-022 no raw data in audit | Security | store:94 | **MISSING** | SEC-BIL-011 |
| BR-BIL-023 status from paid | Workflow | store:75 | **MISSING** | BUG-BIL-010 (status from request) |
| BR-BIL-024 skip zero alloc | Workflow | consolidated:176-178 | ENFORCED | `if ($receivingAmount<=0) continue;` |
| BR-BIL-025 total+alloc stored | Calc | consolidated:188-190 | ENFORCED | consolidated_amount + amount_paid |
| BR-BIL-027 toggle+log | Workflow | toggleStatus:1012-1026 | ENFORCED | activityLog on reconcile toggle |
| BR-BIL-028 reconcile filter | Workflow | buildPaymentReconciliationQuery:331-337 | ENFORCED | — |
| BR-BIL-029 PDF attached | Workflow | SendInvoiceEmailJob:45-51 | ENFORCED | — |
| BR-BIL-030 scheduled pending→sent | Scheduled | scheduleEmail + delay() | PARTIAL | no 'sent'/'failed' transition written |
| BR-BIL-031 Notice Sent audit | Workflow | job:37 / scheduleEmail:563 | ENFORCED | (audit insert itself blocked by DATA-BIL-001) |
| BR-BIL-032 ZIP + temp cleanup | Workflow | downloadPDF:489-525 | **MISSING** | PERF-BIL-001 (temp PDFs not unlinked) |
| BR-BIL-033 print views per type | Workflow | printData | PARTIAL | consolidated print crashes (BUG-BIL-005) |
| BR-BIL-034 append-only audit | Workflow | auditAddNoteUpdate | PARTIAL | note edit allowed but unprotected (SEC-BIL-010) |
| BR-BIL-035 performer+time | Validation | inserts set performed_by/action_date | PARTIAL | auth()->id() null in job context |
| BR-BIL-036 audit report filters | Workflow | downloadAuditNotePdf:117-136 | ENFORCED | date/tenant/performer/type |
| BR-BIL-037..043 (future REQs) | — | — | N/A | Not started |

### Systemic-Pattern Scorecard (Mode D, scoped to BIL)

| Pattern | Present? | Count | vs baseline |
|---------|:---:|------|-------------|
| D17 fillable/SoftDeletes/timestamps vs DDL | **YES** | 5 tables | Above norm — every model affected |
| D24 permission-prefix chaos/typos | No | 0 | All use `prime.*` consistently |
| D25 `$request->all()` into model/store | YES (1) | 1 (audit event_info) | At/below 24-site norm |
| D29 `->enum()` in migrations | n/a | 0 | No migrations |
| D30 FormRequest authorize()=true | YES | 2/3 (BillingCycleRequest clean) | Below 90% norm |
| Layer 2.5 cross-DB/missing FK | YES | 1 (modules_jnt→glb_modules VIEW) | module-local |
| Layer 3.3 privilege fields in $fillable | No | 0 | — |
| Layer 6.2 initialize() without end() | YES | 1 (no try/finally) | SEC-BIL-005 |
| Layer 10.1 job without retry config | YES | 1/1 | Below norm but present |
| TEN-RTG-001 module-subscription mw | n/a | — | Central module — N/A |
| D36 GENERATED columns degraded | No | 0 | No generated cols in bil_ |
| D37 INT-FK-vs-string status | YES | 1 (`status` VARCHAR holds dropdown id) | module-local |

### vs Platform Baseline
- **D30:** 2/3 FormRequests return bare `true` — better than the 90% platform norm (BillingCycleRequest is clean).
- **D25:** 1 `$request->all()` site — below the 24-site platform total.
- **Authorization:** unlike GlobalMaster/Dashboard ("zero auth on entire controller"), Billing controllers are mostly gated; the 9 gaps are residual, and the policies are dead-but-harmless (Gate::before resolves). This module is **above** the platform authz norm.
- **Schema↔model divergence:** **worse than typical** — SoftDeletes/timestamps declared against tables that have neither, across the whole module (the same D17 class flagged for HST/INV/CMP, but here it is module-wide).

### Recommended Fix Order (unblock-the-most-first)
1. **MIG-BIL-001 (P0)** — add `deleted_at` + `created_at/updated_at` to the 5 tables (or remove SoftDeletes/timestamps). Unblocks ALL CRUD. *(DB Architect → migration; 0→1 migration for prime layer.)*
2. **DATA-BIL-001 (P0)** — rename `tenant_invoicing_id`→`tenant_invoice_id` in model/relations/6 inserts; fix audit timestamps. Unblocks the audit trail (REQ-BIL-011) and any path that writes an audit row.
3. **SEC-BIL-001/002 (P0)** — wrap payment posting in `DB::transaction()`; move empty-selection guard before begin.
4. **DATA-BIL-002 (P0)** — remove phantom `invoice_amount` + duplicate fillable block.
5. **SEC-BIL-011 + BUG-BIL-010 (P1)** — drop raw `request_data` from audit; derive status from cumulative paid.
6. **SEC-BIL-010 (P1)** — add Gate::authorize to the 9 unprotected methods (esp. the note-edit write).
7. **SEC-BIL-005 + BUG-BIL-015 (P1)** — `$tenant->run()` for the student count; lock/retry the invoice number.
8. **P2 batch** — fix consolidated print (BUG-BIL-005), broken `view()` route, 3× route dedup, temp-PDF cleanup + queued ZIP, email-job reliability, FK/index migrations, dead-policy cleanup.

---

*Audit complete — Health 37/100 (capped: multiple P0 present). Deploy: NO-GO.*
*Next: (1) Fix P0 schema/data → act as DB Architect + Developer · (2) Completeness score → act as Status_Analyzer · (3) Feature/browser tests → act as Testing Architect.*
