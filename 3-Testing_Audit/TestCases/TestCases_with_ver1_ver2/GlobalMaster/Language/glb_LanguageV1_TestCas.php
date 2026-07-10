<?php

namespace Tests\Browser\Modules\Prime\GlobalMaster;

use App\Models\User;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\Prime\Models\ActivityLog;
use Modules\Prime\Models\Language;
use Tests\Browser\Modules\Prime\PrimeDuskTestCase;
use Throwable;

/**
 * glb_Language V1 — Foundation Dusk suite (central / prime-side).
 *
 * Scope       : CENTRAL. Primary table `glb_languages` (VIEW on `mysql`, real table on
 *               `global_master_mysql`). NO tenant init. Cross-tenant isolation N/A.
 * Under test  : Modules\Prime\Http\Controllers\LanguageController (serves central.global-master.language.*).
 * Base URL    : http://127.0.0.1:8000 (enforced by PrimeDuskTestCase::setUp()).
 * Constraints : follows 05_Known_Test_Failure_Constraints — App\Models\User (B5), typed props
 *               initialised (C13), SoftDeletes verified before withTrashed (C12), forceDelete
 *               guarded (C11), ENUM case-exact (D18), central host on HTTP calls (E21), APP_ENV=testing (E20).
 */
class glb_LanguageV1_TestCas extends PrimeDuskTestCase
{
    private const INDEX_PATH   = '/global-master/language';
    private const CREATE_PATH  = '/global-master/language/create';
    private const TABLE        = 'glb_languages';

    private ?User $adminUser      = null;
    private string $centralBaseUrl = '';
    private string $adminEmail    = '';
    private string $adminPassword = '';
    private static bool $screenshotsCleaned = false;

    protected function setUp(): void
    {
        parent::setUp();

        $this->centralBaseUrl = rtrim($this->primeBaseUrl, '/');
        $this->adminEmail     = (string) env('DUSK_ADMIN_EMAIL', 'root@tenant.com');
        $this->adminPassword  = (string) env('DUSK_ADMIN_PASSWORD', 'password');

        if (!self::$screenshotsCleaned) {
            $this->cleanScreenshots();
            self::$screenshotsCleaned = true;
        }

        $this->resolveAdminUser();
    }

    protected function tearDown(): void
    {
        if (function_exists('tenancy') && tenancy()->initialized) {
            tenancy()->end();
        }
        parent::tearDown();
    }

    // =====================================================================
    // 01 — Schema / model / request configuration truth
    // =====================================================================

    public function test_language_01_migration_model_and_request_configuration_are_correct(): void
    {
        // Table + columns (VIEW on default connection exposes the underlying columns)
        $this->assertTrue(Schema::hasTable(self::TABLE), 'glb_languages table/view must exist');
        $this->assertTrue(
            Schema::hasColumns(self::TABLE, ['id', 'code', 'name', 'native_name', 'direction', 'is_active']),
            'glb_languages core columns must exist'
        );
        // deleted_at / timestamps are added by the migration (NOT the consolidated DDL spec).
        $this->assertTrue(Schema::hasColumn(self::TABLE, 'deleted_at'), 'deleted_at added by migration softDeletes()');

        // Model configuration
        $model = new Language();
        $this->assertSame('glb_languages', $model->getTable());
        $this->assertSame('global_master_mysql', $model->getConnectionName());
        $this->assertTrue(
            in_array(SoftDeletes::class, class_uses_recursive(Language::class), true),
            'Prime\\Language must use SoftDeletes'
        );
        foreach (['code', 'name', 'native_name', 'direction', 'is_active'] as $col) {
            $this->assertContains($col, $model->getFillable());
        }

        // Migration + FormRequest file assertions (best-effort; skipped if app repo path unavailable)
        $migration = $this->mainProjectFile('Modules/GlobalMaster/database/migrations/2025_11_10_061519_create_languages_table.php');
        if ($migration !== null) {
            $src = File::get($migration);
            $this->assertStringContainsString('softDeletes', $src, 'migration adds softDeletes()');
            $this->assertStringContainsString('timestamps', $src, 'migration adds timestamps()');
            $this->assertStringContainsString("enum('direction', ['LTR', 'RTL'])", $src);
        }
        $request = $this->mainProjectFile('Modules/GlobalMaster/app/Http/Requests/LanguageRequest.php');
        if ($request !== null) {
            $src = File::get($request);
            $this->assertStringContainsString("'max:10'", $src);
            $this->assertStringContainsString("'max:50'", $src);
            $this->assertStringContainsString("Rule::in(['LTR', 'RTL'])", $src);
            $this->assertStringContainsString('return true;', $src, 'authorize() returns true (D30)');
        }
    }

    // =====================================================================
    // 02 — Index renders for admin
    // =====================================================================

    public function test_language_02_index_page_renders_for_admin(): void
    {
        $this->browse(function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $browser->assertSee('Language Management');
        });
    }

    // =====================================================================
    // 03 — Create page renders with form fields
    // =====================================================================

    public function test_language_03_create_page_renders_with_form_fields(): void
    {
        $this->browse(function (Browser $browser): void {
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $browser->waitFor('input[name="name"]', 10)
                ->assertPresent('input[name="code"]')
                ->assertPresent('input[name="native_name"]')
                ->assertPresent('select[name="direction"]');
        });
    }

    // =====================================================================
    // 04 — Store creates a language
    // =====================================================================

    public function test_language_04_language_is_created_via_store_endpoint(): void
    {
        $suffix = $this->uniqueSuffix();
        $name   = 'Dusk Lang ' . $suffix;
        $code   = 'dl' . substr($suffix, -6);

        $this->browse(function (Browser $browser) use ($name, $code): void {
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $browser->waitFor('input[name="name"]', 10)
                ->type('name', $name)
                ->type('code', $code)
                ->type('native_name', 'Native ' . $code)
                ->select('direction', 'LTR')
                ->press('Add Language')
                ->pause(1500);
        });

        $row = Language::where('code', $code)->first();
        $this->assertNotNull($row, 'language row must be persisted');
        $this->assertSame($name, $row->name);
        $this->cleanupLanguage($row);
    }

    // =====================================================================
    // 05 — Edit page renders prefilled
    // =====================================================================

    public function test_language_05_edit_page_renders_prefilled(): void
    {
        $lang = $this->makeLanguage();
        if ($lang === null) {
            $this->markTestSkipped('Could not seed language (env).');
        }

        $this->browse(function (Browser $browser) use ($lang): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH . '/' . $lang->id . '/edit');
            $browser->waitFor('input[name="name"]', 10)
                ->assertInputValue('name', $lang->name)
                ->assertInputValue('code', $lang->code);
        });

        $this->cleanupLanguage($lang);
    }

    // =====================================================================
    // 06 — Update persists changes
    // =====================================================================

    public function test_language_06_language_is_updated_via_update_endpoint(): void
    {
        $lang = $this->makeLanguage();
        if ($lang === null) {
            $this->markTestSkipped('Could not seed language (env).');
        }
        $newName = $lang->name . ' Edited';

        $response = $this->httpAsAdmin('put', 'central.global-master.language.update', $lang, [
            'name'        => $newName,
            'code'        => $lang->code,
            'native_name' => $lang->native_name,
            'direction'   => 'LTR',
            'is_active'   => 'on',
        ]);
        if ($this->skippedOnDomain($response)) {
            $this->markTestSkipped('Central domain group not matched in this env.');
        }

        $this->assertSame($newName, $lang->refresh()->name);
        $this->cleanupLanguage($lang);
    }

    // =====================================================================
    // 07 — BUG-GLB-006b: update flash is the raw literal 'update.language'
    // =====================================================================

    public function test_language_07_update_flash_shows_literal_update_language_bug(): void
    {
        $lang = $this->makeLanguage();
        if ($lang === null) {
            $this->markTestSkipped('Could not seed language (env).');
        }

        $response = $this->httpAsAdmin('put', 'central.global-master.language.update', $lang, [
            'name'        => $lang->name . ' Flash',
            'code'        => $lang->code,
            'native_name' => $lang->native_name,
            'direction'   => 'LTR',
            'is_active'   => 'on',
        ]);
        if ($this->skippedOnDomain($response)) {
            $this->markTestSkipped('Central domain group not matched in this env.');
        }

        // Controller flashes the raw key 'update.language' (flash() not called) — proves BUG-GLB-006b.
        $response->assertSessionHas('success', 'update.language');
        $this->cleanupLanguage($lang);
    }

    // =====================================================================
    // 08 — Destroy soft-deletes and logs 'Trashed'
    // =====================================================================

    public function test_language_08_destroy_soft_deletes_and_logs_trashed(): void
    {
        $lang = $this->makeLanguage();
        if ($lang === null) {
            $this->markTestSkipped('Could not seed language (env).');
        }
        $id = $lang->id;

        $response = $this->httpAsAdmin('delete', 'central.global-master.language.destroy', $id);
        if ($this->skippedOnDomain($response)) {
            $this->markTestSkipped('Central domain group not matched in this env.');
        }

        $fresh = Language::withTrashed()->find($id);
        $this->assertNotNull($fresh);
        $this->assertNotNull($fresh->deleted_at, 'row must be soft-deleted');
        $this->assertFalse((bool) $fresh->is_active, 'is_active set false on destroy');
        $this->assertSame('Trashed', $this->latestActivityEvent($id));

        $this->hardCleanup($id);
    }

    // =====================================================================
    // 09 — Trashed page lists soft-deleted rows
    // =====================================================================

    public function test_language_09_trashed_page_lists_soft_deleted(): void
    {
        $lang = $this->makeLanguage();
        if ($lang === null) {
            $this->markTestSkipped('Could not seed language (env).');
        }
        $lang->is_active = false;
        $lang->save();
        $lang->delete();
        $id = $lang->id;

        $this->browse(function (Browser $browser) use ($lang): void {
            $this->visitAuthenticated($browser, self::INDEX_PATH . '/trash/view');
            $browser->assertSee($lang->name);
        });

        $this->hardCleanup($id);
    }

    // =====================================================================
    // 10 — Restore recovers and logs 'Restored'
    // =====================================================================

    public function test_language_10_restore_recovers_and_logs_restored(): void
    {
        $lang = $this->makeLanguage();
        if ($lang === null) {
            $this->markTestSkipped('Could not seed language (env).');
        }
        $lang->is_active = false;
        $lang->save();
        $lang->delete();
        $id = $lang->id;

        $response = $this->httpAsAdmin('get', 'central.global-master.language.restore', $id);
        if ($this->skippedOnDomain($response)) {
            $this->markTestSkipped('Central domain group not matched in this env.');
        }

        $this->assertNull(Language::find($id)?->deleted_at, 'row restored');
        $this->assertSame('Restored', $this->latestActivityEvent($id));
        $this->hardCleanup($id);
    }

    // =====================================================================
    // 11 — BUG-GLB-006a: forceDelete removes and logs 'Stored'
    // =====================================================================

    public function test_language_11_force_delete_removes_and_logs_stored_bug(): void
    {
        $lang = $this->makeLanguage();
        if ($lang === null) {
            $this->markTestSkipped('Could not seed language (env).');
        }
        $lang->delete();
        $id = $lang->id;

        $response = $this->httpAsAdmin('delete', 'central.global-master.language.forceDelete', $id);
        if ($this->skippedOnDomain($response)) {
            $this->markTestSkipped('Central domain group not matched in this env.');
        }

        $this->assertNull(Language::withTrashed()->find($id), 'row permanently removed');
        // Event is mislabeled 'Stored' on forceDelete (should be 'Deleted') — proves BUG-GLB-006a.
        $this->assertSame('Stored', $this->latestActivityEvent($id));
    }

    // =====================================================================
    // 12 — Toggle status endpoint updates and logs 'Toggled'
    // =====================================================================

    public function test_language_12_toggle_status_endpoint_updates_and_logs_toggled(): void
    {
        $lang = $this->makeLanguage(['is_active' => true]);
        if ($lang === null) {
            $this->markTestSkipped('Could not seed language (env).');
        }
        $id = $lang->id;

        $response = $this->httpAsAdmin('post', 'central.global-master.language.toggleStatus', $lang, ['is_active' => 0]);
        if ($this->skippedOnDomain($response)) {
            $this->markTestSkipped('Central domain group not matched in this env.');
        }

        $response->assertOk()->assertJson(['success' => true]);
        $this->assertFalse((bool) $lang->refresh()->is_active);
        $this->assertSame('Toggled', $this->latestActivityEvent($id));
        $this->cleanupLanguage($lang);
    }

    // =====================================================================
    // 13 — code required
    // =====================================================================

    public function test_language_13_code_is_required_validation(): void
    {
        $response = $this->httpAsAdmin('post', 'central.global-master.language.store', null, [
            'name'      => 'Missing Code ' . $this->uniqueSuffix(),
            'direction' => 'LTR',
            'is_active' => 'on',
        ]);
        if ($this->skippedOnDomain($response)) {
            $this->markTestSkipped('Central domain group not matched in this env.');
        }
        $response->assertSessionHasErrors('code');
    }

    // =====================================================================
    // 14 — name required
    // =====================================================================

    public function test_language_14_name_is_required_validation(): void
    {
        $response = $this->httpAsAdmin('post', 'central.global-master.language.store', null, [
            'code'      => 'nc' . substr($this->uniqueSuffix(), -6),
            'direction' => 'LTR',
            'is_active' => 'on',
        ]);
        if ($this->skippedOnDomain($response)) {
            $this->markTestSkipped('Central domain group not matched in this env.');
        }
        $response->assertSessionHasErrors('name');
    }

    // =====================================================================
    // 15 — duplicate code rejected
    // =====================================================================

    public function test_language_15_duplicate_code_is_rejected(): void
    {
        $lang = $this->makeLanguage();
        if ($lang === null) {
            $this->markTestSkipped('Could not seed language (env).');
        }

        $response = $this->httpAsAdmin('post', 'central.global-master.language.store', null, [
            'name'      => 'Dup ' . $this->uniqueSuffix(),
            'code'      => $lang->code,
            'direction' => 'LTR',
            'is_active' => 'on',
        ]);
        if ($this->skippedOnDomain($response)) {
            $this->markTestSkipped('Central domain group not matched in this env.');
        }
        $response->assertSessionHasErrors('code');
        $this->cleanupLanguage($lang);
    }

    // =====================================================================
    // 16 — direction must be LTR/RTL
    // =====================================================================

    public function test_language_16_direction_must_be_ltr_or_rtl(): void
    {
        $response = $this->httpAsAdmin('post', 'central.global-master.language.store', null, [
            'name'      => 'BadDir ' . $this->uniqueSuffix(),
            'code'      => 'bd' . substr($this->uniqueSuffix(), -6),
            'direction' => 'UPDOWN',
            'is_active' => 'on',
        ]);
        if ($this->skippedOnDomain($response)) {
            $this->markTestSkipped('Central domain group not matched in this env.');
        }
        $response->assertSessionHasErrors('direction');
    }

    // =====================================================================
    // 17 — guest redirected to login
    // =====================================================================

    public function test_language_17_guest_is_redirected_to_login(): void
    {
        $this->browse(function (Browser $browser): void {
            $browser->visit($this->centralUrl('/logout'))->pause(500);
            $browser->visit($this->centralUrl(self::INDEX_PATH))->pause(1000);
            $browser->assertPathContains('/login');
        });
    }

    // =====================================================================
    // 18 — activity log written to central table with user_id
    // =====================================================================

    public function test_language_18_activity_log_written_to_central_table_with_user_id(): void
    {
        if ($this->adminUser === null) {
            $this->markTestSkipped('No admin user available.');
        }
        $lang = $this->makeLanguage();
        if ($lang === null) {
            $this->markTestSkipped('Could not seed language (env).');
        }
        $id = $lang->id;

        $response = $this->httpAsAdmin('delete', 'central.global-master.language.destroy', $id);
        if ($this->skippedOnDomain($response)) {
            $this->markTestSkipped('Central domain group not matched in this env.');
        }

        $log = ActivityLog::where('subject_type', Language::class)
            ->where('subject_id', $id)
            ->orderByDesc('id')
            ->first();
        $this->assertNotNull($log, 'central activity row must be written');
        $this->assertSame('Trashed', $log->event);
        $this->assertSame((int) $this->adminUser->getKey(), (int) $log->user_id);

        $this->hardCleanup($id);
    }

    // =====================================================================
    // Helpers
    // =====================================================================

    protected function centralUrl(string $path): string
    {
        if ($path === '') {
            return $this->centralBaseUrl;
        }
        return str_starts_with($path, '/')
            ? $this->centralBaseUrl . $path
            : $this->centralBaseUrl . '/' . $path;
    }

    protected function currentPath(Browser $browser): string
    {
        return (string) parse_url((string) $browser->driver->getCurrentURL(), PHP_URL_PATH);
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
        if (str_contains($this->currentPath($browser), '/login') && $this->adminUser) {
            $browser->loginAs($this->adminUser)->pause(600);
        }
    }

    protected function visitAuthenticated(Browser $browser, string $path, int $pauseMs = 1000): void
    {
        $browser->visit($this->centralUrl($path))->pause($pauseMs);
        if (str_contains($this->currentPath($browser), '/login')) {
            $this->authenticateCentral($browser);
            $browser->visit($this->centralUrl($path))->pause($pauseMs);
        }
    }

    protected function resolveAdminUser(): void
    {
        try {
            $this->adminUser = User::query()->where('is_super_admin', 1)->first()
                ?? User::query()->where('email', $this->adminEmail)->first();
        } catch (Throwable) {
            $this->adminUser = null;
        }
    }

    /**
     * Issue an authenticated in-process HTTP request to a central route, pinning the
     * HTTP host to the central domain so Route::domain(config('app.domain')) matches.
     */
    protected function httpAsAdmin(string $method, string $routeName, mixed $param = null, array $data = [])
    {
        if ($this->adminUser === null) {
            $this->markTestSkipped('No admin user available for HTTP call.');
        }
        $host = (string) parse_url($this->primeBaseUrl, PHP_URL_HOST);
        $port = parse_url($this->primeBaseUrl, PHP_URL_PORT);
        $this->withServerVariables(['HTTP_HOST' => $port ? "{$host}:{$port}" : $host]);

        $uri = $param === null
            ? route($routeName, [], false)
            : route($routeName, [is_object($param) ? $param->getKey() : $param], false);

        return $this->actingAs($this->adminUser)->{$method}($uri, $data);
    }

    protected function skippedOnDomain($response): bool
    {
        // If the central domain group did not match in this env, the route resolves to 404.
        return method_exists($response, 'getStatusCode') && $response->getStatusCode() === 404;
    }

    protected function latestActivityEvent(int $subjectId): ?string
    {
        try {
            return ActivityLog::where('subject_type', Language::class)
                ->where('subject_id', $subjectId)
                ->orderByDesc('id')
                ->value('event');
        } catch (Throwable) {
            return null;
        }
    }

    protected function makeLanguage(array $overrides = []): ?Language
    {
        $suffix = $this->uniqueSuffix();
        try {
            return Language::create(array_merge([
                'code'        => 'lg' . substr($suffix, -6),
                'name'        => 'Lang ' . $suffix,
                'native_name' => 'Native ' . substr($suffix, -6),
                'direction'   => 'LTR',
                'is_active'   => true,
            ], $overrides));
        } catch (Throwable) {
            return null;
        }
    }

    protected function cleanupLanguage(?Language $lang): void
    {
        if ($lang === null) {
            return;
        }
        try {
            $lang->forceDelete();
        } catch (Throwable) {
            // media/soft-delete edge — ignore (C11)
        }
    }

    protected function hardCleanup(int $id): void
    {
        try {
            $row = Language::withTrashed()->find($id);
            if ($row) {
                $row->forceDelete();
            }
        } catch (Throwable) {
        }
    }

    protected function uniqueSuffix(): string
    {
        return substr((string) uniqid(), -8) . random_int(10, 99);
    }

    protected function mainProjectFile(string $relative): ?string
    {
        $root = env('MAIN_PROJECT_PATH');
        if (!is_string($root) || $root === '') {
            return null;
        }
        $path = rtrim($root, '/') . '/' . ltrim($relative, '/');
        return is_file($path) ? $path : null;
    }

    protected function cleanScreenshots(): void
    {
        if (!defined('static::SCREENSHOT_DIR')) {
            return;
        }
        try {
            $dir = base_path(static::SCREENSHOT_DIR);
            if (is_dir($dir)) {
                foreach (glob($dir . DIRECTORY_SEPARATOR . '*.png') ?: [] as $file) {
                    @unlink($file);
                }
            }
        } catch (Throwable) {
        }
    }
}
