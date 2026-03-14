---
name: test
description: Run Pest tests for a specific module, file, or the entire project
user_invocable: true
---

# /test — Run Tests

Run Pest tests and report results.

## Usage
- `/test` — Run all tests
- `/test ModuleName` — Run tests for a specific module
- `/test path/to/TestFile.php` — Run a specific test file
- `/test --filter="test name"` — Run tests matching a filter

## Steps

1. Determine the test scope from the argument:
   - No argument: run all tests
   - Module name (e.g., `SmartTimetable`): run `./vendor/bin/pest Modules/SmartTimetable/tests/`
   - File path: run `./vendor/bin/pest {path}`
   - Filter string: run `./vendor/bin/pest --filter="{filter}"`

2. Run the tests:
   ```bash
   ./vendor/bin/pest {scope} --colors=always
   ```

3. Analyze the output:
   - Report total tests, passed, failed, skipped
   - For failures: show the test name, assertion message, and file:line
   - Suggest fixes for common failures

4. If tests fail, offer to fix the issues.

## Notes
- This project uses Pest 4.x (not PHPUnit class-based)
- Tenant tests require test databases to be set up
- First run may be slow (~50s) due to SQLite migration cold start
