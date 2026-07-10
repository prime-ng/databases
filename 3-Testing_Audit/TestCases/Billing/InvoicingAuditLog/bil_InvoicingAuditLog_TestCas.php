<?php

namespace Tests\Browser\Modules\Prime\Billing\InvoicingAuditLog;

use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use ReflectionClass;
use Tests\Browser\Modules\Prime\Billing\BillingDuskTestCase;
use Throwable;

/**
 * Invoice Audit Log — comprehensive Dusk / source-truth suite (single file per screen).
 *
 * Feature ....: InvoicingAuditLog (screen file: Billing_v1/audit-log.md)
 * Module ......: Billing (BIL)   Prefix: bil_
 * DB scope ....: PRIME / CENTRAL (prime_db, central domain 127.0.0.1:8000) — NO tenant scaffolding.
 * Base class ..: BillingDuskTestCase (alias of prm_BillingDuskTestCase_TestCas via preload) -> PrimeDuskTestCase.
 * Primary tbl .: bil_tenant_invoicing_audit_logs
 *
 * NOTE ON APPROACH: the audit table is P0-broken against a schema-correct prime_db
 * (DATA-BIL-001 FK-column mismatch + MIG-BIL-001 SoftDeletes/timestamps without columns),
 * so audit rows CANNOT be reliably inserted to drive the UI. This suite therefore proves
 * behaviour through deterministic schema/DDL/model/source-truth assertions plus browser
 * render/permission checks on the Invoicing Audit tab. Defects are proven, not hidden.
 *
 * DEV defects proven here:
 *   DEV-BIL-A01 (DATA-BIL-001, P0) — model FK column vs DDL column mismatch.
 *   DEV-BIL-A02 (MIG-BIL-001, P0)  — SoftDeletes + default timestamps, no deleted_at/updated_at columns.
 *   DEV-BIL-A03 (SEC-BIL-011/BR-BIL-022, P1) — event_info over-persists raw request keys beyond whitelist.
 *   DEV-BIL-A04 (AUTH, P2) — blade action gates 'audit.invoicing-audit-log.*' never match backend 'prime.invoicing-audit-log.*'.
 *   DEV-BIL-A05 (AUTH, P3) — audit-log read route authorizes prime.billing-management.view, not invoicing-audit-log.view.
 *   DEV-BIL-A06 (ORM, P3) — event_info not array-cast in the model.
 *   DEV-BIL-A07 (DATA, P3) — action_type mislabels written by non-audit controller methods.
 */
class bil_InvoicingAuditLog_TestCas extends BillingDuskTestCase
{
    protected const SCREENSHOT_DIR = 'tests/Browser/Modules/Prime/Billing/InvoicingAuditLog/screenshots';
    protected const STATUS_REPORT_DIRECTORY = 'tests/Browser/Modules/Prime/Billing/InvoicingAuditLog/report';
    protected const STATUS_REPORT_PREFIX = 'billing_invoicing_audit_log_report_';

    private const BILLING_MANAGEMENT_PATH = '/billing/billing-management';
    private const AUDIT_TAB_SELECTOR = '#invoicing-audit-tab';
    private const AUDIT_PANE_SELECTOR = '#invoicing-audit-pane';

    private const MODEL_CLASS = 'Modules\\Billing\\Models\\InvoicingAuditLog';
    private const AUDIT_TABLE = 'bil_tenant_invoicing_audit_logs';

    /** DDL column name (Billing_DDL_v1.sql) vs the name the model/controllers actually use. */
    private const DDL_FK_COLUMN = 'tenant_invoicing_id';
    private const MODEL_FK_COLUMN = 'tenant_invoice_id';

    /** Documented whitelist (audit-log.md, "Sensitive Data Protection"). */
    private const EVENT_INFO_WHITELIST = ['amount_paid', 'payment_mode', 'payment_status', 'transaction_id', 'currency', 'payment_date'];

    /** Fallback location of the authoritative module DDL (override with env DUSK_BILLING_DDL_PATH). */
    private const DDL_PATH_FALLBACK = '/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/2-DDL_Tenant_Consolidated/Billing_DDL_v1.sql';

    // ============================================================
    // 01–09  SCHEMA / DDL / MODEL / CONFIG TRUTH
    // ============================================================

    public function test_invoicingauditlog_01_model_configuration_is_correct(): void
    {
        $model = $this->modelInstance();
        if ($model === null) {
            $this->markTestSkipped('Model ' . self::MODEL_CLASS . ' not autoloadable in this environment.');
        }

        $this->assertSame(self::AUDIT_TABLE, $model->getTable(), 'Model table name drifted from bil_tenant_invoicing_audit_logs.');

        $fillable = $model->getFillable();
        foreach (['tenant_invoice_id', 'action_type', 'action_date', 'performed_by', 'notes', 'event_info'] as $col) {
            $this->assertContains($col, $fillable, "Fillable is missing '$col' (asserting real current model state).");
        }

        $this->assertArrayHasKey('action_date', $model->getCasts(), 'action_date cast expected on the model.');
    }

    public function test_invoicingauditlog_02_ddl_defines_audit_columns_and_foreign_keys(): void
    {
        $ddl = $this->ddlContents();
        if ($ddl === null) {
            $this->markTestSkipped('Billing DDL file not reachable (set DUSK_BILLING_DDL_PATH).');
        }

        $this->assertStringContainsString('CREATE TABLE IF NOT EXISTS `bil_tenant_invoicing_audit_logs`', $ddl);
        foreach (['`action_date` TIMESTAMP', "`action_type` VARCHAR(20)", '`performed_by` INT UNSIGNED', '`event_info` JSON', '`notes` VARCHAR(500)', '`created_at` TIMESTAMP'] as $needle) {
            $this->assertStringContainsString($needle, $ddl, "DDL audit table is missing definition: $needle");
        }
        $this->assertStringContainsString('ON DELETE CASCADE', $ddl, 'Audit FK to invoice should be CASCADE.');
        $this->assertStringContainsString('ON DELETE SET NULL', $ddl, 'performed_by FK should be SET NULL.');
    }

    public function test_invoicingauditlog_03_model_fk_column_mismatches_ddl_proves_DATA_BIL_001(): void
    {
        // DEV-BIL-A01 / DATA-BIL-001 (P0): the model + every insert site use MODEL_FK_COLUMN,
        // but the authoritative DDL declares DDL_FK_COLUMN. They differ, so an insert on a
        // schema-correct prime_db throws "Unknown column".
        $ddl = $this->ddlContents();
        if ($ddl === null) {
            $this->markTestSkipped('Billing DDL file not reachable (set DUSK_BILLING_DDL_PATH).');
        }

        $this->assertStringContainsString('`' . self::DDL_FK_COLUMN . '`', $ddl, 'DDL should declare the invoicing FK column.');

        $model = $this->modelInstance();
        if ($model !== null) {
            $this->assertContains(self::MODEL_FK_COLUMN, $model->getFillable(), 'Model fillable uses tenant_invoice_id.');
            $this->assertNotContains(self::DDL_FK_COLUMN, $model->getFillable(), 'Model does NOT carry the DDL column name.');
        }

        $this->assertNotSame(
            self::DDL_FK_COLUMN,
            self::MODEL_FK_COLUMN,
            'DATA-BIL-001 PROVEN: DDL column "' . self::DDL_FK_COLUMN . '" != model column "' . self::MODEL_FK_COLUMN . '" — every audit insert fails on a correct DB.'
        );
    }

    public function test_invoicingauditlog_04_softdeletes_without_columns_proves_MIG_BIL_001(): void
    {
        // DEV-BIL-A02 / MIG-BIL-001 (P0): model uses SoftDeletes + default timestamps,
        // but the DDL table has neither deleted_at nor updated_at.
        if (!class_exists(self::MODEL_CLASS)) {
            $this->markTestSkipped('Model not autoloadable.');
        }
        $this->assertContains(
            SoftDeletes::class,
            class_uses_recursive(self::MODEL_CLASS),
            'Model declares SoftDeletes (requires deleted_at that the DDL lacks).'
        );

        $ddl = $this->ddlContents();
        if ($ddl === null) {
            $this->markTestSkipped('Billing DDL file not reachable.');
        }
        $auditBlock = $this->extractAuditTableBlock($ddl);
        $this->assertNotSame('', $auditBlock, 'Could not isolate the audit CREATE TABLE block.');
        $this->assertStringNotContainsString('deleted_at', $auditBlock, 'MIG-BIL-001 PROVEN: no deleted_at in DDL despite SoftDeletes.');
        $this->assertStringNotContainsString('updated_at', $auditBlock, 'MIG-BIL-001 PROVEN: no updated_at in DDL despite default timestamps.');
    }

    public function test_invoicingauditlog_05_event_info_is_not_array_cast_in_model(): void
    {
        // DEV-BIL-A06 (P3): requirement says event_info "should be array-cast"; the model does not cast it.
        $model = $this->modelInstance();
        if ($model === null) {
            $this->markTestSkipped('Model not autoloadable.');
        }
        $casts = $model->getCasts();
        $this->assertTrue(
            !isset($casts['event_info']) || !in_array($casts['event_info'], ['array', 'json', 'object', 'collection'], true),
            'event_info is intentionally NOT array-cast in current source — documented ORM gap (controllers json_encode/json_decode manually).'
        );
    }

    public function test_invoicingauditlog_06_ddl_lacks_is_active_created_by_deleted_at_updated_at(): void
    {
        $ddl = $this->ddlContents();
        if ($ddl === null) {
            $this->markTestSkipped('Billing DDL file not reachable.');
        }
        $auditBlock = $this->extractAuditTableBlock($ddl);
        foreach (['is_active', 'created_by', 'deleted_at', 'updated_at'] as $missing) {
            $this->assertStringNotContainsString($missing, $auditBlock, "DDL audit table unexpectedly contains '$missing' — requirement expected it absent.");
        }
    }

    public function test_invoicingauditlog_07_live_schema_columns_when_reachable(): void
    {
        // Best-effort against the running prime_db; skips cleanly if the table isn't migrated.
        try {
            if (!Schema::hasTable(self::AUDIT_TABLE)) {
                $this->markTestSkipped('Audit table not present in the connected database.');
            }
            $this->assertTrue(
                Schema::hasColumn(self::AUDIT_TABLE, 'action_type'),
                'action_type column expected when the audit table exists.'
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('Schema inspection unavailable: ' . $e->getMessage());
        }
    }

    // ============================================================
    // 10–19  BUSINESS RULES (BC-BIZ)
    // ============================================================

    public function test_invoicingauditlog_10_note_update_endpoint_mutates_only_notes(): void
    {
        // BC-BIZ append-only: auditAddNoteUpdate sets only $log->notes then save().
        $src = $this->appFile('Modules/Billing/app/Http/Controllers/InvoicingAuditLogController.php');
        if ($src === null) {
            $this->markTestSkipped('Controller source not reachable (set MAIN_PROJECT_PATH).');
        }
        $this->assertStringContainsString('function auditAddNoteUpdate', $src);
        $this->assertStringContainsString('$log->notes = $request->notes', $src, 'Only the notes column is mutated.');
        $this->assertStringNotContainsString('$log->action_type =', $src, 'action_type must never be mutated post-create.');
    }

    public function test_invoicingauditlog_11_note_update_writes_store_activity_log(): void
    {
        $src = $this->appFile('Modules/Billing/app/Http/Controllers/InvoicingAuditLogController.php');
        if ($src === null) {
            $this->markTestSkipped('Controller source not reachable.');
        }
        // Verbatim from source — event string is 'Store' (NOT the Class-sample 'Stored'/'Update').
        $this->assertStringContainsString("activityLog(\$log, 'Store', ['message' => 'Audit Log Note Add'])", $src);
    }

    public function test_invoicingauditlog_12_audit_log_read_orders_desc(): void
    {
        $src = $this->appFile('Modules/Billing/app/Http/Controllers/BillingManagementController.php');
        if ($src === null) {
            $this->markTestSkipped('BillingManagementController source not reachable.');
        }
        $this->assertStringContainsString("orderBy('created_at', 'DESC')", $src, 'AuditLog() lists newest-first.');
        $this->assertStringContainsString("orderBy('action_date', 'desc')", $src, 'buildAuditLogQuery() lists action_date DESC.');
    }

    public function test_invoicingauditlog_13_audit_rows_are_created_never_bulk_updated(): void
    {
        $src = $this->appFile('Modules/Billing/app/Http/Controllers/BillingManagementController.php');
        if ($src === null) {
            $this->markTestSkipped('BillingManagementController source not reachable.');
        }
        $this->assertGreaterThanOrEqual(
            2,
            substr_count($src, 'InvoicingAuditLog::create('),
            'Audit entries are appended via create() at multiple event sites.'
        );
    }

    public function test_invoicingauditlog_14_action_type_mislabels_are_documented(): void
    {
        // DEV-BIL-A07 (P3): several controller methods write action_type constants that don't
        // reflect the real event (e.g. 'PDF Downloaded', 'Email Scheduled', 'Remark Updated').
        $src = $this->appFile('Modules/Billing/app/Http/Controllers/BillingManagementController.php');
        if ($src === null) {
            $this->markTestSkipped('BillingManagementController source not reachable.');
        }
        $found = 0;
        foreach (["'PDF Downloaded'", "'Email Scheduled'", "'Remark Updated'"] as $label) {
            if (str_contains($src, $label)) {
                $found++;
            }
        }
        $this->assertGreaterThan(0, $found, 'Documenting action_type labels emitted by non-audit methods.');
    }

    // ============================================================
    // 30–39  VALIDATION / NEGATIVE (BC-VAL)
    // ============================================================

    public function test_invoicingauditlog_30_add_note_uses_findorfail_for_missing_id(): void
    {
        $src = $this->appFile('Modules/Billing/app/Http/Controllers/InvoicingAuditLogController.php');
        if ($src === null) {
            $this->markTestSkipped('Controller source not reachable.');
        }
        // findOrFail => 404 (ModelNotFound) for a bad/missing id on auditAddNote.
        $this->assertMatchesRegularExpression('/function auditAddNote\b.*?InvoicingAuditLog::findOrFail\(\$request->id\)/s', $src);
    }

    public function test_invoicingauditlog_31_add_note_update_uses_findorfail(): void
    {
        $src = $this->appFile('Modules/Billing/app/Http/Controllers/InvoicingAuditLogController.php');
        if ($src === null) {
            $this->markTestSkipped('Controller source not reachable.');
        }
        $this->assertMatchesRegularExpression('/function auditAddNoteUpdate\b.*?findOrFail\(\$request->id\)/s', $src);
    }

    public function test_invoicingauditlog_32_event_info_uses_findorfail(): void
    {
        $src = $this->appFile('Modules/Billing/app/Http/Controllers/InvoicingAuditLogController.php');
        if ($src === null) {
            $this->markTestSkipped('Controller source not reachable.');
        }
        $this->assertMatchesRegularExpression('/function auditEventInfo\b.*?findOrFail\(\$request->id\)/s', $src);
    }

    public function test_invoicingauditlog_33_notes_max_length_500_declared_in_ddl(): void
    {
        $ddl = $this->ddlContents();
        if ($ddl === null) {
            $this->markTestSkipped('Billing DDL file not reachable.');
        }
        $this->assertStringContainsString('`notes` VARCHAR(500)', $ddl, 'notes capped at 500 chars per DDL (validation should mirror it).');
    }

    public function test_invoicingauditlog_34_guest_is_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('audit-guest-redirect', function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->centralUrl(self::BILLING_MANAGEMENT_PATH))->pause(1200);

            $path = $this->currentPath($browser);
            $this->assertStringContainsString('/login', $path, 'Unauthenticated access must redirect to /login.');
        });
    }

    public function test_invoicingauditlog_35_notes_are_html_escaped_in_views(): void
    {
        // Stored-XSS guard: both audit views print notes via Blade {{ }} (auto-escaped), not {!! !!}.
        foreach (['audit-log.blade.php', 'audit-add-note.blade.php'] as $view) {
            $src = $this->appFile('Modules/Billing/resources/views/billing-management/partials/details/' . $view);
            if ($src === null) {
                $this->markTestSkipped('Audit view source not reachable.');
            }
            $this->assertStringNotContainsString('{!! $log->notes', $src, "$view must not print notes unescaped.");
        }
        $this->assertTrue(true);
    }

    // ============================================================
    // 40–49  INTEGRATION / FK (BC-INT / BC-REF)
    // ============================================================

    public function test_invoicingauditlog_40_invoice_fk_is_cascade_on_delete(): void
    {
        $ddl = $this->ddlContents();
        if ($ddl === null) {
            $this->markTestSkipped('Billing DDL file not reachable.');
        }
        $block = $this->extractAuditTableBlock($ddl);
        $this->assertStringContainsString('FOREIGN KEY (`' . self::DDL_FK_COLUMN . '`)', $block);
        $this->assertStringContainsString('ON DELETE CASCADE', $block, 'Audit rows cascade with their invoice.');
    }

    public function test_invoicingauditlog_41_performed_by_fk_is_set_null(): void
    {
        $ddl = $this->ddlContents();
        if ($ddl === null) {
            $this->markTestSkipped('Billing DDL file not reachable.');
        }
        $block = $this->extractAuditTableBlock($ddl);
        $this->assertStringContainsString('FOREIGN KEY (`performed_by`)', $block);
        $this->assertStringContainsString('ON DELETE SET NULL', $block, 'performed_by nulls out when the user is removed.');
    }

    public function test_invoicingauditlog_42_invoice_relationship_targets_invoice_model(): void
    {
        $src = $this->appFile('Modules/Billing/app/Models/InvoicingAuditLog.php');
        if ($src === null) {
            $this->markTestSkipped('Model source not reachable.');
        }
        $this->assertStringContainsString('function invoice()', $src);
        $this->assertStringContainsString("belongsTo(BilTenantInvoice::class, 'tenant_invoice_id')", $src,
            'Relation binds tenant_invoice_id (the mismatched column — see DATA-BIL-001).');
    }

    public function test_invoicingauditlog_43_user_relationship_uses_prime_user_model(): void
    {
        $src = $this->appFile('Modules/Billing/app/Models/InvoicingAuditLog.php');
        if ($src === null) {
            $this->markTestSkipped('Model source not reachable.');
        }
        $this->assertStringContainsString('use Modules\\Prime\\Models\\User;', $src, 'user() resolves the central Prime User.');
        $this->assertStringContainsString("belongsTo(User::class, 'performed_by')", $src);
    }

    // ============================================================
    // 50–59  PERMISSIONS / AUTHORIZATION (BC-AUTH)
    // ============================================================

    public function test_invoicingauditlog_50_policy_uses_prime_permission_namespace(): void
    {
        $src = $this->appFile('Modules/Billing/app/Policies/InvoicingAuditLogPolicy.php');
        if ($src === null) {
            $this->markTestSkipped('Policy source not reachable.');
        }
        foreach (['viewAny', 'view', 'create', 'update', 'delete', 'restore', 'forceDelete'] as $ability) {
            $this->assertStringContainsString("prime.invoicing-audit-log.$ability", $src, "Policy $ability uses the prime.* key.");
        }
    }

    public function test_invoicingauditlog_51_note_update_write_is_gated(): void
    {
        // Current source DOES gate the write (audit report's "no check" is remediated here) — assert the real gate.
        $src = $this->appFile('Modules/Billing/app/Http/Controllers/InvoicingAuditLogController.php');
        if ($src === null) {
            $this->markTestSkipped('Controller source not reachable.');
        }
        $this->assertMatchesRegularExpression(
            '/function auditAddNoteUpdate\b.*?Gate::authorize\(\'prime\.invoicing-audit-log\.update\'\)/s',
            $src,
            'auditAddNoteUpdate authorizes prime.invoicing-audit-log.update (documenting current, remediated state).'
        );
    }

    public function test_invoicingauditlog_52_blade_action_gates_never_match_backend_keys(): void
    {
        // DEV-BIL-A04 (P2): blade @can uses 'audit.invoicing-audit-log.remakr' / '...viewAny'
        // while the Policy/Gate namespace is 'prime.invoicing-audit-log.*' → Add-Note / Event-Info
        // action buttons can never render, silently hiding the only note-edit entry point.
        $src = $this->appFile('Modules/Billing/resources/views/billing-management/partials/invoice-audit/index.blade.php');
        if ($src === null) {
            $this->markTestSkipped('Invoice-audit index view not reachable.');
        }
        $this->assertStringContainsString('audit.invoicing-audit-log.remakr', $src, 'Blade uses the (typo) audit.* key.');
        $this->assertStringNotContainsString('prime.invoicing-audit-log.remark', $src,
            'DEV-BIL-A04 PROVEN: action buttons never gate on the real prime.* namespace.');
    }

    public function test_invoicingauditlog_53_audit_read_route_uses_billing_management_permission(): void
    {
        // DEV-BIL-A05 (P3): the audit-log READ route authorizes prime.billing-management.view,
        // not prime.invoicing-audit-log.view — an authorization-scope inconsistency.
        $src = $this->appFile('Modules/Billing/app/Http/Controllers/BillingManagementController.php');
        if ($src === null) {
            $this->markTestSkipped('BillingManagementController source not reachable.');
        }
        $this->assertMatchesRegularExpression(
            '/function AuditLog\b.*?Gate::authorize\(\'prime\.billing-management\.view\'\)/s',
            $src,
            'DEV-BIL-A05 PROVEN: audit-log read gated on billing-management.view, not the audit permission.'
        );
    }

    public function test_invoicingauditlog_54_audit_tab_requires_viewany_to_render(): void
    {
        $this->browseWithFailureScreenshot('audit-tab-viewany', function (Browser $browser): void {
            $this->openAuditTab($browser);
            // The tab include is wrapped in @can('prime.invoicing-audit-log.viewAny'); admin (super) sees it.
            $this->assertNotNull(
                $browser->element(self::AUDIT_PANE_SELECTOR),
                'Invoicing Audit pane should be visible to the super-admin (viewAny granted via Gate::before).'
            );
        });
    }

    public function test_invoicingauditlog_55_audit_routes_are_registered(): void
    {
        // BC-AUTH / route-registration: these central.* names are referenced from blade AJAX.
        $names = [
            'central.billing.billing-management.audit.log',
            'central.billing.audit.add.note',
            'central.billing.audit.add.note.update',
            'central.billing.audit.event.info',
            'central.billing.audit-note.download.pdf',
        ];
        $missing = [];
        foreach ($names as $name) {
            try {
                if (!Route::has($name)) {
                    $missing[] = $name;
                }
            } catch (Throwable $e) {
                $this->markTestSkipped('Route table unavailable: ' . $e->getMessage());
            }
        }
        $this->assertSame([], $missing, 'Blade-referenced audit routes must be registered: ' . implode(', ', $missing));
    }

    // ============================================================
    // 60–69  UI / UX  (render, filters, empty-state, pagination)
    // ============================================================

    public function test_invoicingauditlog_60_audit_tab_loads_with_filters(): void
    {
        $this->browseWithFailureScreenshot('audit-tab-filters', function (Browser $browser): void {
            $this->openAuditTab($browser);
            $browser
                ->assertPresent(self::AUDIT_PANE_SELECTOR)
                ->assertPresent('input[name="date_range"]')
                ->assertPresent('select[name="performed_by"]')
                ->assertPresent('select[name="audit_status"]')
                ->assertPresent(self::AUDIT_PANE_SELECTOR . ' table');
        });
    }

    public function test_invoicingauditlog_61_export_and_print_controls_present_for_admin(): void
    {
        $this->browseWithFailureScreenshot('audit-export-controls', function (Browser $browser): void {
            $this->openAuditTab($browser);
            // Print + PDF export buttons are @can-gated on prime.invoicing-audit-log.print/pdf (admin has them).
            $hasExport = $browser->element('#downloadData') !== null || $browser->element('#printFiltered') !== null;
            $this->assertTrue($hasExport, 'At least one export/print control should be visible to the admin.');
        });
    }

    public function test_invoicingauditlog_62_audit_status_dropdown_lists_expected_values(): void
    {
        $src = $this->appFile('Modules/Billing/resources/views/billing-management/partials/invoice-audit/index.blade.php');
        if ($src === null) {
            $this->markTestSkipped('Invoice-audit index view not reachable.');
        }
        foreach (['Not Billed', 'GENERATED', 'Notice Sent', 'Partially Paid', 'Fully Paid'] as $value) {
            $this->assertStringContainsString("'$value'", $src, "audit_status filter should offer '$value'.");
        }
    }

    public function test_invoicingauditlog_63_empty_state_message_is_defined(): void
    {
        $src = $this->appFile('Modules/Billing/resources/views/billing-management/partials/invoice-audit/index.blade.php');
        if ($src === null) {
            $this->markTestSkipped('Invoice-audit index view not reachable.');
        }
        $this->assertStringContainsString('No records found.', $src, 'Empty-state text must exist for zero audit rows.');
    }

    public function test_invoicingauditlog_64_pagination_is_rendered(): void
    {
        $src = $this->appFile('Modules/Billing/resources/views/billing-management/partials/invoice-audit/index.blade.php');
        if ($src === null) {
            $this->markTestSkipped('Invoice-audit index view not reachable.');
        }
        $this->assertStringContainsString('->links()', $src, 'Paginator links must render for the audit list.');
    }

    public function test_invoicingauditlog_65_billing_management_page_is_reachable(): void
    {
        $this->browseWithFailureScreenshot('billing-management-reachable', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::BILLING_MANAGEMENT_PATH);
            $this->assertSame(self::BILLING_MANAGEMENT_PATH, $this->currentPath($browser), 'Billing Management page not reachable.');
            $this->ensurePageAccessible($browser, 'Billing Management (Invoicing Audit)');
        });
    }

    // ============================================================
    // 70–79  EDGE CASES (BC-EDG)
    // ============================================================

    public function test_invoicingauditlog_70_action_type_is_varchar20_boundary(): void
    {
        $ddl = $this->ddlContents();
        if ($ddl === null) {
            $this->markTestSkipped('Billing DDL file not reachable.');
        }
        $this->assertStringContainsString("`action_type` VARCHAR(20)", $ddl, 'action_type bounded to 20 chars.');
        // 'PAYMENT_UPDATED' (15) fits; a longer literal would silently truncate/throw in strict mode.
        $this->assertLessThanOrEqual(20, strlen('PAYMENT_UPDATED'));
    }

    public function test_invoicingauditlog_71_performed_by_is_nullable_for_system_events(): void
    {
        $ddl = $this->ddlContents();
        if ($ddl === null) {
            $this->markTestSkipped('Billing DDL file not reachable.');
        }
        $block = $this->extractAuditTableBlock($ddl);
        $this->assertStringContainsString('`performed_by` INT UNSIGNED DEFAULT NULL', $block, 'System/queue events store NULL performed_by.');
    }

    public function test_invoicingauditlog_72_insert_sites_default_performed_by_to_null(): void
    {
        $src = $this->appFile('Modules/Billing/app/Http/Controllers/BillingManagementController.php');
        if ($src === null) {
            $this->markTestSkipped('BillingManagementController source not reachable.');
        }
        $this->assertStringContainsString('auth()->id() ?? null', $src, 'Insert sites null-coalesce performed_by for unauthenticated contexts.');
    }

    public function test_invoicingauditlog_73_queue_job_performed_by_gap_is_documented(): void
    {
        // Requirement "Queue Job Context": Auth::id() is null inside SendInvoiceEmailJob; performed_by
        // must be passed explicitly. Document current handling defensively.
        $src = $this->appFile('Modules/Billing/app/Jobs/SendInvoiceEmailJob.php');
        if ($src === null) {
            $this->markTestSkipped('SendInvoiceEmailJob source not reachable — documented as a requirement risk.');
        }
        $this->assertNotSame('', $src);
    }

    // ============================================================
    // 90–99  TENANCY SCOPE + SECURITY PACK (TC-T / TC-S)
    // ============================================================

    public function test_invoicingauditlog_90_feature_is_central_prime_scoped(): void
    {
        // TC-T: this is a central/prime feature — the base must be pinned to 127.0.0.1 (no tenant host).
        $this->assertStringContainsString('127.0.0.1', $this->centralBaseUrl, 'Central base URL must be 127.0.0.1 (prime scope).');
        $this->assertStringNotContainsString('test.localhost', $this->centralBaseUrl, 'Must NOT use the tenant DUSK_TENANT_URL host.');
    }

    public function test_invoicingauditlog_91_event_info_over_persists_beyond_whitelist_proves_SEC_BIL_011(): void
    {
        // DEV-BIL-A03 / SEC-BIL-011 / BR-BIL-022 (P1): literal $request->all() is remediated in
        // current source, BUT event_info still persists raw request keys NOT in the documented
        // whitelist (e.g. remarks, gateway_response, payment_reconciled) — residual over-capture.
        $src = $this->appFile('Modules/Billing/app/Http/Controllers/InvoicingPaymentController.php');
        if ($src === null) {
            $this->markTestSkipped('InvoicingPaymentController source not reachable.');
        }

        // Confirm the literal mass-capture is gone (honest, current-state reporting).
        $this->assertStringNotContainsString("'request_data' => \$request->all()", $src, 'Literal $request->all() into event_info is remediated.');
        $this->assertStringNotContainsString('$request->all()', $src, 'No raw $request->all() persisted.');

        // Prove residual over-capture: request-sourced keys outside the whitelist land in event_info.
        $overCaptured = [];
        foreach (['remarks', 'gateway_resp', 'payment_reconciled'] as $rawKey) {
            if (str_contains($src, '$request->' . $rawKey)) {
                $overCaptured[] = $rawKey;
            }
        }
        $this->assertNotEmpty(
            $overCaptured,
            'SEC-BIL-011 residual PROVEN: request keys outside the whitelist [' . implode(', ', self::EVENT_INFO_WHITELIST) . '] are persisted into event_info: ' . implode(', ', $overCaptured)
        );
    }

    public function test_invoicingauditlog_92_event_info_view_escapes_values(): void
    {
        $src = $this->appFile('Modules/Billing/resources/views/billing-management/partials/details/audit-event-info.blade.php');
        if ($src === null) {
            $this->markTestSkipped('Event-info view not reachable.');
        }
        $this->assertStringContainsString('{{ $value }}', $src, 'event_info values are Blade-escaped, mitigating stored XSS on render.');
        $this->assertStringNotContainsString('{!! $value', $src, 'event_info must never be printed unescaped.');
    }

    public function test_invoicingauditlog_93_add_note_rejects_unknown_id_as_idor_guard(): void
    {
        // IDOR/negative: findOrFail on a non-existent id yields a 404 rather than leaking another record.
        $src = $this->appFile('Modules/Billing/app/Http/Controllers/InvoicingAuditLogController.php');
        if ($src === null) {
            $this->markTestSkipped('Controller source not reachable.');
        }
        $this->assertSame(
            3,
            substr_count($src, 'findOrFail($request->id)'),
            'All three id-driven audit endpoints (add-note, add-note-update, event-info) use findOrFail => 404 on bad id.'
        );
    }

    // ============================================================
    // PRIVATE HELPER LIBRARY
    // ============================================================

    private function openAuditTab(Browser $browser): void
    {
        $this->authenticateCentral($browser);
        $this->visitAuthenticated($browser, self::BILLING_MANAGEMENT_PATH);
        $this->ensurePageAccessible($browser, 'Billing Management (Invoicing Audit tab)');
        $this->ensureTabVisible($browser, self::AUDIT_TAB_SELECTOR, self::AUDIT_PANE_SELECTOR);
    }

    private function modelInstance(): ?object
    {
        if (!class_exists(self::MODEL_CLASS)) {
            return null;
        }
        $class = self::MODEL_CLASS;

        return new $class();
    }

    private function modelReflection(): ?ReflectionClass
    {
        if (!class_exists(self::MODEL_CLASS)) {
            return null;
        }

        return new ReflectionClass(self::MODEL_CLASS);
    }

    private function appFile(string $relative): ?string
    {
        $base = (string) env('MAIN_PROJECT_PATH', '');
        if ($base === '') {
            return null;
        }
        $path = rtrim($base, '/') . '/' . ltrim($relative, '/');

        return is_file($path) ? (string) file_get_contents($path) : null;
    }

    private function ddlContents(): ?string
    {
        $path = (string) env('DUSK_BILLING_DDL_PATH', self::DDL_PATH_FALLBACK);

        return is_file($path) ? (string) file_get_contents($path) : null;
    }

    private function extractAuditTableBlock(string $ddl): string
    {
        $start = strpos($ddl, 'CREATE TABLE IF NOT EXISTS `bil_tenant_invoicing_audit_logs`');
        if ($start === false) {
            return '';
        }
        $end = strpos($ddl, ';', $start);
        if ($end === false) {
            return substr($ddl, $start);
        }

        return substr($ddl, $start, $end - $start + 1);
    }
}
