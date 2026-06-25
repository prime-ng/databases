# Testing Architect — Enhancement & Feedback Prompts
# Prime-AI Platform
# Created: 2026-06-22
#
# PURPOSE:
# This file contains ready-to-paste prompts to:
#   (A) Set quality expectations at the start of a new testing session
#   (B) Correct the agent when output is wrong, pseudo-code, or incomplete
#
# HOW TO USE:
#   After activating: "act as Testing Architect"
#   Paste PROMPT A immediately to set the quality bar.
#   If the agent produces wrong output, paste the matching PROMPT B-x correction.
# ============================================================

---

## PROMPT A — Session Onboarding (paste at the start of EVERY testing session)

```
Before you write any tests, read and confirm you understand these output quality rules.
I will reject your output and ask you to redo it if any of these are violated.

### Rule 1 — Write REAL Pest 4.x code. Not pseudo-code. Not "something like this".
Every test must:
- Have a proper `uses(Tests\TenantTestCase::class)` or `uses(Tests\TestCase::class)` declaration
- Import all classes used (Student::class, FeeInvoice::class, etc.)
- Have real assertions (assertOk, assertForbidden, assertDatabaseHas, assertJsonStructure)
- Be syntactically valid PHP — I will run it directly without editing

WRONG:
  test('parent cannot book wrong slot', function () {
      // create a parent, create a wrong slot, try to book it
      // assert forbidden
  });

RIGHT:
  test('parent cannot book a PTM slot outside their child class section', function () {
      $parent   = User::factory()->parent()->withChild(['class_id' => 5])->create();
      $wrongSlot = PtmSlot::factory()->create(['class_id' => 7]);
      $this->actingAs($parent)
           ->post(route('ptm.slots.book', $wrongSlot))
           ->assertForbidden();
  })->group('security', 'regression', 'SEC-PPT-003');

### Rule 2 — ALWAYS use TenantTestCase for tenant data. Never plain TestCase.
Any test that touches: students, fees, attendance, PTM, hostel, library, feedback, timetable, or
any module that stores school-specific data MUST use Tests\TenantTestCase.
Using Tests\TestCase for tenant data will query the wrong database and tests will falsely pass.

### Rule 3 — ALWAYS verify the route exists before writing a test for it.
Run: php artisan route:list | grep "route.name"
If the route does not exist, say so. Do not write a test for a non-existent route.

### Rule 4 — Test the RIGHT thing. Authorization tests must prove DENIAL, not just acceptance.
An authorization test that only checks "correct user can access" is incomplete.
Every authorization test must have at least:
  - Test that unauthenticated → 302 redirect to /login (or 401 for API)
  - Test that wrong role → 403 Forbidden
  - Test that correct role → 200 OK (happy path)
  - Test IDOR: user with correct role but WRONG ownership → 403

### Rule 5 — Group every test correctly.
All tests must have a ->group() tag:
  ->group('security')           for auth/IDOR tests
  ->group('regression', 'CODE') for tests mapped to a known-issues.md entry
  ->group('smoke')              for basic route-existence tests
  ->group('tenancy-isolation')  for cross-tenant tests
  ->group('performance')        for DB query count tests

### Rule 6 — Update known-issues.md after writing regression tests.
For every known-issue code you write a test for, append to that row in known-issues.md:
  | CODE | **TEST WRITTEN** | `tests/Feature/Modules/{Module}/AuthorizationTest.php:{line}` |

### Rule 7 — Tell me what you cannot test yet.
If a module has no Factories, say: "Factory missing for [Model] — test stubs written but need factory."
If a route needs a specific setup that is unclear, ask before writing a broken test.
Never write a test that silently always passes because the setup is wrong.

### Rule 8 — One test file per concern, not one giant file.
AuthorizationTest.php      — only auth/IDOR tests
{Resource}CrudTest.php     — only CRUD happy paths + validation
{Resource}BusinessTest.php — only business rule invariants
TenantIsolationTest.php    — only cross-tenant data leak tests

Confirm you have read these rules by replying:
"Quality rules understood. Ready to write tests. What module or task first?"
```

---

## PROMPT B — Correction Prompts (paste when agent makes a specific mistake)

---

### B-1 — Agent wrote pseudo-code / placeholder comments
```
This is pseudo-code, not a real Pest test:
[paste the pseudo-code test]

Rewrite it as a real, runnable Pest 4.x test. Requirements:
1. uses() declaration at the top of the file
2. All classes imported with use statements
3. Factory calls that actually create the records
4. Real HTTP calls using $this->get/post/put/delete
5. Real assertions (assertOk, assertForbidden, assertDatabaseHas, assertJsonFragment)
6. ->group() tag

Do not use comments like "// arrange" or "// assert" as placeholders.
Write the actual code.
```

---

### B-2 — Agent used TestCase instead of TenantTestCase for tenant data
```
This test uses Tests\TestCase but it touches tenant data ([Student/FeeInvoice/etc.]).
That means it will query the wrong database and may silently pass even if broken.

Fix: Change uses(Tests\TestCase::class) to uses(Tests\TenantTestCase::class).
Also add $this->actingAs($this->tenantAdmin) in beforeEach if missing.

Rewrite the test with the correct base class.
```

---

### B-3 — Agent wrote a test for a route that doesn't exist
```
The route [route name or URL] does not exist. I checked with:
  php artisan route:list | grep "[name]"

Do not write a test for a non-existent route. Instead:
1. Check what the actual route name is for this feature
2. If the route truly doesn't exist, flag it as BUG (missing route) instead of writing a test
3. Rewrite the test using the correct, verified route name
```

---

### B-4 — Agent wrote an authorization test that only tests the happy path
```
Your authorization test only proves that an authorized user CAN access the resource.
That is not sufficient. An authorization test must prove DENIAL.

Add these missing cases to [TestFile]:
1. Unauthenticated → assertRedirect('/login') or assertUnauthorized()
2. Wrong role (use a [student/teacher/parent] instead of admin) → assertForbidden()
3. IDOR case — correct role but WRONG record ownership → assertForbidden()

Without these three cases, the test gives false confidence.
```

---

### B-5 — Agent forgot to add ->group() tags
```
Your tests are missing ->group() tags. This means they won't be filtered correctly in CI.

Add the correct group to each test:
- Auth/IDOR tests → ->group('security')
- Regression tests for known-issues → ->group('regression', '[CODE]')
- Basic route smoke tests → ->group('smoke')
- Cross-tenant tests → ->group('tenancy-isolation')

Update the tests now and show me the corrected versions.
```

---

### B-6 — Agent did not update known-issues.md after writing regression tests
```
You wrote regression tests for [CODE1], [CODE2], [CODE3] but did not mark them in known-issues.md.

For each code, open known-issues.md and append to that row:
  | CODE | **TEST WRITTEN** | `[full path to test file]:[line number]` |

Run: grep -n "CODE" /Users/bkwork/WorkFolder/1-Old_PrimeDB/old_db/AI_Brain/lessons/known-issues.md
Find the exact line, then use Edit to update it.

Do this now and confirm each code is marked.
```

---

### B-7 — Agent wrote tests without proper assertions (only assertOk)
```
assertOk() alone is not enough. It only proves the route returns 200 — not that it did the right thing.

For every CRUD test, also assert the database state changed:
  $this->assertDatabaseHas('table_name', ['field' => $value]);   // after create/update
  $this->assertDatabaseMissing('table_name', ['id' => $id]);     // after delete

For API tests, also assert the response structure:
  ->assertJsonStructure(['data' => ['id', 'name', 'status']])
  ->assertJsonFragment(['status' => 'active'])

Rewrite the following tests to add database/JSON assertions:
[list the test names]
```

---

### B-8 — Agent put all tests in one huge file
```
All tests should NOT be in one file. Separate by concern:

Move auth/IDOR tests to:     tests/Feature/Modules/[Module]/AuthorizationTest.php
Move CRUD tests to:          tests/Feature/Modules/[Module]/[Resource]CrudTest.php
Move business logic tests to: tests/Feature/Modules/[Module]/[Resource]BusinessTest.php
Move isolation tests to:     tests/Feature/Modules/[Module]/TenantIsolationTest.php

Split the current file accordingly and show me the new file structure.
```

---

### B-9 — Agent wrote a test that will always pass (false positive)
```
This test will always pass regardless of whether the bug is fixed:
[paste the test]

The problem: [explain — e.g., "the factory creates the record as the wrong user so assertForbidden 
will always be true even if auth is broken" OR "assertOk will pass even if the view has an error 
because Laravel catches it silently"]

Rewrite it so that:
1. If I remove the Gate::authorize() call from the controller, THIS TEST FAILS
2. If I add the Gate::authorize() call back, THIS TEST PASSES

That is the only way to prove the test actually validates the security control.
```

---

### B-10 — Agent wrote tests for the wrong database layer
```
Your test for [Module] uses RefreshDatabase at the top-level but this will wipe global_db.

NEVER use `use Illuminate\Foundation\Testing\RefreshDatabase` directly at the top of a tenant test.
Use Tests\TenantTestCase instead — it handles database refreshing correctly for the tenant layer only.

Also: global_db tables (sys_dropdowns, glb_boards, glb_states) must NOT be truncated in tests.
If your test needs reference data, seed it via a Seeder in TenantTestCase::setUp(), not by creating factory records.

Fix the test class to extend TenantTestCase and remove the standalone RefreshDatabase trait.
```

---

### B-11 — Agent did not verify route exists before writing the test
```
Before writing any more tests for this module, run:
  php artisan route:list --path="[module-prefix]" 2>/dev/null

Show me the output. I will tell you which routes to target.
Only write tests for routes that appear in that output.
If a route is registered but the controller method is missing (BUG P0), 
write a smoke test that asserts the route returns 200 (which will FAIL and prove the bug),
not a test that assumes the method exists.
```

---

### B-12 — Agent wrote tests but the module has no factories yet
```
The tests you wrote depend on [Model]::factory() but I don't think a factory exists for this model.

Check:
  ls /Users/bkwork/Herd/prime_ai/Modules/[Module]/database/factories/

If the factory does not exist:
1. Write the factory file first: [Module]/database/factories/[Model]Factory.php
2. Only then write the tests that use it

Or if writing the factory is out of scope, note clearly which tests are STUBS 
that need factories before they can run, so I know not to execute them yet.
```

---

## PROMPT C — End-of-Session Quality Check

```
Before I close this session, run this final checklist and confirm each item:

[ ] All tests use real Pest 4.x syntax — no pseudo-code, no placeholder comments
[ ] Tenant tests use Tests\TenantTestCase, not Tests\TestCase
[ ] Every authorization test covers: unauthenticated, wrong-role, IDOR, and correct-role
[ ] Every test has a ->group() tag
[ ] Tests for known-issues codes are tagged ->group('regression', 'CODE')
[ ] known-issues.md is updated with TEST WRITTEN for each covered code
[ ] Test files are separated by concern (AuthorizationTest, CrudTest, BusinessTest, etc.)
[ ] All tests have real assertions beyond just assertOk() or assertForbidden()
[ ] No test depends on a factory that doesn't exist (or factory was created in this session)

Show me:
  find /Users/bkwork/Herd/prime_ai/tests/Feature/Modules/[Module] -name "*Test.php"

Confirm each file was written and list the number of tests inside each.
```

---

## PROMPT D — Ask Agent to Self-Review Its Own Output

```
Before I review your output, do a self-review first.

For each test you just wrote, ask yourself:
1. If I delete the Gate::authorize() call from the controller, does this test FAIL? (It must.)
2. If I change the model binding to not scope to the tenant, does the isolation test FAIL? (It must.)
3. Is every assertForbidden actually reachable, or does the request redirect before hitting the controller?
4. Did I import every class used in this file with a use statement at the top?
5. Did I call tenancy()->initialize() anywhere it's needed, or does TenantTestCase handle it?

Report what you found. Fix any tests that fail your own review before showing me.
```
