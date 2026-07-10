<?php

namespace Tests\Browser\Modules\Prime\Billing\BillingCycle;

use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\Billing\Models\BillingCycle;
use Tests\Browser\Modules\Prime\Billing\BillingDuskTestCase;
use Throwable;

/**
 * Billing Cycle — V1 foundation Dusk suite (central prime_db).
 *
 * DB scope: prime_db central (NOT tenant-per-school). No tenancy()->initialize
 * scaffolding — mirrors the committed sibling prm_BillingCycle_TestCas which
 * extends BillingDuskTestCase (central chain PrimeDuskTestCase) and uses
 * authenticateCentral()/visitAuthenticated()/centralUrl().
 *
 * Prefix prm_ verified against DDL Billing_DDL_v1.sql (CREATE TABLE `prm_billing_cycles`).
 */
class prm_BillingCycleV1_TestCas extends BillingDuskTestCase
{
    protected const SCREENSHOT_DIR = 'tests/Browser/Modules/Prime/Billing/BillingCycle/screenshots';
    protected const STATUS_REPORT_DIRECTORY = 'tests/Browser/Modules/Prime/Billing/BillingCycle/report';
    protected const STATUS_REPORT_PREFIX = 'billing_cycle_v1_report_';

    private const INDEX_PATH = '/billing/billing-cycle';
    private const CREATE_PATH = '/billing/billing-cycle/create';
    private const TRASH_PATH = '/billing/billing-cycle/trash/view';
    private const TABLE = 'prm_billing_cycles';

    // ------------------------------------------------------------------
    // Band 01-09 — Schema / model / request configuration
    // ------------------------------------------------------------------

    /** TC-P01 / BC-DB-*: schema, columns, unique index, model config are correct. */
    public function test_billing_cycle_01_schema_and_model_configuration_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable(self::TABLE), self::TABLE . ' table is missing.');

        foreach (['id', 'short_name', 'name', 'months_count', 'description', 'is_recurring', 'is_active'] as $column) {
            $this->assertTrue(
                Schema::hasColumn(self::TABLE, $column),
                self::TABLE . '.' . $column . ' column is missing.'
            );
        }

        $model = new BillingCycle();
        $this->assertSame(self::TABLE, $model->getTable(), 'Model table name mismatch.');

        foreach (['short_name', 'name', 'months_count', 'description', 'is_active', 'is_recurring'] as $fillable) {
            $this->assertContains($fillable, $model->getFillable(), $fillable . ' should be fillable.');
        }

        $casts = $model->getCasts();
        $this->assertSame('boolean', $casts['is_active'] ?? null, 'is_active should cast to boolean.');
        $this->assertSame('boolean', $casts['is_recurring'] ?? null, 'is_recurring should cast to boolean.');
        $this->assertSame('integer', $casts['months_count'] ?? null, 'months_count should cast to integer.');

        $this->assertContains(
            SoftDeletes::class,
            class_uses_recursive(BillingCycle::class),
            'BillingCycle model must use SoftDeletes.'
        );

        foreach (['tenantPlanRates', 'billingSchedules', 'invoices', 'plans'] as $relation) {
            $this->assertTrue(method_exists($model, $relation), 'Missing relationship: ' . $relation);
        }
    }

    /**
     * TC-P02 / DEV: MIG-BIL-001 schema guard.
     * The authoritative DDL (Billing_DDL_v1.sql `prm_billing_cycles`) declares NO
     * deleted_at / created_at / updated_at, yet the model uses SoftDeletes + timestamps.
     * The dev DB is hand-patched, so deleted_at exists here; a schema-correct DDL build
     * would fail this guard — that failure surfaces MIG-BIL-001 (P0).
     */
    public function test_billing_cycle_02_softdeletes_column_present_mig_bil_001_guard(): void
    {
        $this->assertTrue(
            Schema::hasColumn(self::TABLE, 'deleted_at'),
            'prm_billing_cycles.deleted_at is missing — SoftDeletes will break (see MIG-BIL-001).'
        );
    }

    // ------------------------------------------------------------------
    // Band 02-03 — Page render
    // ------------------------------------------------------------------

    /** TC-P03: index page loads and lists the table. */
    public function test_billing_cycle_03_index_loads(): void
    {
        $this->assertBillingCycleTableReady();

        $this->browseWithFailureScreenshot('v1-index-loads', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::INDEX_PATH);

            $this->assertSame(self::INDEX_PATH, $this->currentPath($browser), 'Index not reachable.');
            $this->ensurePageAccessible($browser, 'Billing Cycle index');
            $browser->assertSee('Billing Cycles');
            $browser->assertPresent('table');
        });
    }

    /** TC-P04: create page loads with the form fields. */
    public function test_billing_cycle_04_create_page_loads(): void
    {
        $this->assertBillingCycleTableExists();

        $this->browseWithFailureScreenshot('v1-create-loads', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH);

            $this->assertSame(self::CREATE_PATH, $this->currentPath($browser), 'Create page not reachable.');
            $this->ensurePageAccessible($browser, 'Billing Cycle create');
            $browser->assertPresent('#short_name')
                ->assertPresent('#name')
                ->assertPresent('#months_count')
                ->assertPresent('#is_recurring');
        });
    }

    // ------------------------------------------------------------------
    // Band 10-19 — Core CRUD business flows
    // ------------------------------------------------------------------

    /** TC-P05: create flow persists all fields. */
    public function test_billing_cycle_10_create_flow_persists_record(): void
    {
        $this->assertBillingCycleTableReady();

        $shortName = $this->makeShortName();
        $name = $this->makeName();

        $this->browseWithFailureScreenshot('v1-create-flow', function (Browser $browser) use ($shortName, $name): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $this->ensurePageAccessible($browser, 'Billing Cycle create');

            $browser->type('short_name', $shortName)
                ->type('name', $name)
                ->type('months_count', '1')
                ->type('description', 'V1 create test')
                ->check('#is_active');
            $this->setRecurringField($browser, true);
            $browser->press('Add Billing Cycle')->pause(2000);
        });

        $cycle = BillingCycle::withTrashed()->where('short_name', $shortName)->first();
        $this->assertNotNull($cycle, 'Billing cycle was not created.');

        if ($cycle) {
            try {
                $this->assertSame($name, (string) $cycle->name);
                $this->assertSame(1, (int) $cycle->months_count);
                $this->assertTrue((bool) $cycle->is_active);
                $this->assertTrue((bool) $cycle->is_recurring);
            } finally {
                $this->purgeBillingCycleById((int) $cycle->id);
            }
        }
    }

    /** TC-P06: update flow persists edited fields. */
    public function test_billing_cycle_11_update_flow_persists_changes(): void
    {
        $this->assertBillingCycleTableReady();

        $cycle = $this->createBillingCycleRecord(['months_count' => 2]);
        $newShort = $this->makeShortName();
        $newName = 'Updated ' . $this->makeName();

        try {
            $this->browseWithFailureScreenshot('v1-update-flow', function (Browser $browser) use ($cycle, $newShort, $newName): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH);
                $this->ensurePageAccessible($browser, 'Billing Cycle index');

                $this->clickEditAction($browser, (int) $cycle->id);
                $this->confirmSweetAlert($browser);
                $browser->waitFor('#short_name', 10);

                $this->assertSame(
                    self::INDEX_PATH . '/' . $cycle->id . '/edit',
                    $this->currentPath($browser),
                    'Edit page not reachable.'
                );

                $browser->type('short_name', $newShort)
                    ->type('name', $newName)
                    ->type('months_count', '3')
                    ->type('description', 'Updated by V1')
                    ->check('#is_active');
                $this->setRecurringField($browser, true);
                $browser->press('Update Billing Cycle')->pause(2000);
            });

            $cycle->refresh();
            $this->assertSame($newShort, (string) $cycle->short_name);
            $this->assertSame($newName, (string) $cycle->name);
            $this->assertSame(3, (int) $cycle->months_count);
            $this->assertSame('Updated by V1', (string) $cycle->description);
        } finally {
            $this->purgeBillingCycleById((int) $cycle->id);
        }
    }

    // ------------------------------------------------------------------
    // Band 20-29 — State machine (is_active toggle)
    // ------------------------------------------------------------------

    /** TC-P07 / BC-SM: status switch flips is_active active -> inactive. */
    public function test_billing_cycle_20_status_toggle_updates_is_active(): void
    {
        $this->assertBillingCycleTableReady();

        $cycle = $this->createBillingCycleRecord(['is_active' => true]);

        try {
            $this->browseWithFailureScreenshot('v1-toggle-status', function (Browser $browser) use ($cycle): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::INDEX_PATH);
                $this->ensurePageAccessible($browser, 'Billing Cycle index');

                $selector = '#statusSwitch-' . $cycle->id;
                $browser->assertPresent($selector)->click($selector)->pause(1500);
            });

            $cycle->refresh();
            $this->assertFalse((bool) $cycle->is_active, 'Status did not toggle to inactive.');
        } finally {
            $this->purgeBillingCycleById((int) $cycle->id);
        }
    }

    // ------------------------------------------------------------------
    // Band 30-39 — Validation
    // ------------------------------------------------------------------

    /** TC-N01: required-field validation keeps user on create page. */
    public function test_billing_cycle_30_create_requires_required_fields(): void
    {
        $this->assertBillingCycleTableExists();

        $this->browseWithFailureScreenshot('v1-required-validation', function (Browser $browser): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $this->ensurePageAccessible($browser, 'Billing Cycle create');

            $browser->press('Add Billing Cycle')->pause(1200);

            $this->assertSame(self::CREATE_PATH, $this->currentPath($browser), 'Validation should stay on create page.');
            $browser->assertPresent('.alert.alert-danger')
                ->assertPresent('.alert.alert-danger li');
        });
    }

    /** TC-N02: duplicate short_name is rejected. */
    public function test_billing_cycle_31_duplicate_short_name_rejected(): void
    {
        $this->assertBillingCycleTableReady();

        $cycle = $this->createBillingCycleRecord();
        $shortName = (string) $cycle->short_name;

        try {
            $this->browseWithFailureScreenshot('v1-duplicate-short-name', function (Browser $browser) use ($shortName): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::CREATE_PATH);
                $this->ensurePageAccessible($browser, 'Billing Cycle create');

                $browser->type('short_name', $shortName)
                    ->type('name', $this->makeName())
                    ->type('months_count', '2')
                    ->type('description', 'Duplicate test')
                    ->check('#is_active');
                $this->setRecurringField($browser, true);
                $browser->press('Add Billing Cycle')->pause(1500);

                $this->assertSame(self::CREATE_PATH, $this->currentPath($browser), 'Duplicate should stay on create page.');
                $browser->assertPresent('.alert.alert-danger');
            });

            $this->assertSame(
                1,
                BillingCycle::query()->where('short_name', $shortName)->count(),
                'Duplicate short name created a second billing cycle.'
            );
        } finally {
            $this->purgeBillingCycleById((int) $cycle->id);
        }
    }

    /** TC-N03: months_count below minimum (0) is rejected. */
    public function test_billing_cycle_32_months_count_below_min_rejected(): void
    {
        $this->assertBillingCycleTableExists();

        $shortName = $this->makeShortName();

        $this->browseWithFailureScreenshot('v1-months-min', function (Browser $browser) use ($shortName): void {
            $this->authenticateCentral($browser);
            $this->visitAuthenticated($browser, self::CREATE_PATH);
            $this->ensurePageAccessible($browser, 'Billing Cycle create');

            $browser->type('short_name', $shortName)
                ->type('name', $this->makeName())
                ->type('months_count', '0')
                ->check('#is_active');
            $this->setRecurringField($browser, true);
            $browser->press('Add Billing Cycle')->pause(1500);

            $this->assertSame(self::CREATE_PATH, $this->currentPath($browser), 'Invalid months_count should stay on create page.');
            $browser->assertPresent('.alert.alert-danger');
        });

        $this->assertFalse(
            BillingCycle::withTrashed()->where('short_name', $shortName)->exists(),
            'Invalid months_count should not create a record.'
        );
    }

    // ------------------------------------------------------------------
    // Band 40-49 — Soft delete / restore / force delete lifecycle
    // ------------------------------------------------------------------

    /** TC-D01: full soft-delete -> restore -> force-delete lifecycle. */
    public function test_billing_cycle_40_soft_delete_restore_and_force_delete_flow(): void
    {
        $this->assertBillingCycleTableReady();

        $cycle = $this->createBillingCycleRecord();
        $cycleId = (int) $cycle->id;
        $shortName = (string) $cycle->short_name;

        try {
            $this->browseWithFailureScreenshot('v1-trash-flow', function (Browser $browser) use ($cycleId, $shortName): void {
                $this->authenticateCentral($browser);

                $this->visitAuthenticated($browser, self::INDEX_PATH);
                $this->ensurePageAccessible($browser, 'Billing Cycle index');

                $this->clickDeleteAction($browser, $cycleId);
                $this->confirmSweetAlert($browser);
                $browser->pause(2000);

                $deleted = BillingCycle::withTrashed()->find($cycleId);
                $this->assertNotNull($deleted, 'Missing after soft delete.');
                $this->assertNotNull($deleted->deleted_at, 'Was not soft deleted.');
                $this->assertFalse((bool) $deleted->is_active, 'Soft delete should deactivate first.');

                $this->visitAuthenticated($browser, self::TRASH_PATH);
                $browser->assertSee($shortName);

                $this->clickRestoreAction($browser, $cycleId);
                $this->confirmSweetAlert($browser);
                $browser->pause(2000);

                $restored = BillingCycle::withTrashed()->find($cycleId);
                $this->assertNotNull($restored, 'Missing after restore.');
                $this->assertNull($restored->deleted_at, 'Was not restored.');

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

    // ------------------------------------------------------------------
    // Band 50-59 — Authorization
    // ------------------------------------------------------------------

    /** TC-N04: guest is redirected to /login. */
    public function test_billing_cycle_50_guest_redirected_to_login(): void
    {
        $this->browseWithFailureScreenshot('v1-guest-redirect', function (Browser $browser): void {
            $browser->visit($this->centralUrl(self::INDEX_PATH))->pause(1200);
            $this->assertStringContainsString(
                '/login',
                $this->currentPath($browser),
                'Guest should be redirected to /login.'
            );
        });
    }

    // ------------------------------------------------------------------
    // Band 60-69 — UI
    // ------------------------------------------------------------------

    /** TC-P08: trash view lists soft-deleted records. */
    public function test_billing_cycle_60_trash_view_lists_deleted(): void
    {
        $this->assertBillingCycleTableReady();

        $cycle = $this->createBillingCycleRecord();
        $cycle->delete();
        $shortName = (string) $cycle->short_name;

        try {
            $this->browseWithFailureScreenshot('v1-trash-list', function (Browser $browser) use ($shortName): void {
                $this->authenticateCentral($browser);
                $this->visitAuthenticated($browser, self::TRASH_PATH);
                $this->ensurePageAccessible($browser, 'Billing Cycle trash');
                $browser->assertSee($shortName);
            });
        } finally {
            $this->purgeBillingCycleById((int) $cycle->id);
        }
    }

    // ------------------------------------------------------------------
    // Private helper library (mirrors the committed sibling)
    // ------------------------------------------------------------------

    private function assertBillingCycleTableReady(): void
    {
        $this->assertBillingCycleTableExists();
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
            'description' => 'V1 billing cycle seed',
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
