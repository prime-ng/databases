# Question Versions — Test Case List

## 1) Feature Information

| Field | Value |
|---|---|
| **Module** | QuestionBank |
| **Feature Name** | Question Versions |
| **Table** | `qns_question_versions` |
| **Model** | `Modules\QuestionBank\Models\QuestionVersion` |
| **Controller** | `Modules\QuestionBank\Http\Controllers\QuestionVersionController` |
| **Request** | `Modules\QuestionBank\Http\Requests\QuestionVersionRequest` |
| **Policy** | `Modules\QuestionBank\Policies\QuestionVersionPolicy` (backed by `QuestionBankPolicy` abilities) |
| **Description** | Automatically captures a snapshot of question data each time a question is updated. Versions are read-only historical records; they cannot be created or edited manually via user-facing forms — the controller's `create()`, `store()`, `edit()`, `update()` methods all return `abort(404)`. The version list lives inside the Question Bank tab module. |

## 2) Pre-conditions

- Tenant context is initialised.
- User is authenticated and has the relevant `tenant.question-bank.*` permissions.
- At least one question (`qns_questions_bank`) exists to serve as the FK parent.
- The migration `2026_06_16_114250_create_qns_question_versions_table.php` has run.

## 3) Default Data Load

- No seed data is provided out of the box. Version records are created automatically by `QuestionCRUDService::update()` when a question is edited.
- On fresh install the table is empty.

## 4) BC-DB — Database Schema

**Table:** `qns_question_versions`

| Column | Type | Constraints | Notes |
|---|---|---|---|
| `id` | INT UNSIGNED | AUTO_INCREMENT, PK | |
| `question_bank_id` | INT UNSIGNED | NOT NULL, FK → `qns_questions_bank.id` ON DELETE CASCADE | |
| `version` | INT UNSIGNED | NOT NULL | Part of unique key |
| `data` | JSON | NOT NULL | Stores `{before, after, changed_fields}` |
| `version_created_by` | INT UNSIGNED | NULLABLE | FK → `users.id` |
| `change_reason` | VARCHAR(255) | NULLABLE | |
| `is_active` | TINYINT(1) | DEFAULT 1 | |
| `created_at` | TIMESTAMP | NULLABLE | |
| `updated_at` | TIMESTAMP | NULLABLE | |
| `deleted_at` | TIMESTAMP | NULLABLE | Soft deletes |

**Indexes:**
- UNIQUE `uq_qver_q_v` on (`question_bank_id`, `version`)
- FK `fk_qver_q` on `question_bank_id` → `qns_questions_bank.id`

**Cast/Model mapping:**
- `data` → `array` cast
- `is_active` → `boolean` cast
- `created_at` / `updated_at` / `deleted_at` → `datetime` cast

## 5) BC-VAL — Validation Rules

| Field | Rule |
|---|---|
| `question_bank_id` | required, exists `qns_questions_bank.id` |
| `version` | required, integer, min:1 |
| `data` | required, json |
| `version_created_by` | nullable, exists `users.id` |
| `change_reason` | nullable, string, max:255 |
| `is_active` | boolean |

**Custom messages:**
- `question_bank_id.required` → "Question bank is required."
- `question_bank_id.exists` → "Selected question bank does not exist."
- `version.required` → "Version number is required."
- `data.required` → "Question data is required."
- `data.json` → "Question data must be valid JSON."

## 6) BC-AUTH — Authorization

Versions use `QuestionBankPolicy` gate abilities (not `QuestionVersionPolicy` directly in the controller):

| Action | Gate Ability | Notes |
|---|---|---|---|
| Index (view list) | — | `index()` returns `abort(404)` — dead route |
| Create / Store | — | Both methods return `abort(404)` — versions are system-created |
| Show (view detail) | `tenant.question-bank.view` | |
| Edit / Update | — | Both methods return `abort(404)` — versions are immutable |
| Destroy (soft delete) | `tenant.question-bank.delete` | |
| Trash (view trashed) | `tenant.question-bank.restore` | |
| Restore | `tenant.question-bank.restore` | |
| Force delete | `tenant.question-bank.forceDelete` | |
| Toggle status | `tenant.question-bank.update` | |

**Blade UI permissions:**
- Active column: `@can('tenant.question-version.status')`
- Action column: `@can('tenant.question-version.view')`

## 7) BC-BIZ — Business Logic

1. **Auto snapshot on content change:** When `QuestionCRUDService::update()` is called, a `QuestionVersion` record is created automatically containing the `before` and `after` state plus a `changed_fields` array.
2. **Version increment:** `current_version` on `QuestionBank` is incremented by 1 each update. The new version record uses the incremented value.
3. **Immutable records:** Versions are never modified once created. The controller's `create()`, `store()`, `edit()`, `update()` methods all return `abort(404)`.
4. **No snapshot on pure status change:** Status toggles (`is_active`, question `status` field) do NOT trigger version creation — only the main `update()` service call triggers a snapshot.
5. **The `data` JSON stores:** `{before: {...original}, after: {...new}, changed_fields: [...]}`.
6. **`version_created_by`** is set to `auth()->id()` at snapshot time.
7. **Activity logging on state changes:** `activityLog()` is called on destroy (Trashed), restore (Restored), forceDelete (Deleted), and toggleStatus (Toggled) — each with a descriptive message and performed_by.

## 8) BC-REF — Referential Integrity

| FK | Column | References | On Delete |
|---|---|---|---|
| `fk_qver_q` | `question_bank_id` | `qns_questions_bank.id` | CASCADE |

- When a question bank record is force-deleted, `QuestionCRUDService::forceDelete()` explicitly calls `QuestionVersion::where('question_bank_id', $id)->forceDelete()`.
- The DB-level FK cascade provides a second layer of protection.

---

## 9) Test Case Summary

### 9.1 Database Schema Tests

| TC ID | Test Case | Priority | Automated |
|---|---|---|---|
| TC-DB-01 | Table `qns_question_versions` exists | P0 | Yes |
| TC-DB-02 | All required columns exist | P0 | Yes |
| TC-DB-03 | Column types and constraints are correct | P0 | Yes |
| TC-DB-04 | JSON `data` column stores and retrieves correctly | P0 | Yes |
| TC-DB-05 | Soft delete works (`deleted_at` populated on delete) | P0 | Yes |
| TC-DB-06 | `is_active` behaves as boolean | P0 | Yes |
| TC-DB-07 | UNIQUE (`question_bank_id`, `version`) rejects duplicates | P0 | Yes |
| TC-DB-08 | FK cascade on parent question force-delete | P0 | Yes |

### 9.2 Authorization Tests

| TC ID | Test Case | Priority | Automated |
|---|---|---|---|
| TC-AUTH-01 | User without `tenant.question-bank.view` cannot view detail | P0 | Yes |
| TC-AUTH-02 | User without `tenant.question-bank.update` cannot toggle status | P0 | Yes |
| TC-AUTH-03 | User without `tenant.question-bank.delete` cannot soft delete | P0 | Yes |
| TC-AUTH-04 | User without `tenant.question-bank.restore` cannot restore | P0 | Yes |
| TC-AUTH-05 | User without `tenant.question-bank.forceDelete` cannot force delete | P0 | Yes |

### 9.3 Business Logic Tests

| TC ID | Test Case | Priority | Automated |
|---|---|---|---|
| TC-BIZ-01 | Version snapshot created automatically on question update via CRUD service | P0 | Yes |
| TC-BIZ-02 | Version increments by 1 each update | P0 | Yes |
| TC-BIZ-04 | Status-only change does NOT create version record | P1 | No |
| TC-BIZ-05 | `data` JSON contains `before`, `after`, `changed_fields` keys | P0 | Yes |
| TC-BIZ-06 | `version_created_by` is set to authenticated user at snapshot time | P0 | Yes |
| TC-BIZ-07 | Activity log — Trashed on soft delete | P1 | No |
| TC-BIZ-08 | Activity log — Restored on restore | P1 | No |
| TC-BIZ-09 | Activity log — Deleted on force delete | P1 | No |
| TC-BIZ-10 | Activity log — Toggled on toggle status | P1 | No |

### 9.4 UI / Browser Tests

| TC ID | Test Case | Priority | Automated |
|---|---|---|---|
| TC-UI-01 | Question Versions tab shows in tab module | P0 | Yes |
| TC-UI-02 | Version list page loads with paginated results | P0 | Yes |
| TC-UI-03 | Version list shows version number, question, change reason, created by, created at | P0 | Yes |
| TC-UI-04 | Status filter (Active / Inactive / All) works | P1 | Yes |
| TC-UI-05 | Version number filter works | P1 | Yes |
| TC-UI-06 | View page displays version detail with before/after comparison | P0 | Yes |
| TC-UI-07 | View page shows changed fields list | P0 | Yes |
| TC-UI-08 | Active column toggles status via AJAX | P0 | Yes |
| TC-UI-09 | Empty state shows "No Question Versions Found" | P1 | Yes |
| TC-UI-10 | Breadcrumb navigates in same tab | P0 | Yes |

### 9.5 Soft Delete Lifecycle Tests

| TC ID | Test Case | Priority | Automated |
|---|---|---|---|
| TC-SD-01 | Soft delete sets `deleted_at` and `is_active = false` | P0 | Yes |
| TC-SD-02 | Restore clears `deleted_at` | P0 | Yes |
| TC-SD-03 | Force delete permanently removes record | P0 | Yes |
| TC-SD-04 | Trash page lists soft-deleted records | P0 | Yes |
| TC-SD-05 | Force delete redirects correctly | P0 | Yes |

### 9.6 Edge Case / Negative Tests

| TC ID | Test Case | Priority | Automated |
|---|---|---|---|
| TC-EDGE-01 | Duplicate version for same question rejected | P0 | Yes |
| TC-EDGE-02 | Version 0 or negative rejected | P0 | Yes |
| TC-EDGE-03 | Invalid question_bank_id (non-existent) rejected | P0 | Yes |
| TC-EDGE-04 | Maximum version numbers (sequential increments 1..N) accepted | P1 | Yes |
| TC-EDGE-05 | Viewing non-existent version returns 404 | P1 | Yes |
| TC-EDGE-06 | Toggle with non-boolean value rejected | P1 | Yes |

---

## 10) Detailed TC Steps

#### TC-DB-01: Table exists

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Query `INFORMATION_SCHEMA.TABLES` WHERE `table_name` = `'qns_question_versions'` | Row exists |

#### TC-DB-02: Columns exist

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Get column list from `qns_question_versions` | Columns include: id, question_bank_id, version, data, version_created_by, change_reason, is_active, created_at, updated_at, deleted_at |

#### TC-DB-03: Column types and constraints

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check migration file contains all required column definitions | All column definitions present |
| 2 | Verify `$table->increments('id')` | `id` column is auto-increment primary key |
| 3 | Verify `$table->unsignedInteger('version')` | `version` is unsigned integer |
| 4 | Verify `$table->json('data')` | `data` is JSON type |
| 5 | Verify `$table->unsignedInteger('version_created_by')->nullable()` | `version_created_by` is nullable unsigned integer |
| 6 | Verify `$table->string('change_reason')->nullable()` | `change_reason` is nullable string |
| 7 | Verify `$table->boolean('is_active')->default(true)` | `is_active` is boolean with default true |
| 8 | Verify `$table->unsignedInteger('question_bank_id')` with foreign key cascade | FK references `qns_questions_bank.id` ON DELETE CASCADE |
| 9 | Verify `$table->unique(['question_bank_id', 'version'])` | Unique composite index exists |
| 10 | Verify `$table->softDeletes()` | `deleted_at` timestamp column present |

#### TC-DB-04: JSON data column

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a version with `data = {ques_title: "Test", marks: 2.5, options: [{text: "A"}]}` | Version created successfully |
| 2 | Retrieve the record | Record exists |
| 3 | Assert `data` is an array | `data` is of type array |
| 4 | Assert `data.ques_title === "Test"` | `ques_title` matches |
| 5 | Assert `data.marks === 2.5` | `marks` matches |
| 6 | Assert `count(data.options) === 1` | `options` array has 1 entry |

#### TC-DB-05: Soft delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create version record | Record created |
| 2 | Assert `deleted_at` is null | `deleted_at` is null |
| 3 | Call `$record->delete()` | Delete succeeds |
| 4 | Refresh record | Record loaded |
| 5 | Assert `deleted_at` is not null | `deleted_at` timestamp is set |

#### TC-DB-06: is_active boolean

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create version with `is_active = true` | Record created |
| 2 | Assert `(bool)$record->is_active === true` | Returns boolean `true`, not string `"1"` |
| 3 | Assert model cast `'is_active' => 'boolean'` is set | Cast configuration exists |

#### TC-DB-07: Unique constraint

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create version with `question_bank_id = Q1`, `version = 1` | Creation succeeds |
| 2 | Attempt to create version with `question_bank_id = Q1`, `version = 1` again | Exception thrown: duplicate key / unique violation |
| 3 | Create version with `question_bank_id = Q1`, `version = 2` | Creation succeeds (different version) |
| 4 | Create version with `question_bank_id = Q2`, `version = 1` | Creation succeeds (different question) |

#### TC-DB-08: FK cascade

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a question and a version pointing to it | Both records exist |
| 2 | Force-delete the question | Question removed |
| 3 | Assert version record is also removed from `qns_question_versions` | Version record is cascade-deleted |

#### TC-AUTH-01: User without tenant.question-bank.view cannot view detail

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.question-bank.view` permission | User authenticated |
| 2 | Access version detail route | Request made |
| 3 | Assert: 403 Forbidden response | 403 returned |

#### TC-AUTH-02: User without tenant.question-bank.update cannot toggle status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.question-bank.update` permission | User authenticated |
| 2 | Trigger toggle-status action | Request made |
| 3 | Assert: 403 Forbidden response | 403 returned |

#### TC-AUTH-03: User without tenant.question-bank.delete cannot soft delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.question-bank.delete` permission | User authenticated |
| 2 | Trigger delete action | Request made |
| 3 | Assert: 403 Forbidden response | 403 returned |

#### TC-AUTH-04: User without tenant.question-bank.restore cannot restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.question-bank.restore` permission | User authenticated |
| 2 | Trigger restore action | Request made |
| 3 | Assert: 403 Forbidden response | 403 returned |

#### TC-AUTH-05: User without tenant.question-bank.forceDelete cannot force delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.question-bank.forceDelete` permission | User authenticated |
| 2 | Trigger force-delete action | Request made |
| 3 | Assert: 403 Forbidden response | 403 returned |

#### TC-BIZ-01: Auto snapshot on question update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create question Q with `current_version = 1` | Question created |
| 2 | Call `QuestionCRUDService::update(Q.id, {ques_title: "Updated"})` | Update succeeds |
| 3 | Assert: `QuestionVersion` record exists for Q.id | Version record created |
| 4 | Assert: `version === 2` (incremented) | Version number is 2 |
| 5 | Assert: `data.before.ques_title` === original title | Before snapshot captures original |
| 6 | Assert: `data.after.ques_title === "Updated"` | After snapshot captures new value |
| 7 | Assert: `"ques_title"` in `data.changed_fields` | Changed fields list includes updated field |

#### TC-BIZ-02: Version increments

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create question Q with `current_version = 1` | Question created |
| 2 | Update Q three times | Three updates succeed |
| 3 | Assert: versions 2, 3, 4 exist for Q.id | Sequential versions recorded |

#### TC-BIZ-04: No snapshot on status change

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Toggle `is_active` on question Q | Toggle succeeds |
| 2 | Assert: no new `QuestionVersion` record created | Version count unchanged |

#### TC-BIZ-05: data JSON structure

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | After a question update, retrieve the version record | Version record retrieved |
| 2 | Assert: data contains keys: `before`, `after`, `changed_fields` | All three keys present |
| 3 | Assert: `before` and `after` are objects | Correct types |
| 4 | Assert: `changed_fields` is an array | Correct type |

#### TC-BIZ-06: version_created_by

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Update question as authenticated user U | Update succeeds |
| 2 | Assert: `version_created_by === U.id` | Version record stores user ID |

#### TC-UI-01: Question Versions tab shows in tab module

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin with full permissions | User authenticated |
| 2 | Navigate to question detail page with tab module | Page loads |
| 3 | Assert: "Question Versions" tab is visible | Tab displayed |

#### TC-UI-02: Version list page loads with paginated results

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin with full permissions | User authenticated |
| 2 | Navigate to version list tab | List page loads |
| 3 | Assert: paginated results are displayed | Pagination controls visible |

#### TC-UI-03: Version list shows version number, question, change reason, created by, created at

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin with full permissions | User authenticated |
| 2 | Navigate to version list | List page loads |
| 3 | Assert: columns for version number, question, change reason, created by, created at are displayed | All columns present |

#### TC-UI-04: Status filter (Active / Inactive / All) works

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin with full permissions | User authenticated |
| 2 | Navigate to version list with status filter | Filter controls visible |
| 3 | Select "Active" filter | Only active versions shown |
| 4 | Select "Inactive" filter | Only inactive versions shown |
| 5 | Select "All" filter | All versions shown |

#### TC-UI-05: Version number filter works

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin with full permissions | User authenticated |
| 2 | Navigate to version list with version filter | Filter controls visible |
| 3 | Enter a version number and apply filter | List filtered by version number |

#### TC-UI-06: View page displays version detail with before/after comparison

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin with full permissions | User authenticated |
| 2 | Click a version record to view detail | Detail page loads |
| 3 | Assert: before and after snapshots are displayed side by side | Comparison view visible |

#### TC-UI-07: View page shows changed fields list

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin with full permissions | User authenticated |
| 2 | Navigate to version detail page | Detail page loads |
| 3 | Assert: changed fields list is displayed | Changed fields visible |

#### TC-UI-08: Active column toggles status via AJAX

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin with full permissions | User authenticated |
| 2 | Navigate to version list | List page loads |
| 3 | Click the active toggle on a version | AJAX request made |
| 4 | Assert: status is toggled without page reload | Status updated in UI |

#### TC-UI-09: Empty state shows "No Question Versions Found"

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin with full permissions | User authenticated |
| 2 | Navigate to a question with no versions | Empty list loads |
| 3 | Assert: "No Question Versions Found" message displayed | Empty state message visible |

#### TC-UI-10: Breadcrumb navigates in same tab

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin with full permissions | User authenticated |
| 2 | Navigate to version detail page | Detail page loads |
| 3 | Click breadcrumb link to return to list | Navigates to list within same tab |

#### TC-SD-01: Soft delete sets deleted_at and is_active = false

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create version record | Record created |
| 2 | Call delete on the record | Delete succeeds |
| 3 | Assert: `deleted_at` is set | `deleted_at` timestamp populated |
| 4 | Assert: `is_active` is set to false | `is_active` is false |

#### TC-SD-02: Restore clears deleted_at

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft delete a version record | Record soft-deleted, `deleted_at` set |
| 2 | Call restore on the record | Restore succeeds |
| 3 | Assert: `deleted_at` is null | `deleted_at` cleared |

#### TC-SD-03: Force delete permanently removes record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create version record | Record created |
| 2 | Call forceDelete on the record | Force delete succeeds |
| 3 | Assert: record is removed from database | Record no longer exists |

#### TC-SD-04: Trash page lists soft-deleted records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin with full permissions | User authenticated |
| 2 | Soft delete one or more version records | Records soft-deleted |
| 3 | Navigate to trash page | Trash page loads |
| 4 | Assert: soft-deleted records are listed | Deleted records visible |

#### TC-SD-05: Force delete redirects correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin with full permissions | User authenticated |
| 2 | Navigate to trash page | Trash page loads |
| 3 | Click force delete on a trashed record | Action performed |
| 4 | Assert: redirects to correct page after force delete | Redirect successful |

#### TC-EDGE-01: Duplicate version for same question rejected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create version with `question_bank_id = Q1`, `version = 1` | Creation succeeds |
| 2 | Attempt to create another version with `question_bank_id = Q1`, `version = 1` | Operation fails |
| 3 | Assert: unique constraint violation error | Duplicate key error returned |

#### TC-EDGE-02: Version 0 or negative rejected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Build payload with `version = 0` | Payload prepared |
| 2 | Attempt insert or validation | Operation fails |
| 3 | Assert: validation error (min:1) | Error returned |
| 4 | Build payload with `version = -1` | Payload prepared |
| 5 | Attempt insert or validation | Operation fails |
| 6 | Assert: validation error (min:1) | Error returned |

#### TC-EDGE-03: Invalid question_bank_id (non-existent) rejected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Build payload with non-existent `question_bank_id` | Payload prepared |
| 2 | Attempt insert | Operation fails |
| 3 | Assert: FK constraint violation or validation error | Error returned |

#### TC-EDGE-04: Maximum version numbers (sequential increments 1..N) accepted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create question Q with `current_version = 1` | Question created |
| 2 | Perform N sequential updates | N updates succeed |
| 3 | Assert: versions 2 through N+1 exist | All sequential versions recorded |

#### TC-EDGE-05: Viewing non-existent version returns 404

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin with full permissions | User authenticated |
| 2 | Attempt to view version with non-existent ID | Request made |
| 3 | Assert: 404 response | 404 returned |

#### TC-EDGE-06: Toggle with non-boolean value rejected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin with full permissions | User authenticated |
| 2 | Send toggle request with non-boolean value | Request made |
| 3 | Assert: validation error or 422 returned | Error returned |

#### TC-BIZ-07: Activity log — Trashed on soft delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a version via destroy() — sets is_active=false and calls delete() | Soft delete succeeds |
| 2 | Verify `activityLog()` was called with the QuestionVersion model, action='Trashed', and message 'Question Version trashed' | Logged |
| 3 | Verify performed_by = authenticated user's name | Performer tracked |

#### TC-BIZ-08: Activity log — Restored on restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Restore a trashed version via restore() | Restore succeeds |
| 2 | Verify `activityLog()` called with action='Restored' and message 'Question Version restored' | Logged |

#### TC-BIZ-09: Activity log — Deleted on force delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Force-delete a version via forceDelete() | Force delete succeeds |
| 2 | Verify `activityLog()` called with action='Deleted' and message 'Question Version permanently deleted' | Logged |

#### TC-BIZ-10: Activity log — Toggled on toggle status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Toggle version status via toggleStatus() | AJAX success |
| 2 | Verify `activityLog()` called with action='Toggled' and message 'Question Version status updated' | Logged |

---

## 11) Route Reference

All routes are under module prefix `question-bank` with middleware `web`, `tenancy`, `auth`, `verified`.

| Method | URI | Name | Controller Action | Status |
|---|---|---|---|---|---|
| GET | `/question-bank/question-version` | `question-bank.question-version.index` | `index` | Returns 404 |
| GET | `/question-bank/question-version/create` | `question-bank.question-version.create` | `create` | Returns 404 (method aborted) |
| POST | `/question-bank/question-version` | `question-bank.question-version.store` | `store` | Returns 404 (method aborted) |
| GET | `/question-bank/question-version/{question_version}` | `question-bank.question-version.show` | `show` | Active |
| GET | `/question-bank/question-version/{question_version}/edit` | `question-bank.question-version.edit` | `edit` | Returns 404 (method aborted) |
| PUT/PATCH | `/question-bank/question-version/{question_version}` | `question-bank.question-version.update` | `update` | Returns 404 (method aborted) |
| DELETE | `/question-bank/question-version/{question_version}` | `question-bank.question-version.destroy` | `destroy` | Active |
| GET | `/question-bank/question-version/trash/view` | `question-bank.question-version.trashed` | `trashed` | Active |
| GET | `/question-bank/question-version/{id}/restore` | `question-bank.question-version.restore` | `restore` | Active |
| DELETE | `/question-bank/question-version/{id}/force-delete` | `question-bank.question-version.forceDelete` | `forceDelete` | Active |
| POST | `/question-bank/question-version/{question_version}/toggle-status` | `question-bank.question-version.toggleStatus` | `toggleStatus` | Active |
| GET | `/question-bank/question-version/{questionBankId}` | (custom) | `getByQuestionBank` | Active (AJAX) |

**Defined in:** `Modules/QuestionBank/routes/web.php` (lines 92–96)

```php
Route::resource('question-version', QuestionVersionController::class);
Route::get('/question-version/{id}/restore', [QuestionVersionController::class, 'restore'])->name('question-version.restore');
Route::delete('/question-version/{id}/force-delete', [QuestionVersionController::class, 'forceDelete'])->name('question-version.forceDelete');
Route::post('/question-version/{question_version}/toggle-status', [QuestionVersionController::class, 'toggleStatus'])->name('question-version.toggleStatus');
// create/store/edit/update methods return abort(404) — dead routes retained for resource route compatibility
```

---

## 12) Known Issues

1. **`index()` always returns 404** — The `abort(404)` means the main list page is inaccessible via direct route. The versions tab in the tab module uses its own index view (`question-versions/index.blade.php`) but the controller never serves it.
2. **`create`/`store`/`edit`/`update` all return 404** — These methods now return `abort(404)`. Versions are system-created immutable snapshots; `create()`/`store()`/`edit()`/`update()` are dead code paths retained only for resource route compatibility.
3. **Versions are created only by `QuestionCRUDService::update()`** — Not via the controller's `store()` (which now returns 404). The actual version creation happens in the CRUD service during question update.
4. **Blade uses `tenant.question-version.*` permissions** — The view checks `@can('tenant.question-version.status')` and `@can('tenant.question-version.view')`, but the controller does not have a `QuestionVersionPolicy` that defines these exact abilities. The controller gates against `tenant.question-bank.*` instead. If the permissions `tenant.question-version.status` or `tenant.question-version.view` are not seeded, the Active and Action columns will not render.
5. **`getByQuestionBank()` is not a named route** — It has no `->name()` in web.php, so it cannot be referenced via `route()` helper.
6. **Validation Tests Removed (TC-VAL-01 through TC-VAL-11)** — These tested `QuestionVersionRequest` validation for manual creation. However, versions are system-created by `QuestionCRUDService::update()`, not via the controller's `store()` (which now returns 404). These TCs were removed as they test a code path that is business-logically dead.

---

## 13) Feature Summary Matrix

| Category | Coverage | Notes |
|---|---|---|
| DB Schema | ✅ Full coverage | All columns, types, indexes, FK, soft deletes, unique constraint |
| Validation Rules | ⚠️ Removed | Manual-creation validation TCs removed (versions are system-created — see KI-06) |
| Authorization | ⚠️ Partial | Index is aborted (404); blade uses different permission strings than controller |
| Business Logic | ⚠️ Partial | Snapshot-on-update is tested; status-only no-snapshot is not yet automated |
| UI / Browser | ⚠️ Partial | List view, detail view, filter, toggle, empty state, breadcrumb tested |
| Soft Delete | ✅ Full coverage | Soft delete, restore, force delete, trash view, redirects |
| Edge Cases | ⚠️ Partial | Duplicate version, negative version, invalid FK, 404 tested |
| Referential Integrity | ✅ Covered | FK cascade + explicit forceDelete in service |
| Routes | ⚠️ Known issues | index/create/store/edit/update return 404, getByQuestionBank unnamed |
