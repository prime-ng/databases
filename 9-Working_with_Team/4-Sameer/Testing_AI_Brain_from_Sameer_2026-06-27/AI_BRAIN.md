# AI_BRAIN.md — Prime Testing A-to-Z Gold Standard

> **Purpose:** Complete reference for building Dusk browser test suites across all Prime-AI modules. Every rule, pattern, helper, and workflow we follow.

---

## Table of Contents

1. [What We Build](#1-what-wewe-build)
2. [Source Analysis — Before Writing Tests](#2-source-analysis--before-writing-tests)
3. [Folder Structure](#3-folder-structure)
4. [File Naming Conventions](#4-file-naming-conventions)
5. [Per-Feature Files (4 vs 3)](#5-per-feature-files-4-vs-3)
6. [Test File Anatomy — Full Template](#6-test-file-anatomy--full-template)
7. [Helper Methods — Complete Reference](#7-helper-methods--complete-reference)
8. [Unique Suffix Generation](#8-unique-suffix-generation)
9. [Test Categories](#9-test-categories)
10. [DDL Verification — Full SQL Reference](#10-ddl-verification--full-sql-reference)
11. [Browser Test Patterns](#11-browser-test-patterns)
12. [Security Test Patterns](#12-security-test-patterns)
13. [Child Table Interaction Tests](#13-child-table-interaction-tests)
14. [Tab Navigation Tests](#14-tab-navigation-tests)
15. [TcList_Require.md — Full Template](#15-tclist_requiremd--full-template)
16. [MANUALTESTING_Require.md — Full Template](#16-manualtesting_requiremd--full-template)
17. [GapAnalysis_Require.md — Template](#17-gapanalysis_requiremd--template)
18. [FRD Business Rules Mapping](#18-frd-business-rules-mapping)
19. [Development Issues Documentation](#19-development-issues-documentation)
20. [V1/V2 Management Rules](#20-v1v2-management-rules)
21. [Modules Completed Reference](#21-modules-completed-reference)
22. [Common Pitfalls to Avoid](#22-common-pitfalls-to-avoid)

---

## 1. What We Build

We build Dusk browser test suites for **Prime-AI ERP modules**. Each module has sub-menu tabs, and each tab has features. We test:

- **DDL verification** — Column types, ENUMs, indexes, FKs via `information_schema`
- **Positive CRUD** — Create, show, edit, update, toggle-status, search, filter
- **Negative/Validation** — Required fields, duplicates, max-length, invalid ENUMs, invalid FKs
- **Security** — Guest redirect, 403 Forbidden, 404 Not Found for all endpoints
- **Dependencies** — FK RESTRICT/CASCADE/SET NULL behavior, soft-delete lifecycle
- **Child tables** — Add/remove rows, submit with relations, sync on edit
- **FRD business rules** — Map 24 BRs to test coverage, document gaps

### Core Constraints
| Rule | Description |
|------|-------------|
| **No source changes** | Never modify `pgdatabase/` or `prime_ai/` — only `prime_testing/` |
| **Flat folder** | Each feature = one folder, all files directly inside (no sub-nesting) |
| **Read-only source** | Source code is for analysis only. Bugs found = document as Dev Issue |
| **DDL verification** | Always verify column types via `information_schema`, never trust migration alone |

---

## 2. Source Analysis — Before Writing Tests

Before writing ANY test, you MUST read (in order):

### Step 1: DDL File
Path: `C:\laragon\www\pgdatabase\2-DDL_Tenant_Consolidated\{Module}_ddl_v*.sql`

What to extract:
- All column names, types, nullable, defaults
- ENUM value lists
- UNIQUE indexes (composite or single)
- FOREIGN KEY definitions + ON DELETE rules
- Any CHECK constraints
- Seed data (INSERT statements)

### Step 2: Model File
Path: `C:\laragon\www\prime_ai\Modules\{Module}\app\Models\{Model}.php`

What to verify:
- `$table` name
- `$fillable` / `$guarded`
- `$casts` (especially boolean, ENUM, JSON)
- SoftDeletes trait
- Relationships (BelongsTo, HasMany, etc.)
- Custom accessors/mutators
- Static helper methods (`getIdByCode`, `clearIdCache`, etc.)

### Step 3: FormRequest File
Path: `C:\laragon\www\prime_ai\Modules\{Module}\app\Http\Requests\{Request}.php`

What to verify:
- `authorize()` — permission check
- `rules()` — all validation rules (required, unique, max, exists, enum, etc.)
- Custom validation methods

### Step 4: Controller File
Path: `C:\laragon\www\prime_ai\Modules\{Module}\app\Http\Controllers\{Controller}.php`

What to verify:
- All public methods exist (index, create, store, show, edit, update, destroy, toggleStatus, trashed, restore, forceDelete)
- Any missing methods = Dev Issue
- Redirect URLs (especially tab anchor params like `?tab=exam`)
- Permission checks

### Step 5: Policy File
Path: `C:\laragon\www\prime_ai\Modules\{Module}\app\Policies\{Policy}.php`

What to verify:
- All gate methods exist (viewAny, view, create, update, delete, restore, forceDelete, status)
- Permission string matches blade views
- Any typos in permission names = Dev Issue

### Step 6: Blade View Files
Path: `C:\laragon\www\prime_ai\Modules\{Module}\Resources\views\`

What to verify:
- Create form fields (name, type, required)
- Edit form fields
- Show page fields
- Tab structure
- Permission checks in blade (`@can`)

### Step 7: Routes File
Path: `C:\laragon\www\prime_ai\Modules\{Module}\routes\web.php`

What to verify:
- All resource routes
- Custom routes (toggle-status, restore, forceDelete, AJAX endpoints)
- Route names

### Step 8: FRD / Conditions File
Path: `C:\laragon\www\prime_testing\Doc_Analysis\5-FRD_Reports\{Module}_FRD_v*.md`

What to extract:
- All business rules (BR-xxx-xxx)
- Acceptance criteria
- Workflow rules
- Report specifications

---

## 3. Folder Structure

```
prime_testing/
├── tests/Browser/Modules/
│   ├── Library/
│   │   ├── Lib{Feature1}/
│   │   │   ├── TcList_Require.md
│   │   │   ├── MANUALTESTING_Require.md
│   │   │   ├── GapAnalysis_Require.md       [only if V1 exists]
│   │   │   ├── lib_Lib{Feature}_TestCas.php  [V1 if exists, or single comprehensive]
│   │   │   └── lib_Lib{Feature}_V2_TestCas.php [V2 if V1 exists]
│   │   └── Lib{Feature2}/
│   │       └── ...
│   ├── Complaint/
│   │   ├── Cmp{Feature1}/
│   │   │   └── ...
│   │   └── Cmp{Feature2}/
│   │       └── ...
│   ├── QuestionBank/
│   ├── LmsExam/
│   └── Hpc/
├── Doc_Analysis/
│   ├── 1-Module_DDLs/        [DDL sql files]
│   ├── 4-Module_Requirement/  [BRD documents]
│   ├── 5-FRD_Reports/         [FRD documents]
│   └── 5-Audit_Report/        [Technical audits]
└── AI_BRAIN.md                [this file]
```

### Feature Folder — Allowed Files Only

| File | Required? | Notes |
|------|-----------|-------|
| `TcList_Require.md` | ✅ Always | Full test case mapping |
| `MANUALTESTING_Require.md` | ✅ Always | Manual test steps |
| `GapAnalysis_Require.md` | Only if V1 exists | Documents gaps V2 fills |
| `{Prefix}_{Feature}_TestCas.php` | ✅ Always | V1 (if pre-exists) OR single comprehensive |
| `{Prefix}_{Feature}_V2_TestCas.php` | Only if V1 exists | Gold Standard additions |

**NO other files allowed** — no auto-generated reports, no dusk-report folders, no stray markdown.

---

## 4. File Naming Conventions

| Module | Prefix | V1 File | V2 File (if V1 exists) |
|--------|--------|---------|----------------------|
| HPC | `hpc_` | `hpc_{Feature}_TestCas.php` | `hpc_{Feature}_V2_TestCas.php` |
| QuestionBank | `qbn_` | `qbn_{Feature}_TestCas.php` | `qbn_{Feature}_V2_TestCas.php` |
| Library | `lib_Lib` | `lib_Lib{Feature}_TestCas.php` | `lib_Lib{Feature}_V2_TestCas.php` |
| LmsExam | `lms_` | `lms_{Feature}_TestCas.php` | (no V2 for LmsExam) |
| Complaint | `cmp_` | `cmp_{Feature}_TestCas.php` | `cmp_{Feature}_V2_TestCas.php` |

### Class Name = File Name
```
File: cmp_ComplaintCategory_V2_TestCas.php
Class: cmp_ComplaintCategory_V2_TestCas extends DuskTestCase
```

### Namespace Convention
```
V1 files moved from Testcases/:
  Tests\Browser\Modules\Complaint\CmpCategory

New V2 files:
  Tests\Browser\Modules\Complaint\CmpCategory
```

---

## 5. Per-Feature Files (4 vs 3)

### Scenario A: V1 Pre-Exists (old Testcases/ folder)

```
CmpCategory/
├── TcList_Require.md           ← Combined V1 + V2 TC list
├── MANUALTESTING_Require.md    ← Manual steps for all TCs
├── GapAnalysis_Require.md      ← What V2 adds beyond V1
├── cmp_ComplaintCategoryCrud_TestCas.php   ← V1 (moved from Testcases/, namespace updated)
└── cmp_ComplaintCategory_V2_TestCas.php    ← V2 (new, Gold Standard)
```

### Scenario B: No V1 (new feature)

```
CmpDashboard/
├── TcList_Require.md           ← Full TC list
├── MANUALTESTING_Require.md    ← Manual steps
└── cmp_ComplaintDashboard_TestCas.php   ← Single comprehensive file
```

---

## 6. Test File Anatomy — Full Template

```php
<?php

namespace Tests\Browser\Modules\{Module}\{FeatureFolder};

use App\Models\User;
use Laravel\Dusk\Browser;
use Modules\Prime\Models\Domain;
use Tests\DuskTestCase;
use Throwable;

class {Prefix}_{Feature}_V2_TestCas extends DuskTestCase
{
    // 1. CONSTANTS
    private const BASE_PATH = '/module/feature';
    private const TAB_PARAM = '?tab=feature-tab';
    private const PERMISSION = 'tenant.feature.*';
    private const SUFFIX = ''; // Will be set in setUp

    // 2. STATE
    private ?User $adminUser = null;
    private string $tenantBaseUrl = '';
    private string $adminEmail = '';
    private string $adminPassword = '';

    // 3. SETUP
    protected function setUp(): void
    {
        parent::setUp();
        $this->tenantBaseUrl = rtrim(env('DUSK_TENANT_URL', env('APP_URL', 'http://test.localhost:8000')), '/');
        $this->adminEmail = (string) env('DUSK_ADMIN_EMAIL', 'root@tenant.com');
        $this->adminPassword = (string) env('DUSK_ADMIN_PASSWORD', 'password');
        $this->initializeTenantContext();
        $this->resolveAdminUser();
        self::SUFFIX = now()->format('His') . random_int(100, 999);
    }

    protected function tearDown(): void
    {
        if (function_exists('tenancy') && tenancy()->initialized) { tenancy()->end(); }
        parent::tearDown();
    }

    // 4. DDL TESTS
    public function test_TC_XXX_P01_ddl_schema_verified(): void { /* ... */ }
    public function test_TC_XXX_P02_unique_and_foreign_keys_verified(): void { /* ... */ }

    // 5. POSITIVE TESTS
    public function test_TC_XXX_P03_tab_pane_renders(): void { /* ... */ }
    public function test_TC_XXX_P04_create_page_loads(): void { /* ... */ }
    public function test_TC_XXX_P05_create_submission(): void { /* ... */ }
    public function test_TC_XXX_P06_show_page_loads(): void { /* ... */ }
    public function test_TC_XXX_P07_update_record(): void { /* ... */ }
    public function test_TC_XXX_P08_update_without_changes(): void { /* ... */ }

    // 6. SEARCH/FILTER TESTS
    public function test_TC_XXX_P09_search_by_name(): void { /* ... */ }
    public function test_TC_XXX_P10_filter_by_status(): void { /* ... */ }

    // 7. TOGGLE STATUS
    public function test_TC_XXX_P11_toggle_status_works(): void { /* ... */ }

    // 8. SOFT-DELETE LIFECYCLE
    public function test_TC_XXX_P12_soft_delete_lifecycle(): void { /* ... */ }
    public function test_TC_XXX_P13_empty_trash(): void { /* ... */ }

    // 9. NEGATIVE TESTS
    public function test_TC_XXX_N01_required_validation(): void { /* ... */ }
    public function test_TC_XXX_N02_duplicate_rejected(): void { /* ... */ }
    public function test_TC_XXX_N03_show_non_existent_returns_404(): void { /* ... */ }
    public function test_TC_XXX_N04_edit_non_existent_returns_404(): void { /* ... */ }
    public function test_TC_XXX_N05_update_non_existent_returns_404(): void { /* ... */ }
    public function test_TC_XXX_N06_destroy_non_existent_returns_404(): void { /* ... */ }
    public function test_TC_XXX_N07_toggle_non_existent_returns_404(): void { /* ... */ }
    public function test_TC_XXX_N08_restore_non_existent_returns_404(): void { /* ... */ }
    public function test_TC_XXX_N09_force_delete_non_existent_returns_404(): void { /* ... */ }
    public function test_TC_XXX_N10_guest_redirect(): void { /* ... */ }
    public function test_TC_XXX_N11_403_without_permission(): void { /* ... */ }

    // 10. DEPENDENCY TESTS
    public function test_TC_XXX_D01_fk_restrict_blocks_deletion(): void { /* ... */ }
    public function test_TC_XXX_D02_fk_cascade_deletes_children(): void { /* ... */ }

    // 11. HELPERS
    private function authenticate(Browser $browser): void { /* ... */ }
    private function visitAuthenticated(Browser $browser, string $path, int $pauseMs = 900): void { /* ... */ }
    private function initializeTenantContext(): void { /* ... */ }
    private function resolveAdminUser(): void { /* ... */ }
    private function createRecordDirectly(array $data = []): int { /* ... */ }
    private function forceDeleteRecordByIdIfExists(int $id): void { /* ... */ }
    private function resolveDependenciesOrSkip(): void { /* ... */ }
    private function tenantUrl(string $path): string { /* ... */ }
    private function currentPath(Browser $browser): string { /* ... */ }
}
```

---

## 7. Helper Methods — Complete Reference

### setUp() — Standard Initialization
```php
protected function setUp(): void
{
    parent::setUp();
    $this->tenantBaseUrl = rtrim(env('DUSK_TENANT_URL', env('APP_URL', 'http://test.localhost:8000')), '/');
    $this->adminEmail = (string) env('DUSK_ADMIN_EMAIL', 'root@tenant.com');
    $this->adminPassword = (string) env('DUSK_ADMIN_PASSWORD', 'password');
    $this->initializeTenantContext();
    $this->resolveAdminUser();
}
```

### tearDown() — Cleanup
```php
protected function tearDown(): void
{
    if (function_exists('tenancy') && tenancy()->initialized) { tenancy()->end(); }
    parent::tearDown();
}
```

### authenticate() — Login via UI + fallback
```php
private function authenticate(Browser $browser): void
{
    $browser->visit($this->tenantUrl('/login'))->pause(800);
    if ($browser->element('input[name="email"]') && $browser->element('input[name="password"]')) {
        $browser->type('email', $this->adminEmail)
                ->type('password', $this->adminPassword)
                ->press('Sign In')
                ->pause(1400);
    }
    if (str_contains($this->currentPath($browser), '/login')) {
        $browser->loginAs($this->adminUser)->pause(600);
    }
}
```

### visitAuthenticated() — Visit with retry
```php
private function visitAuthenticated(Browser $browser, string $path, int $pauseMs = 900): void
{
    $browser->visit($this->tenantUrl($path))->pause($pauseMs);
    if (str_contains($this->currentPath($browser), '/login')) {
        $this->authenticate($browser);
        $browser->visit($this->tenantUrl($path))->pause($pauseMs);
    }
}
```

### initializeTenantContext()
```php
private function initializeTenantContext(): void
{
    $tenantHost = parse_url($this->tenantBaseUrl, PHP_URL_HOST);
    if (!is_string($tenantHost) || $tenantHost === '') { $this->markTestSkipped('Tenant host missing.'); }
    $domain = Domain::query()->where('domain', $tenantHost)->first();
    if (!$domain) { $this->markTestSkipped('Tenant domain not found.'); }
    if (function_exists('tenancy')) { tenancy()->initialize($domain->tenant); }
}
```

### resolveAdminUser()
```php
private function resolveAdminUser(): void
{
    $this->adminUser = User::query()->where('email', $this->adminEmail)->first()
        ?? User::query()->first();
    if (!$this->adminUser) { $this->markTestSkipped('No tenant user found.'); }
}
```

### tenantUrl() / currentPath()
```php
private function tenantUrl(string $path): string
{
    return $this->tenantBaseUrl . '/' . ltrim($path, '/');
}

private function currentPath(Browser $browser): string
{
    $p = parse_url($browser->driver->getCurrentURL(), PHP_URL_PATH);
    return is_string($p) ? $p : '';
}
```

### createRecordDirectly()
```php
private function createRecordDirectly(array $data = []): int
{
    $unique = self::SUFFIX;
    return DB::table('table_name')->insertGetId(array_merge([
        'name' => "Test $unique",
        'code' => "TST$unique",
        'is_active' => 1,
    ], $data));
}
```

### forceDeleteRecordByIdIfExists()
```php
private function forceDeleteRecordByIdIfExists(int $id): void
{
    if ($id && DB::table('table_name')->where('id', $id)->exists()) {
        DB::table('table_name')->where('id', $id)->delete();
    }
}
```

### resolveDependenciesOrSkip()
For features with FK dependencies (category, parent records, etc.):
```php
private function resolveDependenciesOrSkip(): void
{
    // Create or resolve parent category
    $this->parentCategoryId = DB::table('cmp_complaint_categories')
        ->insertGetId(['name' => 'Parent ' . self::SUFFIX, 'code' => 'PAR' . self::SUFFIX]);

    // Create or resolve dropdown values
    $this->statusId = DB::table('sys_dropdowns')
        ->where('value', 'Open')->value('id') ?? ...;

    // Create or resolve user
    $this->userId = User::factory()->create()->id;
}
```

---

## 8. Unique Suffix Generation

```php
// At class level or in setUp:
private static string $suffix = '';

protected function setUp(): void
{
    parent::setUp();
    // ...
    self::$suffix = now()->format('His') . random_int(100, 999);
}
```

### Usage in tests:
```php
$name = 'Test Name ' . self::$suffix;
$code = 'CODE' . self::$suffix;
$email = 'user' . self::$suffix . '@test.com';
```

### Why this pattern:
- `His` = Hour + Minute + Second (6 digits, e.g. `143526`)
- `random_int(100, 999)` = 3 random digits
- Total uniqueness: 9+ characters, unique per test run
- Avoids collisions across parallel test runs

---

## 9. Test Categories

| Category | Prefix | Description | Count Target |
|----------|--------|-------------|--------------|
| **DDL/Schema** | `P01-P03` | info_schema verification of columns, ENUMs, indexes, FKs | 2-3 |
| **Positive CRUD** | `P04-Pxx` | Create, show, edit, update, toggle, search, filter | 5-10 |
| **Soft-delete lifecycle** | `Pxx` | Destroy, trash, restore, force-delete, empty trash | 3-5 |
| **Validation/Negative** | `N01-Nxx` | Required, duplicate, max-length, invalid FK, invalid ENUM | 6-12 |
| **404 Security** | `Nxx` | 404 for all endpoints (show/edit/update/destroy/toggle/restore/forceDelete) | 5-7 |
| **Auth Security** | `Nxx` | Guest redirect, 403 Forbidden | 2 |
| **Dependency** | `D01-Dxx` | FK RESTRICT, FK CASCADE, FK SET NULL | 1-3 |
| **FRD Business Rules** | (in TcList) | Map BRs to test coverage | varies |

### Test Method ID Convention
```
TC-{FEATURE}-{TYPE}-{NUMBER}
Example: TC-CAT-P01, TC-CAT-N03, TC-CAT-D01
```

---

## 10. DDL Verification — Full SQL Reference

### Get Schema Name
```php
$schema = DB::select("SELECT DATABASE() as db")[0]->db;
```

### Column Info
```php
$col = DB::select("SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLUMN_DEFAULT,
    CHARACTER_MAXIMUM_LENGTH, NUMERIC_PRECISION, NUMERIC_SCALE,
    DATA_TYPE
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ? AND COLUMN_NAME = ?",
[$schema, $tableName, $columnName]);
```

### ENUM Values
```php
// COLUMN_TYPE returns like "enum('Value1','Value2','Value3')"
$this->assertStringContainsString("'Value1','Value2'", $col->COLUMN_TYPE);

// Or extract all values:
preg_match_all("/'([^']+)'/", $col->COLUMN_TYPE, $matches);
$enumValues = $matches[1];
$this->assertEquals(['Value1', 'Value2', 'Value3'], $enumValues);
```

### FK DELETE_RULE
```php
$fk = DB::select("SELECT DELETE_RULE, UPDATE_RULE
FROM information_schema.REFERENTIAL_CONSTRAINTS
WHERE CONSTRAINT_SCHEMA = ? AND TABLE_NAME = ? AND CONSTRAINT_NAME = ?",
[$schema, $tableName, $fkName]);
$this->assertEquals('RESTRICT', $fk[0]->DELETE_RULE); // or CASCADE, SET NULL
```

### UNIQUE Indexes
```php
$indexes = DB::select("SHOW INDEX FROM `$tableName` WHERE NON_UNIQUE = 0 AND Key_name != 'PRIMARY'");
$this->assertCount(1, $indexes);
$this->assertEquals('uq_column_name', $indexes[0]->Key_name);
```

### DECIMAL Precision
```php
$this->assertEquals(10, $col->NUMERIC_PRECISION);
$this->assertEquals(2, $col->NUMERIC_SCALE);
```

### TINYINT Default
```php
// COLUMN_DEFAULT may return null for no default, or '0', '1'
$this->assertEquals('1', $col->COLUMN_DEFAULT);
```

### Multiple Column Verification (batch)
```php
$columns = DB::select("SELECT COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE, COLUMN_DEFAULT
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ?", [$schema, $tableName]);

$columnMap = [];
foreach ($columns as $c) { $columnMap[$c->COLUMN_NAME] = $c; }

$this->assertEquals("varchar(100)", $columnMap['name']->COLUMN_TYPE);
$this->assertEquals("NO", $columnMap['name']->IS_NULLABLE);
```

---

## 11. Browser Test Patterns

### CRUD Lifecycle — Full Sequence

#### Tab Pane Test
```php
public function test_TC_XXX_P03_tab_pane_renders(): void
{
    $this->browse(function (Browser $browser) {
        $this->authenticate($browser);
        $this->visitAuthenticated($browser, '/module/page?tab=feature-tab');
        $browser->assertSee('Feature Title');
    });
}
```

#### Create Page Loads
```php
public function test_TC_XXX_P04_create_page_loads(): void
{
    $this->browse(function (Browser $browser) {
        $this->authenticate($browser);
        $this->visitAuthenticated($browser, self::BASE_PATH . '/create');
        $browser->assertSee('Create')->assertSee('Name');
    });
}
```

#### Create Submission
```php
public function test_TC_XXX_P05_create_submission(): void
{
    $this->browse(function (Browser $browser) {
        $this->authenticate($browser);
        $this->visitAuthenticated($browser, self::BASE_PATH . '/create');
        $browser->type('name', 'Test ' . self::$suffix)
                ->type('code', 'CODE' . self::$suffix)
                ->press('Save')
                ->pause(1000)
                ->assertSee('Test ' . self::$suffix);
    });
}
```

#### Show Page
```php
public function test_TC_XXX_P06_show_page_loads(): void
{
    $id = $this->createRecordDirectly();
    $this->browse(function (Browser $browser) use ($id) {
        $this->authenticate($browser);
        $this->visitAuthenticated($browser, self::BASE_PATH . '/' . $id);
        $browser->assertSee('Details');
    });
}
```

#### Edit + Update
```php
public function test_TC_XXX_P07_update_record(): void
{
    $id = $this->createRecordDirectly();
    $updatedName = 'Updated ' . self::$suffix;
    $this->browse(function (Browser $browser) use ($id, $updatedName) {
        $this->authenticate($browser);
        $this->visitAuthenticated($browser, self::BASE_PATH . '/' . $id . '/edit');
        $browser->type('name', $updatedName)
                ->press('Update')
                ->pause(1000)
                ->assertSee($updatedName);
    });
}
```

#### Update Without Changes
```php
public function test_TC_XXX_P08_update_without_changes(): void
{
    $id = $this->createRecordDirectly();
    $this->browse(function (Browser $browser) use ($id) {
        $this->authenticate($browser);
        $this->visitAuthenticated($browser, self::BASE_PATH . '/' . $id . '/edit');
        $browser->press('Update')
                ->pause(1000)
                ->assertSee('success'); // or assertPathIs
    });
}
```

#### Toggle Status (AJAX)
```php
public function test_TC_XXX_P09_toggle_status_works(): void
{
    $id = $this->createRecordDirectly(['is_active' => 1]);
    $this->browse(function (Browser $browser) use ($id) {
        $this->authenticate($browser);
        $this->visitAuthenticated($browser, self::BASE_PATH);
        $browser->click(".toggle-status-btn[data-id='$id']")
                ->pause(1000)
                ->assertSee('inactive');
        // Verify DB
        $this->assertFalse((bool) DB::table('table_name')->where('id', $id)->value('is_active'));
    });
}
```

#### Soft-Delete Lifecycle
```php
public function test_TC_XXX_P10_soft_delete_lifecycle(): void
{
    $id = $this->createRecordDirectly();
    $this->browse(function (Browser $browser) use ($id) {
        $this->authenticate($browser);

        // Delete
        $browser->visit($this->tenantUrl(self::BASE_PATH . '/' . $id))
                ->press('Delete')->pause(800);
        $this->assertSoftDeleted('table_name', ['id' => $id]);

        // Trash page shows deleted
        $browser->visit($this->tenantUrl(self::BASE_PATH . '/trash'))
                ->assertSee('Test');

        // Restore
        $browser->press('Restore')->pause(800);
        $this->assertNotSoftDeleted('table_name', ['id' => $id]);

        // Force delete
        $browser->visit($this->tenantUrl(self::BASE_PATH . '/' . $id))
                ->press('Delete')->pause(800)
                ->visit($this->tenantUrl(self::BASE_PATH . '/trash'))
                ->press('Force Delete')->pause(800);
        $this->assertDatabaseMissing('table_name', ['id' => $id]);
    });
}
```

#### Search
```php
public function test_TC_XXX_P11_search_by_name(): void
{
    $id = $this->createRecordDirectly(['name' => 'UniqueSearch_' . self::$suffix]);
    $this->browse(function (Browser $browser) {
        $this->authenticate($browser);
        $this->visitAuthenticated($browser, self::BASE_PATH . '?search=UniqueSearch_' . self::$suffix);
        $browser->assertSee('UniqueSearch_');
    });
}
```

#### Filter
```php
public function test_TC_XXX_P12_filter_by_status(): void
{
    $this->createRecordDirectly(['is_active' => 1]);
    $this->browse(function (Browser $browser) {
        $this->authenticate($browser);
        $this->visitAuthenticated($browser, self::BASE_PATH . '?is_active=0');
        $browser->assertDontSee('Test');
    });
}
```

#### Index Redirect (Index aborts 404 — tab pane only)
```php
public function test_TC_XXX_P13_index_redirects(): void
{
    $this->browse(function (Browser $browser) {
        $this->authenticate($browser);
        $browser->visit($this->tenantUrl(self::BASE_PATH))
                ->assertPathIs('/login'); // or assertSee('404')
    });
}
```

---

## 12. Security Test Patterns

### Guest Redirect
```php
public function test_TC_XXX_N10_guest_redirect(): void
{
    $this->browse(function (Browser $browser) {
        $browser->logout()
                ->visit($this->tenantUrl(self::BASE_PATH))
                ->assertPathIs('/login');
    });
}
```

### 403 Forbidden
```php
public function test_TC_XXX_N11_403_without_permission(): void
{
    $this->browse(function (Browser $browser) {
        $user = User::factory()->create();
        $browser->loginAs($user)
                ->visit($this->tenantUrl(self::BASE_PATH))
                ->assertSee('403')
                ->assertSee('THIS ACTION IS UNAUTHORIZED');
    });
}
```

### 404 Not Found — One Test Per Endpoint
```php
// For each CRUD endpoint that accepts an ID:
public function test_TC_XXX_N03_show_non_existent_returns_404(): void
{
    $this->browse(function (Browser $browser) {
        $this->authenticate($browser);
        $browser->visit($this->tenantUrl(self::BASE_PATH . '/999999'))
                ->assertSee('404');
    });
}

// Repeat for: edit, update (POST), destroy (POST/GET),
// toggle (POST/GET), restore (POST/GET), force-delete (POST/GET)
// Total: 7 tests (show + edit + update + destroy + toggle + restore + forceDelete)
```

**Important:** For POST-only routes (toggle, restore, forceDelete), if controller method is missing, expect 500 error not 404. Document as Dev Issue.

---

## 13. Child Table Interaction Tests

For features with child tables (hasMany relationships):

### Toggle Child Section
```php
// If child section is togglable via checkbox
$browser->click('.has-items-toggle')  // check the toggle
        ->pause(500)
        ->assertVisible('.child-table');
```

### Add Row
```php
$browser->click('.add-row-btn')
        ->pause(300)
        ->assertVisible('.child-row'); // row appears via JS
```

### Remove Row
```php
$browser->click('.remove-row-btn:last')
        ->pause(300);
// If last row: check for alert / warning
// If not last: row count decreases
```

### Fill Row Fields
```php
$browser->type('items[0][name]', 'Item 1')
        ->type('items[0][ordinal]', '1')
        ->click('.add-row-btn')
        ->type('items[1][name]', 'Item 2')
        ->type('items[1][ordinal]', '2');
```

### Submit With Children
```php
$browser->press('Save')->pause(1000)
        ->assertSee('Test ' . self::$suffix);
// Verify children in DB
$children = DB::table('child_table')->where('parent_id', $id)->get();
$this->assertCount(2, $children);
```

### Checkbox ↔ Hidden Sync
```php
// Checkboxes in child tables often sync to hidden inputs
$browser->check('items[0][is_active]')
        ->pause(200);
// Verify hidden input value is 1
$value = $browser->value('input[name="items[0][is_active]"][type="hidden"]');
$this->assertEquals('1', $value);
```

---

## 14. Tab Navigation Tests

For features that load as tabs:

```php
// Visit parent page, click tab
$browser->visit($this->tenantUrl('/complaint/complaint-mgt'))
        ->pause(1000)
        ->click('a[href*="tab=category"]')
        ->pause(1000)
        ->assertSee('Category');

// Or visit directly with tab parameter
$browser->visit($this->tenantUrl('/complaint/complaint-mgt?tab=category'))
        ->pause(1000)
        ->assertSee('Category');
```

---

## 15. TcList_Require.md — Full Template

```markdown
# TcList — {Feature Name} ({FolderName})

## Module Info
- **Feature**: {Feature Display Name} (Tab {N} — {Tab Name})
- **Tab URL**: `/module/page?tab=feature-tab`
- **Permission**: `tenant.feature.*`
- **Base Path**: `/module/feature`

## Schema Constraints (DDL: `{table_name}`)

### Columns
| Column | Type | Nullable | Default | FK / Constraint |
|--------|------|----------|---------|----------------|
| id | INT UNSIGNED | NO | AUTO_INCREMENT | PK |
| name | VARCHAR(100) | NO | — | UNIQUE |
| ... | ... | ... | ... | ... |

### Indexes
- **PRIMARY** (`id`)
- **UNIQUE** `uq_name` (`name`)

### Foreign Keys
- `fk_name` → `parent_table(id)` ON DELETE **RESTRICT** | **CASCADE** | **SET NULL**

## Auth Gates
- `tenant.feature.viewAny` | `tenant.feature.view` | `tenant.feature.create`
- `tenant.feature.store` | `tenant.feature.update` | `tenant.feature.delete`
- `tenant.feature.restore` | `tenant.feature.forceDelete` | `tenant.feature.status`

## FRD Business Rules Coverage
| Rule ID | Business Rule | Test Coverage | Status |
|---------|--------------|---------------|--------|
| BR-XXX-001 | Rule description | TC-XXX-N03 | ✅ Covered |
| BR-XXX-002 | Rule description | — | ❌ Missing — DEV-XX-01 |

## Test Case Mapping

### V1 Tests ({N} methods)
| # | TC ID | Type | Description | Method Name |
|---|-------|------|-------------|-------------|
| 1 | {FEAT}-V1-01 | DDL | Description | `method_name` |

### V2 Tests ({N} methods)
| # | TC ID | Type | Description | Method Name |
|---|-------|------|-------------|-------------|
| 1 | TC-{FEAT}-P01 | DDL | Description | `test_TC_{FEAT}_P01_*` |

## Coverage Summary
| Category | V1 Count | V2 Count | Combined |
|----------|----------|----------|----------|
| DDL/Schema | N | N | N |
| Positive | N | N | N |
| Negative | N | N | N |
| Dependency | N | N | N |
| **Total** | **N** | **N** | **N** |

## Development Issues
| ID | Description |
|----|-------------|
| DEV-XX-01 | Issue description with source file reference |
```

---

## 16. MANUALTESTING_Require.md — Full Template

```markdown
# Manual Testing — {Feature Name}

## Prerequisites
- User must have `tenant.feature.*` permissions
- Tenant must be initialized
- {Any specific setup}

## Test Cases

### TC-{FEAT}-P01: DDL Schema Verification
1. Run SQL: `SELECT COLUMN_TYPE, IS_NULLABLE, COLUMN_DEFAULT FROM information_schema.COLUMNS WHERE TABLE_NAME = '{table}'`
2. Verify column types match specification

### TC-{FEAT}-P04: Create Page Loads
1. Login as Admin
2. Navigate to `{BASE_PATH}/create`
3. Verify form fields: {list fields}
4. Verify breadcrumb

### TC-{FEAT}-P05: Create Submission
1. Fill all required fields
2. Click Save
3. Verify success message
4. Verify record appears in list

### TC-{FEAT}-N03: 404 Show Non-existent
1. Login as Admin
2. Visit `{BASE_PATH}/999999`
3. Verify 404 page

### TC-{FEAT}-N10: Guest Redirect
1. Logout
2. Visit `{BASE_PATH}`
3. Verify redirect to login page

### TC-{FEAT}-N11: 403 Forbidden
1. Login as user without `tenant.feature.viewAny` permission
2. Visit `{BASE_PATH}`
3. Verify 403 "THIS ACTION IS UNAUTHORIZED"
```

---

## 17. GapAnalysis_Require.md — Template

Only created when V1 pre-exists:

```markdown
# Gap Analysis — {Feature Name}

## V1 Coverage ({N} tests)
- DDL/Schema: {N}
- Positive CRUD: {N}
- Negative: {N}

## V2 Gap Filling ({N} tests)
- DDL info_schema: column types, ENUMs, indexes, FK rules
- {N}x 404 endpoints (show/edit/update/destroy/toggle/restore/forceDelete)
- Guest redirect + 403 Forbidden
- Search/filter by status
- Update without changes
- Empty trash
- FK dependency tests
- Tab pane navigation
- {Any other gaps}

## Dev Issues Found
| ID | Description |
|----|-------------|
| DEV-XX-01 | Issue from source analysis |
```

---

## 18. FRD Business Rules Mapping

### When to Do FRD Mapping
1. After completing all V2 tests
2. Read the full FRD document (typically 1000-1300 lines)
3. Extract all business rules (BR-XXX-001 through BR-XXX-N)
4. Map each BR to test coverage
5. Document gaps as Dev Issues

### FRD Mapping Table Template

Add to `TcList_Require.md`:

```markdown
## FRD Business Rules Coverage

| Rule ID | Business Rule | Test Coverage | Status |
|---------|--------------|---------------|--------|
| BR-CMP-001 | Unique name within same parent | TC-CAT-N03 | ✅ Covered |
| BR-CMP-002 | Escalation hours ascending | — | ❌ Missing — DEV-CAT-02 |
```

### BR Coverage Status Rules

| Status | Meaning | Action |
|--------|---------|--------|
| ✅ Covered | Has a direct test method | Add TC ID reference |
| ✅ Covered by DDL | DDL constraint enforces it (e.g., DECIMAL range) | Reference DDL test |
| ❌ Missing | No test, but could be added | Add test OR document as Dev Issue |
| ❌ Not implemented in controller | Controller doesn't implement this BR | Document as Dev Issue (never fix source) |
| ❌ Backend workflow | Requires services/scheduled tasks, not testable via Dusk | Document as Dev Issue |

### FRD Common Gap Categories
- BRs about **auto-population** (severity from category, SLA from dept) — backend workflow
- BRs about **status transitions** (Open→InProgress→Resolved) — workflow
- BRs about **scheduled tasks** (escalation level calculation) — not testable via Dusk
- BRs about **notifications** — not testable via Dusk
- BRs about **portal submission** (anonymous masking) — separate module
- BRs about **valid status transitions** — controller middleware

---

## 19. Development Issues Documentation

### When to Create a Dev Issue
1. **DDL vs Model mismatch**: Model uses SoftDeletes but DDL has no `deleted_at`
2. **DDL typo**: Column name misspelled (e.g., `evidence_uploded` instead of `evidence_uploaded`)
3. **Missing controller methods**: Route defined but controller method absent
4. **Policy bugs**: Permission name typos, missing methods
5. **Permission not registered**: Policy exists but not in config
6. **FRD not implemented**: Controller logic doesn't match BR requirement
7. **View bugs**: Wrong variable name in blade, dead JS references

### Dev Issue Format
```markdown
| DEV-XX-01 | DDL column `evidence_uploded` (missing 'o') vs model `evidence_uploaded` |
| DEV-XX-02 | ComplaintController MISSING trashed/restore/forceDelete/toggleStatus methods — routes 500 |
| DEV-XX-03 | Policy typo: `tenant.vendor-dahsboard.create` (line 32) instead of `tenant.department-sla.create` |
```

---

## 20. V1/V2 Management Rules

### Rule 1: Never Modify V1 Files
```php
// V1 files are PRESERVED AS-IS (except namespace update when moved)
// No changes to methods, logic, or structure
```

### Rule 2: V1 Files Must Be Moved, Not Copied
- Old location: `Testcases/cmp_{Feature}Crud_TestCas.php`
- New location: `CmpFeature/cmp_{Feature}Crud_TestCas.php`
- Namespace must be updated to match new directory
- Git: file is deleted from old + added in new

### Rule 3: V2 Suffix Rules
| Scenario | File Name |
|----------|-----------|
| V1 exists | `cmp_{Feature}_V2_TestCas.php` |
| No V1 (new feature) | `cmp_{Feature}_TestCas.php` (no V2 suffix) |
| Single comprehensive file | `cmp_{Feature}_TestCas.php` |

### Rule 4: TcList Combines Both
TcList must list ALL V1 + ALL V2 methods in one table, not separate.

---

## 21. Modules Completed Reference

| Module | Features | Test Methods | TCs | Status |
|--------|----------|-------------|-----|--------|
| **HPC** | 4 | ~190 | ~180 | ✅ |
| **QuestionBank** | 8 | ~175 | ~240 | ✅ |
| **Library** | 35+ | ~600+ | ~600+ | ✅ |
| **LmsExam** | 23 | ~350+ | ~400+ | ✅ |
| **Complaint** | 9 | 242 | 242 | ✅ |

### Library Sub-Tabs (8)
| Tab | Features |
|-----|----------|
| Masters | Authors, Categories, Genres, Keywords, Publishers, ResourceTypes, LocationMaster, BookConditions, BookMaster, BookCopies |
| Config | FineTypes, FineMaster, FineSlabDetails, AccountEntryConfigs, LibraryStatusMasters |
| Acquisition | BookPurchases, DigitalResources, DigResAccessRestriction, DigAccessRequestTypes |
| Transactions | Reservations, Transactions, DigitalAccessRequests, DigitalTransactions, RenewalRequests, CurricularAlignment, ApprovedReviews |
| Fines | Fines, FineTypes, FineMaster, FineSlabDetails |
| History | TransactionsHistory, InventoryAudit, EngagementEvents, LibrarySettings |
| Analytics | CollectionHealth, PopularityTrends, Predictive, Member360, CollectionPerformance, OverdueBooks, MostIssuedBooks, PredictiveDemand, ReadingBehavior |
| Reports | Dashboard, FineReports, DigitalResourceReports, AcquisitionReports, OverdueReports |

### LmsExam Sub-Tabs (7)
| Tab | Features |
|-----|----------|
| Masters | ExamType, ExamStatusEvent, ExamStudentGroup, ExamStudentGroupMember |
| Creation & Allocation | Exam, ExamPaper, ExamPaperSet, ExamScope, ExamBlueprint, PaperSetQuestion, ExamAllocation |
| Upload | OnlineUpload, OfflineUpload |
| Assessment | OnlineAssessment, OfflineAssessment |
| Log & Grievance | ReEvaluationRequests, ActivityLog, EventLog |
| Advanced Reports | HwSubmissionTracker, HwPerformanceAnalysis, ExamResultReport, StudentExamHistory, ExamSubjectComparison, LmsActivityDashboard |

### Complaint Sub-Features (7 tabs + 2 pages)
| Tab/Page | Features |
|----------|----------|
| Dashboard | KPIs, date filter |
| Category | Parent-child hierarchy, CRUD, is_system protection |
| SLA | 14 target types, escalation JSON, bulk operations |
| Complaint Manage | Ticket lifecycle, AJAX cascade, duplicate ticket_no |
| Medical Check | 6 check types, 3 result types, evidence upload |
| Actions | Read-only timeline, show page, search/filter |
| AI Insights | Unique per complaint, risk scores, read-only |
| Document Request | Standalone page, read-only list |
| Reports | Summary-status page, guest/403 security |

---

## 22. Common Pitfalls to Avoid

### ❌ WRONG — Direct visit without tab param for index-404 features
```php
// Bad: Will get 404 because index always aborts
$browser->visit(self::BASE_PATH);
// Good: Use tab URL
$browser->visit($this->tenantUrl('/parent-page?tab=feature'));
```

### ❌ WRONG — Using GET for POST routes
```php
// Bad: toggle/restore/forceDelete are often POST
$browser->visit(self::BASE_PATH . '/1/toggle-status');
// Good: Use direct fetch
$browser->script("fetch('...', {method:'POST', headers:{'X-CSRF-TOKEN':'...'}})");
```

### ❌ WRONG — Assuming controller has all methods
```php
// Always verify controller has these before testing:
// trashed(), restore(), forceDelete(), toggleStatus()
// If missing → Dev Issue, test will 500
```

### ❌ WRONG — Assuming base path has index route
```php
// Some controllers abort(404) on index() — they render as tab panes only
// Test via tab URL instead of direct path
```

### ❌ WRONG — Skipping tearDown cleanup
```php
// Always cleanup tenancy
protected function tearDown(): void
{
    if (function_exists('tenancy') && tenancy()->initialized) { tenancy()->end(); }
    parent::tearDown();
}
```

### ❌ WRONG — Not using unique suffix
```php
// Bad: Will collide on second run
$name = "Test Name";
// Good: Unique per run
$name = "Test Name " . self::$suffix;
```

### ❌ WRONG — Testing FRD rules that controller doesn't implement
```php
// If controller's excludeRejectedAndClosed() doesn't filter Resolved,
// testing BR-CMP-020 will fail. Document as Dev Issue instead.
```

### ❌ WRONG — Forgetting tenancy initialization
```php
// Without initializeTenantContext(), FK lookups and multi-tenant queries fail
// Always call in setUp()
```

### ❌ WRONG — Nested folders in feature
```php
// Bad: CmpCategory/V1/old_file.php
// Bad: CmpCategory/subfolder/helper.php
// Good: All files directly in CmpCategory/
```

---

> **Last Updated:** 2026-06-27
> **Covers Modules:** HPC, QuestionBank, Library, LmsExam, Complaint
