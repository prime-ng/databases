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
 * Payment Gateway Integration (Razorpay) — V1 foundation suite.
 *
 * FEATURE STATUS: PLANNED / NOT IMPLEMENTED (zero implementation).
 * Per the screen requirement `Billing_v1/gateway-integration.md`, the Razorpay
 * SDK is installed but nothing is wired: no API keys, no webhook endpoint, no
 * initiation/verify routes, no signature verification, no UI, no multi-currency.
 *
 * This V1 suite therefore asserts CURRENT REALITY only:
 *   (a) the `gateway_response` JSON/nullable column EXISTS on
 *       `bil_tenant_invoicing_payments` and is cast to array + fillable;
 *   (b) the planned routes are NOT registered (initiate/verify/webhook);
 *   (c) the Razorpay dependency is present in the APP root composer.json
 *       and ABSENT from the Billing module composer.json (documented gap);
 *   (d) no webhook controller / signature-verification code exists.
 *
 * DB scope: prime_db (central Prime-layer SaaS invoicing) — NO tenant init.
 * Style: browser Dusk central base chain (mirrors the committed
 * `Prime/Billing/InvoicingPayment` sibling). Most methods here are in-process
 * schema/route/composer truth checks and do not open a browser.
 *
 * Planned CRUD operations are captured as documented-gap markTestSkipped stubs
 * pending implementation (see the V2 suite for the full BC-S security pack).
 */
class bil_GatewayIntegrationV1_TestCas extends prm_BillingDuskTestCase_TestCas
{
    protected const SCREENSHOT_DIR = 'tests/Browser/Modules/Prime/Billing/GatewayIntegration/screenshots';
    protected const STATUS_REPORT_DIRECTORY = 'tests/Browser/Modules/Prime/Billing/GatewayIntegration/report';
    protected const STATUS_REPORT_PREFIX = 'billing_gateway_integration_report_';

    private const PAYMENTS_TABLE = 'bil_tenant_invoicing_payments';
    private const GATEWAY_COLUMN = 'gateway_response';

    private const ROOT_COMPOSER = 'composer.json';
    private const MODULE_COMPOSER = 'Modules/Billing/composer.json';
    private const MODULE_API_ROUTES = 'Modules/Billing/routes/api.php';
    private const MODULE_CONFIG = 'Modules/Billing/config/config.php';

    private const PLANNED_INITIATE_URI = 'billing/payment/initiate';
    private const PLANNED_VERIFY_URI = 'billing/payment/verify';
    private const PLANNED_WEBHOOK_URI = 'billing/webhook/razorpay';

    // ---------------------------------------------------------------------
    // Band 01-09 — Schema / model / dependency truth (current reality)
    // ---------------------------------------------------------------------

    /** TC-P01 / BC-DB-01 — Source: DDL-bil_tenant_invoicing_payments (line 73) */
    public function test_gatewayintegration_01_gateway_response_column_exists(): void
    {
        $this->assertTrue(
            Schema::hasColumn(self::PAYMENTS_TABLE, self::GATEWAY_COLUMN),
            'gateway_response column is missing from ' . self::PAYMENTS_TABLE
        );
    }

    /** TC-P02 / BC-DB-02 — Source: DDL-bil_tenant_invoicing_payments */
    public function test_gatewayintegration_02_gateway_response_is_json_and_nullable(): void
    {
        try {
            $meta = DB::selectOne(
                'SELECT DATA_TYPE, IS_NULLABLE, COLUMN_DEFAULT FROM information_schema.COLUMNS '
                . 'WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?',
                [self::PAYMENTS_TABLE, self::GATEWAY_COLUMN]
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('information_schema unavailable: ' . $e->getMessage());
            return;
        }

        $this->assertNotNull($meta, 'gateway_response column metadata not found.');
        $this->assertStringContainsString('json', strtolower((string) $meta->DATA_TYPE));
        $this->assertSame('YES', strtoupper((string) $meta->IS_NULLABLE), 'gateway_response must be nullable.');
    }

    /** TC-P03 / BC-BIZ-01 — Source: Model InvoicingPayment casts */
    public function test_gatewayintegration_03_model_casts_gateway_response_to_array(): void
    {
        $casts = (new InvoicingPayment())->getCasts();
        $this->assertArrayHasKey(self::GATEWAY_COLUMN, $casts);
        $this->assertSame('array', $casts[self::GATEWAY_COLUMN]);
    }

    /** TC-P04 / BC-BIZ-02 — Source: Model InvoicingPayment fillable */
    public function test_gatewayintegration_04_gateway_response_is_fillable(): void
    {
        $this->assertContains(self::GATEWAY_COLUMN, (new InvoicingPayment())->getFillable());
    }

    /** TC-P05 / BC-BIZ-03 — array cast round-trip (in-memory, no DB write) */
    public function test_gatewayintegration_05_gateway_response_array_cast_round_trip(): void
    {
        $payload = ['event' => 'payment.captured', 'payload' => ['payment' => ['entity' => ['id' => 'pay_TEST123']]]];
        $model = new InvoicingPayment();
        $model->gateway_response = $payload;

        $this->assertIsArray($model->gateway_response);
        $this->assertSame('payment.captured', $model->gateway_response['event']);
        $this->assertStringContainsString('pay_TEST123', (string) $model->getAttributes()[self::GATEWAY_COLUMN]);
    }

    /** TC-P06 / BC-INT-01 — Source: root composer.json (razorpay SDK installed) */
    public function test_gatewayintegration_06_razorpay_sdk_present_in_root_composer(): void
    {
        $path = base_path(self::ROOT_COMPOSER);
        $this->assertTrue(File::exists($path), 'Root composer.json not found at ' . $path);
        $this->assertStringContainsString('razorpay/razorpay', File::get($path));
    }

    /**
     * TC-N05 / DEV-BIL-020 (P3, doc-only) — Razorpay is declared in the APP ROOT
     * composer.json, NOT the Billing module composer.json. This documents the
     * current reality; if the SDK is later scoped into the module, update here.
     * Source: Modules/Billing/composer.json
     */
    public function test_gatewayintegration_07_razorpay_absent_from_module_composer(): void
    {
        $path = base_path(self::MODULE_COMPOSER);
        $this->assertTrue(File::exists($path), 'Billing module composer.json not found.');
        $this->assertStringNotContainsString(
            'razorpay',
            strtolower(File::get($path)),
            'Unexpected razorpay dependency now present in module composer.json — update this reality assertion.'
        );
    }

    // ---------------------------------------------------------------------
    // Band 40-49 — Route / endpoint absence (planned, not registered)
    // ---------------------------------------------------------------------

    /** TC-N01 / BC-INT-02 — Source: Screen §Future CRUD (POST /payment/initiate) */
    public function test_gatewayintegration_08_payment_initiate_route_not_registered(): void
    {
        $this->assertFalse(
            $this->routeUriExists(self::PLANNED_INITIATE_URI),
            'Planned initiate route unexpectedly registered — gateway integration may now be implemented.'
        );
    }

    /** TC-N02 / BC-INT-03 — Source: Screen §Future CRUD (POST /payment/verify) */
    public function test_gatewayintegration_09_payment_verify_route_not_registered(): void
    {
        $this->assertFalse($this->routeUriExists(self::PLANNED_VERIFY_URI));
    }

    /** TC-N03 / BC-INT-04 — Source: Screen §Webhook Receiver (POST /webhook/razorpay) */
    public function test_gatewayintegration_10_webhook_route_not_registered(): void
    {
        $this->assertFalse($this->routeUriExists(self::PLANNED_WEBHOOK_URI));
    }

    /** TC-N04 / BC-INT-05 — Source: Modules/Billing/routes/api.php (empty group) */
    public function test_gatewayintegration_11_module_api_routes_file_has_no_gateway_routes(): void
    {
        $path = base_path(self::MODULE_API_ROUTES);
        $this->assertTrue(File::exists($path), 'Module api.php not found.');
        $contents = strtolower(File::get($path));
        $this->assertStringNotContainsString('razorpay', $contents);
        $this->assertStringNotContainsString('webhook', $contents);
        $this->assertStringNotContainsString('payment/initiate', $contents);
    }

    /** TC-N06 / BC-BIZ-04 — Source: Modules/Billing (no webhook controller) */
    public function test_gatewayintegration_12_no_webhook_controller_exists(): void
    {
        $controllerDir = base_path('Modules/Billing/app/Http/Controllers');
        $this->assertTrue(File::isDirectory($controllerDir), 'Billing controllers dir missing.');

        foreach (File::files($controllerDir) as $file) {
            $this->assertStringNotContainsStringIgnoringCase(
                'webhook',
                $file->getFilename(),
                'A webhook controller now exists: ' . $file->getFilename()
            );
        }
        $this->assertFalse(File::exists($controllerDir . DIRECTORY_SEPARATOR . 'RazorpayWebhookController.php'));
    }

    /** TC-N07 / BC-VAL-01 — Source: Modules/Billing (no signature-verification code) */
    public function test_gatewayintegration_13_no_signature_verification_or_config(): void
    {
        // Module config carries only the module name — no razorpay keys yet.
        $config = File::get(base_path(self::MODULE_CONFIG));
        $this->assertStringNotContainsString('razorpay', strtolower($config));
        $this->assertStringNotContainsString('webhook_secret', strtolower($config));
    }

    // ---------------------------------------------------------------------
    // Band 50-59 — Planned permission keys (documented, pending)
    // ---------------------------------------------------------------------

    /**
     * TC-D01 (planned) — Screen §Permissions maps online payment initiation to
     * `prime.invoicing-payment.create` and webhook-log view to
     * `prime.invoicing-audit-log.viewAny`. These keys already exist in
     * InvoicingPaymentController; the gateway flow that would consume them is
     * not built. Skipped pending implementation.
     * Source: Screen-PM-1 / InvoicingPaymentController
     */
    public function test_gatewayintegration_14_planned_permission_flow_pending_implementation(): void
    {
        $this->markTestSkipped(
            'GatewayIntegration is not implemented. Planned permission keys '
            . 'prime.invoicing-payment.create and prime.invoicing-audit-log.viewAny exist but no '
            . 'gateway initiation/verify/webhook flow consumes them yet (REQ-BIL-014 = Not started / future).'
        );
    }

    // ---------------------------------------------------------------------
    // Private helper library
    // ---------------------------------------------------------------------

    /**
     * True if any registered route URI contains the given needle.
     * Deterministic in-process check (no live server / no HTTP round-trip).
     */
    private function routeUriExists(string $needle): bool
    {
        foreach (Route::getRoutes()->getRoutes() as $route) {
            if (str_contains($route->uri(), $needle)) {
                return true;
            }
        }
        return false;
    }
}
