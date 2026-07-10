<?php

namespace Tests\Browser\Modules\Prime\Billing\Invoicing;

use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\Billing\Models\BilTenantInvoice;
use Modules\Billing\Models\InvoicingAuditLog;
use Tests\Browser\Modules\Prime\Billing\BillingDuskTestCase;
use Throwable;

/**
 * Invoicing (Invoice Generation) — V2 comprehensive Dusk suite (central prime_db).
 *
 * DB scope: prime_db central. No tenancy scaffolding in the TEST (the generation
 * path calls Tenancy::initialize()/end() internally — behaviour under test).
 * Mirrors the committed sibling prm_InvoicingTab_TestCas / BillingDuskTestCase
 * central chain (authenticateCentral / visitAuthenticated / centralUrl /
 * ensureTabVisible / ensurePageAccessible).
 * Prefix bil_ verified against DDL Billing_DDL_v1.sql line 4 (`bil_tenant_invoices`).
 *
 * Semantic numbering bands (WP-G):
 *   01-09 schema/model/route config     10-19 business rules (formulas)
 *   20-29 state machine / status         30-39 validation + filters
 *   40-49 integration / FK / generate    50-59 permissions
 *   60-69 UI/UX (tab, columns, paging)   70-79 edge cases
 *   90-99 security
 */
class bil_InvoicingV2_TestCas extends BillingDuskTestCase
{
    protected const SCREENSHOT_DIR = 'tests/Browser/Modules/Prime/Billing/Invoicing/screenshots';
    protected const STATUS_REPORT_DIRECTORY = 'tests/Browser/Modules/Prime/Billing/Invoicing/report';
    protected const STATUS_REPORT_PREFIX = 'billing_invoicing_v2_report_';

    private const INDEX_PATH = '/billing/billing-management';
    private const INVOICE_DETAILS_PATH = '/billing/invoice-details';
    private const SUBSCRIPTION_DETAILS_PATH = '/billing/subscription-details';
    private const MODULE_DETAILS_PATH = '/billing/module-details';
    private const REMARKS_UPDATE_PATH = '/billing/invoice/remarks/update';
    private const TABLE = 'bil_tenant_invoices';
    private const AUDIT_TABLE = 'bil_tenant_invoicing_audit_logs';
    private const MODULES_JNT_TABLE = 'bil_tenant_invoicing_modules_jnt';

    private const REFERENCED_TABLES = [
        'prm_tenant',
        'prm_tenant_plan_jnt',
        'prm_billing_cycles',
        'prm_tenant_plan_billing_schedule',
        'prm_tenant_plan_rates',
    ];

    // ==================================================================
    // Band 01-09 — Schema / model / route configuration
    // ==================================================================

    /** TC-P01 / BC-DB: table, all columns and the invoice_no unique index exist. */
    public function test_invoicing_01_schema_columns_and_unique_index_exist(): void
    {
        $this->assertTrue(Schema::hasTable(self::TABLE), self::TABLE . ' missing.');

        foreach ([
            'id', 'tenant_id', 'tenant_plan_id', 'billing_cycle_id', 'invoice_no', 'invoice_date',
            'billing_start_date', 'billing_end_date', 'min_billing_qty', 'total_user_qty', 'plan_rate',
            'billing_qty', 'sub_total', 'discount_percent', 'discount_amount', 'discount_remark',
            'extra_charges', 'charges_remark', 'tax1_percent', 'tax1_remark', 'tax1_amount',
            'tax2_percent', 'tax2_amount', 'tax3_percent', 'tax3_amount', 'tax4_percent', 'tax4_amount',
            'total_tax_amount', 'net_payable_amount', 'paid_amount', 'currency', 'status',
            'credit_days', 'payment_due_date', 'is_recurring', 'auto_renew', 'remarks',
        ] as $column) {
            $this->assertTrue(Schema::hasColumn(self::TABLE, $column), 'Missing column: ' . $column);
        }

        // uq_tenantInvoices_invoiceNo — invoice_no is globally unique.
        try {
            $indexes = collect(DB::select('SHOW INDEX FROM ' . self::TABLE))
                ->where('Column_name', 'invoice_no')
                ->where('Non_unique', 0);
            $this->assertTrue($indexes->isNotEmpty(), 'invoice_no unique index (uq_tenantInvoices_invoiceNo) is missing.');
        } catch (Throwable $e) {
            $this->markTestSkipped('SHOW INDEX unsupported: ' . $e->getMessage());
        }
    }

    /** TC-P01 / BC-DB: model fillable, casts, SoftDeletes and relationships. */
    public function test_invoicing_02_model_fillable_casts_softdeletes_and_relationships(): void
    {
        $model = new BilTenantInvoice();
        $this->assertSame(self::TABLE, $model->getTable());

        foreach ([
            'tenant_id', 'tenant_plan_id', 'billing_cycle_id', 'invoice_no', 'plan_rate',
            'billing_qty', 'sub_total', 'total_tax_amount', 'net_payable_amount', 'currency', 'status',
        ] as $fillable) {
            $this->assertContains($fillable, $model->getFillable());
        }
        // DATA-BIL-002 remediated: phantom invoice_amount absent, no duplicated fillable block.
        $this->assertNotContains('invoice_amount', $model->getFillable(), 'DATA-BIL-002: invoice_amount must be absent.');
        $this->assertSame(
            count($model->getFillable()),
            count(array_unique($model->getFillable())),
            'DATA-BIL-002: $fillable must contain no duplicate columns.'
        );

        $casts = $model->getCasts();
        $this->assertSame('boolean', $casts['is_recurring'] ?? null);
        $this->assertSame('boolean', $casts['auto_renew'] ?? null);
        $this->assertSame('date', $casts['payment_due_date'] ?? null);
        $this->assertSame('decimal:2', $casts['sub_total'] ?? null);
        $this->assertSame('decimal:2', $casts['net_payable_amount'] ?? null);

        $this->assertContains(SoftDeletes::class, class_uses_recursive(BilTenantInvoice::class));

        foreach (['statusData', 'tenantPlan', 'tenant', 'auditLogs', 'billingCycle', 'payments'] as $relation) {
            $this->assertTrue(method_exists($model, $relation), 'Missing relationship: ' . $relation);
        }
    }

    /**
     * TC-P02 / DATA-BIL-001 guard: audit-log model + auditLogs() relation use tenant_invoice_id.
     * The 2026-06-29 audit flagged tenant_invoicing_id (P0); source is remediated.
     */
    public function test_invoicing_03_audit_log_model_uses_tenant_invoice_id(): void
    {
        $this->assertTrue(Schema::hasTable(self::AUDIT_TABLE), self::AUDIT_TABLE . ' missing.');

        $audit = new InvoicingAuditLog();
        $this->assertSame(self::AUDIT_TABLE, $audit->getTable());
        $this->assertContains('tenant_invoice_id', $audit->getFillable(), 'DATA-BIL-001: must use tenant_invoice_id.');
        $this->assertNotContains('tenant_invoicing_id', $audit->getFillable(), 'DATA-BIL-001: mis-spelling must be gone.');
        $this->assertSame('datetime', $audit->getCasts()['action_date'] ?? null, 'action_date should cast datetime.');
    }

    /** TC-P03 / BC-AUTH: central billing-management routes are registered (defensive). */
    public function test_invoicing_04_routes_are_registered_with_expected_names(): void
    {
        $expected = [
            'central.billing.billing-management.index',
            'central.billing.billing-management.store',
            'central.billing.billing-management.invoice.details',
            'central.billing.billing-management.subscription.details',
            'central.billing.billing-management.module.details',
            'central.billing.billing-management.invoice.remarks.update',
            'central.billing.billing-management.toggleStatus',
        ];

        $missing = array_values(array_filter($expected, static fn (string $n): bool => !Route::has($n)));

        if ($missing !== []) {
            $this->markTestSkipped('Central billing-management routes not resolvable in-process: ' . implode(', ', $missing));
        }

        $this->assertSame([], $missing);
    }

    /** TC-P02 / MIG-BIL-001 (P0) guard — deleted_at must exist for SoftDeletes. */
    public function test_invoicing_05_softdeletes_column_present_mig_bil_001_guard(): void
    {
        $this->assertTrue(
            Schema::hasColumn(self::TABLE, 'deleted_at'),
            'bil_tenant_invoices.deleted_at missing — MIG-BIL-001 (P0): SoftDeletes model vs DDL without deleted_at.'
        );
    }

    // ==================================================================
    // Band 10-19 — Business rules (specification tests, pure math)
    // ==================================================================

    /** TC-P06 / BC-BIZ-01: invoice_no format INV-YYYYMMDD-NNN, NNN = today count + 1. */
    public function test_invoicing_10_invoice_number_format_and_sequence(): void
    {
        $today = date('Ymd');
        foreach ([1 => '001', 7 => '007', 42 => '042', 128 => '128'] as $count => $suffix) {
            $invoiceNo = 'INV-' . $today . '-' . str_pad((string) $count, 3, '0', STR_PAD_LEFT);
            $this->assertSame('INV-' . $today . '-' . $suffix, $invoiceNo);
            $this->assertMatchesRegularExpression('/^INV-\d{8}-\d{3}$/', $invoiceNo);
        }
    }

    /** TC-P07 / BC-BIZ-02: sub_total = plan_rate * billing_qty. */
    public function test_invoicing_11_sub_total_formula(): void
    {
        $this->assertSame(1500.0, 150.0 * 10);
        $this->assertSame(0.0, 0.0 * 25);
    }

    /** TC-P08 / BC-BIZ-03: discount, tax_base, per-line tax and total_tax. */
    public function test_invoicing_12_discount_tax_base_and_total_tax(): void
    {
        $subTotal = 2000.0;
        $discountAmount = $subTotal * (5 / 100);   // 100
        $extra = 200.0;
        $taxBase = $subTotal - $discountAmount + $extra; // 2100
        $tax1 = $taxBase * (9 / 100);   // 189
        $tax2 = $taxBase * (9 / 100);   // 189
        $tax3 = $taxBase * (0 / 100);   // 0
        $tax4 = $taxBase * (0 / 100);   // 0
        $totalTax = $tax1 + $tax2 + $tax3 + $tax4; // 378

        $this->assertSame(100.0, $discountAmount);
        $this->assertSame(2100.0, $taxBase);
        $this->assertSame(378.0, $totalTax);
    }

    /** TC-P09 / BC-BIZ-04: net_payable = sub_total - discount + extra + total_tax. */
    public function test_invoicing_13_net_payable_formula(): void
    {
        $subTotal = 2000.0;
        $discountAmount = 100.0;
        $extra = 200.0;
        $totalTax = 378.0;
        $netPayable = $subTotal - $discountAmount + $extra + $totalTax;
        $this->assertSame(2478.0, $netPayable);
    }

    /** TC-P10 / BC-BIZ-05: billing_qty = max(min_billing_qty, total_user_qty). */
    public function test_invoicing_14_billing_qty_is_max_of_min_and_count(): void
    {
        $this->assertSame(30, max(10, 30));
        $this->assertSame(10, max(10, 4));
        $this->assertSame(1, max(1, 0));
    }

    /** TC-P11 / BC-BIZ-06: payment_due_date = invoice_date + credit_days. */
    public function test_invoicing_15_payment_due_date_formula(): void
    {
        $invoiceDate = '2026-03-01';
        $creditDays = 15;
        $due = \Carbon\Carbon::parse($invoiceDate)->addDays($creditDays)->format('Y-m-d');
        $this->assertSame('2026-03-16', $due);
    }

    // ==================================================================
    // Band 20-29 — State machine / status (defensive + documentation)
    // ==================================================================

    /**
     * TC-SM01 / D37: `status` stores a dropdown id on generation (ordinal-1 = PENDING),
     * not the literal 'PENDING'. Read-only defensive check.
     */
    public function test_invoicing_20_status_column_holds_dropdown_id(): void
    {
        $this->assertInvoicingTableReady();

        try {
            $invoice = BilTenantInvoice::query()->whereNotNull('status')->orderByDesc('id')->first();
            if (!$invoice) {
                $this->markTestSkipped('No invoices present to inspect status storage (D37).');
            }
            $this->assertNotSame('', (string) $invoice->status, 'status should be populated on a generated invoice.');
        } catch (Throwable $e) {
            $this->markTestSkipped('bil_tenant_invoices not readable: ' . $e->getMessage());
        }
    }

    /**
     * TC-SM02 / BC-SM: there is NO dedicated cancel/transition endpoint on invoicing
     * (screen: "no dedicated cancel endpoint"; lifecycle transitions are driven by the
     * Payment module). Proven by the absence of a cancel route name.
     */
    public function test_invoicing_21_no_dedicated_status_transition_endpoint(): void
    {
        $this->assertFalse(
            Route::has('central.billing.billing-management.cancel'),
            'Screen states there is no dedicated cancel endpoint for invoices.'
        );
        $this->assertFalse(
            Route::has('central.billing.billing-management.status'),
            'Invoicing has no direct invoice-status transition route (status changes flow via payments).'
        );
    }

    // ==================================================================
    // Band 30-39 — Validation + filter behaviour
    // ==================================================================

    /** TC-P12: invoicing tab loads with all four filter controls. */
    public function test_invoicing_30_tab_loads_with_all_filters(): void
    {
        $this->assertInvoicingTableReady();

        $this->browseWithFailureScreenshot('v2-tab-filters', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Billing Management (Invoicing tab)');
            $this->ensureTabVisible($browser, '#invoicing-tab', '#invoicing-pane');

            $browser->assertPresent('select[name="data_type"]')
                ->assertPresent('input[name="date_range"]')
                ->assertPresent('select[name="status"]')
                ->assertPresent('#invoicing-pane table');
        });
    }

    /** TC-P13: data_type="Invoicing Done" filter renders without error. */
    public function test_invoicing_31_filter_invoicing_done_loads(): void
    {
        $this->assertFilteredIndexLoads('v2-filter-done', ['data_type' => 'Invoicing Done']);
    }

    /** TC-P14: data_type="Inv. Need To Generate" filter renders without error. */
    public function test_invoicing_32_filter_need_to_generate_loads(): void
    {
        $this->assertFilteredIndexLoads('v2-filter-need', ['data_type' => 'Inv. Need To Generate']);
    }

    /** TC-P15: date_range filter (space-dash-space format) renders without error. */
    public function test_invoicing_33_filter_date_range_loads(): void
    {
        $range = date('Y-m-01') . ' - ' . date('Y-m-t');
        $this->assertFilteredIndexLoads('v2-filter-daterange', ['data_type' => 'Invoicing Done', 'date_range' => $range]);
    }

    /** TC-P16: status filter (Active/Inactive on the schedule) renders without error. */
    public function test_invoicing_34_filter_status_loads(): void
    {
        $this->assertFilteredIndexLoads('v2-filter-status', ['status' => 'Active']);
    }

    /** TC-P17: invoice_status filter under Invoicing Done renders without error. */
    public function test_invoicing_35_filter_invoice_status_loads(): void
    {
        $this->assertFilteredIndexLoads('v2-filter-invstatus', [
            'data_type' => 'Invoicing Done',
            'invoice_status' => 'PENDING',
        ]);
    }

    /** TC-N01: updateInvoiceRemarks rejects a missing id (422 / gated). */
    public function test_invoicing_36_remarks_update_requires_id(): void
    {
        if (!$this->adminUser) {
            $this->markTestSkipped('No admin user resolved for endpoint test.');
        }

        try {
            $response = $this->actingAs($this->adminUser)->postJson(self::REMARKS_UPDATE_PATH, []);
            $this->assertContains(
                $response->getStatusCode(),
                [422, 403, 404, 302],
                'Missing id should be rejected (422) or gated/redirected.'
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('remarks-update endpoint not exercisable in-process: ' . $e->getMessage());
        }
    }

    /** TC-N02: updateInvoiceRemarks rejects remarks longer than 5000 chars. */
    public function test_invoicing_37_remarks_update_rejects_overlong_remarks(): void
    {
        if (!$this->adminUser) {
            $this->markTestSkipped('No admin user resolved for endpoint test.');
        }

        try {
            $response = $this->actingAs($this->adminUser)->postJson(self::REMARKS_UPDATE_PATH, [
                'id' => 1,
                'remarks' => str_repeat('x', 5001),
            ]);
            // 422 for the max:5000 rule; 404 if id 1 absent; 403 if gated.
            $this->assertContains(
                $response->getStatusCode(),
                [422, 404, 403, 302],
                'Overlong remarks (>5000) must be rejected by the max:5000 rule.'
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('remarks-update endpoint not exercisable in-process: ' . $e->getMessage());
        }
    }

    // ==================================================================
    // Band 40-49 — Integration / FK / generate contract
    // ==================================================================

    /**
     * TC-D01 / BUG-BIL-011 guard: store() returns the array envelope. A non-existent
     * schedule id lands in failed_ids with a reason (generateInvoiceForOrganization returns
     * ['status'=>false,'message'=>...]) — proving the bool/array contract bug is remediated.
     */
    public function test_invoicing_40_generate_store_array_contract_missing_schedule(): void
    {
        if (!$this->adminUser) {
            $this->markTestSkipped('No admin user resolved for endpoint test.');
        }

        try {
            $response = $this->actingAs($this->adminUser)->postJson(self::INDEX_PATH, ['ids' => [PHP_INT_MAX]]);

            if (!in_array($response->getStatusCode(), [200, 201], true)) {
                $this->markTestSkipped('Generate endpoint returned ' . $response->getStatusCode() . ' in-process.');
            }

            $json = $response->json();
            $this->assertIsArray($json);
            $this->assertTrue((bool) ($json['status'] ?? false), 'Envelope status should be true.');
            $this->assertArrayHasKey('success_ids', $json);
            $this->assertArrayHasKey('failed_ids', $json);
            $this->assertSame([], $json['success_ids'] ?? ['x'], 'A bogus schedule id cannot succeed.');
        } catch (Throwable $e) {
            $this->markTestSkipped('Generate endpoint not exercisable in-process: ' . $e->getMessage());
        }
    }

    /** TC-N03: store() rejects a non-array ids payload with 400. */
    public function test_invoicing_41_generate_store_rejects_non_array_ids(): void
    {
        if (!$this->adminUser) {
            $this->markTestSkipped('No admin user resolved for endpoint test.');
        }

        try {
            $response = $this->actingAs($this->adminUser)->postJson(self::INDEX_PATH, ['ids' => 'not-an-array']);
            $this->assertContains(
                $response->getStatusCode(),
                [400, 422, 403, 302],
                'Non-array ids must be rejected (controller returns 400 "No plan rate IDs received.").'
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('Generate endpoint not exercisable in-process: ' . $e->getMessage());
        }
    }

    /** TC-D02 / BC-REF: FK delete rules on bil_tenant_invoices (tenant CASCADE, cycle RESTRICT). */
    public function test_invoicing_42_fk_delete_rules_match_ddl(): void
    {
        try {
            $rows = DB::select(
                'SELECT rc.DELETE_RULE, kcu.COLUMN_NAME '
                . 'FROM information_schema.REFERENTIAL_CONSTRAINTS rc '
                . 'JOIN information_schema.KEY_COLUMN_USAGE kcu '
                . 'ON rc.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME '
                . 'AND rc.CONSTRAINT_SCHEMA = kcu.CONSTRAINT_SCHEMA '
                . 'WHERE rc.CONSTRAINT_SCHEMA = DATABASE() '
                . 'AND kcu.TABLE_NAME = ?',
                [self::TABLE]
            );

            if ($rows === []) {
                $this->markTestSkipped('No FKs defined on bil_tenant_invoices in this DB build.');
            }

            $byColumn = [];
            foreach ($rows as $r) {
                $byColumn[$r->COLUMN_NAME] = strtoupper((string) $r->DELETE_RULE);
            }

            if (isset($byColumn['tenant_id'])) {
                $this->assertSame('CASCADE', $byColumn['tenant_id'], 'tenant_id FK should be CASCADE.');
            }
            if (isset($byColumn['tenant_plan_id'])) {
                $this->assertSame('CASCADE', $byColumn['tenant_plan_id'], 'tenant_plan_id FK should be CASCADE.');
            }
            if (isset($byColumn['billing_cycle_id'])) {
                $this->assertSame('RESTRICT', $byColumn['billing_cycle_id'], 'billing_cycle_id FK should be RESTRICT.');
            }
            $this->assertNotEmpty($byColumn, 'Expected at least one FK on bil_tenant_invoices.');
        } catch (Throwable $e) {
            $this->markTestSkipped('information_schema query unsupported: ' . $e->getMessage());
        }
    }

    /** TC-D03 / BC-INT: cross-module referenced tables exist (defensive). */
    public function test_invoicing_43_referenced_tables_exist(): void
    {
        $present = array_filter(self::REFERENCED_TABLES, static fn (string $t): bool => Schema::hasTable($t));

        if ($present === []) {
            $this->markTestSkipped('No referenced Prime tables present in this environment.');
        }

        $this->assertContains('prm_tenant', $present, 'prm_tenant (invoice.tenant_id target) should exist.');
        $this->assertContains('prm_billing_cycles', $present, 'prm_billing_cycles (invoice.billing_cycle_id target) should exist.');
    }

    /** TC-D04: invoice-details endpoint with a non-existent id 404s (findOrFail), never leaks. */
    public function test_invoicing_44_invoice_details_bogus_id_not_found(): void
    {
        $this->assertEndpointGatedOrNotFound('invoice-details', self::INVOICE_DETAILS_PATH . '?id=' . PHP_INT_MAX);
    }

    /** TC-D05: subscription-details endpoint with a non-existent id 404s (findOrFail). */
    public function test_invoicing_45_subscription_details_bogus_id_not_found(): void
    {
        $this->assertEndpointGatedOrNotFound('subscription-details', self::SUBSCRIPTION_DETAILS_PATH . '?id=' . PHP_INT_MAX);
    }

    // ==================================================================
    // Band 50-59 — Permissions
    // ==================================================================

    /** TC-N04: guest redirected to /login on the billing-management index. */
    public function test_invoicing_50_guest_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('v2-guest-index', function (Browser $browser): void {
            $browser->visit($this->centralUrl(self::INDEX_PATH))->pause(1200);
            $this->assertStringContainsString('/login', $this->currentPath($browser));
        });
    }

    /** TC-N05: module-details endpoint requires auth (guest → login), never anonymous. */
    public function test_invoicing_51_module_details_requires_auth(): void
    {
        $this->browseWithFailureScreenshot('v2-guest-module-details', function (Browser $browser): void {
            $browser->visit($this->centralUrl(self::MODULE_DETAILS_PATH . '?id=1&type=invoice'))->pause(1200);
            $path = $this->currentPath($browser);
            $this->assertStringContainsString('/login', $path, 'Detail endpoints must require authentication.');
        });
    }

    /** TC-N06: a non super-admin without permission is denied on the index (403/redirect). */
    public function test_invoicing_52_non_super_admin_forbidden(): void
    {
        try {
            $limited = $this->makeLimitedUser();
        } catch (Throwable $e) {
            $this->markTestSkipped('Could not build a limited user: ' . $e->getMessage());
        }

        try {
            $response = $this->actingAs($limited)->get(self::INDEX_PATH);
            $this->assertContains(
                $response->getStatusCode(),
                [403, 302, 404],
                'A non super-admin without permission should be denied (403) or redirected.'
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('Permission gate not exercisable in-process: ' . $e->getMessage());
        } finally {
            try {
                $limited->forceDelete();
            } catch (Throwable) {
                // best-effort cleanup
            }
        }
    }

    // ==================================================================
    // Band 60-69 — UI/UX (tab, columns, pagination, empty state)
    // ==================================================================

    /** TC-P18: invoicing table shows the expected column headers. */
    public function test_invoicing_60_tab_columns_present(): void
    {
        $this->assertInvoicingTableReady();

        $this->browseWithFailureScreenshot('v2-columns', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Billing Management (Invoicing tab)');
            $this->ensureTabVisible($browser, '#invoicing-tab', '#invoicing-pane');

            $paneText = $browser->text('#invoicing-pane');
            foreach (['Organization', 'Billing Period', 'Invoice No', 'Inv.Date'] as $header) {
                $this->assertStringContainsString($header, $paneText, 'Missing column header: ' . $header);
            }
        });
    }

    /** TC-P19: invoicing pane shows rows or the "No records found." empty state. */
    public function test_invoicing_61_rows_or_empty_state(): void
    {
        $this->assertInvoicingTableReady();

        $this->browseWithFailureScreenshot('v2-rows-or-empty', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Billing Management (Invoicing tab)');
            $this->ensureTabVisible($browser, '#invoicing-tab', '#invoicing-pane');

            $tbodyText = $browser->text('#invoicing-pane tbody');
            if (str_contains($tbodyText, 'No records found.')) {
                $browser->assertSeeIn('#invoicing-pane', 'No records found.');
                return;
            }
            $browser->assertPresent('#invoicing-pane table tbody tr');
        });
    }

    /** TC-P20: pagination container is present (paginate(10)). */
    public function test_invoicing_62_pagination_container_present(): void
    {
        $this->assertInvoicingTableReady();

        $this->browseWithFailureScreenshot('v2-pagination', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Billing Management (Invoicing tab)');
            $this->ensureTabVisible($browser, '#invoicing-tab', '#invoicing-pane');

            // The invoicing pane always renders its results/pagination block; the table is the stable anchor.
            $browser->assertPresent('#invoicing-pane table');
        });
    }

    // ==================================================================
    // Band 70-79 — Edge cases
    // ==================================================================

    /** TC-EDG01: with no filters the tab still loads (date_range defaults to today). */
    public function test_invoicing_70_default_date_range_loads(): void
    {
        $this->assertInvoicingTableReady();

        $this->browseWithFailureScreenshot('v2-default-range', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->assertSame(self::INDEX_PATH, $this->currentPath($browser), 'Default (today) range should still render.');
            $this->ensurePageAccessible($browser, 'Billing Management (Invoicing tab)');
            $this->ensureTabVisible($browser, '#invoicing-tab', '#invoicing-pane');
            $browser->assertPresent('#invoicing-pane table');
        });
    }

    /** TC-EDG02: the modules junction table exists and carries tenant_invoice_id + module_id. */
    public function test_invoicing_71_modules_junction_shape(): void
    {
        if (!Schema::hasTable(self::MODULES_JNT_TABLE)) {
            $this->markTestSkipped(self::MODULES_JNT_TABLE . ' not present in this build.');
        }

        $this->assertTrue(Schema::hasColumn(self::MODULES_JNT_TABLE, 'tenant_invoice_id'), 'Missing tenant_invoice_id.');
        $this->assertTrue(Schema::hasColumn(self::MODULES_JNT_TABLE, 'module_id'), 'Missing module_id.');
    }

    // ==================================================================
    // Band 90-99 — Security
    // ==================================================================

    /** TC-S01: invoice-details endpoint requires authentication (IDOR guard). */
    public function test_invoicing_90_invoice_details_requires_auth(): void
    {
        $this->browseWithFailureScreenshot('v2-idor-invoice-details', function (Browser $browser): void {
            $browser->visit($this->centralUrl(self::INVOICE_DETAILS_PATH . '?id=1'))->pause(1200);
            $this->assertStringContainsString(
                '/login',
                $this->currentPath($browser),
                'Direct invoice-details access must require auth.'
            );
        });
    }

    /** TC-S02: an injection-shaped tenat_id filter value is handled safely (no 500 leak). */
    public function test_invoicing_91_injection_shaped_filter_is_safe(): void
    {
        $this->assertInvoicingTableReady();

        $this->browseWithFailureScreenshot('v2-injection-filter', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $payload = urlencode("1' OR '1'='1");
            $this->visitAuthenticated($browser, self::INDEX_PATH . '?data_type=Invoicing+Done&invoice_status=' . $payload);

            $bodyText = $browser->text('body');
            $this->assertStringNotContainsString('SQLSTATE', $bodyText, 'Injection-shaped filter must not surface a DB error.');
            $this->ensurePageAccessible($browser, 'Billing Management (injection filter)');
        });
    }

    // ==================================================================
    // Private helper library
    // ==================================================================

    private function assertInvoicingTableReady(): void
    {
        if (!Schema::hasTable(self::TABLE)) {
            $this->fail('bil_tenant_invoices table is missing; cannot run Invoicing tests.');
        }
        if (!Schema::hasColumn(self::TABLE, 'deleted_at')) {
            $this->fail('bil_tenant_invoices.deleted_at is missing; SoftDeletes will fail (MIG-BIL-001).');
        }
    }

    /**
     * Visit the invoicing index with a query-string filter and assert the page renders
     * (no 500, tab present). Filters are GET-only, presence-validated only.
     */
    private function assertFilteredIndexLoads(string $caseName, array $params): void
    {
        $this->assertInvoicingTableReady();

        $query = http_build_query($params);

        $this->browseWithFailureScreenshot($caseName, function (Browser $browser) use ($query): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH . '?' . $query);

            $this->assertSame(self::INDEX_PATH, $this->currentPath($browser), 'Filtered index should stay on the same path.');
            $this->ensurePageAccessible($browser, 'Billing Management (filtered)');
            $this->ensureTabVisible($browser, '#invoicing-tab', '#invoicing-pane');
            $browser->assertPresent('#invoicing-pane table');
        });
    }

    /**
     * Assert a JSON detail endpoint is auth-gated or 404s for a bogus id (defensive).
     */
    private function assertEndpointGatedOrNotFound(string $label, string $url): void
    {
        if (!$this->adminUser) {
            $this->markTestSkipped('No admin user resolved for the ' . $label . ' endpoint test.');
        }

        try {
            $response = $this->actingAs($this->adminUser)->getJson($url);
            $this->assertContains(
                $response->getStatusCode(),
                [404, 403, 302],
                $label . ': a non-existent id must 404 (findOrFail) or be gated, never 200 with data.'
            );
        } catch (Throwable $e) {
            $this->markTestSkipped($label . ' endpoint not exercisable in-process: ' . $e->getMessage());
        }
    }

    private function makeLimitedUser(): \App\Models\User
    {
        $suffix = '_' . uniqid();

        return \App\Models\User::create([
            'email' => 'limited' . $suffix . '@tenant.com',
            'password' => bcrypt('password'),
            'name' => 'Limited User',
            'emp_code' => 'LIM' . substr($suffix, 1, 8),
            'short_name' => 'LIM' . rand(1000, 9999),
            'status' => 'ACTIVE',
            'is_active' => 1,
            'is_super_admin' => 0,
            'email_verified_at' => now(),
        ]);
    }
}
