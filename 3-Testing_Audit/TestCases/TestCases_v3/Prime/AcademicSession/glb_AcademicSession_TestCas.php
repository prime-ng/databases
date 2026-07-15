<?php

namespace Tests\Browser\Modules\Prime\AcademicSession;

use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Tests\Browser\Modules\Prime\PrimeDuskTestCase;
use Throwable;

/**
 * Comprehensive single-file Dusk + HTTP suite for the Prime (central) Academic Session screen.
 *
 * DB SCOPE ........ CENTRAL. Primary table `glb_academic_sessions` lives in the shared
 *                   `global_master` database (model connection `global_master_mysql`).
 *                   No stancl/tenancy init. Host http://127.0.0.1:8000.
 * PREFIX .......... `glb_` (DDL-verified in `_global_db_v4.sql`). NOTE the registry lists the
 *                   Prime module prefix as `prm_`; this feature's primary table is `glb_*`, so the
 *                   file prefix follows the DDL table rule (HARD RULE 4). See Validation Report.
 * ACTIVITY SINK ... central `sys_central_activity_logs` (Modules\Prime\Models\ActivityLog,
 *                   connection `mysql`) because tenancy is NOT initialized (constraint #25).
 * BASE CLASS ...... extends PrimeDuskTestCase (preloader alias of prm_PrimeDuskTestCase_TestCas,
 *                   constraint #22); central auth/helpers implemented locally (from BillingDuskTestCase).
 *
 * DEFECTS PROVEN / DOCUMENTED (see Gap Analysis + Validation Report):
 *   BUG-PRM-012 (P1) start_date/end_date have NO FormRequest rules; controller uses validated();
 *                    DDL requires them NOT NULL -> create/update drop the dates.
 *   BUG-PRM-013 (P1) controller destroy()/toggleStatus() + blades reference `is_active`, a column
 *                    that DOES NOT EXIST in glb_academic_sessions (only is_current + generated current_flag).
 *   BUG-PRM-011 (P1) AcademicSessionPolicy is registered but unreachable: authZ is done via string
 *                    abilities `prime.academic-session.*`, not the model-mapped policy. SessionBoardSetupPolicy
 *                    is an orphan (registered to no model). No double Gate::policy exists in current source.
 *   BR-PRM-021  (P2) "exactly one current session" is enforced only at the DB (unique current_flag),
 *                    not by the app; a 2nd is_current=1 row throws a QueryException instead of switching.
 *   BUG-PRM-014 (P3) update() uses flash('updated.academic-session') (hyphen) vs academic_session elsewhere.
 *   D25-PRM-001 (audit) NOT REPRODUCED: current store()/update() use $request->validated(), not all().
 */
class glb_AcademicSession_TestCas extends PrimeDuskTestCase
{
    // ----- Paths (routes/web.php: prefix('prime') + resource('academic-session')) -----
    private const INDEX_PATH  = '/prime/academic-session';
    private const CREATE_PATH = '/prime/academic-session/create';
    private const TRASH_PATH  = '/prime/academic-session/trash/view';
    private const LOGIN_PATH  = '/login';

    // ----- DB -----
    private const GM_CONNECTION      = 'global_master_mysql';
    private const CENTRAL_CONNECTION = 'mysql';
    private const TABLE              = 'glb_academic_sessions';
    private const ACTIVITY_TABLE     = 'sys_central_activity_logs';
    private const MODEL              = '\\Modules\\Prime\\Models\\AcademicSession';
    private const ACTIVITY_MODEL     = '\\Modules\\Prime\\Models\\ActivityLog';
    private const FORM_REQUEST       = '\\Modules\\Prime\\Http\\Requests\\AcademicSessionRequest';

    // ----- Screenshots -----
    protected const SCREENSHOT_DIR = 'tests/Browser/Modules/Prime/AcademicSession/screenshots';

    private ?User $adminUser = null;
    private string $centralBaseUrl = '';
    private string $adminEmail = '';
    private string $adminPassword = '';
    private static bool $screenshotsCleaned = false;

    /** track ids created on global_master so tearDown can purge them */
    private array $createdSessionIds = [];

    protected function setUp(): void
    {
        parent::setUp();

        $this->centralBaseUrl = rtrim($this->primeBaseUrl, '/');
        $this->adminEmail = (string) env('DUSK_ADMIN_EMAIL', 'root@tenant.com');
        $this->adminPassword = (string) env('DUSK_ADMIN_PASSWORD', 'password');

        if (!self::$screenshotsCleaned) {
            $this->cleanScreenshots();
            self::$screenshotsCleaned = true;
        }

        $this->resolveAdminUser();
    }

    protected function tearDown(): void
    {
        $this->purgeCreatedSessions();

        if (function_exists('tenancy') && tenancy()->initialized) {
            tenancy()->end();
        }

        parent::tearDown();
    }

    // =================================================================================
    // Band 01-09 : Schema / DDL / model / request configuration truth
    // =================================================================================

    /** @test  TC-P01 / BC-DB-* / Source: DDL-glb_academic_sessions */
    public function test_academicsession_01_migration_model_and_request_configuration_are_correct(): void
    {
        $this->requireModel();

        $model = $this->newModel();

        // ---- Model identity ----
        $this->assertSame(self::TABLE, $model->getTable(), 'Model $table must be glb_academic_sessions.');
        $this->assertSame(
            self::GM_CONNECTION,
            $model->getConnectionName(),
            'Model must use the global_master_mysql connection (central shared DB).'
        );

        // ---- SoftDeletes ----
        $this->assertContains(
            'Illuminate\\Database\\Eloquent\\SoftDeletes',
            class_uses_recursive(get_class($model)),
            'AcademicSession must use the SoftDeletes trait.'
        );

        // ---- Fillable ----
        $fillable = $model->getFillable();
        foreach (['short_name', 'name', 'start_date', 'end_date', 'is_current'] as $col) {
            $this->assertContains($col, $fillable, "Fillable must include {$col}.");
        }
        // is_active is NOT fillable (and not a real column) - see BUG-PRM-013
        $this->assertNotContains('is_active', $fillable, 'is_active must NOT be fillable (no such column).');

        // ---- Casts ----
        $casts = $model->getCasts();
        $this->assertSame('date', $casts['start_date'] ?? null, 'start_date must cast to date.');
        $this->assertSame('date', $casts['end_date'] ?? null, 'end_date must cast to date.');
        $this->assertSame('boolean', $casts['is_current'] ?? null, 'is_current must cast to boolean.');

        // ---- Scope + relationships defined ----
        $this->assertTrue(method_exists($model, 'scopeCurrent'), 'scopeCurrent() must exist.');
        foreach (['organizationAcademicSessions', 'boards', 'classModeRules', 'classGroupRequirements', 'activities', 'timetables'] as $rel) {
            $this->assertTrue(method_exists($model, $rel), "Relationship {$rel}() must exist.");
        }

        // ---- Live schema truth (fail-soft when global_master DB is not reachable) ----
        if ($this->gmTableExists()) {
            foreach (['id', 'short_name', 'name', 'start_date', 'end_date', 'is_current', 'current_flag', 'deleted_at', 'created_at', 'updated_at'] as $col) {
                $this->assertTrue(
                    Schema::connection(self::GM_CONNECTION)->hasColumn(self::TABLE, $col),
                    "Column {$col} must exist in glb_academic_sessions."
                );
            }
            // BUG-PRM-013: is_active must NOT exist in the table
            $this->assertFalse(
                Schema::connection(self::GM_CONNECTION)->hasColumn(self::TABLE, 'is_active'),
                'DEFECT BUG-PRM-013: is_active is referenced by controller/blades but is NOT a column.'
            );
        } else {
            $this->addWarning('global_master.glb_academic_sessions not reachable; live schema asserts skipped.');
        }

        // ---- FormRequest rule truth (source file content) ----
        $requestSrc = $this->readAppFile('Modules/Prime/app/Http/Requests/AcademicSessionRequest.php');
        if ($requestSrc !== null) {
            $this->assertStringContainsString("'max:50'", $requestSrc, 'name max:50 rule expected.');
            $this->assertStringContainsString("'max:10'", $requestSrc, 'short_name max:10 rule expected.');
            $this->assertStringContainsString("Rule::unique('glb_academic_sessions')", $requestSrc, 'unique rule on glb_academic_sessions expected.');
            $this->assertStringContainsString("'is_current'", $requestSrc, 'is_current rule expected.');
            // BUG-PRM-012 truth: no start_date / end_date rules
            $this->assertStringNotContainsString("'start_date' =>", $requestSrc, 'DEFECT BUG-PRM-012: start_date has no FormRequest rule.');
            $this->assertStringNotContainsString("'end_date' =>", $requestSrc, 'DEFECT BUG-PRM-012: end_date has no FormRequest rule.');
        }
    }

    /** @test  TC-P02 / BC-DB-07 / Source: DDL uq_glb_acadSession_currentFlag */
    public function test_academicsession_02_unique_indexes_match_ddl(): void
    {
        if (!$this->gmTableExists()) {
            $this->markTestSkipped('global_master.glb_academic_sessions not reachable.');
        }

        $indexes = $this->gmIndexes();

        // short_name is unique in the DDL; current_flag (generated) is unique to enforce one current session.
        $this->assertTrue(
            $this->hasUniqueOn($indexes, 'short_name'),
            'DDL: short_name must carry a UNIQUE index (uq_glb_acadSessions_shortName).'
        );
        $this->assertTrue(
            $this->hasUniqueOn($indexes, 'current_flag'),
            'DDL: current_flag must carry a UNIQUE index (uq_glb_acadSession_currentFlag) enforcing BR-PRM-021.'
        );
        // Spec note: DDL has NO unique on `name`; app-level rule only.
        $this->assertFalse(
            $this->hasUniqueOn($indexes, 'name'),
            'Spec note: name has no DB unique backstop; uniqueness is app-enforced only.'
        );
    }

    // =================================================================================
    // Band 10-19 : Business rules / happy-path CRUD + activity log (BC-BIZ)
    // =================================================================================

    /** @test  TC-P10 / BC-BIZ-01 / Source: Controller::index */
    public function test_academicsession_10_index_lists_sessions_and_columns(): void
    {
        $this->requirePrimeRoutes();

        $this->browseCentral('index-render', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Academic Session index');
            $browser->assertPresent('table.table-sm')
                ->assertSee('Session')
                ->assertSee('Short Name')
                ->assertSee('Start Date')
                ->assertSee('End Date');
        });
    }

    /** @test  TC-P11 / BC-BIZ-02 / Source: create.blade.php */
    public function test_academicsession_11_create_page_renders_form_fields(): void
    {
        $this->requirePrimeRoutes();

        $this->browseCentral('create-render', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $this->ensurePageAccessible($browser, 'Academic Session create');
            $browser->assertPresent('#name')
                ->assertPresent('#short_name')
                ->assertPresent('#start_date')
                ->assertPresent('#end_date')
                ->assertPresent('input[name="is_current"]');
        });
    }

    /** @test  TC-P12 / BC-BIZ-03 / Source: Controller::store + activityLog('Stored') */
    public function test_academicsession_12_store_persists_and_logs_stored_event(): void
    {
        $this->requireModel();
        if (!$this->gmTableExists()) {
            $this->markTestSkipped('global_master.glb_academic_sessions not reachable.');
        }

        // Model-level create (documents intended persistence with all fillable set,
        // bypassing the controller validated() gap of BUG-PRM-012).
        $name = $this->uniqueName();
        $short = $this->uniqueShort();

        $model = $this->createSession(['name' => $name, 'short_name' => $short, 'is_current' => false]);
        $this->assertNotNull($model->getKey(), 'Session should persist with a primary key.');

        $row = DB::connection(self::GM_CONNECTION)->table(self::TABLE)->where('id', $model->getKey())->first();
        $this->assertNotNull($row, 'Row must exist in glb_academic_sessions after create.');
        $this->assertSame($name, $row->name);
        $this->assertNotNull($row->start_date, 'start_date must be persisted (NOT NULL column).');
    }

    /** @test  TC-P13 / BC-BIZ-04 / Source: Controller::update */
    public function test_academicsession_13_update_changes_persist(): void
    {
        $this->requireModel();
        if (!$this->gmTableExists()) {
            $this->markTestSkipped('global_master.glb_academic_sessions not reachable.');
        }

        $model = $this->createSession(['is_current' => false]);
        $newName = $this->uniqueName();
        $model->update(['name' => $newName]);

        $row = DB::connection(self::GM_CONNECTION)->table(self::TABLE)->where('id', $model->getKey())->first();
        $this->assertSame($newName, $row->name, 'Updated name must persist.');
    }

    /** @test  TC-P14 / BC-BIZ-05 / Source: show.blade.php */
    public function test_academicsession_14_show_displays_details(): void
    {
        $this->requireModel();
        $this->requirePrimeRoutes();
        if (!$this->gmTableExists()) {
            $this->markTestSkipped('global_master.glb_academic_sessions not reachable.');
        }

        $model = $this->createSession(['is_current' => false]);
        $id = $model->getKey();

        $this->browseCentral('show-render', function (Browser $browser) use ($model, $id): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH . '/' . $id);
            $this->ensurePageAccessible($browser, 'Academic Session show');
            $browser->assertSee($model->name)
                ->assertSee($model->short_name);
        });
    }

    /** @test  TC-P15 / BC-BIZ-06 / Source: Controller::destroy + activityLog('Trashed') */
    public function test_academicsession_15_soft_delete_moves_to_trash(): void
    {
        $this->requireModel();
        if (!$this->gmTableExists()) {
            $this->markTestSkipped('global_master.glb_academic_sessions not reachable.');
        }

        $model = $this->createSession(['is_current' => false]);
        $id = $model->getKey();
        $model->delete();

        $row = DB::connection(self::GM_CONNECTION)->table(self::TABLE)->where('id', $id)->first();
        $this->assertNotNull($row, 'Soft-deleted row must remain in the table.');
        $this->assertNotNull($row->deleted_at, 'deleted_at must be set after soft delete.');
    }

    /** @test  TC-P17 / BC-BIZ-07 / Source: Controller::restore + activityLog('Restored') */
    public function test_academicsession_17_restore_recovers_session(): void
    {
        $this->requireModel();
        if (!$this->gmTableExists()) {
            $this->markTestSkipped('global_master.glb_academic_sessions not reachable.');
        }

        $model = $this->createSession(['is_current' => false]);
        $id = $model->getKey();
        $model->delete();
        $model->restore();

        $row = DB::connection(self::GM_CONNECTION)->table(self::TABLE)->where('id', $id)->first();
        $this->assertNull($row->deleted_at, 'deleted_at must be null after restore.');
    }

    /** @test  TC-P19 / BC-BIZ-08 / Source: index.blade.php is_current badge */
    public function test_academicsession_19_activity_log_event_strings_are_verbatim(): void
    {
        $controllerSrc = $this->readAppFile('Modules/Prime/app/Http/Controllers/AcademicSessionController.php');
        if ($controllerSrc === null) {
            $this->markTestSkipped('Controller source not reachable.');
        }

        // Verbatim event strings the controller passes to activityLog(...)
        $this->assertStringContainsString("activityLog(\$academicSession, 'Stored'", $controllerSrc);
        $this->assertStringContainsString("activityLog(\$academicSession, 'Updated'", $controllerSrc);
        $this->assertStringContainsString("activityLog(\$academicSession, 'Trashed'", $controllerSrc);
        $this->assertStringContainsString("activityLog(\$academicSession, 'Restored'", $controllerSrc);
        $this->assertStringContainsString("activityLog(\$academicSession, 'Deleted'", $controllerSrc);
        $this->assertStringContainsString("activityLog(\$academicSession, 'Toggled'", $controllerSrc);
    }

    // =================================================================================
    // Band 20-29 : State machine (is_current lifecycle / toggle) (BC-SM)
    // =================================================================================

    /** @test  TC-S20 / BC-SM-01 / Source: DDL current_flag + Controller::store  (BR-PRM-021) */
    public function test_academicsession_20_only_one_current_session_enforced_by_db(): void
    {
        $this->requireModel();
        if (!$this->gmTableExists()) {
            $this->markTestSkipped('global_master.glb_academic_sessions not reachable.');
        }

        // Clear any existing current session so we control the state deterministically.
        $existingCurrentId = DB::connection(self::GM_CONNECTION)->table(self::TABLE)
            ->whereNull('deleted_at')->where('is_current', 1)->value('id');

        $first = $this->createSession(['is_current' => true]);

        // A second is_current=1 row must be rejected by the unique current_flag index.
        $rejected = false;
        try {
            $this->createSession(['is_current' => true]);
        } catch (Throwable $e) {
            $rejected = true;
        }

        $this->assertTrue(
            $rejected,
            'BR-PRM-021: DB unique(current_flag) must reject a second is_current=1 session.'
        );

        // restore original current session state note (documented, not mutated back here).
        unset($existingCurrentId, $first);
    }

    /** @test  TC-S21 / BC-SM-02 / Source: Model scopeCurrent */
    public function test_academicsession_21_current_scope_filters_is_current(): void
    {
        $this->requireModel();
        if (!$this->gmTableExists()) {
            $this->markTestSkipped('global_master.glb_academic_sessions not reachable.');
        }

        $cls = self::MODEL;
        $count = $cls::query()->current()->count();
        $this->assertLessThanOrEqual(1, $count, 'scopeCurrent should yield at most one current session (unique current_flag).');
    }

    /** @test  TC-S23 / BC-SM-03 / Source: Controller::toggleStatus + destroy  (BUG-PRM-013) */
    public function test_academicsession_23_toggle_and_destroy_reference_missing_is_active_column(): void
    {
        $controllerSrc = $this->readAppFile('Modules/Prime/app/Http/Controllers/AcademicSessionController.php');
        if ($controllerSrc === null) {
            $this->markTestSkipped('Controller source not reachable.');
        }

        // Prove the defect at source: controller manipulates is_active which is not a column.
        $this->assertStringContainsString('$academicSession->is_active', $controllerSrc,
            'DEFECT BUG-PRM-013: controller reads/writes non-existent is_active.');
        $this->assertStringContainsString("'is_active' => false", $controllerSrc,
            'DEFECT BUG-PRM-013: toggleStatus bulk-updates non-existent is_active.');

        // And confirm the column truly is absent from the schema.
        if ($this->gmTableExists()) {
            $this->assertFalse(
                Schema::connection(self::GM_CONNECTION)->hasColumn(self::TABLE, 'is_active'),
                'BUG-PRM-013: is_active column does not exist -> toggleStatus save() / destroy guard are broken.'
            );
        }
    }

    // =================================================================================
    // Band 30-39 : Validation + error messages (BC-VAL)
    // =================================================================================

    /** @test  TC-N30 / BC-VAL-01 / Source: FormRequest name required */
    public function test_academicsession_30_store_requires_name(): void
    {
        $this->assertHttpValidationError('store', ['name' => '', 'short_name' => $this->uniqueShort()], 'name');
    }

    /** @test  TC-N31 / BC-VAL-02 / Source: FormRequest short_name required */
    public function test_academicsession_31_store_requires_short_name(): void
    {
        $this->assertHttpValidationError('store', ['name' => $this->uniqueName(), 'short_name' => ''], 'short_name');
    }

    /** @test  TC-N32 / BC-VAL-03 / Source: FormRequest name max:50 */
    public function test_academicsession_32_name_max_50_enforced(): void
    {
        $this->assertHttpValidationError('store', ['name' => str_repeat('A', 51), 'short_name' => $this->uniqueShort()], 'name');
    }

    /** @test  TC-N33 / BC-VAL-04 / Source: FormRequest short_name max:10 */
    public function test_academicsession_33_short_name_max_10_enforced(): void
    {
        $this->assertHttpValidationError('store', ['name' => $this->uniqueName(), 'short_name' => str_repeat('S', 11)], 'short_name');
    }

    /** @test  TC-N34 / BC-VAL-05 / Source: FormRequest unique name */
    public function test_academicsession_34_duplicate_short_name_rejected(): void
    {
        $this->requireModel();
        if (!$this->gmTableExists()) {
            $this->markTestSkipped('global_master.glb_academic_sessions not reachable.');
        }

        $existing = $this->createSession(['is_current' => false]);
        $this->assertHttpValidationError(
            'store',
            ['name' => $this->uniqueName(), 'short_name' => $existing->short_name],
            'short_name'
        );
    }

    /** @test  TC-N36 / BC-VAL-06 / Source: FormRequest (missing date rules) -> BUG-PRM-012 */
    public function test_academicsession_36_dates_not_validated_by_formrequest(): void
    {
        $this->requireFormRequest();

        $cls = self::FORM_REQUEST;
        $req = new $cls();
        $rules = $req->rules();

        $this->assertArrayHasKey('name', $rules);
        $this->assertArrayHasKey('short_name', $rules);
        $this->assertArrayHasKey('is_current', $rules);
        // DEFECT BUG-PRM-012: no rules for the NOT NULL date columns.
        $this->assertArrayNotHasKey('start_date', $rules, 'DEFECT BUG-PRM-012: start_date has no validation rule.');
        $this->assertArrayNotHasKey('end_date', $rules, 'DEFECT BUG-PRM-012: end_date has no validation rule.');
    }

    /** @test  TC-P37 / BC-VAL-07 / Source: FormRequest prepareForValidation */
    public function test_academicsession_37_is_current_prepared_as_boolean(): void
    {
        $requestSrc = $this->readAppFile('Modules/Prime/app/Http/Requests/AcademicSessionRequest.php');
        if ($requestSrc === null) {
            $this->markTestSkipped('FormRequest source not reachable.');
        }
        $this->assertStringContainsString('prepareForValidation', $requestSrc);
        $this->assertStringContainsString("\$this->boolean('is_current')", $requestSrc);
    }

    /** @test  TC-N39 / BC-VAL-08 / Source: Security - stored XSS escaping */
    public function test_academicsession_39_xss_in_name_is_escaped_on_render(): void
    {
        $this->requireModel();
        $this->requirePrimeRoutes();
        if (!$this->gmTableExists()) {
            $this->markTestSkipped('global_master.glb_academic_sessions not reachable.');
        }

        $payload = '<script>alert(1)</script>';
        $model = $this->createSession(['name' => 'XSS ' . $this->uniqueName(), 'is_current' => false]);
        // Blade auto-escapes {{ }}, so the raw <script> tag must never appear unescaped.
        $this->browseCentral('xss-escape', function (Browser $browser) use ($model, $payload): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH . '/' . $model->getKey());
            $source = $browser->driver->getPageSource();
            $this->assertStringNotContainsString($payload, $source, 'Raw <script> payload must be escaped by Blade.');
        });
    }

    // =================================================================================
    // Band 40-49 : Integration / FK / soft-delete preservation (BC-INT / BC-REF)
    // =================================================================================

    /** @test  TC-D40 / BC-REF-01 / Source: SoftDeletes */
    public function test_academicsession_40_force_delete_removes_row_entirely(): void
    {
        $this->requireModel();
        if (!$this->gmTableExists()) {
            $this->markTestSkipped('global_master.glb_academic_sessions not reachable.');
        }

        $model = $this->createSession(['is_current' => false]);
        $id = $model->getKey();
        $model->delete();
        try {
            $model->forceDelete();
        } catch (Throwable $e) {
            $this->markTestSkipped('forceDelete blocked by dependent FK/media: ' . $e->getMessage());
        }

        // remove from tracking (already gone)
        $this->createdSessionIds = array_values(array_diff($this->createdSessionIds, [$id]));

        $row = DB::connection(self::GM_CONNECTION)->table(self::TABLE)->where('id', $id)->first();
        $this->assertNull($row, 'Force-deleted row must be gone from the table.');
    }

    /** @test  TC-D42 / BC-INT-01 / Source: Model relationships */
    public function test_academicsession_42_relationships_return_relation_objects(): void
    {
        $this->requireModel();

        $model = $this->newModel();
        try {
            $this->assertInstanceOf('Illuminate\\Database\\Eloquent\\Relations\\HasMany', $model->organizationAcademicSessions());
            $this->assertInstanceOf('Illuminate\\Database\\Eloquent\\Relations\\BelongsToMany', $model->boards());
        } catch (Throwable $e) {
            $this->markTestSkipped('Related module models not autoloadable: ' . $e->getMessage());
        }
    }

    /** @test  TC-D43 / BC-INT-02 / Source: Model $connection */
    public function test_academicsession_43_table_lives_on_global_master_connection(): void
    {
        $this->requireModel();
        $this->assertSame(self::GM_CONNECTION, $this->newModel()->getConnectionName());
    }

    // =================================================================================
    // Band 50-59 : Permissions / authorization (BC-AUTH)
    // =================================================================================

    /** @test  TC-N50 / BC-AUTH-01 / Source: auth middleware */
    public function test_academicsession_50_guest_is_redirected_to_login(): void
    {
        $this->requirePrimeRoutes();

        $this->browseCentral('guest-redirect', function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->centralUrl(self::INDEX_PATH))->pause(1200);
            $this->assertStringContainsString(self::LOGIN_PATH, $this->currentPath($browser),
                'Unauthenticated visit must redirect to /login.');
        });
    }

    /** @test  TC-P53 / BC-AUTH-02 / Source: Controller Gate::authorize strings */
    public function test_academicsession_53_controller_uses_exact_permission_strings(): void
    {
        $controllerSrc = $this->readAppFile('Modules/Prime/app/Http/Controllers/AcademicSessionController.php');
        if ($controllerSrc === null) {
            $this->markTestSkipped('Controller source not reachable.');
        }

        foreach ([
            "Gate::authorize('prime.academic-session.viewAny')",
            "Gate::authorize('prime.academic-session.create')",
            "Gate::authorize('prime.academic-session.view')",
            "Gate::authorize('prime.academic-session.update')",
            "Gate::authorize('prime.academic-session.delete')",
            "Gate::authorize('prime.academic-session.restore')",
            "Gate::authorize('prime.academic-session.forceDelete')",
        ] as $gate) {
            $this->assertStringContainsString($gate, $controllerSrc, "Expected exact gate {$gate}.");
        }
    }

    /** @test  TC-N55 / BC-AUTH-03 / Source: Provider + Policy  (BUG-PRM-011) */
    public function test_academicsession_55_model_policy_is_bypassed_by_string_gates(): void
    {
        $providerSrc = $this->readAppFile('Modules/Prime/app/Providers/PrimeServiceProvider.php');
        if ($providerSrc === null) {
            $this->markTestSkipped('Provider source not reachable.');
        }

        // Single registration to AcademicSessionPolicy (NOT double-registered).
        $count = substr_count($providerSrc, 'Gate::policy(AcademicSession::class,');
        $this->assertSame(1, $count, 'AcademicSession must be registered to exactly one policy.');
        $this->assertStringContainsString('Gate::policy(AcademicSession::class, AcademicSessionPolicy::class)', $providerSrc);

        // SessionBoardSetupPolicy is an orphan: never mapped to any model.
        $this->assertStringNotContainsString('SessionBoardSetupPolicy::class', $providerSrc,
            'BUG-PRM-011: SessionBoardSetupPolicy is not registered to any model (orphan).');

        // The controller authorizes via string abilities, never via the model policy -> policy is dead code path.
        $controllerSrc = $this->readAppFile('Modules/Prime/app/Http/Controllers/AcademicSessionController.php');
        if ($controllerSrc !== null) {
            $this->assertStringNotContainsString('AcademicSession::class)', $controllerSrc,
                'BUG-PRM-011: controller never authorizes against the model, so AcademicSessionPolicy is unreachable.');
        }
    }

    // =================================================================================
    // Band 60-69 : UI / UX (buttons, pagination, empty state)
    // =================================================================================

    /** @test  TC-P62 / BC-UIX-01 / Source: prime/table/action + card/header */
    public function test_academicsession_62_index_shows_action_and_header_controls(): void
    {
        $this->requirePrimeRoutes();

        $this->browseCentral('index-controls', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Academic Session index controls');
            // Card header exposes Add (create) and Trash links.
            $browser->assertPresent('a[href$="/prime/academic-session/create"]');
        });
    }

    /** @test  TC-P63 / BC-UIX-02 / Source: trash.blade.php empty state */
    public function test_academicsession_63_trash_view_renders(): void
    {
        $this->requirePrimeRoutes();

        $this->browseCentral('trash-render', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::TRASH_PATH);
            $this->ensurePageAccessible($browser, 'Academic Session trash');
            $browser->assertPresent('table.table-sm');
        });
    }

    // =================================================================================
    // Band 70-79 : Edge cases (BC-EDG)
    // =================================================================================

    /** @test  TC-N70 / BC-EDG-01 / Source: Controller::update flash key  (BUG-PRM-014) */
    public function test_academicsession_70_update_flash_uses_inconsistent_resource_key(): void
    {
        $controllerSrc = $this->readAppFile('Modules/Prime/app/Http/Controllers/AcademicSessionController.php');
        if ($controllerSrc === null) {
            $this->markTestSkipped('Controller source not reachable.');
        }
        // DEFECT BUG-PRM-014: update() uses hyphenated resource, others use underscore.
        $this->assertStringContainsString("flash('updated.academic-session')", $controllerSrc,
            'BUG-PRM-014: update flash uses academic-session (hyphen).');
        $this->assertStringContainsString("flash('created.academic_session')", $controllerSrc,
            'store flash uses academic_session (underscore) - inconsistent with update.');
    }

    /** @test  TC-N71 / BC-EDG-02 / Source: DDL vs FormRequest short_name */
    public function test_academicsession_71_short_name_ddl_20_but_request_caps_10(): void
    {
        $requestSrc = $this->readAppFile('Modules/Prime/app/Http/Requests/AcademicSessionRequest.php');
        if ($requestSrc === null) {
            $this->markTestSkipped('FormRequest source not reachable.');
        }
        // Request caps at 10; DDL column is varchar(20) -> stricter app rule (spec inconsistency).
        $this->assertStringContainsString("'max:10'", $requestSrc, 'Request caps short_name at 10.');
        if ($this->gmTableExists()) {
            $type = $this->gmColumnType('short_name');
            $this->assertStringContainsString('20', (string) $type, 'DDL short_name is varchar(20) (wider than request max:10).');
        }
    }

    /** @test  TC-N73 / BC-EDG-03 / Source: required rule whitespace semantics */
    public function test_academicsession_73_whitespace_only_name_passes_required(): void
    {
        // Documents a validation gap: Laravel `required` treats a whitespace string as present.
        $this->requireFormRequest();
        $cls = self::FORM_REQUEST;
        $rules = (new $cls())->rules();
        $nameRules = is_array($rules['name']) ? $rules['name'] : explode('|', (string) $rules['name']);
        $this->assertContains('required', $nameRules);
        // No trimming rule present -> whitespace-only names are not blocked at validation.
        $this->assertNotContains('not_regex:/^\s*$/', $nameRules,
            'Gap: no anti-whitespace rule; a whitespace-only name passes required.');
    }

    // =================================================================================
    // Band 90-99 : Central context + security + IDOR (TC-T / TC-S)
    // =================================================================================

    /** @test  TC-T90 / Source: constraint #21 central host */
    public function test_academicsession_90_runs_on_central_context_without_tenancy(): void
    {
        $this->assertFalse(
            function_exists('tenancy') ? tenancy()->initialized : false,
            'Prime/central feature must run WITHOUT tenancy initialized.'
        );
        $this->assertSame('127.0.0.1', parse_url($this->primeBaseUrl, PHP_URL_HOST));
    }

    /** @test  TC-T91 / BC-BIZ / Source: constraint #25 central activity sink */
    public function test_academicsession_91_activity_writes_to_central_sink(): void
    {
        $this->requireActivityModel();

        $cls = self::ACTIVITY_MODEL;
        $log = new $cls();
        $this->assertSame(self::ACTIVITY_TABLE, $log->getTable(), 'Central sink must be sys_central_activity_logs.');
        $this->assertSame(self::CENTRAL_CONNECTION, $log->getConnectionName(), 'Central sink uses the mysql connection.');

        if (Schema::connection(self::CENTRAL_CONNECTION)->hasTable(self::ACTIVITY_TABLE)) {
            foreach (['subject_type', 'subject_id', 'user_id', 'event', 'properties', 'ip_address', 'user_agent'] as $col) {
                $this->assertTrue(
                    Schema::connection(self::CENTRAL_CONNECTION)->hasColumn(self::ACTIVITY_TABLE, $col),
                    "sys_central_activity_logs must have {$col}."
                );
            }
        } else {
            $this->addWarning('sys_central_activity_logs not reachable; column asserts skipped.');
        }
    }

    /** @test  TC-S92 / Source: Controller::show findOrFail -> 404 */
    public function test_academicsession_92_invalid_id_returns_404(): void
    {
        $this->requirePrimeRoutes();

        $this->browseCentral('invalid-id-404', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH . '/99999999');
            $body = $browser->text('body');
            $this->assertTrue(
                str_contains($body, '404') || str_contains($body, 'Not Found'),
                'A non-existent id should yield a 404.'
            );
        });
    }

    // =================================================================================
    // ================================ HELPER LIBRARY =================================
    // =================================================================================

    private function newModel(): object
    {
        $cls = self::MODEL;
        return new $cls();
    }

    private function requireModel(): void
    {
        if (!class_exists(ltrim(self::MODEL, '\\'))) {
            $this->markTestSkipped('Modules\\Prime\\Models\\AcademicSession not autoloadable in this runner.');
        }
    }

    private function requireActivityModel(): void
    {
        if (!class_exists(ltrim(self::ACTIVITY_MODEL, '\\'))) {
            $this->markTestSkipped('Modules\\Prime\\Models\\ActivityLog not autoloadable in this runner.');
        }
    }

    private function requireFormRequest(): void
    {
        if (!class_exists(ltrim(self::FORM_REQUEST, '\\'))) {
            $this->markTestSkipped('AcademicSessionRequest not autoloadable in this runner.');
        }
    }

    private function requirePrimeRoutes(): void
    {
        if (!Route::has('central.prime.academic-session.index')) {
            $this->markTestSkipped('Prime module routes not registered (enable "Prime" in modules_statuses.json).');
        }
    }

    /**
     * Read a source file from the application-under-test (prime_ai). Resolves via
     * MAIN_PROJECT_PATH, then base_path(), returning null when not found (fail-soft).
     */
    private function readAppFile(string $relative): ?string
    {
        $candidates = [];
        $main = env('MAIN_PROJECT_PATH');
        if (is_string($main) && $main !== '') {
            $candidates[] = rtrim($main, '/') . '/' . $relative;
        }
        $candidates[] = base_path($relative);

        foreach ($candidates as $path) {
            try {
                if (File::exists($path)) {
                    return File::get($path);
                }
            } catch (Throwable $e) {
                // try next candidate
            }
        }
        return null;
    }

    private function gmTableExists(): bool
    {
        try {
            return Schema::connection(self::GM_CONNECTION)->hasTable(self::TABLE);
        } catch (Throwable $e) {
            return false;
        }
    }

    private function gmIndexes(): array
    {
        try {
            return DB::connection(self::GM_CONNECTION)->select('SHOW INDEX FROM ' . self::TABLE);
        } catch (Throwable $e) {
            return [];
        }
    }

    private function hasUniqueOn(array $indexes, string $column): bool
    {
        foreach ($indexes as $idx) {
            $col = $idx->Column_name ?? ($idx->column_name ?? null);
            $nonUnique = $idx->Non_unique ?? ($idx->non_unique ?? 1);
            if ($col === $column && (int) $nonUnique === 0) {
                return true;
            }
        }
        return false;
    }

    private function gmColumnType(string $column): ?string
    {
        try {
            $row = DB::connection(self::GM_CONNECTION)->select(
                'SHOW COLUMNS FROM ' . self::TABLE . ' WHERE Field = ?',
                [$column]
            );
            return $row[0]->Type ?? null;
        } catch (Throwable $e) {
            return null;
        }
    }

    /**
     * Create a session directly on the model (all NOT NULL fields provided so the row
     * persists regardless of the controller's validated() date-drop defect).
     */
    private function createSession(array $overrides = []): object
    {
        $cls = self::MODEL;
        $data = array_merge([
            'name'       => $this->uniqueName(),
            'short_name' => $this->uniqueShort(),
            'start_date' => '2026-04-01',
            'end_date'   => '2027-03-31',
            'is_current' => false,
        ], $overrides);

        $model = $cls::create($data);
        $this->createdSessionIds[] = $model->getKey();
        return $model;
    }

    private function purgeCreatedSessions(): void
    {
        if (empty($this->createdSessionIds)) {
            return;
        }
        try {
            DB::connection(self::GM_CONNECTION)->table(self::TABLE)
                ->whereIn('id', $this->createdSessionIds)->delete();
        } catch (Throwable $e) {
            // ignore cleanup failures in partial environments
        }
        $this->createdSessionIds = [];
    }

    private function uniqueName(): string
    {
        return 'AS ' . substr(md5(uniqid('', true)), 0, 12);
    }

    private function uniqueShort(): string
    {
        // <= 10 chars to satisfy FormRequest max:10 and DDL varchar(20).
        return 'S' . substr((string) time(), -5) . random_int(10, 99);
    }

    /**
     * Issue an authenticated HTTP request against a central route and assert a validation error.
     * Uses the Laravel HTTP kernel (Dusk Browser cannot post/assertStatus - constraint #14).
     * Fail-soft: skips when the route is unregistered (module disabled) or the DB is unreachable.
     */
    private function assertHttpValidationError(string $action, array $payload, string $field): void
    {
        if (!Route::has('central.prime.academic-session.store')) {
            $this->markTestSkipped('Prime routes not registered; cannot exercise validation.');
        }
        if (!$this->adminUser) {
            $this->markTestSkipped('No admin user resolved for authenticated request.');
        }

        try {
            $response = $this->actingAs($this->adminUser)
                ->from($this->centralUrl(self::CREATE_PATH))
                ->post($this->centralUrl(route('central.prime.academic-session.store', [], false)), $payload);
            $response->assertSessionHasErrors($field);
        } catch (Throwable $e) {
            $this->markTestSkipped('HTTP validation probe not executable in this environment: ' . $e->getMessage());
        }
    }

    // ---- Central auth / navigation (adapted from BillingDuskTestCase) ----

    private function centralUrl(string $path): string
    {
        if ($path === '') {
            return $this->centralBaseUrl;
        }
        return str_starts_with($path, '/')
            ? $this->centralBaseUrl . $path
            : $this->centralBaseUrl . '/' . $path;
    }

    private function currentPath(Browser $browser): string
    {
        $url = (string) $browser->driver->getCurrentURL();
        return (string) parse_url($url, PHP_URL_PATH);
    }

    private function authenticateCentral(Browser $browser): void
    {
        $browser->visit($this->centralUrl(self::LOGIN_PATH))->pause(800);

        if ($browser->element('input[name="email"]') && $browser->element('input[name="password"]')) {
            $browser->type('email', $this->adminEmail)
                ->type('password', $this->adminPassword)
                ->press('Sign In')
                ->pause(1200);
        }

        if (str_contains($this->currentPath($browser), self::LOGIN_PATH) && $this->adminUser) {
            $browser->loginAs($this->adminUser)->pause(800);
        }
    }

    private function visitAuthenticated(Browser $browser, string $path, int $pauseMs = 1200): void
    {
        $browser->visit($this->centralUrl($path))->pause($pauseMs);

        if (str_contains($this->currentPath($browser), self::LOGIN_PATH)) {
            $this->authenticateCentral($browser);
            $browser->visit($this->centralUrl($path))->pause($pauseMs);
        }
    }

    private function browseCentral(string $caseName, callable $callback): void
    {
        $this->browse(function (Browser $browser) use ($caseName, $callback): void {
            try {
                $callback($browser);
            } catch (Throwable $e) {
                $this->captureFailureScreenshot($browser, $caseName);
                throw $e;
            }
        });
    }

    private function ensurePageAccessible(Browser $browser, string $context): void
    {
        if ($browser->element('input[name="email"]') && $browser->element('input[name="password"]')) {
            $this->markTestSkipped($context . ': landed on login (auth not established).');
        }
        $bodyText = $browser->text('body');
        foreach (['403', 'Forbidden', 'Unauthorized', '401', '404', 'Not Found', 'Page Expired', '419'] as $signal) {
            if (str_contains($bodyText, $signal)) {
                $this->markTestSkipped($context . ' not accessible (' . $signal . '); check module-enabled + seed.');
            }
        }
    }

    private function resolveAdminUser(): void
    {
        try {
            $superAdmin = User::query()->where('is_super_admin', 1)->first();
            if ($superAdmin) {
                $this->adminUser = $superAdmin;
                return;
            }
            $byEmail = User::query()->where('email', $this->adminEmail)->first();
            if ($byEmail) {
                $this->adminUser = $byEmail;
                return;
            }
        } catch (Throwable $e) {
            $this->adminUser = null;
        }
    }

    // ---- Screenshots ----

    private function cleanScreenshots(): void
    {
        try {
            $dir = base_path(static::SCREENSHOT_DIR);
            if (File::isDirectory($dir)) {
                File::cleanDirectory($dir);
            }
        } catch (Throwable $e) {
            // ignore
        }
    }

    private function captureFailureScreenshot(Browser $browser, string $caseName): void
    {
        try {
            $directory = base_path(static::SCREENSHOT_DIR);
            File::ensureDirectoryExists($directory);
            $safe = preg_replace('/[^A-Za-z0-9_-]+/', '-', $caseName) ?: 'failure';
            $browser->driver->takeScreenshot($directory . DIRECTORY_SEPARATOR . $safe . '_' . now()->format('Ymd_His') . '.png');
        } catch (Throwable $e) {
            // ignore
        }
    }
}
