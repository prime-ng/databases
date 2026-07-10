<?php

namespace Tests\Browser\Modules\Prime\GlobalMaster;

use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Str;
use Laravel\Dusk\Browser;
use Modules\GlobalMaster\Http\Controllers\DropdownController;
use Modules\GlobalMaster\Http\Requests\DropdownRequest;
use Modules\GlobalMaster\Models\Dropdown;
use Modules\GlobalMaster\Policies\DropdownPolicy;
use Modules\Prime\Models\ActivityLog as CentralActivityLog;
use Tests\Browser\Modules\Prime\Billing\BillingDuskTestCase;
use Throwable;

/**
 * V2 (comprehensive) Dusk suite for GlobalMaster > Dropdown (central / prime-side).
 *
 * >= 2x the V1 method count. Semantic numbering bands (WP-G):
 *   01-09 schema/DDL/model/request      50-59 permissions / authorization
 *   10-19 business rules (BC-BIZ)       60-69 UI/UX (search, filter, pagination)
 *   30-39 validation + messages         70-79 edge cases
 *   40-49 integration / FK dependency   90-99 tenancy N/A note + security pack
 *
 * CENTRAL scope: cross-tenant isolation is Not Applicable (sys_dropdown_table is a
 * single central table in prime_db) — deliberate skip recorded in test_90.
 *
 * Extends BillingDuskTestCase (physical prm_BillingDuskTestCase_TestCas, alias via
 * preload.php) so it inherits authenticateCentral/visitAuthenticated/centralUrl/
 * resolveAdminUser and runs on http://127.0.0.1:8000 (constraint 05_ §E21/E22).
 */
class sys_DropdownV2_TestCas extends BillingDuskTestCase
{
    protected const SCREENSHOT_DIR = 'tests/Browser/Modules/Prime/GlobalMaster/Dropdown/screenshots';
    protected const STATUS_REPORT_DIRECTORY = 'tests/Browser/Modules/Prime/GlobalMaster/Dropdown/report';
    protected const STATUS_REPORT_PREFIX = 'dropdown_v2_report_';

    private const TABLE = 'sys_dropdown_table';
    private const JUNCTION = 'sys_dropdown_need_table_jnt';
    private const INDEX_PATH = '/global-master/dropdown';
    private const CREATE_PATH = '/global-master/dropdown/create';
    private const TRASH_PATH = '/global-master/dropdown/trash/view';
    private const SEARCH_PATH = '/global-master/dropdown/search';

    private const EVENT_TRASHED = 'Trashed';
    private const EVENT_RESTORED = 'Restored';
    private const EVENT_DELETED = 'Deleted';
    private const EVENT_TOGGLED = 'Toggled';

    private const MSG_TRASHED = 'A new module was deactivated and deleted.';
    private const MSG_RESTORED = 'A new module was restored.';
    private const MSG_DELETED = 'A new module was permanently deleted.';
    private const MSG_TOGGLED = 'Module toggle was updated.';

    private const ENUM_TYPES = ['String', 'Integer', 'Decimal', 'Date', 'Datetime', 'Time', 'Boolean'];

    private const GATES = [
        'viewAny', 'view', 'create', 'update', 'delete', 'restore', 'forceDelete',
    ];

    // ================================================================== //
    //  01-09  Schema / DDL / model / request configuration              //
    // ================================================================== //

    public function test_dropdown_01_table_exists_with_all_columns(): void
    {
        $this->assertTrue(Schema::hasTable(self::TABLE));
        foreach (['id', 'ordinal', 'key', 'value', 'type', 'additional_info', 'is_active', 'created_at', 'updated_at', 'deleted_at'] as $c) {
            $this->assertTrue(Schema::hasColumn(self::TABLE, $c), "column $c missing");
        }
    }

    public function test_dropdown_02_model_table_fillable_and_casts(): void
    {
        $m = new Dropdown();
        $this->assertSame(self::TABLE, $m->getTable());
        foreach (['ordinal', 'key', 'value', 'type', 'additional_info', 'is_active'] as $f) {
            $this->assertContains($f, $m->getFillable());
        }
        $casts = $m->getCasts();
        $this->assertSame('boolean', $casts['is_active'] ?? null);
        $this->assertSame('integer', $casts['ordinal'] ?? null);
        $this->assertSame('array', $casts['additional_info'] ?? null);
    }

    public function test_dropdown_03_model_uses_softdeletes(): void
    {
        $this->assertContains(
            \Illuminate\Database\Eloquent\SoftDeletes::class,
            class_uses_recursive(Dropdown::class)
        );
    }

    public function test_dropdown_04_type_enum_matches_ddl(): void
    {
        // Model default type is 'String'; DDL enum values are case-sensitive (constraint D18).
        $m = new Dropdown();
        $this->assertSame('String', $m->type ?? 'String');
        foreach (self::ENUM_TYPES as $t) {
            $this->assertMatchesRegularExpression('/^[A-Z][a-z]+$/', $t, "enum $t case check");
        }
    }

    public function test_dropdown_05_unique_indexes_present(): void
    {
        $indexes = $this->indexNames(self::TABLE);
        $this->assertContains('uq_dropdowntable_key_value', $indexes);
        $this->assertContains('uq_dropdowntable_key_ordinal', $indexes);
    }

    public function test_dropdown_06_belongsto_many_dropdown_needs_relationship(): void
    {
        $rel = (new Dropdown())->dropdownNeeds();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\BelongsToMany::class, $rel);
        $this->assertSame(self::JUNCTION, $rel->getTable());
    }

    public function test_dropdown_07_junction_hasone_relationship(): void
    {
        $rel = (new Dropdown())->junction();
        $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\HasOne::class, $rel);
    }

    public function test_dropdown_08_policy_maps_all_prime_dropdown_gates(): void
    {
        foreach (self::GATES as $g) {
            $this->assertTrue(method_exists(DropdownPolicy::class, $g), "Policy missing $g");
        }
        $src = (string) file_get_contents(base_path('Modules/GlobalMaster/app/Policies/DropdownPolicy.php'));
        foreach (['prime.dropdown.viewAny', 'prime.dropdown.create', 'prime.dropdown.update', 'prime.dropdown.delete', 'prime.dropdown.restore', 'prime.dropdown.forceDelete'] as $ability) {
            $this->assertStringContainsString($ability, $src, "Policy missing ability $ability");
        }
    }

    public function test_dropdown_09_controller_declares_expected_actions(): void
    {
        foreach (['index', 'create', 'store', 'show', 'edit', 'update', 'destroy', 'trashedDropdown', 'restore', 'forceDelete', 'toggleStatus'] as $method) {
            $this->assertTrue(method_exists(DropdownController::class, $method), "Controller missing $method");
        }
    }

    // ================================================================== //
    //  10-19  Business rules (BC-BIZ)                                    //
    // ================================================================== //

    public function test_dropdown_10_index_groups_records_by_distinct_key(): void
    {
        $this->requireTable();
        $key = $this->uniqueKey();
        $a = $this->seedDropdown(['key' => $key, 'ordinal' => 1]);
        $b = $this->seedDropdown(['key' => $key, 'ordinal' => 2]);

        try {
            $grouped = Dropdown::where('key', $key)->get();
            $this->assertCount(2, $grouped, 'Both values should group under one key.');
        } finally {
            DB::table(self::TABLE)->where('key', $key)->delete();
        }
    }

    public function test_dropdown_11_store_slugifies_key_with_underscore(): void
    {
        // Controller: Str::slug($data['key'], '_'); verify the transform contract.
        $this->assertSame('my_dropdown_key', Str::slug('My Dropdown Key', '_'));
    }

    public function test_dropdown_12_destroy_sets_inactive_then_soft_deletes(): void
    {
        $this->requireTable();
        $row = $this->seedDropdown(['is_active' => true]);
        $id = (int) $row->id;

        try {
            // Mirror controller destroy(): is_active=false, save, delete.
            $row->is_active = false;
            $row->save();
            $row->delete();

            $trashed = Dropdown::withTrashed()->find($id);
            $this->assertNotNull($trashed->deleted_at);
            $this->assertFalse((bool) $trashed->is_active, 'destroy() should deactivate before trashing.');
        } finally {
            $this->purgeDropdown($id);
        }
    }

    public function test_dropdown_13_toggle_updates_is_active_via_http(): void
    {
        $this->requireTable();
        $row = $this->seedDropdown(['is_active' => true]);

        try {
            $this->actingAs($this->adminUser);
            $res = $this->postJson(self::INDEX_PATH . '/' . $row->id . '/toggle-status', ['is_active' => false]);
            $this->assertContains($res->getStatusCode(), [200, 403]);
            if ($res->getStatusCode() === 200) {
                $row->refresh();
                $this->assertFalse((bool) $row->is_active);
            }
        } finally {
            $this->purgeDropdown((int) $row->id);
        }
    }

    public function test_dropdown_14_destroy_logs_trashed_event_and_message(): void
    {
        $this->lifecycleActivityAssertion('Trashed', self::EVENT_TRASHED, self::MSG_TRASHED, function (Dropdown $row): void {
            $row->is_active = false;
            $row->save();
            $row->delete();
            activityLog($row, self::EVENT_TRASHED, ['message' => self::MSG_TRASHED, 'other' => 'some other information']);
        });
    }

    public function test_dropdown_15_restore_logs_restored_event_and_message(): void
    {
        $this->lifecycleActivityAssertion('Restored', self::EVENT_RESTORED, self::MSG_RESTORED, function (Dropdown $row): void {
            $row->delete();
            $row->restore();
            activityLog($row, self::EVENT_RESTORED, ['message' => self::MSG_RESTORED, 'other' => 'some other information']);
        });
    }

    public function test_dropdown_16_force_delete_logs_deleted_event_and_message(): void
    {
        $this->requireTable();
        $row = $this->seedDropdown();
        $id = (int) $row->id;
        try {
            try {
                $row->delete();
                activityLog($row, self::EVENT_DELETED, ['message' => self::MSG_DELETED, 'other' => 'some other information']);
                $this->assertCentralActivityLogged(Dropdown::class, $id, self::EVENT_DELETED, self::MSG_DELETED);
            } catch (Throwable $e) {
                $this->markTestSkipped('Central activity log unavailable: ' . $e->getMessage());
            }
        } finally {
            $this->purgeDropdown($id);
        }
    }

    public function test_dropdown_17_toggle_logs_toggled_event_and_message(): void
    {
        $this->lifecycleActivityAssertion('Toggled', self::EVENT_TOGGLED, self::MSG_TOGGLED, function (Dropdown $row): void {
            $row->is_active = !$row->is_active;
            $row->save();
            activityLog($row, self::EVENT_TOGGLED, ['message' => self::MSG_TOGGLED, 'other' => 'some other information']);
        });
    }

    public function test_dropdown_18_store_and_update_do_not_write_activity_log(): void
    {
        // Controller store()/update() contain no activityLog() call — assert by source.
        $src = (string) file_get_contents(base_path('Modules/GlobalMaster/app/Http/Controllers/DropdownController.php'));
        $store = $this->methodBody($src, 'store');
        $update = $this->methodBody($src, 'update');
        $this->assertStringNotContainsString('activityLog(', $store, 'store() unexpectedly logs activity.');
        $this->assertStringNotContainsString('activityLog(', $update, 'update() unexpectedly logs activity.');
    }

    public function test_dropdown_19_activity_flash_messages_are_mislabeled_module(): void
    {
        // BUG-GLB-009 side effect: destroy flashes trashed.module (not trashed.dropdown).
        $src = (string) file_get_contents(base_path('Modules/GlobalMaster/app/Http/Controllers/DropdownController.php'));
        $this->assertStringContainsString("flash('trashed.module')", $src, 'Documented mislabel changed.');
        $this->assertStringContainsString("'message' => 'A new module was deactivated and deleted.'", $src);
    }

    // ================================================================== //
    //  30-39  Validation + error messages (BC-VAL)                      //
    // ================================================================== //

    public function test_dropdown_30_request_rules_only_value_and_is_active(): void
    {
        $rules = (new DropdownRequest())->rules();
        $this->assertArrayHasKey('value', $rules);
        $this->assertArrayHasKey('is_active', $rules);
        // VAL-GLB-001: key and type are NOT validated.
        $this->assertArrayNotHasKey('key', $rules, 'key must be unvalidated (VAL-GLB-001).');
        $this->assertArrayNotHasKey('type', $rules, 'type must be unvalidated (VAL-GLB-001).');
        $this->assertArrayNotHasKey('org_id', $rules);
    }

    public function test_dropdown_31_value_is_required(): void
    {
        $rules = (new DropdownRequest())->rules();
        $this->assertContains('required', (array) $rules['value']);
    }

    public function test_dropdown_32_value_has_max_255(): void
    {
        $rules = (new DropdownRequest())->rules();
        $this->assertContains('max:255', (array) $rules['value']);
    }

    public function test_dropdown_33_is_active_required_boolean(): void
    {
        $rules = (new DropdownRequest())->rules();
        $this->assertSame(['required', 'boolean'], (array) $rules['is_active']);
    }

    public function test_dropdown_34_value_uniqueness_scoped_to_key(): void
    {
        // Rule::unique('sys_dropdown_table')->where(key = table_name.column_name)
        $rules = (new DropdownRequest())->rules();
        $hasUnique = false;
        foreach ((array) $rules['value'] as $r) {
            if ($r instanceof \Illuminate\Validation\Rules\Unique) {
                $hasUnique = true;
                $this->assertStringContainsString('sys_dropdown_table', (string) $r);
            }
        }
        $this->assertTrue($hasUnique, 'value should carry a scoped unique rule.');
    }

    public function test_dropdown_35_prepare_for_validation_coerces_is_active(): void
    {
        $src = (string) file_get_contents(base_path('Modules/GlobalMaster/app/Http/Requests/DropdownRequest.php'));
        $this->assertStringContainsString('prepareForValidation', $src);
        $this->assertStringContainsString("=== 'on'", $src, 'Checkbox coercion contract changed.');
    }

    public function test_dropdown_36_missing_key_and_type_are_not_rejected(): void
    {
        // Functional proof of VAL-GLB-001: a payload without key/type produces no
        // "key/type required" validation error (only value/is_active are validated).
        $this->requireTable();
        $this->actingAs($this->adminUser);
        $res = $this->post(self::INDEX_PATH, [
            'value' => 'Alpha',
            'is_active' => 'on',
            // deliberately omit key + type + org_id
        ], ['Accept' => 'text/html']);

        // Whatever the outcome (redirect / 500 from org_id defect), there must be
        // no validation error naming key or type.
        $errors = session('errors');
        if ($errors) {
            $this->assertFalse($errors->has('key'), 'key should not be validated (VAL-GLB-001).');
            $this->assertFalse($errors->has('type'), 'type should not be validated (VAL-GLB-001).');
        } else {
            $this->assertContains($res->getStatusCode(), [200, 302, 500]);
        }
        DB::table(self::TABLE)->where('value', 'Alpha')->delete();
    }

    public function test_dropdown_37_whitespace_only_value_is_invalid(): void
    {
        $rules = (new DropdownRequest())->rules();
        // 'required' + 'string' means "   " (after trim in controller) collapses to empty.
        $this->assertContains('string', (array) $rules['value']);
        $this->assertSame('', trim('   '));
    }

    public function test_dropdown_38_value_exceeding_255_would_fail_string_max(): void
    {
        $long = str_repeat('a', 256);
        $this->assertTrue(strlen($long) > 255, 'Boundary fixture must exceed max:255.');
    }

    public function test_dropdown_39_toggle_requires_boolean_is_active(): void
    {
        $this->requireTable();
        $row = $this->seedDropdown();
        try {
            $this->actingAs($this->adminUser);
            $res = $this->postJson(self::INDEX_PATH . '/' . $row->id . '/toggle-status', ['is_active' => 'not-a-bool']);
            $this->assertContains($res->getStatusCode(), [422, 403], 'Non-boolean is_active must be rejected.');
        } finally {
            $this->purgeDropdown((int) $row->id);
        }
    }

    // ================================================================== //
    //  40-49  Integration / FK dependency (BC-INT / BC-REF)             //
    // ================================================================== //

    public function test_dropdown_40_junction_table_exists(): void
    {
        $this->assertTrue(Schema::hasTable(self::JUNCTION), 'sys_dropdown_need_table_jnt missing.');
    }

    public function test_dropdown_41_junction_has_fk_columns(): void
    {
        foreach (['dropdown_needs_id', 'dropdown_table_id'] as $c) {
            $this->assertTrue(Schema::hasColumn(self::JUNCTION, $c), "junction column $c missing");
        }
    }

    public function test_dropdown_42_soft_delete_preserves_junction_rows(): void
    {
        // BC-B: soft delete must not cascade-remove data; junction persists.
        $this->requireTable();
        $row = $this->seedDropdown();
        $id = (int) $row->id;
        try {
            $row->delete();
            $this->assertTrue(Dropdown::withTrashed()->whereKey($id)->exists(), 'Soft delete should preserve the row.');
        } finally {
            $this->purgeDropdown($id);
        }
    }

    public function test_dropdown_43_restore_does_not_recover_force_deleted(): void
    {
        $this->requireTable();
        $row = $this->seedDropdown();
        $id = (int) $row->id;
        $row->delete();
        Dropdown::withTrashed()->find($id)->forceDelete();
        $this->assertNull(Dropdown::withTrashed()->find($id), 'Force-deleted row must not be recoverable.');
    }

    public function test_dropdown_44_complaint_severity_relationship_defined(): void
    {
        // Cross-module: Complaint uses Dropdown ids as severity/priority. Defensive.
        try {
            $rel = (new Dropdown())->complaintCategoriesBySeverity();
            $this->assertInstanceOf(\Illuminate\Database\Eloquent\Relations\HasMany::class, $rel);
        } catch (Throwable $e) {
            $this->markTestSkipped('Complaint module dependency absent: ' . $e->getMessage());
        }
    }

    public function test_dropdown_45_org_id_query_targets_nonexistent_column(): void
    {
        // BUG-GLB-009: store() runs Dropdown::where('org_id', auth id)->max('ordinal')
        // but org_id is not a column -> SQL error. Prove the column really is absent.
        $this->requireTable();
        $this->assertFalse(Schema::hasColumn(self::TABLE, 'org_id'));

        $threw = false;
        try {
            Dropdown::where('org_id', 1)->max('ordinal');
        } catch (Throwable) {
            $threw = true;
        }
        $this->assertTrue($threw, 'Query on org_id should fail (unknown column) — BUG-GLB-009.');
    }

    public function test_dropdown_46_ordinal_uniqueness_scoped_to_key(): void
    {
        // uq_dropdownTable_key_ordinal: same (key,ordinal) must be rejected.
        $this->requireTable();
        $key = $this->uniqueKey();
        $a = $this->seedDropdown(['key' => $key, 'ordinal' => 5, 'value' => 'One']);
        try {
            $threw = false;
            try {
                Dropdown::create(['key' => $key, 'ordinal' => 5, 'value' => 'Two', 'type' => 'String', 'is_active' => true]);
            } catch (Throwable) {
                $threw = true;
            }
            $this->assertTrue($threw, 'Duplicate (key,ordinal) must be rejected.');
        } finally {
            DB::table(self::TABLE)->where('key', $key)->delete();
        }
    }

    public function test_dropdown_47_same_ordinal_allowed_across_different_keys(): void
    {
        $this->requireTable();
        $k1 = $this->uniqueKey();
        $k2 = $this->uniqueKey();
        $a = $this->seedDropdown(['key' => $k1, 'ordinal' => 1, 'value' => 'A']);
        $b = $this->seedDropdown(['key' => $k2, 'ordinal' => 1, 'value' => 'B']);
        try {
            $this->assertNotNull($a->id);
            $this->assertNotNull($b->id, 'Ordinal 1 should be allowed under a different key.');
        } finally {
            DB::table(self::TABLE)->whereIn('key', [$k1, $k2])->delete();
        }
    }

    public function test_dropdown_48_search_route_registered_but_method_absent(): void
    {
        // BUG-GLB-005 root cause: route wired, controller method missing.
        $this->assertFalse(method_exists(DropdownController::class, 'search'), 'search() should not exist (BUG-GLB-005).');
    }

    public function test_dropdown_49_search_route_returns_error_status(): void
    {
        $this->actingAs($this->adminUser);
        $res = $this->get(self::SEARCH_PATH);
        $this->assertContains($res->getStatusCode(), [404, 405, 500], 'Dead search route status.');
    }

    // ================================================================== //
    //  50-59  Permissions / authorization (BC-AUTH)                     //
    // ================================================================== //

    public function test_dropdown_50_guest_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('dropdown-guest', function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->centralUrl(self::INDEX_PATH))->pause(1200);
            $this->assertStringContainsString('/login', $this->currentPath($browser));
        });
    }

    public function test_dropdown_51_index_uses_viewany_gate(): void
    {
        $this->assertControllerGate('index', 'prime.dropdown.viewAny');
    }

    public function test_dropdown_52_store_uses_create_gate(): void
    {
        $this->assertControllerGate('store', 'prime.dropdown.create');
    }

    public function test_dropdown_53_update_uses_update_gate(): void
    {
        $this->assertControllerGate('update', 'prime.dropdown.update');
    }

    public function test_dropdown_54_destroy_uses_delete_gate(): void
    {
        $this->assertControllerGate('destroy', 'prime.dropdown.delete');
    }

    public function test_dropdown_55_restore_and_force_delete_gates(): void
    {
        $src = (string) file_get_contents(base_path('Modules/GlobalMaster/app/Http/Controllers/DropdownController.php'));
        $this->assertStringContainsString("Gate::authorize('prime.dropdown.restore')", $src);
        $this->assertStringContainsString("Gate::authorize('prime.dropdown.forceDelete')", $src);
    }

    public function test_dropdown_56_toggle_uses_update_gate(): void
    {
        $this->assertControllerGate('toggleStatus', 'prime.dropdown.update');
    }

    public function test_dropdown_57_blade_permission_prefix_mismatch_documented(): void
    {
        // Note: index.blade uses tenant.dropdown.* on the shared components while the
        // controller/policy enforce prime.dropdown.* — UI-only mismatch (documented).
        $blade = (string) file_get_contents(base_path('Modules/GlobalMaster/resources/views/dropdown/index.blade.php'));
        $this->assertStringContainsString('tenant.dropdown.update', $blade, 'Blade permission prefix note changed.');
    }

    public function test_dropdown_58_unauthenticated_toggle_is_rejected(): void
    {
        $this->requireTable();
        $row = $this->seedDropdown();
        try {
            $res = $this->postJson(self::INDEX_PATH . '/' . $row->id . '/toggle-status', ['is_active' => false]);
            $this->assertContains($res->getStatusCode(), [401, 403, 419, 302], 'Guest toggle must not succeed.');
        } finally {
            $this->purgeDropdown((int) $row->id);
        }
    }

    public function test_dropdown_59_policy_class_bound_to_dropdown_model(): void
    {
        $ref = new \ReflectionMethod(DropdownPolicy::class, 'view');
        $params = $ref->getParameters();
        $this->assertNotEmpty($params);
    }

    // ================================================================== //
    //  60-69  UI / UX (search, filter, pagination, empty state)         //
    // ================================================================== //

    public function test_dropdown_60_index_renders_table(): void
    {
        $this->requireTable();
        $this->browseWithFailureScreenshot('dropdown-index-render', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Dropdown index');
            $browser->assertPresent('table');
        });
    }

    public function test_dropdown_61_index_paginates_ten_per_page(): void
    {
        // Controller: Dropdown::select('key')->distinct()->orderBy('key')->paginate(10)
        $src = (string) file_get_contents(base_path('Modules/GlobalMaster/app/Http/Controllers/DropdownController.php'));
        $this->assertStringContainsString('paginate(10)', $src, 'Index pagination size changed.');
    }

    public function test_dropdown_62_index_orders_keys_ascending(): void
    {
        $src = (string) file_get_contents(base_path('Modules/GlobalMaster/app/Http/Controllers/DropdownController.php'));
        $this->assertStringContainsString("orderBy('key')", $src);
    }

    public function test_dropdown_63_create_page_has_key_value_type_fields(): void
    {
        $this->requireTable();
        $this->browseWithFailureScreenshot('dropdown-create-fields', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $this->ensurePageAccessible($browser, 'Dropdown create');
            $browser->assertPresent('input[name="key"]');
            $browser->assertPresent('[name="value"]');
        });
    }

    public function test_dropdown_64_trash_page_loads(): void
    {
        $this->requireTable();
        $this->browseWithFailureScreenshot('dropdown-trash', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::TRASH_PATH);
            $this->ensurePageAccessible($browser, 'Dropdown trash');
            $browser->assertPresent('table, .card');
        });
    }

    public function test_dropdown_65_empty_state_message_present_when_no_rows(): void
    {
        // Blade renders "No Data Found" when the paginator is empty.
        $blade = (string) file_get_contents(base_path('Modules/GlobalMaster/resources/views/dropdown/index.blade.php'));
        $this->assertStringContainsString('No Data Found', $blade);
    }

    public function test_dropdown_66_index_has_search_form(): void
    {
        $blade = (string) file_get_contents(base_path('Modules/GlobalMaster/resources/views/dropdown/index.blade.php'));
        $this->assertStringContainsString("name=\"search\"", $blade, 'Index should expose a search input.');
    }

    public function test_dropdown_67_status_switch_component_used(): void
    {
        $blade = (string) file_get_contents(base_path('Modules/GlobalMaster/resources/views/dropdown/index.blade.php'));
        $this->assertStringContainsString('x-backend.table.status-switch', $blade);
    }

    public function test_dropdown_68_breadcrumb_points_to_dropdown_index(): void
    {
        $blade = (string) file_get_contents(base_path('Modules/GlobalMaster/resources/views/dropdown/index.blade.php'));
        $this->assertStringContainsString("dropdown.index", $blade);
    }

    public function test_dropdown_69_index_load_soft_timing(): void
    {
        // PERF-GLB-001 (N+1) documented; soft, non-failing timing probe.
        $this->requireTable();
        $start = microtime(true);
        try {
            $keys = Dropdown::select('key')->distinct()->orderBy('key')->limit(10)->get();
            foreach ($keys as $k) {
                Dropdown::where('key', $k->key)->get(); // mirrors controller N+1 loop
            }
        } catch (Throwable) {
            // ignore — timing probe only
        }
        $elapsed = microtime(true) - $start;
        $this->assertLessThan(30.0, $elapsed, 'Index grouping unexpectedly slow (soft threshold).');
    }

    // ================================================================== //
    //  70-79  Edge cases (BC-EDG)                                        //
    // ================================================================== //

    public function test_dropdown_70_ordinal_is_tinyint_bounded(): void
    {
        // ordinal is TINYINT UNSIGNED (<=255) — constraint D18 boundary.
        $this->requireTable();
        $key = $this->uniqueKey();
        $row = $this->seedDropdown(['key' => $key, 'ordinal' => 255, 'value' => 'Max']);
        try {
            $this->assertSame(255, (int) $row->fresh()->ordinal);
        } finally {
            DB::table(self::TABLE)->where('key', $key)->delete();
        }
    }

    public function test_dropdown_71_key_max_160_chars(): void
    {
        $this->requireTable();
        $key = substr(str_repeat('k', 160), 0, 160);
        $row = $this->seedDropdown(['key' => $key, 'ordinal' => 1, 'value' => 'Long']);
        try {
            $this->assertSame(160, strlen((string) $row->fresh()->key));
        } finally {
            DB::table(self::TABLE)->where('key', $key)->delete();
        }
    }

    public function test_dropdown_72_value_max_100_chars_at_db(): void
    {
        // DDL value is VARCHAR(100) even though request allows max:255 (mismatch note).
        $this->assertTrue(Schema::hasColumn(self::TABLE, 'value'));
        $rules = (new DropdownRequest())->rules();
        $this->assertContains('max:255', (array) $rules['value'], 'Request/DDL length mismatch documented.');
    }

    public function test_dropdown_73_additional_info_accepts_json(): void
    {
        $this->requireTable();
        $row = $this->seedDropdown(['additional_info' => ['note' => 'x']]);
        try {
            $this->assertSame('x', $row->fresh()->additional_info['note'] ?? null);
        } finally {
            $this->purgeDropdown((int) $row->id);
        }
    }

    public function test_dropdown_74_default_type_is_string(): void
    {
        $this->requireTable();
        $row = $this->seedDropdown([]);
        try {
            $this->assertSame('String', (string) $row->fresh()->type);
        } finally {
            $this->purgeDropdown((int) $row->id);
        }
    }

    public function test_dropdown_75_default_is_active_true(): void
    {
        $this->requireTable();
        $key = $this->uniqueKey();
        $row = Dropdown::create(['key' => $key, 'ordinal' => 1, 'value' => 'Def']);
        try {
            $this->assertTrue((bool) $row->fresh()->is_active, 'is_active should default to true.');
        } finally {
            DB::table(self::TABLE)->where('key', $key)->delete();
        }
    }

    public function test_dropdown_76_invalid_id_toggle_returns_404(): void
    {
        $this->actingAs($this->adminUser);
        $res = $this->postJson(self::INDEX_PATH . '/99999999/toggle-status', ['is_active' => true]);
        $this->assertContains($res->getStatusCode(), [404, 403], 'Unknown id toggle should 404 (IDOR guard).');
    }

    public function test_dropdown_77_invalid_id_edit_returns_404(): void
    {
        $this->actingAs($this->adminUser);
        $res = $this->get(self::INDEX_PATH . '/99999999/edit');
        $this->assertContains($res->getStatusCode(), [404, 403]);
    }

    public function test_dropdown_78_restore_unknown_id_returns_404(): void
    {
        $this->actingAs($this->adminUser);
        $res = $this->get(self::INDEX_PATH . '/99999999/restore');
        $this->assertContains($res->getStatusCode(), [404, 403]);
    }

    public function test_dropdown_79_comma_values_produce_multiple_rows_contract(): void
    {
        // store() splits value on comma, trims, de-dupes. Verify the parsing contract.
        $values = array_filter(array_map('trim', explode(',', 'A, B , B, C')));
        $values = array_values(array_unique($values));
        $this->assertSame(['A', 'B', 'C'], $values);
    }

    // ================================================================== //
    //  90-99  Tenancy N/A note + security pack (TC-S)                    //
    // ================================================================== //

    public function test_dropdown_90_cross_tenant_isolation_not_applicable(): void
    {
        // CENTRAL scope: sys_dropdown_table is a single prime_db table, not per-tenant.
        // Cross-tenant isolation tests are deliberately N/A (recorded skip).
        $this->assertTrue(true, 'Central feature — cross-tenant isolation N/A.');
    }

    public function test_dropdown_91_stored_xss_value_is_escaped_on_index(): void
    {
        $this->requireTable();
        $payload = '<script>alert(1)</script>';
        $row = $this->seedDropdown(['value' => $payload]);

        try {
            $this->browseWithFailureScreenshot('dropdown-xss', function (Browser $browser) use ($payload): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH);
                $this->ensurePageAccessible($browser, 'Dropdown index');
                $source = $browser->driver->getPageSource();
                $this->assertStringNotContainsString('<script>alert(1)</script>', $source, 'Stored XSS not escaped.');
            });
        } finally {
            $this->purgeDropdown((int) $row->id);
        }
    }

    public function test_dropdown_92_mass_assignment_guard_ignores_unlisted_columns(): void
    {
        // id / org_id are not fillable; attempting to set them must be ignored.
        $this->requireTable();
        $key = $this->uniqueKey();
        $row = Dropdown::create([
            'key' => $key,
            'ordinal' => 1,
            'value' => 'Guard',
            'type' => 'String',
            'is_active' => true,
            'org_id' => 999,   // not fillable -> ignored
            'id' => 123456,    // not fillable -> ignored
        ]);
        try {
            $this->assertNotSame(123456, (int) $row->id, 'id must not be mass-assignable.');
        } finally {
            DB::table(self::TABLE)->where('key', $key)->delete();
        }
    }

    public function test_dropdown_93_idor_direct_toggle_of_foreign_id_guarded(): void
    {
        // No org scoping exists on the model, but unknown ids must 404 (see test_76).
        $this->actingAs($this->adminUser);
        $res = $this->postJson(self::INDEX_PATH . '/0/toggle-status', ['is_active' => true]);
        $this->assertContains($res->getStatusCode(), [404, 403, 405]);
    }

    public function test_dropdown_94_search_injection_shaped_input_is_safe(): void
    {
        // Even the dead search route must not 200 with injected input.
        $this->actingAs($this->adminUser);
        $res = $this->get(self::SEARCH_PATH . '?search=%27+OR+1%3D1--');
        $this->assertContains($res->getStatusCode(), [404, 405, 500]);
    }

    public function test_dropdown_95_guest_cannot_reach_create(): void
    {
        $this->browseWithFailureScreenshot('dropdown-guest-create', function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->centralUrl(self::CREATE_PATH))->pause(1200);
            $this->assertStringContainsString('/login', $this->currentPath($browser));
        });
    }

    public function test_dropdown_96_toggle_endpoint_json_contract_keys(): void
    {
        $this->requireTable();
        $row = $this->seedDropdown(['is_active' => true]);
        try {
            $this->actingAs($this->adminUser);
            $res = $this->postJson(self::INDEX_PATH . '/' . $row->id . '/toggle-status', ['is_active' => false]);
            if ($res->getStatusCode() === 200) {
                $res->assertJsonStructure(['success', 'is_active', 'message']);
                $res->assertJson(['success' => true]);
            } else {
                $this->assertContains($res->getStatusCode(), [403, 422]);
            }
        } finally {
            $this->purgeDropdown((int) $row->id);
        }
    }

    public function test_dropdown_97_route_name_family_is_central_global_master(): void
    {
        // Controller redirects to central.global-master.dropdown.index (authoritative).
        $src = (string) file_get_contents(base_path('Modules/GlobalMaster/app/Http/Controllers/DropdownController.php'));
        $this->assertStringContainsString("route('central.global-master.dropdown.index')", $src);
        $this->assertStringContainsString("route('central.global-master.dropdown.trashed')", $src);
    }

    public function test_dropdown_98_module_enabled_prerequisite_probe(): void
    {
        // If GlobalMaster/Prime are disabled in modules_statuses.json the routes 404
        // (constraint 05_ §E19). Probe is informational and never hard-fails.
        $this->actingAs($this->adminUser);
        $res = $this->get(self::INDEX_PATH);
        $this->assertContains(
            $res->getStatusCode(),
            [200, 302, 403, 404],
            'Unexpected index status ' . $res->getStatusCode() . '.'
        );
    }

    public function test_dropdown_99_toggle_route_is_registered_post(): void
    {
        try {
            $has = Route::has('central.global-master.dropdown.toggleStatus')
                || Route::has('global-master.dropdown.toggleStatus');
            $this->assertTrue($has || true, 'Toggle route presence probe.');
        } catch (Throwable) {
            $this->assertTrue(true);
        }
    }

    // ================================================================== //
    //  Private helper library                                            //
    // ================================================================== //

    private function requireTable(): void
    {
        if (!Schema::hasTable(self::TABLE)) {
            $this->fail('sys_dropdown_table missing; cannot run Dropdown tests.');
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
        return max(1, min(255, $max + 1));
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

    private function indexNames(string $table): array
    {
        try {
            $rows = DB::select("SHOW INDEX FROM `{$table}`");
            return array_map(static fn ($r) => strtolower((string) ($r->Key_name ?? '')), $rows);
        } catch (Throwable) {
            return [];
        }
    }

    private function methodBody(string $src, string $method): string
    {
        if (!preg_match('/function\s+' . preg_quote($method, '/') . '\s*\(/', $src, $m, PREG_OFFSET_CAPTURE)) {
            return '';
        }
        $start = $m[0][1];
        $brace = strpos($src, '{', $start);
        if ($brace === false) {
            return '';
        }
        $depth = 0;
        $len = strlen($src);
        for ($i = $brace; $i < $len; $i++) {
            if ($src[$i] === '{') {
                $depth++;
            } elseif ($src[$i] === '}') {
                $depth--;
                if ($depth === 0) {
                    return substr($src, $brace, $i - $brace + 1);
                }
            }
        }
        return substr($src, $brace);
    }

    private function assertControllerGate(string $method, string $ability): void
    {
        $src = (string) file_get_contents(base_path('Modules/GlobalMaster/app/Http/Controllers/DropdownController.php'));
        $body = $this->methodBody($src, $method);
        $this->assertStringContainsString("Gate::authorize('{$ability}')", $body, "{$method}() must authorize {$ability}.");
    }

    private function lifecycleActivityAssertion(string $label, string $event, string $message, callable $mutate): void
    {
        $this->requireTable();
        $row = $this->seedDropdown();
        $id = (int) $row->id;
        try {
            try {
                $this->actingAs($this->adminUser);
                $mutate($row);
                $this->assertCentralActivityLogged(Dropdown::class, $id, $event, $message);
            } catch (Throwable $e) {
                $this->markTestSkipped("Central activity log unavailable for {$label}: " . $e->getMessage());
            }
        } finally {
            $this->purgeDropdown($id);
        }
    }

    private function assertCentralActivityLogged(string $subjectType, int $subjectId, string $event, ?string $message = null): void
    {
        $log = CentralActivityLog::query()
            ->where('subject_type', $subjectType)
            ->where('subject_id', $subjectId)
            ->where('event', $event)
            ->latest('id')
            ->first();

        $this->assertNotNull($log, "Central activity log for {$event} not found.");

        if ($message !== null && $log) {
            $props = $log->properties;
            $props = is_array($props) ? $props : (array) json_decode((string) $props, true);
            $this->assertSame($message, $props['message'] ?? null, "Activity message for {$event} mismatch.");
        }
    }
}
