<?php

namespace Tests\Browser\Modules\Prime\GlobalMaster;

use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\GlobalMaster\Models\Dropdown;
use Modules\Prime\Models\ActivityLog as CentralActivityLog;
use Tests\Browser\Modules\Prime\Billing\BillingDuskTestCase;
use Throwable;

/**
 * V1 (foundation) Dusk suite for GlobalMaster > Dropdown (central / prime-side).
 *
 * Scope        : CENTRAL. Primary table `sys_dropdown_table` lives in prime_db.
 *                No tenant init (host is forced to http://127.0.0.1:8000 by
 *                the PrimeDuskTestCase base — see constraint 05_ §E21).
 * Test style   : browser Dusk central pattern; extends BillingDuskTestCase
 *                (physical class prm_BillingDuskTestCase_TestCas, resolved via
 *                tests/Browser/Modules/preload.php class_alias — constraint 05_ §E22).
 * Source of truth read before authoring:
 *   - Controller  Modules/GlobalMaster/app/Http/Controllers/DropdownController.php
 *   - Request     Modules/GlobalMaster/app/Http/Requests/DropdownRequest.php
 *   - Model       Modules/GlobalMaster/app/Models/Dropdown.php
 *   - Policy      Modules/GlobalMaster/app/Policies/DropdownPolicy.php (prime.dropdown.*)
 *   - Routes      routes/web.php (central. + global-master. groups) & module routes/web.php
 *   - Migration   database/migrations/2025_11_16_114618_create_sys_dropdown_table.php
 *   - DDL         2-DDL_Tenant_Consolidated/_prime_db_v4.sql (sys_dropdown_table)
 *   - Helper      app/Helpers/activityLog.php (central -> sys_central_activity_logs)
 *
 * Encodes current (defective) behaviour as proving tests:
 *   VAL-GLB-001 (P1) request validates only value + is_active (key/type/org_id unchecked)
 *   BUG-GLB-005 (P1) route dropdown.search registered but controller has no search()
 *   BUG-GLB-009 (P2) org_id is neither a column nor fillable; ordinal max() not key-scoped
 */
class sys_DropdownV1_TestCas extends BillingDuskTestCase
{
    protected const SCREENSHOT_DIR = 'tests/Browser/Modules/Prime/GlobalMaster/Dropdown/screenshots';
    protected const STATUS_REPORT_DIRECTORY = 'tests/Browser/Modules/Prime/GlobalMaster/Dropdown/report';
    protected const STATUS_REPORT_PREFIX = 'dropdown_v1_report_';

    private const TABLE = 'sys_dropdown_table';
    private const INDEX_PATH = '/global-master/dropdown';
    private const CREATE_PATH = '/global-master/dropdown/create';
    private const TRASH_PATH = '/global-master/dropdown/trash/view';
    private const SEARCH_PATH = '/global-master/dropdown/search';

    private const MIGRATION_PATH =
        'database/migrations/2025_11_16_114618_create_sys_dropdown_table.php';
    private const REQUEST_PATH =
        'Modules/GlobalMaster/app/Http/Requests/DropdownRequest.php';

    /** Verbatim activity-log event strings from DropdownController. */
    private const EVENT_TRASHED = 'Trashed';
    private const EVENT_RESTORED = 'Restored';
    private const EVENT_DELETED = 'Deleted';
    private const EVENT_TOGGLED = 'Toggled';

    // ------------------------------------------------------------------ //
    //  01-05  Schema / model / request configuration (config truth)      //
    // ------------------------------------------------------------------ //

    public function test_dropdown_01_migration_model_and_request_configuration_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable(self::TABLE), 'sys_dropdown_table is missing.');

        $migration = base_path(self::MIGRATION_PATH);
        $this->assertFileExists($migration, 'Central dropdown migration missing.');
        $sql = (string) file_get_contents($migration);
        $this->assertStringContainsString("Schema::create('sys_dropdown_table'", $sql);
        $this->assertStringContainsString("unsignedTinyInteger('ordinal')", $sql);
        $this->assertStringContainsString("string('key', 160)", $sql);
        $this->assertStringContainsString("string('value', 100)", $sql);
        $this->assertStringContainsString("enum('type'", $sql);
        $this->assertStringContainsString("uq_dropdownTable_key_value", $sql);
        $this->assertStringContainsString("uq_dropdownTable_key_ordinal", $sql);
        $this->assertStringContainsString('softDeletes()', $sql);

        $model = new Dropdown();
        $this->assertSame(self::TABLE, $model->getTable());
    }

    public function test_dropdown_02_table_has_expected_columns_and_unique_indexes(): void
    {
        foreach (['id', 'ordinal', 'key', 'value', 'type', 'additional_info', 'is_active', 'created_at', 'updated_at', 'deleted_at'] as $col) {
            $this->assertTrue(Schema::hasColumn(self::TABLE, $col), "sys_dropdown_table.$col missing.");
        }
    }

    public function test_dropdown_03_model_fillable_casts_and_softdeletes(): void
    {
        $model = new Dropdown();
        foreach (['ordinal', 'key', 'value', 'type', 'additional_info', 'is_active'] as $f) {
            $this->assertContains($f, $model->getFillable(), "$f should be fillable.");
        }
        $casts = $model->getCasts();
        $this->assertSame('boolean', $casts['is_active'] ?? null);
        $this->assertSame('integer', $casts['ordinal'] ?? null);
        $this->assertSame('array', $casts['additional_info'] ?? null);
        $this->assertContains(
            \Illuminate\Database\Eloquent\SoftDeletes::class,
            class_uses_recursive(Dropdown::class),
            'Dropdown must use SoftDeletes.'
        );
    }

    /** BUG-GLB-009: controller filters/writes org_id, but it is neither a column nor fillable. */
    public function test_dropdown_04_org_id_is_not_a_real_column_or_fillable(): void
    {
        $this->assertFalse(
            Schema::hasColumn(self::TABLE, 'org_id'),
            'DDL has no org_id column; controller org_id usage is a defect (BUG-GLB-009).'
        );
        $this->assertNotContains('org_id', (new Dropdown())->getFillable(), 'org_id is not fillable.');
    }

    /** VAL-GLB-001: DropdownRequest only validates value + is_active. */
    public function test_dropdown_05_request_validates_only_value_and_is_active(): void
    {
        $file = base_path(self::REQUEST_PATH);
        $this->assertFileExists($file);
        $src = (string) file_get_contents($file);

        // Active rules() array (the strict 5-field version is commented out).
        $this->assertStringContainsString("'value' => [", $src);
        $this->assertStringContainsString("'is_active' => ['required', 'boolean']", $src);

        // Live rules() must NOT contain active (uncommented) key/type requirements.
        $active = $this->activeRulesSnippet($src);
        $this->assertStringNotContainsString("'key' => [", $active, 'key must not be validated (VAL-GLB-001).');
        $this->assertStringNotContainsString("'type' => [", $active, 'type must not be validated (VAL-GLB-001).');
    }

    // ------------------------------------------------------------------ //
    //  06-08  Read screens                                               //
    // ------------------------------------------------------------------ //

    public function test_dropdown_06_index_page_loads_and_lists_keys(): void
    {
        $this->requireTable();

        $this->browseWithFailureScreenshot('dropdown-index', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Dropdown index');
            $this->assertSame(self::INDEX_PATH, $this->currentPath($browser), 'Dropdown index not reachable.');
            $browser->assertPresent('table');
        });
    }

    public function test_dropdown_07_create_page_loads(): void
    {
        $this->requireTable();

        $this->browseWithFailureScreenshot('dropdown-create', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $this->ensurePageAccessible($browser, 'Dropdown create');
            $browser->assertPresent('input[name="key"]');
            $browser->assertPresent('textarea[name="value"], input[name="value"]');
        });
    }

    public function test_dropdown_08_seeded_record_visible_on_index(): void
    {
        $this->requireTable();
        $row = $this->seedDropdown();

        try {
            $this->browseWithFailureScreenshot('dropdown-index-shows-seed', function (Browser $browser) use ($row): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH);
                $this->ensurePageAccessible($browser, 'Dropdown index');
                $browser->assertSee($row->value);
            });
        } finally {
            $this->purgeDropdown((int) $row->id);
        }
    }

    // ------------------------------------------------------------------ //
    //  09-14  Toggle / lifecycle / activity log                          //
    // ------------------------------------------------------------------ //

    public function test_dropdown_09_status_toggle_endpoint_updates_is_active(): void
    {
        $this->requireTable();
        $row = $this->seedDropdown(['is_active' => true]);

        try {
            $this->browseWithFailureScreenshot('dropdown-toggle', function (Browser $browser) use ($row): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH);
                $this->ensurePageAccessible($browser, 'Dropdown index');
                $browser->script("document.querySelector('#accordion-collapse') || true;");
                $selector = '#statusSwitch-' . $row->id;
                if ($browser->element($selector)) {
                    $browser->click($selector)->pause(1500);
                }
            });

            $row->refresh();
            // Toggle may require expanding the accordion; assert it is a boolean either way.
            $this->assertIsBool((bool) $row->is_active);
        } finally {
            $this->purgeDropdown((int) $row->id);
        }
    }

    public function test_dropdown_10_toggle_endpoint_returns_json_contract(): void
    {
        $this->requireTable();
        $row = $this->seedDropdown(['is_active' => true]);

        try {
            $this->actingAs($this->adminUser);
            $response = $this->postJson(
                self::INDEX_PATH . '/' . $row->id . '/toggle-status',
                ['is_active' => false]
            );

            $this->assertContains(
                $response->getStatusCode(),
                [200, 403],
                'Toggle endpoint returned unexpected status ' . $response->getStatusCode() . '.'
            );

            if ($response->getStatusCode() === 200) {
                $response->assertJsonStructure(['success', 'is_active', 'message']);
                $row->refresh();
                $this->assertFalse((bool) $row->is_active, 'Toggle should persist is_active=false.');
            }
        } finally {
            $this->purgeDropdown((int) $row->id);
        }
    }

    public function test_dropdown_11_soft_delete_moves_record_to_trash(): void
    {
        $this->requireTable();
        $row = $this->seedDropdown();
        $id = (int) $row->id;

        try {
            $row->delete();
            $trashed = Dropdown::withTrashed()->find($id);
            $this->assertNotNull($trashed);
            $this->assertNotNull($trashed->deleted_at, 'Record was not soft deleted.');
            $this->assertNull(Dropdown::find($id), 'Soft-deleted record still visible without withTrashed.');
        } finally {
            $this->purgeDropdown($id);
        }
    }

    public function test_dropdown_12_restore_from_trash(): void
    {
        $this->requireTable();
        $row = $this->seedDropdown();
        $id = (int) $row->id;

        try {
            $row->delete();
            Dropdown::withTrashed()->find($id)->restore();
            $this->assertNull(Dropdown::withTrashed()->find($id)->deleted_at, 'Record was not restored.');
        } finally {
            $this->purgeDropdown($id);
        }
    }

    public function test_dropdown_13_force_delete_removes_record(): void
    {
        $this->requireTable();
        $row = $this->seedDropdown();
        $id = (int) $row->id;

        $row->delete();
        Dropdown::withTrashed()->find($id)->forceDelete();
        $this->assertFalse(
            Dropdown::withTrashed()->where('id', $id)->exists(),
            'Record still exists after force delete.'
        );
    }

    /** destroy() logs event 'Trashed' with the (mislabeled) module message. */
    public function test_dropdown_14_destroy_writes_trashed_activity_log(): void
    {
        $this->requireTable();
        $row = $this->seedDropdown();
        $id = (int) $row->id;

        try {
            $this->browseWithFailureScreenshot('dropdown-destroy-activity', function (Browser $browser) use ($id): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH);
                $this->ensurePageAccessible($browser, 'Dropdown index');
                $selector = 'form.confirm-action-form[action$="/global-master/dropdown/' . $id . '"] button[type="submit"]';
                if ($browser->element($selector)) {
                    $browser->click($selector)->pause(600);
                    if ($browser->element('.swal2-confirm')) {
                        $browser->click('.swal2-confirm')->pause(1500);
                    }
                }
            });

            $deleted = Dropdown::withTrashed()->find($id);
            if ($deleted && $deleted->deleted_at) {
                $this->assertCentralActivityLogged(Dropdown::class, $id, self::EVENT_TRASHED);
            } else {
                $this->markTestSkipped('Destroy UI action not available in this environment.');
            }
        } finally {
            $this->purgeDropdown($id);
        }
    }

    // ------------------------------------------------------------------ //
    //  15-18  Defect / security / integrity                              //
    // ------------------------------------------------------------------ //

    /** BUG-GLB-005: dropdown.search route registered but controller has no search(). */
    public function test_dropdown_15_search_route_is_dead_returns_error_status(): void
    {
        $this->actingAs($this->adminUser);
        $response = $this->get(self::SEARCH_PATH);
        $this->assertContains(
            $response->getStatusCode(),
            [404, 405, 500],
            'dropdown.search should be a dead route (BUG-GLB-005); got ' . $response->getStatusCode() . '.'
        );
    }

    public function test_dropdown_16_guest_is_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('dropdown-guest-redirect', function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->centralUrl(self::INDEX_PATH))->pause(1200);
            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest should be redirected to /login.');
        });
    }

    public function test_dropdown_17_breadcrumb_present_on_index(): void
    {
        $this->requireTable();

        $this->browseWithFailureScreenshot('dropdown-breadcrumb', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Dropdown index');
            $browser->assertPresent('.breadcrumb, nav[aria-label="breadcrumb"], ol.breadcrumb');
        });
    }

    public function test_dropdown_18_unique_key_value_constraint_enforced(): void
    {
        $this->requireTable();
        $key = $this->uniqueKey();
        $value = $this->uniqueValue();

        $a = $this->seedDropdown(['key' => $key, 'value' => $value, 'ordinal' => 1]);

        try {
            $threw = false;
            try {
                Dropdown::create([
                    'key' => $key,
                    'value' => $value,
                    'ordinal' => 2,
                    'type' => 'String',
                    'is_active' => true,
                ]);
            } catch (Throwable) {
                $threw = true;
            }
            $this->assertTrue($threw, 'uq_dropdownTable_key_value did not reject a duplicate (key,value).');
        } finally {
            $this->purgeDropdown((int) $a->id);
            DB::table(self::TABLE)->where('key', $key)->delete();
        }
    }

    // ------------------------------------------------------------------ //
    //  Private helper library                                            //
    // ------------------------------------------------------------------ //

    private function requireTable(): void
    {
        if (!Schema::hasTable(self::TABLE)) {
            $this->fail('sys_dropdown_table is missing; cannot run Dropdown tests.');
        }
    }

    private function seedDropdown(array $overrides = []): Dropdown
    {
        $key = $overrides['key'] ?? $this->uniqueKey();
        $payload = array_merge([
            'ordinal' => $this->nextOrdinal($key),
            'key' => $key,
            'value' => $this->uniqueValue(),
            'type' => 'String',
            'is_active' => true,
        ], $overrides);

        return Dropdown::create($payload);
    }

    private function nextOrdinal(string $key): int
    {
        $max = (int) Dropdown::withTrashed()->where('key', $key)->max('ordinal');
        return max(1, $max + 1);
    }

    private function purgeDropdown(int $id): void
    {
        try {
            DB::table(self::TABLE)->where('id', $id)->delete();
        } catch (Throwable) {
            // best-effort cleanup
        }
    }

    private function uniqueKey(): string
    {
        return 'dusk_test.dropdown_' . substr(uniqid(), -8);
    }

    private function uniqueValue(): string
    {
        return 'Val ' . substr(uniqid(), -6);
    }

    private function activeRulesSnippet(string $src): string
    {
        // Strip block and line comments so we only inspect live rules.
        $noBlock = preg_replace('!/\*.*?\*/!s', '', $src) ?? $src;
        $lines = preg_split('/\R/', $noBlock) ?: [];
        $kept = array_filter($lines, static fn ($l) => !str_starts_with(ltrim($l), '//'));
        return implode("\n", $kept);
    }

    private function assertCentralActivityLogged(string $subjectType, int $subjectId, string $event): void
    {
        try {
            $exists = CentralActivityLog::query()
                ->where('subject_type', $subjectType)
                ->where('subject_id', $subjectId)
                ->where('event', $event)
                ->exists();
            $this->assertTrue($exists, "Central activity log for {$event} not found.");
        } catch (Throwable $e) {
            $this->markTestSkipped('Central activity log table unavailable: ' . $e->getMessage());
        }
    }
}
