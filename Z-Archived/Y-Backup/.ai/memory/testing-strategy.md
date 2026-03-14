# Testing Strategy — Prime-AI

## Overview

Prime-AI is a **multi-tenant, 3-database Laravel application**. Testing requires a deliberate
strategy because:
- SQLite in-memory **cannot** replicate 3 separate MySQL database connections
- Tenant context must be explicitly initialized for tenant-scoped tests
- Module code lives in `Modules/` — test suites must cover those too

---

## Test Types & When to Use Each

### 1. Unit Tests (`tests/Unit/` or `Modules/*/tests/Unit/`)
- **What:** Pure logic — no HTTP, no database, no tenancy
- **When:** Services with business logic, helpers, algorithms, value objects, model methods
- **Database:** None (mock or fake data)
- **Tenancy:** Not required
- **Speed:** Very fast
- **Examples:**
  - Timetable conflict detection logic
  - Fee calculation logic
  - Helper functions (`formatCurrency()`, `academicYear()`)
  - Model attribute accessors/mutators

### 2. Central Feature Tests (`tests/Feature/`)
- **What:** HTTP tests for central-scoped routes (prime_db / global_db)
- **When:** Auth, tenant management, billing, global master CRUD
- **Database:** Uses `prime_db_test` and `global_db_test` (MySQL)
- **Tenancy:** Not required — central routes only
- **Base class:** `Tests\TestCase` (extends `CentralTestCase`)
- **Examples:**
  - Login/logout flow
  - Creating a tenant (school)
  - Board/language/country CRUD
  - Billing invoice generation

### 3. Tenant Feature Tests (`Modules/*/tests/Feature/`)
- **What:** HTTP tests for tenant-scoped routes
- **When:** School setup, students, timetable, fees, exams
- **Database:** Uses a dedicated `tenant_test_db` (MySQL)
- **Tenancy:** MUST initialize a test tenant before each test
- **Base class:** `Tests\TenantTestCase`
- **Examples:**
  - Creating a class/section
  - Enrolling a student
  - Generating a timetable
  - Paying a fee

---

## Test Database Architecture

```
phpunit.xml              → overrides connections for testing
.env.testing             → test DB credentials

Connections used in tests:
  default  → prime_test     (prm_* tables)
  global   → global_test    (glb_* tables)
  tenant   → (dynamically set by tenancy bootstrapper per test)
```

### Required test databases
```sql
CREATE DATABASE prime_test   CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE global_test  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- Tenant test DB is created dynamically by TenantTestCase
```

---

## Base Test Classes

### `Tests\TestCase` (Central)
- `RefreshDatabase` on `prime_test` and `global_test`
- Provides `actingAsCentralAdmin()`, `actingAsCentralUser()` helpers

### `Tests\TenantTestCase` (Tenant)
- Extends `Tests\TestCase`
- Creates a test tenant before each test, initializes tenancy
- Tears down tenant DB after each test
- Provides `actingAsSchoolAdmin()`, `actingAsTeacher()`, `actingAsStudent()` helpers

---

## Priority Order (What to Test First)

```
Priority 1 — Core Auth & Access
  [ ] Login / logout
  [ ] Role-based access control (middleware guards)
  [ ] Unauthorized access returns 403

Priority 2 — Central CRUD (GlobalMaster)
  [ ] Board CRUD
  [ ] Country/State CRUD

Priority 3 — School Setup (Tenant)
  [ ] Organization creation
  [ ] Class + Section creation
  [ ] Subject assignment

Priority 4 — Student Management (Tenant)
  [ ] Student enrollment
  [ ] Student profile update

Priority 5 — Fee System (Tenant)
  [ ] Invoice generation
  [ ] Payment recording

Priority 6 — Timetable (Tenant — most complex)
  [ ] Activity creation
  [ ] Constraint validation
  [ ] Generation run

Priority 7 — LMS (Tenant)
  [ ] Exam creation
  [ ] Quiz submission
  [ ] Homework submission
```

---

## Naming Conventions

| Test Type | File Location | Naming |
|-----------|--------------|--------|
| Unit | `tests/Unit/` or `Modules/*/tests/Unit/` | `{Class}Test.php` |
| Central Feature | `tests/Feature/{Module}/` | `{Feature}Test.php` |
| Tenant Feature | `Modules/{Module}/tests/Feature/` | `{Feature}Test.php` |

---

## Key Rules

1. **Never run tests against real databases** — always use `*_test` databases
2. **Never hardcode test user emails** — use factories
3. **Always use `RefreshDatabase`** for Feature tests
4. **Tenant tests must clean up** — TenantTestCase handles this automatically
5. **Test one behavior per test** — one `test()` block = one assertion scenario
6. **Use descriptive test names** — `'school admin can create a class'` not `'test create'`
7. **Mock external services** — Razorpay, email, SMS must be mocked
8. **Test both happy path AND failure cases** — success + validation errors + authorization
