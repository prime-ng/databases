---
globs: ["tests/**", "phpunit.xml", "Modules/*/tests/**"]
---

# Testing Rules

## Framework
- Pest 4.x (NOT PHPUnit class-based syntax)
- Use `it()` or `test()` syntax

## 3 Test Types
1. **Unit Tests** (`tests/Unit/` or `Modules/*/tests/Unit/`) — No DB, no HTTP, no tenancy
2. **Central Feature Tests** (`tests/Feature/`) — Uses `Tests\TestCase`, `RefreshDatabase`
3. **Tenant Feature Tests** (`Modules/*/tests/Feature/`) — Uses `Tests\TenantTestCase`, requires tenant init

## Key Rules
- Always use Pest syntax, not PHPUnit classes
- Descriptive test names: `'school admin can create a class'` not `'test create'`
- Table names in assertions must include prefix: `sch_classes` not `classes`
- Mock external services: Razorpay, email, SMS
- Test both success AND failure paths
- No hardcoded IDs or emails — use factories

## Run Commands
```bash
./vendor/bin/pest                           # All tests
./vendor/bin/pest tests/Unit/               # Unit only
./vendor/bin/pest --filter="student"        # By keyword
./vendor/bin/pest Modules/SmartTimetable/   # Module tests
```

## Known Issues
- First Feature test run is slow (~50s) — SQLite cold start running 29 module migrations
- Spatie MediaLibrary PHP 8.4 deprecation warning on models with `InteractsWithMedia`
