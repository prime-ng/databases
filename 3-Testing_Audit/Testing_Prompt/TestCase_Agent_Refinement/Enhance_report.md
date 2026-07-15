# Test File Quality Report (Batch 2 — from Shailesh) — Agent Enhancement Guide

We have collected additional issues in the TestCase Files created using the "TestCase Creator" Agent. This batch focuses on **DDL-driven coverage gaps** (constraints that exist in the database schema but are never actually tested) and one **process gap** (test cases written from the UI instead of the real code). Below are the important paths referenced in the mistakes, which need to be corrected in the TestCase Creator Agent.

TestCase Files for different Modules :
MAIN_TestCase_Files_Folder = "Users/bkwork/Herd/prime_testing/tests/Browser/Modules"/{MODULE_NAME}
HOSTEL_Testcase_Files = "prime_testing/tests/Browser/Modules/Hostel"
INVENTORY_Testcase_Files = "prime_testing/tests/Browser/Modules/Inventory"

DDL_SCHEMA_FILES = "old_db/2-DDL_Tenant_Consolidated"
ENHANCED_DDL_FILES = "old_db/2-DDL_Tenant_Enhanced"

> **Note on scope:** The reviewer did not list individual file names for most items — these are coverage rules that apply to **every DDL-backed CRUD screen** across all modules. The review scope was the Hostel and Inventory modules.

---

## Mistake #1 — The UNIQUE constraint is never actually tested

**The problem:**
A column is marked `UNIQUE` in the database (DDL), but no test ever tries to create a **second** record with the same value. So if the application silently stops enforcing uniqueness, no test would ever notice.

**Real-life example:**
A cinema says "one seat, one ticket." To check the rule works, you must try to sell seat 5A **twice** and confirm the second sale is refused. If you only ever sell each seat once, you never actually prove the rule is working — you just assumed it.

**Where it happens:**
Any feature whose primary table has a `UNIQUE KEY` in the DDL (e.g. `code`, `short_name`, `email`, a composite unique key) but whose test file only creates one record and never attempts a duplicate.

**What the correct test should do:**
1. Read the DDL and find every `UNIQUE` column / `UNIQUE KEY` on the table.
2. Create the first record successfully.
3. Attempt to create a second record with the **same** unique value.
4. **Pass** if the application rejects the duplicate (validation error or database error).
5. **Fail** only if the duplicate is inserted successfully — that means the UNIQUE constraint is not being enforced.

**Files affected:** All DDL-backed CRUD screens with a UNIQUE column (Hostel, Inventory, and beyond).

**Rule for the agent:**
> For every `UNIQUE` column/key in the DDL, generate a duplicate-rejection test: create one record, then attempt a second with the same value and assert it is rejected. Never assume uniqueness — prove it.

---

## Mistake #2 — NULL / NOT NULL constraints are never verified

**The problem:**
The DDL says a column is `NOT NULL` (required) or nullable (optional), but the test never checks that the application actually enforces this. A required field that quietly accepts an empty value, or an optional field that wrongly rejects an empty value, would slip through untested.

**Real-life example:**
A visa form says "Passport Number is required" and "Middle Name is optional." To prove the form works you must (a) submit it **without** a passport number and confirm it is rejected, and (b) submit it **without** a middle name and confirm it is accepted. Testing only the fully-filled form proves nothing about the rules.

**Where it happens:**
Any feature with `NOT NULL` (no default) or nullable columns in the DDL that are not exercised with a missing-value test.

**What the correct test should do:**
- For each **NOT NULL** (no-default) column: attempt to create/update the record **without** that value and assert the application rejects it (validation or DB error).
- For each **nullable** column: create/update the record **without** that value and assert it succeeds.
- **Pass** if the behaviour matches the DDL; **fail** if a NOT NULL field accepts null, or a nullable field is wrongly rejected.

**Files affected:** All DDL-backed CRUD screens (Hostel, Inventory, and beyond).

**Rule for the agent:**
> Derive required-vs-optional from the DDL `NOT NULL`/nullable definition (not from the form). Generate a missing-value negative test for every NOT NULL-no-default column, and a missing-value positive test for representative nullable columns.

---

## Mistake #3 — Field length limits (VARCHAR size) are never tested

**The problem:**
A column is `VARCHAR(5)` in the DDL, but no test ever tries to save a value longer than 5 characters. If oversized data is accepted (or silently truncated), no test catches it.

**Real-life example:**
A parking meter slot is built for a coin of a fixed size. To prove it rejects the wrong coin, you must actually try to push an oversized coin in and confirm it won't fit. If you only ever insert the correct coin, you never tested the limit.

**Where it happens:**
Any string column with a declared size (`VARCHAR(n)`, `CHAR(n)`) that has no over-length boundary test.

**What the correct test should do:**
- For a `VARCHAR(5)` column, attempt to save an 8-character value.
- **Pass** if the application rejects the oversized value (validation or DB error).
- **Fail** if the too-long value is saved successfully.

**Files affected:** All DDL-backed CRUD screens with sized string columns (Hostel, Inventory, and beyond).

**Rule for the agent:**
> For sized string columns, generate a boundary test that submits a value exceeding the DDL length and asserts rejection. Cross-check the FormRequest `max:` rule against the DDL size — they must agree.

---

## Mistake #4 — The test suite does not verify the app actually matches the DDL

**The problem:**
There is no systematic check that the application's **models, validation rules, forms, and test cases** all line up with the database schema. Drift between the schema and the code (a renamed column, a missing field, a wrong data type, a default that isn't respected) goes undetected because nothing compares the two.

**Real-life example:**
A building's fire-exit map (the DDL) says there are 4 exits. Over time, one exit was bricked up and a new one was added, but nobody updated the map. Unless someone walks the building and compares it against the map, the mismatch is invisible — until it matters.

**Where it happens:**
Every feature — the schema-truth `test_01` method should assert full DDL alignment, but coverage is incomplete.

**What the correct test should do — verify ALL of:**
- Every column defined in the DDL exists in the application (model/migration).
- No application field references a non-existent database column.
- NULL / NOT NULL constraints match the DDL.
- Data types are handled correctly.
- Field lengths match the DDL.
- Default values are respected.
- UNIQUE constraints are properly validated (see Mistake #1).
- Foreign keys and relationships are correctly implemented.
- Column names are consistent across DDL, models, validation rules, controllers, and test cases.

**Soft-delete sub-check:**
- If the DDL table **has** a `deleted_at` column: the model must use the `SoftDeletes` trait, and tests must use soft-delete assertions (`assertSoftDeleted()`) where applicable — not hard-delete assertions.
- If the DDL table **has no** `deleted_at`: the model must **not** use `SoftDeletes`, and tests must **not** use soft-delete methods/assertions.
- (Note: the column and the trait can genuinely disagree in this codebase — assert each independently and report the mismatch as a defect rather than "fixing" it in the test.)

**Files affected:** All features — the `test_01_migration_model_and_request_configuration_are_correct` method must carry this full alignment matrix.

**Rule for the agent:**
> The schema-truth test must assert full DDL↔app consistency (columns, null/not-null, types, lengths, defaults, unique, FKs, name consistency) and the soft-delete trait↔`deleted_at` correspondence. **Pass** only if the app is fully consistent with the DDL; **fail** on any mismatch, missing field, wrong type, or invalid rule.

---

## Mistake #5 — The test uses the wrong (or misconfigured) Eloquent model

**The problem:**
A test performs database operations through a model that is missing, incorrect, or wired to the wrong table — so the test may be exercising the wrong data entirely, or failing for the wrong reason.

**Real-life example:**
You are told to update the record in "Cabinet A," but you open "Cabinet B" instead. Whatever you change in Cabinet B looks like a successful edit, but the record you were supposed to update in Cabinet A is untouched. The action "worked" — on the wrong cabinet.

**Where it happens:**
Any test whose CRUD operations do not go through the correct, properly-configured model for the feature's primary table.

**What the correct test should do — verify:**
- The model exists.
- The correct model is imported and used.
- The model maps to the correct database table (matching the DDL prefix/table).
- Fillable/guarded properties support the fields being tested.
- The relationships used in the test are valid.
- All CRUD operations are performed through the appropriate model.

**Files affected:** All DDL-backed CRUD screens (Hostel, Inventory, and beyond).

**Rule for the agent:**
> Resolve the feature's correct Eloquent model from the real source (controller/service usage + DDL table), confirm its `$table`, `$fillable`, and relationships support the tested fields, and route every CRUD operation through it. **Pass** if the correct model is used throughout; **fail** on an incorrect, missing, or misconfigured model.

---

## Mistake #6 — Test cases written from the UI instead of the actual code

**The problem:**
Test cases are being created by looking only at the **form/UI**, without reviewing the underlying code. As a result, the tests miss (or mis-handle) any logic that is managed **programmatically** rather than through a form field.

**Concrete example the reviewer found:**
The `ordinal` field is set in the **controller** as part of the application's business logic — it is **not** a form field the user fills in. But the generated test case incorrectly suggested **adding the `ordinal` field to the form**. That mistake is only possible if the test was written by looking at the UI and never reading the controller, which auto-assigns `ordinal`.

**Real-life example:**
A restaurant menu lists the dishes a customer can order. But the kitchen also adds a garnish and plates the food a certain way — steps that never appear on the menu. If you "test" the restaurant by reading only the menu, you would never check the garnish or plating, and you might even complain that "garnish is missing from the menu" — when it was never supposed to be there.

**Where it happens:**
Any feature with logic handled outside the form — auto-assigned ordinals, auto-generated codes/names, server-set defaults, status transitions, computed fields, and service-layer business rules.

**What the correct test should do:**
- Before writing any test case, thoroughly review the **controller, request validation, models, services, routes, and business logic** — not just the Blade form.
- Cover all application logic, including fields handled **programmatically** and **not present in the form** (e.g. assert that `ordinal` is auto-assigned by the controller — do **not** treat it as a form input).
- Never suggest adding a programmatically-managed field to the form.

**Files affected:** Any feature with controller/service-managed fields (the `ordinal` case was the concrete example).

**Rule for the agent:**
> Read the real code (controller, FormRequest, model, service, routes, business logic) **before** writing test cases — never write them from the UI/form alone. Fields set programmatically (e.g. `ordinal`, auto-codes, server defaults) must be tested as auto-managed behaviour, and must **never** be proposed as form fields.

---

## Quick Reference Table

| # | Mistake | Simple Name | Scope |
|---|---------|-------------|-------|
| 1 | UNIQUE constraint never tested with a duplicate | "One seat sold twice" | All DDL UNIQUE columns |
| 2 | NULL / NOT NULL constraints never verified | "Required vs optional never checked" | All DDL NOT NULL / nullable columns |
| 3 | Field length (VARCHAR size) never tested | "Oversized coin never tried" | All sized string columns |
| 4 | No DDL ↔ app consistency check (incl. soft-delete) | "Fire-exit map never walked" | Every feature's schema-truth test |
| 5 | Wrong / misconfigured Eloquent model | "Opened the wrong cabinet" | All DDL-backed CRUD screens |
| 6 | Tests written from the UI, not the code | "Testing by reading only the menu" | Any programmatically-managed field (e.g. `ordinal`) |

---

## What Should Change for the Agent

Your AI coding agent should be given these **6 additional rules** to follow every time it writes a test file:

1. **Test every UNIQUE constraint** — create one record, then attempt a duplicate and assert it is rejected. Never assume uniqueness is enforced.
2. **Test NULL / NOT NULL from the DDL** — a missing-value negative test for every NOT NULL-no-default column, and a missing-value positive test for nullable columns.
3. **Test field-length limits** — submit an over-length value for sized string columns and assert rejection; keep the FormRequest `max:` in sync with the DDL size.
4. **Assert full DDL ↔ app consistency in `test_01`** — columns, null/not-null, types, lengths, defaults, unique, FKs, name consistency, and the soft-delete trait↔`deleted_at` correspondence (assert the column and the trait independently).
5. **Verify the correct Eloquent model is used** — model exists, correct import, correct `$table`, fillable/relationships support the tested fields, all CRUD through that model.
6. **Read the code, not just the UI, before writing tests** — review controller, FormRequest, model, service, routes, and business logic; cover programmatically-managed fields (e.g. auto-assigned `ordinal`) as auto-behaviour, and never propose adding them to the form.
