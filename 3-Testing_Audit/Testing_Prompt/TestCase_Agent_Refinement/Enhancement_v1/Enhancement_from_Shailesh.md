# Issues in the Test cases
==========================

We have collected some Issue in TestCase Files while creating TestCases using "TestCase Creator" Agent. Below are some important Paths which has been refered in below Mistakes, which needs to be correct in TestCases Creator Agent.

TestCase Files for different Modules :
MAIN_TestCase_Files_Folder = "Users/bkwork/Herd/prime_testing/tests/Browser/Modules"/{MODULE_NAME}
HOSTEL_Testcase_Files = "prime_testing/tests/Browser/Modules/Hostel"
INVENTORY_Testcase_Files = "prime_testing/tests/Browser/Modules/Inventory"

DDL_SCHEMA_FILES = "old_db/2-DDL_Tenant_Consolidated"
ENHANCED_DDL_FILES = "old_db/2-DDL_Tenant_Enhanced"

1. Unique Constraint Validation
Verify whether any database column has a UNIQUE constraint defined in the DDL. Create the first record successfully, then attempt to create another record with the same unique value.
Expected Result:
Pass the test if the application correctly rejects the duplicate record with a validation or database error.
Fail the test only if the duplicate record is inserted successfully into the database, indicating that the UNIQUE constraint is not being enforced.

2. NULL / NOT NULL Constraint Validation
Verify that all database columns follow the NULL and NOT NULL constraints defined in the DDL.
Expected Result:
For NOT NULL fields, attempt to create or update a record without providing a value. The application should reject the request with an appropriate validation or database error.
For NULL fields, verify that records can be created or updated successfully without providing a value.
Pass the test if the application behaves according to the DDL constraints.
Fail the test if a NOT NULL field accepts a null value or if a nullable field is incorrectly rejected.

3. Field Length Validation
Verify that all string fields respect the maximum length defined in the database DDL.
Expected Result:
Attempt to save a value that exceeds the column's maximum length (e.g., a VARCHAR(5) column receiving an 8-character value).
Pass the test if the application rejects the oversized value with a validation or database error.
Fail the test if the value exceeding the defined length is saved successfully.

4. DDL Schema Consistency Validation
Verify that the application's models, validation rules, forms, and test cases are fully aligned with the database DDL.
Verify the following:
Every column defined in the DDL exists in the application.
No application field references a non-existent database column.
NULL/NOT NULL constraints match the DDL.
Data types are handled correctly.
Field lengths match the DDL.
Default values are respected.
UNIQUE constraints are properly validated.
Foreign keys and relationships are correctly implemented.
Column names are consistent across the DDL, models, validation rules, controllers, and test cases.
Soft Delete Validation:
Check whether the table includes a deleted_at column in the DDL.
If the table supports soft deletes, verify that:
The model uses the SoftDeletes trait.
Test cases use soft delete assertions (e.g., assertSoftDeleted()) instead of hard delete assertions where applicable.
If the table does not include a deleted_at column, ensure that:
The model does not use the SoftDeletes trait.
Test cases do not use soft delete methods or assertions.
Expected Result:
Pass if the application is fully consistent with the DDL.
Fail if any mismatch, missing field, incorrect data type, or invalid validation rule is found.

5. Model Usage Validation
Verify that the test case uses the correct Laravel Eloquent model for all database operations.
Verify the following:
The model exists.
The correct model is imported and used.
The model maps to the correct database table.
Fillable/guarded properties support the tested fields.
Relationships used in the test are valid.
CRUD operations are performed through the appropriate model.
Expected Result:
Pass if the correct model is used throughout the test case.
Fail if an incorrect, missing, or improperly configured model is used.

6. Test Case Creation Issue
One major issue is that the code is not being reviewed properly before creating test cases.
For example, the ordinal field is managed in the controller and is part of the application's business logic, but the generated test case incorrectly suggests adding the field to the form. This indicates that the test case was created by looking only at the UI instead of reviewing the actual code.
Before generating test cases, thoroughly review the controller, request validation, models, services, routes, and business logic. Test cases should cover all application logic, including fields that are handled programmatically and are not present in the form.
