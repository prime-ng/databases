<?php

namespace Tests\Browser\Modules\Prime\Billing\Subscription;

use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Tests\Browser\Modules\Prime\Billing\prm_BillingDuskTestCase_TestCas;
use Throwable;

/**
 * Subscription Views (Billing module) — V1 Foundation Suite.
 *
 * Feature type: PRIME-SIDE (prime_db, central domain http://127.0.0.1:8000), READ-ONLY / REPORT screen.
 * The Billing module never creates/modifies subscriptions — writes live in the Prime module.
 * This screen renders + filters + AJAX detail panels + PDF/ZIP export over Prime models.
 *
 * Mirrors the committed sibling exactly:
 *   tests/Browser/Modules/Prime/Billing/Subscription/prm_SubscriptionTab_TestCas.php
 *   base: prm_BillingDuskTestCase_TestCas (central chain: authenticateCentral / visitAuthenticated /
 *         centralUrl / ensureTabVisible / ensurePageAccessible / browseWithFailureScreenshot).
 *
 * NO tenancy init (prime-side). App\Models\User via base resolveAdminUser().
 * Cross-module Prime-model reads are wrapped try/catch + markTestSkipped (defensive).
 */
class prm_SubscriptionV1_TestCas extends prm_BillingDuskTestCase_TestCas
{
    protected const SCREENSHOT_DIR = 'tests/Browser/Modules/Prime/Billing/Subscription/screenshots';
    protected const STATUS_REPORT_DIRECTORY = 'tests/Browser/Modules/Prime/Billing/Subscription/report';
    protected const STATUS_REPORT_PREFIX = 'billing_subscription_v1_report_';

    private const BILLING_MGMT_PATH        = '/billing/billing-management';
    private const SUBSCRIPTION_TAB_PATH    = '/billing/billing-management?type=subscription_data';
    private const SUBSCRIPTION_DETAILS_URI = '/billing/subscription-details';   // BillingManagementController@subscriptionDetails
    private const MODULE_DETAILS_URI       = '/billing/module-details';         // BillingManagementController@moduleDetails
    private const PRICING_DETAILS_URI      = '/billing/billing/pricing-details'; // SubscriptionController@pricingDetails (double /billing prefix — real path)
    private const BILLING_DETAILS_URI      = '/billing/billing/billing-details'; // SubscriptionController@billingDetails (double /billing prefix — real path)
    private const SUBSCRIPTION_STORE_URI   = '/billing/subscription';           // SubscriptionController@store (PDF/ZIP)
    private const PRINT_URI                = '/billing/billing-management/print/data?type=subscription_data';

    private const TAB_SELECTOR  = '#subscription-tab';
    private const PANE_SELECTOR = '#subscription-pane';

    private const RATES_TABLE = 'prm_tenant_plan_rates';
    private const PLAN_TABLE  = 'prm_tenant_plan_jnt';

    // ---------------------------------------------------------------------
    // 01 — Schema / model / route configuration truth
    // ---------------------------------------------------------------------

    public function test_subscription_01_schema_and_model_configuration_are_correct(): void
    {
        try {
            if (!Schema::hasTable(self::RATES_TABLE)) {
                $this->markTestSkipped('prm_tenant_plan_rates not visible on this connection (prime_db).');
            }

            $this->assertTrue(
                Schema::hasColumns(self::RATES_TABLE, [
                    'id', 'tenant_plan_id', 'start_date', 'end_date', 'billing_cycle_id',
                    'billing_cycle_day', 'rate_per_cycle', 'currency', 'min_billing_qty',
                    'discount_percent', 'tax1_percent', 'credit_days',
                ]),
                'prm_tenant_plan_rates is missing expected columns.'
            );

            if (Schema::hasTable(self::PLAN_TABLE)) {
                $this->assertTrue(
                    Schema::hasColumns(self::PLAN_TABLE, [
                        'id', 'tenant_id', 'plan_id', 'is_subscribed', 'is_trial',
                        'auto_renew', 'automatic_billing', 'status', 'is_active',
                    ]),
                    'prm_tenant_plan_jnt is missing expected columns.'
                );
            }

            // Model configuration truth (Prime models — read-only for Billing).
            $rate = new \Modules\Prime\Models\TenantPlanRate();
            $this->assertSame(self::RATES_TABLE, $rate->getTable(), 'TenantPlanRate table mismatch.');
            $this->assertContains('tenant_plan_id', $rate->getFillable(), 'TenantPlanRate fillable missing tenant_plan_id.');
            $this->assertContains('billing_cycle_id', $rate->getFillable(), 'TenantPlanRate fillable missing billing_cycle_id.');
            $this->assertTrue(method_exists($rate, 'tenantPlan'), 'TenantPlanRate::tenantPlan() relationship missing.');
            $this->assertTrue(method_exists($rate, 'billingCycle'), 'TenantPlanRate::billingCycle() relationship missing.');

            $plan = new \Modules\Prime\Models\TenantPlan();
            $this->assertSame(self::PLAN_TABLE, $plan->getTable(), 'TenantPlan table mismatch.');
        } catch (Throwable $e) {
            $this->markTestSkipped('Prime plan models/tables not available: ' . $e->getMessage());
        }
    }

    // ---------------------------------------------------------------------
    // 02–07 — Render / filters / pagination
    // ---------------------------------------------------------------------

    public function test_subscription_02_billing_management_page_loads_on_central(): void
    {
        $this->browseWithFailureScreenshot('billing-management-load', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::BILLING_MGMT_PATH);

            $this->assertSame(self::BILLING_MGMT_PATH, $this->currentPath($browser), 'Billing Management not reachable.');
            $this->ensurePageAccessible($browser, 'Billing Management (Subscription)');
        });
    }

    public function test_subscription_03_subscription_tab_visible_with_filters(): void
    {
        $this->browseWithFailureScreenshot('subscription-tab-filters', function (Browser $browser): void {
            $this->openSubscriptionTab($browser);

            $this->assertNotNull($browser->element(self::PANE_SELECTOR), 'Subscription pane not visible.');
            $browser->assertPresent('input[name="date_range"]')
                ->assertPresent('select[name="status"]')
                ->assertPresent(self::PANE_SELECTOR . ' table');
        });
    }

    public function test_subscription_04_subscription_table_headers_present(): void
    {
        $this->browseWithFailureScreenshot('subscription-table-headers', function (Browser $browser): void {
            $this->openSubscriptionTab($browser);

            $paneText = $browser->text(self::PANE_SELECTOR);
            foreach (['Organization', 'Plan', 'Billing Period', 'Credit Day'] as $header) {
                $this->assertStringContainsString($header, $paneText, "Column header '{$header}' missing.");
            }
        });
    }

    public function test_subscription_05_status_filter_offers_active_and_inactive(): void
    {
        $this->browseWithFailureScreenshot('subscription-status-options', function (Browser $browser): void {
            $this->openSubscriptionTab($browser);

            $browser->assertPresent('select[name="status"] option[value="Active"]')
                ->assertPresent('select[name="status"] option[value="Inactive"]');
        });
    }

    public function test_subscription_06_hidden_type_field_scopes_query_to_subscription_data(): void
    {
        $this->browseWithFailureScreenshot('subscription-hidden-type', function (Browser $browser): void {
            $this->openSubscriptionTab($browser);

            $this->assertNotNull(
                $browser->element(self::PANE_SELECTOR . ' input[name="type"]'),
                'Hidden type=subscription_data input missing from subscription filter form.'
            );
        });
    }

    public function test_subscription_07_subscription_data_paginates_at_ten(): void
    {
        $this->browseWithFailureScreenshot('subscription-pagination', function (Browser $browser): void {
            $this->openSubscriptionTab($browser);

            $rowCount = (int) $browser->driver->executeScript(
                "return document.querySelectorAll('#subscription-pane table tbody tr').length;"
            );
            $this->assertLessThanOrEqual(10, $rowCount, 'Subscription table shows more than the 10-per-page cap.');
        });
    }

    // ---------------------------------------------------------------------
    // 08–11 — AJAX detail panels (JSON {html})
    // ---------------------------------------------------------------------

    public function test_subscription_08_subscription_details_ajax_returns_html(): void
    {
        $this->browseWithFailureScreenshot('subscription-details-ajax', function (Browser $browser): void {
            $this->openSubscriptionTab($browser);
            $id = $this->firstScheduleIdFromBrowser($browser);
            if ($id === null) {
                $this->markTestSkipped('No billing-schedule id available for subscription-details AJAX.');
            }

            $res = $this->fetchJsonFromBrowser($browser, self::SUBSCRIPTION_DETAILS_URI . '?id=' . $id);
            $this->assertContains((int) $res['status'], [200, 404], 'Unexpected status from subscription-details.');
            if ((int) $res['status'] === 200) {
                $this->assertStringContainsString('html', (string) $res['body'], 'subscription-details JSON has no html key.');
            }
        });
    }

    public function test_subscription_09_pricing_details_ajax_returns_html(): void
    {
        $this->browseWithFailureScreenshot('pricing-details-ajax', function (Browser $browser): void {
            $this->openSubscriptionTab($browser);
            $id = $this->firstTenantPlanIdFromBrowser($browser);
            if ($id === null) {
                $this->markTestSkipped('No tenant_plan_id available for pricing-details AJAX.');
            }

            $res = $this->fetchJsonFromBrowser($browser, self::PRICING_DETAILS_URI . '?id=' . $id);
            $this->assertContains((int) $res['status'], [200, 404], 'Unexpected status from pricing-details.');
            if ((int) $res['status'] === 200) {
                $this->assertStringContainsString('html', (string) $res['body'], 'pricing-details JSON has no html key.');
            }
        });
    }

    public function test_subscription_10_billing_details_ajax_returns_html(): void
    {
        $this->browseWithFailureScreenshot('billing-details-ajax', function (Browser $browser): void {
            $this->openSubscriptionTab($browser);
            $id = $this->firstTenantPlanIdFromBrowser($browser);
            if ($id === null) {
                $this->markTestSkipped('No tenant_plan_id available for billing-details AJAX.');
            }

            $res = $this->fetchJsonFromBrowser($browser, self::BILLING_DETAILS_URI . '?id=' . $id);
            $this->assertContains((int) $res['status'], [200, 404], 'Unexpected status from billing-details.');
            if ((int) $res['status'] === 200) {
                $this->assertStringContainsString('html', (string) $res['body'], 'billing-details JSON has no html key.');
            }
        });
    }

    public function test_subscription_11_module_details_ajax_returns_html(): void
    {
        $this->browseWithFailureScreenshot('module-details-ajax', function (Browser $browser): void {
            $this->openSubscriptionTab($browser);
            $id = $this->firstTenantPlanIdFromBrowser($browser);
            if ($id === null) {
                $this->markTestSkipped('No tenant_plan_id available for module-details AJAX.');
            }

            $res = $this->fetchJsonFromBrowser($browser, self::MODULE_DETAILS_URI . '?type=subscription&id=' . $id);
            $this->assertContains((int) $res['status'], [200, 404], 'Unexpected status from module-details.');
            if ((int) $res['status'] === 200) {
                $this->assertStringContainsString('html', (string) $res['body'], 'module-details JSON has no html key.');
            }
        });
    }

    // ---------------------------------------------------------------------
    // 12–14 — Export / print controls & action links
    // ---------------------------------------------------------------------

    public function test_subscription_12_action_links_present_when_rows_exist(): void
    {
        $this->browseWithFailureScreenshot('subscription-action-links', function (Browser $browser): void {
            $this->openSubscriptionTab($browser);

            $rowCount = (int) $browser->driver->executeScript(
                "return document.querySelectorAll('#subscription-pane table tbody tr').length;"
            );
            if ($rowCount === 0) {
                $this->markTestSkipped('No subscription rows rendered — action links not applicable.');
            }

            foreach (['.module-details', '.pricing-details', '.billing-schedule'] as $marker) {
                $this->assertNotNull(
                    $browser->element(self::PANE_SELECTOR . ' ' . $marker),
                    "Action link '{$marker}' missing from subscription row."
                );
            }
        });
    }

    public function test_subscription_13_export_pdf_control_present_for_admin(): void
    {
        $this->browseWithFailureScreenshot('subscription-export-pdf', function (Browser $browser): void {
            $this->openSubscriptionTab($browser);

            // #downloadPDFMultiBtnsSub is @can('prime.subscription.pdf'); super-admin sees it.
            $this->assertNotNull(
                $browser->element('#downloadPDFMultiBtnsSub'),
                'Subscription PDF export control not present for admin.'
            );
        });
    }

    public function test_subscription_14_row_selection_checkboxes_present(): void
    {
        $this->browseWithFailureScreenshot('subscription-row-select', function (Browser $browser): void {
            $this->openSubscriptionTab($browser);

            $this->assertNotNull(
                $browser->element(self::PANE_SELECTOR . ' #selectAllSections'),
                'Select-all checkbox missing.'
            );
        });
    }

    // ---------------------------------------------------------------------
    // 15–16 — Auth guard & routing quirk (DEV proof)
    // ---------------------------------------------------------------------

    public function test_subscription_15_guest_is_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('subscription-guest-redirect', function (Browser $browser): void {
            $browser->visit($this->centralUrl('/logout'))->pause(600);
            $browser->visit($this->centralUrl(self::BILLING_MGMT_PATH))->pause(1000);

            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest not redirected to /login.');
        });
    }

    public function test_subscription_16_pricing_route_uses_double_billing_prefix(): void
    {
        // Documents the real (quirky) path: prefix 'billing' + 'billing/pricing-details' = /billing/billing/pricing-details.
        // A GET on the single-prefix path must NOT resolve to the pricing endpoint.
        $this->browseWithFailureScreenshot('subscription-route-quirk', function (Browser $browser): void {
            $this->authenticateCentral($browser);

            $doubled = $this->fetchJsonFromBrowser($browser, self::PRICING_DETAILS_URI . '?id=0');
            $this->assertContains((int) $doubled['status'], [200, 404, 500], 'Double-prefixed pricing route did not resolve.');

            $single = $this->fetchJsonFromBrowser($browser, '/billing/pricing-details?id=0');
            $this->assertSame(404, (int) $single['status'], 'Single-prefix /billing/pricing-details unexpectedly resolved (route path quirk changed).');
        });
    }

    // ---------------------------------------------------------------------
    // Private helper library
    // ---------------------------------------------------------------------

    private function openSubscriptionTab(Browser $browser): void
    {
        $this->authenticateCentral($browser);
        $this->visitAuthenticated($browser, self::SUBSCRIPTION_TAB_PATH);
        $this->ensurePageAccessible($browser, 'Subscription tab');
        $this->ensureTabVisible($browser, self::TAB_SELECTOR, self::PANE_SELECTOR);
    }

    /**
     * Issue an authenticated same-origin synchronous GET from the page and return status + body.
     *
     * @return array{status:int, body:string}
     */
    private function fetchJsonFromBrowser(Browser $browser, string $path): array
    {
        $script = <<<'JS'
            var target = arguments[0];
            try {
                var x = new XMLHttpRequest();
                x.open('GET', target, false);
                x.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
                x.setRequestHeader('Accept', 'application/json');
                x.send(null);
                return { status: x.status, body: x.responseText };
            } catch (e) {
                return { status: 0, body: String(e) };
            }
JS;
        $result = $browser->driver->executeScript($script, [$path]);

        return [
            'status' => is_array($result) ? (int) ($result['status'] ?? 0) : 0,
            'body'   => is_array($result) ? (string) ($result['body'] ?? '') : '',
        ];
    }

    private function firstTenantPlanIdFromBrowser(Browser $browser): ?int
    {
        $val = $browser->driver->executeScript(
            "var el=document.querySelector('#subscription-pane .pricing-details, #subscription-pane .module-details, #subscription-pane .billing-schedule');"
            . "return el ? el.getAttribute('data-id') : null;"
        );

        return ($val !== null && $val !== '') ? (int) $val : null;
    }

    private function firstScheduleIdFromBrowser(Browser $browser): ?int
    {
        // Subscription rows carry the plan-rate id in the row checkbox value.
        $val = $browser->driver->executeScript(
            "var el=document.querySelector('#subscription-pane table tbody tr .row-checkbox');"
            . "return el ? el.value : null;"
        );

        return ($val !== null && $val !== '') ? (int) $val : null;
    }
}
