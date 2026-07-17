# Prime Testing — Rules Book

---

## 1. CARDINAL RULES (Never Break These)

| # | Rule | Why |
|---|------|-----|
| 1 | **DDL is absolute source of truth** — DDL > Conditions > FRD docs | DDL reflects actual DB; FRDs may be aspirational |
| 2 | **Never touch source code** — only test files | This repo is tests-only |
| 3 | **Always merge MANUALTESTING → TcList before writing tests** | Prevents orphan files, ensures full coverage |
| 4 | **Verify tab group names from UI views, never invent them** | Wrong names cause broken navigation |
| 5 | **Permission strings from controller's `Gate::authorize()` win** — NOT the seeder | If they differ, document as DEV issue |
| 6 | **ENUM values from DDL only** — never use fake values | Use actual ENUM members; inject non-members via `script()` |
| 7 | **No `addToAssertionCount(1)`** — every test method needs a real assertion | Cheat assertions hide broken tests |
| 8 | **No empty test stubs** — either implement or `$this->markTestIncomplete()` | Stubs rot and pass silently |
| 9 | **Always `->refresh()` after `->create()`** | DB defaults not loaded on model instance |
| 10 | **Use `hasCast()`, not `isCasted()` or `isActive()`** | Those methods don't exist in Laravel 12 |
| 11 | **Every mutation action (create/edit/delete/restore/forceDelete) MUST assert its confirmation + success message pattern** — can be SweetAlert2 CSS class handler, native `confirm()`, `data-confirm`, or toastr/flash message | Without message assertion, test doesn't verify the action completed with user feedback |
| 12 | **A single page/tab may contain multiple tables** — each table's functionality MUST be covered separately in TcList and test cases, never combined into one | Each table has its own data, columns, CRUD (or subset), and business rules; merging them causes coverage gaps |
| 13 | **Never assume full CRUD on any tab** — inspect the view to determine what operations actually exist. Some tabs are read-only, some have only create, some only delete, some are just data display with no mutations | Blindly writing create/edit/delete tests for every tab wastes time and creates false coverage; the view is the source of truth for available operations |

---

## 2. PHASE 0: SOURCE ANALYSIS CHECKLIST

Read ALL 11 sources before writing any code:

```
□ DDL           → Database DDL files
□ Model         → Module Models (casts, fillable, relationships, SoftDeletes)
□ Controller    → every method, every Gate::authorize
□ FormRequests  → every rule + error message
□ Routes        → every URI, name, method
□ Policy        → every permission gate
□ Perm Seeder   → exact permission strings created
□ Views         → selectors, modals, buttons, form fields
□ Services      → business logic, atomic ops, DB transactions
□ Requirements  → Module requirement docs
□ Conditions    → Module condition docs
```

### Multi-table screens:
- A single view/tab may contain **multiple independent tables** (e.g., one page has both an "All Items" table and a "Trashed Items" table, or separate tables for child records, or tab-panes each with their own table)
- **Each table is its own feature** — give it its own `{Prefix}_{Feature}` folder, TcList, and TestCas
- Never combine multiple tables' test cases into one TcList — they have different columns, different CRUD operations (some may be read-only, some have inline edit, some have delete only), different permissions, and different business rules
- When analyzing source, check `index.blade.php` for multiple `<table>` / `datatable` / `#table-id` elements or multiple tab-panes each with a table

### Operations vary per view — never assume CRUD:
- A tab/feature may have **any combination** of operations: create-only, edit-only, delete-only, read-only, or full CRUD — or none at all (just a static display)
- **How to determine available operations from views:**
  - Look for "Add" / "Create" / "New" buttons or modal triggers → create operation exists
  - Look for "Edit" buttons/links, or `a.confirm-action` → edit operation exists
  - Look for "Delete" buttons/forms with class `confirm-action-form` → soft delete exists
  - Look for "Restore" buttons on trashed items → restore operation exists
  - Look for "Force Delete" / "Permanently Delete" → force delete exists
  - Look for toggle switches / `.status-toggle` → toggle status exists
  - Look for search input → search/filter operation exists
  - **Common read-only tab types (no CRUD expected):**
  - **Logs / Activity Logs / Audit Logs** — system-generated, read-only display
  - **Reports** — aggregated data, filters only, no mutations
  - **Dashboards / Analytics** — charts, counts, summaries
  - **Notification lists** — view-only, sometimes mark-as-read (toggle, not CRUD)
  - **History / Timeline** — system-generated event trail
  - **Print/Export views** — display-only
- If none of the above → the tab is **read-only** or pure data display (only list/show tests needed)
- **How to determine from controllers:**
  - Controller method count tells the story — if only `index()` + `tabIndex()` exist, no CRUD
  - If `store()`/`update()`/`destroy()` are missing, those operations don't exist
  - FormRequests exist only for operations that accept form input
- **TcList must only list operations that actually exist** — don't add TC-P for "Create" if there's no create button in the view and no store() route
- **Similarly, test cases must only test what exists** — no phantom positive/negative tests for missing operations

### Red flags to catch:

- **Policy permission ≠ Permission Seeder** → Document as DEV issue
- **Controller bypasses FormRequest** with `$request->validate()` inline → dual validation bug
- **`{!! $var !!}` in views** → XSS vulnerability
- **Missing `deleted_at` in DDL but SoftDeletes on model** → Known issue
- **Routes missing for controller methods** → destroy/trash/restore/forceDelete often unregistered
- **Policy param name mismatch** → Gate never matches, all calls 403

---

## 3. TcList — SECTION-BY-SECTION DETAIL

### §1 — Feature Information

| Item | Details |
|------|---------|
| Module | Module name |
| Tab Group | UI label of tab group |
| Feature | Feature name |
| URL(s) | All URLs for this feature |
| Controller | Full namespace of controller |
| Model | Full namespace of model (traits used) |
| Validation | FormRequest class names |
| Permissions | All permission strings used |
| Seed data | How to seed |
| DB table | Table name |
| Unique fields | Columns with UNIQUE constraint |

---

### §2 — Pre-conditions

```
- Permissions required: (list every permission needed)
- Seed data: (what must be seeded)
- Related records: (what FKs must exist before tests run)
- Modules enabled: (if any specific module must be on)
```

---

### §3 — Test Data Strategy

| Item | Detail |
|------|--------|
| Unique suffix | Pattern used (e.g., `now()->format('His') . random_int(100, 999)`) |
| Student ID | How first student ID is fetched |
| Valid priority values | ENUM values listed |
| Valid status values | ENUM values listed |
| Default priority | Default value |
| Default status | Default value |
| Cleanup strategy | How records are cleaned up |

---

### §4 — Business Conditions

#### 4.1 Database Schema (`{table_name}`)

| BC-ID | Column | Type | Constraints | Covered By |
|-------|--------|------|-------------|------------|
| BC-DB-01 | id | int unsigned | PK, auto-increment | test_method_name |
| BC-DB-02 | name | varchar(150) | NOT NULL | test_required_name |
| BC-DB-03 | field | enum('A','B','C') | NOT NULL, DEFAULT 'A' | test_create_with_default |
| ... | ... | ... | ... | ... |
| BC-DB-nn | deleted_at | timestamp | NULLABLE (soft delete) | test_model_uses_soft_deletes |

**Rules:**
- EVERY column from DDL must be listed (id, all FKs, all NULLABLEs, all defaults, all ENUMs, deleted_at)
- ENUM values written in full (e.g., `enum('PENDING','VIEWED','COMPLETED')`)
- DEFAULT values noted
- Covered By links to the test method that verifies this column

#### 4.2 Indexes

| BC-IDX | Index Name | Columns | Type | Covered By |
|--------|-----------|---------|------|------------|
| BC-IDX-01 | uq_table_field | field | UNIQUE BTREE | test_unique_constraint |
| BC-IDX-02 | idx_table_cols | col1, col2 | BTREE | — |

#### 4.3 Foreign Keys

| BC-REF | FK Column | Referenced Table | onDelete | Covered By |
|--------|-----------|------------------|----------|------------|
| BC-REF-01 | parent_id | parent_table | CASCADE | — |
| BC-REF-02 | nullable_fk_id | other_table | SET NULL | — |

#### 4.4 Validation Rules (`{FormRequestName}`)

| BC-VAL | Field | Rule | Error Message | Covered By |
|--------|-------|------|---------------|------------|
| BC-VAL-01 | name | required, string, max:150 | "The name field is required." | test_required_name |
| BC-VAL-02 | status | required, in:A,B,C | "The selected status is invalid." | test_required_status, test_invalid_status |
| BC-VAL-03 | field | nullable, integer, exists:table,id | — | test_create_with_field |

**Rules:**
- EVERY rule from the FormRequest is listed
- `Rule::in` values listed in full
- nullable/required/unique/min/max noted
- Error message written exactly as it appears in validation

#### 4.5 Authorization (Permission Gates)

| BC-AUTH | Permission | Controller Method | Behavior | Covered By |
|---------|-----------|-------------------|----------|------------|
| BC-AUTH-01 | tenant.module.viewAny | index() | Without → 403 | test_permission_403 |
| BC-AUTH-02 | tenant.module.view | show() | Without → 403 | test_permission_403 |
| BC-AUTH-03 | tenant.module.create | create(), store() | Without → 403 | test_permission_403 |
| BC-AUTH-04 | tenant.module.update | edit(), update(), toggleStatus() | Without → 403 | test_permission_403 |
| BC-AUTH-05 | tenant.module.delete | destroy() | Without → 403 | test_permission_403 |
| BC-AUTH-06 | tenant.module.restore | trashed(), restore() | Without → 403 | test_permission_403 |
| BC-AUTH-07 | tenant.module.forceDelete | forceDelete() | Without → 403 | test_permission_403 |

**Rules:**
- EVERY permission the controller checks must be listed
- Also check what the Permission Seeder actually creates — flag mismatches as DEV issues

#### 4.6 Business Logic

| BC-BIZ | Condition | Expected Behavior | Covered By |
|--------|-----------|-------------------|------------|
| BC-BIZ-01 | Default is_active | Defaults to 1 (Active) | test_create_required_only |
| BC-BIZ-02 | Default priority | Defaults to 10 | test_create_required_only |
| BC-BIZ-03 | Soft delete sets is_active=false | destroy() sets is_active=0 before delete() | test_soft_delete |
| BC-BIZ-04 | Toggle returns JSON | `{success: true, is_active, message}` | test_toggle_status |
| BC-BIZ-05 | Redirect after create | Redirects to index page | test_create |
| BC-BIZ-06 | Checkbox normalization | Controller uses `$request->boolean()` | test_create_unchecked |
| BC-BIZ-07 | Activity log on create | 'Record created.' stored | — |
| BC-BIZ-08 | Search by name | tabIndex() filters with LIKE | test_search |
| BC-BIZ-09 | Force delete error handling | Catches Throwable for FK errors | — |

**Covers:** scopes, atomic operations, DB transactions, FK restrict behavior, soft delete lifecycle, color coding / UI states, cross-feature integration, redirect URLs, JSON response shapes

**Message assertion rules — every pattern used in the codebase:**

> ⚠️ Either SweetAlert (v1) or SweetAlert2 (v2) may be present. v1 uses CSS class `.confirm` / `.cancel`, v2 uses `.swal2-confirm` / `.swal2-cancel`. Check the view's script for `swal(` (v1) vs `Swal.fire(` (v2). The assertion goal is the same — only the CSS selector changes.

| Operation | CSS Class Pattern | Native Pattern | What to Assert |
|-----------|------------------|----------------|----------------|
| Edit/Update | `a.confirm-action` → "Sure to Edit?" | — | Success flash message: `->assertSee('updated')` or `->assertSee('success')` |
| Soft Delete | `form.confirm-action-form` → "Move to Trash?" | `onclick="return confirm('...')"` or `onsubmit="return confirm('...')"` | Confirmation dialog + "Trashed" success |
| Restore | `form.confirm-action-form-restore` / `a.confirm-action-restore` → "Sure to restore?" | — | Confirmation dialog + "restored" success |
| Force Delete | `form.confirm-action-form-force-delete` → "Delete Permanently?" | — | Confirmation dialog + "deleted" success |
| Toggle Status | AJAX → SweetAlert/SweetAlert2 toast (auto) | — | JSON `{success: true}` |
| Create | — | — | Success flash: `->assertSee('created')` or `->assertSee('success')` |
| Other actions | `data-confirm="..."` attribute + jQuery handler | — | Assert data-confirm message text + success toast |

**Key patterns to recognize in views:**
- `<form class="confirm-action-form">` → SweetAlert2 delete (click `.swal2-confirm`, assert "Move to Trash?")
- `<form class="confirm-action-form-restore">` → SweetAlert2 restore (click `.swal2-confirm`, assert "Sure to restore?")
- `<form class="confirm-action-form-force-delete">` → SweetAlert2 force delete (click `.swal2-confirm`, assert "Delete Permanently?")
- `<a class="confirm-action">` → SweetAlert2 edit (click `.swal2-confirm`, assert "Sure to Edit?")
- `swal(...)` inline → SweetAlert v1 (click `.confirm`, assert same messages)
- `Swal.fire(...)` inline → SweetAlert2 v2 (click `.swal2-confirm`, assert same messages)
- `<form class="confirm-action" data-confirm="...">` → Custom message (jQuery + SweetAlert2)
- `onclick="return confirm('...')"` → Native browser confirm dialog
- `onsubmit="return confirm('...')"` → Native browser confirm on form submit
- Session flash → Bootstrap alert or auto SweetAlert/SweetAlert2 toast (assert the message text)

**Test assertions depend on which pattern the view uses — inspect the view HTML first.**

#### 4.7 Routes

| BC-R | Method | URI | Name | Gate | Covered By |
|------|--------|-----|------|------|------------|
| BC-R-01 | GET | /module/items | module.items.index | tenant.module.viewAny | test_tab_loads |
| BC-R-02 | GET | /module/items/create | module.items.create | tenant.module.create | test_create_page_loads |
| BC-R-03 | POST | /module/items | module.items.store | tenant.module.create | test_create |
| BC-R-04 | GET | /module/items/{id} | module.items.show | tenant.module.view | test_show |
| BC-R-05 | GET | /module/items/{id}/edit | module.items.edit | tenant.module.update | test_edit |
| BC-R-06 | PUT | /module/items/{id} | module.items.update | tenant.module.update | test_update |
| BC-R-07 | DELETE | /module/items/{id} | module.items.destroy | tenant.module.delete | test_destroy |
| BC-R-08 | GET | /module/items/trash | module.items.trashed | tenant.module.restore | test_trash |
| BC-R-09 | GET | /module/items/{id}/restore | module.items.restore | tenant.module.restore | test_restore |
| BC-R-10 | DELETE | /module/items/{id}/force-delete | module.items.forceDelete | tenant.module.forceDelete | test_force_delete |
| BC-R-11 | POST | /module/items/{id}/toggle-status | module.items.toggleStatus | tenant.module.update | test_toggle |

**Rules:**
- EVERY route for this feature listed
- Resource routes expanded to individual entries (index, create, store, show, edit, update, destroy)
- Custom routes (toggleStatus, restore, forceDelete, trashed, markCompleted, etc.) listed separately

---

### §5 — Test Case List

#### 5.1 Positive Test Cases

| TC-ID | Description | Expected Result | V2 Test | Status |
|-------|-------------|----------------|---------|--------|
| TC-P01 | Tab loads with datatable | Columns visible, buttons present | test_tab_loads | ✅ |
| TC-P02 | Create with all fields | All values stored correctly | test_create_all_fields | ✅ |
| TC-P03 | Create with required only | Defaults applied | test_create_required_only | ✅ |
| ... | ... | ... | ... | ... |

**Must cover:** page loads, create (all fields), create (required only), show, edit prefill, update, toggle status, soft delete, restore, force delete, search, filter, log consumption / child ops, empty trash, state banner

#### 5.2 Negative Test Cases

| TC-ID | Description | Expected Result | V2 Test | Status |
|-------|-------------|----------------|---------|--------|
| TC-N01 | Required — empty name | Validation error | test_required_name | ✅ |
| TC-N02 | Invalid ENUM value | Validation error | test_invalid_enum | ✅ |
| ... | ... | ... | ... | ... |

**Must cover:** every individual required field, invalid ENUM, negative/min violations, unique constraint, guest redirect, 403 permission, 404 (show, edit, delete, toggle, restore, forceDelete)

#### 5.3 Dependency Test Cases

| TC-ID | Category | Description | Expected Result | V2 Test | Status |
|-------|----------|-------------|----------------|---------|--------|
| TC-D01 | B | Full lifecycle | Create→Edit→Toggle→Delete→Restore→ForceDelete | test_full_lifecycle | ✅ |
| . . . | . . . | . . . | . . . | . . . | . . . |

**Must cover:** create→child→verify, full lifecycle, FK restrict, scope verification

---

### §6 — Detailed Test Steps

#### 6.1 Positive TC Steps

For EACH TC-P from §5.1, a step-by-step table:

| Step | Action | Expected |
|------|--------|----------|
| 1 | Login as admin | Dashboard loaded |
| 2 | Visit create page | Form loaded |
| 3 | Type name = "Test_{unique}" | Field populated |
| 4 | Select dropdown_id = 1 | Value selected |
| 5 | Press "Submit" | Redirect to index |
| 6 | Verify DB | assertDatabaseHas |

**Rules:**
- EVERY TC-P from §5.1 documented
- Test data values included (e.g., "Enter name = 'Morning [timestamp]'")
- UI interactions described (click, select, type, verify)

#### 6.2 Negative TC Steps

For EACH TC-N from §5.2, step-by-step table:

| Step | Action | Expected |
|------|--------|----------|
| 1 | Visit create page | Form loaded |
| 2 | Leave name empty | Empty field |
| 3 | Fill other required fields | Values set |
| 4 | Press "Submit" | Validation error visible |

#### 6.3 Dependency TC Steps

For EACH TC-D from §5.3, step-by-step table:

| TC | Action | Assertion |
|----|--------|-----------|
| TC-D01 | Create → updateStatus → softDelete → restore → forceDelete | All transitions verified |

**Message assertion rules for all mutation steps:** (See §9 for SweetAlert2 details)
```
Edit/Update   → Must assert success flash message after redirect ("updated" or "success")
Soft Delete   → Must assert SweetAlert confirmation ("Are you sure") AND success message ("Trashed")
Restore       → Must assert SweetAlert confirmation ("Are you sure") AND success message ("restored")
Force Delete  → Must assert SweetAlert confirmation ("Are you sure") AND success message ("deleted")
Create        → Must assert success flash message ("created" or "success")
```

---

### §7 — V2 Test Method Index

| # | Method (full name) | Coverage | TC-ID Covered |
|---|--------------------|----------|---------------|
| 1 | test_tab_loads_and_displays_datatable | Tab loads | TC-P01 |
| 2 | test_create_with_required_fields | Create minimal | TC-P02 |
| ... | ... | ... | ... |

**Rules:**
- Every test method in the TestCas file is listed
- TC Map links each method to its TC-P / TC-N / TC-D
- Methods that cover multiple TCs can list multiple

---

### §8 — Coverage Summary

| Category | Total TCs | Covered | Coverage % | Test Methods |
|----------|-----------|---------|------------|--------------|
| Schema | 3 | 3 | 100% | count |
| Positive | N | N | 100% | count |
| Negative | N | N | 100% | count |
| Dependency | N | N | 100% | count |
| **Total** | **N** | **N** | **100%** | **total methods** |

---

### §9 — Route Reference

| Method | URI | Name | Gate |
|--------|-----|------|------|
| GET | /module/items | module.items.index | tenant.module.viewAny |
| ... | ... | ... | ... |

---

### §10 — Development Issues Found

| ID | File | Issue | Severity | Status |
|----|------|-------|----------|--------|
| DEV-01 | Controller | Permission mismatch | High | Open |
| DEV-02 | View | XSS vulnerability | High | Open |
| DEV-03 | DDL | Missing deleted_at | High | Open |

**Must include:** permission gate mismatches, view/attribute bugs, missing FormRequests, controller/policy inconsistencies

---

### §11 — Known Issues Summary

| ID | Issue | Status |
|----|-------|--------|
| KN-01 | Routes not registered for restore/forceDelete | Open |
| KN-02 | Inline validation differs from FormRequest | Open |

---

### §12 — Execution Status

| TC-ID | Test Name | Type | Status | Date | Tester | Remarks |
|-------|-----------|------|--------|------|--------|---------|
| TC-P01 | test_tab_loads | Positive | ✅ | — | — | — |
| TC-N01 | test_required_name | Negative | ✅ | — | — | — |
| TC-D01 | test_full_lifecycle | Dependency | ✅ | — | — | Newly added |

**Status values:** ✅ Implemented, 🟡 Pending, ❌ Not covered

---

### Covered By column rules (applies to all BC-* tables):
- Every BC-DB row **must** reference a test method
- Every BC-VAL row **must** reference at least one test
- Every BC-AUTH row **must** reference a 403 test
- Every BC-R row **must** reference a test that exercises that route
- If nothing covers a BC row yet, mark `—` (coverage gap)

---

## 4. MERGING MANUALTESTING INTO TCLIST

### Steps:
1. MANUALTESTING §1 (Test Environment Setup) → TcList §2 (Pre-conditions) + §3 (Test Data Strategy)
2. MANUALTESTING §2 (Manual Test Cases TC-M) → TcList §6 (Detailed Test Steps)
3. MANUALTESTING §3 (Test Data) → TcList §3 (Test Data Strategy)
4. Delete MANUALTESTING file after merge
5. Also delete any orphan: `*Require.md`, `*ValidationReport.md`, `run-tests.ps1`

### Final directory must contain exactly 2 files:
```
{Feature}/
  {Prefix}_{Feature}_TestCas.php
  {Prefix}_{Feature}TcList_Require.md
```

---

## 5. TEST METHOD COMPLETE CHECKLIST

### Schema Tests (3)
```
□ 01: Table exists, columns, SoftDeletes, casts, fillable, relationships
□ 02: DB NOT NULL columns reject null inserts
□ 03: DB nullable fields accept null values
```

### Positive Tests (16 minimum):
```
□ Tab loads with UI elements        □ Create page loads with form fields
□ Create with all fields            □ Create with required only (verify defaults)
□ Show page / detail view           □ Edit page prefills values + success flash on update
□ Update fields (verify DB)         □ Toggle status (AJAX JSON response)
□ Soft delete (deleted_at + SweetAlert "Trashed")    □ Restore (deleted_at cleared + SweetAlert "restored")
□ Force delete (record gone + SweetAlert "deleted")  □ Search by name/text
□ Filter by status/active           □ Log consumption / child record
□ Empty trash state                 □ State banner (low stock, etc.)
```

### Negative Tests (12 minimum):
```
□ Required field #1 (name/text)     □ Required field #2 (category/select)
□ Required field #3 (other)         □ Invalid ENUM value
□ Negative/min violation #1         □ Negative/min violation #2
□ Guest → /login redirect           □ No permission → 403
□ 404 on non-existent show          □ 404 on non-existent edit
□ 404 on non-existent delete        □ 404 on non-existent toggle
```

### Dependency Tests (4 minimum):
```
□ Create → child → parent verify    □ Full lifecycle (create→view→edit→toggle→delete→restore→forceDelete)
□ FK restrict (can't delete parent) □ Scope verification (scopeActive, etc.)
```

---

## 6. VERSION MANAGEMENT (V1 vs V2)

| Situation | Action |
|-----------|--------|
| No V1 file, no V2 file | Create V1 file |
| V1 exists, no V2 | Create V2 |
| V1 exists, V2 exists | Upgrade Version (modify V2) |

---

## 7. TEST METHOD PATTERNS

### Standard Dusk test:
```php
public function test_create_with_X(): void
{
    $this->browse(function (Browser $browser) {
        $this->loginAsAdmin($browser);
        $browser->visit($this->route('create'))
                ->type('name', "Test_{$this->unique}")
                ->select('field_id', (string) $this->getLookupId())
                ->check('is_active')
                ->press('Submit')
                ->waitForLocation('/expected/url', 10);

        $this->assertDatabaseHas('table_name', [
            'name' => "Test_{$this->unique}",
            'field_id' => $this->getLookupId(),
        ]);
    });
}
```

### Edit/Update test (with success flash message assertion):
```php
public function test_edit_updates_record(): void
{
    $rec = $this->createRecord();
    $newName = "Updated_{$this->unique}";

    $this->browse(function (Browser $browser) use ($rec, $newName) {
        $this->loginAsAdmin($browser);
        $browser->visit($this->route('edit', $rec->id))
                ->type('name', $newName)
                ->press('Update')
                ->waitForLocation('/expected/index', 10)
                ->assertSee('updated');             // Success flash message

        $this->assertDatabaseHas('table', [
            'id' => $rec->id,
            'name' => $newName,
        ]);
    });
}
```

### Soft delete test (with SweetAlert assertion):
```php
public function test_soft_delete_shows_alert_and_trashes(): void
{
    $rec = $this->createRecord();

    $this->browse(function (Browser $browser) use ($rec) {
        $this->loginAsAdmin($browser);
        $browser->visit($this->route('destroy', $rec->id))
                ->assertSee('Are you sure')       // SweetAlert confirmation
                ->assertSee('Trashed');            // Success message after confirm
    });
}
```

### Restore test (with SweetAlert assertion):
```php
public function test_restore_shows_alert_and_restores(): void
{
    $rec = $this->createRecord();
    $rec->delete();

    $this->browse(function (Browser $browser) use ($rec) {
        $this->loginAsAdmin($browser);
        $browser->visit($this->route('restore', $rec->id))
                ->assertSee('Are you sure')       // SweetAlert confirmation
                ->assertSee('restored');           // Success message after confirm
    });
}
```

### Force delete test (with SweetAlert assertion):
```php
public function test_force_delete_shows_alert_and_deletes(): void
{
    $rec = $this->createRecord();
    $rec->delete();

    $this->browse(function (Browser $browser) use ($rec) {
        $this->loginAsAdmin($browser);
        $browser->visit($this->route('forceDelete', $rec->id))
                ->assertSee('Are you sure')       // SweetAlert confirmation
                ->assertSee('deleted');            // Success message after confirm
    });
}
```

### AJAX POST test:
```php
public function test_update_status(): void
{
    $rec = $this->createRecord(['status' => 'PENDING']);
    $this->browse(function (Browser $browser) use ($rec) {
        $this->loginAsAdmin($browser);
        $browser->post($this->route('updateStatus', $rec->id), [
            'status' => 'VIEWED',
        ]);
        $this->assertDatabaseHas('table', ['id' => $rec->id, 'status' => 'VIEWED']);
    });
}
```

### Invalid ENUM via script (bypasses select validation):
```php
public function test_invalid_status_value(): void
{
    $this->browse(function (Browser $browser) {
        $this->loginAsAdmin($browser);
        $browser->visit($this->route('create'))
                ->select('student_id', '1');
        $browser->script(["document.querySelector('select[name=\"status\"]').value = 'BADVALUE';"]);
        $browser->press('Create')
                ->assertSee('The selected status is invalid');
    });
}
```

### XSS safety test:
```php
public function test_xss_in_field_is_escaped(): void
{
    $xss = "<script>alert('xss')</script>";
    $rec = $this->createRecord(['field' => $xss]);
    $this->browse(function (Browser $browser) use ($rec, $xss) {
        $this->loginAsAdmin($browser);
        $browser->visit($this->route('show', $rec->id))
                ->assertSourceHas(htmlspecialchars($xss));
    });
}
```

### Helper methods pattern:
```php
protected string $unique;

protected function setUp(): void
{
    parent::setUp();
    $this->unique = now()->format('His') . random_int(100, 999);
}

protected function route(string $name, mixed $params = []): string
{
    return route("module.route-prefix.{$name}", $params, false);
}

protected function loginAsAdmin(Browser $browser): void
{
    $browser->loginAs(1);
}

protected function createRecord(array $overrides = []): Model
{
    $data = array_merge([
        'name' => "Test_{$this->unique}",
        'is_active' => 1,
    ], $overrides);
    $record = Model::create($data);
    $record->refresh();
    return $record;
}
```

---

## 8. COMMON DEV ISSUES (Pattern Catalog)

### Permission/Package Mismatches
- Controller uses `tenant.X.*` but seeder creates `tenant.Y.*` → **Critical**, gates never match
- Policy checks wrong permission string (copy-paste error) → High
- `show()` uses `viewAny` gate instead of `view` → Medium
- `edit()/update()` shares gate with `create()` → Medium (no ownership check)
- Policy param name wrong → High, gate never fires

### View Bugs
- `{!! $var !!}` instead of `{{ $var }}` → **XSS vulnerability**
- Wrong variable name in blade → High, 500 error
- Non-existent property referenced → High
- Raw FK integer displayed instead of related name → Medium

### Controller Bugs
- Bypasses FormRequest with inline `$request->validate()` → Dual validation
- Inline validation rules differ from FormRequest → Medium
- Missing routes for destroy/trash/restore/forceDelete → High, endpoints unreachable
- Missing toggleStatus method → Low
- Looks up wrong code string → **Critical**, 500 error
- Non-existent model attribute checked → **Critical**, 500 error

### DDL Gaps
- `deleted_at` missing from DDL but model has SoftDeletes → High
- Columns in `$fillable` not in DDL → Medium
- DDL columns that should exist but don't → High
- FK column with no constraint in DDL → Low

---

## 9. SWEETALERT / SWEETALERT2 — CONFIRMATION & NOTIFICATION LIBRARIES

The project uses **both** SweetAlert (v1) and SweetAlert2 (v2) across different modules and views. Some features load SweetAlert2 via CDN (`sweetalert2@11`), others use older inline SweetAlert calls, and some views may reference either library interchangeably.

**Key difference:**

| Feature | SweetAlert (v1) | SweetAlert2 (v2) |
|---------|-----------------|-------------------|
| Global function | `swal(...)` | `Swal.fire(...)` |
| CSS classes | `.sweet-alert` | `.swal2-*` |
| Toast support | No native toast | Built-in toast mode |
| Confirm button | `.confirm` | `.swal2-confirm` |
| Cancel button | `.cancel` | `.swal2-cancel` |
| Title element | `h2` | `.swal2-title` |

The global footer-scripts (loaded on every page) use **SweetAlert2** (`Swal.fire()`). However, individual modules may have their own inline scripts that call `swal()` (v1) or `Swal.fire()` (v2). Always inspect the view's actual script to know which version is in use.

Both libraries are the **primary confirmation dialog and notification system** across the entire project.

### Usage modes:

| Mode | Method | Purpose | Display |
|------|--------|---------|---------|
| **Confirmation modal** | `Swal.fire({...})` | Confirm actions (delete, restore, etc.) | Centered modal with Cancel/Confirm buttons |
| **Toast notification** | `Swal.fire({toast: true, position: 'top-end', ...})` | Success/error/validation flash messages | Top-right corner, auto-dismiss after 2-4s |

### Pre-wired CSS class handlers (defined in footer-scripts — all SweetAlert2):

| CSS Class | Action | Title Text | Expected Button |
|-----------|--------|------------|-----------------|
| `form.confirm-action-form` | Delete → Trash | "Move to Trash ?" | "Yes, move to trash!" |
| `form.confirm-action-form-restore` | Restore | "Sure to restore?" | "Yes, restore!" |
| `form.confirm-action-form-force-delete` | Force delete | "Delete Permanently ?" | "Yes, delete permanently!" |
| `a.confirm-action` | Edit | "Sure to Edit?" | "Yes, proceed!" |

### How tests interact with SweetAlert/SweetAlert2:

1. **Confirmation modals (SweetAlert2)** — The form is NOT submitted until the user clicks the SweetAlert confirm button. In Dusk browser tests:
   - Visit the action URL → SweetAlert2 modal appears
   - `->assertSee('Move to Trash?')` // Confirm dialog title visible
   - Click `.swal2-confirm` → form submits
   - After submit → assert success message
   
   ```php
   // Example: soft delete with SweetAlert2 confirmation
   $browser->visit($this->route('destroy', $rec->id))
           ->assertSee('Move to Trash?')      // Assert dialog title
           ->click('.swal2-confirm')          // Click "Yes, move to trash!"
           ->waitForText('Trashed')
           ->assertSee('Trashed');
   ```

2. **Confirmation modals (SweetAlert v1)** — If the view uses `swal()` instead of `Swal.fire()`:
   - Dialog has class `.sweet-alert`, confirm button is `.confirm`
   - Use same assertion pattern but with different selectors:
   ```php
   $browser->click('.confirm')  // instead of .swal2-confirm
           ->assertSee('Trashed');
   ```

3. **Toast notifications (SweetAlert2 only)** — Auto-displayed on page load after redirect or AJAX response:
   - After form submit → page redirects → SweetAlert2 toast auto-shows
   - `->assertSee('updated')` // Toast message text
   - No user interaction needed — toast auto-dismisses after 2-4s

4. **Status toggle toasts** — Returned via AJAX JSON response:
   - Assert JSON: `$response->assertJson(['success' => true])`
   - Toast shown automatically by the `.status-toggle` handler
   - Toast icon: `'success'` or `'warning'`, timer: 2000ms

5. **Session flash → auto toast** — Every page load checks for `session('success')` or `session('error')` and displays as SweetAlert2 toast:
   - After create: `->assertSee('created')` or `->assertSee('success')`
   - After update: `->assertSee('updated')`
   - After delete: `->assertSee('Trashed')`

### Key Dusk selectors (both versions):

| Element | SweetAlert2 (v2) | SweetAlert (v1) |
|---------|------------------|-----------------|
| Confirm button | `.swal2-confirm` | `.confirm` |
| Cancel button | `.swal2-cancel` | `.cancel` |
| Dialog title | `.swal2-title` | `h2` |
| Dialog body/content | `.swal2-html-container` | `.lead` or `p` |
| Toast container | `.swal2-toast` | N/A (no toasts in v1) |

### Rules:
- **Always inspect the actual HTML/CSS classes of the view** to determine which version is used — check for `.swal2-*` (v2) vs `.sweet-alert` (v1) classes.
- If the view uses `swal()` (v1) vs `Swal.fire()` (v2), adjust Dusk selectors accordingly.
- If the view uses native `confirm()` (no library), test assertions must match native behavior — no `.swal2-confirm` or `.confirm` click needed.
- The global footer-scripts always use SweetAlert2 — but individual module views may override with inline SweetAlert v1 `swal()` calls.
- When in doubt, inspect the page source for `swal(` vs `Swal.fire(` to determine which library is active.

---

## 10. DUSK TEST QUIRKS & GOTCHAS

### Environment
- All modules are **disabled** in `modules_statuses.json` — tests can't run without enabling
- Preloader builds class→file map with `class_alias` — class name ≠ filename is OK
- Use `$this->browse()` for UI interaction, `$this->get/post/delete/put` for HTTP-only tests
- **Never mix `$this->actingAs()` with `$this->browse()` in same method**

### Browser Interactions
- `->script()` breaks the fluent chain — call it as a separate statement
- `->waitForLocation()` needs full or relative URL path
- `->assertSee()` checks visible text only — use `assertSourceHas()` for XSS
- `->press()` triggers form submit — needs `->waitForLocation()` or `->waitForText()`
- CSRF token + `X-Requested-With` header needed for browser AJAX posts
- **Edit/Update tests MUST assert success flash message** — after update redirect, assert "updated" or "success" is visible (see §9 for SweetAlert2 toast details)
- **Soft delete / restore / forceDelete tests MUST assert SweetAlert confirmation** — visit the action URL, assert "Are you sure" (confirmation dialog), then assert success message ("Trashed" / "restored" / "deleted") (see §9 for .swal2-confirm click pattern)

### Data
- Unique suffix: `now()->format('His') . random_int(100, 999)`
- Always `->refresh()` after `->create()` — DB defaults don't populate on model instance
- Use `assertGreaterThanOrEqual()` for seed data counts, never `assertEquals()`
- Clean up in `try/finally` blocks using `forceDelete()` for soft-deletable models
- FK cleanup order: delete children FIRST, then parent

---

## 11. ASSERTION REFERENCE

| Assertion | When to Use |
|-----------|-------------|
| `assertDatabaseHas('table', [...])` | Record exists in DB |
| `assertDatabaseMissing('table', [...])` | Record deleted from DB |
| `assertSoftDeleted('table', [...])` | Soft-deleted record still exists with deleted_at |
| `assertNotSoftDeleted('table', [...])` | Record restored (deleted_at = NULL) |
| `assertSee('text')` | Text visible on page |
| `assertDontSee('text')` | Text NOT visible on page |
| `assertSourceHas('html')` | Raw HTML in page source (XSS tests) |
| `assertStatus(404)` | HTTP 404 response |
| `assertPathIs('/login')` | Redirected to login |
| `assertInstanceOf(Class::class, $var)` | Relationship type check |
| `assertNotNull($var->field)` | Field is not null |
| `assertEquals($expected, $actual)` | Exact value match |
| `assertNotEquals($a, $b)` | Values differ (UUID uniqueness) |
| `assertGreaterThanOrEqual($min, $val)` | Count/range assertions |

---

## 12. TCLIST WRITING CONVENTIONS

### Status column values:
- `✅ Implemented` — test method exists and covers this TC
- `🟡 Pending` — deferred (e.g., complex browser interaction)
- `❌ Not covered` — gap needing work

### Covered By conventions:
- Link BC-DB rows to the test that verifies that column
- If no dedicated test, link to the most relevant test that touches it
- `—` means no test covers it (acceptable for non-critical columns like `updated_at`)

### Test case numbering:
- TC-P01 → TC-Pnn for positive cases
- TC-N01 → TC-Nnn for negative cases
- TC-D01 → TC-Dnn for dependency cases
- Gaps in numbering are OK but order should be logical

---

## 13. PERMISSION TESTING PATTERN

```php
public function test_permission_403_for_unauthorized_user(): void
{
    $user = User::factory()->create([
        'emp_code' => "perm{$this->unique}",
        'short_name' => "perm{$this->unique}",
        'prefered_language' => 'en',
    ]);

    $this->browse(function (Browser $browser) use ($user) {
        $browser->loginAs($user)
                ->visit($this->route('index'))
                ->assertSee('403')
                ->assertSee('Forbidden');
    });

    $user->delete();
}
```

**Key points:**
- Create user with ALL required fields (`emp_code`, `short_name`, `prefered_language`)
- After `revokePermissionTo()`, call `app(PermissionRegistrar::class)->forgetCachedPermissions()`
- Assert actual 403 status text, not just status code

---

## 14. XSS VULNERABILITY PATTERNS

### High-risk patterns in blade files:
```blade
{!! $record->description !!}        <!-- XSS vulnerable -->
{!! $record->content_text !!}       <!-- XSS vulnerable -->
{!! $record->reason !!}             <!-- XSS vulnerable -->
{{ $record->name }}                 <!-- Safe - blade escapes -->
```

### Test approach:
- Inject `<script>alert('xss')</script>` into the vulnerable field
- Visit the show/detail page
- `assertSourceHas(htmlspecialchars($xss))` confirms escaping

---

## 15. FILE MANAGEMENT

### Files to delete per feature:
- `*MANUALTESTING*.md` (after merge)
- `*ValidationReport*.md` (old artifact)
- `*Require.md` (old artifact, except TcList)
- `run-tests.ps1` (old artifact)
- Old V1/CrudTest files in test directory

### Files to keep per feature (exactly 2):
```
{Feature}/
  {Prefix}_{Feature}_TestCas.php
  {Prefix}_{Feature}TcList_Require.md
```

---

## 16. WORKFLOW SUMMARY

```
NEW FEATURE REQUEST
  │
  ├─ Phase 0: Source Analysis (11 sources)
  │   ├─ Read DDL, Model, Controller, FormRequests, Routes, Policy
  │   ├─ Read PermSeeder, Views, Services, Requirements, Conditions
  │   └─ Note: Permission mismatches, XSS, missing routes, DDL gaps
  │
  ├─ Phase 1: Check MANUALTESTING
  │   ├─ YES → Merge into TcList (expand to 12 sections)
  │   │         Delete MANUALTESTING + orphan artifacts
  │   └─ NO  → Write TcList from scratch (12 sections)
  │
  ├─ Phase 2: Check Existing TestCas
  │   ├─ NO TestCas → Create V1
  │   ├─ V1 exists, no V2 → Create V2
  │   └─ V1 + V2 both exist → Upgrade Version
  │
  ├─ Phase 3: Add Missing Methods
  │   ├─ Schema (3) + Positive (16+) + Negative (12+) + Dependency (4+)
  │   └─ Follow existing method patterns
  │
  └─ Phase 4: Verify
      ├─ PHP lint: php -l {file}
      ├─ Method count check
      └─ Directory clean (only 2 files)
```
