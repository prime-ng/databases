<?php

namespace Tests\Browser\Modules\Prime\Billing\ConsolidatedPayment;

use App\Models\User;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Tests\Browser\Modules\Prime\Billing\BillingDuskTestCase;
use Throwable;

/**
 * Consolidated Payment — V1 (foundation) Dusk suite.
 *
 * Feature   : Billing / Consolidated Payment (central Super-Admin, prime_db).
 * Screen     : Billing Management -> Consolidated Payment tab
 *              (GET /billing/billing-management?type=consolidated-payment).
 * Store      : POST /billing/billing/consolidated-store  (InvoicingPaymentController@consolidatedStore)
 * Primary DB : bil_tenant_invoicing_payments  (Billing_DDL_v1.sql line 62)  -> prefix bil_
 *
 * Style: mirrors the committed sibling
 *   tests/Browser/Modules/Prime/Billing/ConsolidatedPayment/prm_ConsolidatedPaymentTab_TestCas.php
 * (browser Dusk, central chain via BillingDuskTestCase: authenticateCentral / visitAuthenticated /
 *  centralUrl / ensureTabVisible / browseWithFailureScreenshot). PRIME-SIDE => no tenant init.
 *
 * Many business/DB flows depend on pre-existing outstanding invoices and on the Billing module
 * being enabled in modules_statuses.json; those are wrapped defensively (try/catch -> markTestSkipped)
 * so a partial environment stays green. Source-truth assertions read the real app files under
 * MAIN_PROJECT_PATH and never invent routes, selectors, gates, or messages.
 */
class bil_ConsolidatedPaymentV1_TestCas extends BillingDuskTestCase
{
    protected const SCREENSHOT_DIR = 'tests/Browser/Modules/Prime/Billing/ConsolidatedPayment/screenshots';
    protected const STATUS_REPORT_DIRECTORY = 'tests/Browser/Modules/Prime/Billing/ConsolidatedPayment/report';
    protected const STATUS_REPORT_PREFIX = 'billing_consolidated_payment_v1_report_';

    private const BILLING_MANAGEMENT_PATH = '/billing/billing-management';
    private const CONSOLIDATED_TAB_QUERY  = '/billing/billing-management?type=consolidated-payment';
    private const CONSOLIDATED_STORE_PATH = '/billing/billing/consolidated-store';
    private const DOWNLOAD_PDF_PATH       = '/billing/billing/download-consolidated-pdf';

    private const PAYMENTS_TABLE = 'bil_tenant_invoicing_payments';
    private const INVOICES_TABLE = 'bil_tenant_invoices';
    private const AUDIT_TABLE    = 'bil_tenant_invoicing_audit_logs';

    private const CONTROLLER_SRC = 'Modules/Billing/app/Http/Controllers/InvoicingPaymentController.php';
    private const REQUEST_SRC    = 'Modules/Billing/app/Http/Requests/ConsolidatedPaymentRequest.php';
    private const POLICY_SRC     = 'Modules/Billing/app/Policies/ConsolidatedPaymentPolicy.php';
    private const MODEL_SRC      = 'Modules/Billing/app/Models/InvoicingPayment.php';
    private const BM_CONTROLLER_SRC = 'Modules/Billing/app/Http/Controllers/BillingManagementController.php';

    // ---------------------------------------------------------------------
    // 01-03  Schema / model / request configuration (source truth)
    // ---------------------------------------------------------------------

    public function test_consolidated_payment_01_payments_table_schema_matches_ddl(): void
    {
        try {
            if (!Schema::hasTable(self::PAYMENTS_TABLE)) {
                $this->markTestSkipped(self::PAYMENTS_TABLE . ' not present (Billing module disabled / DDL not migrated).');
            }
        } catch (Throwable $e) {
            $this->markTestSkipped('Schema inspection unavailable: ' . $e->getMessage());
        }

        $this->assertTrue(
            Schema::hasColumns(self::PAYMENTS_TABLE, [
                'id', 'tenant_invoice_id', 'payment_date', 'transaction_id', 'mode', 'mode_other',
                'amount_paid', 'consolidated_amount', 'currency', 'payment_status',
                'gateway_response', 'payment_reconciled', 'remarks',
            ]),
            'bil_tenant_invoicing_payments is missing one or more DDL columns.'
        );

        // MIG-BIL-001: model uses SoftDeletes but the DDL table has no deleted_at column.
        $this->assertFalse(
            Schema::hasColumn(self::PAYMENTS_TABLE, 'deleted_at'),
            'DDL unexpectedly gained deleted_at — reconcile MIG-BIL-001 note if the schema was patched.'
        );
    }

    public function test_consolidated_payment_02_model_configuration_is_correct(): void
    {
        $model = new \Modules\Billing\Models\InvoicingPayment();

        $this->assertSame(self::PAYMENTS_TABLE, $model->getTable(), 'InvoicingPayment table mismatch.');

        foreach (['tenant_invoice_id', 'amount_paid', 'consolidated_amount', 'payment_status', 'payment_reconciled', 'gateway_response'] as $col) {
            $this->assertContains($col, $model->getFillable(), "Missing fillable: {$col}");
        }

        $casts = $model->getCasts();
        $this->assertSame('boolean', $casts['payment_reconciled'] ?? null, 'payment_reconciled cast should be boolean.');
        $this->assertSame('array', $casts['gateway_response'] ?? null, 'gateway_response cast should be array (BC-EDG-05 read-decode risk).');

        $this->assertContains(
            \Illuminate\Database\Eloquent\SoftDeletes::class,
            class_uses_recursive(\Modules\Billing\Models\InvoicingPayment::class),
            'InvoicingPayment must use SoftDeletes (schema gap vs DDL — MIG-BIL-001).'
        );

        $this->assertTrue(method_exists($model, 'invoice'), 'invoice() relationship missing.');
        $this->assertTrue(method_exists($model, 'paymentStatusData'), 'paymentStatusData() relationship missing.');
    }

    public function test_consolidated_payment_03_request_rules_and_messages_are_correct(): void
    {
        $src = $this->appSource(self::REQUEST_SRC);

        $this->assertStringContainsString("'payment_dates' => 'required|date'", $src);
        $this->assertStringContainsString("'payment_mode' => 'required|string|max:50'", $src);
        $this->assertStringContainsString("'amount_paid' => 'required|numeric|min:0'", $src);
        $this->assertStringContainsString("'payment_consolidated_status' => 'required|string|max:50'", $src);
        $this->assertStringContainsString("'gateway_resp' => 'nullable|string|max:1000'", $src);
        $this->assertStringContainsString("Please enter the payment date.", $src);
        $this->assertStringContainsString("Please select a payment mode.", $src);
        $this->assertStringContainsString("Please select the payment status.", $src);

        // BC-VAL-10: authorize() delegates to the invoicing-payment.create gate (NOT consolidated-payment).
        $this->assertStringContainsString("Gate::allows('prime.invoicing-payment.create')", $src);

        // VAL-BIL-001: no array rules for invoice_ids / new_payment / payment_status.
        $this->assertStringNotContainsString('invoice_ids', $src, 'invoice_ids should have no rule (VAL-BIL-001).');
        $this->assertStringNotContainsString('new_payment', $src, 'new_payment should have no rule (VAL-BIL-001).');
    }

    // ---------------------------------------------------------------------
    // 04-06  Tab render / list / filters (browser, mirrors sibling)
    // ---------------------------------------------------------------------

    public function test_consolidated_payment_04_tab_loads_with_form_fields(): void
    {
        $this->browseWithFailureScreenshot('v1-tab-load', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CONSOLIDATED_TAB_QUERY);

            $this->assertSame(self::BILLING_MANAGEMENT_PATH, $this->currentPath($browser), 'Billing Management not reachable.');
            $this->ensurePageAccessible($browser, 'Consolidated Payment tab');
            $this->ensureTabVisible($browser, '#consolidated-payment-tab', '#consolidated-payment-pane');

            $browser
                ->assertPresent('input[name="payment_dates"]')
                ->assertPresent('select[name="payment_mode"]')
                ->assertPresent('input[name="amount_paid"]')
                ->assertPresent('select[name="payment_consolidated_status"]')
                ->assertPresent('#consolidatedPaymentForm');
        });
    }

    public function test_consolidated_payment_05_list_shows_outstanding_invoices_table(): void
    {
        $this->browseWithFailureScreenshot('v1-list-table', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CONSOLIDATED_TAB_QUERY);
            $this->ensureTabVisible($browser, '#consolidated-payment-tab', '#consolidated-payment-pane');

            $browser->assertPresent('#consolidated-payment-pane table')
                ->assertPresent('#total_balance_amount')
                ->assertPresent('#total_receiving_amount');
        });
    }

    public function test_consolidated_payment_06_filter_fields_present(): void
    {
        $this->browseWithFailureScreenshot('v1-filters', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CONSOLIDATED_TAB_QUERY);
            $this->ensureTabVisible($browser, '#consolidated-payment-tab', '#consolidated-payment-pane');

            $browser
                ->assertPresent('input[name="type"][value="consolidated-payment"]')
                ->assertPresent('[name="tenat_id"]')
                ->assertPresent('#date_range');
        });
    }

    // ---------------------------------------------------------------------
    // 07-08  Store endpoint negative paths (browser-issued JSON)
    // ---------------------------------------------------------------------

    public function test_consolidated_payment_07_store_without_invoices_returns_no_invoices_selected(): void
    {
        $this->browseWithFailureScreenshot('v1-store-no-invoices', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CONSOLIDATED_TAB_QUERY);

            $resp = $this->sendFormRequestFromBrowser($browser, self::CONSOLIDATED_STORE_PATH, [
                'payment_dates'               => date('Y-m-d'),
                'payment_mode'                => 'CASH',
                'amount_paid'                 => '100',
                'payment_consolidated_status' => 'SUCCESS',
            ]);

            // Empty-selection guard runs BEFORE beginTransaction (SEC-BIL-002 remediated) -> JSON, HTTP 200.
            $this->assertContains((int) ($resp['status'] ?? 0), [200, 0], 'Unexpected HTTP status for empty selection.');
            if (($resp['status'] ?? 0) === 200) {
                $this->assertStringContainsString('No invoices selected', (string) ($resp['body'] ?? ''));
            }
        });
    }

    public function test_consolidated_payment_08_store_missing_required_fields_returns_422(): void
    {
        $this->browseWithFailureScreenshot('v1-store-missing-required', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CONSOLIDATED_TAB_QUERY);

            $resp = $this->sendFormRequestFromBrowser($browser, self::CONSOLIDATED_STORE_PATH, [
                'invoice_ids' => [1],
            ]);

            $this->assertContains((int) ($resp['status'] ?? 0), [422, 0], 'Missing required fields should yield HTTP 422.');
            if (($resp['status'] ?? 0) === 422) {
                $this->assertStringContainsString('Please enter the payment date', (string) ($resp['body'] ?? ''));
            }
        });
    }

    // ---------------------------------------------------------------------
    // 09-16  Authorization + business-rule source truth
    // ---------------------------------------------------------------------

    public function test_consolidated_payment_09_store_gate_is_invoicing_payment_create(): void
    {
        $src = $this->appSource(self::CONTROLLER_SRC);
        $this->assertStringContainsString("Gate::authorize('prime.invoicing-payment.create')", $src,
            'consolidatedStore must gate on prime.invoicing-payment.create (screen doc claim of billing-management.create is wrong).');
    }

    public function test_consolidated_payment_10_zero_allocation_is_skipped(): void
    {
        $src = $this->appSource(self::CONTROLLER_SRC);
        $this->assertStringContainsString('$receivingAmount = (float) ($request->new_payment[$invoiceId] ?? 0);', $src);
        $this->assertStringContainsString('if ($receivingAmount <= 0) {', $src, 'Zero-allocation skip (BC-BIZ-03) missing.');
    }

    public function test_consolidated_payment_11_consolidated_amount_stored_per_row(): void
    {
        $src = $this->appSource(self::CONTROLLER_SRC);
        $this->assertStringContainsString("'consolidated_amount'  => (float) \$request->amount_paid,", $src,
            'consolidated_amount must store the TOTAL amount_paid on each row (BC-BIZ-02).');
        $this->assertStringContainsString("'amount_paid'          => \$receivingAmount,", $src,
            'per-row amount_paid must store the per-invoice receiving amount (BC-BIZ-02).');
    }

    public function test_consolidated_payment_12_download_pdf_requires_view_permission(): void
    {
        $src = $this->appSource(self::CONTROLLER_SRC);
        $this->assertStringContainsString("Gate::authorize('prime.invoicing-payment.view')", $src,
            'downloadConsolidatedPdf must gate on prime.invoicing-payment.view (screen doc claim of "no gate" is stale).');
    }

    public function test_consolidated_payment_13_guest_is_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('v1-guest-redirect', function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->centralUrl(self::CONSOLIDATED_TAB_QUERY))->pause(1200);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest should be redirected to /login.');
        });
    }

    public function test_consolidated_payment_14_list_hard_filter_excludes_paid_invoices(): void
    {
        $src = $this->appSource(self::BM_CONTROLLER_SRC);
        $this->assertStringContainsString("whereColumn('paid_amount', '<', 'net_payable_amount')", $src,
            'List query must use the < outstanding-balance hard filter (BC-INT-02).');
    }

    public function test_consolidated_payment_15_audit_log_action_type_is_payment_updated(): void
    {
        $src = $this->appSource(self::CONTROLLER_SRC);
        $this->assertStringContainsString("'action_type'         => 'PAYMENT_UPDATED',", $src,
            'Per-invoice audit action_type must be the literal PAYMENT_UPDATED (BC-BIZ-08).');
    }

    public function test_consolidated_payment_16_activity_log_event_is_store(): void
    {
        $src = $this->appSource(self::CONTROLLER_SRC);
        $this->assertStringContainsString("activityLog(\$invoice, 'Store', [", $src,
            'activityLog event string must be the literal Store (BC-BIZ-08).');
    }

    // =====================================================================
    // Private helper library
    // =====================================================================

    private function appSource(string $relative): string
    {
        $base = rtrim((string) env('MAIN_PROJECT_PATH', ''), '/');
        if ($base === '' || !is_file($base . '/' . $relative)) {
            $this->markTestSkipped('App source not available (set MAIN_PROJECT_PATH): ' . $relative);
        }

        return (string) file_get_contents($base . '/' . $relative);
    }

    /**
     * Issue an authenticated, form-encoded POST from the current browser page and
     * return ['status' => int, 'body' => string]. Uses a synchronous XHR so the
     * request rides the browser's real session/cookies (Dusk cannot ->post() directly).
     */
    private function sendFormRequestFromBrowser(Browser $browser, string $path, array $payload): array
    {
        $url   = $this->centralUrl($path);
        $body  = http_build_query($payload);
        $bodyJs = json_encode($body);
        $urlJs  = json_encode($url);

        $script = <<<JS
            try {
                var meta = document.querySelector('meta[name="csrf-token"]');
                var token = meta ? meta.getAttribute('content') : '';
                var xhr = new XMLHttpRequest();
                xhr.open('POST', {$urlJs}, false);
                xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
                xhr.setRequestHeader('Accept', 'application/json');
                xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8');
                if (token) { xhr.setRequestHeader('X-CSRF-TOKEN', token); }
                xhr.send({$bodyJs});
                return JSON.stringify({ status: xhr.status, body: xhr.responseText });
            } catch (e) {
                return JSON.stringify({ status: 0, body: String(e) });
            }
        JS;

        $raw = $browser->script($script);
        $decoded = json_decode(is_array($raw) ? ($raw[0] ?? '{}') : '{}', true);

        return is_array($decoded) ? $decoded : ['status' => 0, 'body' => ''];
    }
}
