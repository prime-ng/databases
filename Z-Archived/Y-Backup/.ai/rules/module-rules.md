# Module Development Rules — MANDATORY

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
