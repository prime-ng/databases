# Laravel Development Rules — MANDATORY

## Framework: Laravel 12.0 / PHP 8.2+

## 🔴 DDL → Validation Alignment Rule (CRITICAL)
- **DDL is the source of truth** — always check the LATEST DDL file before writing/modifying any CRUD.
- DDL `NOT NULL` → FormRequest MUST use `'required'` (never `'nullable'`)
- DDL `NULL` (nullable) → FormRequest MUST use `'nullable'` (never `'required'`)
- DDL has `DEFAULT` value → Model `$attributes` should match; FormRequest can omit `required`
- DDL `UNIQUE` constraint → FormRequest MUST use `Rule::unique()->ignore($id)->whereNull('deleted_at')`
- DDL composite `UNIQUE` on junction table (e.g., `(menu_id, item_id, category_id)`) → FormRequest MUST validate within-request uniqueness via `$validator->after()` closure checking for duplicate combo keys
- Verify EVERY column in the DDL is represented in: migration → model `$fillable` → model `$casts` → FormRequest rules → blade form inputs

## Architecture Rules

1. **Always use Service classes for business logic.** Controllers must stay thin — receive request, call service, return response.

2. **Always use Form Requests for input validation.** Never validate directly in controllers.
   ```php
   // WRONG
   public function store(Request $request) {
       $request->validate([...]);
   }

   // CORRECT
   public function store(StoreStudentRequest $request) {
       $validated = $request->validated();
   }
   ```

3. **Laravel 12 Gotcha — `$this->validate()` is NOT available.** The default `App\Http\Controllers\Controller` class is empty (no `ValidatesRequests` trait). Calling `$this->validate($request, $rules)` will throw "Call to undefined method" → HTTP 500. Use either:
   - `$request->validate($rules)` (inline, acceptable for simple AJAX endpoints)
   - Form Request classes (preferred for complex validation)
   ```php
   // NEVER — Laravel 12 base Controller lacks ValidatesRequests trait
   $this->validate($request, ['field' => 'required']);  // CRASHES

   // OK — inline request validation
   $validated = $request->validate(['field' => 'required']);

   // BEST — Form Request class
   public function store(StoreRequest $request) {
       $validated = $request->validated();
   }
   ```

   **Unique Constraint Handling in Form Requests:**
   - Always translate DB unique constraints (defined in DDL) into validation rules using Laravel's `Rule::unique()`.
   - During **edit/update operations**, ensure to ignore the current record's ID (`.ignore($id)`) so the constraint doesn't throw a validation error for the same record.
   - For composite unique constraints (e.g. unique `(parent_id, name)`), define the query condition inside the unique rule closure:
     ```php
     $uniqueRule = Rule::unique('table_name', 'name')
         ->where(fn($query) => $query->where('parent_id', $this->input('parent_id')));
     
     if ($id) {
         $uniqueRule = $uniqueRule->ignore($id);
     }
     ```

4. **Always use API Resources for JSON responses** when building API endpoints.

5. **Never modify existing migrations.** Always create new migrations for schema changes.
   ```bash
   # Add column
   php artisan make:migration add_column_to_table --path=database/migrations/tenant

   # NEVER edit an existing migration file
   ```

6. **Queue all heavy operations:**
   - Report generation
   - Bulk imports/exports
   - Email notifications
   - PDF generation for large batches
   - Timetable generation

7. **Use Events and Listeners for cross-module communication** instead of direct coupling.

## Package-Specific Rules

### Laravel Sanctum (v4.0)
- Use for API token authentication
- Token abilities for fine-grained API permissions
- `auth:sanctum` middleware on all API routes

### Spatie Laravel Permission (v6.21)
- Define roles and permissions in seeders
- Use `HasRoles` trait on User model
- Guard name must match: `'guard_name' => 'web'`
- Check permissions: `$user->can('permission-name')` or `@can('permission-name')` in Blade

### Spatie MediaLibrary (v11.17)
- Use `InteractsWithMedia` trait on models needing file uploads
- Define media collections in `registerMediaCollections()`
- Store tenant media in tenant-specific paths

### Maatwebsite Excel (v3.1)
- Create dedicated Import/Export classes
- Use queued imports for large files: `implements ShouldQueue`

### DomPDF (v3.1)
- Use for PDF generation (reports, receipts, certificates)
- Memory limit: watch for large PDFs, paginate if needed

### 🔴 Breadcrumb Rule (`x-backend.components.breadcrum`) — MANDATORY
- **ALWAYS use `:links="[]"` (empty array)** in EVERY blade view. NEVER hardcode route links inside the blade file.
- Breadcrumb navigation is managed **centrally** in `config/breadcrumb.php`:
  - `hub_map` — Maps URL segments to their parent/hub page
  - `tab_aliases` — Maps URL segments to tab IDs for tabbed pages
- If a new route/page needs breadcrumb support → add it to `config/breadcrumb.php`. **Never put route arrays in blade templates.**
- This rule applies to ALL blade files: create, edit, show, trash, index partials, and hub pages.

### UI Table and Page-Level Security Wrappers (`@can` & `@canany`)
> 📄 **Full Gold-Standard Guide**: See `rules/permission-rules.md` for complete patterns, examples, and checklists.

- **Always wrap both `<th>Action</th>` (or Status) and its corresponding `<td>` cell in identical `@can` or `@canany` checks**:
  - Hiding only the `<th>` header while rendering the `<td>` actions column breaks the table layout completely by offsetting the columns.
  - Wrap the actions column header `<th>` and the action data cells `<td>` inside the exact same `@canany` or `@can` check matching the resource permissions (e.g. `tenant.vendor.update`, `tenant.vendor.delete`, etc.).
  - This rule must be strictly applied in all **Index views** and **Trash views**.
- **ALWAYS use string-based `Gate::authorize('{module}.{resource}.{action}')`** — NEVER policy-based `Gate::authorize('create', Model::class)` or `Gate::authorize('view', $profile)`. String-based is the ONLY valid pattern.
- **Permission key format**: `{module}.{resource}.{action}` (e.g. `tenant.vendor-item.forceDelete`, `cafeteria.menu-items.create`).
- **Closing directive must match opening**: `@can` → `@endcan`, `@canany` → `@endcanany`. Never mix them.

## 🔴 Tab-Scoped Filter Rule (Multi-Tab Hub Controllers)
- **In tab-based hub controllers, ALWAYS scope filters by `$request->input('tab')`** — never apply search/status/date filters globally across all tabs.
- This prevents filter pollution (e.g., searching "Paratha" on the Menu Items tab should NOT affect the Weekly Menus tab data).
- Pattern:
  ```php
  $tab = $request->input('tab', 'default');
  $search = $request->input('search');
  $status = $request->input('status');

  // Each query checks tab match before applying filters
  $records = Model::query()
      ->when($tab === 'specific_tab' && $search, fn($q) =>
          $q->where('name', 'like', "%{$search}%")
      )
      ->when($tab === 'specific_tab' && $status !== null && $status !== '', fn($q) =>
          $q->where('is_active', $status)
      )
      ->paginate(15)->withQueryString();
  ```
- Apply to ALL query variables: `search`, `status`, `date_from`, `date_to`, `category_id`, etc.
- 📄 See `rules/crud-patterns.md` Section 2B-1 for the full pattern with private query methods.

## Query Rules

8. **Always eager load relationships** to prevent N+1 queries:
   ```php
   // WRONG
   $students = Student::all();
   foreach ($students as $student) {
       echo $student->guardian->name; // N+1!
   }

   // CORRECT
   $students = Student::with('guardian')->get();
   ```

8. **Use `when()` for conditional queries:**
   ```php
   Student::query()
       ->when($request->class_id, fn($q) => $q->where('class_id', $request->class_id))
       ->when($request->search, fn($q) => $q->where('name', 'like', "%{$request->search}%"))
       ->paginate(15);
   ```

10. **Chunk large datasets:**
   ```php
   Student::chunk(500, function ($students) {
       // Process batch
   });
   ```

## Error Handling

11. **Use try-catch in Service methods** with proper logging:
    ```php
    try {
        DB::beginTransaction();
        // operations
        DB::commit();
    } catch (\Exception $e) {
        DB::rollBack();
        \Log::error('Operation failed', ['error' => $e->getMessage()]);
        throw $e;
    }
    ```

12. **Catch SQLSTATE 23000 (Integrity Constraint Violation)** in controller `store()`/`update()` for duplicate entry errors:
    ```php
    use Illuminate\Database\QueryException;

    try {
        $this->service->create($request->validated());
        return redirect()->back()->with('success', 'Created successfully.');
    } catch (QueryException $e) {
        if ($e->getCode() === '23000') {
            return redirect()->back()->withInput()->with('error', 'Duplicate entry: ...');
        }
        throw $e;
    }
    ```

13. **Return meaningful error messages** in API responses.

## Testing

13. **Use Pest for testing** (project configured with Pest v4.1).
14. **Feature tests use `Tests\TestCase`** with `RefreshDatabase`.
15. **Unit tests use bare PHPUnit** (no Laravel app bootstrap).

## Performance

16. **Use database indexes** on all foreign keys and frequently queried columns.
17. **Use caching** for frequently accessed, rarely changed data (config, settings, menus).
18. **Use pagination** for all list endpoints — never return unbounded collections.

---

> 📄 **Full CRUD Code Templates (Routes + Controller + Blade Views)**: See `rules/crud-patterns.md`.
> 📄 **Full Role & Permission Blade Patterns**: See `rules/permission-rules.md`.

