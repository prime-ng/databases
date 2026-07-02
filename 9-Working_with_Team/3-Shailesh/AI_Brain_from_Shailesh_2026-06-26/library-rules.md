# Library Domain Rules — Custom & Session Learnings

## 1. Dynamic Configuration & Budget Settings (`lib_library_config`)

1. **Table name is `lib_library_config`** (renamed from `lib_library_settings` in V6 schema upgrade).
2. **Model Mapping**: `LibLibrarySetting` is the Laravel model, configured with:
   ```php
   protected $table = 'lib_library_config';
   ```
3. **Dynamic Budget**: The annual library budget must be fetched dynamically using the key `'LIBRARY_BUDGET'` from the settings table instead of hardcoded fallbacks:
   ```php
   $setting = LibLibrarySetting::where('setting_key', 'LIBRARY_BUDGET')->where('is_active', true)->first();
   $annualBudget = $setting ? (float)$setting->setting_value : 500000;
   ```
4. **Seeding Constraints**: Keep fine seeder keys (`LateReturn`, `LostBook`, `DamagedBook`, `ProcessingFee`) aligned with database triggers and events to avoid `UniqueConstraintViolationException` and query failures.

## 2. Master Config Settings Tab UI & CRUD Actions

5. **No Create / Delete Actions**: Library settings must only be updated inline; users cannot add new entries or delete them. Disable create/trash buttons by passing attributes to the search-bar component:
   ```html
   <x-backend.tab.search-bar disableCreate="true" disableTrash="true">
   ```
6. **Inline Dblclick Updates**: Handle inline dblclick updates on values and descriptions using AJAX PUT requests.
7. **Preserve Sibling Columns**: When updating a single field (e.g. `setting_value`), ensure the other field (`description`) is preserved in the PUT request data so it is not updated to null or empty in the database.
8. **Avoid empty parameters in named route generators**: Writing `route('library.lib-library-settings.update', ['id' => ''])` throws a runtime `UrlGenerationException` in Laravel. Instead, use the base `url()` helper:
   ```javascript
   url: '{{ url("library/library-settings") }}/' + settingId,
   ```
9. **Clear Button redirection**: Reset/Clear filters inside the settings tab must redirect back to the parent hub container with the correct tab parameter:
   ```html
   <a href="{{ route('library.historyIndex', ['tab' => 'library-settings']) }}" class="btn btn-secondary btn-sm">
   ```

## 3. Permission Consistency & Visibility (Spatie Permissions)

10. **Tab & Controller Consistency**: The settings tab check in the Blade view and the controller methods must check consistent permissions:
    - If tenant-specific permissions are not fully synchronized in cache for `tenant.lib-library-settings.viewAny`, map both to the existing transactions history permission (`tenant.lib-transactions-history.viewAny`) to ensure the tab does not disappear/remain hidden for the administrator.
    - Close view gates symmetrically (`@can` matches controller `Gate::authorize()`).

## 4. Dynamic Reports & Data Consistency (Acquisition & Dashboard)

11. **Zero Mock Data Policy**: Remove all fake/synthetic categories and random data generation (like `rand(x, y)`) from the report services. Calculate all numbers dynamically from database records.
12. **HTML & PDF Key Matching**: Ensure the final recommendations summary returned by the services has identical flat keys (e.g. both `category` and `name`, `items` and `count`, `estimated_cost` and `cost`) to match the rendering logic of both the web HTML templates and the PDF templates.
13. **Totals in Summary**: Flatten totals like `total_items`, `total_copies`, and `total_cost` to the root of the recommendations returned array so they display correctly in the table footer.
