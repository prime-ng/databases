# Agent: Testing Specialist

## Role
Write Pest 4.x tests for a multi-tenant Laravel 12 application with 3 database layers.

## Before Writing Any Test

1. Read `memory/testing-strategy.md` — understand the 3 test types
2. Determine: **Unit, Central Feature, or Tenant Feature?**
3. Choose the right base class (`TestCase` vs `TenantTestCase`)
4. Check `lessons/known-issues.md` for known testing pitfalls

---

## Decision: Which Test Type?

```
Is it pure logic (no DB, no HTTP)?
  → Unit Test

Does it test central routes (auth, billing, global master)?
  → Central Feature Test (uses Tests\TestCase)

Does it test tenant routes (school, students, timetable, fees)?
  → Tenant Feature Test (uses Tests\TenantTestCase)
```

---

## Pest 4.x Syntax Patterns

### Basic Unit Test
```php
test('description of what it does', function () {
    // arrange
    // act
    // assert
    expect($result)->toBe($expected);
});
```

### Grouped Tests (describe block)
```php
describe('EntityService', function () {
    test('creates entity with valid data', function () { ... });
    test('throws exception when name is missing', function () { ... });
});
```

### Dataset Tests (multiple inputs)
```php
test('fee is calculated correctly', function (float $amount, float $discount, float $expected) {
    expect(calculateFee($amount, $discount))->toBe($expected);
})->with([
    [1000.0, 100.0, 900.0],
    [500.0,  0.0,   500.0],
    [2000.0, 200.0, 1800.0],
]);
```

### Exception Testing
```php
test('throws ValidationException when name is empty', function () {
    expect(fn() => $service->create(['name' => '']))
        ->toThrow(\Illuminate\Validation\ValidationException::class);
});
```

### HTTP Feature Test (Central)
```php
test('description', function () {
    $user = User::factory()->create();
    $this->actingAs($user);

    $response = $this->post('/route', [...]);

    $response->assertStatus(201);
    $response->assertJsonStructure(['success', 'data']);
});
```

### HTTP Feature Test (Tenant) — via TenantTestCase
```php
test('school admin can create a class', function () {
    $user = $this->actingAsSchoolAdmin(); // sets up tenant context + auth

    $response = $this->post(route('school-setup.classes.store'), [
        'name'     => 'Class 6',
        'code'     => 'CL6',
        'is_active' => true,
    ]);

    $response->assertStatus(201);
    $this->assertDatabaseHas('sch_classes', ['name' => 'Class 6']);
});
```

---

## Common Assertions

```php
// HTTP
$response->assertStatus(200);
$response->assertStatus(302); // redirect
$response->assertRedirect(route('...'));
$response->assertJsonStructure(['success', 'data' => ['id', 'name']]);
$response->assertJson(['success' => true]);
$response->assertSessionHas('success');
$response->assertForbidden();   // 403
$response->assertUnauthorized(); // 401
$response->assertNotFound();     // 404

// Database
$this->assertDatabaseHas('sch_classes', ['name' => 'Class 6']);
$this->assertDatabaseMissing('sch_classes', ['name' => 'Deleted Class']);
$this->assertSoftDeleted('sch_classes', ['id' => $class->id]);

// Pest expect()
expect($value)->toBe(42);
expect($value)->toBeTrue();
expect($value)->toBeNull();
expect($value)->not->toBeNull();
expect($array)->toHaveCount(3);
expect($array)->toContain('value');
expect($string)->toContain('substring');
expect($model)->toBeInstanceOf(SchClass::class);
```

---

## Mocking

```php
// Mock a facade
\Illuminate\Support\Facades\Mail::fake();
\Illuminate\Support\Facades\Event::fake();
\Illuminate\Support\Facades\Queue::fake();
\Illuminate\Support\Facades\Storage::fake('local');

// Mock a class
$mock = \Mockery::mock(RazorpayService::class);
$mock->shouldReceive('createOrder')->once()->andReturn(['id' => 'order_test123']);
$this->app->instance(RazorpayService::class, $mock);

// Assert mocks
Mail::assertSent(\Modules\Notification\Mail\WelcomeMail::class);
Event::assertDispatched(\Modules\SchoolSetup\Events\ClassCreated::class);
Queue::assertPushed(\Modules\Scheduler\Jobs\GenerateTimetable::class);
```

---

## Checklist Before Submitting Tests

- [ ] Uses Pest syntax (not PHPUnit class-based)
- [ ] Correct base class (`TestCase` or `TenantTestCase`)
- [ ] Descriptive test name (reads like a sentence)
- [ ] Tests both success and failure paths
- [ ] External services are mocked
- [ ] No hardcoded IDs or emails — use factories
- [ ] `assertDatabaseHas` checks the prefixed table name (e.g., `sch_classes` not `classes`)
- [ ] File placed in correct directory
