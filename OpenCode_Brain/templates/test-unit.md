# Template: Unit Test

## Location
`tests/Unit/{Area}/{Class}Test.php`
or
`Modules/{ModuleName}/tests/Unit/{Class}Test.php`

## When to Use
- Testing pure PHP logic (no DB, no HTTP)
- Service methods with business logic
- Helper functions
- Model accessors/mutators/scopes
- Algorithm correctness (timetable solver, fee calculator, etc.)

## Boilerplate

```php
<?php

use Modules\ModuleName\Services\EntityService;
use Modules\ModuleName\Models\Entity;

// Simple assertion test
test('entity service calculates total correctly', function () {
    $service = new EntityService();

    $result = $service->calculateTotal(items: [100, 200, 300]);

    expect($result)->toBe(600);
});

// Test with setup (beforeEach)
describe('EntityService', function () {
    beforeEach(function () {
        $this->service = new EntityService();
    });

    test('returns zero for empty items', function () {
        expect($this->service->calculateTotal([]))->toBe(0);
    });

    test('throws exception for negative values', function () {
        expect(fn() => $this->service->calculateTotal([-100]))
            ->toThrow(\InvalidArgumentException::class, 'Values must be positive');
    });
});

// Data-driven tests
test('fee discount is applied correctly', function (float $amount, float $pct, float $expected) {
    $service = new EntityService();

    expect($service->applyDiscount($amount, $pct))->toBe($expected);
})->with([
    'full discount'    => [1000.0, 100.0, 0.0],
    'half discount'    => [1000.0, 50.0,  500.0],
    'no discount'      => [1000.0, 0.0,   1000.0],
]);

// Helper function test
test('format currency returns INR formatted string', function () {
    expect(formatCurrency(1500))->toBe('₹1,500.00');
});

// Model accessor test (no DB — use make() not create())
test('student full name accessor combines first and last name', function () {
    $student = new \Modules\StudentProfile\Models\Student([
        'first_name' => 'Ravi',
        'last_name'  => 'Sharma',
    ]);

    expect($student->full_name)->toBe('Ravi Sharma');
});
```

## Notes
- Unit tests do NOT use `RefreshDatabase` — no DB interaction
- Use `new Model([...])` or `Model::make([...])` instead of `Model::create([...])`
- No `$this->actingAs()` needed
- No HTTP calls — test the class/function directly
- Fast: aim for < 10ms per test
