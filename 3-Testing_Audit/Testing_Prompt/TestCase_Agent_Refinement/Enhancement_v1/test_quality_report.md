# Test File Quality Report — Agent Enhancement Guide

We have collected some Issue in TestCase Files while creating TestCases using "TestCase Creator" Agent. Below are some important Paths which has been refered in below Mistakes, which needs to be correct in TestCases Creator Agent.

TestCase Files for different Modules :
MAIN_TestCase_Files_Folder = "Users/bkwork/Herd/prime_testing/tests/Browser/Modules"/{MODULE_NAME}
HOSTEL_Testcase_Files = "prime_testing/tests/Browser/Modules/Hostel"
INVENTORY_Testcase_Files = "prime_testing/tests/Browser/Modules/Inventory"

DDL_SCHEMA_FILES = "old_db/2-DDL_Tenant_Consolidated"
ENHANCED_DDL_FILES = "old_db/2-DDL_Tenant_Enhanced"


## Mistake #1

**The problem:**  
The test looks like it is checking something, but it never actually checks.  
It just says "I did something, count it as a test" — without verifying the result.

**Real-life example:**  
Imagine you ask a security guard:  
"Did you check if the door is locked?"  
The guard says: "I walked to the door. ✅"  
But the guard never actually tried to open the door to see if it is locked.  

That is what `addToAssertionCount(1)` does — it walks to the door but never tries the handle.

**Where it happens:**  
In the 403 (permission) tests, the test:
1. Removes the user's permission
2. Visits the page
3. Adds the permission back
4. Says "I checked it" — ✅ (without ever verifying that the page returned 403 Forbidden)

**Files affected:** 12+ Hostel test files (Bed, BedType, RoomType, Floor, Room, StatusMaster, Hostel, EmergencyContact, WardenAssignment, FeeDemands, FeeStructures, and more)

**What the correct test should do:**  
After visiting the page, the test must check:  
"Did the server return error 403 (forbidden)?" — if yes, the test passes.

**Rule for the agent:**  
> `addToAssertionCount(1)` is NEVER allowed. Every test method must have a real assertion like `assertEquals(403, $statusCode)` or `assertSee('error')`.

---

## Mistake #2 — Using a method that does not exist

**The problem:**  
The test calls a function that does not exist in Laravel.  
PHP crashes immediately before the test even starts.

**Real-life example:**  
You tell your car: "Open the sunroof."  
But your car does not have a sunroof.  
Nothing happens — the car just beeps an error.  

Similarly, the test says:  
`$model->isCasted('is_active')` — but `isCasted()` does not exist in Laravel 12.  
The correct method name is `hasCast()`.

It is like saying "turn on the windscreen wiper fluid" — but the actual button is labeled "windshield washer".  
Same function. Wrong name. Nothing works.

**Where it happens:** 7+ Hostel test files (BedType, RoomType, StatusMaster, WardenDutyRoster, RoomReservation, Attendance, NotificationLog)

**Files affected:**
- `hst_BedType_TestCas.php`
- `hst_RoomType_TestCas.php`
- `hst_StatusMaster_TestCas.php`
- `hst_WardenDutyRoster_TestCas.php`
- `hst_RoomReservation_TestCas.php`
- `hst_Attendance_TestCas.php`
- `hst_NotificationLog_TestCas.php`

**Rule for the agent:**  
> In Laravel 12, there is NO method called `isCasted()`. The correct method is `hasCast()`.  
> Before using any Laravel method, check the official Laravel 12 documentation to confirm it exists.

---

## Mistake #3 — Forgetting to refresh the record after creating it

**The problem:**  
The test creates a record in the database, then immediately checks a value —  
but the value was not loaded from the database yet.

**Real-life example:**  
You go to a restaurant and order a pizza.  
The waiter writes down your order and hands you the paper slip.  
You look at the paper slip and say: "Where is the pizza?"  
The pizza is in the oven — it exists in the kitchen (database), but the paper slip (the variable in your hand) does not show it yet.

You need to wait for the pizza to come out of the oven first.  
In code, `->refresh()` means: "Go back to the kitchen and get the latest version."

**What happens in the test:**
```php
$room = Room::create(['floor_id' => 1, 'room_number' => '101']);
// The database set is_active = 1 automatically (as default)
// But $room in the code still has is_active = null
$this->assertEquals(1, $room->is_active); // FAILS because $room still shows null
```

**The fix:**
```php
$room = Room::create(['floor_id' => 1, 'room_number' => '101']);
$room->refresh(); // Go back to DB and get the actual saved values
$this->assertEquals(1, $room->is_active); // PASSES
```

**Files affected:** 6+ files (Room, Floor, VisitorLog, Housekeeping, StockItem, Quotation)

**Rule for the agent:**  
> ALWAYS call `->refresh()` on a model after `->create()` before checking any database default values.

---

## Mistake #4 — The test says "403" but never checks that 403 was returned

**The problem:**  
The test removes a user's permission, visits the page, restores the permission.  
But it never actually checks whether the page returned "Forbidden" (403).

**Real-life example:**  
You give your friend a key to a locked room.  
Then you take the key back.  
Your friend walks to the door and tries to open it.  
You say: "I checked if he could open it. ✅"  
But you never looked at the door — you don't know if it opened or stayed locked.

**Where it happens:** Same as Mistake #1 — 12+ Hostel files.

**Additional problem:**  
After taking away the permission, the permission cache still remembers the old permission.  
It is like: You tell the system "this person no longer has access", but the guard is asleep and still lets them in.  
You must wake the guard by calling `forgetCachedPermissions()`.

**Rule for the agent:**  
> After `revokePermissionTo()`, ALWAYS call `app(PermissionRegistrar::class)->forgetCachedPermissions()`.  
> After visiting the URL, ALWAYS assert `$this->assertEquals(403, $responseStatusCode)`.

---

## Mistake #5 — Exact seed data counts

**The problem:**  
The test expects exactly "5 bed types" or "30 floors".  
But if any other test runs first and leaves extra data, the count becomes "6" or "31" — and the test fails.

**Real-life example:**  
You have a bag of exactly 5 apples.  
You count them and say "There must always be exactly 5 apples."  
But someone else put 2 more apples in the bag earlier.  
Now there are 7 apples. Your count fails — even though nothing is actually wrong.

**Files affected:** 12+ Inventory test files (StockLedger, StockIssue, IssueRequest, Adjustment, AssetRegister, GRN, Quotation, PurchaseRequisition, PurchaseOrder, Uom, StockGroup, Maintenance)

**Rule for the agent:**  
> Use `assertGreaterThanOrEqual()` instead of `assertEquals()` for seed counts.  
> Example: `$this->assertGreaterThanOrEqual(5, BedType::count())`.

---

## Mistake #6 — Wrong URL path (forgetting the module prefix)

**The problem:**  
The test visits `/fee-structures` but the actual URL is `/hostel/fee-structures`.  
The page never loads — it returns "404 Not Found" — and every test fails.

**Real-life example:**  
You are told: "Go to Shop 5 in the mall and buy bread."  
You go to Shop 5 — but it is a shoe store.  
You come back and say "There is no bread in that shop."  
The problem is not the shop — the bread is in Shop 5 of the **food court**, not the main corridor.  
You went to the wrong location.

**Files affected:** Hostel (FeeStructures uses `/fee-structures` instead of `/hostel/fee-structures`, FeeDemands uses `/fee-demands` instead of `/hostel/fee-demands`)  

**Impact:** ~20 tests that all fail due to this single mistake

**Rule for the agent:**  
> Before writing URL paths, check the actual route file or run `php artisan route:list | grep <module>` to see the real path.

---

## Mistake #7 — The test creates records but never cleans up

**The problem:**  
Each test creates data (new records in the database) but does not delete them afterward.  
Over time, leftover data accumulates.  
The next test run sees old data + new data and gets wrong counts or duplicate errors.

**Where it happens:** Almost every test file in Inventory and Hostel modules.

**Rule for the agent:**  
> Every test that creates a record must delete it afterward, or use `RefreshDatabase` trait,  
> or wrap the test in `try/finally` with cleanup in the `finally` block.

---

## Mistake #8 — Missing the `media` table in the test database

**The problem:**  
Some modules use a feature called "Media Library" (for uploading images, documents, etc.).  
This feature needs a `media` table in the database.  
The `media` table exists in the main database but NOT in the test database.  
Whenever a test triggers media-related code, the database says "table not found" and crashes.

**Files affected:** 8+ files across StudentProfile and Hostel modules

**Rule for the agent:**  
> When a model uses the `InteractsWithMedia` trait, the test environment must have the `media` table.  
> Always check: does the model use media library? If yes, ensure the migration is included in the test database setup.

---

## Mistake #9 — Not initializing the tenant context before tests

**The problem:**  
The application uses "multi-tenancy" — data is separated for each customer/school.  
Before any test can access data, it must first tell the system "we are working with this customer."  
Some tests forget this step entirely. Others do it incorrectly.

**Real-life example:**  
You walk into a hotel and ask for "Room 201".  
The receptionist asks: "Which hotel?"  
You only said the room number, not the hotel name.  
The receptionist cannot help you because they do not know which hotel you are in.

In the same way, the test says "give me student data" but does not first say "this is the school we are working with" — and the system cannot find the data.

**Files affected:** Admission tests (MeritLists, EntranceTests, Withdrawals, Applications — method entirely missing; Enquiries — calls the method but passes empty/null tenant ID)

**Rule for the agent:**  
> Every test class must call `$this->initializeTenantContext()` at the end of `setUp()`.  
> Use the correct implementation: `tenancy()->initializeByDomain($domain)` — NOT `tenancy()->initialize(tenant())`.

---

## Mistake #10 — Copy-pasting the same helper code into 40 files

**The problem:**  
Every test file redefines the same 15+ helper methods identically.  
A file contains:
- `authenticateBrowserSession()` — 40 copies
- `initializeTenantContext()` — 40 copies
- `tenantUrl()` — 40 copies
- `responseStatusCode()` — 40 copies
- ... and so on

If you need to fix one helper, you must fix it 40 times.  
Inevitably, some files get the fix and some do not — causing inconsistent behavior.

**Rule for the agent:**  
> Create ONE shared trait (like `TenantTestSetup`) with all common helpers.  
> Every test file should `use TenantTestSetup;` — not re-copy the methods.  
> If a helper appears in more than 2 files, extract it.

---

## Mistake #11 — Forgetting the CSRF token in AJAX calls

**The problem:**  
Some tests send AJAX requests from the browser (like submitting a form in the background).  
But they forget to include the CSRF token — a security token that Laravel requires.  
The server rejects the request with a 500 error.

**Rule for the agent:**  
> Every `fetch()` or AJAX call from a browser test must include the CSRF token in the headers:  
> `'X-CSRF-TOKEN': csrf_token` and `'X-Requested-With': 'XMLHttpRequest'`.

---

## Mistake #13 — Calling `isActive()` as if it were an instance method (it is not)

**The problem:**  
The test calls `$model->isActive('is_active')` — but `isActive()` does NOT exist as an instance method on Eloquent models.  
There is only `scopeActive()` — a query scope, not an instance method.  
PHP crashes with `BadMethodCallException`.

**Real-life example:**  
Same as Mistake #2 (sunroof).  
You tell the car: "Turn on the headlight washer."  
The car does not have a headlight washer. It has windshield washer.  
Wrong name. Nothing works.

**Files affected:**
- `hst_RoomType_TestCas.php:71` — calls `$model->isActive('is_active')`
- `hst_RoomInventory_TestCas.php:82` — calls `$model->isActive('is_active')`

**Rule for the agent:**  
> There is no `isActive()` instance method on Eloquent models.  
> To check if a model has an active scope, use `$model->hasCast('is_active')` instead.  
> To use the scope, call `Model::active()->get()`.

---

## Mistake #14 — Creating users without required fields (SQL strict mode error 1364)

**The problem:**  
Tests create `User` records but forget to provide fields like `short_name` or `prefered_language`.  
The `sys_users` table requires these columns (NOT NULL, no default value).  
MySQL in strict mode rejects the insert with error `1364: Field 'short_name' doesn't have a default value`.

**Real-life example:**  
You are filling out a form to create a new employee record.  
The form has a field "Short Name (required)" but you leave it blank.  
You click Submit. The system says "Short Name is required."  
The test forgot to fill in a required field.

**Where it happens:**
- `short_name` missing: Admission Allotment test, Vendor Invoice test
- `prefered_language` missing: StudentProfile StudentLeaveType test
- `academic_session_id` missing: Admission Enrollment, FollowUp tests

**Rule for the agent:**  
> When creating a User record in a test, ALWAYS include ALL required fields.  
> Check the database migration to see which columns are NOT NULL without defaults.  
> Minimum safe user creation payload:  
> ```php
> $user = User::create([
>     'name' => 'Test User',
>     'email' => 'test@example.com',
>     'password' => bcrypt('password'),
>     'short_name' => 'Test',
>     'prefered_language' => 'en',
> ]);
> ```

---

## Mistake #15 — Empty test stubs that test nothing

**The problem:**  
Some test methods are completely empty except for `$this->addToAssertionCount(1)`.  
They were written as placeholders but were never actually implemented.  
The test passes without testing anything — it's invisible.

**Real-life example:**  
A restaurant menu lists "Grilled Salmon" with a full description and price.  
You order it. The waiter comes back 20 minutes later and says "Here is your bill."  
You say "Where is the salmon?"  
The waiter says "Oh, we never actually cook that dish. We just list it on the menu."

The test name says "test_validation_field_required" but it never actually checks if validation happens.

**Files affected:** Hostel (Floor, LeavePass, IncidentWarnings, SickBay — dozens of stub methods), Inventory (multiple files), DepartmentDesignation

**Examples found:**
```php
public function test_validation_hostel_id_required(): void
{
    $this->addToAssertionCount(1);  // Tests nothing!
}

public function test_validation_floor_number_integer(): void
{
    $this->addToAssertionCount(1);  // Tests nothing!
}
```

**Rule for the agent:**  
> NEVER write a test method that only contains `$this->addToAssertionCount(1)`.  
> Either implement the test properly, or use `$this->markTestIncomplete('Reason')` if it's intentionally pending.  
> Empty tests are worse than no tests — they create false confidence.

---

## Mistake #16 — Wrong HTML element selectors in browser tests

**The problem:**  
The test looks for a specific HTML element on the page, but the page uses a different element type.  
For example:
- The test waits for a `<table>` element, but the page renders data in cards (`<div class="card">`)
- The test clicks a button labeled "Save", but the button says "Submit" or "Create"
- The test looks for a `<select>` dropdown named `vendor_id`, but the form uses a text input with autocomplete

**Real-life example:**  
You go to a coffee shop and tell the barista: "I'll take the one in the red cup."  
The barista says: "We only have blue cups here."  
You keep looking for a red cup that does not exist.  
The coffee is right there — in a blue cup. But you were looking for the wrong color.

**Files affected:**
- Inventory StockItem: waits for `table` but page uses cards
- Inventory StockItem: presses "Save" but button says "Submit"
- Inventory RateContract: looks for `<select name="vendor_id">` but form uses autocomplete input
- Vendor Agreement: waits for `#vendor_agreement-pane table` but uses card layout

**Rule for the agent:**  
> Before writing browser selectors, inspect the actual HTML of the page.  
> Use the browser's developer tools (Inspect Element) to verify:
> - The element type (`table`, `div`, `input`, `select`)
> - The button text (`Save`, `Submit`, `Create`, `Add`)
> - The field names and IDs  
> Then write the selector to match the actual HTML, not what you assume it looks like.

---

## Mistake #17 — WebDriver/ChromeDriver curl timeouts (infrastructure flakiness)

**The problem:**  
The browser session becomes unresponsive during a test.  
ChromeDriver stops responding to commands.  
The test fails with: `Curl error thrown for http POST to /session/.../log - Operation timed out after 60000+ milliseconds`.

This is NOT a code bug — it's an infrastructure issue. But it causes test failures that look like code problems.

**Real-life example:**  
You are on a phone call. Suddenly the line goes dead.  
You don't know if the other person hung up, the network dropped, or their phone died.  
You cannot continue the conversation until you call back.

**Files affected:** Vendor Invoice tests (4 curl timeout failures out of 21 total failures), StudentProfile Attendance test, and sporadically across other browser tests.

**Suggested fix:**  
- No code change in test files
- Ensure ChromeDriver version matches the installed Chrome browser version
- Add `retry()` wrappers around fragile browser interactions
- Increase Dusk timeouts in config

**Rule for the agent:**  
> When a browser test fails with "Curl error" or "Operation timed out", the issue is likely ChromeDriver infrastructure, not the test logic.  
> Add a `retry()` wrapper around fragile browser operations:  
> ```php
> $browser->retry(3, 100)->click('@submit-button');
> ```

---

## Mistake #18 — Stale route cache makes routes disappear

**The problem:**  
Laravel caches routes to speed up page loads.  
The cache file is at `bootstrap/cache/routes-v7.php`.  
When routes are modified (new module, new route), the cache becomes stale.  
Laravel loads routes from the cache instead of the actual route files.  
The test checks if a route exists — and it does not, because the cache has the old version.

**Real-life example:**  
Your office moves to a new building.  
You update the address in the company directory.  
But the GPS in the delivery truck still has the old address.  
Every delivery goes to the wrong building.  
The GPS cache is stale.

**Files affected:** StudentProfile (StudentLeaveType, StudentCreate) — route names like `student-profile.student-leave-types.index` not found.

**Rule for the agent:**  
> Before running route-related assertions (like `Route::has('name')`),  
> ALWAYS clear the route cache first: `php artisan route:clear`.  
> Better yet, add route cache clearing to the test bootstrap script.

---

## Mistake #19 — Validation errors return 500 instead of 422

**The problem:**  
The test sends invalid data and expects the server to return 422 (validation error).  
Instead, the server returns 500 (server error).  

The root cause: A catch-all exception handler in `prime_testing/bootstrap/app.php` catches EVERY error before Laravel's built-in validation handler can return a proper 422 response.

**Real-life example:**  
You submit a form with a missing required field.  
The website should say: "Please fill in the Name field" (error 422).  
Instead, the website crashes with "Something went wrong" (error 500).  
The form validation is working — but the error message is never shown because the crash handler grabs it first.

**Files affected:** StudentProfile (StudentLeaveType: 10 tests, Attendance: 9 tests, StudentCreate: 7 tests)

**Rule for the agent:**  
> The exception handler in `bootstrap/app.php` must have SPECIFIC render callbacks for known exception types, registered BEFORE the catch-all.  
> ```php
> $exceptions->render(function (ValidationException $e, Request $request) {
>     if ($request->expectsJson()) {
>         return response()->json(['message' => $e->getMessage(), 'errors' => $e->errors()], $e->status);
>     }
> });
> $exceptions->render(function (NotFoundHttpException $e, Request $request) {
>     if ($request->expectsJson()) {
>         return response()->json(['message' => 'Resource not found.'], 404);
>     }
> });
> ```

---

## Mistake #20 — Mixing `$this->actingAs()` HTTP tests inside browser test files

**The problem:**  
Some test files contain BOTH:
- Dusk browser tests (using `$this->browse(function(Browser $browser) {...})`)
- Direct HTTP tests (using `$this->actingAs($user)->post('/url', $data)`)

These are two completely different testing approaches:
- Browser tests: Use a real Chrome browser, execute JavaScript, follow redirects
- HTTP tests: Make direct HTTP requests to the server, no JavaScript, no redirect following

When they are mixed in the same file, it becomes confusing which approach should be used.  
Also, the HTTP tests depend on the tenant context being initialized — if `initializeTenantContext()` was not called before `actingAs()`, the request goes to the wrong database.

**Real-life example:**  
You have a toolbox with two types of screwdrivers:  
- Manual screwdriver (browser test) — you turn it by hand
- Electric screwdriver (HTTP test) — it spins automatically

Both can drive a screw, but they work differently.  
If you pick up the electric screwdriver but forget to plug it in (forget tenant context),  
it does nothing. But the manual one would still work if you just turned it.

**Files affected:** Hostel (RoomChange, IncidentWarnings), and others that mix `$this->actingAs()->post()` with `$this->browse()`.

**Rule for the agent:**  
> Do NOT mix `$this->actingAs()` HTTP tests with Dusk browser tests in the same file.  
> Choose ONE approach per file:
> - Browser tests: Use `$this->browse()` for full end-to-end testing with JavaScript
> - HTTP tests: Use `$this->actingAs()` for API/controller-level testing without browser  
> If you must use HTTP tests, ensure `initializeTenantContext()` is called BEFORE `actingAs()`.

---

## Quick Reference Table

| # | Mistake | Simple Name | Files Affected |
|---|---------|-------------|----------------|
| 1 | No real assertion (`addToAssertionCount(1)`) | "The invisible test" | **100+ instances** across ALL modules |
| 2 | Wrong method name (`isCasted` → `hasCast`) | "Wrong button name" | **10+ files**, 36+ calls |
| 3 | Missing `->refresh()` after create | "Forgot to pick up the pizza" | 6+ files |
| 4 | 403 test never checks 403 | "Watched the door, never tried the handle" | 12+ Hostel files |
| 5 | Exact seed counts instead of minimum | "Exactly 5 apples" | 12+ Inventory files |
| 6 | Wrong URL prefix | "Went to the wrong shop" | FeeStructures, FeeDemands |
| 7 | No data cleanup | "Never empties the garage" | Nearly all files |
| 8 | Missing `media` table | "Printer without driver" | **10+ files** across Hostel, StudentProfile, Vendor |
| 9 | Wrong tenant initialization | "Room number without hotel name" | 5 Admission files |
| 10 | Copy-pasted helpers | "40 copies of the same handbook" | **40+ files** across ALL modules |
| 11 | Missing CSRF token | "ID card without PIN" | StudentProfile, Inventory |
| 12 | Broken cURL fallback in `responseStatusCode()` | "Phone call with no name" | **40+ files** |
| 13 | `isActive()` called as instance method | "Another wrong button" | 2 Hostel files |
| 14 | User creation missing required fields | "Blank required form field" | Admission, Vendor, StudentProfile |
| 15 | Empty test stubs | "Menu item never cooked" | Hostel, Inventory, DepartmentDesignation |
| 16 | Wrong element selectors | "Looking for red cup, only blue exists" | Inventory, Vendor |
| 17 | WebDriver curl timeouts | "Phone line went dead" | Vendor, StudentProfile (sporadic) |
| 18 | Stale route cache | "GPS has old address" | StudentProfile |
| 19 | Validation returns 500 instead of 422 | "Crash instead of error message" | StudentProfile |
| 20 | Mixed HTTP + Browser approaches | "Two different screwdrivers in same toolbox" | Hostel (RoomChange, IncidentWarnings) |

---

## What Should Change for the Agent

Your AI coding agent should be given these **20 rules** to follow every time it writes a test file:

1. **Every test must have a real assertion** — no `addToAssertionCount(1)`.
2. **Use `hasCast()`, not `isCasted()`** — the latter does not exist.
3. **Use `hasCast()`, not `isActive()`** — that also does not exist as an instance method.
4. **Always `->refresh()` after `->create()`** — database defaults are not loaded automatically.
5. **Always flush permission cache after revoking permissions** — `forgetCachedPermissions()`.
6. **Always assert the HTTP status code** — especially in 403 tests.
7. **Use `assertGreaterThanOrEqual()` for seed counts** — never exact numbers.
8. **Verify the actual route URL** — check `php artisan route:list` before writing path constants.
9. **Clean up all created data** — in `try/finally` blocks or via `RefreshDatabase`.
10. **Initialize tenant context correctly** — use `tenancy()->initializeByDomain()`, not `tenancy()->initialize(tenant())`.
11. **Include ALL required fields when creating Users** — check the migration for NOT NULL columns.
12. **Extract shared helpers into traits** — never copy-paste the same method into multiple files.
13. **Include CSRF token in every browser AJAX call** — use `'X-CSRF-TOKEN': csrf_token`.
14. **The cURL fallback in `responseStatusCode()` must include session cookies** — or better, never fall back to cURL.
15. **Do not write empty test stubs** — either implement the test or mark it `$this->markTestIncomplete()`.
16. **Inspect the actual page HTML before writing element selectors** — don't assume `<table>` when the page uses `<div class="card">`.
17. **Do not mix `$this->actingAs()` HTTP tests with `$this->browse()` browser tests** in the same file.
18. **Clear stale route cache before route assertions** — `php artisan route:clear`.
19. **Register specific exception render callbacks for ValidationException (→422) and NotFoundHttpException (→404)** before any catch-all handler.
20. **Add `retry()` wrappers around fragile browser operations** to handle ChromeDriver timeouts gracefully.
