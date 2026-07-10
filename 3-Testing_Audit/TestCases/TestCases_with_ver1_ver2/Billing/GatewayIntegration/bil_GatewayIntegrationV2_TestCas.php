<?php

namespace Tests\Browser\Modules\Prime\Billing\GatewayIntegration;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Modules\Billing\Models\InvoicingPayment;
use Tests\Browser\Modules\Prime\Billing\prm_BillingDuskTestCase_TestCas;
use Throwable;

/**
 * Payment Gateway Integration (Razorpay) — V2 comprehensive suite.
 *
 * FEATURE STATUS: PLANNED / NOT IMPLEMENTED. This suite has two kinds of tests:
 *   1. CURRENT-REALITY truths (schema, model, route-absence, composer, config,
 *      UI-absence) — assert what is actually true today.
 *   2. PLANNED-CONTRACT stubs — every future business rule, state transition,
 *      validation rule and security requirement from the screen file is
 *      captured as a documented markTestSkipped() so the contract is traceable
 *      and turns green only when the feature is built.
 *
 * DB scope: prime_db (central) — NO tenant init. Style: central Dusk base chain.
 * V2 method count >= 2x V1 (V1 = 14, V2 = 32).
 *
 * Semantic numbering bands:
 *   01-09 schema/model/dependency truth   40-49 integration / route absence
 *   10-19 business rules (planned)         50-59 permissions (planned)
 *   20-29 state machine (planned)          60-69 UI/UX absence
 *   30-39 validation (planned)             70-79 edge cases
 *                                          90-99 security pack (BC-S, planned)
 */
class bil_GatewayIntegrationV2_TestCas extends prm_BillingDuskTestCase_TestCas
{
    protected const SCREENSHOT_DIR = 'tests/Browser/Modules/Prime/Billing/GatewayIntegration/screenshots';
    protected const STATUS_REPORT_DIRECTORY = 'tests/Browser/Modules/Prime/Billing/GatewayIntegration/report';
    protected const STATUS_REPORT_PREFIX = 'billing_gateway_integration_v2_report_';

    private const PAYMENTS_TABLE = 'bil_tenant_invoicing_payments';
    private const GATEWAY_COLUMN = 'gateway_response';

    private const ROOT_COMPOSER = 'composer.json';
    private const MODULE_COMPOSER = 'Modules/Billing/composer.json';
    private const MODULE_API_ROUTES = 'Modules/Billing/routes/api.php';
    private const MODULE_WEB_ROUTES = 'Modules/Billing/routes/web.php';
    private const MODULE_CONFIG = 'Modules/Billing/config/config.php';
    private const MODULE_VIEWS = 'Modules/Billing/resources/views';

    private const PLANNED_INITIATE_URI = 'billing/payment/initiate';
    private const PLANNED_VERIFY_URI = 'billing/payment/verify';
    private const PLANNED_WEBHOOK_URI = 'billing/webhook/razorpay';

    private const NOT_IMPLEMENTED = 'GatewayIntegration is PLANNED / NOT IMPLEMENTED (REQ-BIL-014 = Not started / future). ';

    // =====================================================================
    // Band 01-09 — Schema / model / dependency truth (current reality)
    // =====================================================================

    /** TC-P01 / BC-DB-01 — Source: DDL-bil_tenant_invoicing_payments (line 73) */
    public function test_gatewayintegration_01_gateway_response_column_exists(): void
    {
        $this->assertTrue(Schema::hasColumn(self::PAYMENTS_TABLE, self::GATEWAY_COLUMN));
    }

    /** TC-P02 / BC-DB-02 — json + nullable — Source: DDL */
    public function test_gatewayintegration_02_gateway_response_is_json_and_nullable(): void
    {
        $meta = $this->columnMeta(self::PAYMENTS_TABLE, self::GATEWAY_COLUMN);
        if ($meta === null) {
            $this->markTestSkipped('information_schema unavailable for column metadata.');
            return;
        }
        $this->assertStringContainsString('json', strtolower((string) $meta->DATA_TYPE));
        $this->assertSame('YES', strtoupper((string) $meta->IS_NULLABLE));
    }

    /** TC-P03 / BC-DB-03 — default NULL — Source: DDL (DEFAULT NULL) */
    public function test_gatewayintegration_03_gateway_response_default_is_null(): void
    {
        $meta = $this->columnMeta(self::PAYMENTS_TABLE, self::GATEWAY_COLUMN);
        if ($meta === null) {
            $this->markTestSkipped('information_schema unavailable for column metadata.');
            return;
        }
        $this->assertNull($meta->COLUMN_DEFAULT, 'gateway_response should default to NULL.');
    }

    /** TC-P04 / BC-BIZ-01 — array cast — Source: Model casts */
    public function test_gatewayintegration_04_model_casts_gateway_response_to_array(): void
    {
        $casts = (new InvoicingPayment())->getCasts();
        $this->assertArrayHasKey(self::GATEWAY_COLUMN, $casts);
        $this->assertSame('array', $casts[self::GATEWAY_COLUMN]);
    }

    /** TC-P05 / BC-BIZ-02 — fillable — Source: Model fillable */
    public function test_gatewayintegration_05_gateway_response_is_fillable(): void
    {
        $this->assertContains(self::GATEWAY_COLUMN, (new InvoicingPayment())->getFillable());
    }

    /** TC-P06 / BC-BIZ-03 — array cast round-trip (in-memory) */
    public function test_gatewayintegration_06_gateway_response_array_cast_round_trip(): void
    {
        $model = new InvoicingPayment();
        $model->gateway_response = ['event' => 'payment.captured', 'id' => 'pay_ABC'];
        $this->assertIsArray($model->gateway_response);
        $this->assertSame('pay_ABC', $model->gateway_response['id']);
    }

    /** TC-P07 / BC-EDG-01 — nested/large JSON survives cast serialization */
    public function test_gatewayintegration_07_gateway_response_stores_nested_webhook_shape(): void
    {
        $webhook = [
            'event' => 'payment.captured',
            'payload' => ['payment' => ['entity' => ['id' => 'pay_X', 'amount' => 500000, 'currency' => 'INR']]],
        ];
        $model = new InvoicingPayment();
        $model->gateway_response = $webhook;
        $decoded = json_decode((string) $model->getAttributes()[self::GATEWAY_COLUMN], true);
        $this->assertSame('INR', $decoded['payload']['payment']['entity']['currency']);
    }

    /** TC-P08 / BC-INT-01 — Source: root composer.json (razorpay ^2.9) */
    public function test_gatewayintegration_08_razorpay_sdk_present_in_root_composer(): void
    {
        $contents = File::get(base_path(self::ROOT_COMPOSER));
        $this->assertStringContainsString('razorpay/razorpay', $contents);
    }

    /** TC-N05 / DEV-BIL-020 (doc-only) — razorpay absent from module composer */
    public function test_gatewayintegration_09_razorpay_absent_from_module_composer(): void
    {
        $this->assertStringNotContainsString('razorpay', strtolower(File::get(base_path(self::MODULE_COMPOSER))));
    }

    // =====================================================================
    // Band 10-19 — Business rules (PLANNED — skipped pending implementation)
    // =====================================================================

    /** BC-BIZ-10 — Source: Screen §Webhook Security (endpoint outside auth) */
    public function test_gatewayintegration_10_webhook_must_be_outside_auth_middleware(): void
    {
        $this->markTestSkipped(self::NOT_IMPLEMENTED
            . 'Planned: POST /api/v1/billing/webhook/razorpay must NOT sit behind auth middleware '
            . '(server-to-server, no session). Verify once the route is registered.');
    }

    /** BC-BIZ-11 — Source: Screen §Webhook Event Handling (payment.captured) */
    public function test_gatewayintegration_11_payment_captured_creates_payment_and_updates_invoice(): void
    {
        $this->markTestSkipped(self::NOT_IMPLEMENTED
            . 'Planned: payment.captured -> match invoice by payment_id in gateway_response, create '
            . 'InvoicingPayment, update invoice.paid_amount, write audit log, set payment_reconciled = 1.');
    }

    /** BC-BIZ-12 — Source: Screen §Webhook Event Handling (non-mutating events) */
    public function test_gatewayintegration_12_other_events_logged_without_invoice_mutation(): void
    {
        $this->markTestSkipped(self::NOT_IMPLEMENTED
            . 'Planned: payment.failed / order.paid are logged but must NOT mutate any invoice.');
    }

    /** BC-BIZ-13 — Source: Screen §Webhook Event Handling (persist raw response) */
    public function test_gatewayintegration_13_raw_webhook_response_persisted_to_gateway_response(): void
    {
        $this->markTestSkipped(self::NOT_IMPLEMENTED
            . 'Planned: raw Razorpay webhook body stored verbatim in gateway_response JSON column.');
    }

    /** BC-BIZ-14 — Source: Screen §Current State (multi-currency not configured) */
    public function test_gatewayintegration_14_multi_currency_support_planned(): void
    {
        $this->markTestSkipped(self::NOT_IMPLEMENTED . 'Planned: multi-currency support is not configured.');
    }

    // =====================================================================
    // Band 20-29 — Payment state machine (PLANNED — skipped)
    // =====================================================================

    /** BC-SM-20 — Source: Screen-SM (initiate -> order created) */
    public function test_gatewayintegration_20_initiate_creates_razorpay_order(): void
    {
        $this->markTestSkipped(self::NOT_IMPLEMENTED
            . 'Planned transition: initiate -> Razorpay order created, order_id returned to frontend.');
    }

    /** BC-SM-21 — Source: Screen-SM (order -> captured on verify) */
    public function test_gatewayintegration_21_verify_confirms_payment_signature_and_captures(): void
    {
        $this->markTestSkipped(self::NOT_IMPLEMENTED
            . 'Planned transition: order -> captured after Razorpay payment-signature verification.');
    }

    /** BC-SM-22 — Source: Screen-SM (captured -> reconciled) */
    public function test_gatewayintegration_22_captured_sets_payment_reconciled(): void
    {
        $this->markTestSkipped(self::NOT_IMPLEMENTED
            . 'Planned transition: captured -> payment_reconciled = 1 with audit-log entry.');
    }

    /** BC-SM-23 — Source: Screen-SM (illegal: capture without matching invoice) */
    public function test_gatewayintegration_23_captured_without_matching_invoice_is_rejected(): void
    {
        $this->markTestSkipped(self::NOT_IMPLEMENTED
            . 'Planned illegal transition: payment.captured with no matching invoice must not create a payment.');
    }

    // =====================================================================
    // Band 30-39 — Validation / signature (PLANNED — skipped)
    // =====================================================================

    /** BC-VAL-30 — Source: Screen §Webhook Security (HMAC verify) */
    public function test_gatewayintegration_30_webhook_hmac_signature_verified(): void
    {
        $this->markTestSkipped(self::NOT_IMPLEMENTED
            . 'Planned: HMAC verification using X-Razorpay-Signature header + razorpay.webhook_secret config.');
    }

    /** BC-VAL-31 — Source: Screen §Webhook Security (bad sig -> HTTP 400) */
    public function test_gatewayintegration_31_bad_signature_returns_http_400(): void
    {
        $this->markTestSkipped(self::NOT_IMPLEMENTED
            . 'Planned: invalid signature must return HTTP 400 (NOT 401/403 which leak auth info).');
    }

    /** BC-VAL-32 — Source: Screen §Verify Payment (verify signature) */
    public function test_gatewayintegration_32_verify_endpoint_validates_payment_signature(): void
    {
        $this->markTestSkipped(self::NOT_IMPLEMENTED
            . 'Planned: /payment/verify validates the Razorpay payment signature before updating records.');
    }

    /** BC-VAL-33 — Source: Screen §Current State (missing X-Razorpay-Signature) */
    public function test_gatewayintegration_33_missing_signature_header_rejected(): void
    {
        $this->markTestSkipped(self::NOT_IMPLEMENTED
            . 'Planned: webhook without X-Razorpay-Signature header must be rejected with HTTP 400.');
    }

    // =====================================================================
    // Band 40-49 — Integration / route absence (current reality)
    // =====================================================================

    /** TC-N01 / BC-INT-02 — Source: Screen §Future CRUD (initiate) */
    public function test_gatewayintegration_40_payment_initiate_route_not_registered(): void
    {
        $this->assertFalse($this->routeUriExists(self::PLANNED_INITIATE_URI));
    }

    /** TC-N02 / BC-INT-03 — Source: Screen §Future CRUD (verify) */
    public function test_gatewayintegration_41_payment_verify_route_not_registered(): void
    {
        $this->assertFalse($this->routeUriExists(self::PLANNED_VERIFY_URI));
    }

    /** TC-N03 / BC-INT-04 — Source: Screen §Webhook Receiver */
    public function test_gatewayintegration_42_webhook_route_not_registered(): void
    {
        $this->assertFalse($this->routeUriExists(self::PLANNED_WEBHOOK_URI));
    }

    /** TC-N04 / BC-INT-05 — Source: Modules/Billing/routes/api.php (empty group) */
    public function test_gatewayintegration_43_module_api_routes_has_no_gateway_routes(): void
    {
        $contents = strtolower(File::get(base_path(self::MODULE_API_ROUTES)));
        $this->assertStringNotContainsString('razorpay', $contents);
        $this->assertStringNotContainsString('webhook', $contents);
        $this->assertStringNotContainsString('payment/initiate', $contents);
    }

    /** TC-N06 / BC-BIZ-04 — Source: Modules/Billing (no webhook controller) */
    public function test_gatewayintegration_44_no_webhook_controller_exists(): void
    {
        $controllerDir = base_path('Modules/Billing/app/Http/Controllers');
        foreach (File::files($controllerDir) as $file) {
            $this->assertStringNotContainsStringIgnoringCase('webhook', $file->getFilename());
            $this->assertStringNotContainsStringIgnoringCase('razorpay', $file->getFilename());
        }
        $this->assertTrue(true);
    }

    /** TC-N08 / BC-INT-06 — Source: no razorpay usage in any Billing controller */
    public function test_gatewayintegration_45_no_razorpay_usage_in_controllers(): void
    {
        $controllerDir = base_path('Modules/Billing/app/Http/Controllers');
        foreach (File::files($controllerDir) as $file) {
            $this->assertStringNotContainsString('Razorpay', File::get($file->getPathname()),
                'Razorpay usage found in ' . $file->getFilename());
        }
        $this->assertTrue(true);
    }

    /** TC-N09 / BC-INT-07 — Source: module web.php has empty central group */
    public function test_gatewayintegration_46_module_web_routes_have_no_gateway_routes(): void
    {
        $contents = strtolower(File::get(base_path(self::MODULE_WEB_ROUTES)));
        $this->assertStringNotContainsString('razorpay', $contents);
        $this->assertStringNotContainsString('payment/initiate', $contents);
    }

    // =====================================================================
    // Band 50-59 — Permissions (PLANNED keys exist; flow pending)
    // =====================================================================

    /** BC-AUTH-50 — Source: Screen-PM-1 (initiate -> prime.invoicing-payment.create) */
    public function test_gatewayintegration_50_initiate_permission_key_exists_in_controller(): void
    {
        $ctrl = File::get(base_path('Modules/Billing/app/Http/Controllers/InvoicingPaymentController.php'));
        $this->assertStringContainsString('prime.invoicing-payment.create', $ctrl,
            'Planned initiate permission key not found on the existing payment controller.');
    }

    /** BC-AUTH-51 — Source: Screen-PM-2 (view webhook logs -> invoicing-audit-log.viewAny) */
    public function test_gatewayintegration_51_webhook_log_view_permission_flow_pending(): void
    {
        $this->markTestSkipped(self::NOT_IMPLEMENTED
            . 'Planned: viewing webhook logs uses prime.invoicing-audit-log.viewAny; no webhook-log surface exists yet.');
    }

    /** BC-AUTH-52 — Source: Screen §API Route Registration (non-webhook routes behind auth) */
    public function test_gatewayintegration_52_non_webhook_gateway_routes_behind_auth_planned(): void
    {
        $this->markTestSkipped(self::NOT_IMPLEMENTED
            . 'Planned: initiate/verify routes sit behind auth; only the webhook is public. No routes exist yet.');
    }

    // =====================================================================
    // Band 60-69 — UI/UX absence (current reality)
    // =====================================================================

    /** TC-N10 / BC-EDG-02 — Source: Billing views (no checkout.js / Razorpay UI) */
    public function test_gatewayintegration_60_no_razorpay_checkout_ui_in_views(): void
    {
        $hits = $this->grepViews(['checkout.razorpay.com', 'Razorpay(', 'razorpay_order_id', 'rzp_']);
        $this->assertSame([], $hits, 'Unexpected Razorpay checkout UI markers in Billing views: ' . implode(', ', $hits));
    }

    /** BC-EDG-03 — Source: Screen §Current State (no payment initiation UI/button) */
    public function test_gatewayintegration_61_no_pay_online_button_in_views(): void
    {
        $hits = $this->grepViews(['payment/initiate', 'pay-online', 'payOnline']);
        $this->assertSame([], $hits, 'Unexpected online-payment initiation UI markers: ' . implode(', ', $hits));
    }

    /** BC-EDG-04 — Source: Screen §Current State (tenant-facing payment page not built) */
    public function test_gatewayintegration_62_tenant_facing_payment_page_not_built(): void
    {
        $this->markTestSkipped(self::NOT_IMPLEMENTED . 'Planned: tenant-facing online payment page is not built.');
    }

    // =====================================================================
    // Band 70-79 — Edge cases
    // =====================================================================

    /** TC-P09 / BC-EDG-05 — sibling money columns unaffected by the JSON column */
    public function test_gatewayintegration_70_payment_money_columns_present(): void
    {
        $this->assertTrue(Schema::hasColumn(self::PAYMENTS_TABLE, 'amount_paid'));
        $this->assertTrue(Schema::hasColumn(self::PAYMENTS_TABLE, 'currency'));
        $this->assertTrue(Schema::hasColumn(self::PAYMENTS_TABLE, 'payment_reconciled'));
    }

    /** BC-EDG-06 — Source: Screen §Webhook Event Handling (idempotency) */
    public function test_gatewayintegration_71_duplicate_webhook_is_idempotent_planned(): void
    {
        $this->markTestSkipped(self::NOT_IMPLEMENTED
            . 'Planned: duplicate payment.captured deliveries must be idempotent (no double payment).');
    }

    /** TC-P10 / BC-EDG-07 — empty gateway_response reads back as null (not "[]") */
    public function test_gatewayintegration_72_null_gateway_response_reads_as_null(): void
    {
        $model = new InvoicingPayment();
        $this->assertNull($model->gateway_response ?? null);
    }

    // =====================================================================
    // Band 90-99 — Security pack (BC-S — PLANNED, skipped pending impl)
    // =====================================================================

    /** BC-S-90 / TC-S01 — Source: Screen §Webhook Security (public + HMAC) */
    public function test_gatewayintegration_90_webhook_public_but_hmac_protected(): void
    {
        $this->markTestSkipped(self::NOT_IMPLEMENTED
            . 'Security (planned): webhook is public (no auth) yet protected by HMAC signature verification.');
    }

    /** BC-S-91 / TC-S02 — Source: Screen §Webhook Security (no auth-info leak) */
    public function test_gatewayintegration_91_bad_signature_does_not_leak_auth_info(): void
    {
        $this->markTestSkipped(self::NOT_IMPLEMENTED
            . 'Security (planned): bad signature returns 400 (not 401/403) to avoid leaking auth state.');
    }

    /** BC-S-92 / TC-S03 — Source: Screen §Webhook Security (replay/forgery) */
    public function test_gatewayintegration_92_forged_or_replayed_webhook_rejected(): void
    {
        $this->markTestSkipped(self::NOT_IMPLEMENTED
            . 'Security (planned): forged/replayed webhook payloads must be rejected by signature + idempotency.');
    }

    /** BC-S-93 / TC-S04 — Source: Screen §Verify Payment (IDOR on invoice update) */
    public function test_gatewayintegration_93_verify_cannot_update_arbitrary_invoice(): void
    {
        $this->markTestSkipped(self::NOT_IMPLEMENTED
            . 'Security (planned): /payment/verify must bind the payment to its own invoice (no IDOR).');
    }

    // =====================================================================
    // Private helper library
    // =====================================================================

    private function routeUriExists(string $needle): bool
    {
        foreach (Route::getRoutes()->getRoutes() as $route) {
            if (str_contains($route->uri(), $needle)) {
                return true;
            }
        }
        return false;
    }

    private function columnMeta(string $table, string $column): ?object
    {
        try {
            return DB::selectOne(
                'SELECT DATA_TYPE, IS_NULLABLE, COLUMN_DEFAULT FROM information_schema.COLUMNS '
                . 'WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?',
                [$table, $column]
            );
        } catch (Throwable) {
            return null;
        }
    }

    /**
     * Return the subset of markers found anywhere under the Billing views tree.
     * Empty array => none of the markers are present.
     *
     * @param  array<int,string>  $markers
     * @return array<int,string>
     */
    private function grepViews(array $markers): array
    {
        $dir = base_path(self::MODULE_VIEWS);
        if (!File::isDirectory($dir)) {
            return [];
        }

        $found = [];
        foreach (File::allFiles($dir) as $file) {
            $contents = File::get($file->getPathname());
            foreach ($markers as $marker) {
                if (str_contains($contents, $marker) && !in_array($marker, $found, true)) {
                    $found[] = $marker;
                }
            }
        }
        return $found;
    }
}
