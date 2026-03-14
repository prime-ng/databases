# Code Style Rules

## Standard: PSR-12

## Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Controller | PascalCase + `Controller` | `StudentController` |
| Service | PascalCase + `Service` | `StudentService` |
| Model | PascalCase singular | `Student` |
| Form Request | Action + Model + `Request` | `StoreStudentRequest` |
| API Resource | PascalCase + `Resource` | `StudentResource` |
| Policy | PascalCase + `Policy` | `StudentPolicy` |
| Event | PascalCase past tense | `StudentEnrolled` |
| Listener | PascalCase action | `SendEnrollmentNotification` |
| Job | PascalCase action | `ProcessStudentReport` |
| Migration | Snake_case descriptive | `create_students_table` |
| Table | prefix_snake_case plural | `std_students` |
| Column | snake_case | `first_name`, `class_id` |
| Route name | dot-separated | `student.profile.update` |
| Config key | snake_case | `smart_timetable.verbose_logging` |
| Variable | camelCase | `$studentData`, `$academicSession` |
| Constant | UPPER_SNAKE_CASE | `MAX_RETRY_COUNT` |

## Method Rules

1. **Methods must be small and single-purpose.** If a method exceeds 30 lines, consider extracting helpers.

2. **All public methods must have docblocks:**
   ```php
   /**
    * Store a newly created student.
    *
    * @param StoreStudentRequest $request
    * @return \Illuminate\Http\RedirectResponse
    */
   public function store(StoreStudentRequest $request)
   ```

3. **No business logic in controllers, models, or routes.** Controllers call services. Models define data structure. Routes define endpoints.

4. **Use meaningful variable names — no abbreviations:**
   ```php
   // WRONG
   $s = Student::find($id);
   $cls = SchoolClass::all();

   // CORRECT
   $student = Student::find($id);
   $classes = SchoolClass::all();
   ```

## File Organization

5. **One class per file.** Exception: small value objects or enums can share a file.

6. **Imports ordered:** PHP native → Laravel → Spatie → Module → Same module

7. **Method ordering in controllers:**
   1. `index`
   2. `create`
   3. `store`
   4. `show`
   5. `edit`
   6. `update`
   7. `destroy`
   8. Custom methods

## Code Quality

8. **Use type hints** for all method parameters and return types.

9. **Use `strict_types` declaration** in new PHP files:
   ```php
   <?php declare(strict_types=1);
   ```

10. **Use null coalescing** instead of ternary for defaults:
    ```php
    // Preferred
    $name = $data['name'] ?? 'Unknown';
    ```

11. **Use arrow functions** for simple callbacks:
    ```php
    $names = $students->map(fn($s) => $s->name);
    ```

12. **Use early returns** to reduce nesting:
    ```php
    // WRONG
    if ($condition) {
        // 20 lines of code
    }

    // CORRECT
    if (!$condition) {
        return;
    }
    // 20 lines of code
    ```

## Match Existing Codebase

13. **Follow the patterns already established in existing modules.** When in doubt, look at how `SchoolSetup` or `SmartTimetable` modules implement similar features.

14. **Use Laravel Pint** (`laravel/pint` v1.24) for code formatting:
    ```bash
    ./vendor/bin/pint
    ```
