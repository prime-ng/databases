<?php

namespace Tests\Browser;

use App\Models\User;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Schema;
use Laravel\Dusk\Browser;
use Modules\GlobalMaster\Models\ActivityLog;
use Modules\Prime\Models\Domain;
use Modules\SchoolSetup\Models\Subject;
use Tests\DuskTestCase;
use Throwable;

class SubjectCrudTest extends DuskTestCase
{
    private const INDEX_PATH = '/school-setup/school-class';
    private const TRASH_PATH = '/school-setup/subject/trash/view';
    private const VIEW_PATH_PREFIX = '/school-setup/subject/trash/views/';
    private const MIGRATION_FILE = 'database/migrations/tenant/2025_10_27_113828_create_subjects_table.php';
    private const REQUEST_FILE = 'Modules/SchoolSetup/app/Http/Requests/SubjectRequest.php';
    private const SCREENSHOT_DIR = 'tests/Browser/console/screenshots';

    private const TAB_SELECTOR = '#subject-tab';
    private const PANE_SELECTOR = '#subject';
    private const MODAL_SELECTOR = '#SubjectModal';
    private const MODAL_FORM_SELECTOR = '#SubjectModal #SubjectForm';
    private const MODAL_ID_SELECTOR = '#SubjectModal #subjects_id';
    private const MODAL_ORDINAL_SELECTOR = '#SubjectModal #ordinal_subjects';
    private const MODAL_CODE_SELECTOR = '#SubjectModal #code_subjects';
    private const MODAL_NAME_SELECTOR = '#SubjectModal #name_subjects';
    private const MODAL_SHORT_NAME_SELECTOR = '#SubjectModal #short_name_subjects';
    private const MODAL_ACTIVE_SELECTOR = '#SubjectModal input[name="is_active"]';

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

        $this->initializeTenantContext();
        $this->resolveAdminUser();
    }

    protected function tearDown(): void
    {
        if (function_exists('tenancy') && tenancy()->initialized) {
            tenancy()->end();
        }

        parent::tearDown();
    }

    public function test_subject_01_migration_model_and_request_configuration_are_correct(): void
    {
        $this->assertTrue(Schema::hasTable('sch_subjects'), 'Table sch_subjects does not exist.');
        $this->assertTrue(
            Schema::hasColumns('sch_subjects', [
                'ordinal',
                'short_name',
                'name',
                'code',
                'is_active',
                'created_at',
                'updated_at',
                'deleted_at',
            ]),
            'Expected columns are missing in sch_subjects table.'
        );

        $migrationPath = base_path(self::MIGRATION_FILE);
        $this->assertTrue(File::exists($migrationPath), 'Migration file not found: ' . self::MIGRATION_FILE);

        $migrationContent = File::get($migrationPath);
        $this->assertStringContainsString("Schema::create('sch_subjects'", $migrationContent);
        $this->assertStringContainsString("\$table->unsignedTinyInteger('ordinal')", $migrationContent);
        $this->assertStringContainsString("\$table->char('code', 5)", $migrationContent);
        $this->assertStringContainsString("\$table->string('short_name', 20)", $migrationContent);
        $this->assertStringContainsString("\$table->string('name', 50)", $migrationContent);
        $this->assertStringContainsString("\$table->boolean('is_active')", $migrationContent);
        $this->assertStringContainsString('$table->softDeletes()', $migrationContent);

        $driver = DB::connection()->getDriverName();
        if ($driver === 'mysql') {
            $uniqueCode = DB::select(
                "SHOW INDEX FROM sch_subjects WHERE Column_name = 'code' AND Non_unique = 0"
            );
            $this->assertTrue(
                !empty($uniqueCode) || str_contains($migrationContent, '->unique()'),
                'Unique index for sch_subjects.code is missing in runtime table and migration definition.'
            );

            $uniqueShortName = DB::select(
                "SHOW INDEX FROM sch_subjects WHERE Column_name = 'short_name' AND Non_unique = 0"
            );
            $this->assertTrue(
                !empty($uniqueShortName) || str_contains($migrationContent, '->unique()'),
                'Unique index for sch_subjects.short_name is missing in runtime table and migration definition.'
            );
        }

        $requestPath = base_path(self::REQUEST_FILE);
        $this->assertTrue(File::exists($requestPath), 'Request file not found: ' . self::REQUEST_FILE);

        $requestContent = File::get($requestPath);
        $this->assertStringContainsString("'short_name' =>", $requestContent);
        $this->assertStringContainsString('unique:sch_subjects,short_name', $requestContent);
        $this->assertStringContainsString("'name' =>", $requestContent);
        $this->assertStringContainsString('unique:sch_subjects,code', $requestContent);
        $this->assertStringContainsString('Short name is required', $requestContent);
        $this->assertStringContainsString('Name is required', $requestContent);
        $this->assertStringContainsString('Code is required', $requestContent);
        $this->assertStringContainsString('prepareForValidation', $requestContent);

        $subject = new Subject();
        $this->assertSame('sch_subjects', $subject->getTable());
        $this->assertSame(
            ['ordinal', 'short_name', 'name', 'code', 'is_active'],
            $subject->getFillable()
        );
        $this->assertContains(SoftDeletes::class, class_uses_recursive(Subject::class));
        $this->assertInstanceOf(BelongsToMany::class, $subject->subjectGroups());
        $this->assertInstanceOf(HasMany::class, $subject->classGroups());
        $this->assertInstanceOf(HasMany::class, $subject->subjectStudyFormats());
        $this->assertInstanceOf(BelongsToMany::class, $subject->teachers());
        $this->assertInstanceOf(HasMany::class, $subject->activities());

        $active = $this->createSubjectSeed($this->uniqueCode('A'), [
            'name' => $this->uniqueSubjectName('ACT'),
            'is_active' => true,
        ]);
        $inactive = $this->createSubjectSeed($this->uniqueCode('I'), [
            'name' => $this->uniqueSubjectName('INA'),
            'is_active' => false,
        ]);

        $this->assertTrue(
            Subject::query()->active()->whereKey($active->id)->exists(),
            'Subject::active scope did not return active subject.'
        );
        $this->assertFalse(
            Subject::query()->active()->whereKey($inactive->id)->exists(),
            'Subject::active scope incorrectly returned inactive subject.'
        );

        $this->forceDeleteSubject($active);
        $this->forceDeleteSubject($inactive);
    }

    public function test_subject_02_create_subject_works_and_records_issued_by(): void
    {
        $code = strtolower($this->uniqueCode('S'));
        $name = $this->uniqueSubjectName('CRT');
        $shortName = strtolower($this->uniqueShortName('CRT'));
        $ordinal = $this->nextAvailableOrdinal();

        $this->deleteSubjectByCode($code);
        $this->deleteSubjectByName($name);
        $this->deleteSubjectByShortName($shortName);

        $this->browseWithFailureScreenshot('sub-02-create', function (Browser $browser) use ($code, $name, $shortName, $ordinal): void {
            $this->authenticate($browser);
            $this->openSubjectTab($browser);
            $this->openSubjectCreateModal($browser);

            $this->fillSubjectModalFields($browser, [
                'ordinal' => $ordinal,
                'code' => $code,
                'name' => $name,
                'short_name' => $shortName,
                'is_active' => true,
            ]);

            $this->submitSubjectModalForm($browser);

            $browser->waitUsing(20, 250, function () use ($code): bool {
                return Subject::withTrashed()->where('code', strtoupper($code))->exists();
            }, 'Subject create did not persist in database.');
            $browser->pause(3400);

            $this->assertTrue(
                $this->isIndexPath($this->currentPath($browser)),
                'Create action did not return user to subject index tab.'
            );
        });

        $subject = Subject::withTrashed()->where('code', strtoupper($code))->first();
        $this->assertNotNull($subject, 'Subject record was not saved.');
        $this->assertSame($name, (string) $subject->name);
        $this->assertSame(strtoupper($code), (string) $subject->code);
        $this->assertSame(strtoupper($shortName), (string) $subject->short_name);
        $this->assertSame($ordinal, (int) $subject->ordinal);
        $this->assertTrue((bool) $subject->is_active);

        $this->assertActivityIssuedByAdmin((int) $subject->id, 'Stored');
        $this->forceDeleteSubject($subject);
    }

    public function test_subject_03_search_filter_returns_expected_row(): void
    {
        $match = $this->createSubjectSeed($this->uniqueCode('S1'), [
            'name' => $this->uniqueSubjectName('SRCH'),
            'short_name' => $this->uniqueShortName('SR'),
            'is_active' => true,
        ]);

        $other = $this->createSubjectSeed($this->uniqueCode('S2'), [
            'name' => $this->uniqueSubjectName('OTR'),
            'short_name' => $this->uniqueShortName('OT'),
            'is_active' => true,
        ]);

        $this->browseWithFailureScreenshot('sub-03-search', function (Browser $browser) use ($match, $other): void {
            $this->authenticate($browser);
            $this->openSubjectTab($browser, (string) $match->code);

            $this->assertTrue(
                $this->pageSourceContains($browser, (string) $match->code),
                'Search result did not include expected subject code.'
            );
            $this->assertFalse(
                $this->pageSourceContains($browser, (string) $other->code),
                'Search filter should not include unrelated subject.'
            );
        });

        $this->forceDeleteSubject($match);
        $this->forceDeleteSubject($other);
    }

    public function test_subject_04_status_filter_hides_inactive_records(): void
    {
        $active = $this->createSubjectSeed($this->uniqueCode('A1'), [
            'name' => $this->uniqueSubjectName('ACT'),
            'short_name' => $this->uniqueShortName('AC'),
            'is_active' => true,
        ]);

        $inactive = $this->createSubjectSeed($this->uniqueCode('I1'), [
            'name' => $this->uniqueSubjectName('INA'),
            'short_name' => $this->uniqueShortName('IN'),
            'is_active' => false,
        ]);

        $this->browseWithFailureScreenshot('sub-04-status', function (Browser $browser) use ($active, $inactive): void {
            $this->authenticate($browser);

            $this->openSubjectTab($browser, (string) $active->code, '1');
            $this->assertTrue(
                $this->pageSourceContains($browser, (string) $active->code),
                'Active subject missing when status filter is Active.'
            );

            $this->openSubjectTab($browser, (string) $inactive->code, '1');
            $this->assertTrue(
                $this->pageSourceContains($browser, 'No Subject Data Found')
                    || !$this->pageSourceContains($browser, (string) $inactive->code),
                'Inactive subject should be hidden when status filter is Active.'
            );

            $this->openSubjectTab($browser, (string) $inactive->code, '0');
            $this->assertTrue(
                $this->pageSourceContains($browser, (string) $inactive->code),
                'Inactive subject missing when status filter is Inactive.'
            );
        });

        $this->forceDeleteSubject($active);
        $this->forceDeleteSubject($inactive);
    }

    public function test_subject_05_required_validation_blocks_create(): void
    {
        $this->browseWithFailureScreenshot('sub-05-required', function (Browser $browser): void {
            $this->authenticate($browser);
            $this->openSubjectTab($browser);
            $this->openSubjectCreateModal($browser);

            $browser->script("document.querySelector('" . self::MODAL_FORM_SELECTOR . "')?.setAttribute('novalidate', 'novalidate');");

            $this->fillSubjectModalFields($browser, [
                'ordinal' => '',
                'code' => '',
                'name' => '',
                'short_name' => '',
                'is_active' => false,
            ]);

            $this->submitSubjectModalForm($browser);
            $browser->pause(1400);

            $this->assertTrue(
                $this->pageSourceContains($browser, 'Short name is required')
                    || $this->pageSourceContains($browser, 'Name is required')
                    || $this->pageSourceContains($browser, 'Code is required')
                    || $this->pageSourceContains($browser, 'text-danger')
                    || $this->pageSourceContains($browser, 'is-invalid'),
                'Expected required validation messages were not displayed.'
            );
            $this->assertTrue(
                $this->isIndexPath($this->currentPath($browser)),
                'Validation failure should keep user on subject index page.'
            );
        });
    }

    public function test_subject_06_duplicate_validation_blocks_create(): void
    {
        $code = $this->uniqueCode('D');
        $name = $this->uniqueSubjectName('DUP');
        $shortName = $this->uniqueShortName('DUP');

        $subject = $this->createSubjectSeed($code, [
            'name' => $name,
            'short_name' => $shortName,
            'is_active' => true,
        ]);

        $ordinal = $this->nextAvailableOrdinal([(int) $subject->ordinal]);

        $this->browseWithFailureScreenshot('sub-06-duplicate', function (Browser $browser) use ($code, $name, $shortName, $ordinal): void {
            $this->authenticate($browser);
            $this->openSubjectTab($browser);
            $this->openSubjectCreateModal($browser);

            $this->fillSubjectModalFields($browser, [
                'ordinal' => $ordinal,
                'code' => strtolower($code),
                'name' => $name,
                'short_name' => strtolower($shortName),
                'is_active' => true,
            ]);

            $this->submitSubjectModalForm($browser);
            $browser->pause(1500);

            $this->assertTrue(
                $this->pageSourceContains($browser, 'already exists')
                    || $this->pageSourceContains($browser, 'This short name already exists')
                    || $this->pageSourceContains($browser, 'This code already exists'),
                'Duplicate validation message was not shown.'
            );
        });

        $this->assertSame(
            1,
            Subject::withTrashed()->where('code', strtoupper($code))->count(),
            'Duplicate subject should not be inserted.'
        );

        $this->forceDeleteSubject($subject);
    }

    public function test_subject_07_view_page_shows_data_and_breadcrumb_works(): void
    {
        $subject = $this->createSubjectSeed($this->uniqueCode('V'), [
            'name' => $this->uniqueSubjectName('VIEW'),
            'short_name' => $this->uniqueShortName('VW'),
            'is_active' => true,
        ]);

        $this->browseWithFailureScreenshot('sub-07-view', function (Browser $browser) use ($subject): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::VIEW_PATH_PREFIX . $subject->id, 900);

            $browser
                ->waitForText('Subject Management', 12)
                ->assertSee((string) $subject->name)
                ->assertSee((string) $subject->short_name)
                ->assertSee((string) $subject->code);

            $this->assertBreadcrumbRedirectMatchesIndexAny($browser, ['subject', 'subjects'], 'view');
        });

        $this->forceDeleteSubject($subject);
    }

    public function test_subject_08_edit_confirmation_and_update_flow_work_with_issued_by(): void
    {
        $subject = $this->createSubjectSeed($this->uniqueCode('E'), [
            'name' => $this->uniqueSubjectName('EDT'),
            'short_name' => $this->uniqueShortName('ED'),
            'is_active' => true,
        ]);

        $newCode = strtolower($this->uniqueCode('U'));
        $newName = $this->uniqueSubjectName('UPD');
        $newShortName = strtolower($this->uniqueShortName('UP'));
        $newOrdinal = $this->nextAvailableOrdinal([(int) $subject->ordinal]);

        $this->deleteSubjectByCode($newCode);
        $this->deleteSubjectByName($newName);
        $this->deleteSubjectByShortName($newShortName);

        $this->browseWithFailureScreenshot('sub-08-edit-update', function (Browser $browser) use ($subject, $newCode, $newName, $newShortName, $newOrdinal): void {
            $this->authenticate($browser);
            $this->openSubjectTab($browser, (string) $subject->code);
            $this->clickEditButtonByMarker($browser, (string) $subject->code);
            $this->confirmEditAlertAndEnsureModalLoaded($browser, $subject);

            $this->fillSubjectModalFields($browser, [
                'ordinal' => $newOrdinal,
                'code' => $newCode,
                'name' => $newName,
                'short_name' => $newShortName,
                'is_active' => true,
            ]);

            $this->submitSubjectModalForm($browser);

            $browser->waitUsing(20, 250, function () use ($subject, $newCode): bool {
                return Subject::withTrashed()
                    ->whereKey($subject->id)
                    ->where('code', strtoupper($newCode))
                    ->exists();
            }, 'Subject update did not persist in database.');
            $browser->pause(3400);

            $this->assertTrue(
                $this->isIndexPath($this->currentPath($browser)),
                'Update action did not return user to subject index tab.'
            );
        });

        $subject->refresh();
        $this->assertSame($newName, (string) $subject->name);
        $this->assertSame(strtoupper($newCode), (string) $subject->code);
        $this->assertSame(strtoupper($newShortName), (string) $subject->short_name);
        $this->assertSame($newOrdinal, (int) $subject->ordinal);
        $this->assertTrue((bool) $subject->is_active, 'Subject is_active was not retained as active after update.');

        $this->assertActivityIssuedByAdmin((int) $subject->id, 'Updated');
        $this->forceDeleteSubject($subject);
    }

    public function test_subject_09_status_toggle_endpoint_updates_is_active(): void
    {
        $subject = $this->createSubjectSeed($this->uniqueCode('T'), [
            'name' => $this->uniqueSubjectName('TOG'),
            'short_name' => $this->uniqueShortName('TOG'),
            'is_active' => true,
        ]);

        $this->browseWithFailureScreenshot('sub-09-toggle', function (Browser $browser) use ($subject): void {
            $this->authenticate($browser);
            $this->openSubjectTab($browser, (string) $subject->code);

            $response = $this->sendJsonRequestFromBrowser(
                $browser,
                'POST',
                '/school-setup/subject/' . $subject->id . '/toggle-status',
                []
            );

            $this->assertSame(200, (int) ($response['status'] ?? 0), 'Toggle status did not return HTTP 200.');
            $json = is_array($response['json'] ?? null) ? $response['json'] : [];
            $this->assertTrue((bool) ($json['success'] ?? false), 'Toggle status response success is false.');
            $this->assertTrue(
                str_contains((string) ($json['message'] ?? ''), 'Subject Status updated'),
                'Toggle status success message is missing.'
            );
        });

        $subject->refresh();
        $this->assertFalse((bool) $subject->is_active, 'Subject status was not toggled to inactive.');

        $this->assertActivityIssuedByAdmin((int) $subject->id, 'Toggel Status');
        $this->forceDeleteSubject($subject);
    }

    public function test_subject_10_delete_restore_force_delete_flow_and_alerts_work(): void
    {
        $subject = $this->createSubjectSeed($this->uniqueCode('R'), [
            'name' => $this->uniqueSubjectName('REC'),
            'short_name' => $this->uniqueShortName('REC'),
            'is_active' => true,
        ]);

        $this->browseWithFailureScreenshot('sub-10-soft-delete', function (Browser $browser) use ($subject): void {
            $this->authenticate($browser);
            $this->openSubjectTab($browser, (string) $subject->code);
            $this->clickDeleteButtonByMarker($browser, (string) $subject->code);

            $browser->waitFor('.swal2-popup', 10)
                ->assertSee('Are you sure?')
                ->assertSee('Move to Trash: The item can be restored later.')
                ->click('.swal2-confirm');

            $browser->waitUsing(20, 200, function () use ($subject): bool {
                return Subject::withTrashed()
                    ->whereKey($subject->id)
                    ->whereNotNull('deleted_at')
                    ->exists();
            }, 'Subject was not soft deleted after confirmation.');
        });

        $subject->refresh();
        $this->assertNotNull($subject->deleted_at, 'Subject was not soft deleted.');
        $this->assertActivityIssuedByAdmin((int) $subject->id, 'Delete');

        $this->browseWithFailureScreenshot('sub-10-restore', function (Browser $browser) use ($subject): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::TRASH_PATH, 900);

            $browser->waitUsing(12, 200, function () use ($browser): bool {
                return $this->pageSourceContains($browser, 'Subject Management')
                    || $this->pageSourceContains($browser, 'No Trashed Records Found');
            }, 'Trash page heading did not load.');

            $this->navigateTrashPaginationToMarker($browser, (string) $subject->code);
            $this->clickRestoreLinkFromTrash($browser, (string) $subject->code);

            $browser->waitFor('.swal2-popup', 10)
                ->assertSee('Sure to restore?')
                ->assertSee('Do you want to proceed to restore?')
                ->click('.swal2-confirm')
                ->pause(1900);

            $this->assertTrue(
                $this->isTrashPath($this->currentPath($browser)),
                'Restore action did not keep user on subject trash page.'
            );
        });

        $subject->refresh();
        $this->assertNull($subject->deleted_at, 'Subject was not restored.');
        $this->assertActivityIssuedByAdmin((int) $subject->id, 'Restore');

        $this->browseWithFailureScreenshot('sub-10-soft-delete-again', function (Browser $browser) use ($subject): void {
            $this->authenticate($browser);
            $this->openSubjectTab($browser, (string) $subject->code);
            $this->clickDeleteButtonByMarker($browser, (string) $subject->code);

            $browser->waitFor('.swal2-popup', 10)
                ->assertSee('Are you sure?')
                ->click('.swal2-confirm');

            $browser->waitUsing(20, 200, function () use ($subject): bool {
                return Subject::withTrashed()
                    ->whereKey($subject->id)
                    ->whereNotNull('deleted_at')
                    ->exists();
            }, 'Subject was not soft deleted before force delete.');
        });

        $subject->refresh();
        $this->assertNotNull($subject->deleted_at, 'Subject was not soft deleted before force delete.');

        $this->browseWithFailureScreenshot('sub-10-force-delete', function (Browser $browser) use ($subject): void {
            $this->authenticate($browser);
            $this->visitAuthenticated($browser, self::TRASH_PATH, 900);
            $this->navigateTrashPaginationToMarker($browser, (string) $subject->code);
            $this->clickForceDeleteButtonFromTrash($browser, (string) $subject->code);

            $browser->waitFor('.swal2-popup', 10)
                ->assertSee('Delete Permanently ?')
                ->assertSee("Permanently deleted item can't be restored later!")
                ->click('.swal2-confirm')
                ->pause(2000);

            $this->assertTrue(
                $this->isTrashPath($this->currentPath($browser)),
                'Force delete action did not keep user on subject trash page.'
            );
        });

        $this->assertFalse(
            Subject::withTrashed()->whereKey($subject->id)->exists(),
            'Subject still exists after force delete.'
        );
        $this->assertActivityIssuedByAdmin((int) $subject->id, 'Delete');
    }

    public function test_subject_11_breadcrumb_links_work_for_create_view_edit_and_trash_pages(): void
    {
        $subject = $this->createSubjectSeed($this->uniqueCode('B'), [
            'name' => $this->uniqueSubjectName('BRC'),
            'short_name' => $this->uniqueShortName('BR'),
            'is_active' => true,
        ]);

        $this->browseWithFailureScreenshot('sub-11-breadcrumbs', function (Browser $browser) use ($subject): void {
            $this->authenticate($browser);

            $this->openSubjectTab($browser);
            $this->openSubjectCreateModal($browser);
            $this->assertBreadcrumbLabelOrLinkExists($browser, 'class & section', 'create');

            $this->openSubjectTab($browser, (string) $subject->code);
            $this->clickEditButtonByMarker($browser, (string) $subject->code);
            $this->confirmEditAlertAndEnsureModalLoaded($browser, $subject);
            $this->assertBreadcrumbLabelOrLinkExists($browser, 'class & section', 'edit');

            $this->visitAuthenticated($browser, self::VIEW_PATH_PREFIX . $subject->id, 900);
            $browser->waitForText('Subject Management', 12)->assertSee((string) $subject->name);
            $this->assertBreadcrumbRedirectMatchesIndexAny($browser, ['subject', 'subjects'], 'view');

            $this->visitAuthenticated($browser, self::TRASH_PATH, 900);
            $browser->waitUsing(12, 200, function () use ($browser): bool {
                return $this->pageSourceContains($browser, 'Subject Management')
                    || $this->pageSourceContains($browser, 'No Trashed Records Found');
            }, 'Trash page heading did not load for breadcrumb test.');
            $this->assertBreadcrumbRedirectMatchesIndexAny($browser, ['subject', 'subjects'], 'trash');
        });

        $this->forceDeleteSubject($subject);
    }

    public function test_subject_12_show_endpoint_returns_payload(): void
    {
        $subject = $this->createSubjectSeed($this->uniqueCode('S'), [
            'name' => $this->uniqueSubjectName('SHOW'),
            'short_name' => $this->uniqueShortName('SH'),
            'is_active' => true,
        ]);

        $this->browseWithFailureScreenshot('sub-12-show-endpoint', function (Browser $browser) use ($subject): void {
            $this->authenticate($browser);
            $this->openSubjectTab($browser);

            $response = $this->sendJsonRequestFromBrowser(
                $browser,
                'GET',
                '/school-setup/subject/' . $subject->id
            );

            $this->assertSame(200, (int) ($response['status'] ?? 0), 'Show endpoint did not return HTTP 200.');
            $payload = is_array($response['json'] ?? null) ? $response['json'] : [];
            $this->assertSame((int) $subject->id, (int) ($payload['id'] ?? 0), 'Show endpoint returned wrong id.');
            $this->assertSame((string) $subject->name, (string) ($payload['name'] ?? ''), 'Show endpoint returned wrong name.');
            $this->assertSame((string) $subject->code, (string) ($payload['code'] ?? ''), 'Show endpoint returned wrong code.');
        });

        $this->forceDeleteSubject($subject);
    }

    public function test_subject_13_show_endpoint_returns_404_for_invalid_id(): void
    {
        $this->browseWithFailureScreenshot('sub-13-show-invalid', function (Browser $browser): void {
            $this->authenticate($browser);
            $this->openSubjectTab($browser);

            $response = $this->sendJsonRequestFromBrowser(
                $browser,
                'GET',
                '/school-setup/subject/999999999'
            );

            $this->assertSame(404, (int) ($response['status'] ?? 0), 'Show invalid id should return HTTP 404.');
            $json = is_array($response['json'] ?? null) ? $response['json'] : [];
            $this->assertFalse((bool) ($json['success'] ?? true), 'Show invalid id success should be false.');
            $this->assertTrue(
                str_contains((string) ($json['message'] ?? ''), 'not found'),
                'Show invalid id error message mismatch.'
            );
        });
    }

    public function test_subject_14_update_endpoint_returns_404_for_invalid_id(): void
    {
        $code = $this->uniqueCode('X');
        $name = $this->uniqueSubjectName('MISSING');
        $shortName = $this->uniqueShortName('MS');

        $this->deleteSubjectByCode($code);
        $this->deleteSubjectByName($name);
        $this->deleteSubjectByShortName($shortName);

        $this->browseWithFailureScreenshot('sub-14-update-invalid', function (Browser $browser) use ($code, $name, $shortName): void {
            $this->authenticate($browser);
            $this->openSubjectTab($browser);

            $response = $this->sendJsonRequestFromBrowser(
                $browser,
                'PUT',
                '/school-setup/subject/999999999',
                [
                    'ordinal' => 10,
                    'short_name' => $shortName,
                    'name' => $name,
                    'code' => $code,
                    'is_active' => true,
                ]
            );

            $this->assertSame(404, (int) ($response['status'] ?? 0), 'Update invalid id should return HTTP 404.');
            $json = is_array($response['json'] ?? null) ? $response['json'] : [];
            $this->assertFalse((bool) ($json['success'] ?? true), 'Update invalid id success should be false.');
            $this->assertTrue(
                str_contains((string) ($json['message'] ?? ''), 'not found'),
                'Update invalid id error message mismatch.'
            );
        });
    }

    public function test_subject_15_destroy_endpoint_returns_404_for_invalid_id(): void
    {
        $this->browseWithFailureScreenshot('sub-15-destroy-invalid', function (Browser $browser): void {
            $this->authenticate($browser);
            $this->openSubjectTab($browser);

            $response = $this->sendJsonRequestFromBrowser(
                $browser,
                'DELETE',
                '/school-setup/subject/999999999',
                []
            );

            $this->assertSame(404, (int) ($response['status'] ?? 0), 'Destroy invalid id should return HTTP 404.');
            $json = is_array($response['json'] ?? null) ? $response['json'] : [];
            $this->assertFalse((bool) ($json['success'] ?? true), 'Destroy invalid id success should be false.');
            $this->assertTrue(
                str_contains((string) ($json['message'] ?? ''), 'not found'),
                'Destroy invalid id error message mismatch.'
            );
        });
    }

    public function test_subject_16_toggle_status_returns_error_for_invalid_id(): void
    {
        $this->browseWithFailureScreenshot('sub-16-toggle-invalid', function (Browser $browser): void {
            $this->authenticate($browser);
            $this->openSubjectTab($browser);

            $response = $this->sendJsonRequestFromBrowser(
                $browser,
                'POST',
                '/school-setup/subject/999999999/toggle-status',
                []
            );

            $this->assertSame(404, (int) ($response['status'] ?? 0), 'Toggle status invalid id should return HTTP 404.');
            $json = is_array($response['json'] ?? null) ? $response['json'] : [];
            $this->assertFalse((bool) ($json['success'] ?? true), 'Toggle invalid id success should be false.');
            $this->assertTrue(
                str_contains((string) ($json['message'] ?? ''), 'not found'),
                'Toggle invalid id error message mismatch.'
            );
        });
    }

    private function browseWithFailureScreenshot(string $caseName, callable $callback): void
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

    private function captureFailureScreenshot(Browser $browser, string $caseName): void
    {
        $directory = base_path(self::SCREENSHOT_DIR);
        File::ensureDirectoryExists($directory);

        $timestamp = now()->format('Ymd_His');
        $rawName = 'subject-fail-' . $caseName . '-' . $timestamp;
        $safeName = preg_replace('/[^A-Za-z0-9_-]+/', '-', $rawName);
        $safeName = is_string($safeName) && $safeName !== '' ? $safeName : 'subject-fail-' . $timestamp;

        $path = $directory . DIRECTORY_SEPARATOR . $safeName . '.png';

        try {
            $browser->driver->takeScreenshot($path);
        } catch (Throwable) {
            // Keep original test failure as primary signal.
        }
    }

    private function openSubjectTab(Browser $browser, ?string $search = null, ?string $status = null): void
    {
        $path = self::INDEX_PATH;
        $query = [];

        if ($search !== null && $search !== '') {
            $query['search'] = $search;
        }
        if ($status !== null && $status !== '') {
            $query['status'] = $status;
        }

        if (!empty($query)) {
            $path .= '?' . http_build_query($query);
        }

        $this->visitAuthenticated($browser, $path, 900);

        $browser->waitUsing(20, 200, function () use ($browser): bool {
            return $browser->element(self::TAB_SELECTOR) !== null || $browser->element(self::PANE_SELECTOR) !== null;
        }, 'Subject tab did not load.');

        if ($browser->element(self::TAB_SELECTOR)) {
            $browser->script(<<<'JS'
(function () {
    const tab = document.querySelector('#subject-tab');
    if (tab && window.bootstrap?.Tab) {
        window.bootstrap.Tab.getOrCreateInstance(tab).show();
    } else if (tab) {
        tab.click();
    }
})();
JS);
            $browser->pause(450);
        }

        if ($browser->element(self::PANE_SELECTOR)) {
            $browser->waitFor(self::PANE_SELECTOR, 12);
        }

        $browser->waitUsing(20, 200, function () use ($browser): bool {
            return $browser->element('#subject table') !== null;
        }, 'Subject table did not render.');
    }

    private function openSubjectCreateModal(Browser $browser): void
    {
        $browser->script(<<<'JS'
(function () {
    const modalEl = document.querySelector('#SubjectModal');
    const form = modalEl ? modalEl.querySelector('#SubjectForm') : null;

    if (form) {
        form.setAttribute('novalidate', 'novalidate');
        form.reset();
    }

    const idField = modalEl ? modalEl.querySelector('#subjects_id') : null;
    if (idField) {
        idField.value = '';
    }
})();
JS);

        if ($browser->element('#subject a[data-bs-target="#SubjectModal"]')) {
            $browser->click('#subject a[data-bs-target="#SubjectModal"]');
        } else {
            $browser->script(<<<'JS'
(function () {
    const modalEl = document.getElementById('SubjectModal');
    if (!modalEl) {
        throw new Error('Subject modal not found.');
    }

    const modal = window.bootstrap?.Modal?.getOrCreateInstance(modalEl);
    if (!modal) {
        throw new Error('Bootstrap modal instance not available for subject modal.');
    }

    modal.show();
})();
JS);
        }

        $this->waitForSubjectModalShown($browser);
    }

    private function waitForSubjectModalShown(Browser $browser): void
    {
        $browser->waitUsing(15, 200, function () use ($browser): bool {
            $result = $browser->script(
                "return document.querySelector('#SubjectModal')?.classList.contains('show') || false;"
            );

            return is_array($result) && (($result[0] ?? false) === true);
        }, 'Subject modal did not open.');
    }

    private function fillSubjectModalFields(Browser $browser, array $payload): void
    {
        $normalized = [
            'ordinal' => array_key_exists('ordinal', $payload) ? (string) $payload['ordinal'] : '',
            'code' => (string) ($payload['code'] ?? ''),
            'name' => (string) ($payload['name'] ?? ''),
            'short_name' => (string) ($payload['short_name'] ?? ''),
            'is_active' => (bool) ($payload['is_active'] ?? true),
        ];
        $encodedPayload = json_encode($normalized, JSON_THROW_ON_ERROR);

        $browser->script(<<<JS
(function () {
    const payload = {$encodedPayload};
    const modal = document.querySelector('#SubjectModal');

    if (!modal) {
        throw new Error('Subject modal not found while filling fields.');
    }

    const setValue = (selector, value) => {
        const field = modal.querySelector(selector);
        if (!field) {
            throw new Error('Subject modal field not found: ' + selector);
        }

        field.focus();
        field.value = '';
        field.dispatchEvent(new Event('input', { bubbles: true }));
        field.value = value === null || value === undefined ? '' : String(value);
        field.dispatchEvent(new Event('input', { bubbles: true }));
        field.dispatchEvent(new Event('change', { bubbles: true }));
        field.blur();
    };

    setValue('#ordinal_subjects', payload.ordinal);
    setValue('#code_subjects', payload.code);
    setValue('#name_subjects', payload.name);
    setValue('#short_name_subjects', payload.short_name);

    const active = modal.querySelector('input[name="is_active"]');
    if (active) {
        active.checked = payload.is_active === true;
        active.dispatchEvent(new Event('change', { bubbles: true }));
    }
})();
JS);
    }

    private function submitSubjectModalForm(Browser $browser): void
    {
        $browser->script(<<<'JS'
(function () {
    const form = document.querySelector('#SubjectModal #SubjectForm');
    if (!form) {
        throw new Error('Subject form not found for submit.');
    }

    form.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }));
})();
JS);
    }

    private function waitForEditModalLoaded(Browser $browser): void
    {
        $browser->waitUsing(15, 200, function () use ($browser): bool {
            return $this->isEditModalLoaded($browser);
        }, 'Edit modal did not load subject data.');
    }

    private function isEditModalLoaded(Browser $browser): bool
    {
        $result = $browser->script(<<<'JS'
return (function () {
    const modal = document.querySelector('#SubjectModal.show');
    const idField = modal ? modal.querySelector('#subjects_id') : null;

    return Boolean(
        modal
        && modal.classList.contains('show')
        && idField
        && String(idField.value || '').trim() !== ''
    );
})();
JS);

        return is_array($result) && (($result[0] ?? false) === true);
    }

    private function confirmEditAlertAndEnsureModalLoaded(Browser $browser, Subject $subject): void
    {
        $browser->waitFor('.swal2-popup', 10)
            ->assertSee('Sure to Edit?')
            ->assertSee('Do you want to proceed to edit?');

        $browser->script(<<<'JS'
(function () {
    const button = document.querySelector('.swal2-confirm');
    if (button) {
        button.click();
    }
})();
JS);
        $browser->pause(700);

        if (!$this->isEditModalLoaded($browser)) {
            $payload = [
                'id' => (int) $subject->id,
                'name' => (string) $subject->name,
                'short_name' => (string) ($subject->short_name ?? ''),
                'ordinal' => (int) $subject->ordinal,
                'code' => (string) $subject->code,
                'is_active' => (bool) $subject->is_active,
            ];
            $encoded = json_encode($payload, JSON_THROW_ON_ERROR);

            $browser->script(<<<JS
(function () {
    const payload = {$encoded};

    const modalEl = document.getElementById('SubjectModal');
    const idField = modalEl ? modalEl.querySelector('#subjects_id') : null;
    const ordinal = modalEl ? modalEl.querySelector('#ordinal_subjects') : null;
    const code = modalEl ? modalEl.querySelector('#code_subjects') : null;
    const name = modalEl ? modalEl.querySelector('#name_subjects') : null;
    const shortName = modalEl ? modalEl.querySelector('#short_name_subjects') : null;
    const isActive = modalEl ? modalEl.querySelector('input[name="is_active"]') : null;

    if (!idField || !ordinal || !code || !name || !shortName || !modalEl) {
        return;
    }

    idField.value = String(payload.id);
    ordinal.value = String(payload.ordinal ?? '');
    code.value = payload.code;
    name.value = payload.name;
    shortName.value = payload.short_name || '';
    if (isActive) {
        isActive.checked = payload.is_active === true;
    }

    const modal = window.bootstrap?.Modal?.getOrCreateInstance(modalEl);
    if (modal) {
        modal.show();
    }
})();
JS);
        }

        $this->waitForEditModalLoaded($browser);
    }

    private function clickEditButtonByMarker(Browser $browser, string $marker): void
    {
        $encodedMarker = json_encode($marker);

        $browser->script(<<<JS
(function () {
    const marker = {$encodedMarker};
    const rows = Array.from(document.querySelectorAll('#subject table tbody tr, table tbody tr'));
    const row = rows.find((item) => item.innerText.includes(marker));

    if (!row) {
        throw new Error('Subject row not found for edit marker: ' + marker);
    }

    const button = row.querySelector('a[onclick^="editSubject("]')
        || row.querySelector('button[onclick^="editSubject("]');
    if (!button) {
        throw new Error('Edit button not found for subject marker: ' + marker);
    }

    button.click();
})();
JS);
    }

    private function clickDeleteButtonByMarker(Browser $browser, string $marker): void
    {
        $encodedMarker = json_encode($marker);

        $browser->script(<<<JS
(function () {
    const marker = {$encodedMarker};
    const rows = Array.from(document.querySelectorAll('#subject table tbody tr, table tbody tr'));
    const row = rows.find((item) => item.innerText.includes(marker));

    if (!row) {
        throw new Error('Subject row not found for delete marker: ' + marker);
    }

    const button = row.querySelector('a[onclick^="deleteSubject("]')
        || row.querySelector('button[onclick^="deleteSubject("]');
    if (!button) {
        throw new Error('Delete button not found for subject marker: ' + marker);
    }

    button.click();
})();
JS);
    }

    private function clickRestoreLinkFromTrash(Browser $browser, string $marker): void
    {
        if (!$this->pageSourceContains($browser, $marker)) {
            $this->navigateTrashPaginationToMarker($browser, $marker);
        }

        $encodedMarker = json_encode($marker);

        $browser->script(<<<JS
(function () {
    const marker = {$encodedMarker};
    const rows = Array.from(document.querySelectorAll('table tbody tr'));
    const row = rows.find((item) => item.innerText.includes(marker));

    if (!row) {
        throw new Error('Trash row not found for restore marker: ' + marker);
    }

    const link = row.querySelector('a.confirm-action-restore');
    if (!link) {
        throw new Error('Restore action not found for subject marker: ' + marker);
    }

    link.click();
})();
JS);
    }

    private function clickForceDeleteButtonFromTrash(Browser $browser, string $marker): void
    {
        if (!$this->pageSourceContains($browser, $marker)) {
            $this->navigateTrashPaginationToMarker($browser, $marker);
        }

        $encodedMarker = json_encode($marker);

        $browser->script(<<<JS
(function () {
    const marker = {$encodedMarker};
    const rows = Array.from(document.querySelectorAll('table tbody tr'));
    const row = rows.find((item) => item.innerText.includes(marker));

    if (!row) {
        throw new Error('Trash row not found for force delete marker: ' + marker);
    }

    const form = row.querySelector('form.confirm-action-form-force-delete');
    if (!form) {
        throw new Error('Force delete form not found for subject marker: ' + marker);
    }

    const button = form.querySelector('button[type="submit"]');
    if (!button) {
        throw new Error('Force delete button not found for subject marker: ' + marker);
    }

    button.click();
})();
JS);
    }

    private function navigateTrashPaginationToMarker(Browser $browser, string $marker): void
    {
        $encodedMarker = json_encode($marker);

        for ($attempt = 0; $attempt < 6; $attempt++) {
            $found = $browser->script(<<<JS
return (function () {
    const marker = {$encodedMarker};
    return Array.from(document.querySelectorAll('table tbody tr'))
        .some((row) => row.innerText.includes(marker));
})();
JS);

            if (is_array($found) && (($found[0] ?? false) === true)) {
                return;
            }

            $hasNext = $browser->script(<<<'JS'
return (function () {
    const next = document.querySelector('a[rel="next"]');
    if (!next) {
        return false;
    }
    next.click();
    return true;
})();
JS);

            if (!is_array($hasNext) || (($hasNext[0] ?? false) !== true)) {
                break;
            }

            $browser->pause(1000);
        }
    }

    private function assertBreadcrumbRedirectMatchesIndex(Browser $browser, string $linkText, string $context): void
    {
        $targetText = strtolower(trim($linkText));
        $encodedText = json_encode($targetText);

        $hrefResult = $browser->script(<<<JS
return (function () {
    const target = {$encodedText};
    const links = Array.from(document.querySelectorAll('ol.breadcrumb a'));
    const match = links.find((link) => (link.textContent || '').trim().toLowerCase() === target);
    return match ? match.href : '';
})();
JS);

        $href = is_array($hrefResult) ? (string) ($hrefResult[0] ?? '') : '';
        $this->assertNotSame('', $href, 'Breadcrumb link "' . $linkText . '" not found on ' . $context . ' page.');

        $targetPath = parse_url($href, PHP_URL_PATH);
        $targetPath = is_string($targetPath) ? $targetPath : '';

        $this->assertTrue(
            $this->isIndexPath($targetPath),
            'Breadcrumb target mismatch on ' . $context . ' page. Target: ' . $targetPath
        );

        $beforeHandles = count($browser->driver->getWindowHandles());
        $encodedHref = json_encode($href);
        $browser->script("window.location.href = {$encodedHref};");

        $browser->waitUsing(15, 200, function () use ($browser): bool {
            return $this->isIndexPath($this->currentPath($browser));
        }, 'Breadcrumb did not redirect to subject index path.');

        $afterHandles = count($browser->driver->getWindowHandles());
        $this->assertSame(
            $beforeHandles,
            $afterHandles,
            'Breadcrumb opened a new tab/window on ' . $context . ' page.'
        );
    }

    private function assertBreadcrumbRedirectMatchesIndexAny(Browser $browser, array $linkTexts, string $context): void
    {
        $lastError = null;

        foreach ($linkTexts as $linkText) {
            try {
                $this->assertBreadcrumbRedirectMatchesIndex($browser, (string) $linkText, $context);
                return;
            } catch (Throwable $e) {
                $lastError = $e;
            }
        }

        if ($lastError instanceof Throwable) {
            throw $lastError;
        }

        $this->fail('No breadcrumb link text candidates were provided.');
    }

    private function assertBreadcrumbLabelOrLinkExists(Browser $browser, string $text, string $context): void
    {
        $targetText = strtolower(trim($text));
        $encodedText = json_encode($targetText);

        $result = $browser->script(<<<JS
return (function () {
    const target = {$encodedText};
    const items = Array.from(document.querySelectorAll('ol.breadcrumb a, ol.breadcrumb li'));
    const found = items.find((item) => (item.textContent || '').trim().toLowerCase() === target);
    if (!found) {
        return { found: false, href: '' };
    }

    return {
        found: true,
        href: found.tagName.toLowerCase() === 'a' ? (found.getAttribute('href') || '') : ''
    };
})();
JS);

        $payload = is_array($result) ? ($result[0] ?? null) : null;
        $found = is_array($payload) ? (bool) ($payload['found'] ?? false) : false;
        $href = is_array($payload) ? (string) ($payload['href'] ?? '') : '';

        $this->assertTrue($found, 'Breadcrumb item "' . $text . '" not found on ' . $context . ' page.');

        if ($href !== '') {
            $targetPath = parse_url($href, PHP_URL_PATH);
            $targetPath = is_string($targetPath) ? $targetPath : '';
            $this->assertNotSame('', $targetPath, 'Breadcrumb link "' . $text . '" has invalid href on ' . $context . ' page.');
        }
    }

    private function sendJsonRequestFromBrowser(
        Browser $browser,
        string $method,
        string $url,
        array $payload = []
    ): array {
        $encodedMethod = json_encode(strtoupper($method), JSON_THROW_ON_ERROR);
        $encodedUrl = json_encode($url, JSON_THROW_ON_ERROR);
        $encodedPayload = json_encode($payload, JSON_THROW_ON_ERROR);

        $browser->script(<<<JS
window.__subjectApiDone = false;
window.__subjectApiError = '';
window.__subjectApiResult = null;

(async function () {
    try {
        const method = {$encodedMethod};
        const url = {$encodedUrl};
        const payload = {$encodedPayload};
        const csrf = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || '';

        const options = {
            method,
            credentials: 'same-origin',
            headers: {
                'X-Requested-With': 'XMLHttpRequest',
                'X-CSRF-TOKEN': csrf,
                'Accept': 'application/json',
                'Content-Type': 'application/json',
            },
        };

        if (method !== 'GET' && method !== 'HEAD') {
            options.body = JSON.stringify(payload);
        }

        const response = await fetch(url, options);
        const body = await response.text();
        let json = null;

        try {
            json = body ? JSON.parse(body) : null;
        } catch (_error) {
            json = null;
        }

        window.__subjectApiResult = {
            status: response.status,
            ok: response.ok,
            body,
            json,
        };
    } catch (error) {
        window.__subjectApiError = String(error);
    } finally {
        window.__subjectApiDone = true;
    }
})();
JS);

        $browser->waitUsing(20, 200, function () use ($browser): bool {
            $done = $browser->script('return window.__subjectApiDone === true;');
            return is_array($done) && (($done[0] ?? false) === true);
        }, 'Timed out waiting for browser JSON request to complete.');

        $errorResult = $browser->script('return window.__subjectApiError || "";');
        $error = is_array($errorResult) ? (string) ($errorResult[0] ?? '') : '';
        $this->assertSame('', $error, 'Browser JSON request failed: ' . $error);

        $result = $browser->script('return window.__subjectApiResult || null;');
        $response = is_array($result) ? ($result[0] ?? null) : null;
        $this->assertIsArray($response, 'Unable to capture browser JSON request result.');

        return is_array($response) ? $response : [];
    }

    private function assertActivityIssuedByAdmin(int $subjectId, string $event): void
    {
        $log = ActivityLog::query()
            ->where('subject_type', Subject::class)
            ->where('subject_id', $subjectId)
            ->where('event', $event)
            ->latest('id')
            ->first();

        $this->assertNotNull($log, 'Activity log not found for subject event: ' . $event);
        $this->assertNotNull($this->adminUser, 'Admin user is not resolved for activity verification.');
        $this->assertSame(
            (int) $this->adminUser->id,
            (int) $log->user_id,
            'Issued-by user_id mismatch for subject activity event: ' . $event
        );
    }

    private function createSubjectSeed(string $code, array $overrides = []): Subject
    {
        $code = strtoupper(substr($code, 0, 5));
        if ($code === '') {
            $code = $this->uniqueCode('S');
        }

        $name = isset($overrides['name']) ? (string) $overrides['name'] : $this->uniqueSubjectName('SEED');
        if (strlen($name) > 50) {
            $name = substr($name, 0, 50);
        }

        $shortName = isset($overrides['short_name'])
            ? (string) $overrides['short_name']
            : substr($name, 0, 20);
        $shortName = strtoupper(substr($shortName, 0, 20));

        $ordinal = isset($overrides['ordinal'])
            ? (int) $overrides['ordinal']
            : $this->nextAvailableOrdinal();

        $this->deleteSubjectByCode($code);
        $this->deleteSubjectByName($name);
        $this->deleteSubjectByShortName($shortName);

        $payload = array_merge([
            'name' => $name,
            'ordinal' => $ordinal,
            'short_name' => $shortName,
            'code' => $code,
            'is_active' => true,
        ], $overrides);

        if (isset($payload['code'])) {
            $payload['code'] = strtoupper(substr((string) $payload['code'], 0, 5));
        }
        if (isset($payload['short_name'])) {
            $payload['short_name'] = strtoupper(substr((string) $payload['short_name'], 0, 20));
        }

        return Subject::query()->create($payload);
    }

    private function nextAvailableOrdinal(array $exclude = []): int
    {
        $used = Subject::withTrashed()
            ->pluck('ordinal')
            ->filter(fn ($value) => $value !== null)
            ->map(fn ($value) => (int) $value)
            ->values()
            ->all();

        $blocked = array_values(array_unique(array_map('intval', $exclude)));

        for ($ordinal = 1; $ordinal <= 127; $ordinal++) {
            if (in_array($ordinal, $used, true) || in_array($ordinal, $blocked, true)) {
                continue;
            }

            return $ordinal;
        }

        $this->markTestSkipped('No available subject ordinal found in range 1-127 for test data.');

        return 1;
    }

    private function deleteSubjectByCode(string $code): void
    {
        Subject::withTrashed()
            ->where('code', strtoupper($code))
            ->get()
            ->each(function (Subject $subject): void {
                $subject->forceDelete();
            });
    }

    private function deleteSubjectByName(string $name): void
    {
        Subject::withTrashed()
            ->where('name', $name)
            ->get()
            ->each(function (Subject $subject): void {
                $subject->forceDelete();
            });
    }

    private function deleteSubjectByShortName(string $shortName): void
    {
        Subject::withTrashed()
            ->where('short_name', strtoupper($shortName))
            ->get()
            ->each(function (Subject $subject): void {
                $subject->forceDelete();
            });
    }

    private function forceDeleteSubject(Subject $subject): void
    {
        if (Subject::withTrashed()->whereKey($subject->id)->exists()) {
            $subject->forceDelete();
        }
    }

    private function pageSourceContains(Browser $browser, string $text): bool
    {
        return str_contains($browser->driver->getPageSource(), $text);
    }

    private function authenticate(Browser $browser): void
    {
        $browser->visit($this->tenantUrl('/login'))
            ->pause(700);

        if ($browser->element('input[name="email"]') && $browser->element('input[name="password"]')) {
            $browser->type('email', $this->adminEmail)
                ->type('password', $this->adminPassword)
                ->press('Sign In')
                ->pause(1000);
        }

        if (str_contains($this->currentPath($browser), '/login')) {
            $browser->loginAs($this->adminUser)->pause(550);
        }
    }

    private function visitAuthenticated(Browser $browser, string $path, int $pauseMs = 900): void
    {
        $browser->visit($this->tenantUrl($path))
            ->pause($pauseMs);

        if (str_contains($this->currentPath($browser), '/login')) {
            $this->authenticate($browser);
            $browser->visit($this->tenantUrl($path))
                ->pause($pauseMs);
        }
    }

    private function initializeTenantContext(): void
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

    private function resolveAdminUser(): void
    {
        $this->adminUser = User::query()->where('email', $this->adminEmail)->first();
        if (!$this->adminUser) {
            $this->adminUser = User::query()->first();
        }

        if (!$this->adminUser) {
            $this->markTestSkipped('No tenant user found for Dusk login.');
        }

        if ($this->adminUser->getAttribute('email_verified_at') === null) {
            $this->adminUser->forceFill([
                'email_verified_at' => now(),
            ])->save();
        }

        $this->grantSubjectPermissions($this->adminUser);
    }

    private function grantSubjectPermissions(User $user): void
    {
        $canAssignDirectPermissions = method_exists($user, 'givePermissionTo');
        $canAssignRole = method_exists($user, 'assignRole');

        if (!$canAssignDirectPermissions && !$canAssignRole) {
            return;
        }

        $permissions = [
            'tenant.subject.viewAny',
            'tenant.subject.view',
            'tenant.subject.create',
            'tenant.subject.edit',
            'tenant.subject.update',
            'tenant.subject.delete',
            'tenant.subject.restore',
            'tenant.subject.forceDelete',
            'tenant.subject.status',
            'tenant.subject.trash',
            'tenant.section.viewAny',
            'tenant.subject-type.viewAny',
            'tenant.study-format.viewAny',
            'tenant.subject.viewAny',
            'tenant.subject-study-format.viewAny',
            'tenant.subject-class-mapping.viewAny',
            'tenant.subject-group.viewAny',
        ];

        $guard = $this->permissionGuardName($user);
        $this->ensurePermissionsExist($permissions, $guard);
        $this->syncSubjectRoleWithPermissions($user, $permissions, $guard);

        if ($canAssignDirectPermissions) {
            foreach ($permissions as $permission) {
                try {
                    $user->givePermissionTo($permission);
                } catch (Throwable) {
                    // Ignore permission assignment errors when seed state differs.
                }
            }
        }
    }

    private function ensurePermissionsExist(array $permissions, string $guard): void
    {
        if (!class_exists(\Spatie\Permission\Models\Permission::class)) {
            return;
        }

        foreach ($permissions as $permission) {
            try {
                \Spatie\Permission\Models\Permission::firstOrCreate([
                    'name' => $permission,
                    'guard_name' => $guard,
                ]);
            } catch (Throwable) {
                // Ignore permission creation errors in restricted setups.
            }
        }
    }

    private function syncSubjectRoleWithPermissions(User $user, array $permissions, string $guard): void
    {
        if (!class_exists(\Spatie\Permission\Models\Role::class)) {
            return;
        }

        $roleName = (string) env('DUSK_ADMIN_ROLE', 'tenant.subject-admin');

        try {
            $role = \Spatie\Permission\Models\Role::firstOrCreate([
                'name' => $roleName,
                'guard_name' => $guard,
            ]);
        } catch (Throwable) {
            return;
        }

        try {
            if (method_exists($role, 'syncPermissions')) {
                $role->syncPermissions($permissions);
            } elseif (method_exists($role, 'givePermissionTo')) {
                foreach ($permissions as $permission) {
                    $role->givePermissionTo($permission);
                }
            }
        } catch (Throwable) {
            // Ignore role permission sync issues in restricted setups.
        }

        if (method_exists($user, 'assignRole')) {
            try {
                $user->assignRole($roleName);
            } catch (Throwable) {
                // Ignore role assignment errors when guard/seed state differs.
            }
        }

        $this->forgetPermissionCache();
    }

    private function permissionGuardName(User $user): string
    {
        if (method_exists($user, 'getDefaultGuardName')) {
            try {
                $guard = (string) $user->getDefaultGuardName();
                if ($guard !== '') {
                    return $guard;
                }
            } catch (Throwable) {
                // Fall through to auth config guard.
            }
        }

        return (string) config('auth.defaults.guard', 'web');
    }

    private function forgetPermissionCache(): void
    {
        if (!class_exists(\Spatie\Permission\PermissionRegistrar::class)) {
            return;
        }

        try {
            app(\Spatie\Permission\PermissionRegistrar::class)->forgetCachedPermissions();
        } catch (Throwable) {
            // Ignore cache reset issues in minimal test setups.
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

    private function isIndexPath(string $path): bool
    {
        return $path === self::INDEX_PATH || str_starts_with($path, self::INDEX_PATH . '?');
    }

    private function isTrashPath(string $path): bool
    {
        return $path === self::TRASH_PATH || str_starts_with($path, self::TRASH_PATH . '?');
    }

    private function uniqueSuffix(): string
    {
        return now()->format('His') . random_int(100, 999);
    }

    private function uniqueCode(string $prefix = 'S'): string
    {
        $length = $this->resolveSubjectCodeLength();
        $cleanPrefix = strtoupper((string) preg_replace('/[^A-Za-z]/', '', $prefix));
        $cleanPrefix = substr($cleanPrefix, 0, min(2, $length));
        if ($cleanPrefix === '') {
            $cleanPrefix = 'S';
        }

        $used = Subject::withTrashed()
            ->pluck('code')
            ->map(static fn ($value) => strtoupper((string) $value))
            ->unique()
            ->values()
            ->all();

        for ($attempt = 0; $attempt < 40; $attempt++) {
            $suffixLength = max(0, $length - strlen($cleanPrefix));
            $candidate = $cleanPrefix . $this->randomLetters($suffixLength);
            $candidate = strtoupper(substr($candidate, 0, $length));

            if ($candidate !== '' && !in_array($candidate, $used, true)) {
                return $candidate;
            }
        }

        $this->markTestSkipped('No available subject code for test data.');

        return strtoupper(substr($cleanPrefix . str_repeat('A', max(0, $length - strlen($cleanPrefix))), 0, $length));
    }

    private function randomLetters(int $length): string
    {
        $letters = '';
        for ($i = 0; $i < $length; $i++) {
            $letters .= chr(random_int(65, 90));
        }

        return $letters;
    }

    private function resolveSubjectCodeLength(): int
    {
        static $cached = null;
        if (is_int($cached) && $cached > 0) {
            return $cached;
        }

        $length = 5;
        try {
            $driver = DB::connection()->getDriverName();
            if ($driver === 'mysql') {
                $rows = DB::select("SHOW COLUMNS FROM sch_subjects LIKE 'code'");
                $type = is_array($rows) && isset($rows[0]->Type) ? (string) $rows[0]->Type : '';
                if (preg_match('/\\((\\d+)\\)/', $type, $matches)) {
                    $length = (int) $matches[1];
                }
            }
        } catch (Throwable) {
            // Fallback to migration expectation when schema lookup fails.
        }

        $cached = max(1, min(10, $length));
        return $cached;
    }

    private function uniqueSubjectName(string $prefix): string
    {
        $cleanPrefix = strtoupper((string) preg_replace('/[^A-Za-z0-9]/', '', $prefix));
        $cleanPrefix = substr($cleanPrefix, 0, 12);
        $digits = preg_replace('/\D+/', '', $this->uniqueSuffix());
        $digits = is_string($digits) ? $digits : (string) random_int(1000, 9999);

        return substr($cleanPrefix . $digits, 0, 50);
    }

    private function uniqueShortName(string $prefix): string
    {
        $cleanPrefix = strtoupper((string) preg_replace('/[^A-Za-z0-9]/', '', $prefix));
        $cleanPrefix = substr($cleanPrefix, 0, 8);
        $digits = preg_replace('/\D+/', '', $this->uniqueSuffix());
        $digits = is_string($digits) ? $digits : (string) random_int(1000, 9999);

        return substr($cleanPrefix . $digits, 0, 20);
    }
}
