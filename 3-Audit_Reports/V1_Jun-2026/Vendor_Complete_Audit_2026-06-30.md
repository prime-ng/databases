# Complete Audit — Vendor (VND) — 2026-06-30
**Mode X: A + B + C + G + scoped D**
**Auditor:** Technical Auditor Agent (Mode X — 12-Layer A+B+C+G+D Protocol)
**Module:** VND — Vendor
**Module Path:** `Modules/Vendor/`
**Health Score:** 35 / 100 — P0-CAPPED
**Deploy Gate:** ❌ NO-GO

---

## Executive Summary

The Vendor module is a high-risk financial module (manages PAN/GST/bank details, invoices, and vendor payments) sitting at **35/100 health, P0-capped NO-GO**. The most severe finding is that PAN and bank account numbers are stored as unencrypted plain `VARCHAR` columns — a direct DPDPA regulatory violation with no path to production. A second P0 is that `vnd_invoices.balance_due` is a plain `DECIMAL` in the live migration despite the DDL spec mandating `GENERATED ALWAYS AS (net_payable - amount_paid) STORED` — the DB column is never updated by PHP code (mass-assignment protection blocks the write), making every DB-level invoice balance report show the wrong value. A third P0 is a payment race condition: concurrent payment writes to the same invoice have no `lockForUpdate()`, allowing overdraft. The good news: the BA's top finding (VendorInvoiceController zero auth on 14 methods) is fully **CLEARED** — all methods are now properly gated. Seven policies are registered with zero duplicate kills — above the platform baseline. No `dd()` debug contamination. The module cannot deploy until the P0s are resolved.

---

## Health Score

| Layer | Score | Weight | Points | Key Finding |
|-------|-------|--------|--------|-------------|
| 6 Tenancy | 🔴 Red | 15 | 0 | EnsureTenantHasModule absent; Job no tenancy init |
| 5 Authorization | 🟢 Green | 14 | 14 | All 14+ VendorInvoice methods gated; 7 policies, no duplicates |
| 8 Data Integrity/Tx | 🔴 Red | 13 | 0 | balance_due never updated; payment race condition; Job no transaction |
| 7 Validation | 🟡 Amber | 11 | 5.5 | 3/3 FormRequests return true (D30); VndUsageLogController no FormRequest |
| 12 Deployment | 🟡 Amber | 10 | 5 | Cross-DB FKs (sys_dropdowns) would block tenants:migrate |
| 2 Migration↔Model↔DDL | 🔴 Red | 9 | 0 | balance_due GENERATED vs plain; cross-DB FKs |
| 1 DDL Schema | 🟡 Amber | 7 | 3.5 | is_deleted redundancy (5 tables); missing created_by; ENUMs (D29) |
| 9 Performance | 🟡 Amber | 7 | 3.5 | N+1 in dashboard topVendors; unbounded Vendor::get() 4 sites |
| 10 Queue/Job | 🔴 Red | 6 | 0 | SendVendorInvoiceEmailJob: no tenancy, no retry, sends to admin not vendor |
| 4 Code Quality | 🟡 Amber | 4 | 2 | toggleStatus route→missing method; generateMultiple failure masking; destroy no try/catch |
| 3 ORM | 🟡 Amber | 2 | 1 | VndAgreement cross-module Transport import; VndPayment missing status cast |
| 11 Frontend | 🟡 Amber | 2 | 1 | No dd() contamination; no XSS found in Blade |

**Weighted sum: 35 / 100**
**P0 cap (40) is above the raw score; effective score: 35 / 100 (P0-capped)**

---

## Deploy Gate Verdict: ❌ NO-GO

Blocking items:
1. **SEC-VND-010** — PAN / bank account in plaintext (DPDPA)
2. **MIG-VND-002** — `balance_due` plain vs GENERATED STORED — stale DB column
3. **DAT-VND-001** — Payment race condition (no lockForUpdate)
4. **SEC-PLATFORM-003** — EnsureTenantHasModule absent

---

## P0 Findings

---

### [SEC-PLATFORM-003] P0 | EnsureTenantHasModule absent from mapWebRoutes()
- **Location:** `Modules/Vendor/app/Providers/RouteServiceProvider.php:41-51`
- **Evidence:**
```php
Route::middleware([
    'web',
    InitializeTenancyByDomain::class,
    PreventAccessFromCentralDomains::class,
    EnsureTenantIsActive::class,
    'auth',
    'verified',
])
```
- **Why it's a risk:** Any active tenant can access ALL Vendor routes regardless of whether they have the Vendor module licensed. Module-subscription enforcement is entirely absent.
- **Fix:** Add `EnsureTenantHasModule:Vendor` to the middleware array.
- **Confidence:** High
- **Systemic?** Platform-wide P0 — confirmed 13/13 tenant modules (STD is the only exception)

---

### [SEC-VND-010] P0 | PAN card + bank account numbers stored in plaintext
- **Location:** `Modules/Vendor/app/Models/Vendor.php:25-28` + `database/migrations/tenant/2026_06_15_151247_create_vnd_vendors_table.php:21-27`
- **Evidence:**
```php
// Migration
$table->string('gst_number', 50)->nullable();
$table->string('pan_number', 50)->nullable();
$table->string('bank_account_no', 50)->nullable();
$table->string('upi_id', 100)->nullable();

// Model — NO encrypted casts
protected $fillable = ['vendor_name', ..., 'pan_number', 'bank_account_no', 'gst_number', 'upi_id', ...];
protected $casts = ['is_active' => 'boolean']; // only this
```
- **Why it's a risk:** PAN numbers and bank account numbers are classified as Sensitive Personal Data under India's Digital Personal Data Protection Act 2023 (DPDPA). Storage as unencrypted `VARCHAR` means any DB dump, log file, or misconfigured query exposes financial identity data of all vendors across all tenants.
- **Fix:** Add `Illuminate\Database\Eloquent\Casts\Encrypted` cast to `pan_number`, `bank_account_no`, `gst_number`, `upi_id` in Vendor model. Add a one-time data-migration job to encrypt existing plaintext values.
- **Confidence:** High
- **Systemic?** VND-local (confirmed VND 2026-06-30; SEC-VND-010 already in known-issues)

---

### [MIG-VND-002] P0 | `balance_due` is plain DECIMAL in migration — DDL spec says GENERATED STORED
- **Location:** `database/migrations/tenant/2026_06_15_151252_create_vnd_invoices_table.php:36` (migration) vs `2-DDL_Tenant_Consolidated/Vendor_DDL_v2.1.sql:193` (DDL spec)
- **Evidence:**
```php
// LIVE MIGRATION (what ships):
$table->decimal('balance_due', 12, 2);  // plain column, never auto-computed

// DDL SPEC (what was designed):
`balance_due` DECIMAL(12, 2) GENERATED ALWAYS AS (net_payable - amount_paid) STORED,

// VndInvoice::$fillable — balance_due NOT listed (mass-assignment blocked)
// VendorInvoiceController::store():138 — writes 'balance_due' but silently dropped
// VendorPaymentController::update():159, destroy():232 — same silent drop
```
- **Why it's a risk:** The DB `balance_due` column is set at invoice creation time and never updated thereafter. Every payment recorded updates `amount_paid` correctly, but `balance_due` in the DB stays at the original net_payable (or MySQL's implicit default). All raw-SQL reports, analytics dashboards, and any code reading `balance_due` directly from DB (not via the PHP accessor `getBalanceDueAttribute()`) shows wrong/stale financial data. A tenant reporting outstanding invoices via direct SQL will see 100% as unpaid regardless of payments received.
- **Fix:** Replace `$table->decimal('balance_due', 12, 2)` with `DB::statement("ALTER TABLE vnd_invoices ADD COLUMN balance_due DECIMAL(12,2) GENERATED ALWAYS AS (net_payable - amount_paid) STORED")` in a new migration. Remove `balance_due` from all controller `update()` arrays (the GENERATED column cannot be written). The PHP accessor `getBalanceDueAttribute()` in VndInvoice is already correct — keep it as a fallback.
- **Confidence:** High
- **Systemic?** D36 (DDL GENERATED columns shipped as plain in migrations) — module-local confirmation; same pattern as hst_allotments (P0) from 2026-06-29

---

### [DAT-VND-001] P0 | Payment race condition — no row lock on invoice during payment writes
- **Location:** `Modules/Vendor/app/Http/Controllers/VendorInvoiceController.php:108-140` (store), `VendorPaymentController.php:105-161` (update), `VendorPaymentController.php:195-234` (destroy)
- **Evidence:**
```php
// VendorInvoiceController::store() — reads then writes without lock
$invoice = VndInvoice::where('id', $invoiceId)->first();   // no lockForUpdate()
$newPaidAmount = $invoice->amount_paid + $request->amount;
// ... concurrent request reads same $invoice->amount_paid here ...
$invoice->update(['amount_paid' => $newPaidAmount, ...]);  // overwrites concurrent write
```
- **Why it's a risk:** If a Finance Manager and an Accountant both process payments for the same invoice concurrently, both read the same `amount_paid` value, both add their payment amounts, and the last writer wins — meaning one payment is silently lost from the running total. For a financial module, this is a data integrity P0 (double-payment or missed-payment on the ledger).
- **Fix:** Replace `VndInvoice::where('id', $invoiceId)->first()` with `VndInvoice::where('id', $invoiceId)->lockForUpdate()->first()` inside a `DB::transaction()` in all three locations. VendorPaymentController::update() already has a DB::transaction wrapper — add the lock. VendorPaymentController::destroy() needs both a try/catch and a lock (see BUG-VND-004).
- **Confidence:** High
- **Systemic?** Module-local; platform-wide recommendation to add lockForUpdate to all balance/amount decrement paths

---

## P1 Findings

---

### [JOB-VND-001] P1 | SendVendorInvoiceEmailJob — no tenancy init, no retry, sends to admin not vendor
- **Location:** `Modules/Vendor/app/Jobs/SendVendorInvoiceEmailJob.php:1-68`
- **Evidence:**
```php
class SendVendorInvoiceEmailJob implements ShouldQueue
{
    // No $tries, $timeout, $backoff declared

    public function handle()
    {
        foreach ($this->agreementIds as $id) {
            $invoice = VndAgreementItem::with([...])->find($id); // no tenancy init
        }
        Mail::send('vendor::emails.invoice', [], function ($message) use ($attachments) {
            $message->to($this->email);  // $this->email = Auth::user()->email (admin, not vendor!)
        });
        // PDF cleanup ONLY on success — files leak on Mail::send() exception
    }
}
// Dispatch site (VendorInvoiceController:595):
dispatch(new SendVendorInvoiceEmailJob($request->invoice_ids, Auth::user()->email));
```
- **Why it's a risk:** (1) Job queries `vnd_agreement_items_jnt` without initializing tenant context — on the queue worker the DB connection points to the central DB, so `VndAgreementItem::find($id)` returns null for all items → all emails silently empty. (2) No `$tries`/`$timeout`/`$backoff` → job fails permanently on first error with no retry. (3) Emails are sent to the triggering admin's address, never to vendor email addresses — the vendor communication function is broken by design. (4) Temp PDF files at `storage/app/tmp/*.pdf` leak on `Mail::send()` exception.
- **Fix:** (a) Add `$tries = 3; $timeout = 120; $backoff = [30, 60]`. (b) Initialize tenancy: store `$tenantId` in constructor, call `tenancy()->initialize($tenantId)` in `handle()`. (c) Fetch vendor email per invoice and send to `$vendor->email`, not the admin. (d) Move cleanup into a `finally` block.
- **Confidence:** High
- **Systemic?** Platform pattern — Layer 10.1 (Job tenancy missing) already documented for Vendor

---

### [BUG-VND-003] P1 | `generateMultiple()` failure tracking broken — failed invoices silently appear in $success
- **Location:** `Modules/Vendor/app/Http/Controllers/VendorInvoiceController.php:267-305`
- **Evidence:**
```php
foreach ($request->agreement_item_ids as $agreementItemId) {
    try {
        $this->generateInvoice($agreementItemId, false, ...);
        $success[] = $agreementItemId;       // ← runs even when generation failed
    } catch (\Exception $e) {
        $failed[] = [...];                   // ← NEVER reached
    }
}
// Why: generateInvoice() catches all its own exceptions internally (line 414)
// and returns a Response object instead of rethrowing.
// The outer try/catch never fires.
```
- **Why it's a risk:** When batch invoice generation fails (e.g., "Invoice already generated for this period"), the caller receives `success: [1,2,3,4,5]` and `failed: []`. The user believes all 5 invoices were created when some or all failed silently. Financial records appear complete when they are not.
- **Fix:** Remove the inner try/catch from `generateInvoice()` when `$single === false`. Let the exception propagate to `generateMultiple()`'s outer catch. Alternatively, return a typed Result object (not a Response) and check it explicitly.
- **Confidence:** High
- **Systemic?** Module-local

---

### [BUG-VND-004] P1 | `VendorPaymentController::destroy()` — no try/catch, open transaction on exception
- **Location:** `Modules/Vendor/app/Http/Controllers/VendorPaymentController.php:188-247`
- **Evidence:**
```php
public function destroy($id)
{
    Gate::authorize('tenant.vendor-payment.delete');
    DB::beginTransaction();
    $payment = VndPayment::with('invoice')->findOrFail($id); // throws on missing
    $invoice  = $payment->invoice;
    if ($invoice) {
        // ... Dropdown::where() queries (each can throw)
        $invoice->update([...]);
    }
    $payment->delete();
    DB::commit();
    return response()->json([...]);
    // NO try/catch — any exception after beginTransaction leaves transaction open
}
```
- **Why it's a risk:** If any operation throws after `DB::beginTransaction()` (e.g., `findOrFail` on non-existent ID, Dropdown query returning null, DB error on `update()`), the exception propagates without `DB::rollBack()`. The MySQL connection is left in an open transaction state. Subsequent requests on the same connection see a dirty-read state until the connection is closed/recycled.
- **Fix:** Wrap the entire body in a try/catch(\Throwable) block matching the `update()` method's pattern: `DB::rollBack(); return response()->json(['status' => false, ...], 500)`.
- **Confidence:** High
- **Systemic?** Module-local

---

### [BUG-VND-005] P1 | Route `vendor-usage-log.toggleStatus` maps to missing controller method
- **Location:** `Modules/Vendor/routes/web.php:36` vs `Modules/Vendor/app/Http/Controllers/VndUsageLogController.php`
- **Evidence:**
```php
// web.php line 36:
Route::post('/vendor-usage-log/{id}/toggle-status',
    [VndUsageLogController::class, 'toggleStatus']
)->name('vendor-usage-log.toggleStatus');

// VndUsageLogController — methods: index, create, store, show, edit, update,
//                         destroy, trashed, restore, forceDelete
// toggleStatus() does NOT exist in this controller
```
- **Why it's a risk:** Any POST to `/vendor/vendor-usage-log/{id}/toggle-status` results in `BadMethodCallException: Method ... does not exist` → 500. The feature to activate/deactivate usage log entries is fully broken.
- **Fix:** Implement `VndUsageLogController::toggleStatus(Request $request, $id)` following the pattern of `VndItemController::toggleStatus()`, or remove the route if usage-log status toggling is not required.
- **Confidence:** High
- **Systemic?** Module-local

---

### [SEC-VND-011] P1 | VndUsageLogController::store() and update() — no FormRequest, no validation
- **Location:** `Modules/Vendor/app/Http/Controllers/VndUsageLogController.php:53-74` (store), `104-140` (update)
- **Evidence:**
```php
public function store(Request $request)  // plain Request, no FormRequest
{
    Gate::authorize('tenant.usage-log.create');
    $log = VndUsageLog::create([
        'vendor_id'         => $request->vendor_id,         // no validation
        'agreement_item_id' => $request->agreement_item_id, // no existence check
        'usage_date'        => $request->usage_date,        // no date validation
        'qty_used'          => $request->qty_used,          // can be negative!
        'remarks'           => $request->remarks,
        'logged_by'         => Auth::user()->id,
    ]);
}
```
- **Why it's a risk:** A negative `qty_used` (-100) silently corrupts the `usageQty` sum in `generateInvoice()` (line 324: `VndUsageLog::where(...)->sum('qty_used')`), causing inflated credits on the invoice. A future usage_date can book usage in advance. No check that `vendor_id` or `agreement_item_id` belong to the tenant (IDOR vector — any School Admin can book usage against any vendor ID they enumerate).
- **Fix:** Create `VndUsageLogRequest` with rules: `qty_used: required|numeric|min:0.01`, `usage_date: required|date|before_or_equal:today`, `vendor_id: required|exists:vnd_vendors,id`, `agreement_item_id: required|exists:vnd_agreement_items_jnt,id`.
- **Confidence:** High
- **Systemic?** Module-local (platform D30/D25 systemic, but the no-validation-at-all is VND-local)

---

### [ORM-VND-001] P1 | VndAgreement model imports Transport module classes directly
- **Location:** `Modules/Vendor/app/Models/VndAgreement.php:11-12`
- **Evidence:**
```php
use Modules\Transport\Models\Vehicle;
use Modules\Transport\Models\DriverHelper;
```
- **Why it's a risk:** Hard class-import creates a PHP autoloader dependency from the Vendor module on the Transport module. If Transport is disabled or not installed, the autoloader throws `Class 'Modules\Transport\Models\Vehicle' not found` on any Vendor model load — all vendor routes crash with 500. Schools that have Vendor but not Transport cannot use the Vendor module.
- **Fix:** Replace direct model imports with generic DB resolution: `DB::table($agreementItem->related_entity_table)->find($agreementItem->related_entity_id)`. This is the correct use of the existing `related_entity_table`/`related_entity_id` polymorphic pattern already designed into the schema.
- **Confidence:** High
- **Systemic?** Module-local (same pattern as ARCH-SLK-01 cross-layer import)

---

### [BUG-VND-008] P1 | Invoice number collision risk — `rand(100,999)` only 900 unique values/second
- **Location:** `Modules/Vendor/app/Http/Controllers/VendorInvoiceController.php:381`
- **Evidence:**
```php
'invoice_number' => 'INV-' . now()->format('YmdHis') . rand(100,999),
// e.g. "INV-20260630143022" + one of 900 random suffixes
// Unique constraint: uq_vnd_invoice_no(vendor_id, invoice_number)
// Under batch generateMultiple(), 2 items for same vendor in same second → collision
```
- **Why it's a risk:** `generateMultiple()` processes multiple items in a tight loop. Two items for the same vendor processed within the same second produce identical timestamps and a 1-in-900 chance of rand collision → `QueryException` (unique constraint) → invoice not created, silently added to failed list (or to success, per BUG-VND-003).
- **Fix:** Replace with a sequential scheme: `'INV-' . date('Y') . '-' . str_pad($nextSeq, 6, '0', STR_PAD_LEFT)` where `$nextSeq` is fetched via `lockForUpdate()` on a sequence counter row or via `DB::select('SELECT MAX(invoice_sequence) + 1')` inside the transaction.
- **Confidence:** High
- **Systemic?** Module-local

---

### [PERF-VND-001] P1 | N+1 query in VendorDashboardController::getDashboardData() — topVendors loop
- **Location:** `Modules/Vendor/app/Http/Controllers/VendorDashboardController.php:166-189`
- **Evidence:**
```php
$topVendors = $vendors->map(function($vendor) use ($startDate, $endDate) {
    $payments = VndPayment::whereHas('invoice', function($query) use ($vendor, ...) {
        $query->where('vendor_id', $vendor->id)->whereBetween('invoice_date', ...);
    })->get();
    // ... per-vendor aggregation
});
// Result: 1 DB query per vendor in collection → N+1 (N = vendor count)
```
- **Why it's a risk:** A school with 100 vendors triggers 100+ `VndPayment::whereHas()` queries per dashboard refresh. Dashboard load time degrades linearly with vendor count.
- **Fix:** Compute topVendors via a single aggregation query: `VndPayment::selectRaw('vendor_id, SUM(amount) as total_paid')->whereBetween(...)->groupBy('vendor_id')->orderByDesc('total_paid')->limit(10)->get()`. Join vendors table for names.
- **Confidence:** High
- **Systemic?** Module-local

---

## P2 Findings

### [BUG-VND-016] P2 | pdfMultiple() individual temp PDF files never unlinked
- **Location:** `Modules/Vendor/app/Http/Controllers/VendorInvoiceController.php:489-499`
- **Evidence:**
```php
$tempFile = storage_path('app/' . Str::random(10) . '.pdf');
file_put_contents($tempFile, $pdf->output());
$zip->addFile($tempFile, $fileName);
// ...
$zip->close();
@unlink($zipPath); // ← ZIP deleted ✅
// ← individual $tempFile paths NEVER deleted — accumulate in storage/app/
```
- **Fix:** After `$zip->close()`, loop over temp files and `@unlink($tempFile)`. Better: collect temp paths in an array during the loop, then delete them in a `finally` block.
- **Confidence:** High | **Systemic?** Module-local

### [PERF-VND-002] P2 | Unbounded `Vendor::get()` and `VndAgreementItem::get()` in create/edit forms
- **Location:** `VndUsageLogController.php:45-46` (create), `96-97` (edit)
- **Evidence:**
```php
$vendorsList = Vendor::get();           // fetches ALL vendors — no limit
$AgreementItemList = VndAgreementItem::get(); // fetches ALL items — no limit
```
- **Fix:** Replace with paginated / filtered queries, or limit to active vendors: `Vendor::where('is_active', true)->select('id', 'vendor_name')->get()`. Agreement items should be loaded lazily via AJAX after vendor selection.
- **Confidence:** High | **Systemic?** Module-local; similar pattern in VendorController::index():50 and VendorPaymentController::index():64

### [D29-VND-001] P2 | 4 ENUM columns in tenant migrations (D29 pattern)
- **Location:** `create_vnd_agreements_table.php:19-20`, `create_vnd_agreement_items_jnt_table.php:16`, `create_vnd_payments_table.php:19`
- **Evidence:**
```php
$table->enum('status', ['ACTIVE', 'DRAFT', 'EXPIRED', 'TERMINATED']);   // agreements
$table->enum('billing_cycle', ['MONTHLY', 'ONE_TIME', 'ON_DEMAND']);    // agreements
$table->enum('billing_model', ['FIXED', 'HYBRID', 'PER_UNIT']);         // agreement_items_jnt
$table->enum('status', ['FAILED', 'INITIATED', 'SUCCESS']);             // payments
```
- **Fix:** Replace ENUMs with INT UNSIGNED FK → `sys_dropdowns`. Requires DDL migration + seeding dropdown values.
- **Confidence:** High | **Systemic?** D29 — platform baseline ~476 enum calls

### [D30-VND-001] P2 | All 3 FormRequests return `authorize(){return true;}` (D30)
- **Location:** `VendorRequest.php`, `VendorAgreementRequest.php`, `VndItemRequest.php`
- **Confidence:** High | **Systemic?** D30 — platform baseline 437/485 (90%)

### [ORM-VND-002] P2 | VndPayment::$fillable includes `is_deleted` alongside SoftDeletes
- **Location:** `Modules/Vendor/app/Models/VndPayment.php`
- **Evidence:** `$fillable` contains `is_deleted`, yet the model also uses `SoftDeletes` (`deleted_at`). Two soft-delete mechanisms for one table.
- **Fix:** Remove `is_deleted` from `$fillable`; add a migration to drop the `is_deleted` column from `vnd_payments` (and the 4 other tables that have it: vnd_vendors, vnd_items, vnd_agreements, vnd_agreement_items_jnt).
- **Confidence:** High | **Systemic?** Module-local (5 tables affected in VND)

---

## P3 Findings

### [GAP-VND-001] P3 | Zero test coverage
- **Location:** `Modules/Vendor/tests/` — only `.gitkeep` files.
- Priority tests: VendorInvoiceAuthTest (14 gated methods), BillingModelCalculationTest (FIXED/PER_UNIT/HYBRID), PaymentRaceConditionTest, VndUsageLogValidationTest.

### [DEAD-VND-001] P3 | VendorRequest imports `VendorTypeEnum` — never used
- **Location:** `Modules/Vendor/app/Http/Requests/VendorRequest.php:7`
- `use Modules\Vendor\Enums\VendorTypeEnum;` — imported but not referenced anywhere in the class.

### [ORM-VND-003] P3 | VndUsageLog uses deprecated `$dates` pattern
- **Location:** `Modules/Vendor/app/Models/VndUsageLog.php:25`
- `protected $dates = ['deleted_at']` — deprecated since Laravel 9. Replace with `protected $casts = ['deleted_at' => 'datetime']`.

---

## STEP 1 — Three-Way Schema Reconcile

| Table | DDL Spec | Live Migration | Model | Gap |
|-------|----------|----------------|-------|-----|
| `vnd_vendors` | 15 columns incl. created_by missing | 13 columns — no created_by | $fillable matches ✅ | Missing created_by (DDL+migration both miss it) |
| `vnd_invoices.balance_due` | GENERATED STORED | **Plain DECIMAL(12,2)** | Not in $fillable; PHP accessor | **P0 GAP — MIG-VND-002** |
| `vnd_usage_logs.deleted_at` | Not in DDL v2.1 | Added via separate migration ✅ | SoftDeletes ✅ | Consistent |
| `vnd_payments.status` | ENUM | ENUM ✅ | Not cast | Missing `$casts['status']` |
| `vnd_agreements.billing_cycle` | ENUM | ENUM ✅ | — | D29 |
| `vnd_agreement_items_jnt.billing_model` | ENUM | ENUM ✅ | — | D29 |

### Cross-DB FKs (Layer 2.5) — VND contributes 4 FKs to the platform-wide P0
| FK | File | Target |
|----|------|--------|
| `vnd_vendors.vendor_type_id` | `create_vnd_vendors_table.php:35` | `sys_dropdowns` (central) |
| `vnd_invoices.status` | `create_vnd_invoices_table.php:52` | `sys_dropdowns` (central) |
| `vnd_payments.payment_mode` | `create_vnd_payments_table.php:35` | `sys_dropdowns` (central) |
| `vnd_agreement_items_jnt.related_entity_type` | `create_vnd_agreement_items_jnt_table.php:38` | `sys_dropdowns` (central) |

These are part of the platform-wide "52 tenant FKs → sys_dropdowns" P0 pattern. They will cause `errno 150` on `tenants:migrate`.

### Stale BA Findings — CLEARED by Live Code
| BA Finding | Status | Evidence |
|-----------|--------|---------|
| SEC-VND-001/005 — VendorController::index() Gate commented | **CLEARED** | Line 26-34: `Gate::any([7 permissions]) \|\| abort(403)` |
| SEC-VND-002 — VendorInvoiceController ZERO auth on 14 methods | **CLEARED** | All 14+ methods have Gate::authorize() |
| SEC-VND-006 — VendorPaymentController prefix mismatch | **CLEARED** | Uses `tenant.vendor-payment.*` consistently |
| GAP-VND-05 — VendorDashboardController unregistered | **CLEARED** | `routes/web.php:66-67` registers it |
| GAP-VND-24 — VendorReportController dead routes | **CLEARED** | `routes/web.php:73-75` registers it |
| BUG-VND-06 — vnd_usage_logs missing deleted_at | **CLEARED** | `2026_06_18_100111_add_deleted_at_to_vnd_usage_logs_table.php` exists |

---

## FRD Gap Summary (Mode B) — NO FRD

No FRD file exists at `{FRD_DIR}/VND_FRD_*.md`. Modes B (FRD gap analysis) and C (BR enforcement) are **skipped**. The BA module knowledge file at `AI_Brain/module-knowledge/VND_Vendor.md` documents 30 known gaps and serves as a partial substitute, but formal FRD-driven verification is not possible.

**Recommendation:** Generate the FRD first (`act as Business Analyst → Complete Analysis Pack for Vendor`) before re-running Mode B/C.

---

## Business-Rule Enforcement (Mode C) — SKIPPED (no FRD)

Selected critical business rules verified informally from BA knowledge:

| BR | Rule | Status |
|----|------|--------|
| BR-VND-003 | Cannot generate invoice for expired agreement | ❌ MISSING — generateInvoice() does not check agreement.status |
| Collision check | Duplicate invoice blocked for same period | ✅ ENFORCED — VndInvoice whereDate check at line 366 |
| Balance integrity | balance_due = net_payable - amount_paid | ❌ PARTIAL — PHP accessor correct; DB column stale (MIG-VND-002) |
| Immutable invoice | Invoice amounts snapshot at generation time | ✅ ENFORCED — snapshot columns in create array |
| Payment ≤ balance_due | Cannot overpay an invoice | ❌ MISSING — VendorInvoiceController::store() has no amount≤balance_due check |

---

## Systemic-Pattern Scorecard (Mode D, scoped to VND)

| Pattern | VND Verdict | Count |
|---------|-------------|-------|
| SEC-PLATFORM-003 (EnsureTenantHasModule) | ✅ CONFIRMED — absent from mapWebRoutes() | 1 |
| D30 (authorize()=true FormRequests) | ✅ CONFIRMED — 3/3 (100%) | 3 |
| D29 (ENUM in migrations) | ✅ CONFIRMED — 4 ENUM columns | 4 |
| D25 ($request->all() into models) | ❌ NOT PRESENT — VndUsageLogController uses explicit array, not $request->all() | 0 |
| D17 ($fillable → missing column) | ⚠️ PARTIAL — VndPayment.$fillable has is_deleted (column exists but anti-pattern); balance_due write silently blocked | 1 |
| D36 (GENERATED columns shipped as plain) | ✅ CONFIRMED — balance_due GENERATED in DDL, plain in migration | 1 |
| Layer 2.5 (cross-DB FKs) | ✅ CONFIRMED — 4 FKs → sys_dropdowns | 4 |
| Layer 6.2 (initialize() without end()) | ❌ NOT PRESENT — no manual tenancy init in this module | 0 |
| Layer 10.1 (Job missing tenancy/retry) | ✅ CONFIRMED — SendVendorInvoiceEmailJob: tenancy=0, tries=0, timeout=0 | 1 |
| API RSP no tenancy | N/A — api.php exists but has no routes | 0 |
| Duplicate Gate::policy() kill | ❌ NOT PRESENT — 7 policies, all unique, no duplicates | 0 |
| activityLog wrong arg order | ❌ NOT PRESENT — calls appear correct | 0 |
| PII in plaintext | ✅ CONFIRMED — pan_number, bank_account_no, gst_number, upi_id | 4 fields |

---

## vs Platform Baseline

| Metric | VND | Platform Baseline | Delta |
|--------|-----|------------------|-------|
| FormRequests returning `true` | 3/3 (100%) | 90% | = |
| $request->all() into models | 0 | 24 sites | Better |
| Write controllers with zero authz | 0 | 64 | ✅ Best in class |
| ENUM columns in migrations | 4 | ~476 total | Typical |
| Policies registered | 7 / 7 (100%) | Varies | ✅ Above baseline |
| Duplicate Gate::policy() kills | 0 | EXM 13×, TTF 19× | ✅ Clean |
| Job missing tenancy init | 1 (the only job) | Several modules | Typical |
| PII plaintext | 4 fields | 0 confirmed others | Worst in class |
| Test coverage | 0 tests | 0 in most modules | = baseline |

**Above baseline:** Authorization coverage is the module's strongest layer — all controllers now properly gated, 7 policies registered with zero duplicate kills. VendorInvoiceController (the highest-risk controller) has Gate::authorize on all 14+ methods.

**Below baseline:** PII storage is the module's critical weakness — no other module confirmed to store financial identity data (PAN/bank) in plaintext.

---

## Recommended Fix Order

### Sprint 1 (P0 — Deploy Blockers)
1. **MIG-VND-002** — Add migration to convert `balance_due` to `GENERATED ALWAYS AS` stored column. Remove all `balance_due` writes from controller arrays. *(1 day)*
2. **SEC-VND-010** — Add encrypted casts to Vendor model for pan_number, bank_account_no, gst_number, upi_id. Write data-migration job to encrypt existing rows. *(2 days)*
3. **DAT-VND-001** — Add `lockForUpdate()` to all invoice reads before payment writes in VendorInvoiceController::store(), VendorPaymentController::update(), and VendorPaymentController::destroy(). *(0.5 day)*
4. **SEC-PLATFORM-003** — Add EnsureTenantHasModule:Vendor to RSP middleware. *(0.5 day)*

### Sprint 2 (P1 — Release Blockers)
5. **JOB-VND-001** — Fix SendVendorInvoiceEmailJob: add tenancy init, retry/timeout, send to vendor email, finally-block cleanup. *(1 day)*
6. **BUG-VND-003** — Fix generateMultiple() failure tracking: let generateInvoice() rethrow exceptions when called from batch context. *(0.5 day)*
7. **BUG-VND-004** — Add try/catch to VendorPaymentController::destroy(). *(0.25 day)*
8. **BUG-VND-005** — Implement VndUsageLogController::toggleStatus() or remove the route. *(0.25 day)*
9. **SEC-VND-011** — Create VndUsageLogRequest with validation rules. *(0.5 day)*
10. **ORM-VND-001** — Replace Transport model imports in VndAgreement with generic DB::table() resolver. *(0.5 day)*
11. **BUG-VND-008** — Replace rand()-based invoice number with sequential scheme. *(0.5 day)*
12. **PERF-VND-001** — Fix N+1 in VendorDashboardController topVendors. *(0.5 day)*

### Sprint 3 (P2 — Quality)
13. Fix temp file leak in pdfMultiple() (BUG-VND-016)
14. Replace unbounded Vendor::get() / VndAgreementItem::get() (PERF-VND-002)
15. Remove is_deleted redundancy from 5 tables (migration + models)
16. Replace 4 ENUM columns with FK → sys_dropdowns (D29-VND-001)
17. Fix VndUsageLog::$dates to $casts (ORM-VND-003)

### Sprint 4 (Test Coverage)
18. Write VendorInvoiceAuthTest — all gated endpoints
19. Write BillingModelCalculationTest — FIXED/PER_UNIT/HYBRID math
20. Write PaymentRaceConditionTest — concurrent payment simulation
21. Write VndUsageLogValidationTest

---

## Next Steps

```
Audit complete — VND Health 35/100 (P0-capped at 40). NO-GO for production.

1. Fix P0 issues (MIG-VND-002, SEC-VND-010, DAT-VND-001, SEC-PLATFORM-003)
   → act as Developer (Sprint 1 tasks above)

2. Fix schema/DDL gaps (balance_due GENERATED, is_deleted removal, ENUM→FK)
   → act as DB Architect

3. Completeness score  → act as Status_Analyzer

4. Test coverage       → act as Testing Architect

5. Generate FRD (no FRD exists — required for Mode B/C)
   → act as Business Analyst → Complete Analysis Pack for Vendor

6. Platform sweep for cross-DB FK fix (sys_dropdowns)
   → act as Enterprise Architect (fix all 52 tenant FKs platform-wide)
```
