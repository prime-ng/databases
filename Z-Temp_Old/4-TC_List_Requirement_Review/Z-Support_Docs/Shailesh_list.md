# Code Review Checklist
 
## Model
 
* Verify the table name is correct.
* Verify all database fields are included.
* Verify all model relationships are correctly defined and configured.
 
## Controller
 
* Verify exception handling using `try-catch` where required.
* Verify database transactions are used where necessary.
* Verify find() results are checked using an if condition before use to prevent 500 errors when null is returned.
* Verify `findOrFail()` is used where a 404 response is expected.
* Verify `foreach` loops include the required conditional checks before processing.
* Verify `whereHas()` is used when filtering records based on related model data.
* Gate:: Chceck in controller
 
## Form Requests
 
* Verify unique validation rules.
* Verify required (`NOT NULL`) and nullable field validations.
* Verify maximum length validations.
 
## Migration
 
* Verify table names match the project naming conventions.
* Verify all database columns are created with the correct data types.
* Verify nullable and non-nullable column definitions match the business requirements.
* Verify column lengths, precision, and scale are correct.
* Verify default values are defined where required.
* Verify foreign key columns use the correct data types matching the referenced primary key.
* Verify foreign key constraints are correctly defined.
* Verify `onDelete()` and `onUpdate()` actions (`cascade`, `restrict`, `set null`, etc.) are correctly configured.
* Verify indexes are created for foreign keys and frequently searched columns.
* Verify unique constraints are correctly implemented.
* Verify composite unique indexes are created where required.
* Verify timestamps (`created_at`, `updated_at`) are included where required.
* Verify soft deletes (`softDeletes()`) are implemented where required.
* Verify comments are added for complex columns (if project standards require them).
* Verify migration `down()` method correctly rolls back all changes.
* Verify migration can be executed and rolled back without errors.
* Verify database schema matches the DDL and business requirements.
 
## Routes
 
* Verify resource routes cover:
 
  * `index`
  * `create`
  * `store`
  * `edit`
  * `update`
  * `destroy`
* Verify additional routes:
 
  * `forceDelete`
  * `toggle`
  * `trash`
  * `restore`
 
## Policy & Permission
 
Verify screen-wise permissions for:
 
* `viewAny`
* `view`
* `create`
* `edit`
* `delete`
* `trash`
* `restore`
* `forceDelete`
* `toggle`
 
## Views
 
* Verify success messages are displayed correctly after Create, Update, and Delete operations.
* Verify all dropdowns are correctly populated with the expected data.
* Verify uniqueness validation errors are displayed correctly.
* Verify all variables accessed through relationships are wrapped with `isset()` or null-safe checks to prevent runtime errors.
* Verify all `foreach` loops used for dropdowns or related data include appropriate `isset()` or empty checks where required.
* Verify breadcrumbs are correctly implemented using the configuration file.
* Verify `@can` directives are used to enforce permission-based visibility for buttons, actions, and sections.
* Verify client-side validation is implemented where applicable.
* Verify server-side validation is implemented and validation errors are displayed correctly.
* Verify pagination is implemented correctly and navigation links work as expected.
* Verify all Create, Edit, View, and Delete buttons are displayed based on user permissions.
* Verify form fields are correctly pre-filled on the Edit page.
* Verify validation error messages are displayed below the corresponding fields.
* Verify file/image preview is displayed correctly on the Edit page (if applicable).
* Verify all routes used in forms and action buttons are correct.
* Verify search, filter, and reset functionality work correctly (if applicable).
* Verify sorting functionality works correctly (if applicable).
* Verify modals, confirmation dialogs, and delete confirmations function correctly.
* Verify no undefined variable, undefined index, or null property errors occur.
* Verify all Blade syntax (`@if`, `@foreach`, `@can`, etc.) is implemented correctly.
 
## Services
 
* Verify business logic is implemented in the service.
* Verify database transactions are used where required.
* Verify find() results are checked using an if condition before use to prevent 500 errors when null is returned.
* Verify `findOrFail()` is used where a 404 response is expected.
* Verify `foreach` loops include the required conditional checks before processing.
* Verify no duplicate business logic exists in controllers.
* Verify database queries are optimized and unnecessary queries are avoided.
* Verify `whereHas()` is used when filtering records based on related model data.
 
## Requirements
* What This Screen Does
* When This Screen Is Used
* Who Can Access This Screen
* How This Screen Works — Logic Flow (Non-Technical)
* Validate Before Save (Multiple Conditions)
* Business Rules and Conditions
* Error Handling and Validation Messages
* Success Scenarios
* Failure Scenarios
* Example Scenario
* Related Screens
* Dependencies module and tables
 
## Scheduler / Cron Jobs (If Applicable)
* Verify scheduled commands are registered correctly.
* Verify cron frequency is correct.
* Verify scheduled jobs are idempotent (safe to run multiple times).
* Verify logging and exception handling for scheduled jobs.
* Verify queue usage where required.
 
## Queue Jobs (If Applicable)
* Verify jobs implement the correct interfaces.
* Verify retry and timeout configuration.
* Verify failed job handling.
* Verify queue dispatch conditions.
 
## Notifications / Events (If Applicable)
* Verify notifications are triggered correctly.
* Verify events and listeners are registered.
* Verify email/SMS/WhatsApp notifications are sent only when required.
 