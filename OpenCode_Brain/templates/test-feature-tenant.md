# Template: Tenant Feature Test

## Location
`Modules/{ModuleName}/tests/Feature/{Feature}Test.php`

## When to Use
- Testing tenant-scoped routes (school setup, students, timetable, fees, exams)
- Routes in `routes/tenant.php` or module tenant routes
- Requires tenant initialization before each test

## Setup Required
Must use `Tests\TenantTestCase` as the base class.
`TenantTestCase` automatically:
- Creates a test tenant before each test
- Initializes tenancy context (switches to tenant DB)
- Tears down the tenant DB after each test

## Boilerplate

```php
<?php

use Tests\TenantTestCase;
use Modules\SchoolSetup\Models\SchClass;

// Configure this test file to use TenantTestCase
uses(TenantTestCase::class);

// Test: authenticated school admin can create a class
test('school admin can create a class', function () {
    $user = $this->actingAsSchoolAdmin();

    $response = $this->post(route('school-setup.classes.store'), [
        'name'     => 'Class 6',
        'code'     => 'CL6',
        'is_active' => true,
    ]);

    $response->assertRedirect();
    $this->assertDatabaseHas('sch_classes', ['name' => 'Class 6', 'code' => 'CL6']);
});

// Test: validation failure
test('class creation fails with duplicate code', function () {
    $this->actingAsSchoolAdmin();
    SchClass::factory()->create(['code' => 'CL6']);

    $response = $this->post(route('school-setup.classes.store'), [
        'name' => 'Class 6 Duplicate',
        'code' => 'CL6',
    ]);

    $response->assertSessionHasErrors(['code']);
});

// Test: authorization
test('teacher cannot create a class', function () {
    $this->actingAsTeacher();

    $response = $this->post(route('school-setup.classes.store'), [
        'name' => 'Class 7',
        'code' => 'CL7',
    ]);

    $response->assertForbidden();
});

// Test: soft delete and restore
test('school admin can delete and restore a class', function () {
    $this->actingAsSchoolAdmin();
    $class = SchClass::factory()->create();

    // Delete
    $this->delete(route('school-setup.classes.destroy', $class))
         ->assertRedirect();
    $this->assertSoftDeleted('sch_classes', ['id' => $class->id]);

    // Restore
    $this->post(route('school-setup.classes.restore', $class->id))
         ->assertRedirect();
    $this->assertDatabaseHas('sch_classes', ['id' => $class->id, 'deleted_at' => null]);
});

// Test: API endpoint (JSON)
test('API returns class list for tenant', function () {
    $this->actingAsSchoolAdmin();
    SchClass::factory()->count(3)->create();

    $response = $this->getJson(route('api.school-setup.classes.index'));

    $response->assertStatus(200)
             ->assertJsonCount(3, 'data')
             ->assertJsonStructure([
                 'success',
                 'data' => [['id', 'name', 'code', 'is_active']],
             ]);
});
```

## TenantTestCase Helper Methods

```php
$this->actingAsSchoolAdmin()   // Creates + authenticates a user with SchoolAdmin role
$this->actingAsPrincipal()     // Creates + authenticates a user with Principal role
$this->actingAsTeacher()       // Creates + authenticates a user with Teacher role
$this->actingAsAccountant()    // Creates + authenticates a user with Accountant role
$this->actingAsStudent()       // Creates + authenticates a student user
$this->testTenant              // The test Tenant model instance
```

## Notes
- All DB assertions run against tenant DB (tenancy is initialized)
- Table names use module prefixes: `sch_classes`, `std_students`, `tt_activities`
- `RefreshDatabase` runs on the tenant DB (not prime_db)
- External services (Razorpay, SMS, email) must be mocked
- Never test against production/real tenant DBs
