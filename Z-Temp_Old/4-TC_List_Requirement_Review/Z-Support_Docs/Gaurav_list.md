- Model
    - Points to correct, existing table.
    - The fields are properly aligned and equivalent to migrations.
    - For softDelete, SoftDelete trait and for media upload InteractsWithMedia trait should be present.
    - All model relationships are properly defined and configured.
    - All fillable fields should be defined inside "protected $fillable".
 
- Controller
    - Imported classes do exist and at the used location
    - Gate authorization on every method
    - FormRequest validation rules, messages, prepareForValidation
    - Full CRUD flow (index, create, store, show, edit, update, destroy, trashed, restore, forceDelete)
    - Toggle status AJAX endpoint
    - Activity logging
    - Boolean field handling (checkbox → prepareForValidation)
    - Redirect patterns with flash messages
    - Error handling (404, 403, validation, business logic)

- FormRequests
    - rules() — all rule types (required/nullable, type, size, exists/unique, comparison, specific values)
    - messages() — custom error messages via dot notation
    - attributes() — custom attribute name replacements
    - prepareForValidation() — boolean conversion, checkbox detection, field derivation
    - Route model binding in rules
    - Conditional create vs update rules
    - Validation rule combinations (chained constraints)
 
- Migration
    - Migration class structure (up() / down())
    - All the fields from DDL
    - Data types should match with DDL
    - Precise length and default type of fields
    - Schema creation (table naming, column types, modifiers, timestamps, FKs, indexes)
    - Soft deletes pattern
    - FK->PK compatibility check
    - Rollback safety (down() method, hasColumn guards)
    - Required timestamps (created_at, updated_at, softDeletes())

- Routes
    - Resource routes (for full CRUD flow (index, create, store, show, edit, update, destroy, trashed, restore, forceDelete))
    - All routes are assigned proper controllers and methods.

- Policy & Permission
    - Policy class structure, all standard methods
    - Permission naming conventions (tenant.feature.action)
    - Gate authorization in controllers
    - Permission registration (config/permissionslist.php)
    - Role-permission assignment
    - Permission checking in views (@can, @canany)
    - Model registration in AuthServiceProvider
 
 
- Views
    - Layout & structure (layout component, session alerts, CSRF meta)
    - Breadcrumbs
    - Error display ($errors->any() → alert-danger)
    - Form elements (create vs edit patterns, old input, method spoofing)
    - Form components (x-backend.form.*)
    - Index views (table, actions, status switch, search/filter)
    - Show views (detail table, null-safe display, status badges)
    - Trash views (soft-deleted records, restore/force-delete actions)
    - Authorization (@can, @canany)
    - Old input repopulation
    - JavaScript behavior (dependent dropdowns, AJAX toggles)
    - Pagination
 