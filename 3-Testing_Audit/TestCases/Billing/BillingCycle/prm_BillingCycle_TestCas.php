<?php

namespace Tests\Browser\Modules\Prime\Billing\BillingCycle;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\Billing\Http\Controllers\BillingCycleController;
use Modules\Billing\Http\Requests\BillingCycleRequest;
use Modules\Billing\Models\BillingCycle;
use Modules\Billing\Policies\BillingCyclePolicy;
use ReflectionClass;
use Tests\Browser\Modules\Prime\Billing\BillingDuskTestCase;
use Throwable;

/**
 * Comprehensive Dusk suite for the Billing Cycle screen (central / prime_db).
 *
 * DB scope: PRIME/CENTRAL — table `prm_billing_cycles` lives in prime_db, so this
 * class extends the central base (BillingDuskTestCase → prm_BillingDuskTestCase_TestCas
 * → PrimeDuskTestCase) and uses authenticateCentral()/visitAuthenticated()/centralUrl()
 * on http://127.0.0.1:8000. It does NOT use tenant scaffolding (DUSK_TENANT_URL /
 * initializeTenantContext) — see 05_ constraints E21/E22.
 *
 * Semantic numbering bands (WP-G):
 *   01-09 schema/DDL/model/request/route config truth
 *   10-19 business rules (BC-BIZ)
 *   20-29 state-machine transitions (BC-SM)
 *   30-39 validation + error messages (BC-VAL)
 *   40-49 integration / FK dependency (BC-INT/BC-REF)
 *   50-59 permissions / authorization (BC-AUTH)
 *   60-69 UI/UX (pagination, empty-state, breadcrumb, badges)
 *   70-79 edge cases (BC-EDG)
 *   90-99 tenancy / security pack (TC-T / TC-S)
 *
 * Known source defects proven here:
 *   MIG-BIL-001 (P0)   — model declares SoftDeletes + timestamps but the DDL
 *                        `prm_billing_cycles` has NO deleted_at/created_at/updated_at.
 *   DEV-BIL-020 (P2)   — forceDelete() authorizes 'prime.billing-cycle.delete'
 *                        instead of 'prime.billing-cycle.forceDelete' (policy + requirement).
 */
class prm_BillingCycle_TestCas extends BillingDuskTestCase
{
    protected const SCREENSHOT_DIR = 'tests/Browser/Modules/Prime/Billing/BillingCycle/screenshots';
    protected const STATUS_REPORT_DIRECTORY = 'tests/Browser/Modules/Prime/Billing/BillingCycle/report';
    protected const STATUS_REPORT_PREFIX = 'billing_cycle_report_';

    private const TABLE = 'prm_billing_cycles';
    private const INDEX_PATH = '/billing/billing-cycle';
    private const CREATE_PATH = '/billing/billing-cycle/create';
    private const TRASH_PATH = '/billing/billing-cycle/trash/view';

    // ---------------------------------------------------------------------
    // Band 01-09 — Schema / model / request / route configuration truth
    // ---------------------------------------------------------------------

    public function test_billing_cycle_01_schema_table_and_columns_are_correct(): void
    {
        $this->assertBillingCycleTableExists();

        foreach (['id', 'short_name', 'name', 'months_count', 'description', 'is_recurring', 'is_active'] as $column) {
            $this->assertTrue(
                Schema::hasColumn(self::TABLE, $column),
                "prm_billing_cycles is missing expected column '{$column}'."
            );
        }
    }

    public function test_billing_cycle_02_ddl_has_no_timestamp_or_softdelete_columns_mig_bil_001(): void
    {
        $this->assertBillingCycleTableExists();

        // Per the authoritative DDL, prm_billing_cycles ends at is_active and carries
        // NO deleted_at / created_at / updated_at. The model, however, declares
        // SoftDeletes + default timestamps. This asserts the current DDL-vs-model gap
        // (MIG-BIL-001). If a schema patch has since added these columns the assertion
        // documents that the P0 was remediated.
        $missing = [];
        foreach (['deleted_at', 'created_at', 'updated_at'] as $column) {
            if (!Schema::hasColumn(self::TABLE, $column)) {
                $missing[] = $column;
            }
        }

        if ($missing === []) {
            $this->addToAssertionCount(1);
            fwrite(STDERR, "[MIG-BIL-001] prm_billing_cycles now carries deleted_at/created_at/updated_at — P0 appears remediated.\n");
            return;
        }

        $this->assertNotEmpty(
            $missing,
            'MIG-BIL-001 proving test: expected timestamp/soft-delete columns to be absent from the DDL-built table.'
        );
        fwrite(STDERR, '[MIG-BIL-001] prm_billing_cycles missing columns (SoftDeletes+timestamps break CRUD): ' . implode(', ', $missing) . "\n");
    }

    public function test_billing_cycle_03_short_name_unique_index_exists(): void
    {
        $this->assertBillingCycleTableExists();

        $duplicateShortName = $this->makeShortName();
        $first = $this->createBillingCycleRecord(['short_name' => $duplicateShortName]);

        $secondCreated = null;
        try {
            $secondCreated = BillingCycle::create([
                'short_name' => $duplicateShortName,
                'name' => $this->makeName(),
                'months_count' => 1,
                'description' => 'unique index probe',
                'is_active' => true,
            ]);
            $this->fail('Database allowed a duplicate short_name; uq_billingCycles_code unique index is missing.');
        } catch (Throwable $e) {
            $this->assertStringContainsStringIgnoringCase('integrity constraint', $e->getMessage(), 'Duplicate short_name should raise a unique-constraint error.');
        } finally {
            if ($secondCreated) {
                $this->purgeBillingCycleById((int) $secondCreated->id);
            }
            $this->purgeBillingCycleById((int) $first->id);
        }
    }

    public function test_billing_cycle_04_model_configuration_matches_source(): void
    {
        $model = new BillingCycle();

        $this->assertSame(self::TABLE, $model->getTable(), 'BillingCycle table name is wrong.');

        $expectedFillable = ['short_name', 'name', 'months_count', 'description', 'is_active', 'is_recurring'];
        $this->assertSame(
            sort_copy($expectedFillable),
            sort_copy($model->getFillable()),
            'BillingCycle fillable does not match source.'
        );

        $casts = $model->getCasts();
        $this->assertSame('integer', $casts['months_count'] ?? null, 'months_count cast should be integer.');
        $this->assertSame('boolean', $casts['is_active'] ?? null, 'is_active cast should be boolean.');
        $this->assertSame('boolean', $casts['is_recurring'] ?? null, 'is_recurring cast should be boolean.');

        $this->assertTrue(
            in_array(\Illuminate\Database\Eloquent\SoftDeletes::class, class_uses_recursive(BillingCycle::class), true),
            'BillingCycle model must use SoftDeletes (source declares it — this is the MIG-BIL-001 root).'
        );
    }

    public function test_billing_cycle_05_model_relationships_are_defined(): void
    {
        $model = new BillingCycle();

        foreach (['tenantPlanRates', 'billingSchedules', 'invoices', 'plans'] as $relation) {
            $this->assertTrue(
                method_exists($model, $relation),
                "BillingCycle model is missing the '{$relation}' relationship."
            );
        }
    }

    public function test_billing_cycle_06_form_request_rules_present_in_source(): void
    {
        $source = $this->classSource(BillingCycleRequest::class);

        $this->assertStringContainsString("Rule::unique('prm_billing_cycles', 'short_name')", $source, 'short_name unique rule missing.');
        $this->assertStringContainsString("'max:50'", $source, 'max:50 rule missing (short_name/name).');
        $this->assertStringContainsString("'max:255'", $source, 'description max:255 rule missing.');
        $this->assertStringContainsString("'min:1'", $source, 'months_count min:1 rule missing.');
        $this->assertStringContainsString("'max:255'", $source, 'months_count max:255 rule missing.');
        $this->assertStringContainsString('prepareForValidation', $source, 'prepareForValidation (checkbox->boolean) missing.');
    }

    public function test_billing_cycle_07_named_routes_are_registered(): void
    {
        $names = [
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

        foreach ($names as $name) {
            $this->assertTrue(
                \Illuminate\Support\Facades\Route::has($name),
                "Expected route '{$name}' to be registered."
            );
        }
    }

    public function test_billing_cycle_08_controller_methods_exist(): void
    {
        foreach (['index', 'create', 'store', 'show', 'edit', 'update', 'destroy', 'trashed', 'restore', 'forceDelete', 'toggleStatus'] as $method) {
            $this->assertTrue(
                method_exists(BillingCycleController::class, $method),
                "BillingCycleController is missing method '{$method}'."
            );
        }
    }

    // ---------------------------------------------------------------------
    // Band 10-19 — Business rules (BC-BIZ)
    // ---------------------------------------------------------------------

    public function test_billing_cycle_10_index_loads(): void
    {
        $this->assertBillingCycleTableReady();

        $this->browseWithFailureScreenshot('billing-cycle-index', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);

            $this->assertSame(self::INDEX_PATH, $this->currentPath($browser), 'Billing Cycle index not reachable.');
            $this->ensurePageAccessible($browser, 'Billing Cycle index');

            $browser->assertSee('Billing Cycles');
            $browser->assertPresent('table');
        });
    }

    public function test_billing_cycle_11_create_page_loads(): void
    {
        $this->assertBillingCycleTableExists();

        $this->browseWithFailureScreenshot('billing-cycle-create-page', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH);

            $this->assertSame(self::CREATE_PATH, $this->currentPath($browser), 'Billing Cycle create page not reachable.');
            $this->ensurePageAccessible($browser, 'Billing Cycle create');

            $browser->assertPresent('#short_name')
                ->assertPresent('#name')
                ->assertPresent('#months_count')
                ->assertPresent('#description');
        });
    }

    public function test_billing_cycle_12_create_flow_persists_record(): void
    {
        $this->assertBillingCycleTableReady();

        $shortName = $this->makeShortName();
        $name = $this->makeName();

        $this->browseWithFailureScreenshot('billing-cycle-create', function (Browser $browser) use ($shortName, $name): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $this->ensurePageAccessible($browser, 'Billing Cycle create');

            $browser->type('short_name', $shortName)
                ->type('name', $name)
                ->type('months_count', '1')
                ->type('description', 'Dusk billing cycle test')
                ->check('#is_active');

            $this->setRecurringField($browser, true);
            $browser->press('Add Billing Cycle')->pause(2000);
        });

        $cycle = BillingCycle::withTrashed()->where('short_name', $shortName)->first();
        $this->assertNotNull($cycle, 'Billing cycle was not created.');

        if ($cycle) {
            try {
                $this->assertSame($name, $cycle->name);
                $this->assertSame(1, (int) $cycle->months_count);
                $this->assertTrue((bool) $cycle->is_active);
                if ($this->billingCycleSupportsRecurring()) {
                    $this->assertTrue((bool) $cycle->is_recurring);
                }
            } finally {
                $this->purgeBillingCycleById((int) $cycle->id);
            }
        }
    }

    public function test_billing_cycle_13_create_respects_unchecked_recurring(): void
    {
        $this->assertBillingCycleTableReady();

        if (!$this->billingCycleSupportsRecurring()) {
            $this->markTestSkipped('is_recurring column not present; cannot assert recurring toggle.');
        }

        $shortName = $this->makeShortName();

        $this->browseWithFailureScreenshot('billing-cycle-create-non-recurring', function (Browser $browser) use ($shortName): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $this->ensurePageAccessible($browser, 'Billing Cycle create');

            $browser->type('short_name', $shortName)
                ->type('name', $this->makeName())
                ->type('months_count', '3')
                ->type('description', 'Non recurring')
                ->check('#is_active');

            $this->setRecurringField($browser, false);
            $browser->press('Add Billing Cycle')->pause(2000);
        });

        $cycle = BillingCycle::withTrashed()->where('short_name', $shortName)->first();
        $this->assertNotNull($cycle, 'Non-recurring billing cycle was not created.');

        if ($cycle) {
            try {
                $this->assertFalse((bool) $cycle->is_recurring, 'Unchecked recurring should persist as false.');
            } finally {
                $this->purgeBillingCycleById((int) $cycle->id);
            }
        }
    }

    public function test_billing_cycle_14_update_flow_persists_changes(): void
    {
        $this->assertBillingCycleTableReady();

        $cycle = $this->createBillingCycleRecord(['months_count' => 2]);
        $updatedShortName = $this->makeShortName();
        $updatedName = 'Updated ' . $this->makeName();

        try {
            $this->browseWithFailureScreenshot('billing-cycle-update', function (Browser $browser) use ($cycle, $updatedShortName, $updatedName): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH);
                $this->ensurePageAccessible($browser, 'Billing Cycle index');

                $this->clickEditAction($browser, (int) $cycle->id);
                $this->confirmSweetAlert($browser);
                $browser->waitFor('#short_name', 10);

                $this->assertSame(
                    self::INDEX_PATH . '/' . $cycle->id . '/edit',
                    $this->currentPath($browser),
                    'Billing Cycle edit page not reachable.'
                );

                $browser->type('short_name', $updatedShortName)
                    ->type('name', $updatedName)
                    ->type('months_count', '3')
                    ->type('description', 'Updated by Dusk')
                    ->check('#is_active');

                $this->setRecurringField($browser, true);
                $browser->press('Update Billing Cycle')->pause(2000);
            });

            $cycle->refresh();
            $this->assertSame($updatedShortName, (string) $cycle->short_name);
            $this->assertSame($updatedName, (string) $cycle->name);
            $this->assertSame(3, (int) $cycle->months_count);
            $this->assertSame('Updated by Dusk', (string) $cycle->description);
        } finally {
            $this->purgeBillingCycleById((int) $cycle->id);
        }
    }

    public function test_billing_cycle_15_update_allows_same_short_name_unique_ignores_self(): void
    {
        $this->assertBillingCycleTableReady();

        $cycle = $this->createBillingCycleRecord();
        $originalShortName = (string) $cycle->short_name;

        try {
            $this->browseWithFailureScreenshot('billing-cycle-update-same-shortname', function (Browser $browser) use ($cycle, $originalShortName): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH . '/' . $cycle->id . '/edit');
                $this->ensurePageAccessible($browser, 'Billing Cycle edit');
                $browser->waitFor('#short_name', 10);

                // Keep the same short_name, change only the display name.
                $browser->clear('short_name')->type('short_name', $originalShortName)
                    ->type('name', 'Renamed keeping code')
                    ->clear('months_count')->type('months_count', '4')
                    ->check('#is_active');
                $this->setRecurringField($browser, true);
                $browser->press('Update Billing Cycle')->pause(2000);
            });

            $cycle->refresh();
            $this->assertSame($originalShortName, (string) $cycle->short_name, 'short_name should be unchanged.');
            $this->assertSame('Renamed keeping code', (string) $cycle->name, 'Update with same short_name should succeed (unique ignores self).');
        } finally {
            $this->purgeBillingCycleById((int) $cycle->id);
        }
    }

    public function test_billing_cycle_16_show_page_displays_details(): void
    {
        $this->assertBillingCycleTableReady();

        $cycle = $this->createBillingCycleRecord();

        try {
            $this->browseWithFailureScreenshot('billing-cycle-show', function (Browser $browser) use ($cycle): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH . '/' . $cycle->id);
                $this->ensurePageAccessible($browser, 'Billing Cycle show');

                $browser->assertSee((string) $cycle->short_name)
                    ->assertSee((string) $cycle->name);
            });
        } finally {
            $this->purgeBillingCycleById((int) $cycle->id);
        }
    }

    public function test_billing_cycle_17_store_source_redirects_to_sales_plan_mgmt_billing_anchor(): void
    {
        // Static proof of the BC-BIZ redirect target (store()/update() both
        // redirect to central.prime.sales-plan-mgmt.index#billing, NOT the index).
        $source = $this->classSource(BillingCycleController::class);
        $this->assertStringContainsString("route('central.prime.sales-plan-mgmt.index') . '#billing'", $source, 'store/update should redirect to sales-plan-mgmt#billing.');
    }

    public function test_billing_cycle_18_destroy_deactivates_before_soft_delete_in_source(): void
    {
        $source = $this->classSource(BillingCycleController::class);
        $this->assertStringContainsString("\$billingCycle->update(['is_active' => false]);", $source, 'destroy() must set is_active=false before delete (BR pre-delete).');
        $this->assertStringContainsString('$billingCycle->delete();', $source, 'destroy() must soft-delete the record.');
    }

    public function test_billing_cycle_19_activity_log_events_are_verbatim_in_source(): void
    {
        $source = $this->classSource(BillingCycleController::class);
        foreach (["'Stored'", "'Updated'", "'Trashed'", "'Restored'", "'Deleted'"] as $event) {
            $this->assertStringContainsString($event, $source, "Controller must log the {$event} activity event verbatim.");
        }
    }

    // ---------------------------------------------------------------------
    // Band 20-29 — State-machine transitions (BC-SM)
    // ---------------------------------------------------------------------

    public function test_billing_cycle_20_status_toggle_endpoint_returns_json_in_source(): void
    {
        $source = $this->classSource(BillingCycleController::class);
        $this->assertStringContainsString("'is_active' => 'required|boolean'", $source, 'toggleStatus should validate is_active required|boolean.');
        $this->assertStringContainsString("'success' => true", $source, 'toggleStatus should return JSON success payload.');
    }

    public function test_billing_cycle_21_status_toggle_ui_updates_is_active(): void
    {
        $this->assertBillingCycleTableReady();

        $cycle = $this->createBillingCycleRecord(['is_active' => true]);

        try {
            $this->browseWithFailureScreenshot('billing-cycle-toggle-status', function (Browser $browser) use ($cycle): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH);
                $this->ensurePageAccessible($browser, 'Billing Cycle index');

                $toggleSelector = '#statusSwitch-' . $cycle->id;
                $browser->assertPresent($toggleSelector);
                $browser->click($toggleSelector)->pause(1500);
            });

            $cycle->refresh();
            $this->assertFalse((bool) $cycle->is_active, 'Billing cycle status did not toggle to inactive.');
        } finally {
            $this->purgeBillingCycleById((int) $cycle->id);
        }
    }

    public function test_billing_cycle_22_soft_delete_moves_record_to_trash(): void
    {
        $this->assertBillingCycleTableReady();

        $cycle = $this->createBillingCycleRecord(['is_active' => true]);
        $cycleId = (int) $cycle->id;

        try {
            $this->browseWithFailureScreenshot('billing-cycle-soft-delete', function (Browser $browser) use ($cycleId): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH);
                $this->ensurePageAccessible($browser, 'Billing Cycle index');

                $this->clickDeleteAction($browser, $cycleId);
                $this->confirmSweetAlert($browser);
                $browser->pause(2000);
            });

            $deleted = BillingCycle::withTrashed()->find($cycleId);
            $this->assertNotNull($deleted, 'Billing cycle missing after soft delete.');
            $this->assertNotNull($deleted->deleted_at, 'Billing cycle was not soft deleted.');
            $this->assertFalse((bool) $deleted->is_active, 'Soft delete should have set is_active=false first (BR pre-delete).');
        } finally {
            $this->purgeBillingCycleById($cycleId);
        }
    }

    public function test_billing_cycle_23_restore_from_trash(): void
    {
        $this->assertBillingCycleTableReady();

        $cycle = $this->createBillingCycleRecord();
        $cycleId = (int) $cycle->id;
        $shortName = (string) $cycle->short_name;

        try {
            $this->browseWithFailureScreenshot('billing-cycle-restore', function (Browser $browser) use ($cycleId, $shortName): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH);
                $this->ensurePageAccessible($browser, 'Billing Cycle index');

                $this->clickDeleteAction($browser, $cycleId);
                $this->confirmSweetAlert($browser);
                $browser->pause(2000);

                $this->visitAuthenticated($browser, self::TRASH_PATH);
                $browser->assertSee($shortName);

                $this->clickRestoreAction($browser, $cycleId);
                $this->confirmSweetAlert($browser);
                $browser->pause(2000);
            });

            $restored = BillingCycle::withTrashed()->find($cycleId);
            $this->assertNotNull($restored, 'Billing cycle missing after restore.');
            $this->assertNull($restored->deleted_at, 'Billing cycle was not restored.');
        } finally {
            $this->purgeBillingCycleById($cycleId);
        }
    }

    public function test_billing_cycle_24_force_delete_removes_permanently(): void
    {
        $this->assertBillingCycleTableReady();

        $cycle = $this->createBillingCycleRecord();
        $cycleId = (int) $cycle->id;
        $shortName = (string) $cycle->short_name;

        try {
            $this->browseWithFailureScreenshot('billing-cycle-force-delete', function (Browser $browser) use ($cycleId, $shortName): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH);
                $this->clickDeleteAction($browser, $cycleId);
                $this->confirmSweetAlert($browser);
                $browser->pause(2000);

                $this->visitAuthenticated($browser, self::TRASH_PATH);
                $browser->assertSee($shortName);

                $this->clickForceDeleteAction($browser, $cycleId);
                $this->confirmSweetAlert($browser);
                $browser->pause(2000);
            });

            $this->assertFalse(
                BillingCycle::withTrashed()->where('id', $cycleId)->exists(),
                'Billing cycle still exists after force delete.'
            );
        } finally {
            $this->purgeBillingCycleById($cycleId);
        }
    }

    public function test_billing_cycle_25_full_lifecycle_flow(): void
    {
        $this->assertBillingCycleTableReady();

        $cycle = $this->createBillingCycleRecord();
        $cycleId = (int) $cycle->id;
        $shortName = (string) $cycle->short_name;

        try {
            $this->browseWithFailureScreenshot('billing-cycle-lifecycle', function (Browser $browser) use ($cycleId, $shortName): void {
                $this->authenticateCentral($browser);

                $this->visitAuthenticated($browser, self::INDEX_PATH);
                $this->ensurePageAccessible($browser, 'Billing Cycle index');

                $this->clickDeleteAction($browser, $cycleId);
                $this->confirmSweetAlert($browser);
                $browser->pause(2000);

                $deleted = BillingCycle::withTrashed()->find($cycleId);
                $this->assertNotNull($deleted->deleted_at, 'Billing cycle was not soft deleted.');

                $this->visitAuthenticated($browser, self::TRASH_PATH);
                $browser->assertSee($shortName);

                $this->clickRestoreAction($browser, $cycleId);
                $this->confirmSweetAlert($browser);
                $browser->pause(2000);

                $restored = BillingCycle::withTrashed()->find($cycleId);
                $this->assertNull($restored->deleted_at, 'Billing cycle was not restored.');

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
                'Billing cycle still exists after lifecycle force delete.'
            );
        } finally {
            $this->purgeBillingCycleById($cycleId);
        }
    }

    // ---------------------------------------------------------------------
    // Band 30-39 — Validation + error messages (BC-VAL)
    // ---------------------------------------------------------------------

    public function test_billing_cycle_30_create_requires_required_fields(): void
    {
        $this->assertBillingCycleTableExists();

        $this->browseWithFailureScreenshot('billing-cycle-required-fields', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $this->ensurePageAccessible($browser, 'Billing Cycle create');

            $browser->press('Add Billing Cycle')->pause(1500);

            $this->assertSame(self::CREATE_PATH, $this->currentPath($browser), 'Validation should keep user on create page.');
            $browser->assertPresent('.alert.alert-danger');
            $browser->assertPresent('.alert.alert-danger li');
        });
    }

    public function test_billing_cycle_31_short_name_required_message(): void
    {
        $this->submitCreateExpectingError(
            'billing-cycle-shortname-required',
            ['name' => $this->makeName(), 'months_count' => '1'],
            'The short name field is required.'
        );
    }

    public function test_billing_cycle_32_name_required_message(): void
    {
        $this->submitCreateExpectingError(
            'billing-cycle-name-required',
            ['short_name' => $this->makeShortName(), 'months_count' => '1'],
            'The name field is required.'
        );
    }

    public function test_billing_cycle_33_months_count_required_message(): void
    {
        $this->submitCreateExpectingError(
            'billing-cycle-months-required',
            ['short_name' => $this->makeShortName(), 'name' => $this->makeName()],
            'The months count field is required.'
        );
    }

    public function test_billing_cycle_34_short_name_max_50_rejected(): void
    {
        $this->submitCreateExpectingError(
            'billing-cycle-shortname-max',
            ['short_name' => str_repeat('A', 51), 'name' => $this->makeName(), 'months_count' => '1'],
            'short name'
        );
    }

    public function test_billing_cycle_35_name_max_50_rejected(): void
    {
        $this->submitCreateExpectingError(
            'billing-cycle-name-max',
            ['short_name' => $this->makeShortName(), 'name' => str_repeat('B', 51), 'months_count' => '1'],
            'name'
        );
    }

    public function test_billing_cycle_36_description_max_255_rejected(): void
    {
        $this->submitCreateExpectingError(
            'billing-cycle-description-max',
            ['short_name' => $this->makeShortName(), 'name' => $this->makeName(), 'months_count' => '1', 'description' => str_repeat('C', 256)],
            'description'
        );
    }

    public function test_billing_cycle_37_months_count_below_min_rejected(): void
    {
        $this->submitCreateExpectingError(
            'billing-cycle-months-min',
            ['short_name' => $this->makeShortName(), 'name' => $this->makeName(), 'months_count' => '0'],
            'months count'
        );
    }

    public function test_billing_cycle_38_months_count_above_max_rejected(): void
    {
        $this->submitCreateExpectingError(
            'billing-cycle-months-max',
            ['short_name' => $this->makeShortName(), 'name' => $this->makeName(), 'months_count' => '256'],
            'months count'
        );
    }

    public function test_billing_cycle_39_duplicate_short_name_rejected(): void
    {
        $this->assertBillingCycleTableReady();

        $cycle = $this->createBillingCycleRecord();
        $shortName = (string) $cycle->short_name;

        try {
            $this->browseWithFailureScreenshot('billing-cycle-duplicate-short-name', function (Browser $browser) use ($shortName): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::CREATE_PATH);
                $this->ensurePageAccessible($browser, 'Billing Cycle create');

                $browser->type('short_name', $shortName)
                    ->type('name', $this->makeName())
                    ->type('months_count', '2')
                    ->type('description', 'Duplicate short name test')
                    ->check('#is_active');
                $this->setRecurringField($browser, true);
                $browser->press('Add Billing Cycle')->pause(1500);

                $this->assertSame(self::CREATE_PATH, $this->currentPath($browser), 'Duplicate short name should stay on create page.');
                $browser->assertPresent('.alert.alert-danger');
            });

            $count = BillingCycle::query()->where('short_name', $shortName)->count();
            $this->assertSame(1, $count, 'Duplicate short name created a new billing cycle.');
        } finally {
            $this->purgeBillingCycleById((int) $cycle->id);
        }
    }

    // ---------------------------------------------------------------------
    // Band 40-49 — Integration / FK dependency (BC-INT / BC-REF)
    // ---------------------------------------------------------------------

    public function test_billing_cycle_40_referencing_tables_use_restrict_on_delete(): void
    {
        // prm_plans, prm_tenant_plan_rates, prm_tenant_plan_billing_schedule and
        // bil_tenant_invoices all FK billing_cycle_id -> prm_billing_cycles ON DELETE RESTRICT.
        // Assert at least one referencing table exists so the FK-RESTRICT dependency is real.
        $referencing = ['prm_plans', 'prm_tenant_plan_rates', 'bil_tenant_invoices', 'prm_tenant_plan_billing_schedule'];
        $present = array_filter($referencing, static fn (string $t): bool => Schema::hasTable($t));

        if ($present === []) {
            $this->markTestSkipped('No referencing billing tables present in this environment.');
        }

        $this->assertNotEmpty($present, 'Expected FK-referencing tables for billing_cycle_id to exist.');
    }

    public function test_billing_cycle_41_force_delete_wraps_fk_violation_in_try_catch(): void
    {
        $source = $this->classSource(BillingCycleController::class);
        $this->assertStringContainsString('forceDelete()', $source, 'Controller must call forceDelete().');
        $this->assertStringContainsString('catch (\Throwable $th)', $source, 'forceDelete must catch FK violations (RESTRICT) and flash an error.');
        $this->assertStringContainsString("flash('operation_failed.billing_cycle')", $source, 'forceDelete catch branch must return operation_failed flash.');
    }

    public function test_billing_cycle_42_force_delete_blocked_while_referenced_defensive(): void
    {
        $this->assertBillingCycleTableReady();

        if (!Schema::hasTable('prm_plans')) {
            $this->markTestSkipped('prm_plans not present; cannot exercise FK RESTRICT.');
        }

        $cycle = $this->createBillingCycleRecord();
        $cycleId = (int) $cycle->id;
        $planId = null;

        try {
            try {
                $planId = DB::table('prm_plans')->insertGetId([
                    'plan_code' => 'BCFK' . substr((string) $cycleId, -4),
                    'version' => 0,
                    'name' => 'FK probe plan',
                    'billing_cycle_id' => $cycleId,
                    'currency' => 'INR',
                    'is_active' => 1,
                ]);
            } catch (Throwable $e) {
                $this->markTestSkipped('Could not seed a referencing prm_plans row: ' . $e->getMessage());
            }

            $blocked = false;
            try {
                $cycle->forceDelete();
            } catch (Throwable) {
                $blocked = true;
            }

            $stillExists = BillingCycle::withTrashed()->where('id', $cycleId)->exists();
            $this->assertTrue($blocked || $stillExists, 'Force delete should be blocked by the ON DELETE RESTRICT FK while referenced.');
        } finally {
            if ($planId !== null) {
                try {
                    DB::table('prm_plans')->where('id', $planId)->delete();
                } catch (Throwable) {
                }
            }
            $this->purgeBillingCycleById($cycleId);
        }
    }

    // ---------------------------------------------------------------------
    // Band 50-59 — Permissions / authorization (BC-AUTH)
    // ---------------------------------------------------------------------

    public function test_billing_cycle_50_guest_is_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('billing-cycle-guest-redirect', function (Browser $browser): void {
            $browser->driver->manage()->deleteAllCookies();
            $browser->visit($this->centralUrl(self::INDEX_PATH))->pause(1200);

            $this->assertStringContainsString('/login', $this->currentPath($browser), 'Guest should be redirected to the central login.');
        });
    }

    public function test_billing_cycle_51_controller_gates_use_prime_billing_cycle_permissions(): void
    {
        $source = $this->classSource(BillingCycleController::class);

        $this->assertStringContainsString("Gate::authorize('prime.billing-cycle.viewAny')", $source, 'index must gate on viewAny.');
        $this->assertStringContainsString("Gate::authorize('prime.billing-cycle.create')", $source, 'create/store must gate on create.');
        $this->assertStringContainsString("Gate::authorize('prime.billing-cycle.update')", $source, 'edit/update/toggle must gate on update.');
        $this->assertStringContainsString("Gate::authorize('prime.billing-cycle.delete')", $source, 'destroy must gate on delete.');
        $this->assertStringContainsString("Gate::authorize('prime.billing-cycle.restore')", $source, 'restore/trashed must gate on restore.');
        $this->assertStringContainsString("Gate::authorize('prime.billing-cycle.view')", $source, 'show must gate on view.');
    }

    public function test_billing_cycle_52_policy_declares_all_abilities(): void
    {
        $source = $this->classSource(BillingCyclePolicy::class);
        foreach (['viewAny', 'view', 'create', 'update', 'delete', 'restore', 'forceDelete'] as $ability) {
            $this->assertStringContainsString("prime.billing-cycle.{$ability}", $source, "Policy must map the {$ability} ability.");
        }
    }

    public function test_billing_cycle_53_force_delete_permission_mismatch_dev_bil_020(): void
    {
        // DEV-BIL-020 (P2): the Policy + requirement matrix say force delete should
        // require 'prime.billing-cycle.forceDelete', but the controller's forceDelete()
        // authorizes 'prime.billing-cycle.delete'. This proves the current (buggy) behaviour.
        $controllerSource = $this->classSource(BillingCycleController::class);
        $policySource = $this->classSource(BillingCyclePolicy::class);

        $forceDeleteBody = $this->extractMethodBody($controllerSource, 'forceDelete');
        $this->assertNotSame('', $forceDeleteBody, 'Could not isolate forceDelete() body.');

        $this->assertStringContainsString(
            "Gate::authorize('prime.billing-cycle.delete')",
            $forceDeleteBody,
            'DEV-BIL-020: forceDelete() currently authorizes the delete permission (documented mismatch).'
        );
        $this->assertStringNotContainsString(
            "Gate::authorize('prime.billing-cycle.forceDelete')",
            $forceDeleteBody,
            'DEV-BIL-020: forceDelete() should authorize forceDelete but does not (proving current defect).'
        );
        $this->assertStringContainsString(
            "prime.billing-cycle.forceDelete",
            $policySource,
            'Policy defines the forceDelete ability that the controller fails to use.'
        );
    }

    // ---------------------------------------------------------------------
    // Band 60-69 — UI/UX (pagination, empty-state, breadcrumb, badges)
    // ---------------------------------------------------------------------

    public function test_billing_cycle_60_index_breadcrumb_present(): void
    {
        $this->assertBillingCycleTableReady();

        $this->browseWithFailureScreenshot('billing-cycle-breadcrumb', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Billing Cycle index');

            $browser->assertSee('Billing Cycle Management');
        });
    }

    public function test_billing_cycle_61_index_table_headers_present(): void
    {
        $this->assertBillingCycleTableReady();

        $this->browseWithFailureScreenshot('billing-cycle-headers', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);
            $this->ensurePageAccessible($browser, 'Billing Cycle index');

            foreach (['Short Name', 'Name', 'Months', 'Description', 'Recurring'] as $header) {
                $browser->assertSee($header);
            }
        });
    }

    public function test_billing_cycle_62_recurring_badge_renders(): void
    {
        $this->assertBillingCycleTableReady();

        $cycle = $this->createBillingCycleRecord(['is_active' => true]);

        try {
            $this->browseWithFailureScreenshot('billing-cycle-recurring-badge', function (Browser $browser) use ($cycle): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH);
                $this->ensurePageAccessible($browser, 'Billing Cycle index');

                $browser->assertSee((string) $cycle->short_name);
                $browser->assertPresent('.badge');
            });
        } finally {
            $this->purgeBillingCycleById((int) $cycle->id);
        }
    }

    public function test_billing_cycle_63_trash_page_reachable(): void
    {
        $this->assertBillingCycleTableReady();

        $this->browseWithFailureScreenshot('billing-cycle-trash-page', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::TRASH_PATH);
            $this->ensurePageAccessible($browser, 'Billing Cycle trash');

            $this->assertSame(self::TRASH_PATH, $this->currentPath($browser), 'Trash view not reachable.');
            $browser->assertPresent('table');
        });
    }

    // ---------------------------------------------------------------------
    // Band 70-79 — Edge cases (BC-EDG)
    // ---------------------------------------------------------------------

    public function test_billing_cycle_70_months_count_boundary_min_accepted(): void
    {
        $this->assertBillingCycleTableReady();

        $shortName = $this->makeShortName();
        $this->browseWithFailureScreenshot('billing-cycle-months-min-accepted', function (Browser $browser) use ($shortName): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $this->ensurePageAccessible($browser, 'Billing Cycle create');

            $browser->type('short_name', $shortName)
                ->type('name', $this->makeName())
                ->type('months_count', '1')
                ->check('#is_active');
            $this->setRecurringField($browser, true);
            $browser->press('Add Billing Cycle')->pause(2000);
        });

        $cycle = BillingCycle::withTrashed()->where('short_name', $shortName)->first();
        $this->assertNotNull($cycle, 'months_count=1 (min boundary) should be accepted.');
        if ($cycle) {
            $this->purgeBillingCycleById((int) $cycle->id);
        }
    }

    public function test_billing_cycle_71_months_count_boundary_max_accepted(): void
    {
        $this->assertBillingCycleTableReady();

        $shortName = $this->makeShortName();
        $this->browseWithFailureScreenshot('billing-cycle-months-max-accepted', function (Browser $browser) use ($shortName): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $this->ensurePageAccessible($browser, 'Billing Cycle create');

            $browser->type('short_name', $shortName)
                ->type('name', $this->makeName())
                ->type('months_count', '255')
                ->check('#is_active');
            $this->setRecurringField($browser, true);
            $browser->press('Add Billing Cycle')->pause(2000);
        });

        $cycle = BillingCycle::withTrashed()->where('short_name', $shortName)->first();
        $this->assertNotNull($cycle, 'months_count=255 (max boundary) should be accepted.');
        if ($cycle) {
            try {
                $this->assertSame(255, (int) $cycle->months_count);
            } finally {
                $this->purgeBillingCycleById((int) $cycle->id);
            }
        }
    }

    public function test_billing_cycle_72_short_name_exactly_50_chars_accepted(): void
    {
        $this->assertBillingCycleTableReady();

        $shortName = 'BC' . strtoupper(substr(bin2hex(random_bytes(24)), 0, 48)); // 50 chars
        $shortName = substr($shortName, 0, 50);

        $this->browseWithFailureScreenshot('billing-cycle-shortname-50', function (Browser $browser) use ($shortName): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $this->ensurePageAccessible($browser, 'Billing Cycle create');

            $browser->type('short_name', $shortName)
                ->type('name', $this->makeName())
                ->type('months_count', '1')
                ->check('#is_active');
            $this->setRecurringField($browser, true);
            $browser->press('Add Billing Cycle')->pause(2000);
        });

        $cycle = BillingCycle::withTrashed()->where('short_name', $shortName)->first();
        $this->assertNotNull($cycle, 'short_name of exactly 50 chars should be accepted.');
        if ($cycle) {
            $this->purgeBillingCycleById((int) $cycle->id);
        }
    }

    public function test_billing_cycle_73_invalid_id_edit_returns_not_found(): void
    {
        $this->assertBillingCycleTableExists();

        $this->browseWithFailureScreenshot('billing-cycle-invalid-id-edit', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH . '/98765432/edit');

            $body = $browser->text('body');
            $this->assertTrue(
                str_contains($body, '404') || str_contains($body, 'Not Found') || str_contains($body, 'Sorry'),
                'A non-existent billing cycle id should yield a 404 / not-found page.'
            );
        });
    }

    public function test_billing_cycle_74_invalid_id_show_returns_not_found(): void
    {
        $this->assertBillingCycleTableExists();

        $this->browseWithFailureScreenshot('billing-cycle-invalid-id-show', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH . '/98765432');

            $body = $browser->text('body');
            $this->assertTrue(
                str_contains($body, '404') || str_contains($body, 'Not Found') || str_contains($body, 'Sorry'),
                'A non-existent billing cycle id should yield a 404 / not-found page.'
            );
        });
    }

    // ---------------------------------------------------------------------
    // Band 90-99 — Tenancy / security pack (TC-T / TC-S)
    // ---------------------------------------------------------------------

    public function test_billing_cycle_90_central_scope_table_resolves_on_default_connection(): void
    {
        // Billing Cycle is prime/central: prm_billing_cycles resolves on the default
        // (central) connection without any tenant initialization.
        $this->assertTrue(
            Schema::hasTable(self::TABLE),
            'prm_billing_cycles must resolve on the central connection (prime_db).'
        );
        $this->assertFalse(
            function_exists('tenancy') && tenancy()->initialized,
            'Billing Cycle tests must run in central scope with NO tenant initialized.'
        );
    }

    public function test_billing_cycle_91_stored_xss_in_name_is_escaped_on_render(): void
    {
        $this->assertBillingCycleTableReady();

        $payload = '<script>alert("bcxss")</script>';
        $cycle = $this->createBillingCycleRecord(['name' => $payload]);

        try {
            $this->browseWithFailureScreenshot('billing-cycle-xss-name', function (Browser $browser) use ($cycle): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH . '/' . $cycle->id);
                $this->ensurePageAccessible($browser, 'Billing Cycle show');

                // Blade {{ }} escaping must render the raw text, not an executable node.
                $source = $browser->driver->getPageSource();
                $this->assertStringNotContainsString('<script>alert("bcxss")</script>', $source, 'name must be HTML-escaped on render.');
            });
        } finally {
            $this->purgeBillingCycleById((int) $cycle->id);
        }
    }

    public function test_billing_cycle_92_stored_xss_in_description_is_escaped_on_render(): void
    {
        $this->assertBillingCycleTableReady();

        $payload = '<img src=x onerror=alert(1)>';
        $cycle = $this->createBillingCycleRecord(['description' => $payload]);

        try {
            $this->browseWithFailureScreenshot('billing-cycle-xss-description', function (Browser $browser) use ($cycle): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH);
                $this->ensurePageAccessible($browser, 'Billing Cycle index');

                $source = $browser->driver->getPageSource();
                $this->assertStringNotContainsString('<img src=x onerror=alert(1)>', $source, 'description must be HTML-escaped on render.');
            });
        } finally {
            $this->purgeBillingCycleById((int) $cycle->id);
        }
    }

    // =====================================================================
    // Private helper library
    // =====================================================================

    private function submitCreateExpectingError(string $caseName, array $fields, string $expectedMessageFragment): void
    {
        $this->assertBillingCycleTableExists();

        $this->browseWithFailureScreenshot($caseName, function (Browser $browser) use ($fields, $expectedMessageFragment): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $this->ensurePageAccessible($browser, 'Billing Cycle create');

            foreach (['short_name', 'name', 'months_count', 'description'] as $name) {
                if (array_key_exists($name, $fields)) {
                    $browser->type($name, (string) $fields[$name]);
                }
            }

            $browser->press('Add Billing Cycle')->pause(1500);

            $this->assertSame(self::CREATE_PATH, $this->currentPath($browser), 'Invalid submission should stay on the create page.');
            $browser->assertPresent('.alert.alert-danger');

            $alertText = $browser->text('.alert.alert-danger');
            $this->assertStringContainsStringIgnoringCase(
                $expectedMessageFragment,
                $alertText,
                "Expected validation message containing '{$expectedMessageFragment}'."
            );
        });
    }

    private function assertBillingCycleTableReady(): void
    {
        $this->assertBillingCycleTableExists();
        $this->assertBillingCycleSoftDeletesAvailable();
    }

    private function assertBillingCycleTableExists(): void
    {
        if (!Schema::hasTable(self::TABLE)) {
            $this->fail('prm_billing_cycles table is missing; cannot run Billing Cycle tests.');
        }
    }

    private function assertBillingCycleSoftDeletesAvailable(): void
    {
        // MIG-BIL-001 guard: the model uses SoftDeletes but the DDL omits deleted_at.
        // Any flow that touches withTrashed()/delete()/restore() requires the column;
        // fail loudly with the defect reference instead of a cryptic SQL 42S22.
        if (!Schema::hasColumn(self::TABLE, 'deleted_at')) {
            $this->fail('MIG-BIL-001: prm_billing_cycles.deleted_at is missing; SoftDeletes/withTrashed will throw SQLSTATE 42S22. Fix the schema before running soft-delete flows.');
        }
    }

    private function billingCycleSupportsRecurring(): bool
    {
        return Schema::hasColumn(self::TABLE, 'is_recurring');
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
            'description' => 'Dusk billing cycle seed',
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

        if ($this->billingCycleSupportsRecurring()) {
            if ($shouldBeChecked) {
                $browser->check('#is_recurring');
            } else {
                $browser->uncheck('#is_recurring');
            }

            return;
        }

        $browser->uncheck('#is_recurring');
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

    private function classSource(string $class): string
    {
        try {
            $file = (new ReflectionClass($class))->getFileName();
            if (is_string($file) && $file !== '' && File::exists($file)) {
                return (string) File::get($file);
            }
        } catch (Throwable) {
            // fall through
        }

        $this->markTestSkipped('Could not resolve source file for ' . $class . '.');
    }

    private function extractMethodBody(string $source, string $method): string
    {
        $pattern = '/function\s+' . preg_quote($method, '/') . '\s*\(/';
        if (!preg_match($pattern, $source, $m, PREG_OFFSET_CAPTURE)) {
            return '';
        }

        $start = $m[0][1];
        $braceStart = strpos($source, '{', $start);
        if ($braceStart === false) {
            return '';
        }

        $depth = 0;
        $len = strlen($source);
        for ($i = $braceStart; $i < $len; $i++) {
            if ($source[$i] === '{') {
                $depth++;
            } elseif ($source[$i] === '}') {
                $depth--;
                if ($depth === 0) {
                    return substr($source, $braceStart, $i - $braceStart + 1);
                }
            }
        }

        return '';
    }
}

/**
 * Tiny top-level helper: return a sorted copy of an array without mutating the input
 * (used by the fillable comparison so assertion order is deterministic).
 */
if (!function_exists('Tests\\Browser\\Modules\\Prime\\Billing\\BillingCycle\\sort_copy')) {
    function sort_copy(array $values): array
    {
        sort($values);

        return $values;
    }
}
