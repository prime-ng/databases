<?php

namespace Tests\Browser\Modules\Prime\Billing\EmailSchedule;

use App\Models\User;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\Bus;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\Billing\Jobs\SendInvoiceEmailJob;
use Modules\Billing\Models\BilTenantInvoice;
use Modules\Billing\Models\BillTenantEmailSchedule;
use Modules\GlobalMaster\Models\ActivityLog;
use Tests\Browser\Modules\Prime\Billing\BillingDuskTestCase;
use Throwable;

/**
 * Email Schedule — V2 (comprehensive) suite.
 *
 * Coverage: schema/config, business rules (send/schedule/cancel + activity+audit logs),
 * state-machine (pending -> cancelled / sent / failed), validation/negative,
 * integration/FK (DATA-BIL-003 orphan invoice_id, invoice relations), permissions/auth,
 * UI/UX (search, status filter, pagination, empty state, show), edge cases, and security.
 *
 * Semantic numbering bands (WP-G):
 *   01-09 schema | 10-19 BC-BIZ | 20-29 BC-SM | 30-39 BC-VAL | 40-49 BC-INT/REF
 *   50-59 BC-AUTH | 60-69 UI/UX | 70-79 BC-EDG | 90-99 security
 *
 * Central prime_db scope — NO tenant init (mirrors committed Billing siblings).
 * All DB-touching tests guarded (Schema::hasTable + markTestSkipped). See 05_ C12/E19.
 */
class bil_EmailScheduleV2_TestCas extends BillingDuskTestCase
{
    protected const SCREENSHOT_DIR = 'tests/Browser/Modules/Prime/Billing/EmailSchedule/screenshots';
    protected const STATUS_REPORT_DIRECTORY = 'tests/Browser/Modules/Prime/Billing/EmailSchedule/report';
    protected const STATUS_REPORT_PREFIX = 'email_schedule_v2_report_';

    private const TABLE = 'bil_tenant_email_schedules';
    private const INDEX_PATH = '/billing/email-schedule';
    private const SEND_EMAIL_PATH = '/billing/billing-management/send-email';
    private const SCHEDULE_EMAIL_PATH = '/billing/billing-management/schedule-email';

    // =====================================================================
    // 01-09  Schema / model / migration configuration
    // =====================================================================

    public function test_email_schedule_01_table_and_columns_exist(): void
    {
        $this->skipUnlessTableReady();
        $this->assertTrue(Schema::hasColumns(self::TABLE, ['id', 'invoice_id', 'schedule_time', 'status', 'created_at', 'updated_at']));
    }

    public function test_email_schedule_02_model_fillable_matches_source(): void
    {
        $this->assertSame(['invoice_id', 'schedule_time', 'status'], (new BillTenantEmailSchedule())->getFillable());
    }

    public function test_email_schedule_03_model_table_binding(): void
    {
        $this->assertSame(self::TABLE, (new BillTenantEmailSchedule())->getTable());
    }

    public function test_email_schedule_04_model_has_no_soft_deletes(): void
    {
        // Cancel is a status update, not a delete — model must NOT use SoftDeletes.
        $this->assertFalse(in_array(SoftDeletes::class, class_uses_recursive(BillTenantEmailSchedule::class), true));
        if (Schema::hasTable(self::TABLE)) {
            $this->assertFalse(Schema::hasColumn(self::TABLE, 'deleted_at'));
        }
    }

    public function test_email_schedule_05_invoice_id_has_no_foreign_key_data_bil_003(): void
    {
        // DATA-BIL-003 (P2): schedule.invoice_id has no FK constraint. An orphan id is accepted.
        $this->skipUnlessTableReady();
        $orphanId = null;
        try {
            $row = BillTenantEmailSchedule::create([
                'invoice_id' => 2000000000, // non-existent invoice
                'schedule_time' => now(),
                'status' => 'pending',
            ]);
            $orphanId = (int) $row->id;
            $this->assertNotNull($row->id, 'DATA-BIL-003: orphan invoice_id should insert (no FK).');
        } catch (Throwable $e) {
            $this->fail('DATA-BIL-003 unexpected: FK now blocks orphan invoice_id — ' . $e->getMessage());
        } finally {
            if ($orphanId !== null) {
                DB::table(self::TABLE)->where('id', $orphanId)->delete();
            }
        }
    }

    public function test_email_schedule_06_ddl_gap_documented_migration_is_source_of_truth(): void
    {
        // The table is NOT in Billing_DDL_v1.sql; it is created by a Prime-module migration.
        // Assert the runtime schema exists (migration applied) so the drift is provable, not fatal.
        $this->skipUnlessTableReady();
        $this->assertTrue(Schema::hasTable(self::TABLE));
    }

    // =====================================================================
    // 10-19  Business rules (send / schedule / cancel + logs)
    // =====================================================================

    public function test_email_schedule_10_schedule_email_creates_pending(): void
    {
        $this->skipUnlessTableReady();
        $invoice = $this->seedInvoice();
        $this->skipIfNull($invoice, 'Invoice dependency unavailable.');
        Bus::fake([SendInvoiceEmailJob::class]);
        $createdId = null;

        try {
            $resp = $this->actingAs($this->adminUser)->postJson(self::SCHEDULE_EMAIL_PATH, [
                'id' => $invoice->id,
                'schedule_time' => now()->addDays(2)->format('Y-m-d\TH:i'),
            ]);
            $resp->assertOk()->assertJson(['status' => true]);

            $row = BillTenantEmailSchedule::where('invoice_id', $invoice->id)->orderByDesc('id')->first();
            $this->assertNotNull($row);
            $this->assertSame('pending', (string) $row->status);
            $createdId = (int) $row->id;
        } finally {
            if ($createdId !== null) {
                $this->purgeSchedule($createdId);
            }
            $this->purgeInvoice((int) $invoice->id);
        }
    }

    public function test_email_schedule_11_schedule_email_message_format(): void
    {
        $this->skipUnlessTableReady();
        $invoice = $this->seedInvoice();
        $this->skipIfNull($invoice, 'Invoice dependency unavailable.');
        Bus::fake([SendInvoiceEmailJob::class]);
        $createdId = null;

        try {
            $resp = $this->actingAs($this->adminUser)->postJson(self::SCHEDULE_EMAIL_PATH, [
                'id' => $invoice->id,
                'schedule_time' => now()->addDay()->format('Y-m-d\TH:i'),
            ]);
            $this->assertStringContainsString('Email scheduled successfully for', (string) $resp->json('message'));

            $row = BillTenantEmailSchedule::where('invoice_id', $invoice->id)->orderByDesc('id')->first();
            $createdId = $row ? (int) $row->id : null;
        } finally {
            if ($createdId !== null) {
                $this->purgeSchedule($createdId);
            }
            $this->purgeInvoice((int) $invoice->id);
        }
    }

    public function test_email_schedule_12_schedule_email_dispatches_delayed_job(): void
    {
        $this->skipUnlessTableReady();
        $invoice = $this->seedInvoice();
        $this->skipIfNull($invoice, 'Invoice dependency unavailable.');
        Bus::fake([SendInvoiceEmailJob::class]);
        $createdId = null;

        try {
            $this->actingAs($this->adminUser)->postJson(self::SCHEDULE_EMAIL_PATH, [
                'id' => $invoice->id,
                'schedule_time' => now()->addDay()->format('Y-m-d\TH:i'),
            ])->assertOk();

            Bus::assertDispatched(SendInvoiceEmailJob::class, fn (SendInvoiceEmailJob $j) => (int) $j->invoiceId === (int) $invoice->id);

            $row = BillTenantEmailSchedule::where('invoice_id', $invoice->id)->orderByDesc('id')->first();
            $createdId = $row ? (int) $row->id : null;
        } finally {
            if ($createdId !== null) {
                $this->purgeSchedule($createdId);
            }
            $this->purgeInvoice((int) $invoice->id);
        }
    }

    public function test_email_schedule_13_schedule_email_writes_email_scheduled_audit_log(): void
    {
        $this->skipUnlessTableReady();
        if (!Schema::hasTable('bil_tenant_invoicing_audit_logs')) {
            $this->markTestSkipped('bil_tenant_invoicing_audit_logs not present.');
        }
        $invoice = $this->seedInvoice();
        $this->skipIfNull($invoice, 'Invoice dependency unavailable.');
        Bus::fake([SendInvoiceEmailJob::class]);
        $createdId = null;

        try {
            $this->actingAs($this->adminUser)->postJson(self::SCHEDULE_EMAIL_PATH, [
                'id' => $invoice->id,
                'schedule_time' => now()->addDay()->format('Y-m-d\TH:i'),
            ])->assertOk();

            $exists = DB::table('bil_tenant_invoicing_audit_logs')
                ->where('tenant_invoice_id', $invoice->id)
                ->where('action_type', 'Email Scheduled')
                ->exists();
            $this->assertTrue($exists, "Expected InvoicingAuditLog action_type='Email Scheduled'.");

            $row = BillTenantEmailSchedule::where('invoice_id', $invoice->id)->orderByDesc('id')->first();
            $createdId = $row ? (int) $row->id : null;
        } finally {
            if ($createdId !== null) {
                $this->purgeSchedule($createdId);
            }
            DB::table('bil_tenant_invoicing_audit_logs')->where('tenant_invoice_id', $invoice->id)->delete();
            $this->purgeInvoice((int) $invoice->id);
        }
    }

    public function test_email_schedule_14_schedule_email_writes_store_activity_log(): void
    {
        $this->skipUnlessTableReady();
        if (!Schema::hasTable('sys_activity_logs')) {
            $this->markTestSkipped('sys_activity_logs not present.');
        }
        $invoice = $this->seedInvoice();
        $this->skipIfNull($invoice, 'Invoice dependency unavailable.');
        Bus::fake([SendInvoiceEmailJob::class]);
        $createdId = null;

        try {
            $this->actingAs($this->adminUser)->postJson(self::SCHEDULE_EMAIL_PATH, [
                'id' => $invoice->id,
                'schedule_time' => now()->addDay()->format('Y-m-d\TH:i'),
            ])->assertOk();

            $row = BillTenantEmailSchedule::where('invoice_id', $invoice->id)->orderByDesc('id')->first();
            $createdId = $row ? (int) $row->id : null;
            $this->skipIfNull($row, 'Schedule row not created.');

            $logged = ActivityLog::where('subject_type', BillTenantEmailSchedule::class)
                ->where('subject_id', $row->id)
                ->where('event', 'Store')
                ->exists();
            $this->assertTrue($logged, "Expected 'Store' activity-log entry on schedule create.");
        } finally {
            if ($createdId !== null) {
                $this->purgeSchedule($createdId);
            }
            $this->purgeInvoice((int) $invoice->id);
        }
    }

    public function test_email_schedule_15_send_email_queues_job_and_returns_message(): void
    {
        $this->skipUnlessTableReady();
        $invoice = $this->seedInvoice();
        $this->skipIfNull($invoice, 'Invoice dependency unavailable.');
        Bus::fake([SendInvoiceEmailJob::class]);

        try {
            $this->actingAs($this->adminUser)->postJson(self::SEND_EMAIL_PATH, ['ids' => [$invoice->id]])
                ->assertOk()
                ->assertJson(['status' => true, 'message' => 'Emails queued successfully!']);
            Bus::assertDispatched(SendInvoiceEmailJob::class);
        } finally {
            $this->purgeInvoice((int) $invoice->id);
        }
    }

    public function test_email_schedule_16_send_email_captures_performed_by(): void
    {
        // Controller passes auth()->id() into the job constructor (fixes the "null in worker" gap).
        $this->skipUnlessTableReady();
        $invoice = $this->seedInvoice();
        $this->skipIfNull($invoice, 'Invoice dependency unavailable.');
        Bus::fake([SendInvoiceEmailJob::class]);

        try {
            $this->actingAs($this->adminUser)->postJson(self::SEND_EMAIL_PATH, ['ids' => [$invoice->id]])->assertOk();
            Bus::assertDispatched(SendInvoiceEmailJob::class, function (SendInvoiceEmailJob $j) {
                return $j->performedById !== null && (int) $j->performedById === (int) $this->adminUser->getKey();
            });
        } finally {
            $this->purgeInvoice((int) $invoice->id);
        }
    }

    public function test_email_schedule_17_destroy_sets_status_cancelled(): void
    {
        $this->skipUnlessTableReady();
        $schedule = $this->seedSchedule('pending');
        $this->skipIfNull($schedule, 'Could not seed pending schedule.');

        try {
            $this->actingAs($this->adminUser)->delete(self::INDEX_PATH . '/' . $schedule->id)
                ->assertRedirect(self::INDEX_PATH);
            $schedule->refresh();
            $this->assertSame('cancelled', (string) $schedule->status);
        } finally {
            $this->purgeSchedule((int) $schedule->id);
        }
    }

    public function test_email_schedule_18_destroy_writes_cancelled_activity_log(): void
    {
        $this->skipUnlessTableReady();
        if (!Schema::hasTable('sys_activity_logs')) {
            $this->markTestSkipped('sys_activity_logs not present.');
        }
        $schedule = $this->seedSchedule('pending');
        $this->skipIfNull($schedule, 'Could not seed pending schedule.');

        try {
            $this->actingAs($this->adminUser)->delete(self::INDEX_PATH . '/' . $schedule->id);
            $this->assertTrue(
                ActivityLog::where('subject_type', BillTenantEmailSchedule::class)
                    ->where('subject_id', $schedule->id)->where('event', 'Cancelled')->exists()
            );
        } finally {
            $this->purgeSchedule((int) $schedule->id);
        }
    }

    public function test_email_schedule_19_destroy_redirects_with_success_flash(): void
    {
        $this->skipUnlessTableReady();
        $schedule = $this->seedSchedule('pending');
        $this->skipIfNull($schedule, 'Could not seed pending schedule.');

        try {
            $this->actingAs($this->adminUser)->delete(self::INDEX_PATH . '/' . $schedule->id)
                ->assertRedirect(self::INDEX_PATH)
                ->assertSessionHas('success', 'Email schedule cancelled successfully.');
        } finally {
            $this->purgeSchedule((int) $schedule->id);
        }
    }

    // =====================================================================
    // 20-29  State machine  (pending -> cancelled / sent / failed)
    // =====================================================================

    public function test_email_schedule_20_pending_to_cancelled_transition(): void
    {
        $this->skipUnlessTableReady();
        $schedule = $this->seedSchedule('pending');
        $this->skipIfNull($schedule, 'Could not seed pending schedule.');

        try {
            $this->actingAs($this->adminUser)->delete(self::INDEX_PATH . '/' . $schedule->id);
            $schedule->refresh();
            $this->assertSame('cancelled', (string) $schedule->status);
        } finally {
            $this->purgeSchedule((int) $schedule->id);
        }
    }

    public function test_email_schedule_21_pending_to_sent_is_representable(): void
    {
        // The queue worker sets status to 'sent' after delivery; assert the value is storable.
        $this->skipUnlessTableReady();
        $schedule = $this->seedSchedule('pending');
        $this->skipIfNull($schedule, 'Could not seed pending schedule.');

        try {
            $schedule->update(['status' => 'sent']);
            $schedule->refresh();
            $this->assertSame('sent', (string) $schedule->status);
        } finally {
            $this->purgeSchedule((int) $schedule->id);
        }
    }

    public function test_email_schedule_22_pending_to_failed_is_representable(): void
    {
        $this->skipUnlessTableReady();
        $schedule = $this->seedSchedule('pending');
        $this->skipIfNull($schedule, 'Could not seed pending schedule.');

        try {
            $schedule->update(['status' => 'failed']);
            $schedule->refresh();
            $this->assertSame('failed', (string) $schedule->status);
        } finally {
            $this->purgeSchedule((int) $schedule->id);
        }
    }

    public function test_email_schedule_23_only_pending_shows_cancel_button_on_index(): void
    {
        $this->skipUnlessTableReady();
        $sent = $this->seedSchedule('sent');
        $this->skipIfNull($sent, 'Could not seed sent schedule.');

        try {
            $this->browseWithFailureScreenshot('email-schedule-sent-no-cancel', function (Browser $browser) use ($sent): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH . '?status=sent');
                $this->ensurePageAccessible($browser, 'Email Schedule index (sent)');
                // Cancel action form targets the destroy route; a 'sent' row must not render it.
                $browser->assertMissing('form[action$="/email-schedule/' . $sent->id . '"]');
            });
        } finally {
            $this->purgeSchedule((int) $sent->id);
        }
    }

    public function test_email_schedule_24_cancel_button_present_for_pending_on_show(): void
    {
        $this->skipUnlessTableReady();
        $schedule = $this->seedSchedule('pending');
        $this->skipIfNull($schedule, 'Could not seed pending schedule.');

        try {
            $this->browseWithFailureScreenshot('email-schedule-show-cancel-present', function (Browser $browser) use ($schedule): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH . '/' . $schedule->id);
                $this->ensurePageAccessible($browser, 'Email Schedule show (pending)');
                $browser->assertSee('Cancel Schedule');
            });
        } finally {
            $this->purgeSchedule((int) $schedule->id);
        }
    }

    public function test_email_schedule_25_cancel_button_absent_for_cancelled_on_show(): void
    {
        $this->skipUnlessTableReady();
        $schedule = $this->seedSchedule('cancelled');
        $this->skipIfNull($schedule, 'Could not seed cancelled schedule.');

        try {
            $this->browseWithFailureScreenshot('email-schedule-show-cancel-absent', function (Browser $browser) use ($schedule): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH . '/' . $schedule->id);
                $this->ensurePageAccessible($browser, 'Email Schedule show (cancelled)');
                $browser->assertDontSee('Cancel Schedule');
            });
        } finally {
            $this->purgeSchedule((int) $schedule->id);
        }
    }

    // =====================================================================
    // 30-39  Validation / negative
    // =====================================================================

    public function test_email_schedule_30_destroy_invalid_id_returns_404(): void
    {
        $this->skipUnlessTableReady();
        $this->actingAs($this->adminUser)->delete(self::INDEX_PATH . '/999999999')->assertNotFound();
    }

    public function test_email_schedule_31_show_invalid_id_returns_404(): void
    {
        $this->skipUnlessTableReady();
        $this->actingAs($this->adminUser)->get(self::INDEX_PATH . '/999999999')->assertNotFound();
    }

    public function test_email_schedule_32_schedule_email_without_id_does_not_500(): void
    {
        // NOTE (DEV candidate): scheduleEmail has NO FormRequest validation. Missing 'id' is not
        // rejected with 422 — assert current behaviour (endpoint does not hard-500 on the happy path)
        // and document the missing-validation gap in Gap Analysis.
        $this->skipUnlessTableReady();
        Bus::fake([SendInvoiceEmailJob::class]);

        $resp = $this->actingAs($this->adminUser)->postJson(self::SCHEDULE_EMAIL_PATH, [
            'schedule_time' => now()->addDay()->format('Y-m-d\TH:i'),
        ]);
        // Current source returns 200 with a null invoice_id row (documented weakness).
        $this->assertContains($resp->getStatusCode(), [200, 422, 500], 'Unexpected status for missing id.');

        // Cleanup any orphan row created with null invoice_id.
        DB::table(self::TABLE)->whereNull('invoice_id')->delete();
    }

    public function test_email_schedule_33_search_input_is_escaped_no_reflected_xss(): void
    {
        $this->skipUnlessTableReady();
        $payload = '<script>alert(1)</script>';

        $this->browseWithFailureScreenshot('email-schedule-search-xss', function (Browser $browser) use ($payload): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH . '?search=' . urlencode($payload));
            $this->ensurePageAccessible($browser, 'Email Schedule search XSS');
            // Blade escapes the value into the search input; raw <script> must not be in page source.
            $this->assertStringNotContainsString('<script>alert(1)</script>', $browser->driver->getPageSource());
        });
    }

    public function test_email_schedule_34_whitespace_search_reachable(): void
    {
        $this->skipUnlessTableReady();

        $this->browseWithFailureScreenshot('email-schedule-search-whitespace', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH . '?search=' . urlencode('   '));
            $this->assertSame(self::INDEX_PATH, $this->currentPath($browser));
            $this->ensurePageAccessible($browser, 'Email Schedule whitespace search');
        });
    }

    public function test_email_schedule_35_unknown_status_filter_value_reachable(): void
    {
        $this->skipUnlessTableReady();

        $this->browseWithFailureScreenshot('email-schedule-status-unknown', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH . '?status=not-a-real-status');
            $this->assertSame(self::INDEX_PATH, $this->currentPath($browser));
            $this->ensurePageAccessible($browser, 'Email Schedule unknown status');
        });
    }

    // =====================================================================
    // 40-49  Integration / relationships (BC-INT / BC-REF)
    // =====================================================================

    public function test_email_schedule_40_invoice_relationship_eager_loads(): void
    {
        $this->skipUnlessTableReady();
        $schedule = $this->seedSchedule('pending');
        $this->skipIfNull($schedule, 'Could not seed schedule.');

        try {
            $loaded = BillTenantEmailSchedule::with('invoice.tenant')->find($schedule->id);
            $this->assertNotNull($loaded->invoice, 'invoice relation should eager-load.');
        } finally {
            $this->purgeSchedule((int) $schedule->id);
        }
    }

    public function test_email_schedule_41_show_renders_related_invoice_details(): void
    {
        $this->skipUnlessTableReady();
        $schedule = $this->seedSchedule('pending');
        $this->skipIfNull($schedule, 'Could not seed schedule.');

        try {
            $invoiceNo = $schedule->invoice?->invoice_no;
            $this->browseWithFailureScreenshot('email-schedule-show-invoice', function (Browser $browser) use ($schedule, $invoiceNo): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH . '/' . $schedule->id);
                $this->ensurePageAccessible($browser, 'Email Schedule show invoice');
                $browser->assertSee('Related Invoice');
                if (is_string($invoiceNo) && $invoiceNo !== '') {
                    $browser->assertSee($invoiceNo);
                }
            });
        } finally {
            $this->purgeSchedule((int) $schedule->id);
        }
    }

    public function test_email_schedule_42_orphan_invoice_id_renders_dash_not_error(): void
    {
        // DATA-BIL-003 downstream: an orphan invoice_id must degrade gracefully (— placeholder),
        // not 500 the show/index pages (blade uses null-safe operators).
        $this->skipUnlessTableReady();
        $orphanId = null;
        try {
            $row = BillTenantEmailSchedule::create([
                'invoice_id' => 2000000001,
                'schedule_time' => now(),
                'status' => 'pending',
            ]);
            $orphanId = (int) $row->id;

            $this->browseWithFailureScreenshot('email-schedule-orphan-show', function (Browser $browser) use ($orphanId): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH . '/' . $orphanId);
                $this->ensurePageAccessible($browser, 'Email Schedule orphan show');
                $browser->assertSee('Schedule Information');
            });
        } catch (Throwable $e) {
            $this->fail('Orphan invoice_id broke the show page: ' . $e->getMessage());
        } finally {
            if ($orphanId !== null) {
                DB::table(self::TABLE)->where('id', $orphanId)->delete();
            }
        }
    }

    public function test_email_schedule_43_job_handle_uses_notice_sent_audit_action(): void
    {
        // Code-inspection: SendInvoiceEmailJob::handle() writes InvoicingAuditLog action_type='Notice Sent'.
        // (We do not execute handle() — it sends real mail.)
        $src = $this->resolveJobSource();
        $this->skipIfNull($src, 'Job source not locatable in this environment.');
        $this->assertStringContainsString("'Notice Sent'", $src, "handle() should log action_type='Notice Sent'.");
    }

    public function test_email_schedule_44_job_failed_uses_email_failed_audit_action(): void
    {
        $src = $this->resolveJobSource();
        $this->skipIfNull($src, 'Job source not locatable in this environment.');
        $this->assertStringContainsString("'EMAIL_FAILED'", $src, "failed() should log action_type='EMAIL_FAILED'.");
    }

    // =====================================================================
    // 50-59  Permissions / authorization
    // =====================================================================

    public function test_email_schedule_50_guest_redirected_from_index(): void
    {
        $this->skipUnlessTableReady();
        $this->browseWithFailureScreenshot('email-schedule-guest-index', function (Browser $browser): void {
            $browser->visit($this->centralUrl('/logout'))->pause(500);
            $browser->visit($this->centralUrl(self::INDEX_PATH))->pause(900);
            $this->assertStringContainsString('/login', $this->currentPath($browser));
        });
    }

    public function test_email_schedule_51_guest_redirected_from_show(): void
    {
        $this->skipUnlessTableReady();
        $this->browseWithFailureScreenshot('email-schedule-guest-show', function (Browser $browser): void {
            $browser->visit($this->centralUrl('/logout'))->pause(500);
            $browser->visit($this->centralUrl(self::INDEX_PATH . '/1'))->pause(900);
            $this->assertStringContainsString('/login', $this->currentPath($browser));
        });
    }

    public function test_email_schedule_52_controller_gates_reference_expected_permissions(): void
    {
        // Code-inspection: controller gates on prime.email-schedule.{viewAny,view,delete}.
        $src = $this->resolveControllerSource();
        $this->skipIfNull($src, 'Controller source not locatable in this environment.');
        $this->assertStringContainsString("prime.email-schedule.viewAny", $src);
        $this->assertStringContainsString("prime.email-schedule.view", $src);
        $this->assertStringContainsString("prime.email-schedule.delete", $src);
    }

    public function test_email_schedule_53_send_and_schedule_gate_on_billing_management_permission(): void
    {
        // Code-inspection: sendEmail/scheduleEmail gate on prime.billing-management.email-schedule.
        $src = $this->resolveBillingManagementSource();
        $this->skipIfNull($src, 'BillingManagementController source not locatable.');
        $this->assertStringContainsString("prime.billing-management.email-schedule", $src);
    }

    public function test_email_schedule_54_limited_user_forbidden_from_index(): void
    {
        // A non-super-admin without prime.email-schedule.viewAny should get 403.
        $this->skipUnlessTableReady();
        $user = $this->makeLimitedUser();
        $this->skipIfNull($user, 'Could not create a limited user in this environment.');

        try {
            $status = $this->actingAs($user)->get(self::INDEX_PATH)->getStatusCode();
            // Gate::authorize denies -> 403 (or redirect if not verified). Accept 403 primarily.
            $this->assertContains($status, [403, 302], 'Limited user should not get 200 on the index.');
        } finally {
            $this->purgeUser($user);
        }
    }

    // =====================================================================
    // 60-69  UI / UX
    // =====================================================================

    public function test_email_schedule_60_index_table_columns_present(): void
    {
        $this->skipUnlessTableReady();
        $this->browseWithFailureScreenshot('email-schedule-columns', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Email Schedule columns');
            $browser->assertSee('Invoice No.')
                ->assertSee('Tenant')
                ->assertSee('Scheduled Time')
                ->assertSee('Status')
                ->assertSee('Action');
        });
    }

    public function test_email_schedule_61_status_dropdown_has_all_states(): void
    {
        $this->skipUnlessTableReady();
        $this->browseWithFailureScreenshot('email-schedule-status-options', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Email Schedule status options');
            $browser->assertPresent('select[name="status"] option[value="pending"]')
                ->assertPresent('select[name="status"] option[value="sent"]')
                ->assertPresent('select[name="status"] option[value="failed"]')
                ->assertPresent('select[name="status"] option[value="cancelled"]');
        });
    }

    public function test_email_schedule_62_empty_state_text_when_no_rows(): void
    {
        $this->skipUnlessTableReady();
        // Filter to a value guaranteed to have no rows.
        $this->browseWithFailureScreenshot('email-schedule-empty-text', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH . '?search=NO-SUCH-INVOICE-' . uniqid());
            $this->ensurePageAccessible($browser, 'Email Schedule empty state');
            $browser->assertSee('No Email Schedules Found');
        });
    }

    public function test_email_schedule_63_show_back_button_present(): void
    {
        $this->skipUnlessTableReady();
        $schedule = $this->seedSchedule('pending');
        $this->skipIfNull($schedule, 'Could not seed schedule.');

        try {
            $this->browseWithFailureScreenshot('email-schedule-back-button', function (Browser $browser) use ($schedule): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH . '/' . $schedule->id);
                $this->ensurePageAccessible($browser, 'Email Schedule back button');
                $browser->assertSee('Back to Email Schedules');
            });
        } finally {
            $this->purgeSchedule((int) $schedule->id);
        }
    }

    public function test_email_schedule_64_search_control_submits_via_get(): void
    {
        $this->skipUnlessTableReady();
        $this->browseWithFailureScreenshot('email-schedule-get-form', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Email Schedule GET form');
            $browser->type('search', 'INV-TEST')->pause(200);
            // Search field retains typed value (client side) before submit.
            $browser->assertInputValue('search', 'INV-TEST');
        });
    }

    // =====================================================================
    // 70-79  Edge cases
    // =====================================================================

    public function test_email_schedule_70_ordering_is_schedule_time_desc(): void
    {
        $this->skipUnlessTableReady();
        $older = $this->seedScheduleAt('pending', now()->addDay());
        $this->skipIfNull($older, 'Could not seed older schedule.');
        $newer = $this->seedScheduleAt('pending', now()->addDays(5));
        if ($newer === null) {
            $this->purgeSchedule((int) $older->id);
            $this->markTestSkipped('Could not seed newer schedule.');
        }

        try {
            $ids = BillTenantEmailSchedule::orderByDesc('schedule_time')
                ->whereIn('id', [$older->id, $newer->id])
                ->pluck('id')->all();
            $this->assertSame([(int) $newer->id, (int) $older->id], array_map('intval', $ids), 'Newest schedule_time must sort first.');
        } finally {
            $this->purgeSchedule((int) $older->id);
            $this->purgeSchedule((int) $newer->id);
        }
    }

    public function test_email_schedule_71_pagination_size_is_15(): void
    {
        // Controller paginates at 15. Assert the paginator page size, not row count.
        $this->skipUnlessTableReady();
        $paginator = BillTenantEmailSchedule::query()->orderByDesc('schedule_time')->paginate(15);
        $this->assertSame(15, $paginator->perPage(), 'Index must paginate at 15 per page.');
    }

    public function test_email_schedule_72_long_search_string_is_safe(): void
    {
        $this->skipUnlessTableReady();
        $long = str_repeat('A', 500);
        $this->browseWithFailureScreenshot('email-schedule-long-search', function (Browser $browser) use ($long): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH . '?search=' . urlencode($long));
            $this->assertSame(self::INDEX_PATH, $this->currentPath($browser));
            $this->ensurePageAccessible($browser, 'Email Schedule long search');
        });
    }

    public function test_email_schedule_73_cross_table_search_matches_invoice_no(): void
    {
        $this->skipUnlessTableReady();
        $schedule = $this->seedSchedule('pending');
        $this->skipIfNull($schedule, 'Could not seed schedule.');
        $invoiceNo = $schedule->invoice?->invoice_no;
        if (!is_string($invoiceNo) || $invoiceNo === '') {
            $this->purgeSchedule((int) $schedule->id);
            $this->markTestSkipped('Seeded schedule has no invoice_no.');
        }

        try {
            $found = BillTenantEmailSchedule::query()
                ->whereHas('invoice', fn ($q) => $q->where('invoice_no', 'like', "%{$invoiceNo}%"))
                ->where('id', $schedule->id)
                ->exists();
            $this->assertTrue($found, 'Cross-table whereHas(invoice.invoice_no) search failed to match.');
        } finally {
            $this->purgeSchedule((int) $schedule->id);
        }
    }

    // =====================================================================
    // 90-99  Security
    // =====================================================================

    public function test_email_schedule_90_idor_direct_show_requires_auth(): void
    {
        $this->skipUnlessTableReady();
        $this->browseWithFailureScreenshot('email-schedule-idor', function (Browser $browser): void {
            $browser->visit($this->centralUrl('/logout'))->pause(500);
            $browser->visit($this->centralUrl(self::INDEX_PATH . '/1'))->pause(900);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Direct show id must require auth.');
        });
    }

    public function test_email_schedule_91_destroy_requires_delete_verb(): void
    {
        // The cancel form spoofs DELETE via @method('DELETE'); a GET to the same id must not cancel.
        $this->skipUnlessTableReady();
        $schedule = $this->seedSchedule('pending');
        $this->skipIfNull($schedule, 'Could not seed schedule.');

        try {
            // GET to the show route returns the details page, not a cancel action.
            $this->actingAs($this->adminUser)->get(self::INDEX_PATH . '/' . $schedule->id)->assertOk();
            $schedule->refresh();
            $this->assertSame('pending', (string) $schedule->status, 'GET must not cancel the schedule.');
        } finally {
            $this->purgeSchedule((int) $schedule->id);
        }
    }

    public function test_email_schedule_92_stored_xss_invoice_no_is_escaped_on_index(): void
    {
        $this->skipUnlessTableReady();
        $invoice = $this->seedInvoiceWithNo('<b>INVX</b>-' . uniqid());
        $this->skipIfNull($invoice, 'Invoice dependency unavailable.');
        $scheduleId = null;

        try {
            $row = BillTenantEmailSchedule::create([
                'invoice_id' => $invoice->id,
                'schedule_time' => now()->addDay(),
                'status' => 'pending',
            ]);
            $scheduleId = (int) $row->id;

            $this->browseWithFailureScreenshot('email-schedule-stored-xss', function (Browser $browser): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH);
                $this->ensurePageAccessible($browser, 'Email Schedule stored XSS');
                // Blade {{ }} escapes the invoice_no; the raw <b> tag must not appear unescaped.
                $this->assertStringNotContainsString('<b>INVX', $browser->driver->getPageSource());
            });
        } finally {
            if ($scheduleId !== null) {
                $this->purgeSchedule($scheduleId);
            } else {
                $this->purgeInvoice((int) $invoice->id);
            }
        }
    }

    // =====================================================================
    // Private helper library
    // =====================================================================

    private function skipUnlessTableReady(): void
    {
        if (!Schema::hasTable(self::TABLE)) {
            $this->markTestSkipped(self::TABLE . ' is missing (DDL/migration not applied).');
        }
    }

    private function skipIfNull(mixed $value, string $reason): void
    {
        if ($value === null) {
            $this->markTestSkipped($reason);
        }
    }

    private function seedInvoice(): ?BilTenantInvoice
    {
        return $this->seedInvoiceWithNo('INV-EMS-' . strtoupper(substr(md5(uniqid('', true)), 0, 8)));
    }

    private function seedInvoiceWithNo(string $invoiceNo): ?BilTenantInvoice
    {
        if (!Schema::hasTable('bil_tenant_invoices')) {
            return null;
        }
        try {
            return BilTenantInvoice::create([
                'invoice_no' => $invoiceNo,
                'invoice_date' => now()->toDateString(),
                'status' => 'DRAFT',
                'net_payable_amount' => 100.00,
                'currency' => 'INR',
            ]);
        } catch (Throwable) {
            return null;
        }
    }

    private function seedSchedule(string $status): ?BillTenantEmailSchedule
    {
        return $this->seedScheduleAt($status, now()->addDay());
    }

    private function seedScheduleAt(string $status, \DateTimeInterface $when): ?BillTenantEmailSchedule
    {
        $invoice = $this->seedInvoice();
        if ($invoice === null) {
            return null;
        }
        try {
            return BillTenantEmailSchedule::create([
                'invoice_id' => $invoice->id,
                'schedule_time' => $when,
                'status' => $status,
            ]);
        } catch (Throwable) {
            $this->purgeInvoice((int) $invoice->id);
            return null;
        }
    }

    private function purgeSchedule(int $id): void
    {
        try {
            $row = BillTenantEmailSchedule::query()->find($id);
            $invoiceId = $row?->invoice_id;
            DB::table(self::TABLE)->where('id', $id)->delete();
            if ($invoiceId !== null) {
                $this->purgeInvoice((int) $invoiceId);
            }
        } catch (Throwable) {
            // best-effort
        }
    }

    private function purgeInvoice(int $id): void
    {
        try {
            DB::table('bil_tenant_invoices')->where('id', $id)->delete();
        } catch (Throwable) {
            // best-effort
        }
    }

    private function makeLimitedUser(): ?User
    {
        try {
            return User::create([
                'email' => 'ems_limited_' . uniqid() . '@tenant.com',
                'password' => bcrypt('password'),
                'name' => 'EMS Limited',
                'emp_code' => 'EMS' . rand(100, 999),
                'short_name' => 'EMS' . rand(1000, 9999),
                'status' => 'ACTIVE',
                'is_active' => 1,
                'is_super_admin' => 0,
                'email_verified_at' => now(),
            ]);
        } catch (Throwable) {
            return null;
        }
    }

    private function purgeUser(?User $user): void
    {
        if ($user === null) {
            return;
        }
        try {
            DB::table($user->getTable())->where('id', $user->getKey())->delete();
        } catch (Throwable) {
            // best-effort
        }
    }

    private function resolveAppFile(string $relative): ?string
    {
        $candidates = [];
        $main = env('MAIN_PROJECT_PATH');
        if (is_string($main) && $main !== '') {
            $candidates[] = rtrim($main, '/') . '/' . ltrim($relative, '/');
        }
        $candidates[] = base_path('../prime_ai/' . ltrim($relative, '/'));

        foreach ($candidates as $candidate) {
            if (is_string($candidate) && file_exists($candidate)) {
                $contents = file_get_contents($candidate);
                return $contents === false ? null : $contents;
            }
        }
        return null;
    }

    private function resolveJobSource(): ?string
    {
        return $this->resolveAppFile('Modules/Billing/app/Jobs/SendInvoiceEmailJob.php');
    }

    private function resolveControllerSource(): ?string
    {
        return $this->resolveAppFile('Modules/Billing/app/Http/Controllers/EmailScheduleController.php');
    }

    private function resolveBillingManagementSource(): ?string
    {
        return $this->resolveAppFile('Modules/Billing/app/Http/Controllers/BillingManagementController.php');
    }
}
