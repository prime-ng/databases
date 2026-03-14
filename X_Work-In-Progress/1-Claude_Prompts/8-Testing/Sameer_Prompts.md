

ROLE: You are a Laravel QA/BA analyst. Your job is to write detailed, controller-accurate requirements for a new module folder.
 
TASK:

1) First go through with the folder "/Users/bkwork/Herd/laravel/tests/Browser/Modules/Class&SubjectMgmt/ClassGroup" to understand the TEstcase Requirement and the Testcase created with file name "tests/Browser/Modules/Class&SubjectMgmt/ClassGroup/ClassGroupCrudTest.php". After the understanding I want you to create Testcases for all the requirement created in folder "/Users/bkwork/Herd/laravel/tests/Browser/Modules/StudentProfile".

2) Create a folder named `Testcases` inside `StudentProfile` at this path:

   `/Users/bkwork/Herd/laravel/tests/Browser/Modules/StudentProfile`

3) Do NOT write any code. Do NOT modify existing files.

4) Read the relevant controller(s) and routes to understand exact behavior.

5) Then write a full detailed requirements TestCase for SubjectGroupSubject, based strictly on controller behavior.
 
REQUIREMENTS DOCUMENT MUST INCLUDE:

- Feature overview (what SubjectGroupSubject does)

- Exact routes/endpoints used (index, create, store, show, edit, update, destroy, restore, force delete, toggle status, list subgroups, stats, etc.)

- Permissions/Policies (who can view/create/edit/delete/restore/force-delete/toggle)

- Validation rules (required fields, unique constraints, data types)

- Positive cases (happy path for create/edit/view/toggle/trash/restore)

- Negative cases (invalid id, missing fields, duplicates, unauthorized access, dependency issues)

- DB behavior (tables/models involved, soft delete, timestamps, relations)

- UI expectations (forms, modals, alerts, breadcrumb behavior)

- Response expectations (HTTP status, JSON shape, success/failure messages)

- Audit/Activity logging expectations if controller does it

- Any edge cases or constraints implied by controller logic
 
STRICT RULES:

- Requirements must match exactly what the controller does (no assumptions).

- If controller behavior is missing/unclear, clearly mark it as “Not defined in controller”.

- Include both Positive and Negative scenarios.

- Include all file paths you used for reference.

- Output should be in clear English, simple wording.
 
SOURCES YOU MUST CHECK:

- The controller(s) related to SubjectGroupSubject (find via routes).

- Any policies used for SubjectGroupSubject.

- The model(s) used in controller.
 
DELIVERABLE:

- One detailed requirements document text only (no code changes).

 

 -------------------------------------------------------------------
 