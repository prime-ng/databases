# Laravel Development Rules — MANDATORY

## Framework: Laravel 12.0 / PHP 8.2+

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

3. **Always use API Resources for JSON responses** when building API endpoints.

4. **Never modify existing migrations.** Always create new migrations for schema changes.
   ```bash
   # Add column
   php artisan make:migration add_column_to_table --path=database/migrations/tenant

   # NEVER edit an existing migration file
   ```

5. **Queue all heavy operations:**
   - Report generation
   - Bulk imports/exports
   - Email notifications
   - PDF generation for large batches
   - Timetable generation

6. **Use Events and Listeners for cross-module communication** instead of direct coupling.

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

## Query Rules

7. **Always eager load relationships** to prevent N+1 queries:
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

9. **Chunk large datasets:**
   ```php
   Student::chunk(500, function ($students) {
       // Process batch
   });
   ```

## Error Handling

10. **Use try-catch in Service methods** with proper logging:
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

11. **Return meaningful error messages** in API responses.

## Testing

12. **Use Pest for testing** (project configured with Pest v4.1).
13. **Feature tests use `Tests\TestCase`** with `RefreshDatabase`.
14. **Unit tests use bare PHPUnit** (no Laravel app bootstrap).

## Performance

15. **Use database indexes** on all foreign keys and frequently queried columns.
16. **Use caching** for frequently accessed, rarely changed data (config, settings, menus).
17. **Use pagination** for all list endpoints — never return unbounded collections.
