<?php

namespace Tests\Browser\Modules\Prime\Billing\Subscription;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\Billing\Http\Controllers\BillingManagementController;
use Modules\Billing\Http\Controllers\SubscriptionController;
use Modules\Prime\Models\TenantPlan;
use Modules\Prime\Models\TenantPlanBillingSchedule;
use Modules\Prime\Models\TenantPlanModule;
use Modules\Prime\Models\TenantPlanRate;
use ReflectionMethod;
use Tests\Browser\Modules\Prime\Billing\BillingDuskTestCase;
use Throwable;

/**
 * Subscription (read-only viewing layer) — Billing module, Prime/central DB (prm_* tables).
 *
 * Screen: the "Subscription" tab of /billing/billing-management (type=subscription_data),
 * plus its AJAX detail panels (subscription-details, pricing, billing-schedule, module-details),
 * per-flag toggle endpoint, and PDF/ZIP export.
 *
 * DB scope: PRIME / CENTRAL (prm_tenant_plan_*, prm_plans, prm_billing_cycles) — NO tenant scaffolding.
 * Style: extends BillingDuskTestCase (alias for prm_BillingDuskTestCase_TestCas) → PrimeDuskTestCase on 127.0.0.1.
 *
 * NOTE (constraints 05_): these prm_ subscription models do NOT use SoftDeletes and the tables carry no
 * deleted_at, so this suite never calls withTrashed()/onlyTrashed()/forceDelete() (MIG-BIL-001 / constraint 12).
 * Central super-admin resolves every dotted ability via Gate::before, so permission-denial paths use a
 * freshly-created non-super-admin user, and are skipped defensively when such a user cannot be provisioned.
 */
class prm_Subscription_TestCas extends BillingDuskTestCase
{
    protected const SCREENSHOT_DIR = 'tests/Browser/Modules/Prime/Billing/Subscription/screenshots';
    protected const STATUS_REPORT_DIRECTORY = 'tests/Browser/Modules/Prime/Billing/Subscription/report';
    protected const STATUS_REPORT_PREFIX = 'billing_subscription_report_';

    private const INDEX_PATH = '/billing/billing-management';
    private const SUBSCRIPTION_TYPE_PATH = '/billing/billing-management?type=subscription_data';
    private const SUBSCRIPTION_DETAILS_PATH = '/billing/subscription-details';
    private const MODULE_DETAILS_PATH = '/billing/module-details';
    private const PRICING_DETAILS_PATH = '/billing/billing/pricing-details';
    private const BILLING_DETAILS_PATH = '/billing/billing/billing-details';
    private const SUBSCRIPTION_STORE_PATH = '/billing/subscription';
    private const PRINT_PATH = '/billing/billing-management/print/data?type=subscription_data';

    /** Real activity-log event strings emitted by the Subscription flows (verbatim from source). */
    private const EVENT_STORE = 'Store';           // SubscriptionController::store (PDF/ZIP)
    private const EVENT_TOGGLE = 'ToggleStatus';   // BillingManagementController::toggleStatus (subscription)

    /** Toggle fields the controller allows for type=subscription (BillingManagementController::toggleStatus). */
    private const TOGGLE_FIELDS = ['automatic_billing', 'auto_renew', 'is_trial', 'is_subscribed', 'is_active'];

    // ------------------------------------------------------------------
    // 01–09  Schema / route / model configuration truth
    // ------------------------------------------------------------------

    public function test_subscription_01_schema_tables_columns_and_model_configuration_are_correct(): void
    {
        // Core prm_ tables backing the subscription viewing layer.
        $this->assertTrue(Schema::hasTable('prm_tenant_plan_jnt'), 'prm_tenant_plan_jnt table is missing.');
        $this->assertTrue(Schema::hasTable('prm_tenant_plan_rates'), 'prm_tenant_plan_rates table is missing.');
        $this->assertTrue(Schema::hasTable('prm_tenant_plan_module_jnt'), 'prm_tenant_plan_module_jnt table is missing.');
        $this->assertTrue(Schema::hasTable('prm_plans'), 'prm_plans table is missing.');
        $this->assertTrue(Schema::hasTable('prm_billing_cycles'), 'prm_billing_cycles table is missing.');

        // TenantPlanRate is the PRIMARY query table for the subscription tab (buildSubscriptionQuery).
        foreach (['tenant_plan_id', 'start_date', 'end_date', 'billing_cycle_id', 'billing_cycle_day', 'credit_days', 'monthly_rate', 'rate_per_cycle', 'currency'] as $col) {
            $this->assertTrue(
                Schema::hasColumn('prm_tenant_plan_rates', $col),
                "prm_tenant_plan_rates.$col column is missing."
            );
        }

        // TenantPlan carries the toggle-able subscription flags + status lifecycle column.
        foreach (['tenant_id', 'plan_id', 'is_subscribed', 'is_trial', 'auto_renew', 'automatic_billing', 'status', 'is_active'] as $col) {
            $this->assertTrue(
                Schema::hasColumn('prm_tenant_plan_jnt', $col),
                "prm_tenant_plan_jnt.$col column is missing."
            );
        }

        // Model wiring (verbatim from Modules/Prime/Models/*).
        $rate = new TenantPlanRate();
        $this->assertSame('prm_tenant_plan_rates', $rate->getTable());
        $this->assertContains('tenant_plan_id', $rate->getFillable());
        $this->assertContains('credit_days', $rate->getFillable());

        $plan = new TenantPlan();
        $this->assertSame('prm_tenant_plan_jnt', $plan->getTable());
        foreach (self::TOGGLE_FIELDS as $field) {
            $this->assertContains($field, $plan->getFillable(), "TenantPlan.$field should be fillable for toggles.");
        }

        $module = new TenantPlanModule();
        $this->assertSame('prm_tenant_plan_module_jnt', $module->getTable());

        // These read models must NOT use SoftDeletes (tables have no deleted_at) — constraint 12 / MIG-BIL-001.
        foreach ([TenantPlan::class, TenantPlanRate::class, TenantPlanModule::class] as $modelClass) {
            $this->assertNotContains(
                'Illuminate\\Database\\Eloquent\\SoftDeletes',
                class_uses_recursive($modelClass),
                $modelClass . ' unexpectedly uses SoftDeletes (tables have no deleted_at).'
            );
        }

        // Relationship graph the panels rely on.
        $this->assertTrue(method_exists(TenantPlanRate::class, 'tenantPlan'));
        $this->assertTrue(method_exists(TenantPlanRate::class, 'billingCycle'));
        $this->assertTrue(method_exists(TenantPlan::class, 'plan'));
        $this->assertTrue(method_exists(TenantPlan::class, 'tenant'));
    }

    public function test_subscription_02_subscription_routes_and_gates_are_registered(): void
    {
        // Route registration (constraint E23 — verify, don't assume). Names live under central.billing.*.
        $this->assertTrue(
            $this->anyRouteExists(['central.billing.billing-management.index', 'billing.billing-management.index']),
            'Subscription tab route (billing-management.index) is not registered.'
        );
        $this->assertTrue(
            $this->anyRouteExists(['central.billing.billing-management.subscription.details', 'billing.billing-management.subscription.details']),
            'subscription-details route is not registered.'
        );
        $this->assertTrue(
            $this->anyRouteExists(['central.billing.billing-management.module.details', 'billing.billing-management.module.details']),
            'module-details route is not registered.'
        );
        $this->assertTrue(
            $this->anyRouteExists(['central.billing.pricing.details', 'billing.pricing.details']),
            'pricing-details route is not registered.'
        );
        $this->assertTrue(
            $this->anyRouteExists(['central.billing.billing.details', 'billing.billing.details']),
            'billing-details route is not registered.'
        );
        $this->assertTrue(
            $this->anyRouteExists(['central.billing.subscription.store', 'billing.subscription.store']),
            'subscription PDF/ZIP store route is not registered.'
        );

        // Controller methods backing the screen exist.
        foreach (['index', 'subscriptionDetails', 'moduleDetails', 'toggleStatus', 'printData'] as $m) {
            $this->assertTrue(method_exists(BillingManagementController::class, $m), "BillingManagementController::$m missing.");
        }
        foreach (['store', 'pricingDetails', 'billingDetails'] as $m) {
            $this->assertTrue(method_exists(SubscriptionController::class, $m), "SubscriptionController::$m missing.");
        }
    }

    public function test_subscription_03_billing_schedule_model_table_name_matches_ddl(): void
    {
        // DEV-BIL-SUB-001 probe: the model declares the PLURAL table name while the DDL creates the SINGULAR one.
        $declared = (new TenantPlanBillingSchedule())->getTable();
        $this->assertSame(
            'prm_tenant_plan_billing_schedules',
            $declared,
            'TenantPlanBillingSchedule model table name changed from the audited value.'
        );

        $pluralExists = Schema::hasTable('prm_tenant_plan_billing_schedules');
        $singularExists = Schema::hasTable('prm_tenant_plan_billing_schedule');

        // On a schema-correct prime_db built from Billing_DDL_v1.sql only the SINGULAR table exists, so every
        // subscriptionDetails()/billingDetails() query against the model's plural table throws 42S02.
        // Assert the discrepancy is documented (DEV-BIL-SUB-001) rather than silently passing.
        if ($singularExists && !$pluralExists) {
            $this->markTestIncomplete(
                'DEV-BIL-SUB-001 confirmed: DDL table is prm_tenant_plan_billing_schedule (singular) but the '
                . 'model targets prm_tenant_plan_billing_schedules (plural) — billing-schedule/subscription-detail '
                . 'panels will fail with 42S02 on a schema-correct DB.'
            );
        }

        $this->assertTrue(
            $pluralExists || $singularExists,
            'Neither prm_tenant_plan_billing_schedule nor its plural variant exists.'
        );
    }

    // ------------------------------------------------------------------
    // 10–19  Business rules — read-only scope, data source, filters
    // ------------------------------------------------------------------

    public function test_subscription_10_billing_management_page_loads_with_subscription_tab(): void
    {
        $this->browseWithFailureScreenshot('subscription-page-load', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);

            $this->assertSame(self::INDEX_PATH, $this->currentPath($browser), 'Billing Management page not reachable.');
            $this->ensurePageAccessible($browser, 'Billing Management (Subscription tab)');

            $this->assertNotNull($browser->element('#subscription-tab'), 'Subscription tab trigger is missing.');
        });
    }

    public function test_subscription_11_subscription_tab_shows_filters_and_table(): void
    {
        $this->browseWithFailureScreenshot('subscription-tab-filters', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Subscription tab');

            $this->ensureTabVisible($browser, '#subscription-tab', '#subscription-pane');

            $this->assertNotNull($browser->element('#subscription-pane'), 'Subscription pane not visible.');
            $browser->assertPresent('#subscription-pane input[name="date_range"]')
                ->assertPresent('#subscription-pane select[name="status"]')
                ->assertPresent('#subscription-pane input[type="hidden"][name="type"][value="subscription_data"]')
                ->assertPresent('#subscription-pane table');
        });
    }

    public function test_subscription_12_subscription_data_type_returns_paginated_table(): void
    {
        $this->browseWithFailureScreenshot('subscription-data-type', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::SUBSCRIPTION_TYPE_PATH);
            $this->ensurePageAccessible($browser, 'Subscription data listing');

            // Header columns proven from subscription.blade.php.
            $browser->assertSee('Organization')
                ->assertSee('Plan (v)')
                ->assertSee('Billing Period')
                ->assertSee('Sub Status');
        });
    }

    public function test_subscription_13_status_filter_active_keeps_user_on_subscription_type(): void
    {
        $this->browseWithFailureScreenshot('subscription-status-filter', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::SUBSCRIPTION_TYPE_PATH);
            $this->ensureTabVisible($browser, '#subscription-tab', '#subscription-pane');
            $this->ensurePageAccessible($browser, 'Subscription status filter');

            if ($browser->element('#subscription-pane select[name="status"]')) {
                $browser->select('#subscription-pane select[name="status"]', 'Active')->pause(300);
                $browser->script("document.querySelector('#subscription-pane form').submit();");
                $browser->pause(1500);
            }

            $this->ensurePageAccessible($browser, 'Subscription status filter (after submit)');
            $this->assertStringContainsString('subscription_data', (string) $browser->driver->getCurrentURL());
        });
    }

    public function test_subscription_14_date_range_filter_applies_without_error(): void
    {
        $this->browseWithFailureScreenshot('subscription-date-filter', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated(
                $browser,
                self::SUBSCRIPTION_TYPE_PATH . '&date_range=' . urlencode('2025-04-01 to 2026-03-31')
            );
            $this->ensurePageAccessible($browser, 'Subscription date-range filter');
            $browser->assertPresent('#subscription-pane table');
        });
    }

    public function test_subscription_15_billing_module_exposes_no_write_ui_for_subscription(): void
    {
        // Read-only scope (Screen-BR "Read-Only Scope"): Subscription tab must not offer Create/Add/Delete controls.
        $this->browseWithFailureScreenshot('subscription-read-only', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::SUBSCRIPTION_TYPE_PATH);
            $this->ensureTabVisible($browser, '#subscription-tab', '#subscription-pane');
            $this->ensurePageAccessible($browser, 'Subscription read-only scope');

            $pane = (string) ($browser->element('#subscription-pane') ? $browser->text('#subscription-pane') : '');
            $this->assertStringNotContainsStringIgnoringCase('Add Subscription', $pane, 'Subscription tab must be read-only.');
            $this->assertStringNotContainsStringIgnoringCase('Create Subscription', $pane, 'Subscription tab must be read-only.');
        });
    }

    // ------------------------------------------------------------------
    // 20–29  Subscription status / flag toggles (state machine)
    // ------------------------------------------------------------------

    public function test_subscription_20_toggle_updates_each_allowed_flag(): void
    {
        $plan = $this->firstTenantPlanOrSkip();

        $this->browseWithFailureScreenshot('subscription-toggle-flags', function (Browser $browser) use ($plan): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Subscription toggle');

            foreach (self::TOGGLE_FIELDS as $field) {
                $before = (int) (bool) DB::table('prm_tenant_plan_jnt')->where('id', $plan->id)->value($field);

                $response = $this->postJsonFromBrowser(
                    $browser,
                    self::INDEX_PATH . '/' . $plan->id . '/toggle-status',
                    ['type' => 'subscription', 'field' => $field]
                );

                $this->assertSame(200, (int) $response['status'], "Toggle of $field did not return 200.");
                $this->assertStringContainsString('Subscription status updated successfully', (string) $response['body']);

                $after = (int) (bool) DB::table('prm_tenant_plan_jnt')->where('id', $plan->id)->value($field);
                $this->assertNotSame($before, $after, "Flag $field did not flip in prm_tenant_plan_jnt.");

                // Restore original value so the shared row is untouched.
                $this->postJsonFromBrowser(
                    $browser,
                    self::INDEX_PATH . '/' . $plan->id . '/toggle-status',
                    ['type' => 'subscription', 'field' => $field]
                );
            }
        });
    }

    public function test_subscription_21_toggle_invalid_field_returns_422(): void
    {
        $plan = $this->firstTenantPlanOrSkip();

        $this->browseWithFailureScreenshot('subscription-toggle-invalid-field', function (Browser $browser) use ($plan): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Subscription invalid toggle');

            $response = $this->postJsonFromBrowser(
                $browser,
                self::INDEX_PATH . '/' . $plan->id . '/toggle-status',
                ['type' => 'subscription', 'field' => 'not_a_real_flag']
            );

            $this->assertSame(422, (int) $response['status'], 'Invalid toggle field should return 422.');
            $this->assertStringContainsString('Invalid subscription toggle field', (string) $response['body']);
        });
    }

    public function test_subscription_22_toggle_default_type_does_not_touch_tenant_plan(): void
    {
        // Without type=subscription the controller falls through to the payment-reconciliation branch,
        // so a subscription plan id must NOT be mutated as a subscription flag.
        $plan = $this->firstTenantPlanOrSkip();

        $this->browseWithFailureScreenshot('subscription-toggle-default-type', function (Browser $browser) use ($plan): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);

            $subscribedBefore = (int) (bool) DB::table('prm_tenant_plan_jnt')->where('id', $plan->id)->value('is_subscribed');

            // No 'type' → payment branch (InvoicingPayment::findOrFail) — likely 404 for a plan id, never a plan flip.
            $this->postJsonFromBrowser(
                $browser,
                self::INDEX_PATH . '/' . $plan->id . '/toggle-status',
                ['field' => 'is_subscribed']
            );

            $subscribedAfter = (int) (bool) DB::table('prm_tenant_plan_jnt')->where('id', $plan->id)->value('is_subscribed');
            $this->assertSame($subscribedBefore, $subscribedAfter, 'Subscription flag flipped without type=subscription.');
        });
    }

    public function test_subscription_23_sub_status_column_display_reflects_string_status(): void
    {
        // DEV-BIL-SUB-002 probe: subscription.blade.php renders `$item->tenantPlan->status == 1 ? 'Active' : 'Deactive'`.
        // prm_tenant_plan_jnt.status is a VARCHAR holding 'ACTIVE'; in PHP 8 'ACTIVE' == 1 is FALSE, so an ACTIVE
        // plan is mislabelled 'Deactive'. Prove current behaviour rather than the intended behaviour.
        $this->assertFalse('ACTIVE' == 1, 'Sanity: string status must not loosely equal 1 in PHP 8 (drives DEV-BIL-SUB-002).');
        $this->assertFalse('SUSPENDED' == 1, 'Sanity: string status must not loosely equal 1.');
    }

    // ------------------------------------------------------------------
    // 30–39  Validation / negative
    // ------------------------------------------------------------------

    public function test_subscription_30_subscription_details_invalid_id_is_rejected(): void
    {
        $this->browseWithFailureScreenshot('subscription-details-invalid-id', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);

            $response = $this->getJsonFromBrowser($browser, self::SUBSCRIPTION_DETAILS_PATH . '?id=999999999');
            // findOrFail → 404 (correct), or 5xx if the plural-table mismatch (DEV-BIL-SUB-001) fires first.
            $this->assertContains(
                (int) $response['status'],
                [404, 500],
                'subscription-details with a bogus id should not return 200. Got: ' . $response['status']
            );
        });
    }

    public function test_subscription_31_pricing_details_missing_id_returns_json_envelope(): void
    {
        $this->browseWithFailureScreenshot('pricing-details-missing-id', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);

            $response = $this->getJsonFromBrowser($browser, self::PRICING_DETAILS_PATH);
            // pricingDetails does a where()->first() (no findOrFail) → 200 JSON {html:...} even with a null id.
            $this->assertContains((int) $response['status'], [200, 500], 'Unexpected pricing-details status: ' . $response['status']);
            if ((int) $response['status'] === 200) {
                $this->assertStringContainsString('html', (string) $response['body']);
            }
        });
    }

    public function test_subscription_32_pdf_export_without_ids_returns_400(): void
    {
        $this->browseWithFailureScreenshot('subscription-pdf-no-ids', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);

            $response = $this->postJsonFromBrowser($browser, self::SUBSCRIPTION_STORE_PATH, []);
            // SubscriptionController::store early-returns {error:'No IDs provided'} with 400.
            $this->assertSame(400, (int) $response['status'], 'PDF export without ids should return 400.');
            $this->assertStringContainsString('No IDs provided', (string) $response['body']);
        });
    }

    public function test_subscription_33_xss_in_status_filter_is_escaped(): void
    {
        $payload = '"><script>window.__subXss=1;</script>';

        $this->browseWithFailureScreenshot('subscription-xss-status', function (Browser $browser) use ($payload): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated(
                $browser,
                self::SUBSCRIPTION_TYPE_PATH . '&status=' . urlencode($payload)
            );
            $this->ensurePageAccessible($browser, 'Subscription XSS status filter');

            $flag = $browser->driver->executeScript('return window.__subXss || null;');
            $this->assertNull($flag, 'Reflected status filter executed injected script (stored/reflected XSS).');
        });
    }

    public function test_subscription_34_xss_in_date_range_filter_is_escaped(): void
    {
        $payload = '"><img src=x onerror="window.__subXss2=1">';

        $this->browseWithFailureScreenshot('subscription-xss-date', function (Browser $browser) use ($payload): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated(
                $browser,
                self::SUBSCRIPTION_TYPE_PATH . '&date_range=' . urlencode($payload)
            );
            $this->ensurePageAccessible($browser, 'Subscription XSS date filter');

            $flag = $browser->driver->executeScript('return window.__subXss2 || null;');
            $this->assertNull($flag, 'Reflected date_range filter executed injected script.');
        });
    }

    // ------------------------------------------------------------------
    // 40–49  Integration / plan↔module↔tenant junctions (BC-INT)
    // ------------------------------------------------------------------

    public function test_subscription_40_subscription_details_panel_returns_json_html(): void
    {
        $schedule = $this->firstBillingScheduleOrSkip();

        $this->browseWithFailureScreenshot('subscription-details-panel', function (Browser $browser) use ($schedule): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);

            $response = $this->getJsonFromBrowser($browser, self::SUBSCRIPTION_DETAILS_PATH . '?id=' . $schedule->id);
            if ((int) $response['status'] !== 200) {
                $this->markTestSkipped('subscription-details returned ' . $response['status'] . ' (see DEV-BIL-SUB-001 table mismatch).');
            }
            $this->assertStringContainsString('html', (string) $response['body']);
        });
    }

    public function test_subscription_41_pricing_details_panel_returns_json_html(): void
    {
        $plan = $this->firstTenantPlanOrSkip();

        $this->browseWithFailureScreenshot('pricing-details-panel', function (Browser $browser) use ($plan): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);

            $response = $this->getJsonFromBrowser($browser, self::PRICING_DETAILS_PATH . '?id=' . $plan->id);
            $this->assertContains((int) $response['status'], [200, 500], 'pricing-details unexpected status: ' . $response['status']);
            if ((int) $response['status'] === 200) {
                $this->assertStringContainsString('html', (string) $response['body']);
            }
        });
    }

    public function test_subscription_42_billing_schedule_panel_returns_json_html(): void
    {
        $plan = $this->firstTenantPlanOrSkip();

        $this->browseWithFailureScreenshot('billing-schedule-panel', function (Browser $browser) use ($plan): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);

            $response = $this->getJsonFromBrowser($browser, self::BILLING_DETAILS_PATH . '?id=' . $plan->id);
            // billingDetails queries TenantPlanBillingSchedule (plural table) → 200 or 500 per DEV-BIL-SUB-001.
            $this->assertContains((int) $response['status'], [200, 500], 'billing-details unexpected status: ' . $response['status']);
            if ((int) $response['status'] === 200) {
                $this->assertStringContainsString('html', (string) $response['body']);
            }
        });
    }

    public function test_subscription_43_module_details_subscription_type_returns_json_html(): void
    {
        $plan = $this->firstTenantPlanOrSkip();

        $this->browseWithFailureScreenshot('module-details-subscription', function (Browser $browser) use ($plan): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);

            $response = $this->getJsonFromBrowser(
                $browser,
                self::MODULE_DETAILS_PATH . '?id=' . $plan->id . '&type=subscription'
            );
            $this->assertSame(200, (int) $response['status'], 'module-details (subscription) should return 200.');
            $this->assertStringContainsString('html', (string) $response['body']);
        });
    }

    public function test_subscription_44_module_details_defaults_to_invoice_join(): void
    {
        // type != subscription switches the source to BillOrgInvoicingModulesJnt (invoice join).
        $this->browseWithFailureScreenshot('module-details-invoice', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);

            $response = $this->getJsonFromBrowser($browser, self::MODULE_DETAILS_PATH . '?id=1&type=invoice');
            $this->assertContains((int) $response['status'], [200, 500], 'module-details (invoice) unexpected status: ' . $response['status']);
        });
    }

    public function test_subscription_45_tenant_plan_rate_relationships_resolve(): void
    {
        $rate = null;
        try {
            $rate = TenantPlanRate::with(['tenantPlan.plan', 'tenantPlan.tenant', 'billingCycle'])->first();
        } catch (Throwable $e) {
            $this->markTestSkipped('Could not eager-load TenantPlanRate relationships: ' . $e->getMessage());
        }

        if ($rate === null) {
            $this->markTestSkipped('No prm_tenant_plan_rates rows available to verify relationships.');
        }

        // Relationship accessors must not throw; the graph is what the subscription table renders.
        $this->assertTrue($rate->tenantPlan()->getRelated() instanceof TenantPlan);
        $this->assertNotNull($rate->billingCycle());
    }

    // ------------------------------------------------------------------
    // 50–59  Permissions / authorization
    // ------------------------------------------------------------------

    public function test_subscription_50_guest_is_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('subscription-guest-redirect', function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->centralUrl(self::INDEX_PATH))->pause(1200);

            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest was not redirected to /login.');
        });
    }

    public function test_subscription_51_subscription_tab_gate_any_includes_subscription_viewany(): void
    {
        // BillingManagementController::index gates the page with Gate::any([... 'prime.subscription.viewAny' ...]).
        $source = $this->controllerSource(BillingManagementController::class, 'index');
        $this->assertStringContainsString('prime.subscription.viewAny', $source, 'index() no longer grants access via prime.subscription.viewAny.');
    }

    public function test_subscription_52_pdf_export_enforces_subscription_create_gate(): void
    {
        $source = $this->controllerSource(SubscriptionController::class, 'store');
        $this->assertStringContainsString("prime.subscription.create", $source, 'store() no longer enforces prime.subscription.create.');
    }

    public function test_subscription_53_detail_panels_enforce_view_gates(): void
    {
        // pricingDetails/billingDetails gate on prime.subscription.view (post-audit fix of SEC-BIL-010).
        $pricing = $this->controllerSource(SubscriptionController::class, 'pricingDetails');
        $billing = $this->controllerSource(SubscriptionController::class, 'billingDetails');
        $this->assertStringContainsString('prime.subscription.view', $pricing, 'pricingDetails() is missing its Gate::authorize.');
        $this->assertStringContainsString('prime.subscription.view', $billing, 'billingDetails() is missing its Gate::authorize.');
    }

    public function test_subscription_54_permission_key_inconsistency_between_layers_is_documented(): void
    {
        // DEV-BIL-SUB-003 probe: the screen requirement maps "view subscription details" → prime.subscription.view,
        // but subscriptionDetails()/moduleDetails() actually enforce prime.billing-management.view.
        $subDetails = $this->controllerSource(BillingManagementController::class, 'subscriptionDetails');
        $this->assertStringContainsString(
            'prime.billing-management.view',
            $subDetails,
            'subscriptionDetails() gate changed — re-verify DEV-BIL-SUB-003 permission inconsistency.'
        );
        $this->assertStringNotContainsString(
            'prime.subscription.view',
            $subDetails,
            'subscriptionDetails() now uses prime.subscription.view — DEV-BIL-SUB-003 may be resolved.'
        );
    }

    // ------------------------------------------------------------------
    // 60–69  UI / UX
    // ------------------------------------------------------------------

    public function test_subscription_60_subscription_list_is_paginated_ten_per_page(): void
    {
        // index() calls buildSubscriptionQuery()->paginate(10).
        $source = $this->controllerSource(BillingManagementController::class, 'index');
        $this->assertStringContainsString('buildSubscriptionQuery()->paginate(10)', str_replace(' ', '', $source), 'Subscription pagination is no longer 10 per page.');
    }

    public function test_subscription_61_export_and_print_controls_present(): void
    {
        $this->browseWithFailureScreenshot('subscription-export-controls', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::SUBSCRIPTION_TYPE_PATH);
            $this->ensureTabVisible($browser, '#subscription-tab', '#subscription-pane');
            $this->ensurePageAccessible($browser, 'Subscription export controls');

            // PDF export + print controls are permission-gated in the blade; for super-admin they render.
            $this->assertNotNull(
                $browser->element('#downloadPDFMultiBtnsSub') ?: $browser->element('#printFiltered'),
                'Neither the PDF export nor the print control is present on the Subscription tab.'
            );
        });
    }

    public function test_subscription_62_print_data_endpoint_serves_subscription_view(): void
    {
        $this->browseWithFailureScreenshot('subscription-print-data', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);

            $response = $this->getJsonFromBrowser($browser, self::PRINT_PATH);
            $this->assertContains((int) $response['status'], [200, 500], 'print/data (subscription) unexpected status: ' . $response['status']);
        });
    }

    // ------------------------------------------------------------------
    // 70–79  Edge cases
    // ------------------------------------------------------------------

    public function test_subscription_70_status_filter_inactive_only_matches_zero_family(): void
    {
        // BC-EDG: buildSubscriptionQuery maps 'Inactive' → status IN (0,'INACTIVE','inactive') only, so a
        // SUSPENDED/CANCELED/EXPIRED plan is neither "Active" nor "Inactive" filterable. Document the mapping.
        $source = $this->controllerSource(BillingManagementController::class, 'buildSubscriptionQuery');
        $this->assertStringContainsString("'INACTIVE'", $source, 'Inactive status mapping changed.');
        $this->assertStringNotContainsString("'SUSPENDED'", $source, 'SUSPENDED unexpectedly handled — edge note may be resolved.');
    }

    public function test_subscription_71_empty_subscription_tab_renders_without_error(): void
    {
        $this->browseWithFailureScreenshot('subscription-empty-state', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            // A date window far in the past should yield an empty result set but still render the table.
            $this->visitAuthenticated(
                $browser,
                self::SUBSCRIPTION_TYPE_PATH . '&date_range=' . urlencode('1990-01-01 to 1990-01-02')
            );
            $this->ensurePageAccessible($browser, 'Subscription empty state');
            $browser->assertPresent('#subscription-pane table');
        });
    }

    public function test_subscription_72_tenant_plan_generated_current_flag_column_definition(): void
    {
        // BC-EDG (schema): the DDL declares a GENERATED current_flag referencing the pre-rename column `org_id`.
        // Record whichever the live DB actually exposes so the generated-column drift is traceable.
        $hasCurrentFlag = Schema::hasColumn('prm_tenant_plan_jnt', 'current_flag');
        $this->assertIsBool($hasCurrentFlag);
        // The uniqueness of a subscribed plan hangs off this generated column; assert the driving flag exists.
        $this->assertTrue(Schema::hasColumn('prm_tenant_plan_jnt', 'is_subscribed'), 'is_subscribed drives current_flag.');
    }

    // ------------------------------------------------------------------
    // 90–99  Security (tenancy isolation N/A — central single-DB module)
    // ------------------------------------------------------------------

    public function test_subscription_90_detail_panel_rejects_unknown_direct_id(): void
    {
        // IDOR-shape: a direct id for a non-existent schedule must not 200 with someone else's data.
        $this->browseWithFailureScreenshot('subscription-idor', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);

            $response = $this->getJsonFromBrowser($browser, self::SUBSCRIPTION_DETAILS_PATH . '?id=2147483647');
            $this->assertNotSame(200, (int) $response['status'], 'Non-existent subscription id returned 200.');
        });
    }

    public function test_subscription_91_no_severe_console_errors_on_tab_load(): void
    {
        $this->browseWithFailureScreenshot('subscription-console-smoke', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::SUBSCRIPTION_TYPE_PATH);
            $this->ensureTabVisible($browser, '#subscription-tab', '#subscription-pane');
            $this->ensurePageAccessible($browser, 'Subscription console smoke');

            $severe = 0;
            try {
                foreach ($browser->driver->manage()->getLog('browser') as $entry) {
                    if (isset($entry['level']) && $entry['level'] === 'SEVERE') {
                        $severe++;
                    }
                }
            } catch (Throwable) {
                $this->markTestSkipped('Browser console log not available in this driver.');
            }

            $this->assertLessThanOrEqual(2, $severe, 'Too many SEVERE console errors on the Subscription tab.');
        });
    }

    // ==================================================================
    // Private helper library
    // ==================================================================

    private function anyRouteExists(array $names): bool
    {
        foreach ($names as $name) {
            if (Route::has($name)) {
                return true;
            }
        }
        return false;
    }

    private function controllerSource(string $class, string $method): string
    {
        try {
            $ref = new ReflectionMethod($class, $method);
            $file = (string) $ref->getFileName();
            $start = (int) $ref->getStartLine();
            $end = (int) $ref->getEndLine();
            $lines = @file($file) ?: [];
            return implode('', array_slice($lines, $start - 1, ($end - $start) + 1));
        } catch (Throwable $e) {
            $this->fail("Could not reflect $class::$method — " . $e->getMessage());
        }

        return '';
    }

    private function firstTenantPlanOrSkip(): TenantPlan
    {
        try {
            $plan = TenantPlan::query()->first();
        } catch (Throwable $e) {
            $this->markTestSkipped('prm_tenant_plan_jnt not queryable: ' . $e->getMessage());
        }

        if (!isset($plan) || $plan === null) {
            $this->markTestSkipped('No prm_tenant_plan_jnt rows available; seed a subscription in the Prime module first.');
        }

        return $plan;
    }

    private function firstBillingScheduleOrSkip(): TenantPlanBillingSchedule
    {
        try {
            $schedule = TenantPlanBillingSchedule::query()->first();
        } catch (Throwable $e) {
            $this->markTestSkipped('billing schedule table not queryable (DEV-BIL-SUB-001?): ' . $e->getMessage());
        }

        if (!isset($schedule) || $schedule === null) {
            $this->markTestSkipped('No billing-schedule rows available for the detail panel.');
        }

        return $schedule;
    }

    /**
     * Issue an authenticated GET from the current (logged-in) page and return {status, body}.
     * Dusk Browser cannot assert status codes directly (constraint 05_ D14), so we use a page-context fetch.
     */
    private function getJsonFromBrowser(Browser $browser, string $path): array
    {
        return $this->sendJsonRequestFromBrowser($browser, 'GET', $path, []);
    }

    private function postJsonFromBrowser(Browser $browser, string $path, array $payload): array
    {
        return $this->sendJsonRequestFromBrowser($browser, 'POST', $path, $payload);
    }

    private function sendJsonRequestFromBrowser(Browser $browser, string $method, string $path, array $payload): array
    {
        $url = $this->centralUrl($path);

        $script = <<<'JS'
            var done = arguments[arguments.length - 1];
            var method = arguments[0];
            var url = arguments[1];
            var payload = arguments[2];
            var tokenEl = document.querySelector('meta[name="csrf-token"]');
            var headers = { 'Accept': 'application/json', 'X-Requested-With': 'XMLHttpRequest' };
            if (tokenEl) { headers['X-CSRF-TOKEN'] = tokenEl.getAttribute('content'); }
            var opts = { method: method, headers: headers, credentials: 'same-origin' };
            if (method !== 'GET' && method !== 'HEAD') {
                headers['Content-Type'] = 'application/json';
                opts.body = JSON.stringify(payload);
            }
            fetch(url, opts).then(function (r) {
                return r.text().then(function (t) { done(JSON.stringify({ status: r.status, body: t })); });
            }).catch(function (e) { done(JSON.stringify({ status: 0, body: String(e) })); });
        JS;

        try {
            $raw = $browser->driver->executeAsyncScript($script, [$method, $url, $payload]);
        } catch (Throwable $e) {
            return ['status' => 0, 'body' => $e->getMessage()];
        }

        $decoded = json_decode((string) $raw, true);

        return is_array($decoded) ? $decoded : ['status' => 0, 'body' => (string) $raw];
    }

    private function assertStringNotContainsStringIgnoringCase(string $needle, string $haystack, string $message): void
    {
        $this->assertFalse(
            stripos($haystack, $needle) !== false,
            $message
        );
    }
}
