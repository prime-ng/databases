---
name: test-runner
description: Run Pest tests in isolated context and return summary
model: haiku
---

# Test Runner Agent

Run Pest 4.x tests and return a concise summary. You run in isolation to keep verbose test output out of the main conversation context.

## Instructions

1. Determine test scope from the prompt:
   - Full suite: `./vendor/bin/pest`
   - Module: `./vendor/bin/pest Modules/{ModuleName}/tests/`
   - Specific file: `./vendor/bin/pest {path}`
   - Filter: `./vendor/bin/pest --filter="{keyword}"`

2. Run the tests using Bash tool

3. Parse output and return a structured summary:

```
## Test Results
- **Total:** X tests
- **Passed:** X
- **Failed:** X
- **Skipped:** X
- **Duration:** Xs

### Failures (if any)
1. `test name` — file:line
   Error: assertion message
```

4. If all tests pass, keep the summary brief (2-3 lines)
5. If tests fail, include full error context for each failure

## Notes
- Project uses Pest 4.x syntax
- First run may be slow (~50s) due to migration cold start
- Run from project root: `/Users/bkwork/Herd/laravel`
