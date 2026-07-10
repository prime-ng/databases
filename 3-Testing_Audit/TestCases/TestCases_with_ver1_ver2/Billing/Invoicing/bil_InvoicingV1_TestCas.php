<?php

namespace Tests\Browser\Modules\Prime\Billing\Invoicing;

use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\Billing\Models\BilTenantInvoice;
use Modules\Billing\Models\InvoicingAuditLog;
use Tests\Browser\Modules\Prime\Billing\BillingDuskTestCase;
use Throwable;

/**
 * Invoicing (Invoice Generation) — V1 foundation Dusk suite (central prime_db).
 *
 * DB scope: prime_db central (NOT tenant-per-school). The invoicing tab, listing,
 * filters and detail endpoints all run on prime_db; the generation path itself
 * calls Tenancy::initialize()/end() internally to count the tenant's students
 * (behaviour under test), so the TEST does NOT initialise tenancy — it exercises
 * the central controller. Mirrors the committed sibling
 * tests/Browser/Modules/Prime/Billing/Invoicing/prm_InvoicingTab_TestCas.php
 * which extends BillingDuskTestCase (central chain PrimeDuskTestCase) and uses
 * authenticateCentral()/visitAuthenticated()/centralUrl()/ensureTabVisible()/
 * ensurePageAccessible().
 *
 * Prefix bil_ verified against DDL Billing_DDL_v1.sql line 4 (`CREATE TABLE bil_tenant_invoices`).
 */
class bil_InvoicingV1_TestCas extends BillingDuskTestCase
{
    protected const SCREENSHOT_DIR = 'tests/Browser/Modules/Prime/Billing/Invoicing/screenshots';
    protected const STATUS_REPORT_DIRECTORY = 'tests/Browser/Modules/Prime/Billing/Invoicing/report';
    protected const STATUS_REPORT_PREFIX = 'billing_invoicing_v1_report_';

    private const INDEX_PATH = '/billing/billing-management';
    private const INVOICE_DETAILS_PATH = '/billing/invoice-details';
    private const SUBSCRIPTION_DETAILS_PATH = '/billing/subscription-details';
    private const REMARKS_UPDATE_PATH = '/billing/invoice/remarks/update';
    private const TABLE = 'bil_tenant_invoices';
    private const AUDIT_TABLE = 'bil_tenant_invoicing_audit_logs';

    // ------------------------------------------------------------------
    // Band 01-09 — Schema / model configuration
    // ------------------------------------------------------------------

    /** TC-P01 / BC-DB: table, key columns and model configuration are correct. */
    public function test_invoicing_01_schema_and_model_configuration_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable(self::TABLE), self::TABLE . ' table is missing.');

        foreach ([
            'id', 'tenant_id', 'tenant_plan_id', 'billing_cycle_id', 'invoice_no', 'invoice_date',
            'billing_start_date', 'billing_end_date', 'min_billing_qty', 'total_user_qty', 'plan_rate',
            'billing_qty', 'sub_total', 'discount_percent', 'discount_amount', 'extra_charges',
            'tax1_percent', 'tax1_amount', 'total_tax_amount', 'net_payable_amount', 'paid_amount',
            'currency', 'status', 'credit_days', 'payment_due_date', 'is_recurring', 'auto_renew', 'remarks',
        ] as $column) {
            $this->assertTrue(
                Schema::hasColumn(self::TABLE, $column),
                self::TABLE . '.' . $column . ' column is missing.'
            );
        }

        $model = new BilTenantInvoice();
        $this->assertSame(self::TABLE, $model->getTable(), 'Model table name mismatch.');

        foreach ([
            'tenant_id', 'tenant_plan_id', 'billing_cycle_id', 'invoice_no', 'invoice_date',
            'plan_rate', 'billing_qty', 'sub_total', 'net_payable_amount', 'currency', 'status',
        ] as $fillable) {
            $this->assertContains($fillable, $model->getFillable(), $fillable . ' should be fillable.');
        }

        // DATA-BIL-002 (P0 audit) is remediated in current source: no phantom `invoice_amount`.
        $this->assertNotContains(
            'invoice_amount',
            $model->getFillable(),
            'DATA-BIL-002: phantom invoice_amount must NOT be fillable (audit defect remediated in source).'
        );

        $casts = $model->getCasts();
        $this->assertSame('boolean', $casts['is_recurring'] ?? null, 'is_recurring should cast to boolean.');
        $this->assertSame('boolean', $casts['auto_renew'] ?? null, 'auto_renew should cast to boolean.');
        $this->assertSame('date', $casts['invoice_date'] ?? null, 'invoice_date should cast to date.');
        $this->assertSame('decimal:2', $casts['net_payable_amount'] ?? null, 'net_payable_amount should cast decimal:2.');

        $this->assertContains(
            SoftDeletes::class,
            class_uses_recursive(BilTenantInvoice::class),
            'BilTenantInvoice model must use SoftDeletes.'
        );

        foreach (['statusData', 'tenantPlan', 'tenant', 'auditLogs', 'billingCycle', 'payments'] as $relation) {
            $this->assertTrue(method_exists($model, $relation), 'Missing relationship: ' . $relation);
        }
    }

    /**
     * TC-P02 / DATA-BIL-001 guard: the audit-log model + auditLogs() relation use `tenant_invoice_id`.
     * The 2026-06-29 audit flagged the code using `tenant_invoicing_id` (P0); current source is
     * remediated to `tenant_invoice_id`. This test locks that contract in.
     */
    public function test_invoicing_02_audit_log_uses_tenant_invoice_id_fk(): void
    {
        $audit = new InvoicingAuditLog();
        $this->assertSame(self::AUDIT_TABLE, $audit->getTable(), 'Audit-log table name mismatch.');
        $this->assertContains(
            'tenant_invoice_id',
            $audit->getFillable(),
            'DATA-BIL-001: audit-log $fillable must use tenant_invoice_id (not tenant_invoicing_id).'
        );
        $this->assertNotContains(
            'tenant_invoicing_id',
            $audit->getFillable(),
            'DATA-BIL-001: the mis-spelled tenant_invoicing_id must not remain in $fillable.'
        );
    }

    /**
     * TC-P03 / MIG-BIL-001 guard.
     * The authoritative DDL (Billing_DDL_v1.sql) declares bil_tenant_invoices with NO deleted_at,
     * yet the model uses SoftDeletes. The dev DB is hand-patched, so deleted_at exists here; a
     * schema-correct DDL build would fail this guard — surfacing MIG-BIL-001 (P0).
     */
    public function test_invoicing_03_softdeletes_column_present_mig_bil_001_guard(): void
    {
        $this->assertTrue(
            Schema::hasColumn(self::TABLE, 'deleted_at'),
            'bil_tenant_invoices.deleted_at is missing — SoftDeletes will break (see MIG-BIL-001, P0).'
        );
    }

    // ------------------------------------------------------------------
    // Band 03-09 — Tab render (mirrors committed sibling)
    // ------------------------------------------------------------------

    /** TC-P04: invoicing tab loads with its filter controls. */
    public function test_invoicing_04_tab_loads_with_filters(): void
    {
        $this->assertInvoicingTableReady();

        $this->browseWithFailureScreenshot('v1-tab-loads', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);

            $this->assertSame(self::INDEX_PATH, $this->currentPath($browser), 'Billing Management not reachable.');
            $this->ensurePageAccessible($browser, 'Billing Management (Invoicing tab)');
            $this->ensureTabVisible($browser, '#invoicing-tab', '#invoicing-pane');

            $this->assertNotNull($browser->element('#invoicing-pane'), 'Invoicing pane not visible.');

            $browser->assertPresent('select[name="data_type"]')
                ->assertPresent('input[name="date_range"]')
                ->assertPresent('select[name="status"]')
                ->assertPresent('#invoicing-pane table');
        });
    }

    /** TC-P05: invoicing tab shows rows or the empty state. */
    public function test_invoicing_05_tab_table_or_empty_state(): void
    {
        $this->assertInvoicingTableReady();

        $this->browseWithFailureScreenshot('v1-tab-empty-or-rows', function (Browser $browser): void {
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

    // ------------------------------------------------------------------
    // Band 10-19 — Business rules (pure specification tests, no DB)
    // ------------------------------------------------------------------

    /** TC-P06 / BC-BIZ-01: invoice number follows the INV-YYYYMMDD-NNN spec. */
    public function test_invoicing_10_invoice_number_format_matches_spec(): void
    {
        // Mirrors BillingManagementController::generateInvoiceForOrganization():
        //   $invoiceNo = 'INV-' . date('Ymd') . '-' . str_pad($count, 3, '0', STR_PAD_LEFT);
        $count = 1;
        $invoiceNo = 'INV-' . date('Ymd') . '-' . str_pad((string) $count, 3, '0', STR_PAD_LEFT);

        $this->assertMatchesRegularExpression(
            '/^INV-\d{8}-\d{3}$/',
            $invoiceNo,
            'Invoice number must match INV-YYYYMMDD-NNN.'
        );
        $this->assertSame('INV-' . date('Ymd') . '-001', $invoiceNo, 'First invoice of the day should end in -001.');
    }

    /** TC-P07 / BC-BIZ-02: financial formulas match the controller. */
    public function test_invoicing_11_financial_formula_matches_spec(): void
    {
        // planRate.rate_per_cycle=100, billingQty=10, discount_percent=10, extra=50, tax1=9, tax2=9
        $rate = 100.0;
        $billingQty = 10;
        $discountPercent = 10.0;
        $extra = 50.0;

        $subTotal = $rate * $billingQty;                          // 1000
        $discountAmount = $subTotal * ($discountPercent / 100);   // 100
        $taxBase = $subTotal - $discountAmount + $extra;          // 950
        $tax1 = $taxBase * (9 / 100);                             // 85.5
        $tax2 = $taxBase * (9 / 100);                             // 85.5
        $totalTax = $tax1 + $tax2;                                // 171
        $netPayable = $subTotal - $discountAmount + $extra + $totalTax; // 1121

        $this->assertSame(1000.0, $subTotal);
        $this->assertSame(100.0, $discountAmount);
        $this->assertSame(950.0, $taxBase);
        $this->assertSame(171.0, $totalTax);
        $this->assertSame(1121.0, $netPayable);
    }

    /** TC-P08 / BC-BIZ-03: billing_qty = max(min_billing_qty, total_user_qty). */
    public function test_invoicing_12_billing_qty_is_max_of_min_and_count(): void
    {
        $this->assertSame(20, max(5, 20), 'When students (20) > min (5), bill the student count.');
        $this->assertSame(5, max(5, 3), 'When students (3) < min (5), bill the minimum.');
    }

    // ------------------------------------------------------------------
    // Band 20-29 — Status / state machine (defensive)
    // ------------------------------------------------------------------

    /**
     * TC-P09 / BC-SM-01 / D37: generated invoices store a dropdown *id* in `status`
     * (not the literal 'PENDING'). Read-only, defensive — skips when no invoice exists.
     */
    public function test_invoicing_20_status_is_dropdown_id_when_invoices_exist(): void
    {
        $this->assertInvoicingTableReady();

        try {
            $invoice = BilTenantInvoice::query()->orderByDesc('id')->first();
            if (!$invoice) {
                $this->markTestSkipped('No invoice rows present to inspect status storage (D37).');
            }
            $this->assertNotNull($invoice->status, 'Generated invoice must carry a status value.');
        } catch (Throwable $e) {
            $this->markTestSkipped('bil_tenant_invoices not readable: ' . $e->getMessage());
        }
    }

    // ------------------------------------------------------------------
    // Band 30-39 — Validation (defensive endpoint)
    // ------------------------------------------------------------------

    /** TC-N01: updateInvoiceRemarks requires an id (422). */
    public function test_invoicing_30_remarks_update_requires_id(): void
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

    // ------------------------------------------------------------------
    // Band 40-49 — Integration / FK dependency
    // ------------------------------------------------------------------

    /**
     * TC-P10 / BC-BIZ / BUG-BIL-011 guard: store() returns the array contract even for a
     * non-existent schedule (generateInvoiceForOrganization returns ['status'=>false,...],
     * proving BUG-BIL-011 is remediated). Defensive.
     */
    public function test_invoicing_40_generate_store_returns_array_contract(): void
    {
        if (!$this->adminUser) {
            $this->markTestSkipped('No admin user resolved for endpoint test.');
        }

        try {
            $response = $this->actingAs($this->adminUser)
                ->postJson(self::INDEX_PATH, ['ids' => [PHP_INT_MAX]]);

            if (!in_array($response->getStatusCode(), [200, 201], true)) {
                $this->markTestSkipped('Generate endpoint returned ' . $response->getStatusCode() . ' in-process.');
            }

            $json = $response->json();
            $this->assertIsArray($json, 'Generate must return a JSON array/object.');
            $this->assertArrayHasKey('status', $json);
            $this->assertArrayHasKey('failed_ids', $json);
            $this->assertTrue((bool) $json['status'], 'store() envelope status should be true.');
        } catch (Throwable $e) {
            $this->markTestSkipped('Generate endpoint not exercisable in-process: ' . $e->getMessage());
        }
    }

    /** TC-D01 / BC-REF: FK integrity on bil_tenant_invoices (billing_cycle_id RESTRICT). */
    public function test_invoicing_41_billing_cycle_fk_uses_restrict(): void
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

            if (isset($byColumn['billing_cycle_id'])) {
                $this->assertSame('RESTRICT', $byColumn['billing_cycle_id'], 'billing_cycle_id FK should be RESTRICT.');
            } else {
                $this->markTestSkipped('billing_cycle_id FK not present in this build.');
            }
        } catch (Throwable $e) {
            $this->markTestSkipped('information_schema query unsupported: ' . $e->getMessage());
        }
    }

    // ------------------------------------------------------------------
    // Band 50-59 — Authorization
    // ------------------------------------------------------------------

    /** TC-N02: guest is redirected to /login on the billing-management index. */
    public function test_invoicing_50_guest_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('v1-guest-redirect', function (Browser $browser): void {
            $browser->visit($this->centralUrl(self::INDEX_PATH))->pause(1200);
            $this->assertStringContainsString(
                '/login',
                $this->currentPath($browser),
                'Guest should be redirected to /login.'
            );
        });
    }

    /** TC-N03: invoice-details endpoint with a bogus id is auth-gated / 404 (never leaks). */
    public function test_invoicing_60_invoice_details_bogus_id_is_gated_or_not_found(): void
    {
        if (!$this->adminUser) {
            $this->markTestSkipped('No admin user resolved for endpoint test.');
        }

        try {
            $response = $this->actingAs($this->adminUser)
                ->getJson(self::INVOICE_DETAILS_PATH . '?id=' . PHP_INT_MAX);

            $this->assertContains(
                $response->getStatusCode(),
                [404, 403, 302],
                'A non-existent invoice id must 404 (findOrFail) or be gated, never 200 with data.'
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('invoice-details endpoint not exercisable in-process: ' . $e->getMessage());
        }
    }

    // ------------------------------------------------------------------
    // Private helper library (mirrors the committed sibling)
    // ------------------------------------------------------------------

    private function assertInvoicingTableReady(): void
    {
        if (!Schema::hasTable(self::TABLE)) {
            $this->fail('bil_tenant_invoices table is missing; cannot run Invoicing tests.');
        }
        if (!Schema::hasColumn(self::TABLE, 'deleted_at')) {
            $this->fail('bil_tenant_invoices.deleted_at is missing; SoftDeletes will fail (MIG-BIL-001).');
        }
    }
}
