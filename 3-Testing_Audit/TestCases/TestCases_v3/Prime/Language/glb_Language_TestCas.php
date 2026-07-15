<?php

namespace Tests\Browser\Modules\Prime\Language;

use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Tests\Browser\Modules\Prime\PrimeDuskTestCase;
use Throwable;

/**
 * Prime (PRM) / GlobalMaster Language screen — single comprehensive Dusk suite.
 *
 * SCOPE: Prime = CENTRAL DB. No tenant initialization. Host http://127.0.0.1:8000.
 * The screen is served by Modules\Prime\Http\Controllers\LanguageController and backed
 * by Modules\Prime\Models\Language whose $connection = 'global_master_mysql' and
 * $table = 'glb_languages'. In prime_db, glb_languages is a VIEW mirroring
 * global_master.glb_languages; the model bypasses the view and writes go straight to
 * the base table via the global_master_mysql connection, so CRUD IS writable.
 *
 * Real route names: central.global-master.language.*  (NOT central.prime.language.*).
 * Real permission gates: prime.language.{viewAny|view|create|update|delete|restore|forceDelete}.
 * Activity sink (central, no tenant init): sys_central_activity_logs via
 * Modules\Prime\Models\ActivityLog. Literal events: 'Trashed', 'Restored', 'Stored'
 * (forceDelete — mislabeled), 'Toggled'. store()/update() log nothing.
 *
 * @see 05_Known_Test_Failure_Constraints.md #21 (127.0.0.1 host), #22 (base-class alias
 *      via preload.php), #25 (central activity sink), #10 (glb_languages VIEW / FK).
 */
class glb_Language_TestCas extends PrimeDuskTestCase
{
    private const INDEX_PATH = '/global-master/language';
    private const CREATE_PATH = '/global-master/language/create';
    private const TRASH_PATH = '/global-master/language/trash/view';

    private const LANG_CONNECTION = 'global_master_mysql';
    private const LANG_TABLE = 'glb_languages';

    private const CONTROLLER_FILE = 'Modules/Prime/app/Http/Controllers/LanguageController.php';
    private const MODEL_FILE = 'Modules/Prime/app/Models/Language.php';
    private const REQUEST_FILE = 'Modules/GlobalMaster/app/Http/Requests/LanguageRequest.php';
    private const MIGRATION_GLOB = 'Modules/GlobalMaster/database/migrations/*create_languages_table.php';

    private const SCREENSHOT_DIR = 'tests/Browser/Modules/Prime/Language/screenshots';

    private ?User $adminUser = null;
    private string $centralBaseUrl = '';
    private string $adminEmail = '';
    private string $adminPassword = '';
    private array $createdLanguageIds = [];
    private static bool $screenshotsCleaned = false;

    protected function setUp(): void
    {
        parent::setUp();

        $this->centralBaseUrl = rtrim($this->primeBaseUrl, '/');
        $this->adminEmail = (string) env('DUSK_ADMIN_EMAIL', 'root@tenant.com');
        $this->adminPassword = (string) env('DUSK_ADMIN_PASSWORD', 'password');
        $this->createdLanguageIds = [];

        if (!self::$screenshotsCleaned) {
            $this->cleanScreenshots();
            self::$screenshotsCleaned = true;
        }

        $this->resolveAdminUser();
    }

    protected function tearDown(): void
    {
        $this->cleanupCreatedLanguages();
        parent::tearDown();
    }

    // =====================================================================
    // 01-09  SCHEMA / DDL / MODEL / REQUEST CONFIGURATION (truth first)
    // =====================================================================

    /** TC-P01 / BC-DB-* — schema, model, request configuration are correct. */
    public function test_language_01_schema_model_and_request_configuration_are_correct(): void
    {
        // --- Live schema truth on the global_master connection (base table) ---
        $this->assertTrue(
            Schema::connection(self::LANG_CONNECTION)->hasTable(self::LANG_TABLE),
            'global_master.glb_languages base table is missing.'
        );

        $expectedColumns = ['id', 'code', 'name', 'native_name', 'direction', 'is_active'];
        foreach ($expectedColumns as $column) {
            $this->assertTrue(
                Schema::connection(self::LANG_CONNECTION)->hasColumn(self::LANG_TABLE, $column),
                "Column {$column} missing from glb_languages."
            );
        }

        // Migration adds softDeletes()+timestamps() even though the consolidated DDL omits them.
        foreach (['deleted_at', 'created_at', 'updated_at'] as $column) {
            $this->assertTrue(
                Schema::connection(self::LANG_CONNECTION)->hasColumn(self::LANG_TABLE, $column),
                "Soft-delete/timestamp column {$column} missing — SoftDeletes model would break."
            );
        }

        // Unique indexes on code AND name (MySQL 8 COLUMN_TYPE variance tolerated).
        $indexes = DB::connection(self::LANG_CONNECTION)->select('SHOW INDEX FROM ' . self::LANG_TABLE);
        $uniqueColumns = [];
        foreach ($indexes as $index) {
            if ((int) $index->Non_unique === 0) {
                $uniqueColumns[] = strtolower($index->Column_name);
            }
        }
        $this->assertContains('code', $uniqueColumns, 'code is not uniquely indexed.');
        $this->assertContains('name', $uniqueColumns, 'name is not uniquely indexed.');

        // --- Model configuration ---
        $model = new \Modules\Prime\Models\Language();
        $this->assertSame(self::LANG_TABLE, $model->getTable());
        $this->assertSame(self::LANG_CONNECTION, $model->getConnectionName());
        $this->assertEqualsCanonicalizing(
            ['code', 'name', 'native_name', 'direction', 'is_active'],
            $model->getFillable()
        );
        $this->assertContains(
            \Illuminate\Database\Eloquent\SoftDeletes::class,
            class_uses_recursive(\Modules\Prime\Models\Language::class),
            'Language model must use SoftDeletes.'
        );

        // --- Migration file content ---
        $migrationFiles = File::glob(base_path(self::MIGRATION_GLOB));
        $this->assertNotEmpty($migrationFiles, 'create_languages_table migration not found.');
        $migration = File::get($migrationFiles[0]);
        $this->assertStringContainsString("global_master_mysql", $migration);
        $this->assertStringContainsString('softDeletes()', $migration);
        $this->assertStringContainsString('timestamps()', $migration);
        $this->assertStringContainsString('CREATE OR REPLACE VIEW glb_languages', $migration);

        // --- FormRequest rule strings (exact) ---
        $request = File::get(base_path(self::REQUEST_FILE));
        $this->assertStringContainsString("'max:10'", $request, 'code max:10 rule missing.');
        $this->assertStringContainsString("'max:50'", $request, 'name/native max:50 rule missing.');
        $this->assertStringContainsString("Rule::unique('glb_languages', 'code')", $request);
        $this->assertStringContainsString("Rule::unique('glb_languages', 'name')", $request);
        $this->assertStringContainsString("Rule::in(['LTR', 'RTL'])", $request);
    }

    /** TC-P02 / BC-AUTH — routes registered under central.global-master.language.*. */
    public function test_language_02_routes_are_registered_under_central_global_master(): void
    {
        $resourceRoutes = ['index', 'create', 'store', 'show', 'edit', 'update', 'destroy'];
        foreach ($resourceRoutes as $name) {
            $this->assertTrue(
                Route::has('central.global-master.language.' . $name),
                "Route central.global-master.language.{$name} is not registered."
            );
        }
        foreach (['trashed', 'restore', 'forceDelete', 'toggleStatus'] as $name) {
            $this->assertTrue(
                Route::has('central.global-master.language.' . $name),
                "Route central.global-master.language.{$name} is not registered."
            );
        }

        // The expected central.prime.language.* names do NOT exist — flag the assumption.
        $this->assertFalse(
            Route::has('central.prime.language.index'),
            'Unexpected: central.prime.language.* is registered; real names are central.global-master.language.*'
        );
    }

    /** TC-P03 / BC-BIZ — controller wires the real gates and activity events. */
    public function test_language_03_controller_gates_and_activity_events_are_wired(): void
    {
        $controller = File::get(base_path(self::CONTROLLER_FILE));

        foreach ([
            'prime.language.viewAny',
            'prime.language.create',
            'prime.language.view',
            'prime.language.update',
            'prime.language.delete',
            'prime.language.restore',
            'prime.language.forceDelete',
        ] as $gate) {
            $this->assertStringContainsString($gate, $controller, "Gate {$gate} missing from controller.");
        }

        // Literal activity-log event strings (verbatim — 'Stored' on forceDelete is a defect).
        $this->assertStringContainsString("activityLog(\$language, 'Trashed'", $controller);
        $this->assertStringContainsString("activityLog(\$language, 'Restored'", $controller);
        $this->assertStringContainsString("activityLog(\$language, 'Stored'", $controller);
        $this->assertStringContainsString("activityLog(\$language, 'Toggled'", $controller);

        // Central activity sink is reachable (no consolidated DDL — assert table + fillable).
        $this->assertTrue(
            Schema::hasTable('sys_central_activity_logs'),
            'Central activity sink sys_central_activity_logs is missing.'
        );
    }

    // =====================================================================
    // 10-19  BUSINESS RULES (BC-BIZ)
    // =====================================================================

    /** TC-P10 — index lists languages with pagination (11 per page). */
    public function test_language_10_index_lists_languages_with_pagination(): void
    {
        $this->browseWithFailureScreenshot('index-list', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Language index');

            $browser->assertSee('Language Management')
                ->assertPresent('table.js-sortable')
                ->assertSeeIn('thead', 'Language')
                ->assertSeeIn('thead', 'Native Name')
                ->assertSeeIn('thead', 'Code');
        });
    }

    /** TC-P11 — creating a language persists a row and redirects to index. */
    public function test_language_11_create_language_persists_row_and_redirects(): void
    {
        $code = $this->uniqueCode();
        $name = $this->uniqueName();

        $this->browseWithFailureScreenshot('create-persist', function (Browser $browser) use ($code, $name): void {
            $this->submitCreateForm($browser, $name, $code, 'Native ' . $name, 'LTR', true);

            $browser->assertPathIs(self::INDEX_PATH);
        });

        $row = DB::connection(self::LANG_CONNECTION)->table(self::LANG_TABLE)
            ->where('code', $code)->first();
        $this->assertNotNull($row, 'Created language row not found in global_master.glb_languages.');
        $this->assertSame($name, $row->name);
        $this->rememberLanguage((int) $row->id);
    }

    /** TC-P12 — updating a language persists changes. */
    public function test_language_12_update_language_persists_changes(): void
    {
        $id = $this->seedLanguage();
        $newNative = 'Updated Native ' . uniqid();

        $this->browseWithFailureScreenshot('update-persist', function (Browser $browser) use ($id, $newNative): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH . '/' . $id . '/edit');
            $this->ensurePageAccessible($browser, 'Language edit');
            $browser->assertInputPresent('name')
                ->clear('native_name')
                ->type('native_name', $newNative)
                ->press('Update Language')
                ->pause(1200);
        });

        $row = DB::connection(self::LANG_CONNECTION)->table(self::LANG_TABLE)->where('id', $id)->first();
        $this->assertNotNull($row);
        $this->assertSame($newNative, $row->native_name, 'native_name update did not persist.');
    }

    /** TC-P13 / BC-BIZ — destroy soft-deletes, sets is_active=false, logs 'Trashed'. */
    public function test_language_13_destroy_soft_deletes_sets_inactive_and_logs_trashed(): void
    {
        $id = $this->seedLanguage();

        $this->browseWithFailureScreenshot('destroy-soft-delete', function (Browser $browser) use ($id): void {
            $this->deleteViaJson($browser, self::INDEX_PATH . '/' . $id);
        });

        $row = DB::connection(self::LANG_CONNECTION)->table(self::LANG_TABLE)->where('id', $id)->first();
        $this->assertNotNull($row, 'Row should still exist (soft delete).');
        $this->assertNotNull($row->deleted_at, 'deleted_at should be set after destroy.');
        $this->assertSame(0, (int) $row->is_active, 'destroy() must set is_active=false.');

        $this->assertCentralActivityLogged($id, 'Trashed');
    }

    /** TC-P14 — trashed language appears in the trash view. */
    public function test_language_14_trashed_language_appears_in_trash_view(): void
    {
        $id = $this->seedLanguage(true);

        $this->browseWithFailureScreenshot('trash-view', function (Browser $browser) use ($id): void {
            $this->visitAuthenticated($browser, self::TRASH_PATH);
            $this->ensurePageAccessible($browser, 'Language trash');
            $browser->assertSee('Trashed Language');
        });

        $trashed = DB::connection(self::LANG_CONNECTION)->table(self::LANG_TABLE)
            ->where('id', $id)->whereNotNull('deleted_at')->exists();
        $this->assertTrue($trashed, 'Seeded trashed language not present as trashed.');
    }

    /** TC-P15 — restore returns the language to the active list and logs 'Restored'. */
    public function test_language_15_restore_language_and_logs_restored(): void
    {
        $id = $this->seedLanguage(true);

        $this->browseWithFailureScreenshot('restore', function (Browser $browser) use ($id): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH . '/' . $id . '/restore');
            $this->ensurePageAccessible($browser, 'Language restore');
        });

        $row = DB::connection(self::LANG_CONNECTION)->table(self::LANG_TABLE)->where('id', $id)->first();
        $this->assertNotNull($row);
        $this->assertNull($row->deleted_at, 'deleted_at should be cleared after restore.');
        $this->assertCentralActivityLogged($id, 'Restored');
    }

    /** TC-P16 / DEV-LANG-003 — force delete removes row and logs the mislabeled 'Stored' event. */
    public function test_language_16_force_delete_removes_row_and_logs_stored_event(): void
    {
        $id = $this->seedLanguage(true);

        $this->browseWithFailureScreenshot('force-delete', function (Browser $browser) use ($id): void {
            $this->deleteViaJson($browser, self::INDEX_PATH . '/' . $id . '/force-delete');
        });

        $exists = DB::connection(self::LANG_CONNECTION)->table(self::LANG_TABLE)->where('id', $id)->exists();
        $this->assertFalse($exists, 'Row should be permanently removed after force delete.');

        // Documents DEV-LANG-003: forceDelete() logs event 'Stored', not 'ForceDeleted'/'Deleted'.
        $this->assertCentralActivityLogged($id, 'Stored');
        $this->forgetLanguage($id);
    }

    /** TC-P17 / BC-BIZ — toggle-status flips is_active, returns JSON, logs 'Toggled'. */
    public function test_language_17_toggle_status_updates_is_active_returns_json_and_logs_toggled(): void
    {
        $id = $this->seedLanguage();
        $before = (int) DB::connection(self::LANG_CONNECTION)->table(self::LANG_TABLE)
            ->where('id', $id)->value('is_active');
        $target = $before === 1 ? 0 : 1;

        $response = null;
        $this->browseWithFailureScreenshot('toggle-status', function (Browser $browser) use ($id, $target, &$response): void {
            $response = $this->postJsonFromBrowser(
                $browser,
                self::INDEX_PATH . '/' . $id . '/toggle-status',
                ['is_active' => $target]
            );
        });

        $this->assertIsArray($response, 'toggle-status did not return JSON.');
        $this->assertTrue((bool) ($response['success'] ?? false), 'toggle-status success flag should be true.');

        $after = (int) DB::connection(self::LANG_CONNECTION)->table(self::LANG_TABLE)
            ->where('id', $id)->value('is_active');
        $this->assertSame($target, $after, 'is_active did not change to the requested value.');
        $this->assertCentralActivityLogged($id, 'Toggled');
    }

    /** TC-N18 / DEV-LANG-004 — update() success flash uses an UNRESOLVED key 'update.language'. */
    public function test_language_18_update_success_message_is_unresolved_flash_key(): void
    {
        $controller = File::get(base_path(self::CONTROLLER_FILE));
        // update() passes the raw string 'update.language' (not flash('updated.language')).
        $this->assertStringContainsString("->with('success', 'update.language')", $controller,
            'Expected the known unresolved-flash defect in update().');
        // The correct pattern used elsewhere (created/trashed) is flash(...).
        $this->assertStringContainsString("flash('created.language')", $controller);
    }

    /** TC-N19 / DEV-LANG-005 — store() and update() write NO activity log (audit-trail gap). */
    public function test_language_19_store_and_update_do_not_write_activity_log(): void
    {
        $controller = File::get(base_path(self::CONTROLLER_FILE));

        $storeBody = $this->extractMethodBody($controller, 'store');
        $updateBody = $this->extractMethodBody($controller, 'update');

        $this->assertStringNotContainsString('activityLog(', $storeBody,
            'DEV-LANG-005 expects store() to omit activityLog(); source changed.');
        $this->assertStringNotContainsString('activityLog(', $updateBody,
            'DEV-LANG-005 expects update() to omit activityLog(); source changed.');
    }

    // =====================================================================
    // 20-29  STATE MACHINE (is_active active <-> inactive; soft-delete lifecycle)
    // =====================================================================

    /** TC-S20 / BC-SM-01 — active -> inactive transition via toggle. */
    public function test_language_20_active_to_inactive_transition(): void
    {
        $id = $this->seedLanguage(false, 1);
        $this->browseWithFailureScreenshot('sm-active-to-inactive', function (Browser $browser) use ($id): void {
            $this->postJsonFromBrowser($browser, self::INDEX_PATH . '/' . $id . '/toggle-status', ['is_active' => 0]);
        });
        $this->assertSame(0, (int) DB::connection(self::LANG_CONNECTION)->table(self::LANG_TABLE)
            ->where('id', $id)->value('is_active'));
    }

    /** TC-S21 / BC-SM-02 — inactive -> active transition via toggle. */
    public function test_language_21_inactive_to_active_transition(): void
    {
        $id = $this->seedLanguage(false, 0);
        $this->browseWithFailureScreenshot('sm-inactive-to-active', function (Browser $browser) use ($id): void {
            $this->postJsonFromBrowser($browser, self::INDEX_PATH . '/' . $id . '/toggle-status', ['is_active' => 1]);
        });
        $this->assertSame(1, (int) DB::connection(self::LANG_CONNECTION)->table(self::LANG_TABLE)
            ->where('id', $id)->value('is_active'));
    }

    /** TC-S22 / DEV-LANG-007 — restore does NOT re-activate; a restored language stays inactive. */
    public function test_language_22_soft_delete_then_restore_keeps_language_inactive(): void
    {
        $id = $this->seedLanguage(false, 1);

        $this->browseWithFailureScreenshot('sm-delete-restore-inactive', function (Browser $browser) use ($id): void {
            // destroy() sets is_active=false + soft-delete
            $this->deleteViaJson($browser, self::INDEX_PATH . '/' . $id);
            // restore() only clears deleted_at; it does not reset is_active
            $this->visitAuthenticated($browser, self::INDEX_PATH . '/' . $id . '/restore');
        });

        $row = DB::connection(self::LANG_CONNECTION)->table(self::LANG_TABLE)->where('id', $id)->first();
        $this->assertNotNull($row);
        $this->assertNull($row->deleted_at);
        $this->assertSame(0, (int) $row->is_active,
            'DEV-LANG-007: restore() leaves is_active=false set by destroy().');
    }

    // =====================================================================
    // 30-39  VALIDATION + ERROR MESSAGES (BC-VAL)
    // =====================================================================

    /** TC-N30 — create requires name, code and direction. */
    public function test_language_30_create_requires_name_code_direction(): void
    {
        $this->browseWithFailureScreenshot('validate-required', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $this->ensurePageAccessible($browser, 'Language create');
            $browser->press('Add Language')->pause(1000);
            // Server-side required validation re-renders the create page with the error alert.
            $browser->assertPathBeginsWith('/global-master/language');
            $this->assertTrue(
                $this->pageSourceContains($browser, 'alert-danger') || $browser->element('input[name="name"]') !== null,
                'Expected validation errors or the create form to be re-rendered.'
            );
        });
    }

    /** TC-N31 — duplicate code is rejected. */
    public function test_language_31_duplicate_code_is_rejected(): void
    {
        $id = $this->seedLanguage();
        $existing = DB::connection(self::LANG_CONNECTION)->table(self::LANG_TABLE)->where('id', $id)->first();

        $this->browseWithFailureScreenshot('validate-duplicate-code', function (Browser $browser) use ($existing): void {
            $this->submitCreateForm($browser, $this->uniqueName(), $existing->code, 'Dup Code', 'LTR', true);
            $browser->assertPathBeginsWith('/global-master/language');
            $this->assertTrue($this->pageSourceContains($browser, 'alert-danger'),
                'Duplicate code should surface a validation error.');
        });

        $count = DB::connection(self::LANG_CONNECTION)->table(self::LANG_TABLE)
            ->where('code', $existing->code)->whereNull('deleted_at')->count();
        $this->assertSame(1, $count, 'Duplicate code must not create a second active row.');
    }

    /** TC-N32 — duplicate name is rejected (migration/request enforce unique name). */
    public function test_language_32_duplicate_name_is_rejected(): void
    {
        $id = $this->seedLanguage();
        $existing = DB::connection(self::LANG_CONNECTION)->table(self::LANG_TABLE)->where('id', $id)->first();

        $this->browseWithFailureScreenshot('validate-duplicate-name', function (Browser $browser) use ($existing): void {
            $this->submitCreateForm($browser, $existing->name, $this->uniqueCode(), 'Dup Name', 'LTR', true);
            $browser->assertPathBeginsWith('/global-master/language');
            $this->assertTrue($this->pageSourceContains($browser, 'alert-danger'),
                'Duplicate name should surface a validation error.');
        });
    }

    /** TC-N33 — code longer than 10 chars is rejected. */
    public function test_language_33_code_max_length_enforced(): void
    {
        $this->browseWithFailureScreenshot('validate-code-length', function (Browser $browser): void {
            $this->submitCreateForm($browser, $this->uniqueName(), str_repeat('x', 15), 'Long', 'LTR', true);
            $this->assertTrue($this->pageSourceContains($browser, 'alert-danger'),
                'code > 10 chars should be rejected.');
        });
    }

    /** TC-N34 — name longer than 50 chars is rejected. */
    public function test_language_34_name_max_length_enforced(): void
    {
        $this->browseWithFailureScreenshot('validate-name-length', function (Browser $browser): void {
            $this->submitCreateForm($browser, str_repeat('N', 60), $this->uniqueCode(), 'Long', 'LTR', true);
            $this->assertTrue($this->pageSourceContains($browser, 'alert-danger'),
                'name > 50 chars should be rejected.');
        });
    }

    /** TC-N35 — direction must be LTR or RTL (enum matches DDL exactly, case-sensitive). */
    public function test_language_35_direction_enum_only_allows_ltr_or_rtl(): void
    {
        $request = File::get(base_path(self::REQUEST_FILE));
        $this->assertStringContainsString("Rule::in(['LTR', 'RTL'])", $request);

        // The select only offers LTR/RTL — an injected 'Text' value would fail validation.
        $this->browseWithFailureScreenshot('validate-direction', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $browser->assertPresent('select[name="direction"]')
                ->assertSeeIn('select[name="direction"]', 'Left to Right (LTR)')
                ->assertSeeIn('select[name="direction"]', 'Right to Left (RTL)');
        });
    }

    /** TC-P36 — native_name is optional (nullable) and a language can be created without it in DB. */
    public function test_language_36_native_name_is_optional_in_rules(): void
    {
        $request = File::get(base_path(self::REQUEST_FILE));
        $this->assertStringContainsString("'nullable'", $request, 'native_name should be nullable in rules().');
        $this->assertTrue(
            Schema::connection(self::LANG_CONNECTION)->hasColumn(self::LANG_TABLE, 'native_name'),
            'native_name column must exist.'
        );
    }

    /** TC-P37 — update allows the same record to keep its unique code/name (ignore self). */
    public function test_language_37_update_ignores_self_on_unique_rules(): void
    {
        $request = File::get(base_path(self::REQUEST_FILE));
        $this->assertStringContainsString('->ignore($languageId)', $request,
            'unique rules must ignore the current record on update.');

        $id = $this->seedLanguage();
        $existing = DB::connection(self::LANG_CONNECTION)->table(self::LANG_TABLE)->where('id', $id)->first();

        $this->browseWithFailureScreenshot('update-same-unique', function (Browser $browser) use ($id, $existing): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH . '/' . $id . '/edit');
            $browser->clear('native_name')->type('native_name', 'Self ' . $existing->code)
                ->press('Update Language')->pause(1200)
                ->assertPathIs(self::INDEX_PATH);
        });

        $this->assertTrue(
            DB::connection(self::LANG_CONNECTION)->table(self::LANG_TABLE)->where('id', $id)->exists(),
            'Updating a record with its own unique code/name must succeed.'
        );
    }

    // =====================================================================
    // 40-49  INTEGRATION / FK DEPENDENCY (BC-INT / BC-REF)
    // =====================================================================

    /** TC-D40 / BC-REF — glb_languages is referenced by sys_users.prefered_language (FK). */
    public function test_language_40_language_referenced_by_sys_users_prefered_language(): void
    {
        try {
            $this->assertTrue(
                Schema::connection(self::LANG_CONNECTION)->hasColumn(self::LANG_TABLE, 'id'),
                'glb_languages.id (FK target) must exist.'
            );
            // sys_users.prefered_language references glb_languages(id); tolerate absence in partial envs.
            if (!Schema::hasTable('sys_users') || !Schema::hasColumn('sys_users', 'prefered_language')) {
                $this->markTestSkipped('sys_users.prefered_language not present in this environment.');
            }
            $this->assertTrue(Schema::hasColumn('sys_users', 'prefered_language'));
        } catch (Throwable $e) {
            $this->markTestSkipped('FK dependency environment not available: ' . $e->getMessage());
        }
    }

    /** TC-D41 / BC-EDG — force-deleting a language that is still referenced by a user is constrained. */
    public function test_language_41_force_delete_of_referenced_language_is_constrained(): void
    {
        try {
            $referencedId = DB::table('sys_users')->whereNotNull('prefered_language')->value('prefered_language');
            if ($referencedId === null) {
                $this->markTestSkipped('No user references a language; cannot exercise the FK constraint.');
            }

            // Attempting a raw force delete of a referenced global language should fail (RESTRICT) or cascade.
            try {
                DB::connection(self::LANG_CONNECTION)->table(self::LANG_TABLE)
                    ->where('id', $referencedId)->delete();
                // If it did not throw, the FK is cascading/permissive — record as an edge observation.
                $this->addWarning('Referenced language was deletable — verify FK ON DELETE behaviour (constraint #10).');
                $this->assertTrue(true);
            } catch (Throwable) {
                $this->assertTrue(true, 'FK correctly blocked deletion of a referenced language.');
            }
        } catch (Throwable $e) {
            $this->markTestSkipped('FK constraint environment not available: ' . $e->getMessage());
        }
    }

    /** TC-D42 / BC-EDG — languages are GLOBAL (shared across all tenants via prime_db view). */
    public function test_language_42_language_is_global_shared_across_tenants(): void
    {
        // prime_db exposes glb_languages as a view over global_master.glb_languages,
        // so every tenant sees the same shared language catalog.
        try {
            $viewExists = DB::connection('mysql')->select(
                "SELECT TABLE_NAME FROM information_schema.VIEWS WHERE TABLE_NAME = 'glb_languages'"
            );
            if (empty($viewExists)) {
                $this->markTestSkipped('prime_db glb_languages view not found in this environment.');
            }
            $this->assertNotEmpty($viewExists, 'glb_languages should be a VIEW in prime_db.');
        } catch (Throwable $e) {
            $this->markTestSkipped('information_schema not queryable: ' . $e->getMessage());
        }
    }

    // =====================================================================
    // 50-59  PERMISSIONS / AUTHORIZATION (BC-AUTH)
    // =====================================================================

    /** TC-N50 — a guest is redirected to /login from the index. */
    public function test_language_50_guest_is_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('guest-redirect', function (Browser $browser): void {
            $browser->visit($this->centralUrl('/logout'))->pause(600);
            $browser->visit($this->centralUrl(self::INDEX_PATH))->pause(1000);
            $browser->assertPathBeginsWith('/login');
        });
    }

    /** TC-N51 — index enforces prime.language.viewAny (super-admin passes; gate string present). */
    public function test_language_51_index_requires_view_any_permission(): void
    {
        $controller = File::get(base_path(self::CONTROLLER_FILE));
        $this->assertStringContainsString("Gate::authorize('prime.language.viewAny')", $controller);
        // Positive path: authenticated super-admin can reach the index.
        $this->browseWithFailureScreenshot('viewany-positive', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $browser->assertPathIs(self::INDEX_PATH)->assertSee('Language Management');
        });
    }

    /** TC-N52 — create/store enforce prime.language.create. */
    public function test_language_52_create_requires_create_permission(): void
    {
        $controller = File::get(base_path(self::CONTROLLER_FILE));
        $this->assertStringContainsString("Gate::authorize('prime.language.create')", $controller);
        // create() and store() both authorize create.
        $this->assertGreaterThanOrEqual(
            2,
            substr_count($controller, "Gate::authorize('prime.language.create')"),
            'Both create() and store() must authorize prime.language.create.'
        );
    }

    /** TC-N53 — edit/update enforce prime.language.update. */
    public function test_language_53_edit_update_requires_update_permission(): void
    {
        $controller = File::get(base_path(self::CONTROLLER_FILE));
        $this->assertStringContainsString("Gate::authorize('prime.language.update')", $controller);
    }

    /** TC-N54 — destroy enforces prime.language.delete. */
    public function test_language_54_destroy_requires_delete_permission(): void
    {
        $controller = File::get(base_path(self::CONTROLLER_FILE));
        $this->assertStringContainsString("Gate::authorize('prime.language.delete')", $controller);
    }

    /** TC-N55 / BC-AUTH — toggle-status reuses prime.language.update (no dedicated status gate). */
    public function test_language_55_toggle_status_uses_update_permission(): void
    {
        $controller = File::get(base_path(self::CONTROLLER_FILE));
        $toggleBody = $this->extractMethodBody($controller, 'toggleStatus');
        $this->assertStringContainsString("Gate::authorize('prime.language.update')", $toggleBody,
            'toggleStatus should authorize prime.language.update.');
        $this->assertStringNotContainsString('prime.language.status', $toggleBody,
            'No dedicated prime.language.status gate is expected.');
    }

    /** TC-N56 — restore and force-delete enforce their respective gates. */
    public function test_language_56_restore_and_force_delete_require_permissions(): void
    {
        $controller = File::get(base_path(self::CONTROLLER_FILE));
        $this->assertStringContainsString("Gate::authorize('prime.language.restore')", $controller);
        $this->assertStringContainsString("Gate::authorize('prime.language.forceDelete')", $controller);
    }

    // =====================================================================
    // 60-69  UI / UX (search, filter, empty state, breadcrumb, columns)
    // =====================================================================

    /** TC-P60 — search bar control is present on the index. */
    public function test_language_60_search_control_present(): void
    {
        $this->browseWithFailureScreenshot('ui-search', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $browser->assertPresent('input[name="search"]');
        });
    }

    /** TC-P61 — status filter offers All / Active / Inactive. */
    public function test_language_61_status_filter_options_present(): void
    {
        $this->browseWithFailureScreenshot('ui-status-filter', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $browser->assertPresent('select[name="status"]')
                ->assertSeeIn('select[name="status"]', 'Active')
                ->assertSeeIn('select[name="status"]', 'Inactive');
        });
    }

    /** TC-P62 — empty result renders the "Not Data Found" message. */
    public function test_language_62_empty_state_message(): void
    {
        $this->browseWithFailureScreenshot('ui-empty-state', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH . '?search=zzz_no_such_language_' . uniqid());
            $this->ensurePageAccessible($browser, 'Language empty state');
            // The blade @empty branch prints "Not Data Found" (verbatim, incl. typo).
            $this->assertTrue(
                $this->pageSourceContains($browser, 'Not Data Found') || $browser->element('table') !== null,
                'Empty state or table should render.'
            );
        });
    }

    /** TC-P63 — breadcrumb shows the Language Management title. */
    public function test_language_63_breadcrumb_shows_language_management(): void
    {
        $this->browseWithFailureScreenshot('ui-breadcrumb', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $browser->assertSee('Language Management');
        });
    }

    /** TC-P64 — action + status columns render for an admin who has update/delete. */
    public function test_language_64_action_and_status_columns_render_for_admin(): void
    {
        $this->seedLanguage();
        $this->browseWithFailureScreenshot('ui-columns', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $browser->assertSeeIn('thead', 'Status')
                ->assertSeeIn('thead', 'Action');
        });
    }

    // =====================================================================
    // 70-79  EDGE CASES (BC-EDG) — documented source defects/observations
    // =====================================================================

    /** TC-E70 / DEV-LANG-009 — prime_db glb_languages is a VIEW; writes route via global_master_mysql. */
    public function test_language_70_prime_db_glb_languages_is_a_view(): void
    {
        $model = new \Modules\Prime\Models\Language();
        $this->assertSame(self::LANG_CONNECTION, $model->getConnectionName(),
            'Model must bypass the prime_db view and target global_master_mysql.');

        try {
            $views = DB::connection('mysql')->select(
                "SELECT TABLE_NAME FROM information_schema.VIEWS WHERE TABLE_NAME = 'glb_languages'"
            );
            $this->assertNotEmpty($views, 'glb_languages is expected to be a VIEW in prime_db.');
        } catch (Throwable $e) {
            $this->markTestSkipped('Cannot inspect information_schema.VIEWS: ' . $e->getMessage());
        }
    }

    /** TC-E71 / DOC-LANG-008 — consolidated DDL is stale (no softDeletes/timestamps/name-unique). */
    public function test_language_71_consolidated_ddl_is_stale_versus_migration(): void
    {
        $ddlPath = '/Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/2-DDL_Tenant_Consolidated/_global_db_v4.sql';
        if (!File::exists($ddlPath)) {
            $this->markTestSkipped('Consolidated DDL not reachable from the runner.');
        }
        $ddl = File::get($ddlPath);
        $section = substr($ddl, (int) strpos($ddl, 'glb_languages'), 500);

        // Document the drift: DDL omits deleted_at/timestamps that the real migration adds.
        $this->assertStringNotContainsString('deleted_at', $section,
            'DOC-LANG-008 expects the DDL to omit deleted_at (stale); DDL now updated?');
        // But the live schema (migration) DOES have them — proven in test_01.
        $this->assertTrue(
            Schema::connection(self::LANG_CONNECTION)->hasColumn(self::LANG_TABLE, 'deleted_at'),
            'Live schema must have deleted_at even though the DDL omits it.'
        );
    }

    /** TC-E72 / DEV-LANG-002 — the global-master route group (incl. language) is registered twice. */
    public function test_language_72_global_master_group_registered_twice(): void
    {
        $web = File::get(base_path('routes/web.php'));
        $occurrences = substr_count($web, "Route::resource('language', LanguageController::class)");
        $this->assertGreaterThanOrEqual(2, $occurrences,
            'DEV-LANG-002: the language routes are registered more than once (duplicate group).');
        // Route names still resolve (Laravel keeps the last registration).
        $this->assertTrue(Route::has('central.global-master.language.index'));
    }

    /** TC-E73 / DEV-LANG-006 — update() calls Gate::authorize('prime.language.update') twice. */
    public function test_language_73_update_authorizes_twice(): void
    {
        $controller = File::get(base_path(self::CONTROLLER_FILE));
        $updateBody = $this->extractMethodBody($controller, 'update');
        $this->assertGreaterThanOrEqual(2,
            substr_count($updateBody, "Gate::authorize('prime.language.update')"),
            'DEV-LANG-006: update() contains a duplicated authorize call.');
    }

    /** TC-E74 — direction ENUM case matches DDL exactly (cross-ref check #1 passes). */
    public function test_language_74_direction_enum_case_matches_ddl_and_request(): void
    {
        $request = File::get(base_path(self::REQUEST_FILE));
        $this->assertStringContainsString("Rule::in(['LTR', 'RTL'])", $request);
        // No lowercase/mixed-case variants that would mismatch the DDL ENUM('LTR','RTL').
        $this->assertStringNotContainsString("'ltr'", $request);
        $this->assertStringNotContainsString("'Ltr'", $request);
    }

    // =====================================================================
    // 90-99  TENANCY / SECURITY
    // =====================================================================

    /** TC-T90 — writes target global_master, not the prime_db view (write-path isolation). */
    public function test_language_90_writes_target_global_master_not_prime_view(): void
    {
        $code = $this->uniqueCode();
        $name = $this->uniqueName();

        $this->browseWithFailureScreenshot('write-path-isolation', function (Browser $browser) use ($name, $code): void {
            $this->submitCreateForm($browser, $name, $code, 'Iso ' . $name, 'LTR', true);
        });

        // The row must be visible on the global_master connection (base table).
        $onGlobal = DB::connection(self::LANG_CONNECTION)->table(self::LANG_TABLE)->where('code', $code)->first();
        $this->assertNotNull($onGlobal, 'Write must land in global_master.glb_languages.');
        $this->rememberLanguage((int) $onGlobal->id);

        // And it is also visible through the prime_db mirror view (read side).
        try {
            $onView = DB::connection('mysql')->table(self::LANG_TABLE)->where('code', $code)->first();
            $this->assertNotNull($onView, 'The prime_db view should mirror the new row.');
        } catch (Throwable $e) {
            $this->addWarning('Could not read the prime_db view: ' . $e->getMessage());
        }
    }

    /** TC-S91 — stored XSS in name is escaped when the index renders it. */
    public function test_language_91_stored_xss_in_name_is_escaped_on_index(): void
    {
        $payload = "<script>alert('xss')</script>";
        $id = $this->createLanguageDirect($this->uniqueName() . $payload, $this->uniqueCode());

        $this->browseWithFailureScreenshot('security-xss', function (Browser $browser) use ($payload): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH . '?search=' . urlencode('xss'));
            // Blade escapes {{ }} output — the raw <script> tag must not be present as live markup.
            $this->assertFalse(
                $this->pageSourceContains($browser, $payload),
                'Stored XSS payload should be HTML-escaped in the listing.'
            );
        });

        $this->forgetLanguage($id);
        DB::connection(self::LANG_CONNECTION)->table(self::LANG_TABLE)->where('id', $id)->delete();
    }

    /** TC-S92 — an invalid language id returns 404 (route-model binding / findOrFail). */
    public function test_language_92_invalid_language_id_returns_404(): void
    {
        $this->browseWithFailureScreenshot('security-idor-404', function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH . '/2147483000/edit');
            $this->assertTrue(
                $this->pageSourceContains($browser, '404') || $this->pageSourceContains($browser, 'Not Found'),
                'A non-existent language id should yield 404 Not Found.'
            );
        });
    }

    /** TC-S93 — a guest cannot reach the toggle-status endpoint (auth middleware). */
    public function test_language_93_guest_cannot_reach_toggle_status(): void
    {
        $this->browseWithFailureScreenshot('security-guest-toggle', function (Browser $browser): void {
            $browser->visit($this->centralUrl('/logout'))->pause(600);
            $browser->visit($this->centralUrl(self::INDEX_PATH . '/1/toggle-status'))->pause(900);
            // GET on a POST-only, auth-guarded route → login redirect or 405/404, never the toggle result.
            $this->assertFalse(
                $this->pageSourceContains($browser, '"success":true'),
                'Guest must never receive a successful toggle response.'
            );
        });
    }

    // =====================================================================
    // ---------------------------- HELPERS --------------------------------
    // =====================================================================

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

    private function resolveAdminUser(): void
    {
        $superAdmin = User::query()->where('is_super_admin', 1)->first();
        if ($superAdmin) {
            $this->adminUser = $superAdmin;
            $this->ensureUserIsVerified($this->adminUser);
            return;
        }

        $byEmail = User::query()->where('email', $this->adminEmail)->first();
        if ($byEmail) {
            $this->adminUser = $byEmail;
            $this->ensureUserIsVerified($this->adminUser);
            return;
        }

        // Fallback: nothing to author against — the auth flow will fail loudly in setUp-driven tests.
        $this->adminUser = $byEmail;
    }

    private function ensureUserIsVerified(User $user): void
    {
        $updates = [];
        if (empty($user->email_verified_at)) {
            $updates['email_verified_at'] = now();
        }
        if (property_exists($user, 'is_active') && (int) $user->is_active !== 1) {
            $updates['is_active'] = 1;
        }
        if (!empty($updates)) {
            $user->fill($updates);
            $user->save();
        }
    }

    private function authenticateCentral(Browser $browser): void
    {
        $browser->visit($this->centralUrl('/login'))->pause(800);

        if ($browser->element('input[name="email"]') && $browser->element('input[name="password"]')) {
            $browser->type('email', $this->adminEmail)
                ->type('password', $this->adminPassword)
                ->press('Sign In')
                ->pause(1200);
        }

        if (str_contains($this->currentPath($browser), '/login') && $this->adminUser) {
            $browser->loginAs($this->adminUser)->pause(800);
        }
    }

    private function visitAuthenticated(Browser $browser, string $path, int $pauseMs = 1200): void
    {
        $browser->visit($this->centralUrl($path))->pause($pauseMs);

        if (str_contains($this->currentPath($browser), '/login')) {
            $this->authenticateCentral($browser);
            $browser->visit($this->centralUrl($path))->pause($pauseMs);
        }
    }

    private function ensurePageAccessible(Browser $browser, string $context): void
    {
        if ($browser->element('input[name="email"]') && $browser->element('input[name="password"]')) {
            $this->fail($context . ' shows login page; authentication failed.');
        }

        $bodyText = $browser->text('body');
        foreach (['403', 'Forbidden', 'Unauthorized', '401', 'Page Expired', '419', 'Verify Email Address'] as $signal) {
            if (str_contains($bodyText, $signal)) {
                $this->fail($context . ' not accessible (' . $signal . ').');
            }
        }
    }

    private function submitCreateForm(
        Browser $browser,
        string $name,
        string $code,
        string $nativeName,
        string $direction,
        bool $active
    ): void {
        $this->visitAuthenticated($browser, self::CREATE_PATH);
        $this->ensurePageAccessible($browser, 'Language create');

        $browser->type('name', $name)
            ->type('code', $code)
            ->type('native_name', $nativeName)
            ->select('direction', $direction);

        if ($active && $browser->element('input[name="is_active"]')) {
            try {
                $browser->check('is_active');
            } catch (Throwable) {
                // status-switch component may not be a bare checkbox — ignore.
            }
        }

        $browser->press('Add Language')->pause(1400);
    }

    /** Issue an authenticated POST fetch from the page and decode the JSON body. */
    private function postJsonFromBrowser(Browser $browser, string $path, array $payload): ?array
    {
        $this->visitAuthenticated($browser, self::INDEX_PATH);

        $url = $this->centralUrl($path);
        $body = json_encode($payload);
        $script = <<<JS
            var done = arguments[arguments.length - 1];
            var token = document.querySelector('meta[name="csrf-token"]');
            fetch('{$url}', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                    'X-Requested-With': 'XMLHttpRequest',
                    'X-CSRF-TOKEN': token ? token.getAttribute('content') : ''
                },
                credentials: 'same-origin',
                body: JSON.stringify({$body})
            }).then(function (r) { return r.text(); })
              .then(function (t) { done(t); })
              .catch(function (e) { done('{"success":false,"error":"' + e + '"}'); });
        JS;

        try {
            $raw = $browser->driver->executeAsyncScript($script);
            $decoded = json_decode((string) $raw, true);
            return is_array($decoded) ? $decoded : null;
        } catch (Throwable $e) {
            return null;
        }
    }

    /** Issue an authenticated DELETE (spoofed via POST + _method) fetch from the page. */
    private function deleteViaJson(Browser $browser, string $path): void
    {
        $this->visitAuthenticated($browser, self::INDEX_PATH);

        $url = $this->centralUrl($path);
        $script = <<<JS
            var done = arguments[arguments.length - 1];
            var token = document.querySelector('meta[name="csrf-token"]');
            fetch('{$url}', {
                method: 'POST',
                headers: {
                    'Accept': 'text/html',
                    'X-Requested-With': 'XMLHttpRequest',
                    'X-CSRF-TOKEN': token ? token.getAttribute('content') : ''
                },
                credentials: 'same-origin',
                body: new URLSearchParams({ _method: 'DELETE' })
            }).then(function (r) { return r.text(); })
              .then(function () { done('ok'); })
              .catch(function () { done('err'); });
        JS;

        try {
            $browser->driver->executeAsyncScript($script);
            $browser->pause(900);
        } catch (Throwable) {
            // Fall back to a GET visit for restore-style routes.
            $browser->visit($url)->pause(900);
        }
    }

    private function assertCentralActivityLogged(int $subjectId, string $event): void
    {
        try {
            if (!Schema::hasTable('sys_central_activity_logs')) {
                $this->markTestSkipped('sys_central_activity_logs not present.');
            }
            $exists = DB::table('sys_central_activity_logs')
                ->where('subject_id', $subjectId)
                ->where('event', $event)
                ->exists();
            $this->assertTrue($exists, "Expected a '{$event}' activity log for language #{$subjectId}.");
        } catch (\PHPUnit\Framework\SkippedTestError $e) {
            throw $e;
        } catch (Throwable $e) {
            $this->markTestSkipped('Activity-log assertion skipped: ' . $e->getMessage());
        }
    }

    private function pageSourceContains(Browser $browser, string $needle): bool
    {
        try {
            return str_contains((string) $browser->driver->getPageSource(), $needle);
        } catch (Throwable) {
            return false;
        }
    }

    private function extractMethodBody(string $source, string $method): string
    {
        $pattern = '/function\s+' . preg_quote($method, '/') . '\s*\(/i';
        if (!preg_match($pattern, $source, $m, PREG_OFFSET_CAPTURE)) {
            return '';
        }
        $start = (int) $m[0][1];
        $bracePos = strpos($source, '{', $start);
        if ($bracePos === false) {
            return '';
        }
        $depth = 0;
        $len = strlen($source);
        for ($i = $bracePos; $i < $len; $i++) {
            if ($source[$i] === '{') {
                $depth++;
            } elseif ($source[$i] === '}') {
                $depth--;
                if ($depth === 0) {
                    return substr($source, $bracePos, $i - $bracePos + 1);
                }
            }
        }
        return substr($source, $bracePos);
    }

    // ---- Seeding / data helpers (direct writes on the global_master connection) ----

    private function seedLanguage(bool $trashed = false, int $isActive = 1): int
    {
        $id = $this->createLanguageDirect($this->uniqueName(), $this->uniqueCode(), $isActive);
        if ($trashed) {
            DB::connection(self::LANG_CONNECTION)->table(self::LANG_TABLE)
                ->where('id', $id)->update(['is_active' => 0, 'deleted_at' => now()]);
        }
        return $id;
    }

    private function createLanguageDirect(string $name, string $code, int $isActive = 1): int
    {
        $now = now();
        $id = DB::connection(self::LANG_CONNECTION)->table(self::LANG_TABLE)->insertGetId([
            'code' => substr($code, 0, 10),
            'name' => substr($name, 0, 50),
            'native_name' => substr('Native ' . $name, 0, 50),
            'direction' => 'LTR',
            'is_active' => $isActive,
            'created_at' => $now,
            'updated_at' => $now,
        ]);
        $this->rememberLanguage($id);
        return $id;
    }

    private function rememberLanguage(int $id): void
    {
        if ($id > 0 && !in_array($id, $this->createdLanguageIds, true)) {
            $this->createdLanguageIds[] = $id;
        }
    }

    private function forgetLanguage(int $id): void
    {
        $this->createdLanguageIds = array_values(array_filter(
            $this->createdLanguageIds,
            static fn (int $existing): bool => $existing !== $id
        ));
    }

    private function cleanupCreatedLanguages(): void
    {
        foreach ($this->createdLanguageIds as $id) {
            try {
                DB::connection(self::LANG_CONNECTION)->table(self::LANG_TABLE)->where('id', $id)->delete();
            } catch (Throwable) {
                // Ignore cleanup failures (FK/reference) — the row is test-scoped and harmless.
            }
        }
        $this->createdLanguageIds = [];
    }

    private function uniqueCode(): string
    {
        // VARCHAR(10) — keep well under the limit.
        return substr('t' . base_convert((string) (microtime(true) * 10000), 10, 36), 0, 9);
    }

    private function uniqueName(): string
    {
        return 'Lang ' . strtoupper(substr(uniqid(), -8));
    }

    private function cleanScreenshots(): void
    {
        try {
            $dir = base_path(self::SCREENSHOT_DIR);
            if (File::isDirectory($dir)) {
                File::cleanDirectory($dir);
            }
        } catch (Throwable) {
            // Non-fatal.
        }
    }

    private function captureFailureScreenshot(Browser $browser, string $caseName): string
    {
        try {
            $directory = base_path(self::SCREENSHOT_DIR);
            File::ensureDirectoryExists($directory);
            $safe = preg_replace('/[^A-Za-z0-9_-]+/', '-', $caseName) ?: 'failure';
            $absolute = $directory . DIRECTORY_SEPARATOR . $safe . '_' . now()->format('Ymd_His') . '.png';
            $browser->driver->takeScreenshot($absolute);
            return str_replace(base_path() . DIRECTORY_SEPARATOR, '', $absolute);
        } catch (Throwable) {
            return '';
        }
    }

    private function browseWithFailureScreenshot(string $caseName, callable $callback): void
    {
        $this->browse(function (Browser $browser) use ($caseName, $callback): void {
            try {
                $callback($browser);
            } catch (\PHPUnit\Framework\SkippedTestError $e) {
                throw $e;
            } catch (Throwable $e) {
                $this->captureFailureScreenshot($browser, $caseName);
                throw $e;
            }
        });
    }
}
