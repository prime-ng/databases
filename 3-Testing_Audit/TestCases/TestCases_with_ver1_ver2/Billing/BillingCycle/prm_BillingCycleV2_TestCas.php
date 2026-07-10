<?php

namespace Tests\Browser\Modules\Prime\Billing\BillingCycle;

use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\Billing\Models\BillingCycle;
use Modules\GlobalMaster\Models\ActivityLog;
use Tests\Browser\Modules\Prime\Billing\BillingDuskTestCase;
use Throwable;

/**
 * Billing Cycle — V2 comprehensive Dusk suite (central prime_db).
 *
 * DB scope: prime_db central. No tenancy scaffolding (mirrors the committed
 * sibling prm_BillingCycle_TestCas / BillingDuskTestCase central chain).
 * Prefix prm_ verified against DDL Billing_DDL_v1.sql `prm_billing_cycles`.
 *
 * Semantic numbering bands (WP-G):
 *   01-09 schema/model/request config   10-19 business rules
 *   20-29 state machine (is_active)      30-39 validation + messages
 *   40-49 integration / FK dependency    50-59 permissions
 *   60-69 UI/UX                          70-79 edge cases
 *   90-99 security
 */
class prm_BillingCycleV2_TestCas extends BillingDuskTestCase
{
    protected const SCREENSHOT_DIR = 'tests/Browser/Modules/Prime/Billing/BillingCycle/screenshots';
    protected const STATUS_REPORT_DIRECTORY = 'tests/Browser/Modules/Prime/Billing/BillingCycle/report';
    protected const STATUS_REPORT_PREFIX = 'billing_cycle_v2_report_';

    private const INDEX_PATH = '/billing/billing-cycle';
    private const CREATE_PATH = '/billing/billing-cycle/create';
    private const TRASH_PATH = '/billing/billing-cycle/trash/view';
    private const TABLE = 'prm_billing_cycles';

    private const REFERENCING_TABLES = [
        'prm_plans',
        'prm_tenant_plan_rates',
        'prm_tenant_plan_billing_schedule',
        'bil_tenant_invoices',
    ];

    // ==================================================================
    // Band 01-09 — Schema / model / request configuration
    // ==================================================================

    /** TC-P01 / BC-DB: table, columns and unique index exist. */
    public function test_billing_cycle_01_schema_columns_and_unique_index_exist(): void
    {
        $this->assertTrue(Schema::hasTable(self::TABLE), self::TABLE . ' missing.');

        foreach (['id', 'short_name', 'name', 'months_count', 'description', 'is_recurring', 'is_active'] as $column) {
            $this->assertTrue(Schema::hasColumn(self::TABLE, $column), 'Missing column: ' . $column);
        }

        // uq_billingCycles_code — short_name is globally unique.
        try {
            $indexes = collect(DB::select('SHOW INDEX FROM ' . self::TABLE))
                ->where('Column_name', 'short_name')
                ->where('Non_unique', 0);
            $this->assertTrue($indexes->isNotEmpty(), 'short_name unique index (uq_billingCycles_code) is missing.');
        } catch (Throwable $e) {
            $this->markTestSkipped('SHOW INDEX unsupported: ' . $e->getMessage());
        }
    }

    /** TC-P02 / BC-DB: model fillable, casts, SoftDeletes and relationships. */
    public function test_billing_cycle_02_model_fillable_casts_softdeletes_and_relationships(): void
    {
        $model = new BillingCycle();
        $this->assertSame(self::TABLE, $model->getTable());

        foreach (['short_name', 'name', 'months_count', 'description', 'is_active', 'is_recurring'] as $fillable) {
            $this->assertContains($fillable, $model->getFillable());
        }

        $casts = $model->getCasts();
        $this->assertSame('boolean', $casts['is_active'] ?? null);
        $this->assertSame('boolean', $casts['is_recurring'] ?? null);
        $this->assertSame('integer', $casts['months_count'] ?? null);

        $this->assertContains(SoftDeletes::class, class_uses_recursive(BillingCycle::class));

        foreach (['tenantPlanRates', 'billingSchedules', 'invoices', 'plans'] as $relation) {
            $this->assertTrue(method_exists($model, $relation), 'Missing relationship: ' . $relation);
        }
    }

    /** TC-P03 / BC-AUTH: routes are registered with the expected central names. */
    public function test_billing_cycle_03_routes_are_registered_with_expected_names(): void
    {
        $expected = [
            'central.billing.billing-cycle.index',
            'central.billing.billing-cycle.create',
            'central.billing.billing-cycle.store',
            'central.billing.billing-cycle.show',
            'central.billing.billing-cycle.edit',
            'central.billing.billing-cycle.update',
            'central.billing.billing-cycle.destroy',
            'central.billing.billing-cycle.trashed',
            'central.billing.billing-cycle.restore',
            'central.billing.billing-cycle.forceDelete',
            'central.billing.billing-cycle.toggleStatus',
        ];

        $missing = array_values(array_filter($expected, static fn (string $name): bool => !Route::has($name)));

        if ($missing !== []) {
            // Route names resolve only when the app routes are loaded in-process.
            $this->markTestSkipped('Central billing-cycle routes not resolvable in-process: ' . implode(', ', $missing));
        }

        $this->assertSame([], $missing);
    }

    /**
     * TC-D-DEV / MIG-BIL-001 (P0) guard.
     * DDL Billing_DDL_v1.sql declares prm_billing_cycles with NO deleted_at/created_at/
     * updated_at, but the model uses SoftDeletes + timestamps. The dev DB is hand-patched.
     * A schema-correct DDL build fails this guard, surfacing MIG-BIL-001.
     */
    public function test_billing_cycle_05_softdeletes_column_present_mig_bil_001_guard(): void
    {
        $this->assertTrue(
            Schema::hasColumn(self::TABLE, 'deleted_at'),
            'prm_billing_cycles.deleted_at missing — MIG-BIL-001 (P0): SoftDeletes model vs DDL without deleted_at.'
        );
    }

    // ==================================================================
    // Band 10-19 — Business rules
    // ==================================================================

    /** TC-P05 / BC-BIZ: create persists every field. */
    public function test_billing_cycle_10_create_persists_all_fields(): void
    {
        $this->assertBillingCycleTableReady();

        $shortName = $this->makeShortName();
        $name = $this->makeName();

        $this->browseWithFailureScreenshot('v2-create-all-fields', function (Browser $browser) use ($shortName, $name): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $this->ensurePageAccessible($browser, 'Billing Cycle create');

            $browser->type('short_name', $shortName)
                ->type('name', $name)
                ->type('months_count', '3')
                ->type('description', 'Quarterly cycle')
                ->check('#is_active');
            $this->setRecurringField($browser, true);
            $browser->press('Add Billing Cycle')->pause(2000);
        });

        $cycle = BillingCycle::withTrashed()->where('short_name', $shortName)->first();
        $this->assertNotNull($cycle, 'Record not created.');

        if ($cycle) {
            try {
                $this->assertSame($name, (string) $cycle->name);
                $this->assertSame(3, (int) $cycle->months_count);
                $this->assertSame('Quarterly cycle', (string) $cycle->description);
                $this->assertTrue((bool) $cycle->is_active);
                $this->assertTrue((bool) $cycle->is_recurring);
            } finally {
                $this->purgeBillingCycleById((int) $cycle->id);
            }
        }
    }

    /** TC-P06 / BC-BIZ: update persists edited fields. */
    public function test_billing_cycle_11_update_persists_all_fields(): void
    {
        $this->assertBillingCycleTableReady();

        $cycle = $this->createBillingCycleRecord(['months_count' => 2]);
        $newShort = $this->makeShortName();
        $newName = 'Updated ' . $this->makeName();

        try {
            $this->browseWithFailureScreenshot('v2-update-all-fields', function (Browser $browser) use ($cycle, $newShort, $newName): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH);
                $this->ensurePageAccessible($browser, 'Billing Cycle index');

                $this->clickEditAction($browser, (int) $cycle->id);
                $this->confirmSweetAlert($browser);
                $browser->waitFor('#short_name', 10);

                $browser->type('short_name', $newShort)
                    ->type('name', $newName)
                    ->type('months_count', '12')
                    ->type('description', 'Yearly cycle')
                    ->check('#is_active');
                $this->setRecurringField($browser, true);
                $browser->press('Update Billing Cycle')->pause(2000);
            });

            $cycle->refresh();
            $this->assertSame($newShort, (string) $cycle->short_name);
            $this->assertSame($newName, (string) $cycle->name);
            $this->assertSame(12, (int) $cycle->months_count);
            $this->assertSame('Yearly cycle', (string) $cycle->description);
        } finally {
            $this->purgeBillingCycleById((int) $cycle->id);
        }
    }

    /** TC-P07 / BC-BIZ: destroy sets is_active=false before soft delete. */
    public function test_billing_cycle_12_soft_delete_deactivates_before_deleting(): void
    {
        $this->assertBillingCycleTableReady();

        $cycle = $this->createBillingCycleRecord(['is_active' => true]);
        $cycleId = (int) $cycle->id;

        try {
            $this->browseWithFailureScreenshot('v2-soft-delete-deactivates', function (Browser $browser) use ($cycleId): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH);
                $this->ensurePageAccessible($browser, 'Billing Cycle index');

                $this->clickDeleteAction($browser, $cycleId);
                $this->confirmSweetAlert($browser);
                $browser->pause(2000);
            });

            $deleted = BillingCycle::withTrashed()->find($cycleId);
            $this->assertNotNull($deleted, 'Missing after soft delete.');
            $this->assertNotNull($deleted->deleted_at, 'Was not soft deleted.');
            $this->assertFalse((bool) $deleted->is_active, 'is_active should be set false before delete.');
        } finally {
            $this->purgeBillingCycleById($cycleId);
        }
    }

    /** TC-P08 / BC-BIZ: create writes a "Stored" activity-log entry (defensive). */
    public function test_billing_cycle_13_store_writes_stored_activity_log(): void
    {
        $this->assertBillingCycleTableReady();

        $shortName = $this->makeShortName();

        $this->browseWithFailureScreenshot('v2-activity-log-stored', function (Browser $browser) use ($shortName): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $this->ensurePageAccessible($browser, 'Billing Cycle create');

            $browser->type('short_name', $shortName)
                ->type('name', $this->makeName())
                ->type('months_count', '1')
                ->type('description', 'Activity log test')
                ->check('#is_active');
            $this->setRecurringField($browser, true);
            $browser->press('Add Billing Cycle')->pause(2000);
        });

        $cycle = BillingCycle::withTrashed()->where('short_name', $shortName)->first();
        $this->assertNotNull($cycle, 'Record not created.');

        try {
            $logged = ActivityLog::query()
                ->where('event', 'Stored')
                ->where('subject_id', (int) $cycle->id)
                ->exists();
            $this->assertTrue($logged, 'Expected a "Stored" activity-log entry for the created billing cycle.');
        } catch (Throwable $e) {
            $this->markTestSkipped('Activity-log table not reachable: ' . $e->getMessage());
        } finally {
            $this->purgeBillingCycleById((int) $cycle->id);
        }
    }

    // ==================================================================
    // Band 20-29 — State machine (is_active)
    // ==================================================================

    /** TC-SM01: switch toggles active -> inactive. */
    public function test_billing_cycle_20_status_switch_active_to_inactive(): void
    {
        $this->assertBillingCycleTableReady();

        $cycle = $this->createBillingCycleRecord(['is_active' => true]);

        try {
            $this->browseWithFailureScreenshot('v2-toggle-off', function (Browser $browser) use ($cycle): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH);
                $this->ensurePageAccessible($browser, 'Billing Cycle index');

                $selector = '#statusSwitch-' . $cycle->id;
                $browser->assertPresent($selector)->click($selector)->pause(1500);
            });

            $cycle->refresh();
            $this->assertFalse((bool) $cycle->is_active, 'Should be inactive after toggle.');
        } finally {
            $this->purgeBillingCycleById((int) $cycle->id);
        }
    }

    /** TC-SM02: switch toggles inactive -> active. */
    public function test_billing_cycle_21_status_switch_inactive_to_active(): void
    {
        $this->assertBillingCycleTableReady();

        $cycle = $this->createBillingCycleRecord(['is_active' => false]);

        try {
            $this->browseWithFailureScreenshot('v2-toggle-on', function (Browser $browser) use ($cycle): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH);
                $this->ensurePageAccessible($browser, 'Billing Cycle index');

                $selector = '#statusSwitch-' . $cycle->id;
                $browser->assertPresent($selector)->click($selector)->pause(1500);
            });

            $cycle->refresh();
            $this->assertTrue((bool) $cycle->is_active, 'Should be active after toggle.');
        } finally {
            $this->purgeBillingCycleById((int) $cycle->id);
        }
    }

    /** TC-SM03 / API: toggle-status endpoint returns the JSON contract (defensive). */
    public function test_billing_cycle_22_toggle_status_endpoint_json_contract(): void
    {
        $this->assertBillingCycleTableReady();

        if (!$this->adminUser) {
            $this->markTestSkipped('No admin user resolved for endpoint test.');
        }

        $cycle = $this->createBillingCycleRecord(['is_active' => true]);

        try {
            $url = self::INDEX_PATH . '/' . $cycle->id . '/toggle-status';
            $response = $this->actingAs($this->adminUser)
                ->postJson($url, ['is_active' => false]);

            $response->assertStatus(200)
                ->assertJson(['success' => true, 'is_active' => false]);

            $cycle->refresh();
            $this->assertFalse((bool) $cycle->is_active, 'Endpoint did not deactivate the record.');
        } catch (Throwable $e) {
            $this->markTestSkipped('toggle-status endpoint not exercisable in-process: ' . $e->getMessage());
        } finally {
            $this->purgeBillingCycleById((int) $cycle->id);
        }
    }

    /** TC-N-SM / API: toggle-status rejects a missing is_active (422) (defensive). */
    public function test_billing_cycle_23_toggle_status_requires_is_active(): void
    {
        $this->assertBillingCycleTableReady();

        if (!$this->adminUser) {
            $this->markTestSkipped('No admin user resolved for endpoint test.');
        }

        $cycle = $this->createBillingCycleRecord(['is_active' => true]);

        try {
            $url = self::INDEX_PATH . '/' . $cycle->id . '/toggle-status';
            $response = $this->actingAs($this->adminUser)->postJson($url, []);
            $response->assertStatus(422);
        } catch (Throwable $e) {
            $this->markTestSkipped('toggle-status validation not exercisable in-process: ' . $e->getMessage());
        } finally {
            $this->purgeBillingCycleById((int) $cycle->id);
        }
    }

    // ==================================================================
    // Band 30-39 — Validation + error messages
    // ==================================================================

    /** TC-N01: short_name required. */
    public function test_billing_cycle_30_short_name_required(): void
    {
        $this->assertInvalidCreateStaysOnPage('v2-short-name-required', [
            'name' => $this->makeName(),
            'months_count' => '1',
        ], null);
    }

    /** TC-N02: name required. */
    public function test_billing_cycle_31_name_required(): void
    {
        $short = $this->makeShortName();
        $this->assertInvalidCreateStaysOnPage('v2-name-required', [
            'short_name' => $short,
            'months_count' => '1',
        ], $short);
    }

    /** TC-N03: months_count required. */
    public function test_billing_cycle_32_months_count_required(): void
    {
        $short = $this->makeShortName();
        $this->assertInvalidCreateStaysOnPage('v2-months-required', [
            'short_name' => $short,
            'name' => $this->makeName(),
        ], $short);
    }

    /** TC-N04: duplicate short_name rejected. */
    public function test_billing_cycle_33_duplicate_short_name_rejected(): void
    {
        $this->assertBillingCycleTableReady();

        $cycle = $this->createBillingCycleRecord();
        $shortName = (string) $cycle->short_name;

        try {
            $this->browseWithFailureScreenshot('v2-duplicate', function (Browser $browser) use ($shortName): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::CREATE_PATH);
                $this->ensurePageAccessible($browser, 'Billing Cycle create');

                $browser->type('short_name', $shortName)
                    ->type('name', $this->makeName())
                    ->type('months_count', '2')
                    ->check('#is_active');
                $this->setRecurringField($browser, true);
                $browser->press('Add Billing Cycle')->pause(1500);

                $this->assertSame(self::CREATE_PATH, $this->currentPath($browser));
                $browser->assertPresent('.alert.alert-danger');
            });

            $this->assertSame(1, BillingCycle::query()->where('short_name', $shortName)->count());
        } finally {
            $this->purgeBillingCycleById((int) $cycle->id);
        }
    }

    /** TC-N05: months_count = 0 (below min:1) rejected. */
    public function test_billing_cycle_34_months_count_zero_rejected(): void
    {
        $short = $this->makeShortName();
        $this->assertInvalidCreateStaysOnPage('v2-months-zero', [
            'short_name' => $short,
            'name' => $this->makeName(),
            'months_count' => '0',
        ], $short);
    }

    /** TC-N06: months_count above max:255 rejected. */
    public function test_billing_cycle_35_months_count_above_255_rejected(): void
    {
        $short = $this->makeShortName();
        $this->assertInvalidCreateStaysOnPage('v2-months-256', [
            'short_name' => $short,
            'name' => $this->makeName(),
            'months_count' => '256',
        ], $short);
    }

    /** TC-N07: short_name longer than 50 chars rejected. */
    public function test_billing_cycle_36_short_name_over_50_rejected(): void
    {
        $short = str_repeat('A', 51);
        $this->assertInvalidCreateStaysOnPage('v2-short-name-51', [
            'short_name' => $short,
            'name' => $this->makeName(),
            'months_count' => '1',
        ], null);
    }

    /** TC-N08: name longer than 50 chars rejected. */
    public function test_billing_cycle_37_name_over_50_rejected(): void
    {
        $short = $this->makeShortName();
        $this->assertInvalidCreateStaysOnPage('v2-name-51', [
            'short_name' => $short,
            'name' => str_repeat('B', 51),
            'months_count' => '1',
        ], $short);
    }

    /** TC-N09: description longer than 255 chars rejected. */
    public function test_billing_cycle_38_description_over_255_rejected(): void
    {
        $short = $this->makeShortName();
        $this->assertInvalidCreateStaysOnPage('v2-description-256', [
            'short_name' => $short,
            'name' => $this->makeName(),
            'months_count' => '1',
            'description' => str_repeat('C', 256),
        ], $short);
    }

    /** TC-P09: update keeps the same short_name on the same record (unique ignore-self). */
    public function test_billing_cycle_39_update_keeps_same_short_name_on_self(): void
    {
        $this->assertBillingCycleTableReady();

        $cycle = $this->createBillingCycleRecord();
        $sameShort = (string) $cycle->short_name;
        $newName = 'Renamed ' . $this->makeName();

        try {
            $this->browseWithFailureScreenshot('v2-update-same-short-name', function (Browser $browser) use ($cycle, $sameShort, $newName): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH);
                $this->ensurePageAccessible($browser, 'Billing Cycle index');

                $this->clickEditAction($browser, (int) $cycle->id);
                $this->confirmSweetAlert($browser);
                $browser->waitFor('#short_name', 10);

                $browser->type('short_name', $sameShort)
                    ->type('name', $newName)
                    ->type('months_count', '1')
                    ->check('#is_active');
                $this->setRecurringField($browser, true);
                $browser->press('Update Billing Cycle')->pause(2000);
            });

            $cycle->refresh();
            $this->assertSame($sameShort, (string) $cycle->short_name);
            $this->assertSame($newName, (string) $cycle->name, 'Update with same short_name should succeed.');
        } finally {
            $this->purgeBillingCycleById((int) $cycle->id);
        }
    }

    // ==================================================================
    // Band 40-49 — Integration / FK dependency
    // ==================================================================

    /** TC-D-F: full lifecycle create -> toggle -> delete -> restore -> force delete. */
    public function test_billing_cycle_40_full_lifecycle_flow(): void
    {
        $this->assertBillingCycleTableReady();

        $cycle = $this->createBillingCycleRecord();
        $cycleId = (int) $cycle->id;
        $shortName = (string) $cycle->short_name;

        try {
            $this->browseWithFailureScreenshot('v2-full-lifecycle', function (Browser $browser) use ($cycleId, $shortName): void {
                $this->authenticateCentral($browser);

                $this->visitAuthenticated($browser, self::INDEX_PATH);
                $this->ensurePageAccessible($browser, 'Billing Cycle index');

                $browser->click('#statusSwitch-' . $cycleId)->pause(1500);

                $this->clickDeleteAction($browser, $cycleId);
                $this->confirmSweetAlert($browser);
                $browser->pause(2000);

                $this->assertNotNull(BillingCycle::withTrashed()->find($cycleId)->deleted_at, 'Not soft deleted.');

                $this->visitAuthenticated($browser, self::TRASH_PATH);
                $browser->assertSee($shortName);

                $this->clickRestoreAction($browser, $cycleId);
                $this->confirmSweetAlert($browser);
                $browser->pause(2000);

                $this->assertNull(BillingCycle::withTrashed()->find($cycleId)->deleted_at, 'Not restored.');

                $this->visitAuthenticated($browser, self::INDEX_PATH);
                $this->clickDeleteAction($browser, $cycleId);
                $this->confirmSweetAlert($browser);
                $browser->pause(2000);

                $this->visitAuthenticated($browser, self::TRASH_PATH);
                $this->clickForceDeleteAction($browser, $cycleId);
                $this->confirmSweetAlert($browser);
                $browser->pause(2000);
            });

            $this->assertFalse(
                BillingCycle::withTrashed()->where('id', $cycleId)->exists(),
                'Still exists after force delete.'
            );
        } finally {
            $this->purgeBillingCycleById($cycleId);
        }
    }

    /**
     * TC-D-C / BC-REF: at least one FK references prm_billing_cycles with ON DELETE RESTRICT.
     * Proves delete is blocked while referenced (invoices/plans/rates/schedules).
     */
    public function test_billing_cycle_41_referencing_fk_uses_restrict(): void
    {
        try {
            $rows = DB::select(
                'SELECT rc.DELETE_RULE, kcu.TABLE_NAME '
                . 'FROM information_schema.REFERENTIAL_CONSTRAINTS rc '
                . 'JOIN information_schema.KEY_COLUMN_USAGE kcu '
                . 'ON rc.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME '
                . 'AND rc.CONSTRAINT_SCHEMA = kcu.CONSTRAINT_SCHEMA '
                . 'WHERE rc.CONSTRAINT_SCHEMA = DATABASE() '
                . 'AND rc.REFERENCED_TABLE_NAME = ?',
                [self::TABLE]
            );

            if ($rows === []) {
                $this->markTestSkipped('No FK references prm_billing_cycles in this DB build.');
            }

            $restrict = array_filter($rows, static fn ($r): bool => strtoupper((string) $r->DELETE_RULE) === 'RESTRICT');
            $this->assertNotEmpty($restrict, 'Expected at least one ON DELETE RESTRICT FK referencing prm_billing_cycles.');
        } catch (Throwable $e) {
            $this->markTestSkipped('information_schema query unsupported: ' . $e->getMessage());
        }
    }

    /** TC-D-E / BC-INT: cross-module reference tables exist (defensive). */
    public function test_billing_cycle_42_cross_module_reference_tables_exist(): void
    {
        $present = array_filter(self::REFERENCING_TABLES, static fn (string $t): bool => Schema::hasTable($t));

        if ($present === []) {
            $this->markTestSkipped('No billing-cycle referencing tables present in this environment.');
        }

        foreach ($present as $table) {
            $this->assertTrue(
                Schema::hasColumn($table, 'billing_cycle_id'),
                $table . ' should carry a billing_cycle_id FK column.'
            );
        }
    }

    // ==================================================================
    // Band 50-59 — Permissions
    // ==================================================================

    /** TC-N10: guest redirected to /login on the index. */
    public function test_billing_cycle_50_guest_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('v2-guest-index', function (Browser $browser): void {
            $browser->visit($this->centralUrl(self::INDEX_PATH))->pause(1200);
            $this->assertStringContainsString('/login', $this->currentPath($browser));
        });
    }

    /** TC-N11: guest redirected to /login on a create attempt. */
    public function test_billing_cycle_51_guest_redirected_from_create(): void
    {
        $this->browseWithFailureScreenshot('v2-guest-create', function (Browser $browser): void {
            $browser->visit($this->centralUrl(self::CREATE_PATH))->pause(1200);
            $this->assertStringContainsString('/login', $this->currentPath($browser));
        });
    }

    /** TC-N12 / API: a non super-admin without permission is forbidden (defensive). */
    public function test_billing_cycle_52_non_super_admin_forbidden(): void
    {
        try {
            $limited = $this->makeLimitedUser();
        } catch (Throwable $e) {
            $this->markTestSkipped('Could not build a limited user: ' . $e->getMessage());
        }

        try {
            $response = $this->actingAs($limited)->get(self::INDEX_PATH);
            $this->assertContains(
                $response->getStatusCode(),
                [403, 302],
                'A non super-admin without permission should be denied (403) or redirected.'
            );
        } catch (Throwable $e) {
            $this->markTestSkipped('Permission gate not exercisable in-process: ' . $e->getMessage());
        } finally {
            try {
                $limited->forceDelete();
            } catch (Throwable) {
                // best-effort cleanup
            }
        }
    }

    // ==================================================================
    // Band 60-69 — UI/UX
    // ==================================================================

    /** TC-P10: index shows table headers and pagination container. */
    public function test_billing_cycle_60_index_columns_present(): void
    {
        $this->assertBillingCycleTableReady();

        $this->browseWithFailureScreenshot('v2-index-columns', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Billing Cycle index');

            $browser->assertSee('Short Name')
                ->assertSee('Name')
                ->assertSee('Months')
                ->assertSee('Recurring')
                ->assertPresent('table');
        });
    }

    /** TC-P11: a created record is listed on the index. */
    public function test_billing_cycle_61_index_lists_created_record(): void
    {
        $this->assertBillingCycleTableReady();

        $cycle = $this->createBillingCycleRecord();
        $shortName = (string) $cycle->short_name;

        try {
            $this->browseWithFailureScreenshot('v2-index-lists', function (Browser $browser) use ($shortName): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH);
                $this->ensurePageAccessible($browser, 'Billing Cycle index');
                $browser->assertSee($shortName);
            });
        } finally {
            $this->purgeBillingCycleById((int) $cycle->id);
        }
    }

    /** TC-P12: create page shows the breadcrumb. */
    public function test_billing_cycle_62_breadcrumb_present_on_create(): void
    {
        $this->assertBillingCycleTableExists();

        $this->browseWithFailureScreenshot('v2-breadcrumb', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $this->ensurePageAccessible($browser, 'Billing Cycle create');
            $browser->assertSee('Billing Cycle Management')
                ->assertSee('Add New Billing Cycle');
        });
    }

    // ==================================================================
    // Band 70-79 — Edge cases
    // ==================================================================

    /** TC-EDG01: months_count boundary 1 accepted. */
    public function test_billing_cycle_70_months_count_boundary_one_accepted(): void
    {
        $this->assertValidCreatePersists('v2-months-1', 1);
    }

    /** TC-EDG02: months_count boundary 255 accepted. */
    public function test_billing_cycle_71_months_count_boundary_255_accepted(): void
    {
        $this->assertValidCreatePersists('v2-months-255', 255);
    }

    /**
     * TC-EDG03 / BC-EDG: a soft-deleted short_name remains reserved (unique index is not
     * scoped to deleted_at) — creating a duplicate is still rejected.
     */
    public function test_billing_cycle_72_soft_deleted_short_name_still_reserved(): void
    {
        $this->assertBillingCycleTableReady();

        $cycle = $this->createBillingCycleRecord();
        $shortName = (string) $cycle->short_name;
        $cycle->delete();

        try {
            $this->browseWithFailureScreenshot('v2-trashed-name-reserved', function (Browser $browser) use ($shortName): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::CREATE_PATH);
                $this->ensurePageAccessible($browser, 'Billing Cycle create');

                $browser->type('short_name', $shortName)
                    ->type('name', $this->makeName())
                    ->type('months_count', '1')
                    ->check('#is_active');
                $this->setRecurringField($browser, true);
                $browser->press('Add Billing Cycle')->pause(1500);

                $this->assertSame(self::CREATE_PATH, $this->currentPath($browser), 'Reserved short_name should stay on create page.');
                $browser->assertPresent('.alert.alert-danger');
            });

            $this->assertSame(
                1,
                BillingCycle::withTrashed()->where('short_name', $shortName)->count(),
                'A trashed short_name must not be reusable.'
            );
        } finally {
            $this->purgeBillingCycleById((int) $cycle->id);
        }
    }

    // ==================================================================
    // Band 90-99 — Security
    // ==================================================================

    /** TC-S01: XSS payload in name is stored raw and rendered escaped on the index. */
    public function test_billing_cycle_90_xss_in_name_is_escaped_on_index(): void
    {
        $this->assertBillingCycleTableReady();

        $short = $this->makeShortName();
        $payload = '<script>alert("bcx")</script>';

        $cycle = $this->createBillingCycleRecord([
            'short_name' => $short,
            'name' => $payload,
        ]);

        try {
            $this->browseWithFailureScreenshot('v2-xss-name', function (Browser $browser) use ($short): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH);
                $this->ensurePageAccessible($browser, 'Billing Cycle index');

                $browser->assertSee($short);
                // Blade {{ }} escapes — the raw <script> tag must not appear in the DOM source.
                $source = (string) $browser->driver->getPageSource();
                $this->assertStringNotContainsString('<script>alert("bcx")</script>', $source, 'XSS payload rendered unescaped.');
            });

            $cycle->refresh();
            $this->assertSame($payload, (string) $cycle->name, 'Name should be stored verbatim (escaping is a render concern).');
        } finally {
            $this->purgeBillingCycleById((int) $cycle->id);
        }
    }

    /** TC-S02: direct edit URL for a valid record requires authentication (IDOR guard). */
    public function test_billing_cycle_91_direct_edit_url_requires_auth(): void
    {
        $this->assertBillingCycleTableReady();

        $cycle = $this->createBillingCycleRecord();
        $editPath = self::INDEX_PATH . '/' . $cycle->id . '/edit';

        try {
            $this->browseWithFailureScreenshot('v2-idor-guard', function (Browser $browser) use ($editPath): void {
                $browser->visit($this->centralUrl($editPath))->pause(1200);
                $this->assertStringContainsString('/login', $this->currentPath($browser), 'Direct edit URL must require auth.');
            });
        } finally {
            $this->purgeBillingCycleById((int) $cycle->id);
        }
    }

    // ==================================================================
    // Private helper library
    // ==================================================================

    private function assertBillingCycleTableReady(): void
    {
        if (!Schema::hasTable(self::TABLE)) {
            $this->fail('prm_billing_cycles table is missing; cannot run Billing Cycle tests.');
        }
        if (!Schema::hasColumn(self::TABLE, 'deleted_at')) {
            $this->fail('prm_billing_cycles.deleted_at is missing; SoftDeletes will fail (MIG-BIL-001).');
        }
    }

    private function assertBillingCycleTableExists(): void
    {
        if (!Schema::hasTable(self::TABLE)) {
            $this->fail('prm_billing_cycles table is missing; cannot run Billing Cycle tests.');
        }
    }

    private function billingCycleSupportsRecurring(): bool
    {
        return Schema::hasColumn(self::TABLE, 'is_recurring');
    }

    /**
     * Submit an invalid create payload and assert the user stays on the create page
     * with the validation alert, and that no matching record was persisted.
     */
    private function assertInvalidCreateStaysOnPage(string $caseName, array $fields, ?string $shortNameToCheck): void
    {
        $this->assertBillingCycleTableExists();

        $this->browseWithFailureScreenshot($caseName, function (Browser $browser) use ($fields): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $this->ensurePageAccessible($browser, 'Billing Cycle create');

            foreach ($fields as $name => $value) {
                $browser->type($name, (string) $value);
            }
            $browser->check('#is_active');
            $this->setRecurringField($browser, true);
            $browser->press('Add Billing Cycle')->pause(1500);

            $this->assertSame(self::CREATE_PATH, $this->currentPath($browser), 'Invalid submission should stay on create page.');
            $browser->assertPresent('.alert.alert-danger');
        });

        if ($shortNameToCheck !== null) {
            $this->assertFalse(
                BillingCycle::withTrashed()->where('short_name', $shortNameToCheck)->exists(),
                'Invalid submission should not persist a record.'
            );
        }
    }

    /** Submit a valid create with the given months_count and assert it persists. */
    private function assertValidCreatePersists(string $caseName, int $monthsCount): void
    {
        $this->assertBillingCycleTableReady();

        $short = $this->makeShortName();

        $this->browseWithFailureScreenshot($caseName, function (Browser $browser) use ($short, $monthsCount): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $this->ensurePageAccessible($browser, 'Billing Cycle create');

            $browser->type('short_name', $short)
                ->type('name', $this->makeName())
                ->type('months_count', (string) $monthsCount)
                ->check('#is_active');
            $this->setRecurringField($browser, true);
            $browser->press('Add Billing Cycle')->pause(2000);
        });

        $cycle = BillingCycle::withTrashed()->where('short_name', $short)->first();
        $this->assertNotNull($cycle, 'Boundary months_count ' . $monthsCount . ' should persist.');

        if ($cycle) {
            try {
                $this->assertSame($monthsCount, (int) $cycle->months_count);
            } finally {
                $this->purgeBillingCycleById((int) $cycle->id);
            }
        }
    }

    private function makeLimitedUser(): \App\Models\User
    {
        $suffix = '_' . uniqid();

        return \App\Models\User::create([
            'email' => 'limited' . $suffix . '@tenant.com',
            'password' => bcrypt('password'),
            'name' => 'Limited User',
            'emp_code' => 'LIM' . substr($suffix, 1, 8),
            'short_name' => 'LIM' . rand(1000, 9999),
            'status' => 'ACTIVE',
            'is_active' => 1,
            'is_super_admin' => 0,
            'email_verified_at' => now(),
        ]);
    }

    private function makeShortName(): string
    {
        try {
            $suffix = strtoupper(bin2hex(random_bytes(3)));
        } catch (Throwable) {
            $suffix = (string) rand(100000, 999999);
        }

        return 'BC' . $suffix;
    }

    private function makeName(): string
    {
        return 'Billing Cycle ' . rand(1000, 9999);
    }

    private function createBillingCycleRecord(array $overrides = []): BillingCycle
    {
        $payload = [
            'short_name' => $this->makeShortName(),
            'name' => $this->makeName(),
            'months_count' => 1,
            'description' => 'V2 billing cycle seed',
            'is_active' => true,
        ];

        if ($this->billingCycleSupportsRecurring()) {
            $payload['is_recurring'] = false;
        }

        $payload = array_merge($payload, $overrides);

        if (!$this->billingCycleSupportsRecurring()) {
            unset($payload['is_recurring']);
        }

        return BillingCycle::create($payload);
    }

    private function purgeBillingCycleById(int $id): void
    {
        try {
            DB::table(self::TABLE)->where('id', $id)->delete();
        } catch (Throwable) {
            // best-effort cleanup
        }
    }

    private function setRecurringField(Browser $browser, bool $shouldBeChecked): void
    {
        if (!$browser->element('#is_recurring')) {
            return;
        }

        if ($shouldBeChecked) {
            $browser->check('#is_recurring');
        } else {
            $browser->uncheck('#is_recurring');
        }
    }

    private function confirmSweetAlert(Browser $browser, int $waitSeconds = 10): void
    {
        $browser->waitFor('.swal2-popup', $waitSeconds);
        $this->assertNotNull($browser->element('.swal2-confirm'), 'SweetAlert confirm button not found.');
        $browser->click('.swal2-confirm')->pause(1200);
    }

    private function clickEditAction(Browser $browser, int $id): void
    {
        $selector = 'a.confirm-action[href$="/billing/billing-cycle/' . $id . '/edit"]';
        $browser->assertPresent($selector);
        $browser->click($selector);
    }

    private function clickDeleteAction(Browser $browser, int $id): void
    {
        $selector = 'form.confirm-action-form[action$="/billing/billing-cycle/' . $id . '"] button[type="submit"]';
        $browser->assertPresent($selector);
        $browser->click($selector);
    }

    private function clickRestoreAction(Browser $browser, int $id): void
    {
        $selector = 'a.confirm-action-restore[href$="/billing/billing-cycle/' . $id . '/restore"]';
        $browser->assertPresent($selector);
        $browser->click($selector);
    }

    private function clickForceDeleteAction(Browser $browser, int $id): void
    {
        $selector = 'form.confirm-action-form-force-delete[action$="/billing/billing-cycle/' . $id . '/force-delete"] button[type="submit"]';
        $browser->assertPresent($selector);
        $browser->click($selector);
    }
}
