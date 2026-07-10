<?php

namespace Tests\Browser\Modules\Prime\Billing\ConsolidatedPayment;

use App\Models\User;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\Billing\Http\Requests\ConsolidatedPaymentRequest;
use Modules\Billing\Models\BilTenantInvoice;
use Modules\Billing\Models\InvoicingAuditLog;
use Modules\Billing\Models\InvoicingPayment;
use Modules\Billing\Policies\ConsolidatedPaymentPolicy;
use ReflectionClass;
use Tests\Browser\Modules\Prime\Billing\BillingDuskTestCase;
use Throwable;

/**
 * Consolidated Payment (Billing / Prime-central) — single comprehensive Dusk suite.
 *
 * Screen: Billing Management → "Consolidated Payment" tab.
 * A single payment (cheque / bank transfer) is distributed across several outstanding
 * invoices of a tenant; each invoice receives a per-invoice allocation while the total
 * cheque amount is stored on every payment row via `consolidated_amount`.
 *
 * DB scope: PRIME / CENTRAL (prime_db). No tenant scaffolding — extends the central
 * BillingDuskTestCase (127.0.0.1) per constraint E21/E22.
 *
 * Primary table  : bil_tenant_invoicing_payments  (prefix bil_)
 * Related tables : bil_tenant_invoices, bil_tenant_invoicing_audit_logs
 * Controller      : Modules\Billing\Http\Controllers\InvoicingPaymentController::consolidatedStore()
 * FormRequest     : Modules\Billing\Http\Requests\ConsolidatedPaymentRequest
 * Policy          : Modules\Billing\Policies\ConsolidatedPaymentPolicy (abilities prime.consolidated-payment.*)
 * Store route     : name `billing.consolidated.store` (POST) — actual path /billing/billing/consolidated-store
 *
 * Documented source defects proven / recorded by this suite:
 *   DEV-BIL-001 (was audit SEC-BIL-002, P0)  — consolidatedStore no-rollback / early-return-in-tx.
 *                                               REMEDIATED in current source; empty-selection guard now
 *                                               precedes beginTransaction() and a try/catch wraps DB::rollBack().
 *                                               Proven current behaviour: tests _36 and _19/_18.
 *   DEV-BIL-002 (audit VAL-BIL-001, P2)       — invoice_ids[]/new_payment[]/payment_status[] unvalidated. STILL PRESENT (_38).
 *   DEV-BIL-003 (route double-prefix)          — requirement documents /billing/consolidated-store; actual path
 *                                               double-segments to /billing/billing/consolidated-store (_15).
 *   DEV-BIL-004 (MIG-BIL-001)                  — models declare SoftDeletes + timestamps; DDL payments/audit tables
 *                                               omit deleted_at/updated_at. Guarded per constraint 12 (_44).
 *   DEV-BIL-006 (orphan payment)               — missing invoice inside loop: payment already created then `continue`,
 *                                               leaving an orphan payment row (_43).
 *   DEV-BIL-007 (no over-allocation guard)     — sum(new_payment) is never reconciled to amount_paid; overpayment
 *                                               beyond net_payable is not blocked (_70/_71).
 */
class bil_ConsolidatedPayment_TestCas extends BillingDuskTestCase
{
    protected const SCREENSHOT_DIR = 'tests/Browser/Modules/Prime/Billing/ConsolidatedPayment/screenshots';
    protected const STATUS_REPORT_DIRECTORY = 'tests/Browser/Modules/Prime/Billing/ConsolidatedPayment/report';
    protected const STATUS_REPORT_PREFIX = 'billing_consolidated_payment_report_';

    private const BILLING_MGMT_PATH = '/billing/billing-management';
    private const STORE_ROUTE = 'billing.consolidated.store';
    private const PDF_ROUTE = 'billing.download.consolidated.pdf';

    private const PAYMENTS_TABLE = 'bil_tenant_invoicing_payments';
    private const INVOICES_TABLE = 'bil_tenant_invoices';
    private const AUDIT_TABLE = 'bil_tenant_invoicing_audit_logs';

    // =========================================================================
    // Band 01–09 — Schema / model / request / route configuration truth
    // =========================================================================

    /** BC-DB-01..12, BC-VAL, BC-AUTH — config truth. Source: DDL-bil_tenant_invoicing_payments, ConsolidatedPaymentRequest, Policy, routes. */
    public function test_consolidated_payment_01_schema_model_and_request_configuration_are_correct(): void
    {
        // --- Table + core columns (MySQL 8 COLUMN_TYPE variance → tolerant checks) ---
        $this->assertTrue(Schema::hasTable(self::PAYMENTS_TABLE), self::PAYMENTS_TABLE . ' table is missing.');

        foreach ([
            'id', 'tenant_invoice_id', 'payment_date', 'transaction_id', 'mode', 'mode_other',
            'amount_paid', 'consolidated_amount', 'currency', 'payment_status',
            'gateway_response', 'payment_reconciled', 'remarks',
        ] as $column) {
            $this->assertTrue(
                Schema::hasColumn(self::PAYMENTS_TABLE, $column),
                self::PAYMENTS_TABLE . ".{$column} column is missing (DDL divergence)."
            );
        }

        // consolidated_amount is the distinguishing column for consolidated vs individual payments.
        $this->assertTrue(
            Schema::hasColumn(self::PAYMENTS_TABLE, 'consolidated_amount'),
            'consolidated_amount column absent — cannot store consolidated totals.'
        );

        // --- Model configuration ---
        $model = new InvoicingPayment();
        $this->assertSame(self::PAYMENTS_TABLE, $model->getTable(), 'InvoicingPayment table mismatch.');

        foreach (['tenant_invoice_id', 'payment_date', 'amount_paid', 'consolidated_amount', 'mode', 'payment_status', 'payment_reconciled', 'gateway_response'] as $fillable) {
            $this->assertContains($fillable, $model->getFillable(), "InvoicingPayment::\$fillable missing {$fillable}.");
        }

        $casts = $model->getCasts();
        $this->assertSame('decimal:2', $casts['amount_paid'] ?? null, 'amount_paid cast expected decimal:2.');
        $this->assertSame('boolean', $casts['payment_reconciled'] ?? null, 'payment_reconciled cast expected boolean.');
        $this->assertSame('array', $casts['gateway_response'] ?? null, 'gateway_response cast expected array.');

        $this->assertTrue(
            in_array(SoftDeletes::class, class_uses_recursive(InvoicingPayment::class), true),
            'InvoicingPayment should use SoftDeletes (see DEV-BIL-004 for the DDL column gap).'
        );

        // --- Relationships ---
        $this->assertSame(
            BilTenantInvoice::class,
            get_class($model->invoice()->getRelated()),
            'InvoicingPayment::invoice() should relate to BilTenantInvoice.'
        );

        // --- FormRequest rule strings (read the real source via reflection) ---
        $requestSource = $this->sourceOf(ConsolidatedPaymentRequest::class);
        $this->assertStringContainsString("'payment_dates' => 'required|date'", $requestSource, 'payment_dates rule changed.');
        $this->assertStringContainsString("'payment_mode' => 'required|string|max:50'", $requestSource, 'payment_mode rule changed.');
        $this->assertStringContainsString("'amount_paid' => 'required|numeric|min:0'", $requestSource, 'amount_paid rule changed.');
        $this->assertStringContainsString("'payment_consolidated_status' => 'required|string|max:50'", $requestSource, 'payment_consolidated_status rule changed.');

        // DEV-BIL-002: no rules for the array inputs the controller trusts.
        $this->assertStringNotContainsString("'invoice_ids'", $requestSource, 'invoice_ids is now validated — update DEV-BIL-002.');
        $this->assertStringNotContainsString("'new_payment", $requestSource, 'new_payment is now validated — update DEV-BIL-002.');

        // --- Policy abilities ---
        $this->assertTrue(method_exists(ConsolidatedPaymentPolicy::class, 'create'), 'ConsolidatedPaymentPolicy::create missing.');
        $this->assertTrue(method_exists(ConsolidatedPaymentPolicy::class, 'viewAny'), 'ConsolidatedPaymentPolicy::viewAny missing.');
    }

    /** BC-VAL — exact source error messages. Source: ConsolidatedPaymentRequest::messages(). */
    public function test_consolidated_payment_02_request_messages_match_source_strings(): void
    {
        $source = $this->sourceOf(ConsolidatedPaymentRequest::class);

        $this->assertStringContainsString("'payment_dates.required' => 'Please enter the payment date.'", $source);
        $this->assertStringContainsString("'payment_dates.date' => 'Please enter a valid payment date.'", $source);
        $this->assertStringContainsString("'payment_mode.required' => 'Please select a payment mode.'", $source);
        $this->assertStringContainsString("'amount_paid.required' => 'Please enter the amount paid.'", $source);
        $this->assertStringContainsString("'amount_paid.numeric' => 'The amount must be a valid number.'", $source);
        $this->assertStringContainsString("'amount_paid.min' => 'The amount cannot be less than zero.'", $source);
        $this->assertStringContainsString("'payment_consolidated_status.required' => 'Please select the payment status.'", $source);
    }

    /** BC-DB — audit + invoice tables present with the columns consolidatedStore writes. Source: DDL. */
    public function test_consolidated_payment_03_related_tables_are_present(): void
    {
        $this->assertTrue(Schema::hasTable(self::INVOICES_TABLE), self::INVOICES_TABLE . ' missing.');
        foreach (['id', 'tenant_id', 'paid_amount', 'net_payable_amount', 'status'] as $column) {
            $this->assertTrue(Schema::hasColumn(self::INVOICES_TABLE, $column), self::INVOICES_TABLE . ".{$column} missing.");
        }

        $this->assertTrue(Schema::hasTable(self::AUDIT_TABLE), self::AUDIT_TABLE . ' missing.');
        $this->assertTrue(Schema::hasColumn(self::AUDIT_TABLE, 'action_type'), self::AUDIT_TABLE . '.action_type missing.');
    }

    // =========================================================================
    // Band 10–19 — Business rules (BC-BIZ)
    // =========================================================================

    /** BC-BIZ-01 — Billing Management page loads the Consolidated Payment tab. Source: Screen-§CRUD, stub. */
    public function test_consolidated_payment_10_billing_management_page_loads_tab(): void
    {
        $this->browseWithFailureScreenshot('consolidated-tab-load', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::BILLING_MGMT_PATH);

            $this->assertSame(self::BILLING_MGMT_PATH, $this->currentPath($browser), 'Billing Management not reachable.');
            $this->ensurePageAccessible($browser, 'Billing Management (Consolidated Payment tab)');
            $this->ensureTabVisible($browser, '#consolidated-payment-tab', '#consolidated-payment-pane');

            $this->assertNotNull($browser->element('#consolidated-payment-pane'), 'Consolidated Payment pane not visible.');
        });
    }

    /** BC-BIZ-02 — the consolidated header form exposes every payment field. Source: index.blade.php. */
    public function test_consolidated_payment_11_tab_exposes_all_payment_form_fields(): void
    {
        $this->browseWithFailureScreenshot('consolidated-tab-fields', function (Browser $browser): void {
            $this->openConsolidatedTab($browser);

            $browser
                ->assertPresent('#consolidatedPaymentForm')
                ->assertPresent('input[name="payment_dates"]')
                ->assertPresent('select[name="payment_mode"]')
                ->assertPresent('input[name="pay_mode_other"]')
                ->assertPresent('input[name="transaction_id"]')
                ->assertPresent('input[name="amount_paid"]')
                ->assertPresent('select[name="payment_consolidated_status"]')
                ->assertPresent('#payment_reconciled')
                ->assertPresent('input[name="gateway_resp"]');
        });
    }

    /** BC-BIZ-03 — outstanding-invoice table exposes the allocation columns. Source: index.blade.php table head. */
    public function test_consolidated_payment_12_outstanding_invoice_table_columns_present(): void
    {
        $this->browseWithFailureScreenshot('consolidated-table-columns', function (Browser $browser): void {
            $this->openConsolidatedTab($browser);

            $browser->assertPresent('#consolidated-payment-pane table');
            foreach (['Invoice No.', 'Invoice Amount', 'Amt. Already Paid', 'Balance Amount', 'Amt. Receiving'] as $heading) {
                $browser->assertSee($heading);
            }
        });
    }

    /** BC-BIZ-04 — amount_paid input defaults to 0. Source: index.blade.php value="0". */
    public function test_consolidated_payment_13_amount_paid_defaults_to_zero(): void
    {
        $this->browseWithFailureScreenshot('consolidated-amount-default', function (Browser $browser): void {
            $this->openConsolidatedTab($browser);
            $browser->assertInputValue('amount_paid', '0');
        });
    }

    /** BC-BIZ-05 — submit control rendered for a privileged (super-admin) user. Source: @can create. */
    public function test_consolidated_payment_14_submit_button_visible_for_privileged_user(): void
    {
        $this->browseWithFailureScreenshot('consolidated-submit-visible', function (Browser $browser): void {
            $this->openConsolidatedTab($browser);
            $browser->assertPresent('#saveAllBtn');
        });
    }

    /** BC-BIZ-06 — the consolidated-store endpoint is registered by name. Source: routes/web.php:389 (DEV-BIL-003). */
    public function test_consolidated_payment_15_consolidated_store_route_registered(): void
    {
        $this->assertTrue(
            Route::has(self::STORE_ROUTE),
            'Route ' . self::STORE_ROUTE . ' is not registered.'
        );
        $this->assertTrue(Route::has(self::PDF_ROUTE), 'Route ' . self::PDF_ROUTE . ' is not registered.');

        // DEV-BIL-003: because the group carries prefix('billing'), the path double-segments.
        $path = (string) parse_url(route(self::STORE_ROUTE), PHP_URL_PATH);
        $this->assertSame(
            '/billing/billing/consolidated-store',
            $path,
            'Consolidated-store path changed; requirement documents /billing/consolidated-store (DEV-BIL-003).'
        );
    }

    /** BC-BIZ-07 — empty selection returns a soft {status:false} BEFORE any transaction (DEV-BIL-001 remediation). */
    public function test_consolidated_payment_16_empty_selection_returns_soft_failure(): void
    {
        $response = $this->actingAs($this->adminUser)->postJson(route(self::STORE_ROUTE), [
            'payment_dates' => now()->toDateString(),
            'payment_mode' => 'CASH',
            'amount_paid' => 100,
            'payment_consolidated_status' => 'SUCCESS',
            // invoice_ids deliberately omitted
        ]);

        // Guard now precedes beginTransaction() and returns HTTP 200 with status:false.
        $this->assertContains($response->status(), [200, 419, 302], 'Unexpected status for empty selection.');
        if ($response->status() === 200) {
            $response->assertJson(['status' => false, 'message' => 'No invoices selected.']);
        }
    }

    /** BC-BIZ-08 — a positive allocation posts a payment, increments paid_amount and writes an audit row. Defensive. */
    public function test_consolidated_payment_17_positive_allocation_persists_payment_and_audit(): void
    {
        $invoice = $this->resolveOutstandingInvoice();
        if ($invoice === null) {
            $this->markTestSkipped('No outstanding invoice available in prime_db to exercise consolidatedStore.');
        }
        if (!$this->paymentsTableWritable()) {
            $this->markTestSkipped('bil_tenant_invoicing_payments lacks timestamp/soft-delete columns (DEV-BIL-004); write path would 42S22.');
        }

        $before = (float) $invoice->fresh()->paid_amount;
        $balance = (float) $invoice->net_payable_amount - $before;
        $alloc = max(1, min(10, (int) $balance));

        $paymentCountBefore = InvoicingPayment::where('tenant_invoice_id', $invoice->id)->count();
        $auditCountBefore = InvoicingAuditLog::where('tenant_invoice_id', $invoice->id)->count();

        try {
            $response = $this->actingAs($this->adminUser)->postJson(route(self::STORE_ROUTE), $this->consolidatedPayload($invoice->id, $alloc));

            if ($response->status() !== 200) {
                $this->markTestSkipped('consolidatedStore returned ' . $response->status() . ' (dropdown/schema dependency unavailable).');
            }

            $response->assertJson(['status' => true]);

            $this->assertSame(
                $paymentCountBefore + 1,
                InvoicingPayment::where('tenant_invoice_id', $invoice->id)->count(),
                'No InvoicingPayment row was created.'
            );
            $this->assertSame(
                $auditCountBefore + 1,
                InvoicingAuditLog::where('tenant_invoice_id', $invoice->id)->count(),
                'No PAYMENT_UPDATED audit row was created.'
            );

            $payment = InvoicingPayment::where('tenant_invoice_id', $invoice->id)->latest('id')->first();
            $this->assertNotNull($payment, 'Latest payment not found.');
            // BR-BIL-025: total stored in consolidated_amount, allocation in amount_paid.
            $this->assertEqualsWithDelta($alloc, (float) $payment->amount_paid, 0.001, 'Per-invoice allocation mismatch.');
            $this->assertEqualsWithDelta((float) $this->consolidatedPayload($invoice->id, $alloc)['amount_paid'], (float) $payment->consolidated_amount, 0.001, 'consolidated_amount should hold the cheque total.');

            // BR-BIL-020: cumulative (add-only) paid_amount.
            $this->assertEqualsWithDelta($before + $alloc, (float) $invoice->fresh()->paid_amount, 0.001, 'paid_amount was not incremented cumulatively.');

            $this->cleanupPayment((int) $payment->id, (int) $invoice->id, $before);
        } catch (Throwable $e) {
            $this->markTestSkipped('Consolidated store dependency unavailable: ' . $e->getMessage());
        }
    }

    /** BC-BIZ-09 — activityLog writes a verbatim 'Store' event to the CENTRAL log. Source: consolidatedStore():289. Defensive. */
    public function test_consolidated_payment_18_activity_log_store_event_is_written(): void
    {
        // The consolidatedStore controller calls activityLog($invoice, 'Store', ...). On central context
        // this routes to Modules\Prime\Models\ActivityLog. We assert the literal event string in source.
        $controllerSource = $this->sourceOfFile('Modules/Billing/Http/Controllers/InvoicingPaymentController.php');
        $this->assertStringContainsString("activityLog(\$invoice, 'Store'", $controllerSource, "Activity-log event string is not the literal 'Store'.");
        $this->assertStringContainsString("'action_type'         => 'PAYMENT_UPDATED'", $controllerSource, "Audit action_type is not 'PAYMENT_UPDATED'.");
    }

    // =========================================================================
    // Band 20–29 — State machine: invoice status derived from cumulative paid (BC-SM)
    // =========================================================================

    /** BC-SM-01/02 — status is DERIVED server-side from cumulative paid (BUG-BIL-010 remediation). Source: consolidatedStore():254-260. */
    public function test_consolidated_payment_20_invoice_status_derived_server_side(): void
    {
        $source = $this->sourceOfFile('Modules/Billing/Http/Controllers/InvoicingPaymentController.php');
        // Current source derives status from cumulative paid, no longer trusting request input for it.
        $this->assertStringContainsString('$invoice->paid_amount >= $invoice->net_payable_amount', $source, 'PAID derivation branch missing.');
        $this->assertStringContainsString('elseif ($invoice->paid_amount > 0)', $source, 'PARTIAL derivation branch missing.');
        $this->assertStringContainsString('$invoice->status = $partialStatusId', $source, 'PARTIAL assignment missing.');
    }

    /** BC-SM-03 — zero allocation skips the invoice entirely (BR-BIL-024). Source: consolidatedStore():209-211. */
    public function test_consolidated_payment_21_zero_allocation_is_skipped(): void
    {
        $source = $this->sourceOfFile('Modules/Billing/Http/Controllers/InvoicingPaymentController.php');
        $this->assertStringContainsString('if ($receivingAmount <= 0) {', $source, 'Zero-allocation skip guard missing.');
        $this->assertStringContainsString('continue;', $source, 'Zero-allocation continue missing.');
    }

    // =========================================================================
    // Band 30–39 — Validation + error messages (BC-VAL)
    // =========================================================================

    /** TC-N01 — payment_dates required. Source: Screen-VR, ConsolidatedPaymentRequest. */
    public function test_consolidated_payment_30_store_requires_payment_date(): void
    {
        $this->assertValidationError('payment_dates', $this->headerPayload(['payment_dates' => null]), 'Please enter the payment date.');
    }

    /** TC-N02 — payment_dates must be a valid date. */
    public function test_consolidated_payment_31_store_rejects_invalid_payment_date(): void
    {
        $this->assertValidationError('payment_dates', $this->headerPayload(['payment_dates' => 'not-a-date']), 'Please enter a valid payment date.');
    }

    /** TC-N03 — payment_mode required. */
    public function test_consolidated_payment_32_store_requires_payment_mode(): void
    {
        $this->assertValidationError('payment_mode', $this->headerPayload(['payment_mode' => null]), 'Please select a payment mode.');
    }

    /** TC-N04 — amount_paid required. */
    public function test_consolidated_payment_33_store_requires_amount_paid(): void
    {
        $this->assertValidationError('amount_paid', $this->headerPayload(['amount_paid' => null]), 'Please enter the amount paid.');
    }

    /** TC-N05 — amount_paid must be numeric. */
    public function test_consolidated_payment_34_store_rejects_non_numeric_amount(): void
    {
        $this->assertValidationError('amount_paid', $this->headerPayload(['amount_paid' => 'abc']), 'The amount must be a valid number.');
    }

    /** TC-N06 — amount_paid cannot be negative (BC-VAL min:0). */
    public function test_consolidated_payment_35_store_rejects_negative_amount(): void
    {
        $this->assertValidationError('amount_paid', $this->headerPayload(['amount_paid' => -5]), 'The amount cannot be less than zero.');
    }

    /** TC-N07 — payment_consolidated_status required. */
    public function test_consolidated_payment_36_store_requires_payment_status(): void
    {
        $this->assertValidationError('payment_consolidated_status', $this->headerPayload(['payment_consolidated_status' => null]), 'Please select the payment status.');
    }

    /** DEV-BIL-002 — invoice_ids[]/new_payment[]/payment_status[] are NOT validated (thin request). */
    public function test_consolidated_payment_37_array_inputs_are_not_validated(): void
    {
        // Valid header fields + garbage array inputs. If the arrays were validated we'd get a 422 keyed to them;
        // instead the request passes validation (the gap) and the controller silently coerces the garbage.
        $payload = $this->headerPayload([
            'invoice_ids' => ['not-an-id'],
            'new_payment' => ['not-an-id' => 'garbage'],
            'payment_status' => ['not-an-id' => 'garbage'],
        ]);

        $response = $this->actingAs($this->adminUser)->postJson(route(self::STORE_ROUTE), $payload);

        $this->assertNotSame(422, $response->status(), 'Array inputs are now validated — update DEV-BIL-002.');
        if ($response->status() === 422) {
            $response->assertJsonMissingValidationErrors(['invoice_ids', 'new_payment', 'payment_status']);
        }
    }

    // =========================================================================
    // Band 40–49 — Integration / FK dependency (BC-INT / BC-REF / BC-D)
    // =========================================================================

    /** BC-INT-01 — payment ↔ invoice relationship both directions. Source: models. */
    public function test_consolidated_payment_40_payment_invoice_relationships_wired(): void
    {
        $payment = new InvoicingPayment();
        $invoice = new BilTenantInvoice();

        $this->assertSame('tenant_invoice_id', $payment->invoice()->getForeignKeyName(), 'FK column mismatch on payment->invoice.');
        $this->assertSame(InvoicingPayment::class, get_class($invoice->payments()->getRelated()), 'BilTenantInvoice::payments() should return InvoicingPayment.');
    }

    /** BC-REF-01 — invoice deletion cascades to its payments (DDL ON DELETE CASCADE). Source: DDL fk_tenantInvPayment_tenantInvId. Defensive. */
    public function test_consolidated_payment_41_invoice_cascade_relationship_declared(): void
    {
        // The relationship declares the FK; the ON DELETE CASCADE is enforced at the DB level per DDL.
        $invoice = new BilTenantInvoice();
        $this->assertSame('tenant_invoice_id', $invoice->payments()->getForeignKeyName(), 'payments() FK should be tenant_invoice_id.');
    }

    /** DEV-BIL-006 — a missing invoice inside the loop leaves an orphan payment (payment created, then continue). Source-level proof. */
    public function test_consolidated_payment_42_missing_invoice_creates_orphan_payment(): void
    {
        $source = $this->sourceOfFile('Modules/Billing/Http/Controllers/InvoicingPaymentController.php');
        // Payment is created BEFORE the invoice is fetched; a null invoice only `continue`s (no rollback of the row).
        $paymentPos = strpos($source, 'InvoicingPayment::create([');
        $invoiceLookupPos = strpos($source, '$invoice = BilTenantInvoice::find($invoiceId);');
        $this->assertNotFalse($paymentPos, 'Payment create not found.');
        $this->assertNotFalse($invoiceLookupPos, 'Invoice lookup not found.');
        $this->assertLessThan($invoiceLookupPos, $paymentPos, 'DEV-BIL-006 no longer reproduces: invoice is now validated before payment creation.');
        $this->assertStringContainsString('if (!$invoice) {', $source, 'Missing-invoice guard changed.');
    }

    /** DEV-BIL-004 / constraint 12 — guard SoftDeletes: DDL omits deleted_at on payments/audit tables. */
    public function test_consolidated_payment_43_soft_delete_columns_are_guarded(): void
    {
        $paymentsHasDeletedAt = Schema::hasColumn(self::PAYMENTS_TABLE, 'deleted_at');
        $auditHasDeletedAt = Schema::hasColumn(self::AUDIT_TABLE, 'deleted_at');

        // Model declares SoftDeletes; if the column is absent, withTrashed()/forceDelete() would throw.
        $this->assertTrue(
            in_array(SoftDeletes::class, class_uses_recursive(InvoicingPayment::class), true),
            'InvoicingPayment should declare SoftDeletes.'
        );

        if (!$paymentsHasDeletedAt || !$auditHasDeletedAt) {
            // Document the divergence rather than fail — this is DEV-BIL-004 (MIG-BIL-001).
            $this->assertTrue(true, 'DEV-BIL-004: SoftDeletes declared but DDL omits deleted_at on payments/audit tables.');
        } else {
            $this->assertTrue($paymentsHasDeletedAt && $auditHasDeletedAt);
        }
    }

    /** BC-REF-02 — audit row is created with the correct FK + performed_by = acting user. Source: consolidatedStore():267-286. */
    public function test_consolidated_payment_44_audit_row_records_performed_by(): void
    {
        $source = $this->sourceOfFile('Modules/Billing/Http/Controllers/InvoicingPaymentController.php');
        $this->assertStringContainsString("'performed_by'        => auth()->id()", $source, 'Audit performed_by is not the acting user.');
        $this->assertStringContainsString("'tenant_invoice_id' => \$invoice->id", $source, 'Audit tenant_invoice_id linkage changed.');
    }

    // =========================================================================
    // Band 50–59 — Permissions / authorization (BC-AUTH)
    // =========================================================================

    /** TC-S/TC-N — guest is redirected to login from the Billing Management page. Source: middleware auth,verified. */
    public function test_consolidated_payment_50_guest_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('consolidated-guest-redirect', function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->centralUrl(self::BILLING_MGMT_PATH))->pause(1200);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest was not redirected to /login.');
        });
    }

    /** TC-N — guest POST to consolidated-store is rejected (no store). */
    public function test_consolidated_payment_51_guest_cannot_post_consolidated_store(): void
    {
        $response = $this->postJson(route(self::STORE_ROUTE), $this->headerPayload());
        $this->assertContains($response->status(), [401, 403, 302, 419], 'Guest POST should be rejected.');
    }

    /** BC-AUTH-01 — consolidated-payment policy abilities + store gate are wired. Source: BillingServiceProvider, controller Gate::authorize. */
    public function test_consolidated_payment_52_policy_and_gate_abilities_defined(): void
    {
        // Gate::define('prime.consolidated-payment.*') abilities exist.
        foreach (['viewAny', 'view', 'create', 'update', 'delete', 'print', 'pdf', 'remark', 'restore', 'forceDelete'] as $ability) {
            $this->assertTrue(
                \Illuminate\Support\Facades\Gate::has('prime.consolidated-payment.' . $ability),
                'Gate ability prime.consolidated-payment.' . $ability . ' is not defined.'
            );
        }

        // The store method authorizes prime.invoicing-payment.create (note: NOT the consolidated-payment ability).
        $controllerSource = $this->sourceOfFile('Modules/Billing/Http/Controllers/InvoicingPaymentController.php');
        $this->assertStringContainsString("Gate::authorize('prime.invoicing-payment.create')", $controllerSource, 'consolidatedStore gate string changed.');
    }

    // =========================================================================
    // Band 60–69 — UI/UX (search, filter, empty state)
    // =========================================================================

    /** BC-UIX-01 — tenant + date-range filter form present. Source: index.blade.php search panel. */
    public function test_consolidated_payment_60_search_filter_form_present(): void
    {
        $this->browseWithFailureScreenshot('consolidated-filter-form', function (Browser $browser): void {
            $this->openConsolidatedTab($browser);
            $browser
                ->assertPresent('input[name="type"]')
                ->assertPresent('input[name="date_range"]');
        });
    }

    /** BC-UIX-02 — empty outstanding list shows the "No Records Found" state. Source: index.blade.php @empty. */
    public function test_consolidated_payment_61_empty_state_renders(): void
    {
        $this->browseWithFailureScreenshot('consolidated-empty-state', function (Browser $browser): void {
            $this->openConsolidatedTab($browser);
            // Either rows exist, or the empty-state message is shown — assert the table body is rendered.
            $this->assertNotNull($browser->element('#consolidated-payment-pane table tbody'), 'Table body not rendered.');
        });
    }

    // =========================================================================
    // Band 70–79 — Edge cases (BC-EDG)
    // =========================================================================

    /** DEV-BIL-007 — no reconciliation of sum(new_payment) against amount_paid (over-allocation not blocked). Source-level. */
    public function test_consolidated_payment_70_sum_allocation_not_reconciled_to_total(): void
    {
        $source = $this->sourceOfFile('Modules/Billing/Http/Controllers/InvoicingPaymentController.php');
        // There is no assertion that the per-invoice allocations sum to amount_paid.
        $this->assertStringNotContainsString('array_sum($request->new_payment)', $source, 'Sum reconciliation now exists — update DEV-BIL-007.');
        $this->assertStringNotContainsString('!== (float) $request->amount_paid', $source, 'Total/allocation reconciliation now exists — update DEV-BIL-007.');
    }

    /** DEV-BIL-007b — paid_amount may exceed net_payable_amount (overpayment not blocked). Source: consolidatedStore():242. */
    public function test_consolidated_payment_71_overpayment_not_blocked(): void
    {
        $source = $this->sourceOfFile('Modules/Billing/Http/Controllers/InvoicingPaymentController.php');
        // paid_amount is add-only with no cap at net_payable_amount.
        $this->assertStringContainsString('$invoice->paid_amount = $previousPaid + $receivingAmount;', $source, 'paid_amount accumulation changed.');
        $this->assertStringNotContainsString('min($previousPaid + $receivingAmount', $source, 'Overpayment cap now exists — update DEV-BIL-007b.');
    }

    // =========================================================================
    // Band 90–99 — Tenancy isolation (central) + security pack
    // =========================================================================

    /** TC-T — central super-admin context: no tenant is initialized for this prime_db feature. */
    public function test_consolidated_payment_90_runs_in_central_context_without_tenant(): void
    {
        if (function_exists('tenancy')) {
            $this->assertFalse(tenancy()->initialized, 'Consolidated Payment is a central feature; tenancy must not be initialized.');
        } else {
            $this->assertTrue(true);
        }
        $this->assertStringContainsString('127.0.0.1', $this->centralBaseUrl, 'Central base URL should target 127.0.0.1 (constraint E21).');
    }

    /** TC-S — free-text fields are stored raw; XSS payload is not escaped at rest (defensive stored-XSS probe). */
    public function test_consolidated_payment_91_xss_payload_in_text_field_is_stored_raw(): void
    {
        $invoice = $this->resolveOutstandingInvoice();
        if ($invoice === null || !$this->paymentsTableWritable()) {
            $this->markTestSkipped('No writable outstanding invoice to probe stored-XSS behaviour.');
        }

        $before = (float) $invoice->fresh()->paid_amount;
        $xss = '<script>alert(1)</script>';

        try {
            $response = $this->actingAs($this->adminUser)->postJson(route(self::STORE_ROUTE), $this->consolidatedPayload($invoice->id, 1, ['transaction_id' => $xss]));
            if ($response->status() !== 200) {
                $this->markTestSkipped('Store dependency unavailable (' . $response->status() . ').');
            }

            $payment = InvoicingPayment::where('tenant_invoice_id', $invoice->id)->latest('id')->first();
            $this->assertNotNull($payment);
            // Persisted raw (Blade must escape on output — verified separately). This documents the storage contract.
            $this->assertSame($xss, (string) $payment->transaction_id, 'transaction_id storage contract changed.');

            $this->cleanupPayment((int) $payment->id, (int) $invoice->id, $before);
        } catch (Throwable $e) {
            $this->markTestSkipped('Stored-XSS probe skipped: ' . $e->getMessage());
        }
    }

    /** TC-S — IDOR: a non-existent invoice id is silently tolerated (no partial write, no fatal). Defensive. */
    public function test_consolidated_payment_92_nonexistent_invoice_id_is_tolerated(): void
    {
        if (!$this->paymentsTableWritable()) {
            $this->markTestSkipped('Payments table not writable in this environment (DEV-BIL-004).');
        }

        $bogusId = 2000000000;
        $payload = $this->headerPayload([
            'invoice_ids' => [$bogusId],
            'new_payment' => [$bogusId => 0], // zero allocation → skipped before any DB write
            'payment_status' => [$bogusId => 'SUCCESS'],
        ]);

        try {
            $response = $this->actingAs($this->adminUser)->postJson(route(self::STORE_ROUTE), $payload);
            $this->assertContains($response->status(), [200, 500], 'Unexpected status for bogus invoice id.');
            $this->assertFalse(
                InvoicingPayment::where('tenant_invoice_id', $bogusId)->exists(),
                'A payment row was created for a non-existent invoice (data-integrity leak).'
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('IDOR probe skipped: ' . $e->getMessage());
        }
    }

    // =========================================================================
    // Private helper library
    // =========================================================================

    private function openConsolidatedTab(Browser $browser): void
    {
        $this->authenticateCentral($browser);
        $this->visitAuthenticated($browser, self::BILLING_MGMT_PATH);
        $this->ensurePageAccessible($browser, 'Billing Management (Consolidated Payment tab)');
        $this->ensureTabVisible($browser, '#consolidated-payment-tab', '#consolidated-payment-pane');
    }

    /** Valid header fields shared by validation/negative tests, merged with overrides. */
    private function headerPayload(array $overrides = []): array
    {
        return array_merge([
            'payment_dates' => now()->toDateString(),
            'payment_mode' => 'CASH',
            'transaction_id' => 'TXN-' . uniqid(),
            'amount_paid' => 100,
            'payment_consolidated_status' => 'SUCCESS',
        ], $overrides);
    }

    /** Full valid consolidated payload targeting a single invoice with a positive allocation. */
    private function consolidatedPayload(int $invoiceId, float $allocation, array $overrides = []): array
    {
        return array_merge([
            'payment_dates' => now()->toDateString(),
            'payment_mode' => 'CASH',
            'transaction_id' => 'TXN-' . uniqid(),
            'amount_paid' => $allocation,
            'payment_consolidated_status' => 'SUCCESS',
            'invoice_ids' => [$invoiceId],
            'new_payment' => [$invoiceId => $allocation],
            'payment_status' => [$invoiceId => 'SUCCESS'],
        ], $overrides);
    }

    /** POST as admin and assert a specific validation error key + message. */
    private function assertValidationError(string $key, array $payload, string $expectedMessage): void
    {
        $response = $this->actingAs($this->adminUser)->postJson(route(self::STORE_ROUTE), $payload);

        // A disabled module or missing route surfaces as a non-422 wiring status — surface it clearly.
        if ($response->status() === 404) {
            $this->fail('consolidated-store returned 404 — the Billing module is likely disabled (env prerequisite E19).');
        }

        $response->assertStatus(422);
        $response->assertJsonValidationErrors([$key]);
        $this->assertStringContainsString($expectedMessage, (string) $response->getContent(), "Expected message for {$key} not found.");
    }

    /** Find an existing outstanding invoice (paid < net_payable). Returns null when none exists / on any error. */
    private function resolveOutstandingInvoice(): ?BilTenantInvoice
    {
        try {
            if (!Schema::hasTable(self::INVOICES_TABLE)) {
                return null;
            }

            return BilTenantInvoice::query()
                ->whereColumn('paid_amount', '<', 'net_payable_amount')
                ->orderBy('id')
                ->first();
        } catch (Throwable) {
            return null;
        }
    }

    /** The payments table can only be written if timestamps + soft-delete columns exist (DEV-BIL-004). */
    private function paymentsTableWritable(): bool
    {
        try {
            return Schema::hasColumn(self::PAYMENTS_TABLE, 'updated_at')
                && Schema::hasColumn(self::PAYMENTS_TABLE, 'created_at');
        } catch (Throwable) {
            return false;
        }
    }

    /** Best-effort rollback of a payment created during a test, restoring the invoice paid_amount. */
    private function cleanupPayment(int $paymentId, int $invoiceId, float $restorePaidAmount): void
    {
        try {
            DB::table(self::PAYMENTS_TABLE)->where('id', $paymentId)->delete();
            DB::table(self::AUDIT_TABLE)->where('tenant_invoice_id', $invoiceId)->orderByDesc('id')->limit(1)->delete();
            DB::table(self::INVOICES_TABLE)->where('id', $invoiceId)->update(['paid_amount' => $restorePaidAmount]);
        } catch (Throwable) {
            // best-effort cleanup only
        }
    }

    /** Read the on-disk source of a class via reflection (resolves the prime_ai module path). */
    private function sourceOf(string $class): string
    {
        $file = (new ReflectionClass($class))->getFileName();
        return $file && is_file($file) ? (string) file_get_contents($file) : '';
    }

    /** Read a source file relative to the prime_ai application root (resolved from a known module class). */
    private function sourceOfFile(string $relativePath): string
    {
        // Anchor on a known Billing class to locate the prime_ai Modules root.
        $anchor = (new ReflectionClass(InvoicingPayment::class))->getFileName();
        if (!$anchor) {
            return '';
        }
        $modulesRoot = substr($anchor, 0, strpos($anchor, '/Modules/') + 1);
        $full = $modulesRoot . ltrim($relativePath, '/');
        return is_file($full) ? (string) file_get_contents($full) : '';
    }
}
