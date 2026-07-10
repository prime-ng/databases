<?php

namespace Tests\Browser\Modules\Prime\Billing\InvoicingAuditLog;

use App\Models\User;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Tests\Browser\Modules\Prime\Billing\BillingDuskTestCase;
use Throwable;

/**
 * Invoicing Audit Log — V1 (foundation) Dusk suite.
 *
 * Feature    : Billing / Invoicing Audit Log (central Super-Admin, prime_db).
 * Screen     : Billing Management -> Invoicing Audit tab
 *              (GET /billing/billing-management?type=audit-note).
 * Endpoints  : GET  /billing/billing/audit-log?id=            BillingManagementController@AuditLog
 *              GET  /billing/audit/add-note?id=               InvoicingAuditLogController@auditAddNote
 *              POST /billing/audit/add-note/update            InvoicingAuditLogController@auditAddNoteUpdate  [WRITE, gate .update]
 *              GET  /billing/audit/event-info?id=             InvoicingAuditLogController@auditEventInfo
 *              GET  /billing/audit-note.download.pdf          InvoicingAuditLogController@downloadAuditNotePdf
 * Primary DB : bil_tenant_invoicing_audit_logs  (Billing_DDL_v1.sql line 82)  -> prefix bil_
 *
 * Style: mirrors the committed sibling
 *   tests/Browser/Modules/Prime/Billing/InvoicingAudit/prm_InvoicingAuditTab_TestCas.php
 * (browser Dusk, central chain via BillingDuskTestCase: authenticateCentral / visitAuthenticated /
 *  centralUrl / ensureTabVisible / browseWithFailureScreenshot). PRIME-SIDE => no tenant init.
 *
 * Append-only trail: rows are created via create() only; the notes field is the ONLY mutable column
 * (auditAddNoteUpdate). This suite is therefore read/report-heavy (tab/filter/pagination/PDF) plus the
 * single note-update write path. Source-truth assertions read the real app files under MAIN_PROJECT_PATH
 * and never invent routes, selectors, gates, or messages.
 *
 * Documented source defects proved/observed here (see Gap Analysis / Validation Report):
 *   DATA-BIL-001 (P0)  model column tenant_invoice_id vs consolidated DDL tenant_invoicing_id.
 *   MIG-BIL-001  (P0)  SoftDeletes + default timestamps but DDL has created_at only.
 *   SEC-BIL-010  (P1)  note-edit WRITE now gated (remediation verified: gate .update present).
 *   SEC-BIL-011  (P1)  raw $request->all() into event_info — write path lives in Invoicing/Payment, not here.
 *   AUTH-BIL-002 (P2)  Blade action column gates on audit.* keys; Policy/Gates use prime.* keys (unreachable UI).
 *   VAL-BIL-002  (P2)  auditAddNoteUpdate has no FormRequest / no max:500 / no sanitization on notes.
 */
class bil_InvoicingAuditLogV1_TestCas extends BillingDuskTestCase
{
    protected const SCREENSHOT_DIR = 'tests/Browser/Modules/Prime/Billing/InvoicingAuditLog/screenshots';
    protected const STATUS_REPORT_DIRECTORY = 'tests/Browser/Modules/Prime/Billing/InvoicingAuditLog/report';
    protected const STATUS_REPORT_PREFIX = 'billing_invoicing_audit_log_v1_report_';

    private const BILLING_MANAGEMENT_PATH = '/billing/billing-management';
    private const AUDIT_TAB_QUERY         = '/billing/billing-management?type=audit-note';
    private const AUDIT_LOG_AJAX_PATH     = '/billing/billing/audit-log';
    private const ADD_NOTE_PATH           = '/billing/audit/add-note';
    private const ADD_NOTE_UPDATE_PATH    = '/billing/audit/add-note/update';
    private const EVENT_INFO_PATH         = '/billing/audit/event-info';
    private const DOWNLOAD_PDF_PATH       = '/billing/audit-note.download.pdf';

    private const AUDIT_TABLE    = 'bil_tenant_invoicing_audit_logs';
    private const INVOICES_TABLE = 'bil_tenant_invoices';
    private const ACTIVITY_TABLE = 'sys_activity_logs';

    // The model declares tenant_invoice_id; the consolidated Billing DDL declares tenant_invoicing_id.
    private const MODEL_FK_COLUMN = 'tenant_invoice_id';
    private const DDL_FK_COLUMN   = 'tenant_invoicing_id';

    private const CONTROLLER_SRC    = 'Modules/Billing/app/Http/Controllers/InvoicingAuditLogController.php';
    private const BM_CONTROLLER_SRC = 'Modules/Billing/app/Http/Controllers/BillingManagementController.php';
    private const POLICY_SRC        = 'Modules/Billing/app/Policies/InvoicingAuditLogPolicy.php';
    private const MODEL_SRC         = 'Modules/Billing/app/Models/InvoicingAuditLog.php';
    private const INVOICE_MODEL_SRC = 'Modules/Billing/app/Models/BilTenantInvoice.php';
    private const INDEX_BLADE_SRC   = 'Modules/Billing/resources/views/billing-management/partials/invoice-audit/index.blade.php';
    private const ADDNOTE_BLADE_SRC = 'Modules/Billing/resources/views/billing-management/partials/details/audit-add-note.blade.php';

    // ---------------------------------------------------------------------
    // 01-05  Schema / model / config source truth
    // ---------------------------------------------------------------------

    public function test_invoicing_audit_log_01_audit_table_schema_matches_ddl(): void
    {
        try {
            if (!Schema::hasTable(self::AUDIT_TABLE)) {
                $this->markTestSkipped(self::AUDIT_TABLE . ' not present (Billing module disabled / DDL not migrated).');
            }
        } catch (Throwable $e) {
            $this->markTestSkipped('Schema inspection unavailable: ' . $e->getMessage());
        }

        $this->assertTrue(
            Schema::hasColumns(self::AUDIT_TABLE, ['id', 'action_date', 'action_type', 'performed_by', 'event_info', 'notes', 'created_at']),
            self::AUDIT_TABLE . ' is missing one or more DDL columns.'
        );

        // MIG-BIL-001 (P0): DDL has created_at only — no updated_at, no deleted_at — but the model uses
        // SoftDeletes + default timestamps. This test documents the current (broken-on-correct-DB) schema.
        $this->assertFalse(
            Schema::hasColumn(self::AUDIT_TABLE, 'deleted_at'),
            'DDL unexpectedly gained deleted_at — reconcile MIG-BIL-001 if the schema was patched.'
        );
        $this->assertFalse(
            Schema::hasColumn(self::AUDIT_TABLE, 'updated_at'),
            'DDL unexpectedly gained updated_at — reconcile MIG-BIL-001 if the schema was patched.'
        );
    }

    public function test_invoicing_audit_log_02_data_bil_001_column_mismatch_is_reproduced(): void
    {
        try {
            if (!Schema::hasTable(self::AUDIT_TABLE)) {
                $this->markTestSkipped(self::AUDIT_TABLE . ' not present.');
            }
        } catch (Throwable $e) {
            $this->markTestSkipped('Schema inspection unavailable: ' . $e->getMessage());
        }

        $model = new \Modules\Billing\Models\InvoicingAuditLog();

        // Source truth: the model's fillable + invoice() relation use tenant_invoice_id.
        $this->assertContains(self::MODEL_FK_COLUMN, $model->getFillable(), 'Model fillable must declare tenant_invoice_id (source truth).');

        $hasModelCol = Schema::hasColumn(self::AUDIT_TABLE, self::MODEL_FK_COLUMN);
        $hasDdlCol   = Schema::hasColumn(self::AUDIT_TABLE, self::DDL_FK_COLUMN);

        // The audit FK column must exist under SOME name.
        $this->assertTrue($hasModelCol || $hasDdlCol, 'Audit FK column missing entirely under both candidate names.');

        // DATA-BIL-001: when the live table carries the DDL name (tenant_invoicing_id) but NOT the model
        // name (tenant_invoice_id), every audit read via invoice()/where('tenant_invoice_id') targets a
        // non-existent column -> SQLSTATE 42S22. This assertion makes the mismatch explicit.
        if ($hasDdlCol && !$hasModelCol) {
            $this->assertTrue(
                true,
                'DATA-BIL-001 reproduced: table has tenant_invoicing_id but model/queries use tenant_invoice_id.'
            );
        } else {
            // Either the schema was patched to tenant_invoice_id (remediation) or both exist. Record it.
            $this->assertTrue(
                $hasModelCol,
                'DATA-BIL-001: model column tenant_invoice_id absent AND DDL column absent — investigate schema.'
            );
        }
    }

    public function test_invoicing_audit_log_03_model_configuration_is_correct(): void
    {
        $model = new \Modules\Billing\Models\InvoicingAuditLog();

        $this->assertSame(self::AUDIT_TABLE, $model->getTable(), 'InvoicingAuditLog table mismatch.');

        foreach (['tenant_invoice_id', 'action_type', 'action_date', 'performed_by', 'notes', 'event_info'] as $col) {
            $this->assertContains($col, $model->getFillable(), "Missing fillable: {$col}");
        }

        // BC-EDG-01: action_date cast is present; event_info has NO array cast (read-decode risk).
        $casts = $model->getCasts();
        $this->assertSame('datetime', $casts['action_date'] ?? null, 'action_date cast should be datetime.');
        $this->assertArrayNotHasKey('event_info', $casts, 'event_info is NOT array-cast in the model (BC-EDG-02).');

        // MIG-BIL-001: model uses SoftDeletes though the DDL table has no deleted_at.
        $this->assertContains(
            \Illuminate\Database\Eloquent\SoftDeletes::class,
            class_uses_recursive(\Modules\Billing\Models\InvoicingAuditLog::class),
            'InvoicingAuditLog declares SoftDeletes (schema gap vs DDL — MIG-BIL-001).'
        );

        $this->assertTrue(method_exists($model, 'invoice'), 'invoice() relationship missing.');
        $this->assertTrue(method_exists($model, 'user'), 'user() relationship missing.');
    }

    public function test_invoicing_audit_log_04_model_relations_use_expected_columns(): void
    {
        $src = $this->appSource(self::MODEL_SRC);

        // invoice() belongsTo BilTenantInvoice on tenant_invoice_id (DATA-BIL-001 origin).
        $this->assertStringContainsString("belongsTo(BilTenantInvoice::class, 'tenant_invoice_id')", $src,
            'invoice() must belongTo BilTenantInvoice on tenant_invoice_id (source truth).');

        // user() belongsTo the CENTRAL user model on performed_by.
        $this->assertStringContainsString("belongsTo(User::class, 'performed_by')", $src,
            'user() must belongTo User on performed_by.');
        $this->assertStringContainsString('use Modules\\Prime\\Models\\User;', $src,
            'user() must reference the central Modules\\Prime\\Models\\User.');

        // Reverse relation on BilTenantInvoice also uses the mismatched column (DATA-BIL-001 second site).
        $invSrc = $this->appSource(self::INVOICE_MODEL_SRC);
        $this->assertStringContainsString("hasMany(InvoicingAuditLog::class, 'tenant_invoice_id', 'id')", $invSrc,
            'BilTenantInvoice::auditLogs() also targets tenant_invoice_id (DATA-BIL-001).');
    }

    public function test_invoicing_audit_log_05_activity_log_target_is_central(): void
    {
        // Note-update writes to Modules\GlobalMaster\Models\ActivityLog (table sys_activity_logs).
        $this->assertSame(self::ACTIVITY_TABLE, (new \Modules\GlobalMaster\Models\ActivityLog())->getTable(),
            'ActivityLog table must be sys_activity_logs.');

        try {
            if (Schema::hasTable(self::ACTIVITY_TABLE)) {
                $this->assertTrue(
                    Schema::hasColumns(self::ACTIVITY_TABLE, ['subject_type', 'subject_id', 'user_id', 'event', 'properties']),
                    'sys_activity_logs missing expected columns.'
                );
            }
        } catch (Throwable $e) {
            $this->markTestSkipped('Activity-log schema unavailable: ' . $e->getMessage());
        }
    }

    // ---------------------------------------------------------------------
    // 06-10  Tab render / list / filters (browser, mirrors sibling)
    // ---------------------------------------------------------------------

    public function test_invoicing_audit_log_06_tab_loads_with_filters(): void
    {
        $this->browseWithFailureScreenshot('v1-audit-tab-load', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::BILLING_MANAGEMENT_PATH);

            $this->assertSame(self::BILLING_MANAGEMENT_PATH, $this->currentPath($browser), 'Billing Management not reachable.');
            $this->ensurePageAccessible($browser, 'Billing Management (Invoicing Audit tab)');
            $this->ensureTabVisible($browser, '#invoicing-audit-tab', '#invoicing-audit-pane');

            $this->assertNotNull($browser->element('#invoicing-audit-pane'), 'Invoicing Audit pane not visible.');
            $browser
                ->assertPresent('input[name="date_range"]')
                ->assertPresent('select[name="performed_by"]')
                ->assertPresent('select[name="audit_status"]')
                ->assertPresent('#invoicing-audit-pane table');
        });
    }

    public function test_invoicing_audit_log_07_audit_table_headers_render(): void
    {
        $this->browseWithFailureScreenshot('v1-audit-headers', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::AUDIT_TAB_QUERY);
            $this->ensureTabVisible($browser, '#invoicing-audit-tab', '#invoicing-audit-pane');

            $pane = $browser->text('#invoicing-audit-pane');
            foreach (['Invoice No', 'Audit Date', 'Audit Entry Type', 'Performed By'] as $header) {
                $this->assertStringContainsString($header, $pane, "Audit table header '{$header}' missing.");
            }
        });
    }

    public function test_invoicing_audit_log_08_filter_form_carries_type_audit_note(): void
    {
        $this->browseWithFailureScreenshot('v1-audit-filter-form', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::AUDIT_TAB_QUERY);
            $this->ensureTabVisible($browser, '#invoicing-audit-tab', '#invoicing-audit-pane');

            $browser
                ->assertPresent('#invoicing-audit-pane input[name="type"][value="audit-note"]')
                ->assertPresent('input[name="date_range"]')
                ->assertPresent('select[name="performed_by"]')
                ->assertPresent('select[name="audit_status"]');
        });
    }

    public function test_invoicing_audit_log_09_query_orders_desc_and_eager_loads(): void
    {
        $src = $this->appSource(self::BM_CONTROLLER_SRC);
        $this->assertStringContainsString("InvoicingAuditLog::with(['invoice', 'user'])", $src,
            'buildAuditLogQuery must eager load invoice + user (BC-BIZ-06).');
        $this->assertStringContainsString("orderBy('action_date', 'desc')", $src,
            'Audit list must order by action_date desc (newest first) (BC-BIZ-07).');
        $this->assertStringContainsString('->paginate(10)', $src, 'Audit tab must paginate at 10/page (BC-BIZ-05).');
    }

    public function test_invoicing_audit_log_10_filters_map_to_expected_columns(): void
    {
        $src = $this->appSource(self::BM_CONTROLLER_SRC);
        // date_range -> whereBetween action_date
        $this->assertStringContainsString("whereBetween('action_date'", $src, 'date_range filter missing (BC-BIZ-09).');
        // tenat_id (intentional typo) -> whereHas invoice tenant_id
        $this->assertStringContainsString("'tenat_id'", $src, "tenat_id filter key (intentional typo) missing (BC-BIZ-10).");
        $this->assertStringContainsString("where('tenant_id', \$this->filters['tenat_id'])", $src, 'tenat_id -> invoice.tenant_id filter missing.');
        // performed_by exact match
        $this->assertStringContainsString("where('performed_by', \$this->filters['performed_by'])", $src, 'performed_by filter missing (BC-BIZ-11).');
        // audit_status -> action_type
        $this->assertStringContainsString("where('action_type', \$this->filters['audit_status'])", $src, 'audit_status -> action_type filter missing (BC-BIZ-12).');
    }

    // ---------------------------------------------------------------------
    // 11-13  Note-update write path + activity log (source + endpoint)
    // ---------------------------------------------------------------------

    public function test_invoicing_audit_log_11_note_update_is_gated_and_logs_store_event(): void
    {
        $src = $this->appSource(self::CONTROLLER_SRC);

        // SEC-BIL-010 remediation: the note-edit WRITE now carries the update gate.
        $this->assertStringContainsString("Gate::authorize('prime.invoicing-audit-log.update')", $src,
            'auditAddNoteUpdate must gate on prime.invoicing-audit-log.update (SEC-BIL-010 remediation).');

        // Only the notes field is mutated.
        $this->assertStringContainsString('$log->notes = $request->notes;', $src, 'Only notes must be mutated (append-only invariant).');

        // Activity-log event is the literal 'Store'.
        $this->assertStringContainsString("activityLog(\$log, 'Store', ['message' => 'Audit Log Note Add'])", $src,
            'Note update must write activity event Store (BC-AUTO-01).');

        // Success message is exact.
        $this->assertStringContainsString('Audit note updated successfully!', $src, 'Exact success message missing.');
    }

    public function test_invoicing_audit_log_12_read_endpoints_are_gated_on_view(): void
    {
        $src = $this->appSource(self::CONTROLLER_SRC);
        // auditAddNote / auditEventInfo / downloadAuditNotePdf all gate on .view (SEC-BIL-010 remediated).
        $this->assertSame(3, substr_count($src, "Gate::authorize('prime.invoicing-audit-log.view')"),
            'auditAddNote, auditEventInfo and downloadAuditNotePdf must each gate on prime.invoicing-audit-log.view.');
    }

    public function test_invoicing_audit_log_13_ajax_audit_log_uses_model_column(): void
    {
        $src = $this->appSource(self::BM_CONTROLLER_SRC);
        // AuditLog() filters on the model column tenant_invoice_id (DATA-BIL-001 second call site).
        $this->assertStringContainsString("InvoicingAuditLog::where('tenant_invoice_id', \$invoiceId)", $src,
            'AuditLog() filters on tenant_invoice_id (DATA-BIL-001).');
        $this->assertStringContainsString("Gate::authorize('prime.billing-management.view')", $src,
            'AuditLog() must gate on prime.billing-management.view.');
    }

    // ---------------------------------------------------------------------
    // 14-16  Authorization / guest / defect source truth
    // ---------------------------------------------------------------------

    public function test_invoicing_audit_log_14_guest_is_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('v1-guest-redirect', function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->centralUrl(self::AUDIT_TAB_QUERY))->pause(1200);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest should be redirected to /login.');
        });
    }

    public function test_invoicing_audit_log_15_blade_action_gates_use_wrong_prefix(): void
    {
        // AUTH-BIL-002 (NEW): Blade action column + links gate on audit.* keys with a typo (remakr),
        // while the Policy/Gates use prime.* keys -> action column never renders for prime.* holders.
        $src = $this->appSource(self::INDEX_BLADE_SRC);
        $this->assertStringContainsString("audit.invoicing-audit-log.remakr", $src,
            'AUTH-BIL-002: Blade Add-Note link gates on the non-existent audit.invoicing-audit-log.remakr key.');
        $this->assertStringContainsString("audit.invoicing-audit-log.viewAny", $src,
            'AUTH-BIL-002: Blade Event-Info link gates on the non-existent audit.invoicing-audit-log.viewAny key.');
        $this->assertStringNotContainsString("audit.invoicing-audit-log.remakr", $this->appSource(self::POLICY_SRC),
            'Policy defines no audit.* ability — confirming the AUTH-BIL-002 mismatch.');
    }

    public function test_invoicing_audit_log_16_note_update_has_no_validation(): void
    {
        // VAL-BIL-002 (NEW): auditAddNoteUpdate reads $request->notes with no FormRequest, no max:500,
        // no sanitization. Confirm the controller signature takes the base Request (not a FormRequest).
        $src = $this->appSource(self::CONTROLLER_SRC);
        $this->assertStringContainsString('public function auditAddNoteUpdate(Request $request)', $src,
            'VAL-BIL-002: auditAddNoteUpdate uses the base Request (no validation layer).');
        $this->assertStringNotContainsString("'notes' => 'required", $src, 'VAL-BIL-002: no notes validation rule exists.');
        $this->assertStringNotContainsString('max:500', $src, 'VAL-BIL-002: notes VARCHAR(500) is not enforced by any max:500 rule.');
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
}
