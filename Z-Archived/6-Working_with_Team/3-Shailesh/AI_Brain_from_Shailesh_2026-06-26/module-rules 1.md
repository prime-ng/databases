# Module Development Rules — MANDATORY

## 🚫 NEVER ASSUME — ALWAYS ASK
- **Never assume anything.** If a question arises about the code, pattern, or approach — ASK the user first.
- Do not make decisions based on your own judgment. Follow exactly what the user instructs.
- If something is unclear, ask for clarification before proceeding.
- The user's actual code pattern is the SOURCE OF TRUTH — not the generic rule files.

## 🔴 GOLDEN RULE: NEVER TOUCH COMPONENT FILES
- 🚫 NEVER modify any component file — `<x-backend.*>`, `<x-frontend.*>`, or any file under `resources/views/components/` or `Modules/*/resources/views/components/`.
- 🚫 NEVER add/remove/change props, CSS, JS, or HTML inside component files.
- **What to do:** If a component doesn't do what you need, write the logic directly in your Blade view using plain HTML. Components are shared infrastructure — changing them breaks other modules.
- No exceptions. Ever.

## 🔴 MANUAL COMMAND EXECUTION ONLY
- **🚫 NEVER run database seeders, migrations, tinker scripts, or configuration commands directly.**
- **What to do:** Always explain the required commands or scripts to the user in the chat window so they can copy and execute them manually.


## Core Principles

1. **Every new feature MUST be built as a module inside `Modules/`.**
   - NEVER put new business logic directly in `app/` — only shared core utilities belong there.
   - The only exceptions: `app/Models/User.php`, `app/Helpers/`, `app/Providers/`, `app/Policies/`.

2. **Each module must be self-contained** with its own:
   - Routes (`routes/web.php`, `routes/api.php`)
   - Controllers (`app/Http/Controllers/`)
   - Models (`app/Models/`)
   - Migrations (`database/migrations/`)
   - Seeders (`database/seeders/`)
   - Services (`app/Services/`)
   - Form Requests (`app/Http/Requests/`)
   - Views (`resources/views/`)
   - Tests (`tests/`)
   - Providers (`app/Providers/`)

3. **Modules must avoid tight coupling.** Use:
   - Service container bindings for cross-module communication
   - Events and listeners for loose coupling
   - Contracts/interfaces for module APIs

## Module Creation

4. **Create a new module:**
   ```bash
   php artisan module:make ModuleName
   php artisan module:enable ModuleName
   ```

5. **Module naming convention:** PascalCase singular (e.g., `Student`, `Attendance`, `Examination`)

6. **Post-creation checklist:**
   - [ ] Verify `module.json` is correct
   - [ ] Service providers registered properly
   - [ ] Routes file exists and loads
   - [ ] Namespace matches folder structure

## Required Module Structure
```
Modules/ModuleName/
├── app/
│   ├── Http/
│   │   ├── Controllers/
│   │   │   └── ModuleController.php
│   │   ├── Requests/
│   │   │   ├── StoreModuleRequest.php
│   │   │   └── UpdateModuleRequest.php
│   │   └── Middleware/
│   ├── Models/
│   │   └── Module.php
│   ├── Services/
│   │   └── ModuleService.php
│   ├── Providers/
│   │   ├── ModuleServiceProvider.php
│   │   ├── RouteServiceProvider.php
│   │   └── EventServiceProvider.php
│   ├── Jobs/
│   └── Emails/
├── database/
│   ├── migrations/
│   └── seeders/
├── resources/
│   └── views/
├── routes/
│   ├── api.php
│   └── web.php
├── tests/
├── config/
├── composer.json
├── module.json
└── vite.config.js
```

## Coding Standards

7. **Controllers must be thin.** All business logic goes in Service classes.

8. **All input validation through Form Requests.** Never validate in controllers.

9. **Models define relationships, scopes, casts, and fillable.** No business logic in models.

10. **Services handle business logic.** Constructor injection for dependencies.

11. **Table naming:** Use module prefix convention (`tt_`, `std_`, `sch_`, etc.) matching the existing pattern.

## Route Registration

12. **Tenant module routes** are loaded via `routes/tenant.php` which includes module route files.

13. **Route naming convention:** `module-name.resource.action` (e.g., `smart-timetable.activity.store`)

14. **Middleware stack for tenant routes:**
    ```php
    Route::middleware(['auth', 'verified'])->group(function () {
        // Module routes here
    });
    ```

## Inter-Module Communication

15. **Use Events/Listeners** for cross-module side effects:
    ```php
    // In StudentProfile module
    event(new StudentEnrolled($student));

    // In Notification module (listener)
    class SendEnrollmentNotification {
        public function handle(StudentEnrolled $event) { ... }
    }
    ```

16. **Use service container** for cross-module data access:
    ```php
    // Register in ServiceProvider
    $this->app->bind(StudentServiceInterface::class, StudentService::class);

    // Resolve in another module
    $studentService = app(StudentServiceInterface::class);
    ```

## UI & CRUD Coding Conventions

17. **Form Layouts**: A **4-Column Layout** is strictly required for Create, Edit, and View pages. Do not alter this component structure. Use Bootstrap grids like `col-md-3`.

18. **Routing**: All CRUD operations must use standard Laravel resource routes (`Route::resource()`).

19. **Dropdowns**: Any form featuring the `Admission Cycle *` field MUST present it as a dropdown (`<select>`), never as a hidden or read-only input.

20. **Trash/Soft Deletes**: `trashed()`, `restore()`, and `forceDelete()` must be properly routed with standard resource names (e.g., `seats.trashed`, `quotas.trashed`) so the `x-backend.tab.search-bar` can dynamically detect and show the Trash button.

21. **Breadcrumbs**: All views must use the `x-backend.components.breadcrum` component with an empty `:links="[]"` array attribute by default.

22. **Data Integrity**: Enforce all DDL `UNIQUE` constraints (e.g., composite keys like `admission_cycle_id` + `class_id` + `quota_type`) and `DEFAULT` constraints strictly in Controller validation logic (using `Rule::unique()`) to prevent `SQLSTATE` database exceptions.

23. **Filters**: Ensure query scopes or filter logic (like `status`/`is_active`) are consistently applied across all tabs on index methods (e.g., in `AdmMenuController` when using `.when(request()->filled('status'), ...)`).

24. **Role & Permission Check Consistency (Gold Standard)**:
    > 📄 **Full Guide**: See `rules/permission-rules.md` for complete patterns, naming conventions, and checklists.
    - Wrap BOTH the column header (`<th>`) and body cells (`<td>`) in identical `@can` or `@canany` checks for **Status** and **Action** columns.
    - If a header is protected, the corresponding cells must be protected with the exact same permission gate check to prevent table grid misalignments and columns shifting.
    - Always use standard matching closing tags (e.g., `@canany` -> `@endcanany`).
    - Use `Gate::authorize('tenant.<slug>.<action>')` at the top of every Controller method.
    - Permission key format: `tenant.<module-slug>.<action>` (e.g. `tenant.vendor-item.forceDelete`).

---

## 📚 Cross-Reference Guide

| Topic | File |
|---|---|
| Full CRUD Code Templates (Routes + Controller + All Blade Views) | `rules/crud-patterns.md` |
| Tab-Based Hub Module Pattern (Section 2B) | `rules/crud-patterns.md` |
| **Module Structure** (directory, ServiceProvider, RouteServiceProvider, Policy, Model, FormRequest) | `rules/module-structure.md` |
| Role & Permission Blade Patterns, Naming, Checklists | `rules/permission-rules.md` |
| Laravel Framework Rules & Package Configs | `rules/laravel-rules.md` |
| Security & Auth Rules | `rules/security-rules.md` |



