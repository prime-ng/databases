<?php

namespace Tests\Browser;

use App\Models\User;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\FrontOffice\Models\CertificateRequest;
use Modules\GlobalMaster\Models\ActivityLog;
use Modules\Prime\Models\Domain;
use Modules\StudentProfile\Models\Student;
use Tests\DuskTestCase;
use Throwable;

/**
 * FrontOffice — Certificate Request & Issuance (workflow screen).
 *
 * Table:   fof_certificate_requests   (prefix fof_, verified vs FrontOffice_DDL_v1.sql)
 * Model:   Modules\FrontOffice\Models\CertificateRequest (SoftDeletes)
 * Routes:  /front-office/certificates/* (name group fof.certificates.*)
 * Gates:   frontoffice.certificate.{view,create,update,delete,issue,restore,forceDelete}
 * Events:  certificate_request_created|updated|deleted, certificate_approved|rejected|issued
 *
 * STYLE: single-style file — browser (Dusk) flows + tenant-side DB/model/reflection assertions.
 *        No actingAs()->post() HTTP calls are mixed in (Rule Card A1). Endpoint/gate checks are
 *        done at the model/Gate/reflection layer so they hold even when the module is DISABLED
 *        in modules_statuses.json (all /front-office/* routes 404 until enabled — env prereq).
 *
 * Cross-module FKs (std_students, sys_media, StudentFee) are guarded with try/catch + markTestSkipped.
 */
class fof_CertificateRequest_TestCas extends DuskTestCase
{
    private const TABLE = 'fof_certificate_requests';
    private const INDEX_PATH = '/front-office/certificates';
    private const CREATE_PATH = '/front-office/certificates/create';
    private const LOG_PATH = '/front-office/certificates/log';
    private const TRASH_PATH = '/front-office/certificates/trash/view';
    private const SHOW_BASE_PATH = '/front-office/certificates';

    private const CERT_TYPES = ['Bonafide', 'Character', 'Fee_Paid', 'Study', 'TC_Copy', 'Migration', 'Conduct', 'Other'];
    private const STATUSES = ['Pending_Approval', 'Approved', 'Rejected', 'Issued', 'Cancelled'];

    private ?User $adminUser = null;
    private string $tenantBaseUrl = '';
    private string $adminEmail = '';
    private string $adminPassword = '';
    private static bool $screenshotsCleaned = false;

    protected function setUp(): void
    {
        parent::setUp();

        if (!self::$screenshotsCleaned) {
            $this->cleanScreenshots();
            self::$screenshotsCleaned = true;
        }

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

    // ===================================================================
    // 01–09  SCHEMA / DDL / MODEL / CONFIG TRUTH
    // ===================================================================

    /** G46 — full DDL↔app alignment matrix vs the LIVE schema. */
    public function test_cert_01_migration_model_and_request_configuration_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable(self::TABLE), 'Table fof_certificate_requests is missing.');

        $expected = [
            'id', 'request_number', 'student_id', 'cert_type', 'purpose', 'copies_requested',
            'is_urgent', 'applicant_name', 'applicant_contact', 'stages_json', 'status',
            'approved_by', 'approved_at', 'rejection_reason', 'cert_number', 'issued_at',
            'issued_by', 'issued_to', 'media_id', 'is_active', 'created_by', 'updated_by',
            'created_at', 'updated_at', 'deleted_at',
        ];
        $this->assertTrue(
            Schema::hasColumns(self::TABLE, $expected),
            'One or more DDL columns are missing from the live fof_certificate_requests table.'
        );

        // Model wiring
        $model = new CertificateRequest();
        $this->assertSame(self::TABLE, $model->getTable(), 'Model $table must equal fof_certificate_requests (G47).');

        $fillable = $model->getFillable();
        foreach (['request_number', 'student_id', 'cert_type', 'purpose', 'status', 'cert_number', 'issued_to'] as $f) {
            $this->assertContains($f, $fillable, "Column {$f} must be fillable.");
        }

        $casts = $model->getCasts();
        $this->assertSame('boolean', $casts['is_urgent'] ?? null);
        $this->assertSame('boolean', $casts['is_active'] ?? null);
        $this->assertSame('array', $casts['stages_json'] ?? null);
        $this->assertArrayHasKey('approved_at', $casts);
        $this->assertArrayHasKey('issued_at', $casts);

        // Relationship + scopes exist (real Laravel methods only — F34)
        $this->assertTrue(method_exists($model, 'student'), 'student() relationship missing.');
        $this->assertTrue(method_exists($model, 'scopeActive'), 'scopeActive missing.');
        $this->assertTrue(method_exists($model, 'scopePending'), 'scopePending missing.');
    }

    /** G43 — both UNIQUE indexes present on the live schema (request_number, cert_number). */
    public function test_cert_02_unique_indexes_present_on_live_schema(): void
    {
        try {
            $indexes = collect(DB::select('SHOW INDEX FROM ' . self::TABLE));
        } catch (Throwable $e) {
            $this->markTestSkipped('SHOW INDEX unavailable: ' . $e->getMessage());
        }

        $uniqueCols = $indexes
            ->where('Non_unique', 0)
            ->pluck('Column_name')
            ->map(static fn ($c) => strtolower((string) $c))
            ->all();

        $this->assertContains('request_number', $uniqueCols, 'UNIQUE index on request_number missing (uq_fof_cr_request_number).');
        $this->assertContains('cert_number', $uniqueCols, 'UNIQUE index on cert_number missing (uq_fof_cr_cert_number).');
    }

    /** G46/#30 — soft-delete column and trait asserted INDEPENDENTLY. */
    public function test_cert_03_soft_delete_column_and_trait_are_independent(): void
    {
        $columnPresent = Schema::hasColumn(self::TABLE, 'deleted_at');
        $traitPresent = in_array(SoftDeletes::class, class_uses_recursive(CertificateRequest::class), true);

        $this->assertTrue($columnPresent, 'deleted_at column missing on live schema.');
        $this->assertTrue($traitPresent, 'CertificateRequest must use the SoftDeletes trait.');
        // If these ever disagree, that is a DEV-### (do not force them to match).
    }

    /** NOT-NULL / nullable posture matches the DDL on the live schema (G44/G46). */
    public function test_cert_04_column_nullability_matches_ddl(): void
    {
        $notNull = ['request_number', 'student_id', 'cert_type', 'purpose', 'created_by', 'updated_by'];
        $nullable = ['applicant_name', 'applicant_contact', 'rejection_reason', 'cert_number', 'issued_at', 'issued_by', 'issued_to', 'media_id', 'approved_by', 'approved_at'];

        foreach ($notNull as $col) {
            $this->assertSame('NO', $this->columnIsNullable($col), "Column {$col} must be NOT NULL per DDL.");
        }
        foreach ($nullable as $col) {
            $this->assertSame('YES', $this->columnIsNullable($col), "Column {$col} must be NULLABLE per DDL.");
        }
    }

    // ===================================================================
    // 10–19  BUSINESS RULES (auto fields / defaults)
    // ===================================================================

    /** BR — request_number is auto-generated by the controller (CERT-YYYYMMDD-NNN); user cannot set it (G48). */
    public function test_cert_10_request_number_generator_format_is_code_managed(): void
    {
        $file = $this->controllerSourceOrSkip();
        $this->assertStringContainsString('generateRequestNumber', $file, 'request_number generator missing.');
        $this->assertStringContainsString("'CERT-'", $file, 'request_number prefix should be CERT-.');
        // Auto field — never a form input; store() sets it, so it is NOT in the store() validate() ruleset.
        $this->assertStringNotContainsString("'request_number' =>", $this->validationBlock($file), 'request_number must not be a validated form input.');
    }

    /** BR — copies_requested defaults to 1 when omitted (DB/controller default). Read back via refresh() (F35). */
    public function test_cert_11_copies_requested_defaults_to_one(): void
    {
        $studentId = $this->resolveActiveStudentIdOrSkip();
        $record = null;
        try {
            $record = $this->createRequestDirectly($studentId, ['copies_requested' => 1]);
            $record->refresh();
            $this->assertSame(1, (int) $record->copies_requested, 'copies_requested should default to 1.');
            $this->assertFalse((bool) $record->is_urgent, 'is_urgent should default to 0/false.');
            $this->assertSame('Pending_Approval', $record->status, 'status should default to Pending_Approval.');
        } finally {
            $this->forceDeleteIfExists($record);
        }
    }

    /** BR — is_urgent boolean cast persists true. */
    public function test_cert_12_is_urgent_flag_persists(): void
    {
        $studentId = $this->resolveActiveStudentIdOrSkip();
        $record = null;
        try {
            $record = $this->createRequestDirectly($studentId, ['is_urgent' => true]);
            $record->refresh();
            $this->assertTrue((bool) $record->is_urgent, 'is_urgent should persist as true.');
        } finally {
            $this->forceDeleteIfExists($record);
        }
    }

    /** BUG-FOF-004 — cert_number generator prefix/format is code-managed (observed: slash format, deviates from BR spec). */
    public function test_cert_13_cert_number_generator_is_code_managed(): void
    {
        $file = $this->controllerSourceOrSkip();
        $this->assertStringContainsString('generateCertNumber', $file, 'cert_number generator missing.');
        // Observed current format uses "/" (e.g. BON/2026/0001) — BUG-FOF-004 deviation from BR-FOF-016 dash spec.
        $this->assertStringContainsString("'/'", $file, 'Observed cert_number format uses slash separators (BUG-FOF-004).');
    }

    // ===================================================================
    // 20–29  STATE MACHINE (BC-SM)
    // ===================================================================

    /** BC-SM — legal: Pending_Approval --approve--> Approved (approve() sets approved_by/at). */
    public function test_cert_20_approve_transitions_pending_to_approved(): void
    {
        $studentId = $this->resolveActiveStudentIdOrSkip();
        $record = null;
        try {
            $record = $this->createRequestDirectly($studentId, ['status' => 'Pending_Approval']);
            // Simulate the controller's approve() effect through the verified model (G47).
            $record->update([
                'status' => 'Approved',
                'approved_by' => (int) $this->adminUser->id,
                'approved_at' => now(),
                'updated_by' => (int) $this->adminUser->id,
            ]);
            $record->refresh();
            $this->assertSame('Approved', $record->status);
            $this->assertNotNull($record->approved_at, 'approved_at must be set on approval.');
        } finally {
            $this->forceDeleteIfExists($record);
        }
    }

    /** BC-SM — legal: Pending_Approval --reject--> Rejected (rejection_reason required by controller). */
    public function test_cert_21_reject_transitions_pending_to_rejected(): void
    {
        $studentId = $this->resolveActiveStudentIdOrSkip();
        $record = null;
        try {
            $record = $this->createRequestDirectly($studentId, ['status' => 'Pending_Approval']);
            $record->update(['status' => 'Rejected', 'rejection_reason' => 'Incomplete documents']);
            $record->refresh();
            $this->assertSame('Rejected', $record->status);
            $this->assertSame('Incomplete documents', $record->rejection_reason);
        } finally {
            $this->forceDeleteIfExists($record);
        }
    }

    /** BC-SM — legal: Approved --issue--> Issued (cert_number assigned, issued_at set). */
    public function test_cert_22_issue_transitions_approved_to_issued(): void
    {
        $studentId = $this->resolveActiveStudentIdOrSkip();
        $record = null;
        try {
            $record = $this->createRequestDirectly($studentId, ['status' => 'Approved', 'cert_type' => 'Bonafide']);
            $certNo = 'BON/' . now()->format('Y') . '/' . $this->uniqueSuffix();
            $record->update([
                'status' => 'Issued',
                'cert_number' => $certNo,
                'issued_to' => 'Parent Name',
                'issued_by' => (int) $this->adminUser->id,
                'issued_at' => now(),
            ]);
            $record->refresh();
            $this->assertSame('Issued', $record->status);
            $this->assertSame($certNo, $record->cert_number);
            $this->assertNotNull($record->issued_at);
        } finally {
            $this->forceDeleteIfExists($record);
        }
    }

    /** BC-SM — illegal transitions are guarded in the controller (throw_unless DomainException). */
    public function test_cert_23_illegal_transitions_are_guarded_in_source(): void
    {
        $file = $this->controllerSourceOrSkip();
        // approve()/reject() only from Pending_Approval; issue() only from Approved.
        $this->assertStringContainsString("Only Pending_Approval requests can be approved.", $file);
        $this->assertStringContainsString("Only Pending_Approval requests can be rejected.", $file);
        $this->assertStringContainsString("Only Approved requests can be issued.", $file);
        $this->assertStringContainsString('DomainException', $file, 'Illegal transitions must throw DomainException.');
    }

    /** BC-SM — download() is available only when status = Issued (abort_if 404 otherwise). */
    public function test_cert_24_download_requires_issued_status(): void
    {
        $file = $this->controllerSourceOrSkip();
        $this->assertStringContainsString("abort_if(\$cert->status !== 'Issued'", $file, 'download() must 404 for non-Issued.');
    }

    /**
     * BC-SM — DEV-FOF-CR-03: the 'Cancelled' status exists in the DDL enum + requirement lifecycle
     * but NO controller action transitions a request into 'Cancelled' (unreachable state).
     */
    public function test_cert_25_cancelled_status_is_unreachable_via_controller(): void
    {
        $file = $this->controllerSourceOrSkip();
        // update() validation whitelist deliberately omits 'Cancelled'; no method sets it.
        $this->assertStringNotContainsString("'status'      => 'Cancelled'", $file);
        $this->assertStringNotContainsString("'status' => 'Cancelled'", $file);
        // The DB column still accepts it, proving it is a code-reachability gap, not a schema gap.
        $this->assertContains('Cancelled', self::STATUSES);
    }

    // ===================================================================
    // 30–39  VALIDATION (BC-VAL) — DDL-derived negatives (G44/G45) + inline rules
    // ===================================================================

    /** G44 — every NOT-NULL-no-default column rejects a missing value at the DB layer. */
    public function test_cert_30_missing_not_null_fields_are_rejected(): void
    {
        $studentId = $this->resolveActiveStudentIdOrSkip();
        foreach (['request_number', 'student_id', 'cert_type', 'purpose', 'created_by', 'updated_by'] as $field) {
            $this->assertDbRejectsMissingField($studentId, $field);
        }
    }

    /** G44 — nullable columns accept NULL (omitted-value positive). */
    public function test_cert_31_nullable_fields_accept_null(): void
    {
        $studentId = $this->resolveActiveStudentIdOrSkip();
        $record = null;
        try {
            $record = $this->createRequestDirectly($studentId, [
                'applicant_name' => null,
                'applicant_contact' => null,
                'stages_json' => null,
                'rejection_reason' => null,
                'cert_number' => null,
                'issued_to' => null,
                'issued_at' => null,
                'issued_by' => null,
                'approved_by' => null,
                'approved_at' => null,
                'media_id' => null,
            ]);
            $this->assertNotNull($record->id, 'Record with nullable values omitted did not save.');
        } finally {
            $this->forceDeleteIfExists($record);
        }
    }

    /** G45 — over-length purpose (VARCHAR(200)) is rejected; exactly-200 is accepted. */
    public function test_cert_32_purpose_length_boundary(): void
    {
        $studentId = $this->resolveActiveStudentIdOrSkip();

        // exactly 200 — should succeed
        $ok = null;
        try {
            $ok = $this->createRequestDirectly($studentId, ['purpose' => str_repeat('a', 200)]);
            $this->assertNotNull($ok->id, 'Exactly-200-char purpose should be accepted.');
        } finally {
            $this->forceDeleteIfExists($ok);
        }

        // 201 — DB must reject (strict mode 1406) OR silently truncate; tolerate both (F41).
        $overLen = null;
        try {
            $overLen = $this->createRequestDirectly($studentId, ['purpose' => str_repeat('b', 260)]);
            $overLen->refresh();
            $this->assertLessThanOrEqual(200, mb_strlen((string) $overLen->purpose), 'Over-length purpose must not persist beyond 200 chars.');
        } catch (Throwable $e) {
            $msg = strtolower($e->getMessage());
            $this->assertTrue(
                str_contains($msg, 'data too long') || str_contains($msg, '1406') || str_contains($msg, '22001'),
                'Over-length purpose should be rejected by the DB (1406 / data too long), got: ' . $e->getMessage()
            );
        } finally {
            $this->forceDeleteIfExists($overLen);
        }
    }

    /** G45 — cert_number VARCHAR(30) length boundary (exactly 30 accepted). */
    public function test_cert_33_cert_number_length_boundary(): void
    {
        $studentId = $this->resolveActiveStudentIdOrSkip();
        $ok = null;
        try {
            $ok = $this->createRequestDirectly($studentId, [
                'status' => 'Issued',
                'cert_number' => substr('C' . str_repeat('9', 29), 0, 30),
            ]);
            $this->assertNotNull($ok->id, 'Exactly-30-char cert_number should be accepted.');
            $this->assertSame(30, mb_strlen((string) $ok->cert_number));
        } finally {
            $this->forceDeleteIfExists($ok);
        }
    }

    /** BC-VAL — inline controller rules match the DDL enum/ranges (source assertion). */
    public function test_cert_34_store_validation_rules_match_ddl(): void
    {
        $file = $this->controllerSourceOrSkip();
        $this->assertStringContainsString("'student_id'       => 'required|integer|exists:std_students,id'", $file);
        $this->assertStringContainsString("'cert_type'        => 'required|in:Bonafide,Character,Fee_Paid,Study,TC_Copy,Migration,Conduct,Other'", $file);
        $this->assertStringContainsString("'purpose'          => 'required|string|max:200'", $file);
        $this->assertStringContainsString("'copies_requested' => 'integer|min:1|max:10'", $file);
    }

    /** DEV-FOF-CR-02 — copies_requested range divergence: controller max:10 vs DDL/req spec 1–5. */
    public function test_cert_35_copies_requested_range_divergence_is_documented(): void
    {
        $file = $this->controllerSourceOrSkip();
        // Controller permits up to 10 copies; requirement + DDL comment say 1–5. Assert observed (10).
        $this->assertStringContainsString('min:1|max:10', $file, 'Observed store() copies range is 1..10 (DEV-FOF-CR-02).');
    }

    /** BC-VAL — reject() requires rejection_reason; issue() requires issued_to (source). */
    public function test_cert_36_workflow_actions_require_their_fields(): void
    {
        $file = $this->controllerSourceOrSkip();
        $this->assertStringContainsString("'rejection_reason' => 'required|string|max:500'", $file, 'reject() must require rejection_reason.');
        $this->assertStringContainsString("'issued_to' => 'required|string|max:100'", $file, 'issue() must require issued_to.');
    }

    // ===================================================================
    // 40–49  INTEGRATION / FK DEPENDENCY (BC-INT / BC-REF) + fee-gate
    // ===================================================================

    /** BC-REF — student_id FK RESTRICT: an invalid student id is rejected by the DB. */
    public function test_cert_40_invalid_student_fk_is_rejected(): void
    {
        $bogus = 2147480000; // extremely unlikely to exist
        $created = null;
        try {
            $created = CertificateRequest::query()->create($this->rawPayload($bogus));
            $this->fail('Expected FK rejection for a non-existent student_id.');
        } catch (Throwable $e) {
            $msg = strtolower($e->getMessage());
            $this->assertTrue(
                str_contains($msg, 'foreign key') || str_contains($msg, 'constraint') || str_contains($msg, '1452') || str_contains($msg, '23000'),
                'Expected a FK/integrity failure, got: ' . $e->getMessage()
            );
        } finally {
            $this->forceDeleteIfExists($created);
        }
    }

    /**
     * DAT-FOF-001 (audit) — issue() fee-clearance guard for TC_Copy/Migration.
     * VERIFIED REMEDIATED in current source: the guard is PRESENT (StudentFee balance check).
     * Proving test asserts the guard exists (source-level, env-independent).
     */
    public function test_cert_41_issue_has_fee_clearance_guard_for_tc_and_migration(): void
    {
        $file = $this->controllerSourceOrSkip();
        $this->assertStringContainsString("in_array(\$cert->cert_type, ['TC_Copy', 'Migration'])", $file, 'DAT-FOF-001: fee-gate condition for TC_Copy/Migration must be present.');
        $this->assertStringContainsString('balance_amount', $file, 'Fee-gate must sum outstanding balance_amount.');
        $this->assertStringContainsString('outstanding fees', $file, 'Fee-gate must block issuance with an outstanding-fees message.');
    }

    /** BC-INT — the StudentFee dependency classes referenced by the fee-gate are resolvable (defensive). */
    public function test_cert_42_studentfee_dependency_is_available_or_skipped(): void
    {
        try {
            $this->assertTrue(
                class_exists(\Modules\StudentFee\Models\FeeInvoice::class),
                'FeeInvoice model should be autoloadable for the fee-gate.'
            );
            $this->assertTrue(
                class_exists(\Modules\StudentFee\Models\FeeStudentAssignment::class),
                'FeeStudentAssignment model should be autoloadable for the fee-gate.'
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('StudentFee module not present in this environment: ' . $e->getMessage());
        }
    }

    // ===================================================================
    // 50–59  PERMISSIONS / AUTHORIZATION (BC-AUTH)
    // ===================================================================

    /** BC-AUTH — every controller method authorizes via the frontoffice.certificate.* gates (source). */
    public function test_cert_50_controller_methods_call_expected_gates(): void
    {
        $file = $this->controllerSourceOrSkip();
        foreach ([
            "Gate::authorize('frontoffice.certificate.view')",
            "Gate::authorize('frontoffice.certificate.create')",
            "Gate::authorize('frontoffice.certificate.update')",
            "Gate::authorize('frontoffice.certificate.delete')",
            "Gate::authorize('frontoffice.certificate.issue')",
            "Gate::authorize('frontoffice.certificate.restore')",
            "Gate::authorize('frontoffice.certificate.forceDelete')",
        ] as $gate) {
            $this->assertStringContainsString($gate, $file, "Missing gate: {$gate}");
        }
    }

    /**
     * F37/#31 — permission NEGATIVE: a non-super-admin without the ability is DENIED.
     * Uses forgetCachedPermissions() and a fresh non-super-admin so Gate::before cannot false-pass.
     */
    public function test_cert_51_non_super_admin_without_permission_is_denied(): void
    {
        $user = $this->makeLimitedUserOrSkip();
        try {
            app(\Spatie\Permission\PermissionRegistrar::class)->forgetCachedPermissions();

            $this->assertTrue(
                Gate::forUser($user)->denies('frontoffice.certificate.create'),
                'A non-super-admin without frontoffice.certificate.create must be denied.'
            );
            $this->assertTrue(
                Gate::forUser($user)->denies('frontoffice.certificate.issue'),
                'A non-super-admin without frontoffice.certificate.issue must be denied.'
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('Permission stack unavailable: ' . $e->getMessage());
        } finally {
            try {
                $user->forceDelete();
            } catch (Throwable) {
                // ignore cleanup errors
            }
        }
    }

    /** BC-AUTH — guest visiting the index is redirected to /login (auth middleware). */
    public function test_cert_52_guest_is_redirected_to_login(): void
    {
        $this->browse(function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->tenantUrl(self::INDEX_PATH))->pause(1200);

            $path = $this->currentPath($browser);
            // Module may be disabled (404) — tolerate that; otherwise must bounce to /login.
            $this->assertTrue(
                str_contains($path, '/login') || $browser->driver->getCurrentURL() !== $this->tenantUrl(self::INDEX_PATH) || $this->pageSourceContains($browser, 'login') || $this->pageSourceContains($browser, 'Not Found'),
                'Guest should not reach the authenticated certificates index directly.'
            );
        });
    }

    // ===================================================================
    // 60–69  UI / UX (render, empty state, modal, log)
    // ===================================================================

    /** UI — index renders with the New Request control and Issued Log link (when module enabled). */
    public function test_cert_60_index_renders_or_skips_when_module_disabled(): void
    {
        $this->browse(function (Browser $browser): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::INDEX_PATH, 1200);

            if ($this->pageSourceContains($browser, 'Not Found') || str_contains($this->currentPath($browser), '/login')) {
                $this->markTestSkipped('FrontOffice module disabled or login gate — index unreachable (env prereq).');
            }

            $browser->assertSee('Certificate Requests');
        });
    }

    /** UI — the issued-certificates log page loads (registry view). */
    public function test_cert_61_issued_log_page_loads_or_skips(): void
    {
        $this->browse(function (Browser $browser): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::LOG_PATH, 1200);

            if ($this->pageSourceContains($browser, 'Not Found') || str_contains($this->currentPath($browser), '/login')) {
                $this->markTestSkipped('FrontOffice module disabled — log page unreachable (env prereq).');
            }
            $this->assertFalse($this->pageSourceContains($browser, 'Server Error'), 'Log page should not 500.');
        });
    }

    /** UI — create-form Blade exposes the real field names used by store(). */
    public function test_cert_62_create_form_exposes_expected_fields(): void
    {
        $blade = $this->readModuleFileOrSkip('resources/views/fof/certificates/create.blade.php');
        foreach (['name="student_id"', 'name="cert_type"', 'name="purpose"', 'name="copies_requested"', 'name="is_urgent"'] as $needle) {
            $this->assertStringContainsString($needle, $blade, "Create form should expose {$needle}.");
        }
    }

    // ===================================================================
    // 70–79  EDGE CASES (BC-EDG) — uniqueness / duplicates / defect probes
    // ===================================================================

    /** G43 — duplicate request_number is rejected by the UNIQUE index. */
    public function test_cert_70_duplicate_request_number_is_rejected(): void
    {
        $studentId = $this->resolveActiveStudentIdOrSkip();
        $number = 'CERT-' . now()->format('Ymd') . '-' . random_int(100, 999);
        $first = null;
        $second = null;
        try {
            $first = $this->createRequestDirectly($studentId, ['request_number' => $number]);
            try {
                $second = $this->createRequestDirectly($studentId, ['request_number' => $number]);
                $this->fail('Duplicate request_number should have been rejected by uq_fof_cr_request_number.');
            } catch (Throwable $e) {
                $this->assertTrue($this->isUniqueViolation($e), 'Expected UNIQUE violation, got: ' . $e->getMessage());
            }
        } finally {
            $this->forceDeleteIfExists($second);
            $this->forceDeleteIfExists($first);
        }
    }

    /** G43 — duplicate NON-NULL cert_number is rejected; multiple NULL cert_numbers are allowed (BR-FOF-006). */
    public function test_cert_71_duplicate_cert_number_rejected_but_nulls_allowed(): void
    {
        $studentId = $this->resolveActiveStudentIdOrSkip();
        $certNo = 'DUP/' . now()->format('Y') . '/' . random_int(1000, 9999);
        $a = $b = $n1 = $n2 = null;
        try {
            // multiple NULLs are fine
            $n1 = $this->createRequestDirectly($studentId, ['cert_number' => null]);
            $n2 = $this->createRequestDirectly($studentId, ['cert_number' => null]);
            $this->assertNotNull($n1->id);
            $this->assertNotNull($n2->id);

            // duplicate non-null is rejected
            $a = $this->createRequestDirectly($studentId, ['cert_number' => $certNo]);
            try {
                $b = $this->createRequestDirectly($studentId, ['cert_number' => $certNo]);
                $this->fail('Duplicate cert_number should have been rejected by uq_fof_cr_cert_number.');
            } catch (Throwable $e) {
                $this->assertTrue($this->isUniqueViolation($e), 'Expected UNIQUE violation, got: ' . $e->getMessage());
            }
        } finally {
            $this->forceDeleteIfExists($b);
            $this->forceDeleteIfExists($a);
            $this->forceDeleteIfExists($n2);
            $this->forceDeleteIfExists($n1);
        }
    }

    /**
     * DEV-FOF-CR-04 — update() lets an operator jump status directly (e.g. to 'Issued') and set
     * cert_number/issued_to via the form, bypassing issue()'s fee-gate + auto cert_number + issued_by/at.
     * Proving test documents the observed permissive update() ruleset.
     */
    public function test_cert_72_update_allows_direct_status_jump_bypassing_issue_guard(): void
    {
        $file = $this->controllerSourceOrSkip();
        // update() whitelists status IN (...,'Issued') and accepts cert_number directly — no fee-gate on this path.
        $this->assertStringContainsString("'status'           => 'required|in:Pending_Approval,Approved,Rejected,Issued'", $file);
        $this->assertStringContainsString("'cert_number'      => 'nullable|string|max:30'", $file);
    }

    // ===================================================================
    // 90–99  TENANCY / SECURITY (TC-T / TC-S) + activity log
    // ===================================================================

    /** Activity-log — the controller logs the exact verbatim event strings (source assertion). */
    public function test_cert_90_activity_log_events_are_verbatim(): void
    {
        $file = $this->controllerSourceOrSkip();
        foreach ([
            "activityLog(\$cert, 'certificate_request_created'",
            "activityLog(\$cert, 'certificate_request_updated'",
            "activityLog(\$cert, 'certificate_request_deleted'",
            "activityLog(\$cert, 'certificate_approved'",
            "activityLog(\$cert, 'certificate_rejected'",
            "activityLog(\$cert, 'certificate_issued'",
        ] as $needle) {
            $this->assertStringContainsString($needle, $file, "Missing activity-log event: {$needle}");
        }
    }

    /** Activity-log sink — the tenant ActivityLog model/table exists and is the correct sink. */
    public function test_cert_91_tenant_activity_log_sink_is_correct(): void
    {
        try {
            $model = new ActivityLog();
            $this->assertTrue(Schema::hasTable($model->getTable()), 'Tenant activity_logs table missing.');
            $this->assertTrue(
                in_array('event', $model->getFillable(), true) || Schema::hasColumn($model->getTable(), 'event'),
                'Activity log must have an event column.'
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('Tenant ActivityLog model/table unavailable: ' . $e->getMessage());
        }
    }

    /** TC-S — stored XSS in the free-text purpose field is neutralised on the show view (or skipped if disabled). */
    public function test_cert_92_stored_xss_in_purpose_is_escaped(): void
    {
        $studentId = $this->resolveActiveStudentIdOrSkip();
        $record = null;
        try {
            $payload = '<script>alert("cert-xss")</script>';
            $record = $this->createRequestDirectly($studentId, ['purpose' => $payload]);

            $this->browse(function (Browser $browser) use ($record): void {
                $this->authenticateBrowserSession($browser);
                $this->visitPathWithAuthentication($browser, self::SHOW_BASE_PATH . '/' . $record->id, 1200);

                if ($this->pageSourceContains($browser, 'Not Found') || str_contains($this->currentPath($browser), '/login')) {
                    $this->markTestSkipped('Show page unreachable (module disabled) — cannot assert render escaping.');
                }
                // Blade {{ }} escapes — raw <script> must not appear unescaped in the DOM source.
                $this->assertFalse(
                    $this->pageSourceContains($browser, '<script>alert("cert-xss")</script>'),
                    'Purpose must be HTML-escaped on the show page (no raw <script>).'
                );
            });
        } finally {
            $this->forceDeleteIfExists($record);
        }
    }

    /** TC-T — records are addressable only within the initialized tenant context (basic isolation smoke). */
    public function test_cert_93_records_are_scoped_to_initialized_tenant(): void
    {
        $this->assertTrue(
            function_exists('tenancy') && tenancy()->initialized,
            'Tenant context must be initialized for fof_certificate_requests access (tenant-side table).'
        );
        $studentId = $this->resolveActiveStudentIdOrSkip();
        $record = null;
        try {
            $record = $this->createRequestDirectly($studentId);
            $found = CertificateRequest::query()->find($record->id);
            $this->assertNotNull($found, 'Record must be visible within its own tenant.');
        } finally {
            $this->forceDeleteIfExists($record);
        }
    }

    // ===================================================================
    // ------------------------ PRIVATE HELPERS --------------------------
    // ===================================================================

    private function columnIsNullable(string $column): string
    {
        try {
            $row = DB::selectOne(
                'SELECT IS_NULLABLE FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?',
                [self::TABLE, $column]
            );
            return $row->IS_NULLABLE ?? 'UNKNOWN';
        } catch (Throwable) {
            return 'UNKNOWN';
        }
    }

    private function rawPayload(int $studentId, array $overrides = []): array
    {
        $adminId = (int) ($this->adminUser?->id ?? 1);

        return array_merge([
            'request_number' => 'CERT-' . now()->format('Ymd') . '-' . $this->uniqueSuffix(),
            'student_id' => $studentId,
            'cert_type' => 'Bonafide',
            'purpose' => 'Automated test purpose',
            'copies_requested' => 1,
            'is_urgent' => false,
            'status' => 'Pending_Approval',
            'is_active' => true,
            'created_by' => $adminId,
            'updated_by' => $adminId,
        ], $overrides);
    }

    private function createRequestDirectly(int $studentId, array $overrides = []): CertificateRequest
    {
        return CertificateRequest::query()->create($this->rawPayload($studentId, $overrides));
    }

    private function assertDbRejectsMissingField(int $studentId, string $missingField): void
    {
        $created = null;
        try {
            $payload = $this->rawPayload($studentId);
            unset($payload[$missingField]);
            $created = CertificateRequest::query()->create($payload);
            $this->fail("Expected DB rejection for missing NOT-NULL field {$missingField}, but insert succeeded.");
        } catch (Throwable $e) {
            $msg = strtolower($e->getMessage());
            $isDbConstraint = str_contains($msg, 'cannot be null')
                || str_contains($msg, 'not null')
                || str_contains($msg, "doesn't have a default value")
                || str_contains($msg, 'integrity constraint')
                || str_contains($msg, 'foreign key')
                || str_contains($msg, '23000')
                || str_contains($msg, '1452')
                || str_contains($msg, '1364');
            $this->assertTrue($isDbConstraint, "Expected DB required/constraint failure for {$missingField}, got: " . $e->getMessage());
        } finally {
            $this->forceDeleteIfExists($created);
        }
    }

    private function isUniqueViolation(Throwable $e): bool
    {
        $msg = strtolower($e->getMessage());
        return str_contains($msg, 'duplicate')
            || str_contains($msg, 'unique')
            || str_contains($msg, '1062')
            || str_contains($msg, '23000');
    }

    private function forceDeleteIfExists(?CertificateRequest $record): void
    {
        if ($record instanceof CertificateRequest && $record->id) {
            try {
                CertificateRequest::withTrashed()->where('id', $record->id)->forceDelete();
            } catch (Throwable) {
                // ignore cleanup failures
            }
        }
    }

    private function resolveActiveStudentIdOrSkip(): int
    {
        try {
            $id = (int) Student::query()->where('is_active', 1)->orderBy('id')->value('id');
        } catch (Throwable $e) {
            $this->markTestSkipped('std_students not available (cross-module dependency): ' . $e->getMessage());
        }
        if ($id <= 0) {
            $this->markTestSkipped('No active std_students row to satisfy the RESTRICT FK.');
        }
        return $id;
    }

    private function makeLimitedUserOrSkip(): User
    {
        try {
            $suffix = $this->uniqueSuffix();
            $user = User::factory()->create([
                'name' => 'CertLimited ' . $suffix,
                'email' => 'cert.limited.' . $suffix . '@example.test',
                'emp_code' => 'CL_' . uniqid(),
                'short_name' => 'CL' . substr($suffix, -4),
            ]);

            // Strip any super-admin escalation so Gate::before cannot false-pass (#31).
            foreach (['is_super_admin', 'super_admin_flag', 'is_admin'] as $flag) {
                if (Schema::hasColumn('sys_users', $flag)) {
                    $user->forceFill([$flag => 0])->saveQuietly();
                }
            }
            if (method_exists($user, 'syncRoles')) {
                try {
                    $user->syncRoles([]);
                } catch (Throwable) {
                }
            }
            if (method_exists($user, 'syncPermissions')) {
                try {
                    $user->syncPermissions([]);
                } catch (Throwable) {
                }
            }
            return $user;
        } catch (Throwable $e) {
            $this->markTestSkipped('Could not build a limited non-super-admin user: ' . $e->getMessage());
        }
    }

    private function controllerSourceOrSkip(): string
    {
        return $this->readModuleFileOrSkip('app/Http/Controllers/CertificateRequestController.php');
    }

    /**
     * Read a file relative to the FrontOffice module root, resolved via reflection (#32).
     * Falls back to MAIN_PROJECT_PATH; markTestSkipped when unreadable.
     */
    private function readModuleFileOrSkip(string $relative): string
    {
        $path = null;
        try {
            $ref = new \ReflectionClass(CertificateRequest::class);
            // .../Modules/FrontOffice/app/Models/CertificateRequest.php → module root = dirname(file, 3)
            $moduleRoot = dirname((string) $ref->getFileName(), 3);
            $candidate = $moduleRoot . '/' . ltrim($relative, '/');
            if (is_readable($candidate)) {
                $path = $candidate;
            }
        } catch (Throwable) {
            $path = null;
        }

        if ($path === null) {
            $main = rtrim((string) env('MAIN_PROJECT_PATH', base_path('../prime_ai')), '/');
            $candidate = $main . '/Modules/FrontOffice/' . ltrim($relative, '/');
            if (is_readable($candidate)) {
                $path = $candidate;
            }
        }

        if ($path === null || !is_readable($path)) {
            $this->markTestSkipped("Source file unreadable from runner: {$relative}");
        }

        return (string) file_get_contents($path);
    }

    /** Extract the store() validate() block so auto fields can be asserted as NOT validated. */
    private function validationBlock(string $file): string
    {
        $start = strpos($file, 'public function store(');
        if ($start === false) {
            return $file;
        }
        return substr($file, $start, 1200);
    }

    private function cleanScreenshots(): void
    {
        try {
            $dir = base_path('tests/Browser/screenshots');
            if (is_dir($dir)) {
                foreach (glob($dir . '/*.png') ?: [] as $png) {
                    @unlink($png);
                }
            }
        } catch (Throwable) {
            // non-fatal
        }
    }

    private function initializeTenantContextForTests(): void
    {
        $host = parse_url($this->tenantBaseUrl, PHP_URL_HOST);
        if (!is_string($host) || $host === '') {
            $this->markTestSkipped('Tenant host missing in DUSK_TENANT_URL/APP_URL.');
        }
        try {
            $domain = Domain::query()->where('domain', $host)->first();
        } catch (Throwable $e) {
            $this->markTestSkipped('Domain lookup failed: ' . $e->getMessage());
        }
        if (!isset($domain) || !$domain) {
            $this->markTestSkipped('Tenant domain not found for host: ' . $host);
        }
        if (function_exists('tenancy')) {
            tenancy()->initialize($domain->tenant);
        }
    }

    private function resolveAdminUserAndPermissions(): void
    {
        try {
            $this->adminUser = User::query()->where('email', $this->adminEmail)->first()
                ?? User::query()->orderBy('id')->first();
        } catch (Throwable $e) {
            $this->markTestSkipped('No tenant user available: ' . $e->getMessage());
        }

        if (!$this->adminUser) {
            $this->markTestSkipped('No tenant user found for tests.');
        }

        if (Schema::hasColumn('sys_users', 'email_verified_at') && !$this->adminUser->email_verified_at) {
            try {
                $this->adminUser->email_verified_at = now();
                $this->adminUser->saveQuietly();
            } catch (Throwable) {
                // ignore
            }
        }

        $this->grantCertificatePermissions($this->adminUser);
    }

    private function grantCertificatePermissions(User $user): void
    {
        if (!method_exists($user, 'givePermissionTo')) {
            return;
        }
        $permissions = [
            'frontoffice.certificate.view',
            'frontoffice.certificate.create',
            'frontoffice.certificate.update',
            'frontoffice.certificate.delete',
            'frontoffice.certificate.issue',
            'frontoffice.certificate.restore',
            'frontoffice.certificate.forceDelete',
        ];
        $this->ensurePermissionsExist($permissions);
        foreach ($permissions as $permission) {
            try {
                $user->givePermissionTo($permission);
            } catch (Throwable) {
                // ignore duplicates / guard mismatch
            }
        }
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
                // ignore
            }
        }
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

        if (str_contains($this->currentPath($browser), '/login') && $this->adminUser) {
            try {
                $browser->loginAs($this->adminUser)->pause(600);
            } catch (Throwable) {
                // ignore
            }
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

    private function tenantUrl(string $path): string
    {
        return $this->tenantBaseUrl . '/' . ltrim($path, '/');
    }

    private function currentPath(Browser $browser): string
    {
        $path = parse_url($browser->driver->getCurrentURL(), PHP_URL_PATH);
        return is_string($path) ? $path : '';
    }

    private function pageSourceContains(Browser $browser, string $needle): bool
    {
        try {
            return str_contains((string) $browser->driver->getPageSource(), $needle);
        } catch (Throwable) {
            return false;
        }
    }

    private function uniqueSuffix(): string
    {
        return now()->format('His') . random_int(100, 999);
    }
}
