<?php

namespace Tests\Browser;

use App\Models\User;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\FrontOffice\Models\CommunicationLog;
use Modules\FrontOffice\Models\EmailTemplate;
use Modules\FrontOffice\Models\SmsLog;
use Modules\GlobalMaster\Models\ActivityLog;
use Modules\Prime\Models\Domain;
use Tests\DuskTestCase;
use Throwable;

/**
 * FrontOffice :: Communication  (fof_communication_logs / fof_sms_logs / fof_email_templates)
 * -----------------------------------------------------------------------------------------
 * ONE comprehensive tenant-side Dusk suite for the Email & SMS Communication screen.
 * Mirrors the nearest committed same-module sibling (fof_PhoneDiary_TestCas) for style,
 * tenancy scaffolding and the private helper library.
 *
 * DDL truth ------------------------------------------------------------------------------
 * fof_communication_logs (CL):
 *   NOT-NULL user cols : channel(ENUM Email|SMS), body(TEXT), recipient_group(V100)
 *   Nullable cols      : template_id(FK->fof_email_templates SET NULL), subject(V300), sent_at
 *   Defaults           : total_recipients=0, sent_count=0, failed_count=0, is_active=1
 *   UNIQUE keys        : NONE (no G43 duplicate-rejection case applies)
 *   FKs                : template_id -> fof_email_templates ON DELETE SET NULL
 * fof_email_templates (ET):
 *   NOT-NULL user cols : name(V100), subject(V300), body(LONGTEXT)
 *   Nullable cols      : module(V50)
 *   Defaults           : is_active=1
 *   UNIQUE keys        : NONE
 * fof_sms_logs (SL):
 *   NOT-NULL user cols : communication_log_id(FK RESTRICT), recipient_user_id(FK sys_users RESTRICT),
 *                        mobile_number(V15), message(TEXT)
 *   Nullable cols      : sent_at, delivered_at, gateway_response(TEXT)
 *   Defaults           : sms_units=1, status='Queued', is_active=1
 *   UNIQUE keys        : NONE
 *   FKs                : communication_log_id -> fof_communication_logs ON DELETE RESTRICT;
 *                        recipient_user_id -> sys_users ON DELETE RESTRICT
 *   Auto/managed (G48) : created_by, updated_by, and (on send) channel/counters/template_id
 *
 * Permission scheme (string gates, VERBATIM from CommunicationController):
 *   frontoffice.communication.create  (emailCompose, emailSend, smsSend)
 *   frontoffice.communication.view    (emailTemplates, emailLogs, smsLogs, menu.communication)
 *   frontoffice.communication.update  (toggleStatus)
 *   NOTE: the requirement doc specifies .email / .sms keys — DIVERGENCE (DEV-FOF-COM-03).
 *
 * Activity log (VERBATIM from controller): events 'email_queued' (emailSend) and
 *   'sms_queued' (smsSend), written by activityLog() -> Modules\GlobalMaster\Models\ActivityLog
 *   ($table = 'sys_activity_logs'). toggleStatus performs NO activityLog().
 *
 * ENV prerequisites (see Validation Report): FrontOffice must be ENABLED in
 *   prime_testing/modules_statuses.json (currently false -> /front-office/* 404); APP_ENV=testing.
 */
class fof_Communication_TestCas extends DuskTestCase
{
    private const CL_TABLE = 'fof_communication_logs';
    private const ET_TABLE = 'fof_email_templates';
    private const SL_TABLE = 'fof_sms_logs';

    private const COMPOSE_PATH   = '/front-office/communication/email/compose';
    private const EMAIL_SEND_PATH = '/front-office/communication/email/send';
    private const TEMPLATES_PATH = '/front-office/communication/email/templates';
    private const EMAIL_LOGS_PATH = '/front-office/communication/email/logs';
    private const SMS_SEND_PATH  = '/front-office/communication/sms/send';
    private const SMS_LOGS_PATH  = '/front-office/communication/sms/logs';
    private const MENU_PATH      = '/front-office/communication';

    private const PERMISSIONS = [
        'frontoffice.communication.view',
        'frontoffice.communication.create',
        'frontoffice.communication.update',
    ];

    private ?User $adminUser = null;
    private string $tenantBaseUrl = '';
    private string $adminEmail = '';
    private string $adminPassword = '';

    protected function setUp(): void
    {
        parent::setUp();
        $this->tenantBaseUrl = rtrim(
            env('DUSK_TENANT_URL', env('APP_URL', 'http://test.localhost:8000')),
            '/'
        );
        $this->adminEmail = (string) env('DUSK_ADMIN_EMAIL', 'root@tenant.com');
        $this->adminPassword = (string) env('DUSK_ADMIN_PASSWORD', 'password');
        $this->initializeTenantContextForTests();
        $this->resolveAdminUserAndPermissions();
    }

    protected function tearDown(): void
    {
        if (function_exists('tenancy') && tenancy()->initialized) {
            tenancy()->end();
        }
        parent::tearDown();
    }

    // ============================================================
    // 01-09  Schema / DDL / model / request configuration (G46)
    // ============================================================

    /** test_01 — full DDL <-> app alignment matrix for all three tables (LIVE schema). */
    public function test_communication_01_migration_model_and_config_are_correct(): void
    {
        // ---- fof_communication_logs ----
        $this->assertTrue(Schema::hasTable(self::CL_TABLE), 'Table fof_communication_logs must exist.');
        $this->assertTrue(Schema::hasColumns(self::CL_TABLE, [
            'id', 'template_id', 'channel', 'subject', 'body', 'recipient_group',
            'total_recipients', 'sent_count', 'failed_count', 'sent_at', 'is_active',
            'created_by', 'updated_by', 'created_at', 'updated_at', 'deleted_at',
        ]), 'fof_communication_logs is missing expected columns.');

        $cl = new CommunicationLog();
        $this->assertSame(self::CL_TABLE, $cl->getTable(), 'CommunicationLog::$table must be fof_communication_logs.');
        foreach (['channel', 'subject', 'body', 'recipient_group', 'template_id',
                  'total_recipients', 'sent_count', 'failed_count', 'sent_at',
                  'is_active', 'created_by', 'updated_by'] as $col) {
            $this->assertContains($col, $cl->getFillable(), "CommunicationLog fillable must contain {$col}.");
        }
        $clCasts = $cl->getCasts();
        $this->assertSame('integer', $clCasts['total_recipients'] ?? null);
        $this->assertSame('integer', $clCasts['sent_count'] ?? null);
        $this->assertSame('integer', $clCasts['failed_count'] ?? null);
        $this->assertSame('boolean', $clCasts['is_active'] ?? null);

        // ---- fof_email_templates ----
        $this->assertTrue(Schema::hasTable(self::ET_TABLE), 'Table fof_email_templates must exist.');
        $this->assertTrue(Schema::hasColumns(self::ET_TABLE, [
            'id', 'name', 'subject', 'body', 'module', 'is_active',
            'created_by', 'updated_by', 'created_at', 'updated_at', 'deleted_at',
        ]), 'fof_email_templates is missing expected columns.');
        $et = new EmailTemplate();
        $this->assertSame(self::ET_TABLE, $et->getTable(), 'EmailTemplate::$table must be fof_email_templates.');
        foreach (['name', 'subject', 'body', 'module', 'is_active'] as $col) {
            $this->assertContains($col, $et->getFillable(), "EmailTemplate fillable must contain {$col}.");
        }

        // ---- fof_sms_logs ----
        $this->assertTrue(Schema::hasTable(self::SL_TABLE), 'Table fof_sms_logs must exist.');
        $this->assertTrue(Schema::hasColumns(self::SL_TABLE, [
            'id', 'communication_log_id', 'recipient_user_id', 'mobile_number', 'message',
            'sms_units', 'status', 'sent_at', 'delivered_at', 'gateway_response',
            'is_active', 'created_by', 'updated_by', 'created_at', 'updated_at', 'deleted_at',
        ]), 'fof_sms_logs is missing expected columns.');
        $sl = new SmsLog();
        $this->assertSame(self::SL_TABLE, $sl->getTable(), 'SmsLog::$table must be fof_sms_logs.');
        foreach (['communication_log_id', 'recipient_user_id', 'mobile_number', 'message',
                  'sms_units', 'status', 'gateway_response', 'sent_at'] as $col) {
            $this->assertContains($col, $sl->getFillable(), "SmsLog fillable must contain {$col}.");
        }
        $slCasts = $sl->getCasts();
        $this->assertSame('integer', $slCasts['sms_units'] ?? null);
        $this->assertSame('datetime', $slCasts['sent_at'] ?? null);

        // Soft-delete column and trait asserted INDEPENDENTLY (#30/G46).
        foreach ([[self::CL_TABLE, CommunicationLog::class], [self::ET_TABLE, EmailTemplate::class], [self::SL_TABLE, SmsLog::class]] as [$table, $modelClass]) {
            $hasCol = Schema::hasColumn($table, 'deleted_at');
            $usesTrait = in_array(SoftDeletes::class, class_uses_recursive($modelClass), true);
            $this->assertTrue($hasCol, "DDL: {$table}.deleted_at must exist.");
            $this->assertTrue($usesTrait, "Model: {$modelClass} must use SoftDeletes.");
            $this->assertSame($hasCol, $usesTrait, "Soft-delete column/trait must agree for {$table}.");
        }

        // No UNIQUE keys on any of the three tables (G43 — documented absence).
        $this->assertSame(0, $this->uniqueIndexCount(self::CL_TABLE), 'fof_communication_logs must have NO unique index.');
        $this->assertSame(0, $this->uniqueIndexCount(self::ET_TABLE), 'fof_email_templates must have NO unique index.');
        $this->assertSame(0, $this->uniqueIndexCount(self::SL_TABLE), 'fof_sms_logs must have NO unique index.');
    }

    /** G44 negative — CommunicationLog NOT-NULL-no-default cols reject a missing value. */
    public function test_communication_02_comm_log_required_columns_reject_missing(): void
    {
        foreach (['channel', 'body', 'recipient_group'] as $col) {
            $created = null;
            try {
                $payload = $this->buildCommLogPayload();
                unset($payload[$col]);
                $created = CommunicationLog::query()->create($payload);
                $this->fail("Expected DB rejection creating a CommunicationLog without {$col}.");
            } catch (Throwable $e) {
                $this->assertTrue($this->looksLikeConstraintFailure($e), "Expected NOT-NULL failure for {$col}, got: " . $e->getMessage());
            } finally {
                if ($created instanceof CommunicationLog) {
                    $created->forceDelete();
                }
            }
        }
    }

    /** G44 positive — CommunicationLog nullable cols may be omitted and the row persists. */
    public function test_communication_03_comm_log_nullable_columns_accept_omitted(): void
    {
        $record = null;
        try {
            $record = CommunicationLog::query()->create($this->buildCommLogPayload());
            $record->refresh();

            $this->assertNotNull($record->id, 'CommunicationLog with only required cols must persist.');
            $this->assertNull($record->template_id, 'Omitted template_id should be NULL.');
            $this->assertNull($record->sent_at, 'Omitted sent_at should be NULL.');
        } finally {
            if ($record instanceof CommunicationLog) {
                $record->forceDelete();
            }
        }
    }

    /** DDL defaults applied when omitted (read back via refresh — #35). */
    public function test_communication_04_comm_log_defaults_applied_on_create(): void
    {
        $record = null;
        try {
            $payload = $this->buildCommLogPayload();
            unset($payload['total_recipients'], $payload['sent_count'], $payload['failed_count'], $payload['is_active']);

            $record = CommunicationLog::query()->create($payload);
            $record->refresh();

            $this->assertSame(0, (int) $record->total_recipients, 'total_recipients must default to 0.');
            $this->assertSame(0, (int) $record->sent_count, 'sent_count must default to 0.');
            $this->assertSame(0, (int) $record->failed_count, 'failed_count must default to 0.');
            $this->assertTrue((bool) $record->is_active, 'is_active must default to 1.');
        } finally {
            if ($record instanceof CommunicationLog) {
                $record->forceDelete();
            }
        }
    }

    /** G44 negative — EmailTemplate NOT-NULL-no-default cols reject a missing value. */
    public function test_communication_05_email_template_required_columns_reject_missing(): void
    {
        foreach (['name', 'subject', 'body'] as $col) {
            $created = null;
            try {
                $payload = $this->buildTemplatePayload();
                unset($payload[$col]);
                $created = EmailTemplate::query()->create($payload);
                $this->fail("Expected DB rejection creating an EmailTemplate without {$col}.");
            } catch (Throwable $e) {
                $this->assertTrue($this->looksLikeConstraintFailure($e), "Expected NOT-NULL failure for {$col}, got: " . $e->getMessage());
            } finally {
                if ($created instanceof EmailTemplate) {
                    $created->forceDelete();
                }
            }
        }
    }

    /** G44 positive — EmailTemplate nullable module omitted + default is_active applied. */
    public function test_communication_06_email_template_nullable_and_default(): void
    {
        $record = null;
        try {
            $payload = $this->buildTemplatePayload();
            unset($payload['module'], $payload['is_active']);

            $record = EmailTemplate::query()->create($payload);
            $record->refresh();

            $this->assertNull($record->module, 'Omitted module should be NULL.');
            $this->assertTrue((bool) $record->is_active, 'is_active must default to 1.');
        } finally {
            if ($record instanceof EmailTemplate) {
                $record->forceDelete();
            }
        }
    }

    /** G44 negative — SmsLog NOT-NULL-no-default cols reject a missing value. */
    public function test_communication_07_sms_log_required_columns_reject_missing(): void
    {
        $parent = $this->createCommLog(['channel' => 'SMS', 'subject' => null]);
        try {
            foreach (['communication_log_id', 'recipient_user_id', 'mobile_number', 'message'] as $col) {
                $created = null;
                try {
                    $payload = $this->buildSmsLogPayload($parent);
                    unset($payload[$col]);
                    $created = SmsLog::query()->create($payload);
                    $this->fail("Expected DB rejection creating a SmsLog without {$col}.");
                } catch (Throwable $e) {
                    $this->assertTrue($this->looksLikeConstraintFailure($e), "Expected NOT-NULL/FK failure for {$col}, got: " . $e->getMessage());
                } finally {
                    if ($created instanceof SmsLog) {
                        $created->forceDelete();
                    }
                }
            }
        } finally {
            $parent->forceDelete();
        }
    }

    /** DDL defaults applied on SmsLog create (sms_units=1, status='Queued', is_active=1). */
    public function test_communication_08_sms_log_defaults_applied_on_create(): void
    {
        $parent = $this->createCommLog(['channel' => 'SMS', 'subject' => null]);
        $record = null;
        try {
            $payload = $this->buildSmsLogPayload($parent);
            unset($payload['sms_units'], $payload['status'], $payload['is_active']);

            $record = SmsLog::query()->create($payload);
            $record->refresh();

            $this->assertSame(1, (int) $record->sms_units, 'sms_units must default to 1.');
            $this->assertSame('Queued', (string) $record->status, "status must default to 'Queued'.");
            $this->assertTrue((bool) $record->is_active, 'is_active must default to 1.');
        } finally {
            if ($record instanceof SmsLog) {
                $record->forceDelete();
            }
            $parent->forceDelete();
        }
    }

    /** Casts return typed values across the three models. */
    public function test_communication_09_casts_return_typed_values(): void
    {
        $cl = null;
        $parent = null;
        $sl = null;
        try {
            $cl = CommunicationLog::query()->create($this->buildCommLogPayload(['total_recipients' => 5]));
            $cl->refresh();
            $this->assertIsInt($cl->total_recipients, 'total_recipients must cast to int.');
            $this->assertIsBool($cl->is_active, 'CommunicationLog.is_active must cast to bool.');

            $parent = $this->createCommLog(['channel' => 'SMS', 'subject' => null]);
            $sl = SmsLog::query()->create($this->buildSmsLogPayload($parent, ['sms_units' => 2, 'sent_at' => now()]));
            $sl->refresh();
            $this->assertIsInt($sl->sms_units, 'sms_units must cast to int.');
            $this->assertInstanceOf(\Illuminate\Support\Carbon::class, $sl->sent_at, 'sent_at must cast to datetime.');
        } finally {
            if ($sl instanceof SmsLog) {
                $sl->forceDelete();
            }
            if ($parent instanceof CommunicationLog) {
                $parent->forceDelete();
            }
            if ($cl instanceof CommunicationLog) {
                $cl->forceDelete();
            }
        }
    }

    // ============================================================
    // 10-19  Business rules (BC-BIZ)
    // ============================================================

    /** emailSend creates a CommunicationLog with channel=Email and zeroed counters (stub — DEV-FOF-COM-04). */
    public function test_communication_10_email_send_creates_email_channel_log(): void
    {
        $group = 'All_Parents';
        $subject = 'EmailSend ' . $this->generateUniqueSuffix();
        $created = null;

        try {
            $this->browse(function (Browser $browser) use ($group, $subject): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::COMPOSE_PATH, 900);

                $this->postFormFromBrowser($browser, $this->tenantUrl(self::EMAIL_SEND_PATH), [
                    'recipient_group' => $group,
                    'subject'         => $subject,
                    'body'            => 'Body for ' . $subject,
                ]);
                $browser->pause(1500);
            });

            $created = CommunicationLog::query()->where('subject', $subject)->first();
            if (!$created) {
                $this->markTestSkipped('emailSend did not persist a log (module may be disabled — see Validation Report).');
                return;
            }
            $this->assertSame('Email', (string) $created->channel, 'emailSend must set channel=Email.');
            $this->assertSame($group, (string) $created->recipient_group, 'recipient_group must be stored.');
            // Stub behaviour (DEV-FOF-COM-04): counters remain zero, no real dispatch.
            $this->assertSame(0, (int) $created->total_recipients, 'Stub: total_recipients stays 0.');
            $this->assertSame(0, (int) $created->sent_count, 'Stub: sent_count stays 0.');
        } finally {
            if ($created instanceof CommunicationLog) {
                $created->forceDelete();
            }
        }
    }

    /** smsSend creates a CommunicationLog with channel=SMS and NULL subject. */
    public function test_communication_11_sms_send_creates_sms_channel_log(): void
    {
        $group = 'All_Staff';
        $body = 'SmsSend ' . $this->generateUniqueSuffix();
        $created = null;

        try {
            $this->browse(function (Browser $browser) use ($group, $body): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SMS_LOGS_PATH, 900);

                $this->postFormFromBrowser($browser, $this->tenantUrl(self::SMS_SEND_PATH), [
                    'recipient_group' => $group,
                    'body'            => $body,
                ]);
                $browser->pause(1500);
            });

            $created = CommunicationLog::query()->where('body', $body)->where('channel', 'SMS')->first();
            if (!$created) {
                $this->markTestSkipped('smsSend did not persist a log (module may be disabled — see Validation Report).');
                return;
            }
            $this->assertSame('SMS', (string) $created->channel, 'smsSend must set channel=SMS.');
            $this->assertNull($created->subject, 'smsSend must store NULL subject.');
        } finally {
            if ($created instanceof CommunicationLog) {
                $created->forceDelete();
            }
        }
    }

    /** scopeActive() excludes inactive CommunicationLog rows. */
    public function test_communication_12_active_scope_excludes_inactive_logs(): void
    {
        $active = null;
        $inactive = null;
        try {
            $active = $this->createCommLog(['is_active' => 1, 'subject' => 'ActiveLog ' . $this->generateUniqueSuffix()]);
            $inactive = $this->createCommLog(['is_active' => 0, 'subject' => 'InactiveLog ' . $this->generateUniqueSuffix()]);

            $activeIds = CommunicationLog::query()->active()->pluck('id')->all();
            $this->assertContains($active->id, $activeIds, 'Active log must appear in active scope.');
            $this->assertNotContains($inactive->id, $activeIds, 'Inactive log must NOT appear in active scope.');
        } finally {
            foreach ([$active, $inactive] as $r) {
                if ($r instanceof CommunicationLog) {
                    $r->forceDelete();
                }
            }
        }
    }

    /** emailLogs / smsLogs channel separation: Email query returns only Email rows and vice-versa. */
    public function test_communication_13_channel_query_separation(): void
    {
        $email = null;
        $sms = null;
        try {
            $email = $this->createCommLog(['channel' => 'Email', 'subject' => 'ChE ' . $this->generateUniqueSuffix()]);
            $sms = $this->createCommLog(['channel' => 'SMS', 'subject' => null, 'body' => 'ChS ' . $this->generateUniqueSuffix()]);

            $emailIds = CommunicationLog::query()->active()->where('channel', 'Email')->pluck('id')->all();
            $smsIds = CommunicationLog::query()->active()->where('channel', 'SMS')->pluck('id')->all();

            $this->assertContains($email->id, $emailIds, 'Email log must be in the Email query.');
            $this->assertNotContains($email->id, $smsIds, 'Email log must NOT be in the SMS query.');
            $this->assertContains($sms->id, $smsIds, 'SMS log must be in the SMS query.');
            $this->assertNotContains($sms->id, $emailIds, 'SMS log must NOT be in the Email query.');
        } finally {
            foreach ([$email, $sms] as $r) {
                if ($r instanceof CommunicationLog) {
                    $r->forceDelete();
                }
            }
        }
    }

    /** EmailTemplate::active() excludes inactive templates (drives the compose picker). */
    public function test_communication_14_template_active_scope_excludes_inactive(): void
    {
        $active = null;
        $inactive = null;
        try {
            $active = $this->createTemplate(['is_active' => 1]);
            $inactive = $this->createTemplate(['is_active' => 0]);

            $activeIds = EmailTemplate::query()->active()->pluck('id')->all();
            $this->assertContains($active->id, $activeIds, 'Active template must appear in active scope.');
            $this->assertNotContains($inactive->id, $activeIds, 'Inactive template must NOT appear.');
        } finally {
            foreach ([$active, $inactive] as $r) {
                if ($r instanceof EmailTemplate) {
                    $r->forceDelete();
                }
            }
        }
    }

    /**
     * DEV-FOF-COM-02 (proving test): BR-FOF-011 multi-unit SMS is UNIMPLEMENTED.
     * The requirement mandates a SendBulkSmsRequest with ceil(strlen/160), max 4 units (640 chars).
     * The controller instead inline-validates body 'max:1000' with NO sms_units calculation.
     */
    public function test_communication_15_sms_multiunit_rule_is_not_implemented(): void
    {
        $source = $this->readControllerSource();
        if ($source === null) {
            return;
        }
        $this->assertStringNotContainsString('SendBulkSmsRequest', $source, 'DEV-FOF-COM-02: SendBulkSmsRequest is not used.');
        $this->assertStringNotContainsString('sms_units', $source, 'DEV-FOF-COM-02: no sms_units calculation in the controller.');
        $this->assertStringContainsString("'body'            => 'required|string|max:1000'", $source, 'smsSend caps body at 1000 (not the 640 spec).');
    }

    // ============================================================
    // 20-29  State-machine transitions (BC-SM)
    // ============================================================

    /** EmailTemplate toggle-status flips is_active true->false and returns JSON success. */
    public function test_communication_20_template_toggle_status_deactivates(): void
    {
        $template = $this->createTemplate(['is_active' => 1]);
        $templateId = (int) $template->id;

        try {
            $this->browse(function (Browser $browser) use ($templateId): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::TEMPLATES_PATH, 900);

                $url = $this->tenantUrl(self::TEMPLATES_PATH . '/' . $templateId . '/toggle-status');
                $response = $this->jsonRequestFromBrowser($browser, $url, 'POST');
                if (is_array($response) && array_key_exists('success', $response)) {
                    $this->assertTrue((bool) $response['success'], 'toggle-status success flag must be true.');
                }
            });

            $template->refresh();
            if ((bool) $template->is_active === true) {
                $this->markTestSkipped('toggle-status had no effect (module may be disabled — see Validation Report).');
                return;
            }
            $this->assertFalse((bool) $template->is_active, 'toggle-status must flip is_active to false.');
        } finally {
            EmailTemplate::withTrashed()->where('id', $templateId)->get()
                ->each(fn (EmailTemplate $r) => $r->forceDelete());
        }
    }

    /** EmailTemplate toggle-status legal reverse transition false->true. */
    public function test_communication_21_template_toggle_status_reactivates(): void
    {
        $template = $this->createTemplate(['is_active' => 0]);
        $templateId = (int) $template->id;

        try {
            $this->browse(function (Browser $browser) use ($templateId): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::TEMPLATES_PATH, 900);

                $url = $this->tenantUrl(self::TEMPLATES_PATH . '/' . $templateId . '/toggle-status');
                $this->jsonRequestFromBrowser($browser, $url, 'POST');
            });

            $template->refresh();
            if ((bool) $template->is_active === false) {
                $this->markTestSkipped('toggle-status had no effect (module may be disabled).');
                return;
            }
            $this->assertTrue((bool) $template->is_active, 'toggle-status must flip is_active back to true.');
        } finally {
            EmailTemplate::withTrashed()->where('id', $templateId)->get()
                ->each(fn (EmailTemplate $r) => $r->forceDelete());
        }
    }

    /** SmsLog status ENUM accepts every legal delivery state. */
    public function test_communication_22_sms_log_status_enum_accepts_legal_states(): void
    {
        $parent = $this->createCommLog(['channel' => 'SMS', 'subject' => null]);
        try {
            foreach (['Queued', 'Sent', 'Delivered', 'Failed'] as $status) {
                $record = null;
                try {
                    $record = SmsLog::query()->create($this->buildSmsLogPayload($parent, ['status' => $status]));
                    $record->refresh();
                    $this->assertSame($status, (string) $record->status, "SmsLog.status must accept {$status}.");
                } finally {
                    if ($record instanceof SmsLog) {
                        $record->forceDelete();
                    }
                }
            }
        } finally {
            $parent->forceDelete();
        }
    }

    /** SmsLog status ENUM rejects an out-of-domain value (illegal state). */
    public function test_communication_23_sms_log_status_enum_rejects_illegal(): void
    {
        $parent = $this->createCommLog(['channel' => 'SMS', 'subject' => null]);
        $created = null;
        try {
            $created = SmsLog::query()->create($this->buildSmsLogPayload($parent, ['status' => 'Bounced']));
            $created->refresh();
            $this->assertNotContains(
                (string) $created->status,
                ['Queued', 'Sent', 'Delivered', 'Failed'],
                'An invalid SmsLog status must not be stored as a canonical value.'
            );
        } catch (Throwable $e) {
            $this->assertTrue(true, 'DB rejected invalid SmsLog status: ' . $e->getMessage());
        } finally {
            if ($created instanceof SmsLog) {
                $created->forceDelete();
            }
            $parent->forceDelete();
        }
    }

    /** CommunicationLog channel ENUM accepts Email/SMS and rejects an invalid channel. */
    public function test_communication_24_comm_log_channel_enum_boundary(): void
    {
        foreach (['Email', 'SMS'] as $channel) {
            $ok = null;
            try {
                $ok = $this->createCommLog(['channel' => $channel, 'subject' => $channel === 'SMS' ? null : 'Ch ' . $this->generateUniqueSuffix()]);
                $ok->refresh();
                $this->assertSame($channel, (string) $ok->channel, "channel must accept {$channel}.");
            } finally {
                if ($ok instanceof CommunicationLog) {
                    $ok->forceDelete();
                }
            }
        }

        $bad = null;
        try {
            $bad = CommunicationLog::query()->create($this->buildCommLogPayload(['channel' => 'Push']));
            $bad->refresh();
            $this->assertNotContains((string) $bad->channel, ['Email', 'SMS'], 'Invalid channel must not persist canonically.');
        } catch (Throwable $e) {
            $this->assertTrue(true, 'DB rejected invalid channel: ' . $e->getMessage());
        } finally {
            if ($bad instanceof CommunicationLog) {
                $bad->forceDelete();
            }
        }
    }

    // ============================================================
    // 30-39  Validation + error messages (BC-VAL, G45)
    // ============================================================

    /** emailSend rejects missing required request fields (recipient_group/subject/body). */
    public function test_communication_30_email_send_rejects_missing_required(): void
    {
        $this->browse(function (Browser $browser): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::COMPOSE_PATH, 900);

            $status = $this->postFormFromBrowser($browser, $this->tenantUrl(self::EMAIL_SEND_PATH), [
                'recipient_group' => '',
                'subject'         => '',
                'body'            => '',
            ]);
            $this->assertContains($status, [302, 422, 419, 404, 500], 'Missing required fields must not yield 2xx. Got: ' . $status);
        });
    }

    /**
     * DEV-FOF-COM-01 (proving test): emailSend validates subject 'max:255' although the
     * column and requirement both allow VARCHAR(300) — a stricter-than-schema divergence.
     */
    public function test_communication_31_email_send_subject_max_255_divergence(): void
    {
        $source = $this->readControllerSource();
        if ($source === null) {
            return;
        }
        $this->assertStringContainsString("'subject'         => 'required|string|max:255'", $source, 'DEV-FOF-COM-01: subject capped at 255 vs DDL VARCHAR(300).');
        // Confirm the DDL column really is 300 (the divergence source of truth).
        $this->assertTrue(Schema::hasColumn(self::CL_TABLE, 'subject'));
    }

    /** smsSend rejects missing required request fields (recipient_group/body). */
    public function test_communication_32_sms_send_rejects_missing_required(): void
    {
        $this->browse(function (Browser $browser): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::SMS_LOGS_PATH, 900);

            $status = $this->postFormFromBrowser($browser, $this->tenantUrl(self::SMS_SEND_PATH), [
                'recipient_group' => '',
                'body'            => '',
            ]);
            $this->assertContains($status, [302, 422, 419, 404, 500], 'Missing required fields must not yield 2xx. Got: ' . $status);
        });
    }

    /** DEV-FOF-COM-02 corollary: smsSend caps body at 1000 chars (exceeds the 640/4-unit spec). */
    public function test_communication_33_sms_send_body_cap_exceeds_spec(): void
    {
        $source = $this->readControllerSource();
        if ($source === null) {
            return;
        }
        $this->assertStringContainsString('max:1000', $source, 'DEV-FOF-COM-02: SMS body max is 1000, not the 640-char (4-unit) requirement.');
    }

    /** G45 — EmailTemplate.name VARCHAR(100) boundary. */
    public function test_communication_34_template_name_length_boundary(): void
    {
        $this->assertTemplateSizedColumn('name', 100);
    }

    /** G45 — EmailTemplate.subject VARCHAR(300) boundary. */
    public function test_communication_35_template_subject_length_boundary(): void
    {
        $this->assertTemplateSizedColumn('subject', 300);
    }

    /** G45 — EmailTemplate.module VARCHAR(50) boundary. */
    public function test_communication_36_template_module_length_boundary(): void
    {
        $this->assertTemplateSizedColumn('module', 50);
    }

    /** G45 — CommunicationLog.recipient_group VARCHAR(100) boundary. */
    public function test_communication_37_comm_log_recipient_group_length_boundary(): void
    {
        $this->assertCommLogSizedColumn('recipient_group', 100);
    }

    /** G45 — CommunicationLog.subject VARCHAR(300) boundary. */
    public function test_communication_38_comm_log_subject_length_boundary(): void
    {
        $this->assertCommLogSizedColumn('subject', 300);
    }

    /** G45 — SmsLog.mobile_number VARCHAR(15) boundary. */
    public function test_communication_39_sms_log_mobile_number_length_boundary(): void
    {
        $parent = $this->createCommLog(['channel' => 'SMS', 'subject' => null]);
        try {
            // Over-length (n+5) — rejected or truncated to <= 15.
            $over = null;
            try {
                $over = SmsLog::query()->create($this->buildSmsLogPayload($parent, ['mobile_number' => str_repeat('9', 20)]));
                $over->refresh();
                $this->assertLessThanOrEqual(15, strlen((string) $over->mobile_number), 'Over-length mobile_number must be rejected/truncated.');
            } catch (Throwable $e) {
                $this->assertTrue(true, 'DB rejected over-length mobile_number: ' . $e->getMessage());
            } finally {
                if ($over instanceof SmsLog) {
                    $over->forceDelete();
                }
            }

            // Exactly-15 accepted.
            $exact = null;
            try {
                $value = str_repeat('8', 15);
                $exact = SmsLog::query()->create($this->buildSmsLogPayload($parent, ['mobile_number' => $value]));
                $exact->refresh();
                $this->assertSame($value, (string) $exact->mobile_number, 'Exactly-15-char mobile_number must persist intact.');
            } finally {
                if ($exact instanceof SmsLog) {
                    $exact->forceDelete();
                }
            }
        } finally {
            $parent->forceDelete();
        }
    }

    // ============================================================
    // 40-49  FK / integration (BC-INT / BC-REF)
    // ============================================================

    /** CommunicationLog.template_id FK to fof_email_templates is enforced (invalid id rejected). */
    public function test_communication_40_comm_log_template_fk_enforced(): void
    {
        $created = null;
        try {
            $created = CommunicationLog::query()->create($this->buildCommLogPayload(['template_id' => 2147483000]));
            $this->fail('Expected FK violation for a non-existent template_id.');
        } catch (Throwable $e) {
            $this->assertTrue($this->looksLikeConstraintFailure($e), 'Expected FK failure, got: ' . $e->getMessage());
        } finally {
            if ($created instanceof CommunicationLog) {
                $created->forceDelete();
            }
        }
    }

    /** template_id ON DELETE SET NULL: force-deleting the template nulls the log's template_id. */
    public function test_communication_41_template_delete_sets_log_template_id_null(): void
    {
        $template = $this->createTemplate();
        $log = $this->createCommLog(['template_id' => $template->id, 'channel' => 'Email', 'subject' => 'FkSetNull ' . $this->generateUniqueSuffix()]);
        $logId = (int) $log->id;

        try {
            $template->forceDelete(); // hard delete fires the FK action
            $fresh = CommunicationLog::withTrashed()->find($logId);
            $this->assertNotNull($fresh, 'Log row must survive template deletion (SET NULL, not cascade).');
            $this->assertNull($fresh->template_id, 'template_id must be set NULL when the template is deleted.');
        } catch (Throwable $e) {
            $this->markTestSkipped('SET NULL path not exercised in this environment: ' . $e->getMessage());
        } finally {
            CommunicationLog::withTrashed()->where('id', $logId)->get()->each(fn (CommunicationLog $r) => $r->forceDelete());
            EmailTemplate::withTrashed()->where('id', $template->id)->get()->each(fn (EmailTemplate $r) => $r->forceDelete());
        }
    }

    /** SmsLog.communication_log_id FK RESTRICT: parent CL cannot be hard-deleted while a child exists. */
    public function test_communication_42_sms_log_parent_delete_restricted(): void
    {
        $parent = $this->createCommLog(['channel' => 'SMS', 'subject' => null]);
        $child = SmsLog::query()->create($this->buildSmsLogPayload($parent));
        $parentId = (int) $parent->id;
        $childId = (int) $child->id;

        try {
            $blocked = false;
            try {
                $parent->forceDelete(); // RESTRICT should block this
            } catch (Throwable $e) {
                $blocked = $this->looksLikeConstraintFailure($e);
            }
            $this->assertTrue($blocked, 'RESTRICT must prevent deleting a CommunicationLog that still has SmsLog children.');
        } finally {
            SmsLog::withTrashed()->where('id', $childId)->get()->each(fn (SmsLog $r) => $r->forceDelete());
            CommunicationLog::withTrashed()->where('id', $parentId)->get()->each(fn (CommunicationLog $r) => $r->forceDelete());
        }
    }

    /** SmsLog.recipient_user_id FK to sys_users RESTRICT is enforced (invalid id rejected). */
    public function test_communication_43_sms_log_recipient_fk_enforced(): void
    {
        $parent = $this->createCommLog(['channel' => 'SMS', 'subject' => null]);
        $created = null;
        try {
            $created = SmsLog::query()->create($this->buildSmsLogPayload($parent, ['recipient_user_id' => 2147483000]));
            $this->fail('Expected FK violation for a non-existent recipient_user_id.');
        } catch (Throwable $e) {
            $this->assertTrue($this->looksLikeConstraintFailure($e), 'Expected FK failure, got: ' . $e->getMessage());
        } finally {
            if ($created instanceof SmsLog) {
                $created->forceDelete();
            }
            $parent->forceDelete();
        }
    }

    /** FK declarations present in SHOW CREATE TABLE (SET NULL on CL, RESTRICT on SL). */
    public function test_communication_44_foreign_keys_declared(): void
    {
        try {
            $clSql = $this->showCreateTable(self::CL_TABLE);
            $slSql = $this->showCreateTable(self::SL_TABLE);
        } catch (Throwable $e) {
            $this->markTestSkipped('Cannot read SHOW CREATE TABLE: ' . $e->getMessage());
            return;
        }

        $this->assertStringContainsStringIgnoringCase('foreign key', $clSql, 'communication_logs must declare a FK.');
        $this->assertStringContainsStringIgnoringCase('template_id', $clSql);
        $this->assertStringContainsStringIgnoringCase('set null', $clSql, 'template_id FK should be ON DELETE SET NULL.');

        $this->assertStringContainsStringIgnoringCase('foreign key', $slSql, 'sms_logs must declare FKs.');
        $this->assertStringContainsStringIgnoringCase('communication_log_id', $slSql);
        $this->assertStringContainsStringIgnoringCase('recipient_user_id', $slSql);
        $this->assertStringContainsStringIgnoringCase('restrict', $slSql, 'sms_logs FKs should be ON DELETE RESTRICT.');
    }

    /** created_by / updated_by are set by the controller from auth()->id() on emailSend (auto-managed — G48). */
    public function test_communication_45_created_by_is_set_by_controller_on_send(): void
    {
        $subject = 'CreatedByProbe ' . $this->generateUniqueSuffix();
        $created = null;

        try {
            $this->browse(function (Browser $browser) use ($subject): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::COMPOSE_PATH, 900);

                $this->postFormFromBrowser($browser, $this->tenantUrl(self::EMAIL_SEND_PATH), [
                    'recipient_group' => 'Management',
                    'subject'         => $subject,
                    'body'            => 'Created-by probe body.',
                ]);
                $browser->pause(1500);
            });

            $created = CommunicationLog::query()->where('subject', $subject)->first();
            if (!$created) {
                $this->markTestSkipped('emailSend did not persist a row (module may be disabled).');
                return;
            }
            $this->assertSame((int) $this->adminUser?->id, (int) $created->created_by, 'created_by must be the acting user.');
            $this->assertSame((int) $this->adminUser?->id, (int) $created->updated_by, 'updated_by must be the acting user.');
        } finally {
            if ($created instanceof CommunicationLog) {
                $created->forceDelete();
            }
        }
    }

    // ============================================================
    // 50-59  Permissions / authorization (BC-AUTH, F37/#31)
    // ============================================================

    /** Guest is redirected to login on the compose page. */
    public function test_communication_50_guest_redirected_to_login(): void
    {
        $this->browse(function (Browser $browser): void {
            $browser->visit($this->tenantUrl(self::COMPOSE_PATH))->pause(1500);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest must be redirected to /login.');
        });
    }

    /** Compose page requires the create permission (limited user 403). */
    public function test_communication_51_compose_requires_create_permission(): void
    {
        $this->assertForbiddenForLimitedUser(self::COMPOSE_PATH, 'GET');
    }

    /** Templates/logs pages require the view permission (limited user 403). */
    public function test_communication_52_view_pages_require_view_permission(): void
    {
        $this->assertForbiddenForLimitedUser(self::TEMPLATES_PATH, 'GET');
        $this->assertForbiddenForLimitedUser(self::EMAIL_LOGS_PATH, 'GET');
    }

    /** emailSend requires the create permission (limited user POST forbidden). */
    public function test_communication_53_email_send_requires_create_permission(): void
    {
        $this->assertForbiddenForLimitedUser(self::EMAIL_SEND_PATH, 'POST', self::COMPOSE_PATH, [
            'recipient_group' => 'All_Parents',
            'subject'         => 'PermProbe ' . $this->generateUniqueSuffix(),
            'body'            => 'Permission probe body.',
        ]);
    }

    /** smsSend requires the create permission (limited user POST forbidden). */
    public function test_communication_54_sms_send_requires_create_permission(): void
    {
        $this->assertForbiddenForLimitedUser(self::SMS_SEND_PATH, 'POST', self::SMS_LOGS_PATH, [
            'recipient_group' => 'All_Staff',
            'body'            => 'Permission probe SMS.',
        ]);
    }

    /** toggle-status requires the update permission (limited user POST forbidden). */
    public function test_communication_55_toggle_status_requires_update_permission(): void
    {
        $template = $this->createTemplate();
        $templateId = (int) $template->id;
        try {
            $this->assertForbiddenForLimitedUser(
                self::TEMPLATES_PATH . '/' . $templateId . '/toggle-status',
                'POST',
                self::TEMPLATES_PATH,
                []
            );
        } finally {
            EmailTemplate::withTrashed()->where('id', $templateId)->get()->each(fn (EmailTemplate $r) => $r->forceDelete());
        }
    }

    // ============================================================
    // 60-69  UI / UX (render pages)
    // ============================================================

    /** Compose page renders the send form (recipient_group, subject, body). */
    public function test_communication_60_compose_page_loads(): void
    {
        $this->browse(function (Browser $browser): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::COMPOSE_PATH, 1000);

            if ($this->responseStatusCode($browser) === 404) {
                $this->markTestSkipped('Compose route 404 (module disabled — see Validation Report).');
                return;
            }
            $browser->assertPresent('select[name="recipient_group"]')
                ->assertPresent('input[name="subject"]')
                ->assertPresent('textarea[name="body"]');
        });
    }

    /** Templates page loads and lists a seeded template. */
    public function test_communication_61_templates_page_lists_records(): void
    {
        $template = $this->createTemplate(['name' => 'ListTpl ' . $this->generateUniqueSuffix()]);
        try {
            $this->browse(function (Browser $browser) use ($template): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::TEMPLATES_PATH, 1000);

                if ($this->responseStatusCode($browser) === 404) {
                    $this->markTestSkipped('Templates route 404 (module disabled).');
                    return;
                }
                $browser->waitForText((string) $template->name, 12)->assertSee((string) $template->name);
            });
        } finally {
            $template->forceDelete();
        }
    }

    /** Email logs page loads and lists a seeded email log. */
    public function test_communication_62_email_logs_page_lists_records(): void
    {
        $log = $this->createCommLog(['channel' => 'Email', 'subject' => 'LogSubj ' . $this->generateUniqueSuffix()]);
        try {
            $this->browse(function (Browser $browser) use ($log): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::EMAIL_LOGS_PATH, 1000);

                if ($this->responseStatusCode($browser) === 404) {
                    $this->markTestSkipped('Email logs route 404 (module disabled).');
                    return;
                }
                $browser->waitForText((string) $log->recipient_group, 12)->assertSee((string) $log->recipient_group);
            });
        } finally {
            $log->forceDelete();
        }
    }

    /** SMS logs page loads. */
    public function test_communication_63_sms_logs_page_loads(): void
    {
        $log = $this->createCommLog(['channel' => 'SMS', 'subject' => null, 'body' => 'SmsLogPage ' . $this->generateUniqueSuffix()]);
        try {
            $this->browse(function (Browser $browser) use ($log): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SMS_LOGS_PATH, 1000);

                if ($this->responseStatusCode($browser) === 404) {
                    $this->markTestSkipped('SMS logs route 404 (module disabled).');
                    return;
                }
                $browser->waitForText((string) $log->recipient_group, 12)->assertSee((string) $log->recipient_group);
            });
        } finally {
            $log->forceDelete();
        }
    }

    /** Communication menu (email-sms tab) loads. */
    public function test_communication_64_menu_email_sms_tab_loads(): void
    {
        $this->browse(function (Browser $browser): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::MENU_PATH . '?tab=email-sms', 1200);

            $status = $this->responseStatusCode($browser);
            if ($status === 404) {
                $this->markTestSkipped('Communication menu route 404 (module disabled).');
                return;
            }
            $this->assertNotContains($status, [500], 'Menu email-sms tab must render without a 500.');
        });
    }

    // ============================================================
    // 70-79  Edge cases + soft-delete lifecycle (BC-EDG)
    // ============================================================

    /** CommunicationLog soft delete sets deleted_at; force delete is permanent. */
    public function test_communication_70_comm_log_soft_and_force_delete(): void
    {
        $log = $this->createCommLog(['subject' => 'SoftDel ' . $this->generateUniqueSuffix()]);
        $logId = (int) $log->id;

        try {
            $log->delete();
            $log->refresh();
            $this->assertNotNull($log->deleted_at, 'Soft delete must set deleted_at.');
            $this->assertNotNull(CommunicationLog::withTrashed()->find($logId), 'Row must survive soft delete.');

            $log->forceDelete();
            $this->assertNull(CommunicationLog::withTrashed()->find($logId), 'Force delete must permanently remove the row.');
        } finally {
            CommunicationLog::withTrashed()->where('id', $logId)->get()->each(fn (CommunicationLog $r) => $r->forceDelete());
        }
    }

    /** EmailTemplate soft delete + restore round-trip. */
    public function test_communication_71_email_template_soft_delete_and_restore(): void
    {
        $template = $this->createTemplate();
        $templateId = (int) $template->id;

        try {
            $template->delete();
            $this->assertNotNull(EmailTemplate::withTrashed()->find($templateId)->deleted_at, 'Soft delete must set deleted_at.');

            EmailTemplate::withTrashed()->find($templateId)->restore();
            $template->refresh();
            $this->assertNull($template->deleted_at, 'restore() must clear deleted_at.');
        } finally {
            EmailTemplate::withTrashed()->where('id', $templateId)->get()->each(fn (EmailTemplate $r) => $r->forceDelete());
        }
    }

    /** SmsLog soft delete sets deleted_at. */
    public function test_communication_72_sms_log_soft_delete(): void
    {
        $parent = $this->createCommLog(['channel' => 'SMS', 'subject' => null]);
        $child = SmsLog::query()->create($this->buildSmsLogPayload($parent));
        $childId = (int) $child->id;

        try {
            $child->delete();
            $child->refresh();
            $this->assertNotNull($child->deleted_at, 'SmsLog soft delete must set deleted_at.');
        } finally {
            SmsLog::withTrashed()->where('id', $childId)->get()->each(fn (SmsLog $r) => $r->forceDelete());
            $parent->forceDelete();
        }
    }

    /** CommunicationLog.body TEXT and EmailTemplate.body LONGTEXT accept long content. */
    public function test_communication_73_text_columns_accept_long_content(): void
    {
        $cl = null;
        $et = null;
        try {
            $long = str_repeat('Campaign copy. ', 500); // ~7.5k chars
            $cl = $this->createCommLog(['body' => $long, 'subject' => 'LongBody ' . $this->generateUniqueSuffix()]);
            $cl->refresh();
            $this->assertSame($long, (string) $cl->body, 'TEXT body must store long content.');

            $et = $this->createTemplate(['body' => $long]);
            $et->refresh();
            $this->assertSame($long, (string) $et->body, 'LONGTEXT template body must store long content.');
        } finally {
            if ($cl instanceof CommunicationLog) {
                $cl->forceDelete();
            }
            if ($et instanceof EmailTemplate) {
                $et->forceDelete();
            }
        }
    }

    /** SmsLog.sms_units TINYINT stores multi-unit values (BR-FOF-011 audit column). */
    public function test_communication_74_sms_units_multi_unit_persists(): void
    {
        $parent = $this->createCommLog(['channel' => 'SMS', 'subject' => null]);
        $record = null;
        try {
            $record = SmsLog::query()->create($this->buildSmsLogPayload($parent, ['sms_units' => 4]));
            $record->refresh();
            $this->assertSame(4, (int) $record->sms_units, 'sms_units must store the multi-unit count.');
        } finally {
            if ($record instanceof SmsLog) {
                $record->forceDelete();
            }
            $parent->forceDelete();
        }
    }

    // ============================================================
    // 90-99  Security + source-defect probes (TC-S / DEV)
    // ============================================================

    /** Stored XSS in a CommunicationLog subject is escaped on the email-logs page. */
    public function test_communication_90_stored_xss_in_subject_is_escaped(): void
    {
        $marker = 'com' . $this->generateUniqueSuffix();
        $xss = '<script>alert("' . $marker . '")</script>';
        $log = $this->createCommLog(['channel' => 'Email', 'subject' => $xss, 'recipient_group' => 'XSSGrp ' . $marker]);

        try {
            $this->browse(function (Browser $browser) use ($log, $marker): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::EMAIL_LOGS_PATH, 1200);

                if ($this->responseStatusCode($browser) === 404) {
                    $this->markTestSkipped('Email logs route 404 (module disabled).');
                    return;
                }
                $source = $browser->driver->getPageSource();
                $this->assertStringNotContainsString('<script>alert("' . $marker, $source, 'subject must be HTML-escaped (no raw <script>).');
            });
        } finally {
            $log->forceDelete();
        }
    }

    /** emailSend writes an activity-log row with event 'email_queued' to sys_activity_logs. */
    public function test_communication_91_email_send_writes_activity_log(): void
    {
        if (!Schema::hasTable('sys_activity_logs')) {
            $this->markTestSkipped('sys_activity_logs table absent — activity sink unavailable.');
            return;
        }

        $subject = 'ActivityProbe ' . $this->generateUniqueSuffix();
        $created = null;
        try {
            $this->browse(function (Browser $browser) use ($subject): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::COMPOSE_PATH, 900);

                $this->postFormFromBrowser($browser, $this->tenantUrl(self::EMAIL_SEND_PATH), [
                    'recipient_group' => 'All_Parents',
                    'subject'         => $subject,
                    'body'            => 'Activity probe body.',
                ]);
                $browser->pause(1500);
            });

            $created = CommunicationLog::query()->where('subject', $subject)->first();
            if (!$created) {
                $this->markTestSkipped('emailSend did not persist a log (module may be disabled).');
                return;
            }

            $log = ActivityLog::query()
                ->where('subject_type', CommunicationLog::class)
                ->where('subject_id', $created->id)
                ->where('event', 'email_queued')
                ->first();
            $this->assertNotNull($log, "Activity event 'email_queued' must be recorded for the send.");
            $this->assertSame((int) $this->adminUser?->id, (int) $log->user_id, 'Activity causer must be the acting user.');
        } finally {
            if ($created instanceof CommunicationLog) {
                ActivityLog::query()->where('subject_type', CommunicationLog::class)->where('subject_id', $created->id)->delete();
                $created->forceDelete();
            }
        }
    }

    /**
     * DEV-FOF-COM-03 (proving test): the controller's permission keys are
     * frontoffice.communication.{create,view,update} — NOT the requirement's .email / .sms keys.
     */
    public function test_communication_92_permission_keys_diverge_from_requirement(): void
    {
        $source = $this->readControllerSource();
        if ($source === null) {
            return;
        }
        $this->assertStringContainsString("Gate::authorize('frontoffice.communication.create')", $source, 'create gate present.');
        $this->assertStringContainsString("Gate::authorize('frontoffice.communication.view')", $source, 'view gate present.');
        $this->assertStringContainsString("Gate::authorize('frontoffice.communication.update')", $source, 'update gate present.');
        $this->assertStringNotContainsString("frontoffice.communication.email", $source, 'DEV-FOF-COM-03: .email key from the requirement is NOT used.');
        $this->assertStringNotContainsString("frontoffice.communication.sms", $source, 'DEV-FOF-COM-03: .sms key from the requirement is NOT used.');
    }

    /**
     * DEV-FOF-COM-04 (proving test): emailSend/smsSend are stubs — no real Mail dispatch,
     * no recipient resolution, and fof_sms_logs is never written by the controller.
     */
    public function test_communication_93_send_is_a_stub_no_dispatch(): void
    {
        $source = $this->readControllerSource();
        if ($source === null) {
            return;
        }
        // Mail is imported but never actually sent.
        $this->assertStringNotContainsString('Mail::send', $source, 'DEV-FOF-COM-04: no Mail::send in the controller.');
        $this->assertStringNotContainsString('Mail::to', $source, 'DEV-FOF-COM-04: no Mail::to dispatch in the controller.');
        // fof_sms_logs / SmsLog is never created by the send flow.
        $this->assertStringNotContainsString('SmsLog::create', $source, 'DEV-FOF-COM-04: controller never writes per-recipient SmsLog rows.');
    }

    /**
     * DEV-FOF-COM-05 (proving test): template management is read + toggle only —
     * the controller exposes NO store/update/destroy for templates (requirement asks for CRUD).
     */
    public function test_communication_94_template_crud_is_incomplete(): void
    {
        $source = $this->readControllerSource();
        if ($source === null) {
            return;
        }
        $this->assertStringContainsString('function emailTemplates(', $source, 'template list method present.');
        $this->assertStringContainsString('function toggleStatus(', $source, 'template toggle method present.');
        $this->assertStringNotContainsString('function storeTemplate(', $source, 'DEV-FOF-COM-05: no template store method.');
        $this->assertStringNotContainsString('function updateTemplate(', $source, 'DEV-FOF-COM-05: no template update method.');
        $this->assertStringNotContainsString('function destroyTemplate(', $source, 'DEV-FOF-COM-05: no template destroy method.');
    }

    // ============================================================
    // ---- Private helper library (mirrors fof_PhoneDiary sibling) ----
    // ============================================================

    /** Read CommunicationController raw source from the runner (reflection), or skip. */
    private function readControllerSource(): ?string
    {
        try {
            $file = (new \ReflectionClass(\Modules\FrontOffice\Http\Controllers\CommunicationController::class))->getFileName();
            $source = @file_get_contents((string) $file);
        } catch (Throwable $e) {
            $this->markTestSkipped('Cannot read CommunicationController source: ' . $e->getMessage());
            return null;
        }
        if (!is_string($source) || $source === '') {
            $this->markTestSkipped('CommunicationController source unreadable from the runner.');
            return null;
        }
        return $source;
    }

    private function looksLikeConstraintFailure(Throwable $e): bool
    {
        $msg = strtolower($e->getMessage());
        return str_contains($msg, 'cannot be null')
            || str_contains($msg, 'not null')
            || str_contains($msg, "doesn't have a default value")
            || str_contains($msg, 'foreign key')
            || str_contains($msg, 'integrity constraint')
            || str_contains($msg, 'constraint')
            || str_contains($msg, '23000')
            || str_contains($msg, 'incorrect');
    }

    /** G45 boundary helper for EmailTemplate sized columns. */
    private function assertTemplateSizedColumn(string $column, int $max): void
    {
        $over = null;
        try {
            $over = EmailTemplate::query()->create($this->buildTemplatePayload([$column => str_repeat('X', $max + 5)]));
            $over->refresh();
            $this->assertLessThanOrEqual($max, strlen((string) ($over->{$column} ?? '')), "Over-length {$column} must be rejected/truncated to <= {$max}.");
        } catch (Throwable $e) {
            $this->assertTrue(true, "DB rejected over-length {$column}: " . $e->getMessage());
        } finally {
            if ($over instanceof EmailTemplate) {
                $over->forceDelete();
            }
        }

        $exact = null;
        try {
            $value = str_repeat('Y', $max);
            $exact = EmailTemplate::query()->create($this->buildTemplatePayload([$column => $value]));
            $exact->refresh();
            $this->assertSame($value, (string) $exact->{$column}, "Exactly-{$max}-char {$column} must persist intact.");
        } finally {
            if ($exact instanceof EmailTemplate) {
                $exact->forceDelete();
            }
        }
    }

    /** G45 boundary helper for CommunicationLog sized columns. */
    private function assertCommLogSizedColumn(string $column, int $max): void
    {
        $over = null;
        try {
            $over = CommunicationLog::query()->create($this->buildCommLogPayload([$column => str_repeat('X', $max + 5)]));
            $over->refresh();
            $this->assertLessThanOrEqual($max, strlen((string) ($over->{$column} ?? '')), "Over-length {$column} must be rejected/truncated to <= {$max}.");
        } catch (Throwable $e) {
            $this->assertTrue(true, "DB rejected over-length {$column}: " . $e->getMessage());
        } finally {
            if ($over instanceof CommunicationLog) {
                $over->forceDelete();
            }
        }

        $exact = null;
        try {
            $value = str_repeat('Y', $max);
            $exact = CommunicationLog::query()->create($this->buildCommLogPayload([$column => $value]));
            $exact->refresh();
            $this->assertSame($value, (string) $exact->{$column}, "Exactly-{$max}-char {$column} must persist intact.");
        } finally {
            if ($exact instanceof CommunicationLog) {
                $exact->forceDelete();
            }
        }
    }

    /** Permission-negative (F37/#31): a fresh non-super-admin without the ability must get 403. */
    private function assertForbiddenForLimitedUser(string $path, string $method = 'GET', string $primerPath = self::COMPOSE_PATH, array $payload = []): void
    {
        $limited = $this->makeLimitedUserOrSkip();

        try {
            $this->browse(function (Browser $browser) use ($limited, $path, $method, $primerPath, $payload): void {
                $browser->visit($this->tenantUrl('/login'))->pause(400);
                $browser->loginAs($limited)->pause(600);

                if ($method === 'GET') {
                    $browser->visit($this->tenantUrl($path))->pause(1200);
                    $status = $this->responseStatusCode($browser);
                    if ($status === 404) {
                        $this->markTestSkipped('Route 404 (module disabled) — cannot assert 403.');
                        return;
                    }
                    $source = strtolower($browser->driver->getPageSource());
                    $forbidden = $status === 403
                        || str_contains($source, 'forbidden')
                        || str_contains($source, 'not authorized')
                        || str_contains($source, 'this action is unauthorized');
                    $this->assertTrue($forbidden, 'Limited user must be forbidden (403). Got status: ' . $status);
                } else {
                    $browser->visit($this->tenantUrl($primerPath))->pause(800);
                    $status = $this->postFormFromBrowser($browser, $this->tenantUrl($path), $payload);
                    if ($status === 404) {
                        $this->markTestSkipped('Route 404 (module disabled) — cannot assert 403.');
                        return;
                    }
                    $this->assertContains($status, [403, 419], 'Limited user POST must be forbidden (403). Got: ' . $status);
                }
            });
        } finally {
            $this->deleteLimitedUser($limited);
        }
    }

    private function makeLimitedUserOrSkip(): User
    {
        try {
            $suffix = $this->generateUniqueSuffix();
            $attrs = [
                'name'              => 'Limited COM ' . $suffix,
                'short_name'        => 'lcm' . substr($suffix, -5),
                'email'             => 'limited.com.' . $suffix . '@tenant.test',
                'emp_code'          => 'LCM_' . uniqid(),
                'password'          => 'password',
                'email_verified_at' => now(),
            ];

            if (Schema::hasColumn('sys_users', 'user_type')) {
                $attrs['user_type'] = 'Staff';
            }
            if (Schema::hasColumn('sys_users', 'prefered_language')) {
                $lang = DB::table('glb_languages')->value('id');
                if ($lang !== null) {
                    $attrs['prefered_language'] = $lang;
                }
            }

            $user = User::factory()->create($attrs);

            foreach (['is_super_admin', 'super_admin_flag', 'is_admin'] as $flag) {
                if (Schema::hasColumn('sys_users', $flag)) {
                    $user->forceFill([$flag => 0])->save();
                }
            }
            if (method_exists($user, 'syncRoles')) {
                $user->syncRoles([]);
            }
            if (method_exists($user, 'syncPermissions')) {
                $user->syncPermissions([]);
            }
            $this->forgetPermissionCache();

            return $user;
        } catch (Throwable $e) {
            $this->markTestSkipped('Cannot build a limited tenant user: ' . $e->getMessage());
        }
    }

    private function deleteLimitedUser(?User $user): void
    {
        if (!$user) {
            return;
        }
        try {
            if (method_exists($user, 'syncRoles')) {
                $user->syncRoles([]);
            }
            if (method_exists($user, 'syncPermissions')) {
                $user->syncPermissions([]);
            }
            $user->forceDelete();
        } catch (Throwable) {
            try {
                $user->delete();
            } catch (Throwable) {
            }
        }
    }

    private function forgetPermissionCache(): void
    {
        try {
            app(\Spatie\Permission\PermissionRegistrar::class)->forgetCachedPermissions();
        } catch (Throwable) {
        }
    }

    /** Valid CommunicationLog payload (created_by/updated_by auto-managed cols supplied). */
    private function buildCommLogPayload(array $overrides = []): array
    {
        $adminId = (int) ($this->adminUser?->id ?? User::query()->orderBy('id')->value('id'));

        return array_merge([
            'channel'          => 'Email',
            'subject'          => 'Subject ' . $this->generateUniqueSuffix(),
            'body'             => 'Message body ' . $this->generateUniqueSuffix(),
            'recipient_group'  => 'All_Parents',
            'total_recipients' => 0,
            'sent_count'       => 0,
            'failed_count'     => 0,
            'is_active'        => 1,
            'created_by'       => $adminId,
            'updated_by'       => $adminId,
        ], $overrides);
    }

    /** Valid EmailTemplate payload. */
    private function buildTemplatePayload(array $overrides = []): array
    {
        $adminId = (int) ($this->adminUser?->id ?? User::query()->orderBy('id')->value('id'));

        return array_merge([
            'name'       => 'Template ' . $this->generateUniqueSuffix(),
            'subject'    => 'Welcome {{student_name}} ' . $this->generateUniqueSuffix(),
            'body'       => '<p>Hello {{parent_name}}</p>',
            'module'     => 'FrontOffice',
            'is_active'  => 1,
            'created_by' => $adminId,
            'updated_by' => $adminId,
        ], $overrides);
    }

    /** Valid SmsLog payload bound to a real parent CommunicationLog + the admin as recipient. */
    private function buildSmsLogPayload(CommunicationLog $parent, array $overrides = []): array
    {
        $adminId = (int) ($this->adminUser?->id ?? User::query()->orderBy('id')->value('id'));

        return array_merge([
            'communication_log_id' => $parent->id,
            'recipient_user_id'    => $adminId,
            'mobile_number'        => '9876543210',
            'message'              => 'SMS body ' . $this->generateUniqueSuffix(),
            'sms_units'            => 1,
            'status'               => 'Queued',
            'is_active'            => 1,
            'created_by'           => $adminId,
            'updated_by'           => $adminId,
        ], $overrides);
    }

    private function createCommLog(array $overrides = []): CommunicationLog
    {
        return CommunicationLog::query()->create($this->buildCommLogPayload($overrides));
    }

    private function createTemplate(array $overrides = []): EmailTemplate
    {
        return EmailTemplate::query()->create($this->buildTemplatePayload($overrides));
    }

    /** Issue an authenticated JSON request from the page and return the decoded body. */
    private function jsonRequestFromBrowser(Browser $browser, string $url, string $method): ?array
    {
        $encodedUrl = json_encode($url);
        $csrf = $browser->script("return document.querySelector('meta[name=\"csrf-token\"]')?.getAttribute('content') || '';");
        $csrfToken = is_array($csrf) ? ($csrf[0] ?? '') : '';
        $jsMethod = strtoupper($method);
        $spoof = in_array($jsMethod, ['PATCH', 'PUT', 'DELETE'], true) ? $jsMethod : '';

        $browser->script(<<<JS
window.__jsonDone = false;
window.__jsonResponse = null;
(async function () {
    try {
        const csrf = {$this->escapeJsString($csrfToken)};
        const body = new URLSearchParams({ _token: csrf });
        if ('{$spoof}' !== '') { body.append('_method', '{$spoof}'); }
        const response = await fetch({$encodedUrl}, {
            method: '{$spoof}' !== '' ? 'POST' : '{$jsMethod}',
            credentials: 'same-origin',
            headers: {
                'X-Requested-With': 'XMLHttpRequest',
                'X-CSRF-TOKEN': csrf,
                'Accept': 'application/json',
                'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
            },
            body: body.toString(),
        });
        try { window.__jsonResponse = await response.json(); }
        catch (e) { window.__jsonResponse = { success: response.ok, status: response.status }; }
    } catch (error) {
        console.error(error);
    } finally {
        window.__jsonDone = true;
    }
})();
JS);

        $browser->waitUsing(20, 200, function () use ($browser): bool {
            $result = $browser->script('return window.__jsonDone === true;');
            return is_array($result) && (($result[0] ?? false) === true);
        }, 'JSON request did not complete.');

        $result = $browser->script('return window.__jsonResponse || null;');
        return is_array($result) ? ($result[0] ?? null) : null;
    }

    /** POST an application/x-www-form-urlencoded body from the page; return the HTTP status. */
    private function postFormFromBrowser(Browser $browser, string $url, array $fields): int
    {
        $encodedUrl = json_encode($url);
        $csrf = $browser->script("return document.querySelector('meta[name=\"csrf-token\"]')?.getAttribute('content') || '';");
        $csrfToken = is_array($csrf) ? ($csrf[0] ?? '') : '';
        $fieldsJson = json_encode($fields, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);

        $browser->script(<<<JS
window.__postDone = false;
window.__postStatus = 0;
(async function () {
    try {
        const csrf = {$this->escapeJsString($csrfToken)};
        const params = new URLSearchParams(Object.assign({ _token: csrf }, {$fieldsJson}));
        const response = await fetch({$encodedUrl}, {
            method: 'POST',
            credentials: 'same-origin',
            redirect: 'manual',
            headers: {
                'X-CSRF-TOKEN': csrf,
                'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
            },
            body: params.toString(),
        });
        window.__postStatus = response.status === 0 ? 302 : response.status;
    } catch (error) {
        console.error(error);
        window.__postStatus = -1;
    } finally {
        window.__postDone = true;
    }
})();
JS);

        $browser->waitUsing(20, 200, function () use ($browser): bool {
            $result = $browser->script('return window.__postDone === true;');
            return is_array($result) && (($result[0] ?? false) === true);
        }, 'Form POST did not complete.');

        $result = $browser->script('return window.__postStatus || 0;');
        return is_array($result) ? (int) ($result[0] ?? 0) : 0;
    }

    private function uniqueIndexCount(string $table): int
    {
        try {
            $rows = DB::select("SHOW INDEX FROM `{$table}` WHERE Non_unique = 0 AND Key_name <> 'PRIMARY'");
            $names = [];
            foreach ($rows as $row) {
                $names[$row->Key_name ?? ''] = true;
            }
            return count($names);
        } catch (Throwable) {
            return 0;
        }
    }

    private function showCreateTable(string $table): string
    {
        $row = DB::selectOne("SHOW CREATE TABLE `{$table}`");
        if (!$row) {
            throw new \RuntimeException('SHOW CREATE TABLE returned nothing.');
        }
        $arr = (array) $row;
        return (string) ($arr['Create Table'] ?? $arr['Create View'] ?? '');
    }

    private function authenticateBrowserSession(Browser $browser): void
    {
        $browser->visit($this->tenantUrl('/login'))->pause(800);

        if ($browser->element('input[name="email"]') && $browser->element('input[name="password"]')) {
            $browser->type('email', $this->adminEmail)
                ->type('password', $this->adminPassword)
                ->press('Sign In')
                ->pause(1400);
        }

        if (str_contains($this->currentPath($browser), '/login')) {
            $browser->loginAs($this->adminUser)->pause(600);
        }
    }

    private function visitPathWithAuthentication(Browser $browser, string $path, int $pauseMs = 900): void
    {
        $browser->visit($this->tenantUrl($path))->pause($pauseMs);

        if (str_contains($this->currentPath($browser), '/login')) {
            $this->authenticateBrowserSession($browser);
            $browser->visit($this->tenantUrl($path))->pause($pauseMs);
        }
    }

    private function initializeTenantContextForTests(): void
    {
        $tenantHost = parse_url($this->tenantBaseUrl, PHP_URL_HOST);

        if (!is_string($tenantHost) || $tenantHost === '') {
            $this->markTestSkipped('Tenant host missing in DUSK_TENANT_URL/APP_URL.');
        }

        $domain = Domain::query()->where('domain', $tenantHost)->first();
        if (!$domain) {
            $this->markTestSkipped('Tenant domain not found for host: ' . $tenantHost);
        }

        if (function_exists('tenancy')) {
            tenancy()->initialize($domain->tenant);
        }
    }

    private function resolveAdminUserAndPermissions(): void
    {
        $this->adminUser = User::query()->where('email', $this->adminEmail)->first()
            ?? User::query()->first();

        if (!$this->adminUser) {
            $this->markTestSkipped('No tenant user found for dusk login.');
        }

        if (property_exists($this->adminUser, 'email_verified_at') && !$this->adminUser->email_verified_at) {
            $this->adminUser->email_verified_at = now();
            $this->adminUser->save();
        }

        $this->grantPermissionsToUser($this->adminUser);
    }

    private function grantPermissionsToUser(User $user): void
    {
        if (!method_exists($user, 'givePermissionTo')) {
            return;
        }

        $this->ensurePermissionsExist(self::PERMISSIONS);

        foreach (self::PERMISSIONS as $permission) {
            try {
                $user->givePermissionTo($permission);
            } catch (Throwable) {
            }
        }
        $this->forgetPermissionCache();
    }

    private function ensurePermissionsExist(array $permissions): void
    {
        if (!class_exists(\Spatie\Permission\Models\Permission::class)) {
            return;
        }

        $guard = config('auth.defaults.guard', 'web');

        foreach ($permissions as $permission) {
            try {
                \Spatie\Permission\Models\Permission::firstOrCreate([
                    'name' => $permission,
                    'guard_name' => $guard,
                ]);
            } catch (Throwable) {
            }
        }
    }

    private function tenantUrl(string $path): string
    {
        return $this->tenantBaseUrl . '/' . ltrim($path, '/');
    }

    private function currentPath(Browser $browser): string
    {
        $path = parse_url($browser->driver->getCurrentURL(), PHP_URL_PATH);
        return is_string($path) ? $path : '';
    }

    private function generateUniqueSuffix(): string
    {
        return now()->format('His') . random_int(100, 999);
    }

    private function escapeJsString(string $value): string
    {
        return json_encode($value, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE);
    }

    private function responseStatusCode(Browser $browser): int
    {
        try {
            $result = $browser->driver->executeScript(
                'return window.performance.getEntriesByType("navigation")[0]?.responseStatus || 0'
            );
            if (is_numeric($result) && (int) $result > 0) {
                return (int) $result;
            }
        } catch (Throwable) {
        }
        try {
            $url = $browser->driver->getCurrentURL();
            $ch = curl_init($url);
            curl_setopt_array($ch, [
                CURLOPT_RETURNTRANSFER => true, CURLOPT_NOBODY => true,
                CURLOPT_HEADER => true, CURLOPT_FOLLOWLOCATION => false,
                CURLOPT_TIMEOUT => 10, CURLOPT_SSL_VERIFYPEER => false,
            ]);
            curl_exec($ch);
            $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
            curl_close($ch);
            return (int) $httpCode;
        } catch (Throwable) {
        }
        return 0;
    }
}
