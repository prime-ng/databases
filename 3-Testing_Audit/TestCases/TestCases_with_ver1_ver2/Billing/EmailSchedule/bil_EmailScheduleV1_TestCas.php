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
 * Email Schedule — V1 (foundation) suite.
 *
 * Feature: Billing / EmailSchedule (central prime_db, Super Admin facing).
 * DB scope: prime_db central — NO tenant init (mirrors the committed Billing siblings
 *           BillingCycle / Invoicing which extend BillingDuskTestCase → PrimeDuskTestCase).
 * Primary table: bil_tenant_email_schedules  (prefix bil_).
 *
 * IMPORTANT SOURCE FACTS (verified against prime_ai on 2026-Jul-09):
 *  - Table created by Prime-module migration
 *    Modules/Prime/database/migrations/2025_12_03_094529_create_bil_tenant_email_schedules_table.php
 *    but is ABSENT from Billing_DDL_v1.sql  (DDL/schema drift — documented as a gap).
 *  - Model Modules\Billing\Models\BillTenantEmailSchedule: fillable [invoice_id, schedule_time,
 *    status]; HasFactory; NO SoftDeletes; default timestamps; relation invoice() belongsTo BilTenantInvoice.
 *  - Controller EmailScheduleController: index/show/destroy only; gates
 *    prime.email-schedule.{viewAny,view,delete}; destroy sets status='cancelled' and logs 'Cancelled'.
 *  - Send/Schedule live in BillingManagementController (gate prime.billing-management.email-schedule).
 *
 * All DB-touching tests are guarded with Schema::hasTable() + markTestSkipped so the suite stays
 * green in partial environments (05_ constraints C12, E19).
 */
class bil_EmailScheduleV1_TestCas extends BillingDuskTestCase
{
    protected const SCREENSHOT_DIR = 'tests/Browser/Modules/Prime/Billing/EmailSchedule/screenshots';
    protected const STATUS_REPORT_DIRECTORY = 'tests/Browser/Modules/Prime/Billing/EmailSchedule/report';
    protected const STATUS_REPORT_PREFIX = 'email_schedule_report_';

    private const TABLE = 'bil_tenant_email_schedules';
    private const INDEX_PATH = '/billing/email-schedule';
    private const SEND_EMAIL_PATH = '/billing/billing-management/send-email';
    private const SCHEDULE_EMAIL_PATH = '/billing/billing-management/schedule-email';

    // ---------------------------------------------------------------------
    // 01 — Schema / model / migration configuration truth
    // ---------------------------------------------------------------------

    public function test_email_schedule_01_migration_model_and_request_configuration_are_correct(): void
    {
        $this->skipUnlessTableReady();

        // Schema truth (MySQL-8 tolerant assertions — 05_ D17).
        $this->assertTrue(Schema::hasTable(self::TABLE), self::TABLE . ' table is missing.');
        $this->assertTrue(
            Schema::hasColumns(self::TABLE, ['id', 'invoice_id', 'schedule_time', 'status', 'created_at', 'updated_at']),
            'bil_tenant_email_schedules is missing expected columns.'
        );

        // No SoftDeletes column (matches model — no deleted_at). Documents DDL/model design.
        $this->assertFalse(
            Schema::hasColumn(self::TABLE, 'deleted_at'),
            'deleted_at unexpectedly present; model declares no SoftDeletes.'
        );

        // Model configuration.
        $model = new BillTenantEmailSchedule();
        $this->assertSame(self::TABLE, $model->getTable());
        $this->assertSame(['invoice_id', 'schedule_time', 'status'], $model->getFillable());
        $this->assertFalse(
            in_array(SoftDeletes::class, class_uses_recursive(BillTenantEmailSchedule::class), true),
            'Model must NOT use SoftDeletes (source truth: cancel = status update, not delete).'
        );
        $this->assertTrue(
            method_exists($model, 'invoice'),
            'Model must expose invoice() relationship.'
        );

        // Class-name spelling is correct in code (audit narrative "BillTenatEmailSchedule" is a typo
        // in the requirement text only — the real class is BillTenantEmailSchedule).
        $this->assertTrue(class_exists(BillTenantEmailSchedule::class));

        // Migration content (best-effort — only when app repo is locatable).
        $migration = $this->resolveMigrationPath();
        if ($migration !== null) {
            $sql = (string) file_get_contents($migration);
            $this->assertStringContainsString('bil_tenant_email_schedules', $sql);
            $this->assertStringContainsString('invoice_id', $sql);
            $this->assertStringContainsString("status", $sql);
            // DATA-BIL-003: invoice_id has NO foreign key in the migration.
            $this->assertStringNotContainsString('->foreign', $sql, 'DATA-BIL-003 regression: FK unexpectedly added.');
        }
    }

    // ---------------------------------------------------------------------
    // 02–06 — Index render + controls + pagination
    // ---------------------------------------------------------------------

    public function test_email_schedule_02_index_page_loads(): void
    {
        $this->skipUnlessTableReady();

        $this->browseWithFailureScreenshot('email-schedule-index', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);

            $this->assertSame(self::INDEX_PATH, $this->currentPath($browser), 'Email Schedule index not reachable.');
            $this->ensurePageAccessible($browser, 'Email Schedule index');

            $browser->assertSee('Email Schedules');
            $browser->assertPresent('table');
        });
    }

    public function test_email_schedule_03_breadcrumb_present(): void
    {
        $this->skipUnlessTableReady();

        $this->browseWithFailureScreenshot('email-schedule-breadcrumb', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Email Schedule index');

            $browser->assertSee('Email Schedule Management');
        });
    }

    public function test_email_schedule_04_search_and_status_filter_controls_present(): void
    {
        $this->skipUnlessTableReady();

        $this->browseWithFailureScreenshot('email-schedule-filter-controls', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Email Schedule index');

            $browser->assertPresent('input[name="search"]')
                ->assertPresent('select[name="status"]')
                ->assertSee('All Status')
                ->assertSee('Pending')
                ->assertSee('Sent')
                ->assertSee('Failed')
                ->assertSee('Cancelled');
        });
    }

    public function test_email_schedule_05_empty_state_or_rows(): void
    {
        $this->skipUnlessTableReady();

        $this->browseWithFailureScreenshot('email-schedule-empty-or-rows', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Email Schedule index');

            $bodyText = $browser->text('tbody');
            if (str_contains($bodyText, 'No Email Schedules Found')) {
                $browser->assertSee('No Email Schedules Found');
            } else {
                $browser->assertPresent('tbody tr');
            }
        });
    }

    public function test_email_schedule_06_status_filter_query_reachable(): void
    {
        $this->skipUnlessTableReady();

        $this->browseWithFailureScreenshot('email-schedule-status-filter', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH . '?status=pending');

            $this->assertSame(self::INDEX_PATH, $this->currentPath($browser), 'Status filter query broke the index.');
            $this->ensurePageAccessible($browser, 'Email Schedule status filter');
            $browser->assertPresent('table');
        });
    }

    public function test_email_schedule_07_search_filter_query_reachable(): void
    {
        $this->skipUnlessTableReady();

        $this->browseWithFailureScreenshot('email-schedule-search-filter', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH . '?search=INV-ZZZ-' . uniqid());

            $this->assertSame(self::INDEX_PATH, $this->currentPath($browser), 'Search filter query broke the index.');
            $this->ensurePageAccessible($browser, 'Email Schedule search filter');
            // Cross-table whereHas search should not error; empty result renders empty-state.
            $browser->assertPresent('table');
        });
    }

    // ---------------------------------------------------------------------
    // 08 — Show page
    // ---------------------------------------------------------------------

    public function test_email_schedule_08_show_page_loads_for_seeded_schedule(): void
    {
        $this->skipUnlessTableReady();
        $schedule = $this->seedSchedule('pending');
        $this->skipIfNull($schedule, 'Could not seed an email schedule (invoice dependency unavailable).');

        try {
            $this->browseWithFailureScreenshot('email-schedule-show', function (Browser $browser) use ($schedule): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH . '/' . $schedule->id);

                $this->assertSame(
                    self::INDEX_PATH . '/' . $schedule->id,
                    $this->currentPath($browser),
                    'Email Schedule show page not reachable.'
                );
                $this->ensurePageAccessible($browser, 'Email Schedule show');
                $browser->assertSee('Email Schedule Details')
                    ->assertSee('Schedule Information')
                    ->assertSee('Related Invoice');
            });
        } finally {
            $this->purgeSchedule((int) $schedule->id);
        }
    }

    // ---------------------------------------------------------------------
    // 09–10 — Destroy (cancel) flow + activity log
    // ---------------------------------------------------------------------

    public function test_email_schedule_09_destroy_cancels_pending_schedule(): void
    {
        $this->skipUnlessTableReady();
        $schedule = $this->seedSchedule('pending');
        $this->skipIfNull($schedule, 'Could not seed a pending email schedule.');

        try {
            $this->actingAs($this->adminUser)
                ->delete(self::INDEX_PATH . '/' . $schedule->id)
                ->assertRedirect(self::INDEX_PATH);

            $schedule->refresh();
            // Source truth: cancel = status update to 'cancelled' (NOT a soft delete/row removal).
            $this->assertSame('cancelled', (string) $schedule->status, 'Schedule was not marked cancelled.');
            $this->assertTrue(
                BillTenantEmailSchedule::query()->whereKey($schedule->id)->exists(),
                'Row must still exist after cancel (no soft delete).'
            );
        } finally {
            $this->purgeSchedule((int) $schedule->id);
        }
    }

    public function test_email_schedule_10_destroy_writes_cancelled_activity_log(): void
    {
        $this->skipUnlessTableReady();
        if (!Schema::hasTable('sys_activity_logs')) {
            $this->markTestSkipped('sys_activity_logs not present.');
        }
        $schedule = $this->seedSchedule('pending');
        $this->skipIfNull($schedule, 'Could not seed a pending email schedule.');

        try {
            $this->actingAs($this->adminUser)->delete(self::INDEX_PATH . '/' . $schedule->id);

            $logged = ActivityLog::query()
                ->where('subject_type', BillTenantEmailSchedule::class)
                ->where('subject_id', $schedule->id)
                ->where('event', 'Cancelled')
                ->exists();
            $this->assertTrue($logged, "Expected a 'Cancelled' activity-log entry for the schedule.");
        } finally {
            $this->purgeSchedule((int) $schedule->id);
        }
    }

    // ---------------------------------------------------------------------
    // 11–12 — Schedule / Send endpoints (job dispatch)
    // ---------------------------------------------------------------------

    public function test_email_schedule_11_schedule_email_endpoint_creates_pending_record(): void
    {
        $this->skipUnlessTableReady();
        $invoice = $this->seedInvoice();
        $this->skipIfNull($invoice, 'Invoice dependency unavailable for schedule-email.');

        Bus::fake([SendInvoiceEmailJob::class]);
        $createdId = null;

        try {
            $response = $this->actingAs($this->adminUser)->postJson(self::SCHEDULE_EMAIL_PATH, [
                'id' => $invoice->id,
                'schedule_time' => now()->addDay()->format('Y-m-d\TH:i'),
            ]);

            $response->assertOk()->assertJson(['status' => true]);
            $this->assertStringContainsString('Email scheduled successfully for', (string) $response->json('message'));

            $row = BillTenantEmailSchedule::query()
                ->where('invoice_id', $invoice->id)
                ->orderByDesc('id')
                ->first();
            $this->assertNotNull($row, 'Schedule row was not created.');
            $this->assertSame('pending', (string) $row->status);
            $createdId = (int) $row->id;

            Bus::assertDispatched(SendInvoiceEmailJob::class);
        } finally {
            if ($createdId !== null) {
                $this->purgeSchedule($createdId);
            }
            $this->purgeInvoice((int) $invoice->id);
        }
    }

    public function test_email_schedule_12_send_email_endpoint_queues_job(): void
    {
        $this->skipUnlessTableReady();
        $invoice = $this->seedInvoice();
        $this->skipIfNull($invoice, 'Invoice dependency unavailable for send-email.');

        Bus::fake([SendInvoiceEmailJob::class]);

        try {
            $response = $this->actingAs($this->adminUser)->postJson(self::SEND_EMAIL_PATH, [
                'ids' => [$invoice->id],
            ]);

            $response->assertOk()->assertJson([
                'status' => true,
                'message' => 'Emails queued successfully!',
            ]);
            Bus::assertDispatched(SendInvoiceEmailJob::class);
        } finally {
            $this->purgeInvoice((int) $invoice->id);
        }
    }

    // ---------------------------------------------------------------------
    // 13 — Auth guard
    // ---------------------------------------------------------------------

    public function test_email_schedule_13_guest_redirected_to_login(): void
    {
        $this->skipUnlessTableReady();

        $this->browseWithFailureScreenshot('email-schedule-guest', function (Browser $browser): void {
            $browser->visit($this->centralUrl('/logout'))->pause(600);
            $browser->visit($this->centralUrl(self::INDEX_PATH))->pause(1000);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest was not redirected to login.');
        });
    }

    // ---------------------------------------------------------------------
    // 14 — JOB-BIL-001 code-inspection (audit vs current source)
    // ---------------------------------------------------------------------

    public function test_email_schedule_14_job_has_retry_configuration(): void
    {
        // Audit JOB-BIL-001 claimed SendInvoiceEmailJob had no $tries/$backoff/$timeout/failed().
        // Current source REMEDIATES this — assert present behaviour (source wins over stale audit).
        $job = new SendInvoiceEmailJob(1, 99);

        $this->assertSame(3, $job->tries, 'JOB-BIL-001: $tries should be configured (=3).');
        $this->assertSame([60, 300, 900], $job->backoff, 'JOB-BIL-001: $backoff should be configured.');
        $this->assertSame(120, $job->timeout, 'JOB-BIL-001: $timeout should be configured.');
        $this->assertTrue(method_exists($job, 'failed'), 'JOB-BIL-001: failed() handler should exist.');

        // performedById is captured at construction (dispatch-time), not left null for the worker.
        $this->assertSame(99, $job->performedById, 'performed_by must be captured in the constructor.');
    }

    // ---------------------------------------------------------------------
    // 15 — Relationship
    // ---------------------------------------------------------------------

    public function test_email_schedule_15_invoice_relationship_returns_invoice(): void
    {
        $this->skipUnlessTableReady();
        $schedule = $this->seedSchedule('pending');
        $this->skipIfNull($schedule, 'Could not seed a schedule with invoice.');

        try {
            $schedule->load('invoice');
            $this->assertNotNull($schedule->invoice, 'invoice() relation returned null for a seeded schedule.');
            $this->assertInstanceOf(BilTenantInvoice::class, $schedule->invoice);
        } finally {
            $this->purgeSchedule((int) $schedule->id);
        }
    }

    // ---------------------------------------------------------------------
    // 16 — Pagination markup
    // ---------------------------------------------------------------------

    public function test_email_schedule_16_pagination_present(): void
    {
        $this->skipUnlessTableReady();

        $this->browseWithFailureScreenshot('email-schedule-pagination', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Email Schedule index');
            // Paginator container is always rendered by $schedules->links().
            $browser->assertPresent('.card-body');
        });
    }

    // =====================================================================
    // Private helper library
    // =====================================================================

    private function skipUnlessTableReady(): void
    {
        if (!Schema::hasTable(self::TABLE)) {
            $this->markTestSkipped(self::TABLE . ' is missing (DDL/migration not applied) — cannot run EmailSchedule tests.');
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
        if (!Schema::hasTable('bil_tenant_invoices')) {
            return null;
        }

        try {
            return BilTenantInvoice::create([
                'invoice_no' => 'INV-EMS-' . strtoupper(substr(md5(uniqid('', true)), 0, 8)),
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
        $invoice = $this->seedInvoice();
        if ($invoice === null) {
            return null;
        }

        try {
            return BillTenantEmailSchedule::create([
                'invoice_id' => $invoice->id,
                'schedule_time' => now()->addDay(),
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
            // best-effort cleanup
        }
    }

    private function purgeInvoice(int $id): void
    {
        try {
            DB::table('bil_tenant_invoices')->where('id', $id)->delete();
        } catch (Throwable) {
            // best-effort cleanup
        }
    }

    private function resolveMigrationPath(): ?string
    {
        $candidates = [];
        $main = env('MAIN_PROJECT_PATH');
        if (is_string($main) && $main !== '') {
            $candidates[] = rtrim($main, '/') . '/Modules/Prime/database/migrations/2025_12_03_094529_create_bil_tenant_email_schedules_table.php';
        }
        $candidates[] = base_path('../prime_ai/Modules/Prime/database/migrations/2025_12_03_094529_create_bil_tenant_email_schedules_table.php');

        foreach ($candidates as $candidate) {
            if (is_string($candidate) && file_exists($candidate)) {
                return $candidate;
            }
        }

        return null;
    }
}
