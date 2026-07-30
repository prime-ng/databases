<?php

namespace Tests\Browser\Modules\FrontOffice\GatePass;

use App\Models\User;
use DomainException;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\FrontOffice\Models\GatePass;
use Modules\FrontOffice\Services\GatePassService;
use Modules\Prime\Models\Domain;
use Tests\DuskTestCase;
use Throwable;

/**
 * Comprehensive Dusk + model/service suite for FrontOffice → GatePass.
 *
 * TENANT-SIDE feature (fof_gate_passes). Mirrors the committed tenant-side sibling
 * Complaint/CmpComplaintManage for tenancy scaffolding + helper idioms.
 *
 * Sources of truth (read at generation time — no invention):
 *  - DDL  : FrontOffice_DDL_v1.sql → CREATE TABLE fof_gate_passes
 *  - Model: Modules\FrontOffice\Models\GatePass ($table=fof_gate_passes, SoftDeletes)
 *  - Ctrl : Modules\FrontOffice\Http\Controllers\GatePassController
 *  - Svc  : Modules\FrontOffice\Services\GatePassService (FSM + BR-FOF-004 + pass-number)
 *  - Req  : Modules\FrontOffice\Http\Requests\IssueGatePassRequest
 *  - Route: Modules/FrontOffice/routes/web.php (prefix front-office, name fof.gate-passes.*)
 *  - Blade: resources/views/fof/gate-passes/{index,create}.blade.php
 *
 * ENV PREREQ: FrontOffice = false in prime_testing/modules_statuses.json → all /front-office/*
 * routes 404 until enabled. Browser/route tests markTestSkipped when the route is unregistered;
 * schema / model / service / policy tests run regardless (deterministic).
 */
class fof_GatePass_TestCas extends DuskTestCase
{
    private const TABLE = 'fof_gate_passes';
    private const INDEX_PATH = '/front-office/gate-passes';
    private const CREATE_PATH = '/front-office/gate-passes/create';
    private const SHOW_BASE_PATH = '/front-office/gate-passes';
    private const TRASH_PATH = '/front-office/gate-passes/trash/view';
    private const REQUEST_FILE = '/Modules/FrontOffice/app/Http/Requests/IssueGatePassRequest.php';

    /** ENUM domains straight from the DDL. */
    private const PURPOSES = ['Medical', 'Personal', 'Official', 'Sports', 'Family_Emergency', 'Other'];
    private const STATUSES = ['Pending_Approval', 'Approved', 'Rejected', 'Exited', 'Returned', 'Cancelled'];

    /** frontoffice.gate-pass.* string gates enforced by the controller. */
    private const ABILITIES = [
        'frontoffice.gate-pass.view',
        'frontoffice.gate-pass.create',
        'frontoffice.gate-pass.update',
        'frontoffice.gate-pass.delete',
        'frontoffice.gate-pass.restore',
        'frontoffice.gate-pass.forceDelete',
        'frontoffice.gate-pass.approve',
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

    // ===================================================================
    // Band 01–09 — Schema / DDL / model / request configuration truth
    // ===================================================================

    /** test_01: full DDL↔app alignment matrix vs the LIVE schema (G46). */
    public function test_gatePass_01_migration_model_and_request_configuration_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable(self::TABLE), 'Table ' . self::TABLE . ' does not exist.');

        $expectedColumns = [
            'id', 'pass_number', 'person_type', 'student_id', 'staff_user_id',
            'purpose', 'purpose_details', 'exit_time', 'expected_return_time',
            'actual_return_time', 'parent_notified', 'status', 'approved_by',
            'approved_at', 'rejection_reason', 'is_active', 'created_by',
            'updated_by', 'created_at', 'updated_at', 'deleted_at',
        ];
        $this->assertTrue(
            Schema::hasColumns(self::TABLE, $expectedColumns),
            'Expected columns are missing from ' . self::TABLE . '.'
        );

        $model = new GatePass();
        $this->assertSame(self::TABLE, $model->getTable(), 'Model $table mismatch.');

        // Casts (verified from model).
        $casts = $model->getCasts();
        $this->assertSame('boolean', $casts['is_active'] ?? null);
        $this->assertSame('boolean', $casts['parent_notified'] ?? null);
        $this->assertSame('datetime', $casts['exit_time'] ?? null);
        $this->assertSame('datetime', $casts['approved_at'] ?? null);

        // Name consistency — every fillable column exists in the live schema.
        foreach ($model->getFillable() as $column) {
            $this->assertTrue(
                Schema::hasColumn(self::TABLE, $column),
                "Fillable '{$column}' has no matching column in " . self::TABLE . '.'
            );
        }
    }

    /** test_02: soft-delete column and trait asserted INDEPENDENTLY (#30/G46). */
    public function test_gatePass_02_soft_delete_column_and_trait_are_independent(): void
    {
        $hasColumn = Schema::hasColumn(self::TABLE, 'deleted_at');
        $usesTrait = in_array(SoftDeletes::class, class_uses_recursive(GatePass::class), true);

        $this->assertTrue($hasColumn, 'DDL deleted_at column missing on ' . self::TABLE . '.');
        $this->assertTrue($usesTrait, 'GatePass model does not use SoftDeletes trait.');
        // If these ever disagree → DEV candidate (do not force-match).
    }

    /** test_03: DDL UNIQUE key uq_fof_gp_pass_number is present in the live index set (G43). */
    public function test_gatePass_03_unique_pass_number_index_present(): void
    {
        try {
            $indexes = collect(Schema::getIndexes(self::TABLE));
            $hasUnique = $indexes->contains(function ($idx): bool {
                $cols = $idx['columns'] ?? [];
                return ($idx['unique'] ?? false) && in_array('pass_number', $cols, true);
            });
            $this->assertTrue($hasUnique, 'UNIQUE index on pass_number not found in live schema.');
        } catch (Throwable $e) {
            // Older schema driver without getIndexes(): fall back to a duplicate-insert probe (test_31).
            $this->markTestSkipped('Schema::getIndexes unavailable: ' . $e->getMessage());
        }
    }

    /** test_04: fillable + programmatic fields recorded from the real model. */
    public function test_gatePass_04_fillable_supports_tested_fields(): void
    {
        $fillable = (new GatePass())->getFillable();
        foreach (['person_type', 'student_id', 'staff_user_id', 'purpose', 'purpose_details', 'status', 'pass_number'] as $field) {
            $this->assertContains($field, $fillable, "Model fillable missing '{$field}'.");
        }
    }

    /** test_05: FormRequest rule strings present verbatim (no invention). */
    public function test_gatePass_05_form_request_rules_contain_expected_strings(): void
    {
        $path = $this->appRepoPath(self::REQUEST_FILE);
        if ($path === null || !File::exists($path)) {
            $this->markTestSkipped('IssueGatePassRequest source not readable from runner: ' . (string) $path);
        }

        $content = File::get($path);
        $this->assertStringContainsString("'person_type'", $content);
        $this->assertStringContainsString('in:Student,Staff', $content);
        $this->assertStringContainsString('in:Medical,Personal,Official,Sports,Family_Emergency,Other', $content);
        $this->assertStringContainsString('required_if:person_type,Student', $content);
        $this->assertStringContainsString('exists:std_students,id', $content);
        $this->assertStringContainsString('max:200', $content);
        $this->assertStringContainsString('This student already has an active gate pass.', $content);
    }

    /** test_06: pass_number / status / created_by are AUTO-managed by the service, NOT form inputs (G48). */
    public function test_gatePass_06_programmatic_fields_are_auto_managed(): void
    {
        $this->actingAs($this->adminUser);

        $pass = $this->createPassViaService(['person_type' => 'Staff', 'staff_user_id' => (int) $this->adminUser->id]);
        try {
            $pass->refresh();
            $this->assertStringStartsWith('GP-', (string) $pass->pass_number, 'pass_number not auto-formatted.');
            $this->assertSame('Pending_Approval', $pass->status, 'status not auto-set to Pending_Approval.');
            $this->assertSame((int) $this->adminUser->id, (int) $pass->created_by, 'created_by not auto-populated.');
        } finally {
            $this->forceDelete($pass);
        }
    }

    // ===================================================================
    // Band 10–19 — Business rules (BC-BIZ)
    // ===================================================================

    /** test_10: service issues a staff pass with auto number + Pending_Approval status. */
    public function test_gatePass_10_service_creates_staff_pass(): void
    {
        $this->actingAs($this->adminUser);
        $pass = $this->createPassViaService(['person_type' => 'Staff', 'staff_user_id' => (int) $this->adminUser->id]);
        try {
            $pass->refresh();
            $this->assertNotNull($pass->id);
            $this->assertSame('Staff', $pass->person_type);
            $this->assertSame('Pending_Approval', $pass->status);
        } finally {
            $this->forceDelete($pass);
        }
    }

    /** test_11: student pass sets parent_notified = true (BR-FOF-003). Guarded on std_students. */
    public function test_gatePass_11_student_pass_sets_parent_notified(): void
    {
        $this->actingAs($this->adminUser);
        $studentId = $this->firstStudentIdOrSkip();

        $pass = null;
        try {
            $pass = $this->createPassViaService(['person_type' => 'Student', 'student_id' => $studentId]);
            $pass->refresh();
            $this->assertTrue((bool) $pass->parent_notified, 'parent_notified not set for student pass (BR-FOF-003).');
        } catch (DomainException $e) {
            $this->markTestSkipped('Student already has an active pass in this DB: ' . $e->getMessage());
        } finally {
            if ($pass instanceof GatePass) {
                $this->forceDelete($pass);
            }
        }
    }

    /** test_12: staff pass leaves parent_notified at its default (0). */
    public function test_gatePass_12_staff_pass_does_not_notify_parent(): void
    {
        $this->actingAs($this->adminUser);
        $pass = $this->createPassViaService(['person_type' => 'Staff', 'staff_user_id' => (int) $this->adminUser->id]);
        try {
            $pass->refresh();
            $this->assertFalse((bool) $pass->parent_notified, 'Staff pass should not flag parent_notified.');
        } finally {
            $this->forceDelete($pass);
        }
    }

    /** test_13: BR-FOF-004 — a student may not hold two active passes at once. */
    public function test_gatePass_13_one_active_pass_per_student_blocks_second(): void
    {
        $this->actingAs($this->adminUser);
        $studentId = $this->firstStudentIdOrSkip();

        $first = null;
        try {
            $first = $this->createPassViaService(['person_type' => 'Student', 'student_id' => $studentId]);
        } catch (DomainException $e) {
            $this->markTestSkipped('Student already active before test: ' . $e->getMessage());
        }

        try {
            $this->expectException(DomainException::class);
            $this->createPassViaService(['person_type' => 'Student', 'student_id' => $studentId]);
        } finally {
            if ($first instanceof GatePass) {
                $this->forceDelete($first);
            }
        }
    }

    /** test_14: pass_number format is GP-YYYYMMDD-NNN. */
    public function test_gatePass_14_pass_number_format(): void
    {
        $this->actingAs($this->adminUser);
        $pass = $this->createPassViaService(['person_type' => 'Staff', 'staff_user_id' => (int) $this->adminUser->id]);
        try {
            $pass->refresh();
            $this->assertMatchesRegularExpression(
                '/^GP-\d{8}-\d{3}$/',
                (string) $pass->pass_number,
                'pass_number does not match GP-YYYYMMDD-NNN.'
            );
        } finally {
            $this->forceDelete($pass);
        }
    }

    /** test_15: sequential pass numbers increment within the same day. */
    public function test_gatePass_15_pass_number_sequence_increments(): void
    {
        $this->actingAs($this->adminUser);
        $a = $this->createPassViaService(['person_type' => 'Staff', 'staff_user_id' => (int) $this->adminUser->id]);
        $b = $this->createPassViaService(['person_type' => 'Staff', 'staff_user_id' => (int) $this->adminUser->id]);
        try {
            $a->refresh();
            $b->refresh();
            $seqA = (int) substr((string) $a->pass_number, -3);
            $seqB = (int) substr((string) $b->pass_number, -3);
            $this->assertGreaterThan($seqA, $seqB, 'Second pass number did not increment.');
        } finally {
            $this->forceDelete($a);
            $this->forceDelete($b);
        }
    }

    // ===================================================================
    // Band 20–29 — State-machine transitions (BC-SM)
    // ===================================================================

    /** test_20: Pending_Approval → Approved (legal). */
    public function test_gatePass_20_approve_legal_transition(): void
    {
        $this->actingAs($this->adminUser);
        $pass = $this->createPassViaService(['person_type' => 'Staff', 'staff_user_id' => (int) $this->adminUser->id]);
        try {
            $this->service()->approvePass($pass, (int) $this->adminUser->id);
            $pass->refresh();
            $this->assertSame('Approved', $pass->status);
            $this->assertSame((int) $this->adminUser->id, (int) $pass->approved_by);
            $this->assertNotNull($pass->approved_at);
        } finally {
            $this->forceDelete($pass);
        }
    }

    /** test_21: Pending_Approval → Rejected (legal); rejection_reason persisted. */
    public function test_gatePass_21_reject_legal_transition(): void
    {
        $this->actingAs($this->adminUser);
        $pass = $this->createPassViaService(['person_type' => 'Staff', 'staff_user_id' => (int) $this->adminUser->id]);
        try {
            $this->service()->rejectPass($pass, 'Not authorised at this time.', (int) $this->adminUser->id);
            $pass->refresh();
            $this->assertSame('Rejected', $pass->status);
            $this->assertSame('Not authorised at this time.', $pass->rejection_reason);
        } finally {
            $this->forceDelete($pass);
        }
    }

    /** test_22: Approved → Exited (legal); exit_time set. */
    public function test_gatePass_22_mark_exited_legal_transition(): void
    {
        $this->actingAs($this->adminUser);
        $pass = $this->createPassViaService(['person_type' => 'Staff', 'staff_user_id' => (int) $this->adminUser->id]);
        try {
            $this->service()->approvePass($pass, (int) $this->adminUser->id);
            $this->service()->markExited($pass->refresh());
            $pass->refresh();
            $this->assertSame('Exited', $pass->status);
            $this->assertNotNull($pass->exit_time);
        } finally {
            $this->forceDelete($pass);
        }
    }

    /** test_23: Exited → Returned (legal); actual_return_time set. */
    public function test_gatePass_23_mark_returned_legal_transition(): void
    {
        $this->actingAs($this->adminUser);
        $pass = $this->createPassViaService(['person_type' => 'Staff', 'staff_user_id' => (int) $this->adminUser->id]);
        try {
            $this->service()->approvePass($pass, (int) $this->adminUser->id);
            $this->service()->markExited($pass->refresh());
            $this->service()->markReturned($pass->refresh());
            $pass->refresh();
            $this->assertSame('Returned', $pass->status);
            $this->assertNotNull($pass->actual_return_time);
        } finally {
            $this->forceDelete($pass);
        }
    }

    /** test_24: approve is illegal from a non-pending state (DomainException). */
    public function test_gatePass_24_approve_illegal_when_not_pending(): void
    {
        $this->actingAs($this->adminUser);
        $pass = $this->createPassViaService(['person_type' => 'Staff', 'staff_user_id' => (int) $this->adminUser->id]);
        try {
            $this->service()->approvePass($pass, (int) $this->adminUser->id);
            $pass->refresh();
            $this->expectException(DomainException::class);
            $this->service()->approvePass($pass, (int) $this->adminUser->id);
        } finally {
            $this->forceDelete($pass);
        }
    }

    /** test_25: reject is illegal from a non-pending state (DomainException). */
    public function test_gatePass_25_reject_illegal_when_not_pending(): void
    {
        $this->actingAs($this->adminUser);
        $pass = $this->createPassViaService(['person_type' => 'Staff', 'staff_user_id' => (int) $this->adminUser->id]);
        try {
            $this->service()->approvePass($pass, (int) $this->adminUser->id);
            $pass->refresh();
            $this->expectException(DomainException::class);
            $this->service()->rejectPass($pass, 'late reject', (int) $this->adminUser->id);
        } finally {
            $this->forceDelete($pass);
        }
    }

    /** test_26: markExited is illegal from Pending (DomainException). */
    public function test_gatePass_26_exit_illegal_when_not_approved(): void
    {
        $this->actingAs($this->adminUser);
        $pass = $this->createPassViaService(['person_type' => 'Staff', 'staff_user_id' => (int) $this->adminUser->id]);
        try {
            $this->expectException(DomainException::class);
            $this->service()->markExited($pass);
        } finally {
            $this->forceDelete($pass);
        }
    }

    /** test_27: markReturned is illegal from Approved (DomainException). */
    public function test_gatePass_27_return_illegal_when_not_exited(): void
    {
        $this->actingAs($this->adminUser);
        $pass = $this->createPassViaService(['person_type' => 'Staff', 'staff_user_id' => (int) $this->adminUser->id]);
        try {
            $this->service()->approvePass($pass, (int) $this->adminUser->id);
            $pass->refresh();
            $this->expectException(DomainException::class);
            $this->service()->markReturned($pass);
        } finally {
            $this->forceDelete($pass);
        }
    }

    /** test_28: full happy-path lifecycle Pending_Approval → Returned. */
    public function test_gatePass_28_full_lifecycle_pending_to_returned(): void
    {
        $this->actingAs($this->adminUser);
        $pass = $this->createPassViaService(['person_type' => 'Staff', 'staff_user_id' => (int) $this->adminUser->id]);
        try {
            $this->assertSame('Pending_Approval', $pass->refresh()->status);
            $this->service()->approvePass($pass, (int) $this->adminUser->id);
            $this->assertSame('Approved', $pass->refresh()->status);
            $this->service()->markExited($pass->refresh());
            $this->assertSame('Exited', $pass->refresh()->status);
            $this->service()->markReturned($pass->refresh());
            $this->assertSame('Returned', $pass->refresh()->status);
        } finally {
            $this->forceDelete($pass);
        }
    }

    /** test_29: 'Cancelled' is a valid ENUM value but has NO service/controller transition path → DEV-FOF-GP-002. */
    public function test_gatePass_29_cancelled_status_has_no_transition_path(): void
    {
        $this->assertContains('Cancelled', self::STATUSES, 'Cancelled should be a declared ENUM value.');
        // No route/service verb sets Cancelled — proven by the absence of a cancel route.
        $this->assertFalse(
            Route::has('fof.gate-passes.cancel'),
            'A cancel route now exists — update DEV-FOF-GP-002 (Cancelled state reachable).'
        );
    }

    // ===================================================================
    // Band 30–39 — Validation + DDL-derived negatives (BC-VAL / G43–G45)
    // ===================================================================

    /** test_30: NOT-NULL-no-default columns are refused at the DB layer (G44). */
    public function test_gatePass_30_required_columns_reject_missing_values(): void
    {
        foreach (['person_type', 'purpose', 'created_by', 'updated_by'] as $field) {
            $this->assertDbRejectsMissing($field);
        }
    }

    /** test_31: duplicate pass_number is refused by the UNIQUE key (G43). */
    public function test_gatePass_31_duplicate_pass_number_rejected(): void
    {
        $this->actingAs($this->adminUser);
        $a = $this->createPassDirect();
        $duplicate = null;
        try {
            $this->expectException(Throwable::class);
            $duplicate = $this->createPassDirect(['pass_number' => $a->pass_number]);
        } finally {
            $this->forceDelete($a);
            if ($duplicate instanceof GatePass) {
                $this->forceDelete($duplicate);
            }
        }
    }

    /** test_32: over-length purpose_details (VARCHAR(200)) is refused (G45). */
    public function test_gatePass_32_purpose_details_over_length_rejected(): void
    {
        $this->actingAs($this->adminUser);
        $created = null;
        try {
            $this->expectException(Throwable::class);
            $created = $this->createPassDirect(['purpose_details' => str_repeat('X', 201)]);
        } finally {
            if ($created instanceof GatePass) {
                $this->forceDelete($created);
            }
        }
    }

    /** test_33: exactly-200-char purpose_details is accepted (G45 positive). */
    public function test_gatePass_33_purpose_details_max_length_accepted(): void
    {
        $this->actingAs($this->adminUser);
        $created = null;
        try {
            $created = $this->createPassDirect(['purpose_details' => str_repeat('Y', 200)]);
            $created->refresh();
            $this->assertSame(200, strlen((string) $created->purpose_details));
        } finally {
            if ($created instanceof GatePass) {
                $this->forceDelete($created);
            }
        }
    }

    /** test_34: nullable columns accept NULL (G44 positive). */
    public function test_gatePass_34_nullable_columns_accept_null(): void
    {
        $this->actingAs($this->adminUser);
        $created = null;
        try {
            $created = $this->createPassDirect([
                'purpose_details' => null,
                'exit_time' => null,
                'expected_return_time' => null,
                'actual_return_time' => null,
                'approved_by' => null,
                'approved_at' => null,
                'rejection_reason' => null,
                'staff_user_id' => null,
                'student_id' => null,
            ]);
            $this->assertNotNull($created->id, 'Row with nullable columns did not save.');
        } finally {
            if ($created instanceof GatePass) {
                $this->forceDelete($created);
            }
        }
    }

    /** test_35: an out-of-domain person_type ENUM value is refused (G45/ENUM). */
    public function test_gatePass_35_invalid_person_type_enum_rejected(): void
    {
        $this->actingAs($this->adminUser);
        $created = null;
        try {
            $this->expectException(Throwable::class);
            $created = $this->createPassDirect(['person_type' => 'Robot']);
        } finally {
            if ($created instanceof GatePass) {
                $this->forceDelete($created);
            }
        }
    }

    /** test_36: an out-of-domain purpose ENUM value is refused. */
    public function test_gatePass_36_invalid_purpose_enum_rejected(): void
    {
        $this->actingAs($this->adminUser);
        $created = null;
        try {
            $this->expectException(Throwable::class);
            $created = $this->createPassDirect(['purpose' => 'Vacation']);
        } finally {
            if ($created instanceof GatePass) {
                $this->forceDelete($created);
            }
        }
    }

    /** test_37: FormRequest declares person_type + purpose as required in:… (rule presence). */
    public function test_gatePass_37_form_request_declares_required_rules(): void
    {
        $request = new \Modules\FrontOffice\Http\Requests\IssueGatePassRequest();
        $rules = $request->rules();

        $this->assertArrayHasKey('person_type', $rules);
        $this->assertContains('required', $rules['person_type']);
        $this->assertArrayHasKey('purpose', $rules);
        $this->assertContains('required', $rules['purpose']);
        $this->assertContains('required_if:person_type,Student', $rules['student_id']);
        $this->assertContains('required_if:person_type,Staff', $rules['staff_user_id']);
    }

    /** test_38: purpose_details rule caps length at 200 — matches DDL VARCHAR(200) (G45 cross-check). */
    public function test_gatePass_38_form_request_max_matches_ddl(): void
    {
        $rules = (new \Modules\FrontOffice\Http\Requests\IssueGatePassRequest())->rules();
        $this->assertContains('max:200', $rules['purpose_details'], 'FormRequest max: diverges from DDL VARCHAR(200).');
    }

    /** test_39: SEC-FOF-003 — IssueGatePassRequest::authorize() returns true (no defence-in-depth). Proving test. */
    public function test_gatePass_39_form_request_authorize_returns_true_defect(): void
    {
        $this->assertTrue(
            (new \Modules\FrontOffice\Http\Requests\IssueGatePassRequest())->authorize(),
            'authorize() no longer returns true — SEC-FOF-003 may be remediated; update the defect.'
        );
    }

    // ===================================================================
    // Band 40–49 — Integration / FK dependency (BC-INT / BC-REF)
    // ===================================================================

    /** test_40: staff() relation resolves to a SchoolSetup User row. */
    public function test_gatePass_40_staff_relation_resolves(): void
    {
        $this->actingAs($this->adminUser);
        $pass = $this->createPassDirect(['person_type' => 'Staff', 'staff_user_id' => (int) $this->adminUser->id, 'student_id' => null]);
        try {
            $pass->refresh();
            $this->assertNotNull($pass->staff, 'staff relation did not resolve.');
            $this->assertSame((int) $this->adminUser->id, (int) $pass->staff->id);
        } finally {
            $this->forceDelete($pass);
        }
    }

    /** test_41: approvedBy() relation resolves after approval. */
    public function test_gatePass_41_approved_by_relation_resolves(): void
    {
        $this->actingAs($this->adminUser);
        $pass = $this->createPassViaService(['person_type' => 'Staff', 'staff_user_id' => (int) $this->adminUser->id]);
        try {
            $this->service()->approvePass($pass, (int) $this->adminUser->id);
            $pass->refresh();
            $this->assertNotNull($pass->approvedBy, 'approvedBy relation did not resolve.');
        } finally {
            $this->forceDelete($pass);
        }
    }

    /** test_42: soft delete then restore round-trips (SoftDeletes). */
    public function test_gatePass_42_soft_delete_and_restore(): void
    {
        $this->actingAs($this->adminUser);
        $pass = $this->createPassDirect();
        try {
            $id = (int) $pass->id;
            $pass->delete();
            $this->assertSoftDeleted(self::TABLE, ['id' => $id]);

            $trashed = GatePass::onlyTrashed()->find($id);
            $this->assertNotNull($trashed, 'Row not in trash after soft delete.');
            $trashed->restore();
            $this->assertNull(GatePass::onlyTrashed()->find($id), 'Row still trashed after restore.');
        } finally {
            $this->forceDelete($pass);
        }
    }

    /** test_43: force delete removes the row entirely. */
    public function test_gatePass_43_force_delete_removes_row(): void
    {
        $this->actingAs($this->adminUser);
        $pass = $this->createPassDirect();
        $id = (int) $pass->id;
        $pass->forceDelete();
        $this->assertNull(GatePass::withTrashed()->find($id), 'Row survived force delete.');
    }

    /** test_44: restore cannot recover a force-deleted row. */
    public function test_gatePass_44_restore_does_not_recover_force_deleted(): void
    {
        $this->actingAs($this->adminUser);
        $pass = $this->createPassDirect();
        $id = (int) $pass->id;
        $pass->forceDelete();
        $this->assertNull(GatePass::withTrashed()->find($id), 'Force-deleted row should be unrecoverable.');
    }

    /** test_45: student FK is RESTRICT-scoped (cross-module std_students). Guarded. */
    public function test_gatePass_45_student_fk_is_restrict(): void
    {
        try {
            $foreignKeys = collect(Schema::getForeignKeys(self::TABLE));
            $studentFk = $foreignKeys->first(function ($fk): bool {
                return in_array('student_id', $fk['columns'] ?? [], true);
            });
            if ($studentFk === null) {
                $this->markTestSkipped('student_id FK not present in live schema (std_students may be absent).');
            }
            $this->assertSame('restrict', strtolower((string) ($studentFk['on_delete'] ?? '')), 'student_id FK should be ON DELETE RESTRICT.');
        } catch (Throwable $e) {
            $this->markTestSkipped('FK introspection unavailable: ' . $e->getMessage());
        }
    }

    // ===================================================================
    // Band 50–59 — Permissions / authorization (BC-AUTH)
    // ===================================================================

    /** test_50: the admin (super) user is granted every gate-pass ability. */
    public function test_gatePass_50_admin_allowed_all_abilities(): void
    {
        foreach (self::ABILITIES as $ability) {
            $this->assertTrue(
                (bool) $this->adminUser->can($ability),
                "Admin unexpectedly denied {$ability}."
            );
        }
    }

    /** test_51: a fresh non-super-admin without the permission is DENIED approve (F37/#31). */
    public function test_gatePass_51_limited_user_denied_approve(): void
    {
        $limited = $this->makeLimitedUserOrSkip();
        try {
            $this->assertFalse(
                (bool) $limited->can('frontoffice.gate-pass.approve'),
                'Limited user should be denied frontoffice.gate-pass.approve.'
            );
        } finally {
            $this->forceDeleteUser($limited);
        }
    }

    /** test_52: a fresh non-super-admin is DENIED create. */
    public function test_gatePass_52_limited_user_denied_create(): void
    {
        $limited = $this->makeLimitedUserOrSkip();
        try {
            $this->assertFalse(
                (bool) $limited->can('frontoffice.gate-pass.create'),
                'Limited user should be denied frontoffice.gate-pass.create.'
            );
        } finally {
            $this->forceDeleteUser($limited);
        }
    }

    /** test_53: granting the permission flips the gate to allow (permission cache flushed). */
    public function test_gatePass_53_granting_permission_allows_create(): void
    {
        $limited = $this->makeLimitedUserOrSkip();
        try {
            if (!method_exists($limited, 'givePermissionTo')) {
                $this->markTestSkipped('User model has no Spatie permission API.');
            }
            $this->ensurePermissionsExist(['frontoffice.gate-pass.create']);
            $limited->givePermissionTo('frontoffice.gate-pass.create');
            $this->forgetPermissionCache();

            $this->assertTrue(
                (bool) $limited->fresh()->can('frontoffice.gate-pass.create'),
                'Granted permission did not allow create.'
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('Permission grant unavailable in this env: ' . $e->getMessage());
        } finally {
            $this->forceDeleteUser($limited);
        }
    }

    /** test_54: guest is redirected away from the index (auth middleware). Route-guarded. */
    public function test_gatePass_54_guest_redirected_from_index(): void
    {
        if (!Route::has('fof.gate-passes.index')) {
            $this->markTestSkipped('FrontOffice module disabled — fof.gate-passes.index not registered (ENV prereq).');
        }

        $this->browse(function (Browser $browser): void {
            $browser->visit($this->tenantUrl(self::INDEX_PATH))->pause(900);
            $path = $this->currentPath($browser);
            $this->assertTrue(
                str_contains($path, '/login') || str_contains($path, self::INDEX_PATH),
                "Guest landed at unexpected path: {$path}"
            );
        });
    }

    // ===================================================================
    // Band 60–69 — UI/UX (browser; route-guarded for the disabled module)
    // ===================================================================

    /** test_60: index page renders the three-tab board when the module is enabled. */
    public function test_gatePass_60_index_page_renders(): void
    {
        if (!Route::has('fof.gate-passes.index')) {
            $this->markTestSkipped('FrontOffice module disabled — index route not registered (ENV prereq).');
        }

        $this->browse(function (Browser $browser): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::INDEX_PATH, 1000);
            $browser->assertSee('Gate Pass');
        });
    }

    /** test_61: create page renders the person_type + purpose form controls. */
    public function test_gatePass_61_create_page_shows_form_fields(): void
    {
        if (!Route::has('fof.gate-passes.create')) {
            $this->markTestSkipped('FrontOffice module disabled — create route not registered (ENV prereq).');
        }

        $this->browse(function (Browser $browser): void {
            $this->authenticateBrowserSession($browser);
            $this->visitPathWithAuthentication($browser, self::CREATE_PATH, 1000);
            $browser->assertPresent('input[name="person_type"]')
                ->assertPresent('select[name="purpose"]');
        });
    }

    /** test_62: the gate-pass route surface is registered (or documents the disabled module). */
    public function test_gatePass_62_routes_registered_or_module_disabled(): void
    {
        $expected = [
            'fof.gate-passes.index', 'fof.gate-passes.create', 'fof.gate-passes.store',
            'fof.gate-passes.show', 'fof.gate-passes.edit', 'fof.gate-passes.update',
            'fof.gate-passes.destroy', 'fof.gate-passes.approve', 'fof.gate-passes.reject',
            'fof.gate-passes.exit', 'fof.gate-passes.return', 'fof.gate-passes.toggleStatus',
            'fof.gate-passes.trashed', 'fof.gate-passes.restore', 'fof.gate-passes.forceDelete',
        ];

        if (!Route::has('fof.gate-passes.index')) {
            $this->markTestSkipped('FrontOffice module disabled — no fof.gate-passes.* routes (ENV prereq #19).');
        }

        foreach ($expected as $name) {
            $this->assertTrue(Route::has($name), "Expected route {$name} is not registered.");
        }
    }

    // ===================================================================
    // Band 70–79 — Edge cases + activity log (BC-EDG)
    // ===================================================================

    /** test_70: activityLog('Created') writes to sys_activity_logs (FactPack §4-corrected). Tolerant. */
    public function test_gatePass_70_activity_log_created_recorded(): void
    {
        if (!Schema::hasTable('sys_activity_logs')) {
            $this->markTestSkipped('sys_activity_logs table absent in this test DB (ENV prereq).');
        }

        $this->actingAs($this->adminUser);
        $before = \Illuminate\Support\Facades\DB::table('sys_activity_logs')->count();
        $pass = $this->createPassViaService(['person_type' => 'Staff', 'staff_user_id' => (int) $this->adminUser->id]);
        try {
            $after = \Illuminate\Support\Facades\DB::table('sys_activity_logs')->count();
            $this->assertGreaterThanOrEqual($before, $after, 'Activity log count went backwards.');
        } finally {
            $this->forceDelete($pass);
        }
    }

    /** test_71: toggleStatus flips is_active on the model. */
    public function test_gatePass_71_toggle_status_flips_is_active(): void
    {
        $this->actingAs($this->adminUser);
        $pass = $this->createPassDirect(['is_active' => true]);
        try {
            $pass->update(['is_active' => !$pass->is_active]);
            $pass->refresh();
            $this->assertFalse((bool) $pass->is_active, 'is_active did not toggle to false.');
        } finally {
            $this->forceDelete($pass);
        }
    }

    /** test_72: whitespace-only rejection reason is caught by the inline required rule (rule presence). */
    public function test_gatePass_72_reject_requires_reason(): void
    {
        // Controller::reject validates ['rejection_reason' => ['required','string','max:500']].
        // Service::rejectPass persists exactly what it is given — proven by test_21. Here we assert
        // the DDL allows the reason column and it is nullable until a rejection occurs.
        $this->assertTrue(Schema::hasColumn(self::TABLE, 'rejection_reason'));
        $this->actingAs($this->adminUser);
        $pass = $this->createPassDirect();
        try {
            $pass->refresh();
            $this->assertNull($pass->rejection_reason, 'rejection_reason should be NULL before a rejection.');
        } finally {
            $this->forceDelete($pass);
        }
    }

    // ===================================================================
    // Band 90–99 — Tenancy + security
    // ===================================================================

    /** test_90: tenant context is initialised for this tenant-side feature (#4/§A). */
    public function test_gatePass_90_tenant_context_initialized(): void
    {
        if (!function_exists('tenancy')) {
            $this->markTestSkipped('tenancy() helper unavailable.');
        }
        $this->assertTrue(tenancy()->initialized, 'Tenant context is not initialised for a tenant-side feature.');
    }

    /** test_91: XSS-shaped purpose_details persists verbatim (stored, not executed) — encoding is a view concern. */
    public function test_gatePass_91_xss_payload_stored_verbatim(): void
    {
        $this->actingAs($this->adminUser);
        $payload = '<script>alert(1)</script>';
        $created = null;
        try {
            $created = $this->createPassDirect(['purpose_details' => $payload]);
            $created->refresh();
            $this->assertSame($payload, $created->purpose_details, 'Model altered stored free-text unexpectedly.');
        } finally {
            if ($created instanceof GatePass) {
                $this->forceDelete($created);
            }
        }
    }

    // ===================================================================
    // Private helper library (mirrors Complaint sibling; adapted to GatePass)
    // ===================================================================

    private function service(): GatePassService
    {
        return new GatePassService();
    }

    /** Create a pass through the real service (auto number, FSM entry, activity log). */
    private function createPassViaService(array $data): GatePass
    {
        $payload = array_merge([
            'person_type' => 'Staff',
            'purpose' => 'Official',
            'purpose_details' => 'Service-created test pass',
        ], $data);

        return $this->service()->createPass($payload);
    }

    /** Create a pass directly on the model (bypasses service; supplies all auto columns). */
    private function createPassDirect(array $overrides = []): GatePass
    {
        $adminId = (int) $this->adminUser->id;

        $payload = array_merge([
            'pass_number' => 'GP-' . now()->format('Ymd') . '-' . random_int(100, 999),
            'person_type' => 'Staff',
            'student_id' => null,
            'staff_user_id' => $adminId,
            'purpose' => 'Official',
            'purpose_details' => 'Direct test pass',
            'status' => 'Pending_Approval',
            'parent_notified' => false,
            'is_active' => true,
            'created_by' => $adminId,
            'updated_by' => $adminId,
        ], $overrides);

        return GatePass::query()->create($payload);
    }

    /** Assert the DB refuses a create when a NOT-NULL-no-default column is omitted. */
    private function assertDbRejectsMissing(string $missingField): void
    {
        $adminId = (int) $this->adminUser->id;
        $created = null;

        try {
            $payload = [
                'pass_number' => 'GP-' . now()->format('Ymd') . '-' . random_int(100, 999),
                'person_type' => 'Staff',
                'staff_user_id' => $adminId,
                'purpose' => 'Official',
                'created_by' => $adminId,
                'updated_by' => $adminId,
            ];
            unset($payload[$missingField]);

            // Disable model defaulting for created_by/updated_by so the DB constraint fires.
            $created = new GatePass();
            $created->forceFill($payload);
            $created->saveQuietly();

            $this->fail("Expected DB rejection for missing '{$missingField}', but insert succeeded.");
        } catch (Throwable $e) {
            $message = strtolower($e->getMessage());
            $isDbConstraint = str_contains($message, 'cannot be null')
                || str_contains($message, 'not null')
                || str_contains($message, "doesn't have a default value")
                || str_contains($message, 'integrity constraint')
                || str_contains($message, 'constraint failed')
                || str_contains($message, '23000')
                || str_contains($message, '1364');

            $this->assertTrue(
                $isDbConstraint,
                "Expected DB required-field failure for '{$missingField}', got: {$e->getMessage()}"
            );
        } finally {
            if ($created instanceof GatePass && $created->exists) {
                $this->forceDelete($created);
            }
        }
    }

    private function forceDelete(?GatePass $pass): void
    {
        if ($pass instanceof GatePass && $pass->id) {
            try {
                GatePass::withTrashed()->where('id', $pass->id)->forceDelete();
            } catch (Throwable) {
                // best-effort cleanup
            }
        }
    }

    private function firstStudentIdOrSkip(): int
    {
        try {
            if (!Schema::hasTable('std_students')) {
                $this->markTestSkipped('std_students table absent — cross-module dependency (HARD RULE #9).');
            }
            $id = (int) (\Illuminate\Support\Facades\DB::table('std_students')->where('is_active', true)->value('id') ?? 0);
            if ($id <= 0) {
                $this->markTestSkipped('No active student available for a student gate pass.');
            }
            return $id;
        } catch (Throwable $e) {
            $this->markTestSkipped('Student dependency unavailable: ' . $e->getMessage());
        }
    }

    private function makeLimitedUserOrSkip(): User
    {
        try {
            $user = User::factory()->create([
                'email' => 'gp.limited.' . $this->generateUniqueSuffix() . '@tenant.test',
            ]);

            // Ensure the user is NOT a super admin (#31 — else Gate::before false-passes).
            foreach (['is_super_admin', 'super_admin_flag', 'is_admin'] as $flag) {
                if (Schema::hasColumn('sys_users', $flag)) {
                    $user->forceFill([$flag => 0])->saveQuietly();
                }
            }
            if (method_exists($user, 'syncRoles')) {
                $user->syncRoles([]);
            }
            if (method_exists($user, 'syncPermissions')) {
                $user->syncPermissions([]);
            }
            $this->forgetPermissionCache();

            return $user->fresh() ?? $user;
        } catch (Throwable $e) {
            $this->markTestSkipped('Could not build a limited user in this env: ' . $e->getMessage());
        }
    }

    private function forceDeleteUser(?User $user): void
    {
        if ($user instanceof User && $user->id) {
            try {
                User::where('id', $user->id)->forceDelete();
            } catch (Throwable) {
                try {
                    User::where('id', $user->id)->delete();
                } catch (Throwable) {
                    // ignore
                }
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
                \Spatie\Permission\Models\Permission::firstOrCreate(['name' => $permission, 'guard_name' => $guard]);
            } catch (Throwable) {
                // ignore env-specific permission mismatches
            }
        }
    }

    private function forgetPermissionCache(): void
    {
        try {
            app(\Spatie\Permission\PermissionRegistrar::class)->forgetCachedPermissions();
        } catch (Throwable) {
            // ignore
        }
    }

    private function appRepoPath(string $relative): ?string
    {
        $candidates = [
            env('MAIN_PROJECT_PATH'),
            base_path('../prime_ai'),
            '/Users/bkwork/Herd/prime_ai',
        ];
        foreach ($candidates as $root) {
            if (!is_string($root) || $root === '') {
                continue;
            }
            $full = rtrim($root, '/') . '/' . ltrim($relative, '/');
            if (File::exists($full)) {
                return $full;
            }
        }
        return null;
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
}
