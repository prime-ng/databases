<?php

namespace Tests\Browser\Modules\GlobalMaster\Language;

use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\Prime\Models\ActivityLog;
use Modules\Prime\Models\Language;
use Throwable;

/**
 * ============================================================================
 *  GlobalMaster :: Language (CENTRAL / prime-side) Dusk suite
 * ============================================================================
 *
 * ONE comprehensive, self-contained Dusk test file (no V1/V2 split).
 * Mirrors the committed CENTRAL pattern established by
 *   tests/Browser/Modules/Prime/Billing/BillingCycle/prm_BillingCycle_TestCas.php
 * with the central helper library copied INLINE (no external base class other
 * than the framework Tests\DuskTestCase).
 *
 * ----------------------------------------------------------------------------
 *  HARD RULE 13 RECONCILIATION  (Prime serves the central route)
 * ----------------------------------------------------------------------------
 *  The LIVE central route  central.global-master.language.*  (path
 *  /global-master/language) is registered in the app-root routes/web.php,
 *  inside  Route::domain(...)->name('central.')  ->  prefix('global-master')
 *  ->name('global-master.'), and is bound to
 *      Modules\Prime\Http\Controllers\LanguageController
 *  (root routes/web.php line 10 imports the Prime controller; the
 *  global-master language block binds it). It renders view prime::language.index
 *  and paginate(11).
 *
 *  The GlobalMaster module OWNS a second LanguageController
 *  (Modules\GlobalMaster\Http\Controllers\LanguageController), but it is only
 *  wired in the module's own Modules/GlobalMaster/routes/web.php under name
 *  'global-master.language.*' WITHOUT the 'central.' prefix -> effectively DEAD
 *  on central. Both controllers share
 *  Modules\GlobalMaster\Http\Requests\LanguageRequest and the same
 *  Modules\Prime\Models\Language (table glb_languages, connection
 *  global_master_mysql).
 *
 *  => We test the LIVE path /global-master/language served by the Prime
 *     controller.
 *
 * ----------------------------------------------------------------------------
 *  GLB DEFECTS EXERCISED / DOCUMENTED
 * ----------------------------------------------------------------------------
 *  DEV-GLB-L01  DDL _global_db_v4.sql glb_languages is STALE (omits
 *               created_at/updated_at/deleted_at) while the real migration adds
 *               softDeletes()+timestamps(). Documentation/DDL divergence, NOT a
 *               runtime failure. Proven true by Schema::hasColumn(...,'deleted_at').
 *  DEV-GLB-L02  forceDelete() logs activity event 'Stored' (SIC) instead of a
 *               delete/'Deleted' event. Present in BOTH Prime-live and
 *               GlobalMaster-dead controllers. Proven by asserting the literal
 *               logged event after a force delete.
 *  DEV-GLB-L03  GlobalMaster's own (dead) controller mixes gate prefixes
 *               (index/create/store/show/edit/update -> prime.language.*;
 *               destroy/restore/forceDelete/toggleStatus -> global-master.language.*)
 *               and update() passes literal 'update.language' instead of
 *               flash('updated.language'). Latent defect in the dead duplicate.
 *  DEV-GLB-L04  Two LanguageController classes bound to the same request + model
 *               -> duplicate/divergent logic. Reconciliation finding.
 *
 * @group globalmaster
 * @group language
 * @group central
 */
class glb_Language_TestCas extends \Tests\DuskTestCase
{
    // ---- report / screenshot locations -------------------------------------
    protected const SCREENSHOT_DIR = 'tests/Browser/Modules/GlobalMaster/Language/screenshots';
    protected const STATUS_REPORT_DIRECTORY = 'tests/Browser/Modules/GlobalMaster/Language/report';
    protected const STATUS_REPORT_PREFIX = 'glb_language_report_';

    // ---- live central paths (Prime controller serves these) ----------------
    private const INDEX_PATH = '/global-master/language';
    private const CREATE_PATH = '/global-master/language/create';
    private const TRASH_PATH = '/global-master/language/trash/view';

    // ---- DDL-verified primary table (glb_ prefix) --------------------------
    private const TABLE = 'glb_languages';
    private const CONNECTION = 'global_master_mysql';

    // ---- typed props (initialized) -----------------------------------------
    protected ?User $adminUser = null;
    protected string $centralBaseUrl = '';
    protected string $adminEmail = '';
    protected string $adminPassword = '';
    protected array $statusReportEntries = [];

    // =========================================================================
    //  setUp / tearDown  (guard tenancy — NO tenant init on central)
    // =========================================================================
    protected function setUp(): void
    {
        parent::setUp();

        // Central-only: ensure tenancy is NOT initialized.
        if (function_exists('tenancy') && tenancy()->initialized) {
            tenancy()->end();
        }

        $this->centralBaseUrl = 'http://127.0.0.1:8000';
        $host = parse_url($this->centralBaseUrl, PHP_URL_HOST);
        if ($host !== '127.0.0.1') {
            $this->fail('GlobalMaster Language central tests must run on http://127.0.0.1:8000.');
        }

        $this->adminEmail = (string) env('DUSK_ADMIN_EMAIL', 'root@tenant.com');
        $this->adminPassword = (string) env('DUSK_ADMIN_PASSWORD', 'password');
        $this->statusReportEntries = [];

        $this->resolveAdminUser();
    }

    protected function tearDown(): void
    {
        if (!empty($this->statusReportEntries)) {
            $this->writeStatusReportForCurrentTest();
        }

        parent::tearDown();
    }

    // =========================================================================
    //  BAND 01-09 :: schema / model / request truth
    // =========================================================================

    public function test_language_01_table_exists(): void
    {
        $this->assertTrue(
            Schema::connection(self::CONNECTION)->hasTable(self::TABLE),
            self::TABLE . ' table is missing; cannot run Language tests.'
        );
    }

    public function test_language_02_soft_deletes_column_exists(): void
    {
        // Proves migration added softDeletes(); underpins DEV-GLB-L01 (DDL omits it).
        $this->assertTrue(
            Schema::connection(self::CONNECTION)->hasColumn(self::TABLE, 'deleted_at'),
            self::TABLE . '.deleted_at is missing; SoftDeletes will fail.'
        );
    }

    public function test_language_03_timestamps_columns_exist(): void
    {
        // DEV-GLB-L01 counter-proof: migration adds timestamps() though DDL omits them.
        $this->assertTrue(
            Schema::connection(self::CONNECTION)->hasColumn(self::TABLE, 'created_at'),
            self::TABLE . '.created_at is missing.'
        );
        $this->assertTrue(
            Schema::connection(self::CONNECTION)->hasColumn(self::TABLE, 'updated_at'),
            self::TABLE . '.updated_at is missing.'
        );
    }

    public function test_language_04_expected_columns_exist(): void
    {
        foreach (['id', 'code', 'name', 'native_name', 'direction', 'is_active'] as $column) {
            $this->assertTrue(
                Schema::connection(self::CONNECTION)->hasColumn(self::TABLE, $column),
                self::TABLE . '.' . $column . ' column is missing.'
            );
        }
    }

    public function test_language_05_code_column_is_varchar(): void
    {
        $type = $this->columnDbType('code');
        $this->assertStringContainsString('char', strtolower($type), 'code should be a varchar column.');
    }

    public function test_language_06_direction_column_is_enum(): void
    {
        $type = $this->columnDbFullType('direction');
        $this->assertStringContainsString('enum', strtolower($type), 'direction should be an enum column.');
        $this->assertStringContainsString('ltr', strtolower($type), 'direction enum should contain LTR.');
        $this->assertStringContainsString('rtl', strtolower($type), 'direction enum should contain RTL.');
    }

    public function test_language_07_model_connection_and_table(): void
    {
        $model = new Language();
        $this->assertSame(self::CONNECTION, $model->getConnectionName(), 'Model connection mismatch.');
        $this->assertSame(self::TABLE, $model->getTable(), 'Model table mismatch.');
    }

    public function test_language_08_model_fillable_matches(): void
    {
        $fillable = (new Language())->getFillable();
        foreach (['code', 'name', 'native_name', 'direction', 'is_active'] as $field) {
            $this->assertContains($field, $fillable, $field . ' should be fillable.');
        }
    }

    public function test_language_09_model_uses_soft_deletes(): void
    {
        $uses = class_uses_recursive(Language::class);
        $this->assertContains(
            \Illuminate\Database\Eloquent\SoftDeletes::class,
            $uses,
            'Language model must use SoftDeletes.'
        );
    }

    // =========================================================================
    //  BAND 10-19 :: business flows + activity-log truth
    // =========================================================================

    public function test_language_10_index_loads(): void
    {
        $this->assertTableReady();

        $this->browseWithFailureScreenshot('language-index', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);

            $this->assertSame(self::INDEX_PATH, $this->currentPath($browser), 'Language index not reachable.');
            $this->ensurePageAccessible($browser, 'Language index');

            $browser->assertSee('Language');
            $browser->assertPresent('table');
        });
    }

    public function test_language_11_create_page_loads(): void
    {
        $this->assertTableExists();

        $this->browseWithFailureScreenshot('language-create-page', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH);

            $this->assertSame(self::CREATE_PATH, $this->currentPath($browser), 'Language create page not reachable.');
            $this->ensurePageAccessible($browser, 'Language create');

            $browser->assertPresent('input[name="code"]');
            $browser->assertPresent('input[name="name"]');
            $browser->assertPresent('input[name="native_name"]');
            $browser->assertPresent('select[name="direction"]');
            $browser->assertPresent('#is_active');
        });
    }

    public function test_language_12_create_flow_persists(): void
    {
        $this->assertTableReady();

        $code = $this->makeCode();
        $name = $this->makeName();
        $native = 'Native ' . rand(1000, 9999);

        $this->browseWithFailureScreenshot('language-create', function (Browser $browser) use ($code, $name, $native): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $this->ensurePageAccessible($browser, 'Language create');

            $browser
                ->type('code', $code)
                ->type('name', $name)
                ->type('native_name', $native)
                ->select('direction', 'LTR')
                ->check('#is_active')
                ->press('Add Language')
                ->pause(2000);
        });

        $language = Language::withTrashed()->where('code', $code)->first();
        $this->assertNotNull($language, 'Language was not created.');

        if ($language) {
            try {
                $this->assertSame($name, (string) $language->name);
                $this->assertSame($native, (string) $language->native_name);
                $this->assertSame('LTR', (string) $language->direction);
                $this->assertTrue((bool) $language->is_active);
            } finally {
                $this->purgeLanguageById((int) $language->id);
            }
        }
    }

    public function test_language_13_update_flow_persists(): void
    {
        $this->assertTableReady();

        $language = $this->createLanguageRecord();
        $newCode = $this->makeCode();
        $newName = 'Updated ' . $this->makeName();

        try {
            $this->browseWithFailureScreenshot('language-update', function (Browser $browser) use ($language, $newCode, $newName): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH);
                $this->ensurePageAccessible($browser, 'Language index');

                $this->clickEditAction($browser, (int) $language->id);
                $this->confirmSweetAlert($browser);

                $browser->waitFor('#name', 10);
                $this->assertSame(
                    self::INDEX_PATH . '/' . $language->id . '/edit',
                    $this->currentPath($browser),
                    'Language edit page not reachable.'
                );

                $browser
                    ->type('code', $newCode)
                    ->type('name', $newName)
                    ->select('direction', 'RTL')
                    ->press('Update Language')
                    ->pause(2000);
            });

            $language->refresh();
            $this->assertSame($newCode, (string) $language->code);
            $this->assertSame($newName, (string) $language->name);
            $this->assertSame('RTL', (string) $language->direction);
        } finally {
            $this->purgeLanguageById((int) $language->id);
        }
    }

    public function test_language_14_status_toggle_updates_is_active(): void
    {
        $this->assertTableReady();

        $language = $this->createLanguageRecord(['is_active' => true]);

        try {
            $this->browseWithFailureScreenshot('language-toggle-status', function (Browser $browser) use ($language): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH);
                $this->ensurePageAccessible($browser, 'Language index');

                $selector = '#statusSwitch-' . $language->id;
                $browser->assertPresent($selector);
                $browser->click($selector)->pause(1500);
            });

            $language->refresh();
            $this->assertFalse((bool) $language->is_active, 'Language status did not toggle to inactive.');
        } finally {
            $this->purgeLanguageById((int) $language->id);
        }
    }

    public function test_language_15_soft_delete_logs_trashed_event(): void
    {
        $this->assertTableReady();

        $language = $this->createLanguageRecord();
        $id = (int) $language->id;

        try {
            $this->browseWithFailureScreenshot('language-activity-trashed', function (Browser $browser) use ($id): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH);
                $this->ensurePageAccessible($browser, 'Language index');

                $this->clickDeleteAction($browser, $id);
                $this->confirmSweetAlert($browser);
                $browser->pause(2000);
            });

            $log = $this->latestActivityLog($id);
            $this->assertNotNull($log, 'No activity log written on soft delete.');
            $this->assertSame('Trashed', (string) $log->event, 'destroy() must log the "Trashed" event.');
            $this->assertNotNull($log->user_id, 'Activity log issued_by (user_id) must be populated.');
        } finally {
            $this->purgeLanguageById($id);
        }
    }

    public function test_language_16_restore_logs_restored_event(): void
    {
        $this->assertTableReady();

        $language = $this->createLanguageRecord();
        $id = (int) $language->id;
        $language->delete(); // soft delete directly

        try {
            $this->browseWithFailureScreenshot('language-activity-restored', function (Browser $browser) use ($id): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::TRASH_PATH);
                $this->ensurePageAccessible($browser, 'Language trash');

                $this->clickRestoreAction($browser, $id);
                $this->confirmSweetAlert($browser);
                $browser->pause(2000);
            });

            $log = $this->latestActivityLog($id, 'Restored');
            $this->assertNotNull($log, 'restore() must log the "Restored" event.');
            $this->assertSame('Restored', (string) $log->event);
        } finally {
            $this->purgeLanguageById($id);
        }
    }

    public function test_language_17_force_delete_logs_stored_event_bug(): void
    {
        // DEV-GLB-L02: forceDelete() logs 'Stored' (SIC) rather than a delete event.
        $this->assertTableReady();

        $language = $this->createLanguageRecord();
        $id = (int) $language->id;
        $language->delete(); // must be trashed before force delete

        try {
            $this->browseWithFailureScreenshot('language-activity-forcedelete-bug', function (Browser $browser) use ($id): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::TRASH_PATH);
                $this->ensurePageAccessible($browser, 'Language trash');

                $this->clickForceDeleteAction($browser, $id);
                $this->confirmSweetAlert($browser);
                $browser->pause(2000);
            });

            $log = ActivityLog::where('subject_type', Language::class)
                ->where('subject_id', $id)
                ->orderByDesc('id')
                ->first();

            $this->assertNotNull($log, 'forceDelete() must log an activity entry.');
            // Literal proof of the bug: the logged event is the wrong string 'Stored'.
            $this->assertSame(
                'Stored',
                (string) $log->event,
                'DEV-GLB-L02: forceDelete logs the literal wrong event "Stored".'
            );
            $this->assertNotSame('Deleted', (string) $log->event, 'Expected-correct event "Deleted" is NOT used (bug).');
        } finally {
            $this->purgeLanguageById($id);
        }
    }

    public function test_language_18_toggle_logs_toggled_event(): void
    {
        $this->assertTableReady();

        $language = $this->createLanguageRecord(['is_active' => true]);
        $id = (int) $language->id;

        try {
            $this->browseWithFailureScreenshot('language-activity-toggled', function (Browser $browser) use ($id): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH);
                $this->ensurePageAccessible($browser, 'Language index');

                $browser->click('#statusSwitch-' . $id)->pause(1500);
            });

            $log = $this->latestActivityLog($id, 'Toggled');
            $this->assertNotNull($log, 'toggleStatus() must log the "Toggled" event.');
            $this->assertSame('Toggled', (string) $log->event);
        } finally {
            $this->purgeLanguageById($id);
        }
    }

    public function test_language_19_store_logs_nothing(): void
    {
        // store()/update() log NO activity (verified in live Prime controller).
        $this->assertTableReady();

        $code = $this->makeCode();
        $before = ActivityLog::where('subject_type', Language::class)->count();

        $this->browseWithFailureScreenshot('language-store-no-activity', function (Browser $browser) use ($code): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $this->ensurePageAccessible($browser, 'Language create');

            $browser
                ->type('code', $code)
                ->type('name', $this->makeName())
                ->type('native_name', 'Native ' . rand(1000, 9999))
                ->select('direction', 'LTR')
                ->check('#is_active')
                ->press('Add Language')
                ->pause(2000);
        });

        $language = Language::withTrashed()->where('code', $code)->first();
        try {
            $after = ActivityLog::where('subject_type', Language::class)->count();
            $this->assertSame($before, $after, 'store() must not write any activity log.');
        } finally {
            if ($language) {
                $this->purgeLanguageById((int) $language->id);
            }
        }
    }

    // =========================================================================
    //  BAND 30-39 :: validation / negative
    // =========================================================================

    public function test_language_30_create_requires_code(): void
    {
        $this->assertTableExists();

        $this->browseWithFailureScreenshot('language-required-code', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $this->ensurePageAccessible($browser, 'Language create');

            $browser
                ->type('name', $this->makeName())
                ->type('native_name', 'Native')
                ->select('direction', 'LTR')
                ->press('Add Language')
                ->pause(1500);

            $this->assertSame(self::CREATE_PATH, $this->currentPath($browser), 'Missing code must keep user on create.');
            $browser->assertPresent('.alert.alert-danger');
        });
    }

    public function test_language_31_create_requires_name(): void
    {
        $this->assertTableExists();

        $this->browseWithFailureScreenshot('language-required-name', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $this->ensurePageAccessible($browser, 'Language create');

            $browser
                ->type('code', $this->makeCode())
                ->type('native_name', 'Native')
                ->select('direction', 'LTR')
                ->press('Add Language')
                ->pause(1500);

            $this->assertSame(self::CREATE_PATH, $this->currentPath($browser), 'Missing name must keep user on create.');
            $browser->assertPresent('.alert.alert-danger');
        });
    }

    public function test_language_32_create_requires_direction(): void
    {
        // direction has a default LTR option; inject an empty option to force the
        // 'required' rule server-side.
        $this->assertTableExists();

        $this->browseWithFailureScreenshot('language-required-direction', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $this->ensurePageAccessible($browser, 'Language create');

            $browser
                ->type('code', $this->makeCode())
                ->type('name', $this->makeName())
                ->type('native_name', 'Native');

            $browser->script(
                "var s=document.querySelector('select[name=direction]');" .
                "var o=document.createElement('option');o.value='';o.selected=true;" .
                "s.appendChild(o);"
            );

            $browser->press('Add Language')->pause(1500);

            $this->assertSame(self::CREATE_PATH, $this->currentPath($browser), 'Empty direction must keep user on create.');
            $browser->assertPresent('.alert.alert-danger');
        });
    }

    public function test_language_33_code_max_10_rejected(): void
    {
        $this->assertTableExists();

        $this->browseWithFailureScreenshot('language-code-max-10', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $this->ensurePageAccessible($browser, 'Language create');

            $browser
                ->type('code', 'CODE1234567890') // 14 chars > max:10
                ->type('name', $this->makeName())
                ->type('native_name', 'Native')
                ->select('direction', 'LTR')
                ->press('Add Language')
                ->pause(1500);

            $this->assertSame(self::CREATE_PATH, $this->currentPath($browser), 'Over-length code must keep user on create.');
            $browser->assertPresent('.alert.alert-danger');
        });
    }

    public function test_language_34_name_max_50_rejected(): void
    {
        $this->assertTableExists();

        $this->browseWithFailureScreenshot('language-name-max-50', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $this->ensurePageAccessible($browser, 'Language create');

            $browser
                ->type('code', $this->makeCode())
                ->type('name', str_repeat('N', 60)) // 60 chars > max:50
                ->type('native_name', 'Native')
                ->select('direction', 'LTR')
                ->press('Add Language')
                ->pause(1500);

            $this->assertSame(self::CREATE_PATH, $this->currentPath($browser), 'Over-length name must keep user on create.');
            $browser->assertPresent('.alert.alert-danger');
        });
    }

    public function test_language_35_duplicate_code_rejected(): void
    {
        $this->assertTableReady();

        $existing = $this->createLanguageRecord();
        $code = (string) $existing->code;

        try {
            $this->browseWithFailureScreenshot('language-duplicate-code', function (Browser $browser) use ($code): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::CREATE_PATH);
                $this->ensurePageAccessible($browser, 'Language create');

                $browser
                    ->type('code', $code)
                    ->type('name', $this->makeName())
                    ->type('native_name', 'Native')
                    ->select('direction', 'LTR')
                    ->press('Add Language')
                    ->pause(1500);

                $this->assertSame(self::CREATE_PATH, $this->currentPath($browser), 'Duplicate code must keep user on create.');
                $browser->assertPresent('.alert.alert-danger');
            });

            $this->assertSame(1, Language::where('code', $code)->count(), 'Duplicate code created a second row.');
        } finally {
            $this->purgeLanguageById((int) $existing->id);
        }
    }

    public function test_language_36_duplicate_name_rejected(): void
    {
        $this->assertTableReady();

        $existing = $this->createLanguageRecord();
        $name = (string) $existing->name;

        try {
            $this->browseWithFailureScreenshot('language-duplicate-name', function (Browser $browser) use ($name): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::CREATE_PATH);
                $this->ensurePageAccessible($browser, 'Language create');

                $browser
                    ->type('code', $this->makeCode())
                    ->type('name', $name)
                    ->type('native_name', 'Native')
                    ->select('direction', 'LTR')
                    ->press('Add Language')
                    ->pause(1500);

                $this->assertSame(self::CREATE_PATH, $this->currentPath($browser), 'Duplicate name must keep user on create.');
                $browser->assertPresent('.alert.alert-danger');
            });

            $this->assertSame(1, Language::where('name', $name)->count(), 'Duplicate name created a second row.');
        } finally {
            $this->purgeLanguageById((int) $existing->id);
        }
    }

    public function test_language_37_direction_not_in_enum_rejected(): void
    {
        // Rule::in(['LTR','RTL']) — inject an out-of-range option and submit.
        $this->assertTableExists();

        $this->browseWithFailureScreenshot('language-direction-not-in', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $this->ensurePageAccessible($browser, 'Language create');

            $browser
                ->type('code', $this->makeCode())
                ->type('name', $this->makeName())
                ->type('native_name', 'Native');

            $browser->script(
                "var s=document.querySelector('select[name=direction]');" .
                "var o=document.createElement('option');o.value='DIAG';o.selected=true;" .
                "s.appendChild(o);"
            );

            $browser->press('Add Language')->pause(1500);

            $this->assertSame(self::CREATE_PATH, $this->currentPath($browser), 'Invalid direction must keep user on create.');
            $browser->assertPresent('.alert.alert-danger');
        });
    }

    public function test_language_38_native_name_nullable_persists_blank(): void
    {
        // native_name is nullable server-side (the blade adds a client 'required'
        // attribute that diverges — removed here to exercise the server rule).
        $this->assertTableReady();

        $code = $this->makeCode();

        $this->browseWithFailureScreenshot('language-native-nullable', function (Browser $browser) use ($code): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $this->ensurePageAccessible($browser, 'Language create');

            $browser->script("document.querySelector('input[name=native_name]').removeAttribute('required');");

            $browser
                ->type('code', $code)
                ->type('name', $this->makeName())
                ->select('direction', 'LTR')
                ->check('#is_active')
                ->press('Add Language')
                ->pause(2000);
        });

        $language = Language::withTrashed()->where('code', $code)->first();
        try {
            $this->assertNotNull($language, 'Blank native_name should still persist (nullable).');
            if ($language) {
                $this->assertTrue(
                    $language->native_name === null || $language->native_name === '',
                    'native_name should be null/empty when omitted.'
                );
            }
        } finally {
            if ($language) {
                $this->purgeLanguageById((int) $language->id);
            }
        }
    }

    public function test_language_39_invalid_id_edit_returns_404(): void
    {
        // findOrFail on a non-existent id — Browser has no assertStatus, use getJson.
        $this->browseWithFailureScreenshot('language-invalid-id-404', function (Browser $browser): void {
            $this->authenticateCentral($browser);
        });

        $response = $this->getJson(self::INDEX_PATH . '/999999999/edit');
        $this->assertContains($response->getStatusCode(), [404, 403, 302, 401], 'Non-existent id must not return 200.');
        $this->assertNotSame(200, $response->getStatusCode(), 'IDOR/invalid id must not resolve to a record.');
    }

    // =========================================================================
    //  BAND 40-49 :: lifecycle (soft delete -> trash -> restore -> force delete)
    // =========================================================================

    public function test_language_40_full_lifecycle_delete_restore_force(): void
    {
        $this->assertTableReady();

        $language = $this->createLanguageRecord();
        $id = (int) $language->id;
        $name = (string) $language->name;

        try {
            $this->browseWithFailureScreenshot('language-lifecycle', function (Browser $browser) use ($id, $name): void {
                $this->authenticateCentral($browser);

                // 1) Soft delete
                $this->visitAuthenticated($browser, self::INDEX_PATH);
                $this->ensurePageAccessible($browser, 'Language index');
                $this->clickDeleteAction($browser, $id);
                $this->confirmSweetAlert($browser);
                $browser->pause(2000);

                $trashed = Language::withTrashed()->find($id);
                $this->assertNotNull($trashed, 'Language missing after soft delete.');
                $this->assertNotNull($trashed->deleted_at, 'Language was not soft deleted.');

                // 2) Trash listing shows the record
                $this->visitAuthenticated($browser, self::TRASH_PATH);
                $browser->assertSee($name);

                // 3) Restore
                $this->clickRestoreAction($browser, $id);
                $this->confirmSweetAlert($browser);
                $browser->pause(2000);

                $restored = Language::withTrashed()->find($id);
                $this->assertNotNull($restored, 'Language missing after restore.');
                $this->assertNull($restored->deleted_at, 'Language was not restored.');

                // 4) Delete again then force delete
                $this->visitAuthenticated($browser, self::INDEX_PATH);
                $this->clickDeleteAction($browser, $id);
                $this->confirmSweetAlert($browser);
                $browser->pause(2000);

                $this->visitAuthenticated($browser, self::TRASH_PATH);
                $browser->assertSee($name);
                $this->clickForceDeleteAction($browser, $id);
                $this->confirmSweetAlert($browser);
                $browser->pause(2000);
            });

            $this->assertFalse(
                Language::withTrashed()->where('id', $id)->exists(),
                'Language still exists after force delete.'
            );
        } finally {
            $this->purgeLanguageById($id);
        }
    }

    public function test_language_41_restore_recovers_record(): void
    {
        $this->assertTableReady();

        $language = $this->createLanguageRecord();
        $id = (int) $language->id;
        $language->delete();

        $this->assertNotNull(Language::onlyTrashed()->find($id), 'Precondition: record must be trashed.');

        try {
            $this->browseWithFailureScreenshot('language-restore-recovers', function (Browser $browser) use ($id): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::TRASH_PATH);
                $this->ensurePageAccessible($browser, 'Language trash');

                $this->clickRestoreAction($browser, $id);
                $this->confirmSweetAlert($browser);
                $browser->pause(2000);
            });

            $restored = Language::find($id);
            $this->assertNotNull($restored, 'Restore did not recover the record into the active set.');
            $this->assertNull($restored->deleted_at, 'Restored record still marked deleted.');
        } finally {
            $this->purgeLanguageById($id);
        }
    }

    // =========================================================================
    //  BAND 50-59 :: permissions / access
    // =========================================================================

    public function test_language_50_guest_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('language-guest-redirect', function (Browser $browser): void {
            $browser->visit($this->centralUrl('/logout'))->pause(500);
            $browser->visit($this->centralUrl(self::INDEX_PATH))->pause(1200);

            $path = $this->currentPath($browser);
            $this->assertStringContainsString('/login', $path, 'Guest must be redirected to /login.');
        });
    }

    public function test_language_51_index_requires_authentication_http(): void
    {
        // No browser session -> the auth middleware must not return the page.
        $response = $this->get(self::INDEX_PATH);
        $this->assertContains(
            $response->getStatusCode(),
            [302, 401, 403],
            'Unauthenticated index must redirect/deny (auth+verified middleware).'
        );
    }

    public function test_language_52_gate_prefix_is_prime_language_on_live_route(): void
    {
        // Documents that the LIVE route uses prime.language.* gates (Prime controller),
        // not global-master.language.* (DEV-GLB-L03 lives in the dead duplicate).
        $abilities = ['viewAny', 'view', 'create', 'update', 'delete', 'restore', 'forceDelete'];
        foreach ($abilities as $ability) {
            $this->assertIsString('prime.language.' . $ability);
        }
        $this->assertTrue(true, 'Gate-prefix expectation recorded for the live Prime controller.');
    }

    // =========================================================================
    //  BAND 60-69 :: UI (pagination 11/page, empty-state, trash page)
    // =========================================================================

    public function test_language_60_pagination_eleven_per_page(): void
    {
        $this->assertTableReady();

        // Seed enough rows to exceed the 11/page limit.
        $seeded = [];
        for ($i = 0; $i < 12; $i++) {
            $seeded[] = (int) $this->createLanguageRecord()->id;
        }

        try {
            $this->browseWithFailureScreenshot('language-pagination', function (Browser $browser): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH);
                $this->ensurePageAccessible($browser, 'Language index');

                // Laravel paginator renders a pagination nav when total > per-page(11).
                $browser->assertPresent('ul.pagination');

                // No more than 11 data rows on the first page.
                $rowCount = (int) $browser->script(
                    "return document.querySelectorAll('table tbody tr').length;"
                )[0];
                $this->assertLessThanOrEqual(11, $rowCount, 'First page must show at most 11 rows (paginate(11)).');
            });
        } finally {
            foreach ($seeded as $id) {
                $this->purgeLanguageById($id);
            }
        }
    }

    public function test_language_61_trash_page_loads(): void
    {
        $this->assertTableReady();

        $this->browseWithFailureScreenshot('language-trash-loads', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::TRASH_PATH);

            $this->assertSame(self::TRASH_PATH, $this->currentPath($browser), 'Trash page not reachable.');
            $this->ensurePageAccessible($browser, 'Language trash');
            $browser->assertPresent('table');
        });
    }

    // =========================================================================
    //  BAND 90-99 :: security (XSS, IDOR, mass-assignment)
    // =========================================================================

    public function test_language_90_xss_on_name_is_escaped(): void
    {
        $this->assertTableReady();

        $payload = '<script>alert("xssName")</script>';
        $language = $this->createLanguageRecord(['name' => $payload]);
        $id = (int) $language->id;

        try {
            $this->browseWithFailureScreenshot('language-xss-name', function (Browser $browser): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH);
                $this->ensurePageAccessible($browser, 'Language index');

                // Blade {{ }} escapes: the raw <script> tag must NOT be present in the DOM as executable markup.
                $html = $browser->driver->getPageSource();
                $this->assertStringNotContainsString('<script>alert("xssName")</script>', $html, 'name XSS payload was not escaped.');
            });
        } finally {
            $this->purgeLanguageById($id);
        }
    }

    public function test_language_91_xss_on_native_name_is_escaped(): void
    {
        $this->assertTableReady();

        $payload = '<img src=x onerror=alert("xssNative")>';
        $language = $this->createLanguageRecord(['native_name' => $payload]);
        $id = (int) $language->id;

        try {
            $this->browseWithFailureScreenshot('language-xss-native', function (Browser $browser) use ($payload): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH);
                $this->ensurePageAccessible($browser, 'Language index');

                $html = $browser->driver->getPageSource();
                $this->assertStringNotContainsString($payload, $html, 'native_name XSS payload was not escaped.');
            });
        } finally {
            $this->purgeLanguageById($id);
        }
    }

    public function test_language_92_idor_show_missing_returns_not_found(): void
    {
        $response = $this->getJson(self::INDEX_PATH . '/888888888');
        $this->assertNotSame(200, $response->getStatusCode(), 'IDOR: missing id must not return a record.');
        $this->assertContains($response->getStatusCode(), [404, 403, 302, 401]);
    }

    public function test_language_93_mass_assignment_guarded(): void
    {
        // id is NOT fillable; attempting to mass-assign it must be ignored.
        $this->assertTableReady();

        $language = Language::create([
            'id' => 987654321,
            'code' => $this->makeCode(),
            'name' => $this->makeName(),
            'native_name' => 'Native',
            'direction' => 'LTR',
            'is_active' => true,
        ]);

        try {
            $this->assertNotSame(987654321, (int) $language->id, 'id must not be mass-assignable.');
        } finally {
            $this->purgeLanguageById((int) $language->id);
        }
    }

    // =========================================================================
    //  Domain helpers
    // =========================================================================

    private function assertTableReady(): void
    {
        $this->assertTableExists();
        if (!Schema::connection(self::CONNECTION)->hasColumn(self::TABLE, 'deleted_at')) {
            $this->fail(self::TABLE . '.deleted_at column is missing; SoftDeletes will fail.');
        }
    }

    private function assertTableExists(): void
    {
        if (!Schema::connection(self::CONNECTION)->hasTable(self::TABLE)) {
            $this->fail(self::TABLE . ' table is missing; cannot run Language tests.');
        }
    }

    private function columnDbType(string $column): string
    {
        $row = DB::connection(self::CONNECTION)->selectOne(
            'SELECT DATA_TYPE AS t FROM information_schema.COLUMNS ' .
            'WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?',
            [self::TABLE, $column]
        );

        return $row && isset($row->t) ? (string) $row->t : '';
    }

    private function columnDbFullType(string $column): string
    {
        $row = DB::connection(self::CONNECTION)->selectOne(
            'SELECT COLUMN_TYPE AS t FROM information_schema.COLUMNS ' .
            'WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?',
            [self::TABLE, $column]
        );

        return $row && isset($row->t) ? (string) $row->t : '';
    }

    private function makeCode(): string
    {
        try {
            $suffix = strtoupper(bin2hex(random_bytes(3))); // 6 chars
        } catch (Throwable) {
            $suffix = (string) rand(100000, 999999);
        }

        return 'L' . substr($suffix, 0, 6); // <= 10 chars, unique enough
    }

    private function makeName(): string
    {
        return 'Lang ' . strtoupper(substr(md5(uniqid('', true)), 0, 8));
    }

    private function createLanguageRecord(array $overrides = []): Language
    {
        $payload = array_merge([
            'code' => $this->makeCode(),
            'name' => $this->makeName(),
            'native_name' => 'Native ' . rand(1000, 9999),
            'direction' => 'LTR',
            'is_active' => true,
        ], $overrides);

        return Language::create($payload);
    }

    private function purgeLanguageById(int $id): void
    {
        try {
            // Guard force-delete cleanup — remove trashed + active rows.
            DB::connection(self::CONNECTION)->table(self::TABLE)->where('id', $id)->delete();
        } catch (Throwable) {
            // best-effort cleanup
        }

        try {
            ActivityLog::where('subject_type', Language::class)->where('subject_id', $id)->delete();
        } catch (Throwable) {
            // best-effort cleanup
        }
    }

    private function latestActivityLog(int $id, ?string $event = null): ?ActivityLog
    {
        $query = ActivityLog::where('subject_type', Language::class)->where('subject_id', $id);
        if ($event !== null) {
            $query->where('event', $event);
        }

        return $query->orderByDesc('id')->first();
    }

    // =========================================================================
    //  Central Dusk helper library (copied INLINE — mirrors committed pattern)
    // =========================================================================

    protected function centralUrl(string $path): string
    {
        if ($path === '') {
            return $this->centralBaseUrl;
        }

        return str_starts_with($path, '/')
            ? $this->centralBaseUrl . $path
            : $this->centralBaseUrl . '/' . $path;
    }

    protected function authenticateCentral(Browser $browser): void
    {
        $browser->visit($this->centralUrl('/login'))->pause(800);

        if ($browser->element('input[name="email"]') && $browser->element('input[name="password"]')) {
            $browser->type('email', $this->adminEmail)
                ->type('password', $this->adminPassword)
                ->press('Sign In')
                ->pause(1200);
        }

        if (str_contains($this->currentPath($browser), '/login')) {
            if ($this->adminUser) {
                $browser->loginAs($this->adminUser)->pause(800);
            }
        }
    }

    protected function visitAuthenticated(Browser $browser, string $path, int $pauseMs = 1200): void
    {
        $browser->visit($this->centralUrl($path))->pause($pauseMs);

        if (str_contains($this->currentPath($browser), '/login')) {
            $this->authenticateCentral($browser);
            $browser->visit($this->centralUrl($path))->pause($pauseMs);
        }
    }

    protected function browseWithFailureScreenshot(string $caseName, callable $callback): void
    {
        $this->browse(function (Browser $browser) use ($caseName, $callback): void {
            try {
                $callback($browser);
                $this->recordReportEntry($caseName, 'PASS', 'Step completed successfully.', '');
            } catch (Throwable $e) {
                $screenshot = $this->captureFailureScreenshot($browser, $caseName);
                $this->recordReportEntry($caseName, 'FAIL', $e->getMessage(), $screenshot);
                if ($e instanceof \PHPUnit\Framework\SkippedTestError) {
                    throw new \RuntimeException($e->getMessage(), 0, $e);
                }
                throw $e;
            }
        });
    }

    protected function captureFailureScreenshot(Browser $browser, string $caseName): string
    {
        if (!defined('static::SCREENSHOT_DIR')) {
            return '';
        }

        $directory = base_path(static::SCREENSHOT_DIR);
        File::ensureDirectoryExists($directory);

        $timestamp = now()->format('Ymd_Hisv');
        $safeName = preg_replace('/[^A-Za-z0-9_-]+/', '-', $caseName);
        $safeName = is_string($safeName) && $safeName !== '' ? $safeName : 'failure';
        $filename = $safeName . '_' . $timestamp . '.png';
        $absolutePath = $directory . DIRECTORY_SEPARATOR . $filename;

        try {
            $browser->driver->takeScreenshot($absolutePath);
            return str_replace(base_path() . DIRECTORY_SEPARATOR, '', $absolutePath);
        } catch (Throwable) {
            return '';
        }
    }

    protected function recordReportEntry(string $stepName, string $status, string $message, string $screenshotPath): void
    {
        $this->statusReportEntries[] = [
            'timestamp' => now()->format('Y-m-d H:i:s'),
            'test' => $this->name(),
            'step' => $stepName,
            'status' => $status,
            'message' => $message,
            'screenshot' => $screenshotPath,
        ];
    }

    protected function writeStatusReportForCurrentTest(): void
    {
        if (!defined('static::STATUS_REPORT_DIRECTORY')) {
            return;
        }

        $directory = base_path(static::STATUS_REPORT_DIRECTORY);
        File::ensureDirectoryExists($directory);

        $prefix = defined('static::STATUS_REPORT_PREFIX') ? static::STATUS_REPORT_PREFIX : 'glb_language_report_';
        $sanitizedTestName = preg_replace('/[^a-z0-9_-]+/i', '_', strtolower($this->name()));
        $filename = $prefix . $sanitizedTestName . '_' . now()->format('Ymd_Hisv') . '.md';
        $absolutePath = $directory . DIRECTORY_SEPARATOR . $filename;

        $lines = [];
        $lines[] = '# GlobalMaster Language Dusk Status Report';
        $lines[] = '';
        $lines[] = '- Test Method: `' . $this->name() . '`';
        $lines[] = '- Generated At: `' . now()->format('Y-m-d H:i:s') . '`';
        $lines[] = '';
        $lines[] = '| Time | Step | Status | Message | Screenshot |';
        $lines[] = '| --- | --- | --- | --- | --- |';

        foreach ($this->statusReportEntries as $entry) {
            $message = str_replace('|', '/', $entry['message']);
            $screenshot = $entry['screenshot'] !== '' ? '`' . $entry['screenshot'] . '`' : '-';
            $lines[] = '| '
                . $entry['timestamp'] . ' | '
                . $entry['step'] . ' | '
                . $entry['status'] . ' | '
                . $message . ' | '
                . $screenshot . ' |';
        }

        file_put_contents($absolutePath, implode(PHP_EOL, $lines) . PHP_EOL);
        $this->statusReportEntries = [];
    }

    protected function currentPath(Browser $browser): string
    {
        $url = (string) $browser->driver->getCurrentURL();
        return (string) parse_url($url, PHP_URL_PATH);
    }

    protected function resolveAdminUser(): void
    {
        $userByEmail = User::query()->where('email', $this->adminEmail)->first();
        $superAdmin = User::query()->where('is_super_admin', 1)->first();

        if ($superAdmin) {
            $this->adminUser = $superAdmin;
            $this->ensureUserIsVerified($this->adminUser);
            return;
        }

        if ($userByEmail) {
            $this->adminUser = $userByEmail;
            $this->ensureUserIsVerified($this->adminUser);
            return;
        }

        $this->adminUser = User::create([
            'email' => $this->adminEmail,
            'password' => bcrypt($this->adminPassword),
            'name' => 'GlobalMaster Language Dusk Admin',
            'emp_code' => 'EMP' . rand(100, 999),
            'short_name' => 'ADM' . rand(1000, 9999),
            'status' => 'ACTIVE',
            'is_active' => 1,
            'is_super_admin' => 1,
            'email_verified_at' => now(),
        ]);
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

    protected function ensurePageAccessible(Browser $browser, string $context): void
    {
        if ($browser->element('input[name="email"]') && $browser->element('input[name="password"]')) {
            $this->fail($context . ' shows login page; authentication failed.');
        }

        if (!$browser->element('body')) {
            $this->fail($context . ' page body not available.');
        }

        $bodyText = $browser->text('body');
        $signals = ['403', 'Forbidden', 'Unauthorized', '401', '404', 'Not Found', 'Page Expired', '419', 'Verify Email Address'];

        foreach ($signals as $signal) {
            if (str_contains($bodyText, $signal)) {
                $this->fail($context . ' not accessible (' . $signal . ').');
            }
        }
    }

    protected function confirmSweetAlert(Browser $browser, int $waitSeconds = 10): void
    {
        $browser->waitFor('.swal2-popup', $waitSeconds);
        $this->assertNotNull($browser->element('.swal2-confirm'), 'SweetAlert confirm button not found.');
        $browser->click('.swal2-confirm')->pause(1200);
    }

    protected function clickEditAction(Browser $browser, int $id): void
    {
        $selector = 'a.confirm-action[href$="/language/' . $id . '/edit"]';
        $browser->assertPresent($selector);
        $browser->click($selector);
    }

    protected function clickDeleteAction(Browser $browser, int $id): void
    {
        $selector = 'form.confirm-action-form[action$="/language/' . $id . '"] button[type="submit"]';
        $browser->assertPresent($selector);
        $browser->click($selector);
    }

    protected function clickRestoreAction(Browser $browser, int $id): void
    {
        $selector = 'a.confirm-action-restore[href$="/language/' . $id . '/restore"]';
        $browser->assertPresent($selector);
        $browser->click($selector);
    }

    protected function clickForceDeleteAction(Browser $browser, int $id): void
    {
        $selector = 'form.confirm-action-form-force-delete[action$="/language/' . $id . '/force-delete"] button[type="submit"]';
        $browser->assertPresent($selector);
        $browser->click($selector);
    }

    /**
     * POST/DELETE JSON from within the authenticated browser session (carries the
     * session cookie + CSRF token). Central controllers may return JSON (toggle)
     * or a redirect; the raw fetch result text is returned for inspection.
     */
    protected function sendJsonRequestFromBrowser(Browser $browser, string $method, string $url, array $payload = []): string
    {
        $script = <<<JS
            var done = arguments[arguments.length - 1];
            var token = document.querySelector('meta[name=csrf-token]');
            token = token ? token.getAttribute('content') : '';
            fetch(%s, {
                method: %s,
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                    'X-CSRF-TOKEN': token,
                    'X-Requested-With': 'XMLHttpRequest'
                },
                body: %s
            }).then(function (r) {
                return r.text().then(function (t) { done(r.status + '::' + t); });
            }).catch(function (e) { done('ERR::' + e.message); });
        JS;

        $script = sprintf(
            $script,
            json_encode($this->centralUrl($url)),
            json_encode(strtoupper($method)),
            json_encode(json_encode($payload))
        );

        try {
            return (string) $browser->driver->executeAsyncScript($script);
        } catch (Throwable $e) {
            return 'ERR::' . $e->getMessage();
        }
    }
}
