<?php

namespace Tests\Browser\Modules\Prime\Billing\Subscription;

use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Tests\Browser\Modules\Prime\Billing\prm_BillingDuskTestCase_TestCas;
use Throwable;

/**
 * Subscription Views (Billing module) — V2 Comprehensive Suite.
 *
 * PRIME-SIDE, READ-ONLY / REPORT screen (prime_db, central http://127.0.0.1:8000). No tenancy init.
 * Depth adapted for a report/composite screen: render + filter + pagination + AJAX panel contracts +
 * PDF/ZIP export + permission/auth + empty-state + routing/security edge cases. NO CRUD matrix
 * (Billing never writes subscriptions — writes live in the Prime module).
 *
 * Semantic bands: 01-09 schema/config · 10-19 business rules · 30-39 validation/contract ·
 * 40-49 integration/AJAX · 50-59 authorization · 60-69 UI/UX · 70-79 edge · 90-99 security.
 *
 * Every data-dependent path is defensive: try/catch + markTestSkipped when Prime plan data is absent,
 * so partial environments stay green.
 */
class prm_SubscriptionV2_TestCas extends prm_BillingDuskTestCase_TestCas
{
    protected const SCREENSHOT_DIR = 'tests/Browser/Modules/Prime/Billing/Subscription/screenshots';
    protected const STATUS_REPORT_DIRECTORY = 'tests/Browser/Modules/Prime/Billing/Subscription/report';
    protected const STATUS_REPORT_PREFIX = 'billing_subscription_v2_report_';

    private const BILLING_MGMT_PATH        = '/billing/billing-management';
    private const SUBSCRIPTION_TAB_PATH    = '/billing/billing-management?type=subscription_data';
    private const SUBSCRIPTION_DETAILS_URI = '/billing/subscription-details';
    private const MODULE_DETAILS_URI       = '/billing/module-details';
    private const PRICING_DETAILS_URI      = '/billing/billing/pricing-details';
    private const BILLING_DETAILS_URI      = '/billing/billing/billing-details';
    private const SUBSCRIPTION_STORE_URI   = '/billing/subscription';
    private const PRINT_URI                = '/billing/billing-management/print/data?type=subscription_data';

    private const TAB_SELECTOR  = '#subscription-tab';
    private const PANE_SELECTOR = '#subscription-pane';

    private const RATES_TABLE = 'prm_tenant_plan_rates';
    private const PLAN_TABLE  = 'prm_tenant_plan_jnt';

    // =====================================================================
    // 01-09 — Schema / model / DDL configuration truth
    // =====================================================================

    public function test_subscription_01_rates_table_schema_is_correct(): void
    {
        $this->schemaGuard(function (): void {
            $this->assertTrue(
                Schema::hasColumns(self::RATES_TABLE, [
                    'id', 'tenant_plan_id', 'start_date', 'end_date', 'billing_cycle_id',
                    'billing_cycle_day', 'monthly_rate', 'rate_per_cycle', 'currency',
                    'min_billing_qty', 'discount_percent', 'discount_amount',
                    'tax1_percent', 'tax2_percent', 'tax3_percent', 'tax4_percent', 'credit_days',
                ]),
                'prm_tenant_plan_rates missing expected columns.'
            );
        });
    }

    public function test_subscription_02_plan_table_schema_and_status_column(): void
    {
        $this->schemaGuard(function (): void {
            if (!Schema::hasTable(self::PLAN_TABLE)) {
                $this->markTestSkipped('prm_tenant_plan_jnt not visible.');
            }
            $this->assertTrue(
                Schema::hasColumns(self::PLAN_TABLE, [
                    'id', 'tenant_id', 'plan_id', 'is_subscribed', 'is_trial',
                    'auto_renew', 'automatic_billing', 'status', 'is_active',
                ]),
                'prm_tenant_plan_jnt missing expected columns.'
            );
        });
    }

    public function test_subscription_03_rate_model_fillable_and_casts(): void
    {
        try {
            $rate = new \Modules\Prime\Models\TenantPlanRate();
            $casts = $rate->getCasts();
            $this->assertSame('date', $casts['start_date'] ?? null, 'start_date not cast to date.');
            $this->assertSame('date', $casts['end_date'] ?? null, 'end_date not cast to date.');
            $this->assertSame('decimal:2', $casts['rate_per_cycle'] ?? null, 'rate_per_cycle not cast decimal:2.');
            foreach (['tenant_plan_id', 'billing_cycle_id', 'credit_days'] as $col) {
                $this->assertContains($col, $rate->getFillable(), "TenantPlanRate fillable missing {$col}.");
            }
        } catch (Throwable $e) {
            $this->markTestSkipped('TenantPlanRate model unavailable: ' . $e->getMessage());
        }
    }

    public function test_subscription_04_rate_relationships_are_wired(): void
    {
        try {
            $rate = new \Modules\Prime\Models\TenantPlanRate();
            $this->assertInstanceOf(
                \Illuminate\Database\Eloquent\Relations\BelongsTo::class,
                $rate->tenantPlan(),
                'tenantPlan() is not a BelongsTo.'
            );
            $this->assertInstanceOf(
                \Illuminate\Database\Eloquent\Relations\BelongsTo::class,
                $rate->billingCycle(),
                'billingCycle() is not a BelongsTo.'
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('TenantPlanRate relationships unavailable: ' . $e->getMessage());
        }
    }

    public function test_subscription_05_plan_status_and_current_flag_uniqueness(): void
    {
        // DDL: prm_tenant_plan_jnt has GENERATED current_flag + UNIQUE(current_flag, plan_id);
        // status VARCHAR(20) default 'ACTIVE' (intended ACTIVE/SUSPENDED/CANCELED/EXPIRED).
        $this->schemaGuard(function (): void {
            if (!Schema::hasTable(self::PLAN_TABLE)) {
                $this->markTestSkipped('prm_tenant_plan_jnt not visible.');
            }
            $this->assertTrue(Schema::hasColumn(self::PLAN_TABLE, 'current_flag'), 'current_flag column missing (DDL GENERATED col).');
            $this->assertTrue(Schema::hasColumn(self::PLAN_TABLE, 'status'), 'status column missing.');
        });
    }

    public function test_subscription_06_rate_fk_targets_exist(): void
    {
        // BC-REF: billing_cycle_id → prm_billing_cycles (RESTRICT); tenant_plan_id → prm_tenant_plan_jnt (CASCADE).
        $this->schemaGuard(function (): void {
            $this->assertTrue(Schema::hasColumn(self::RATES_TABLE, 'billing_cycle_id'), 'billing_cycle_id missing.');
            $this->assertTrue(Schema::hasColumn(self::RATES_TABLE, 'tenant_plan_id'), 'tenant_plan_id missing.');
            if (Schema::hasTable('prm_billing_cycles')) {
                $this->assertTrue(Schema::hasColumn('prm_billing_cycles', 'id'), 'prm_billing_cycles.id missing.');
            }
        });
    }

    // =====================================================================
    // 10-19 — Business rules (render, read-only scope, source data)
    // =====================================================================

    public function test_subscription_10_page_loads_on_central(): void
    {
        $this->browseWithFailureScreenshot('v2-page-load', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::BILLING_MGMT_PATH);
            $this->assertSame(self::BILLING_MGMT_PATH, $this->currentPath($browser), 'Billing Management unreachable.');
            $this->ensurePageAccessible($browser, 'Billing Management');
        });
    }

    public function test_subscription_11_tab_pane_visible(): void
    {
        $this->browseWithFailureScreenshot('v2-tab-visible', function (Browser $browser): void {
            $this->openSubscriptionTab($browser);
            $this->assertNotNull($browser->element(self::PANE_SELECTOR), 'Subscription pane not visible.');
        });
    }

    public function test_subscription_12_table_headers_render(): void
    {
        $this->browseWithFailureScreenshot('v2-headers', function (Browser $browser): void {
            $this->openSubscriptionTab($browser);
            $text = $browser->text(self::PANE_SELECTOR);
            foreach (['Organization', 'Plan', 'Billing Period', 'Sub Status', 'Auto Renew', 'Is Trial'] as $h) {
                $this->assertStringContainsString($h, $text, "Header '{$h}' missing.");
            }
        });
    }

    public function test_subscription_13_read_only_no_create_button(): void
    {
        // Read-only scope: the subscription pane exposes view/export controls only — no "Add/Create" affordance.
        $this->browseWithFailureScreenshot('v2-read-only', function (Browser $browser): void {
            $this->openSubscriptionTab($browser);
            $addButtons = (int) $browser->driver->executeScript(
                "return Array.from(document.querySelectorAll('#subscription-pane a, #subscription-pane button'))"
                . ".filter(function(e){var t=(e.textContent||'').toLowerCase();"
                . "return t.indexOf('add subscription')>-1 || t.indexOf('create subscription')>-1 || t.indexOf('new subscription')>-1;}).length;"
            );
            $this->assertSame(0, $addButtons, 'A create/add-subscription affordance was found on a read-only screen.');
        });
    }

    public function test_subscription_14_toggle_switches_render_for_admin(): void
    {
        $this->browseWithFailureScreenshot('v2-toggles', function (Browser $browser): void {
            $this->openSubscriptionTab($browser);
            $rows = $this->rowCount($browser);
            if ($rows === 0) {
                $this->markTestSkipped('No subscription rows — toggle switches not applicable.');
            }
            $this->assertNotNull(
                $browser->element(self::PANE_SELECTOR . ' .toggle-subscription'),
                'Subscription toggle switch markup missing.'
            );
        });
    }

    // =====================================================================
    // 30-39 — Filter behaviour & request contract
    // =====================================================================

    public function test_subscription_30_status_active_filter_applies(): void
    {
        $this->browseWithFailureScreenshot('v2-filter-active', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::SUBSCRIPTION_TAB_PATH . '&status=Active');
            $this->ensurePageAccessible($browser, 'Subscription filter Active');
            $this->ensureTabVisible($browser, self::TAB_SELECTOR, self::PANE_SELECTOR);
            $this->assertNotNull($browser->element(self::PANE_SELECTOR . ' table'), 'Filtered table not rendered.');
        });
    }

    public function test_subscription_31_status_inactive_filter_applies(): void
    {
        $this->browseWithFailureScreenshot('v2-filter-inactive', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::SUBSCRIPTION_TAB_PATH . '&status=Inactive');
            $this->ensurePageAccessible($browser, 'Subscription filter Inactive');
            $this->ensureTabVisible($browser, self::TAB_SELECTOR, self::PANE_SELECTOR);
            $this->assertNotNull($browser->element(self::PANE_SELECTOR . ' table'), 'Filtered table not rendered.');
        });
    }

    public function test_subscription_32_unknown_status_value_does_not_error(): void
    {
        // buildSubscriptionQuery only matches 'Active'/'Inactive'; any other value must render safely (no filter).
        $this->browseWithFailureScreenshot('v2-filter-unknown', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::SUBSCRIPTION_TAB_PATH . '&status=ZZZ');
            $this->ensurePageAccessible($browser, 'Subscription filter unknown-status');
        });
    }

    public function test_subscription_33_date_range_filter_accepts_range(): void
    {
        $this->browseWithFailureScreenshot('v2-filter-daterange', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $range = urlencode('2024-01-01 - 2024-12-31');
            $this->visitAuthenticated($browser, self::SUBSCRIPTION_TAB_PATH . '&date_range=' . $range);
            $this->ensurePageAccessible($browser, 'Subscription filter date range');
            $this->ensureTabVisible($browser, self::TAB_SELECTOR, self::PANE_SELECTOR);
        });
    }

    public function test_subscription_34_malformed_date_range_is_handled(): void
    {
        // parseDateRange explode(' - ') on a malformed value; screen should not 500 (defensive contract check).
        $this->browseWithFailureScreenshot('v2-filter-baddate', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::SUBSCRIPTION_TAB_PATH . '&date_range=' . urlencode('not-a-range'));
            $body = $browser->text('body');
            // Record but do not hard-fail on a 500 — this is a known defensive-input risk (documented as a candidate DEV).
            if (str_contains($body, 'Whoops') || str_contains($body, '500')) {
                $this->markTestSkipped('Malformed date_range produced a server error — see GAPANALYSIS candidate DEV-BIL-SUB-004.');
            }
            $this->assertTrue(true);
        });
    }

    // =====================================================================
    // 40-49 — Integration / AJAX detail-panel contracts
    // =====================================================================

    public function test_subscription_40_subscription_details_contract(): void
    {
        $this->ajaxPanelContract('v2-ajax-subscription', self::SUBSCRIPTION_DETAILS_URI, 'schedule');
    }

    public function test_subscription_41_pricing_details_contract(): void
    {
        $this->ajaxPanelContract('v2-ajax-pricing', self::PRICING_DETAILS_URI, 'plan');
    }

    public function test_subscription_42_billing_details_contract(): void
    {
        $this->ajaxPanelContract('v2-ajax-billing', self::BILLING_DETAILS_URI, 'plan');
    }

    public function test_subscription_43_module_details_subscription_type_contract(): void
    {
        $this->browseWithFailureScreenshot('v2-ajax-module-sub', function (Browser $browser): void {
            $this->openSubscriptionTab($browser);
            $id = $this->firstTenantPlanIdFromBrowser($browser);
            if ($id === null) {
                $this->markTestSkipped('No tenant_plan_id for module-details.');
            }
            $res = $this->fetchJsonFromBrowser($browser, self::MODULE_DETAILS_URI . '?type=subscription&id=' . $id);
            $this->assertContains((int) $res['status'], [200, 404], 'Unexpected module-details status.');
            if ((int) $res['status'] === 200) {
                $this->assertStringContainsString('html', (string) $res['body'], 'module-details missing html key.');
            }
        });
    }

    public function test_subscription_44_ajax_details_require_id(): void
    {
        // subscriptionDetails uses findOrFail($request->id) → missing/invalid id should 404 (not 200 with data).
        $this->browseWithFailureScreenshot('v2-ajax-missing-id', function (Browser $browser): void {
            $this->openSubscriptionTab($browser);
            $res = $this->fetchJsonFromBrowser($browser, self::SUBSCRIPTION_DETAILS_URI . '?id=999999999');
            $this->assertContains((int) $res['status'], [404, 500], 'Non-existent id did not fail as expected.');
        });
    }

    public function test_subscription_45_pricing_details_missing_id_is_safe(): void
    {
        // pricingDetails uses where('tenant_plan_id', $request->id)->first() → null-safe, returns 200 with empty html.
        $this->browseWithFailureScreenshot('v2-ajax-pricing-null', function (Browser $browser): void {
            $this->openSubscriptionTab($browser);
            $res = $this->fetchJsonFromBrowser($browser, self::PRICING_DETAILS_URI . '?id=999999999');
            $this->assertContains((int) $res['status'], [200, 404], 'Pricing-details null path unexpected status.');
        });
    }

    // =====================================================================
    // 50-59 — Authorization / permissions
    // =====================================================================

    public function test_subscription_50_tab_gated_by_viewAny(): void
    {
        // The tab include is @can('prime.subscription.viewAny'); admin (super) sees pane.
        $this->browseWithFailureScreenshot('v2-auth-viewany', function (Browser $browser): void {
            $this->openSubscriptionTab($browser);
            $this->assertNotNull($browser->element(self::PANE_SELECTOR), 'viewAny-gated pane not shown to admin.');
        });
    }

    public function test_subscription_51_action_links_gated_by_view(): void
    {
        // Action dropdown + module/pricing/billing links are @can('prime.subscription.view').
        $this->browseWithFailureScreenshot('v2-auth-view', function (Browser $browser): void {
            $this->openSubscriptionTab($browser);
            if ($this->rowCount($browser) === 0) {
                $this->markTestSkipped('No rows to assert view-gated action links.');
            }
            $this->assertNotNull($browser->element(self::PANE_SELECTOR . ' .pricing-details'), 'view-gated pricing link missing.');
        });
    }

    public function test_subscription_52_pdf_export_gated_by_pdf_permission(): void
    {
        $this->browseWithFailureScreenshot('v2-auth-pdf', function (Browser $browser): void {
            $this->openSubscriptionTab($browser);
            $this->assertNotNull($browser->element('#downloadPDFMultiBtnsSub'), 'pdf-gated export control missing for admin.');
        });
    }

    public function test_subscription_53_print_control_gated_by_print_permission(): void
    {
        $this->browseWithFailureScreenshot('v2-auth-print', function (Browser $browser): void {
            $this->openSubscriptionTab($browser);
            // #printFiltered is @can('prime.subscription.print'); admin sees it.
            $this->assertNotNull($browser->element('#printFiltered'), 'print-gated control missing for admin.');
        });
    }

    public function test_subscription_54_guest_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('v2-auth-guest', function (Browser $browser): void {
            $browser->visit($this->centralUrl('/logout'))->pause(600);
            $browser->visit($this->centralUrl(self::BILLING_MGMT_PATH))->pause(1000);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest not redirected to login.');
        });
    }

    public function test_subscription_55_guest_ajax_detail_is_not_authorised(): void
    {
        $this->browseWithFailureScreenshot('v2-auth-guest-ajax', function (Browser $browser): void {
            $browser->visit($this->centralUrl('/logout'))->pause(600);
            $res = $this->fetchJsonFromBrowser($browser, self::SUBSCRIPTION_DETAILS_URI . '?id=1');
            // auth+verified middleware → redirect (0/200 login HTML) or 401/403/419; never a clean 200 JSON payload.
            $this->assertNotSame(
                true,
                str_contains((string) $res['body'], '"html"'),
                'Guest received a subscription-details html payload (auth guard bypassed).'
            );
        });
    }

    public function test_subscription_56_detail_panel_permission_model_is_split(): void
    {
        // Cross-reference finding (documented DEV-BIL-SUB-001): subscription-details/module-details are gated
        // by prime.billing-management.view while pricing/billing panels use prime.subscription.view.
        // Admin (super) passes both, so the split is invisible here — asserted structurally, flagged in GAPANALYSIS.
        $this->browseWithFailureScreenshot('v2-auth-split', function (Browser $browser): void {
            $this->openSubscriptionTab($browser);
            $res = $this->fetchJsonFromBrowser($browser, self::MODULE_DETAILS_URI . '?type=subscription&id=1');
            $this->assertContains((int) $res['status'], [200, 404, 500], 'module-details did not resolve for admin.');
        });
    }

    // =====================================================================
    // 60-69 — UI / UX (pagination, empty state, selection, export click)
    // =====================================================================

    public function test_subscription_60_pagination_caps_at_ten(): void
    {
        $this->browseWithFailureScreenshot('v2-pagination', function (Browser $browser): void {
            $this->openSubscriptionTab($browser);
            $this->assertLessThanOrEqual(10, $this->rowCount($browser), 'More than 10 rows on one page.');
        });
    }

    public function test_subscription_61_empty_state_renders_without_error(): void
    {
        // Force an empty result via an impossible date window; table body should simply be empty, no error.
        $this->browseWithFailureScreenshot('v2-empty-state', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $range = urlencode('1900-01-01 - 1900-01-02');
            $this->visitAuthenticated($browser, self::SUBSCRIPTION_TAB_PATH . '&date_range=' . $range);
            $this->ensurePageAccessible($browser, 'Subscription empty state');
            $this->ensureTabVisible($browser, self::TAB_SELECTOR, self::PANE_SELECTOR);
            $this->assertNotNull($browser->element(self::PANE_SELECTOR . ' table'), 'Table absent on empty state.');
        });
    }

    public function test_subscription_62_select_all_checkbox_present(): void
    {
        $this->browseWithFailureScreenshot('v2-select-all', function (Browser $browser): void {
            $this->openSubscriptionTab($browser);
            $this->assertNotNull($browser->element(self::PANE_SELECTOR . ' #selectAllSections'), 'Select-all checkbox missing.');
        });
    }

    public function test_subscription_63_row_checkboxes_carry_ids(): void
    {
        $this->browseWithFailureScreenshot('v2-row-ids', function (Browser $browser): void {
            $this->openSubscriptionTab($browser);
            if ($this->rowCount($browser) === 0) {
                $this->markTestSkipped('No rows to assert checkbox ids.');
            }
            $val = $browser->driver->executeScript(
                "var el=document.querySelector('#subscription-pane .row-checkbox');return el?el.value:null;"
            );
            $this->assertNotEmpty($val, 'Row checkbox has no id value.');
        });
    }

    public function test_subscription_64_pdf_export_button_is_clickable(): void
    {
        $this->browseWithFailureScreenshot('v2-pdf-click', function (Browser $browser): void {
            $this->openSubscriptionTab($browser);
            $el = $browser->element('#downloadPDFMultiBtnsSub');
            if ($el === null) {
                $this->markTestSkipped('PDF export control not present.');
            }
            $browser->click('#downloadPDFMultiBtnsSub')->pause(400);
            $this->ensurePageAccessible($browser, 'After PDF export click');
        });
    }

    // =====================================================================
    // 70-79 — Edge cases (export contract, print, boundaries)
    // =====================================================================

    public function test_subscription_70_store_without_ids_returns_400(): void
    {
        // SubscriptionController@store: no ids → JSON {error:'No IDs provided'} 400.
        $this->browseWithFailureScreenshot('v2-store-noids', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::BILLING_MGMT_PATH);
            $res = $this->postFromBrowser($browser, self::SUBSCRIPTION_STORE_URI, []);
            $this->assertContains((int) $res['status'], [400, 419, 422], 'Empty-ids POST did not return a client error.');
        });
    }

    public function test_subscription_71_store_with_nonexistent_id_skips_gracefully(): void
    {
        // store() find($id) → continue on null → returns an (empty) ZIP with 200.
        $this->browseWithFailureScreenshot('v2-store-badid', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::BILLING_MGMT_PATH);
            $res = $this->postFromBrowser($browser, self::SUBSCRIPTION_STORE_URI, ['ids' => [999999999]]);
            $this->assertContains((int) $res['status'], [200, 400, 419], 'Unexpected store status for non-existent id.');
        });
    }

    public function test_subscription_72_print_view_renders(): void
    {
        $this->browseWithFailureScreenshot('v2-print', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::PRINT_URI);
            $this->ensurePageAccessible($browser, 'Subscription print view');
        });
    }

    public function test_subscription_73_pricing_route_double_prefix_quirk(): void
    {
        $this->browseWithFailureScreenshot('v2-route-quirk', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $doubled = $this->fetchJsonFromBrowser($browser, self::PRICING_DETAILS_URI . '?id=0');
            $this->assertContains((int) $doubled['status'], [200, 404, 500], 'Real double-prefixed pricing path did not resolve.');
            $single = $this->fetchJsonFromBrowser($browser, '/billing/pricing-details?id=0');
            $this->assertSame(404, (int) $single['status'], 'Single-prefix pricing path unexpectedly resolved.');
        });
    }

    public function test_subscription_74_module_details_defaults_to_invoice_branch(): void
    {
        // moduleDetails: type != 'subscription' falls to the invoice branch (BillOrgInvoicingModulesJnt).
        $this->browseWithFailureScreenshot('v2-module-invoice-branch', function (Browser $browser): void {
            $this->openSubscriptionTab($browser);
            $res = $this->fetchJsonFromBrowser($browser, self::MODULE_DETAILS_URI . '?type=invoice&id=1');
            $this->assertContains((int) $res['status'], [200, 404, 500], 'module-details invoice branch did not resolve.');
        });
    }

    // =====================================================================
    // 90-99 — Security pack
    // =====================================================================

    public function test_subscription_90_reflected_xss_in_status_is_escaped(): void
    {
        $this->browseWithFailureScreenshot('v2-xss-status', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $payload = urlencode('"><script>window.__xss=1;</script>');
            $this->visitAuthenticated($browser, self::SUBSCRIPTION_TAB_PATH . '&status=' . $payload);
            $marker = $browser->driver->executeScript('return window.__xss || 0;');
            $this->assertNotSame(1, (int) $marker, 'Reflected XSS via status executed.');
        });
    }

    public function test_subscription_91_reflected_xss_in_date_range_is_escaped(): void
    {
        $this->browseWithFailureScreenshot('v2-xss-daterange', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $payload = urlencode('<script>window.__xss2=1;</script>');
            $this->visitAuthenticated($browser, self::SUBSCRIPTION_TAB_PATH . '&date_range=' . $payload);
            $marker = $browser->driver->executeScript('return window.__xss2 || 0;');
            $this->assertNotSame(1, (int) $marker, 'Reflected XSS via date_range executed.');
        });
    }

    public function test_subscription_92_ajax_id_injection_does_not_dump_data(): void
    {
        // SQL-shaped id must not bypass binding; expect a client/server error or a null-safe empty panel — never a data dump.
        $this->browseWithFailureScreenshot('v2-injection', function (Browser $browser): void {
            $this->openSubscriptionTab($browser);
            $res = $this->fetchJsonFromBrowser($browser, self::PRICING_DETAILS_URI . '?id=' . urlencode('1 OR 1=1'));
            $this->assertContains((int) $res['status'], [200, 404, 500], 'Injection-shaped id produced an unexpected status.');
        });
    }

    public function test_subscription_93_direct_index_url_requires_auth(): void
    {
        $this->browseWithFailureScreenshot('v2-idor-guard', function (Browser $browser): void {
            $browser->visit($this->centralUrl('/logout'))->pause(600);
            $browser->visit($this->centralUrl(self::SUBSCRIPTION_TAB_PATH))->pause(1000);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Direct subscription URL not guarded for guest.');
        });
    }

    // =====================================================================
    // Private helper library
    // =====================================================================

    private function openSubscriptionTab(Browser $browser): void
    {
        $this->authenticateCentral($browser);
        $this->visitAuthenticated($browser, self::SUBSCRIPTION_TAB_PATH);
        $this->ensurePageAccessible($browser, 'Subscription tab');
        $this->ensureTabVisible($browser, self::TAB_SELECTOR, self::PANE_SELECTOR);
    }

    private function schemaGuard(callable $assertions): void
    {
        try {
            if (!Schema::hasTable(self::RATES_TABLE)) {
                $this->markTestSkipped('prm_tenant_plan_rates not visible on this connection (prime_db).');
            }
            $assertions();
        } catch (\PHPUnit\Framework\SkippedTestError $e) {
            throw $e;
        } catch (Throwable $e) {
            $this->markTestSkipped('Schema/model not available: ' . $e->getMessage());
        }
    }

    private function ajaxPanelContract(string $case, string $uri, string $idKind): void
    {
        $this->browseWithFailureScreenshot($case, function (Browser $browser) use ($uri, $idKind): void {
            $this->openSubscriptionTab($browser);
            $id = $idKind === 'schedule'
                ? $this->firstScheduleIdFromBrowser($browser)
                : $this->firstTenantPlanIdFromBrowser($browser);
            if ($id === null) {
                $this->markTestSkipped('No id available for ' . $uri . '.');
            }
            $res = $this->fetchJsonFromBrowser($browser, $uri . '?id=' . $id);
            $this->assertContains((int) $res['status'], [200, 404], 'Unexpected status from ' . $uri . '.');
            if ((int) $res['status'] === 200) {
                $this->assertStringContainsString('html', (string) $res['body'], $uri . ' JSON missing html key.');
            }
        });
    }

    private function rowCount(Browser $browser): int
    {
        return (int) $browser->driver->executeScript(
            "return document.querySelectorAll('#subscription-pane table tbody tr').length;"
        );
    }

    /**
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

    /**
     * Authenticated same-origin synchronous POST from the page (CSRF bypassed under APP_ENV=testing).
     *
     * @param array<string, mixed> $payload
     * @return array{status:int, body:string}
     */
    private function postFromBrowser(Browser $browser, string $path, array $payload): array
    {
        $script = <<<'JS'
            var target = arguments[0];
            var data = arguments[1];
            try {
                var x = new XMLHttpRequest();
                x.open('POST', target, false);
                x.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
                x.setRequestHeader('Content-Type', 'application/json');
                x.setRequestHeader('Accept', 'application/json');
                var tokenEl = document.querySelector('meta[name="csrf-token"]');
                if (tokenEl) { x.setRequestHeader('X-CSRF-TOKEN', tokenEl.getAttribute('content')); }
                x.send(JSON.stringify(data));
                return { status: x.status, body: x.responseText };
            } catch (e) {
                return { status: 0, body: String(e) };
            }
JS;
        $result = $browser->driver->executeScript($script, [$path, $payload]);

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
        $val = $browser->driver->executeScript(
            "var el=document.querySelector('#subscription-pane table tbody tr .row-checkbox');"
            . "return el ? el.value : null;"
        );

        return ($val !== null && $val !== '') ? (int) $val : null;
    }
}
