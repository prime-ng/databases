# qns_QuestionBank_UsageType_TcList

## Module: QuestionBank → Question Usage Type Management

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | QuestionBank (QNS) |
| Tab Group | Question Bank (Tabbed Interface) |
| Features | Question Usage Type List, Create/Edit/View/Delete/Restore, Status Toggle (REQ-QNS-USAGE-001, 002, 003) |
| URL(s) | `/question-bank/question-usage-type`, `/question-bank/question-usage-type/create`, `/question-bank/question-usage-type/{id}/edit`, `/question-bank/question-usage-type/{id}`, `/question-bank/question-usage-type/{id}/toggle-status`, `/question-bank/question-usage-type/trash`, `/question-bank/question-usage-type/{id}/restore`, `/question-bank/question-usage-type/{id}/force-delete` |
| Controller | `Modules\QuestionBank\Http\Controllers\QuestionUsageTypeController` |
| Model(s) | `QuestionUsageType` |
| Validation | `QuestionUsageTypeRequest` (code required|string|max:50|unique, name required|string|max:100|unique, description nullable|string|max:1000) |
| Permission Gates (Controller) | Controller uses `Gate::authorize()` with `tenant.question_bank.*` (underscore) — `QuestionUsageTypePolicy` (`tenant.question-usage-type.*`) exists but is **NOT wired** to controller |
| Soft Deletes | Yes — supports soft deletes |
| Events | Activity log on toggleStatus (`activityLog()`) |

---

## 2. Pre-conditions

- Required permissions (controller gates): `tenant.question_bank.viewAny`, `.create`, `.update`, `.view`, `.delete`, `.restore`, `.forceDelete`
- For referential integrity tests: At least one record in `qns_question_usage_log` referencing a usage type must exist
- Default pre-seeded data must exist: QUIZ, QUEST, ONLINE_EXAM, OFFLINE_EXAM

---

## 3. Default Data Load

### 3.1 Filter Data for Usage Type List

The `QuestionUsageTypeService::getFilterData()` method returns:
- `usageTypes` — Active question usage types
- `usageTypeCounts` — Count of questions per usage type
- `usageTypeStatuses` — Active/Inactive status filter

### 3.2 Create/Edit Form Data

The `QuestionUsageTypeService::getCreateData()` and `getEditData()` methods populate:
- All filter data above
- Usage type data with relations (for edit)

---

## 4. BC-DB — Database Schema

### 4.1 `qns_question_usage_type` — Question Usage Type Table

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| code | VARCHAR(50) | NOT NULL | — | Unique usage type code |
| name | VARCHAR(100) | NOT NULL | — | Unique usage type display name |
| description | TEXT | YES | NULL | Optional description |
| is_active | TINYINT(1) | YES | 1 | Active flag |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | Update time |
| deleted_at | TIMESTAMP | YES | NULL | Soft delete time |

**Indexes:**
- PRIMARY KEY (`id`)
- UNIQUE KEY `uq_usage_type_code` (`code`)
- UNIQUE KEY `uq_usage_type_name` (`name`)
- KEY `idx_usage_type_active` (`is_active`)

---

## 5. BC-VAL — Validation Rules

### 5.1 QuestionUsageTypeRequest Validation

| Field | Rules | Error Message |
|-------|-------|---------------|
| code | required, string, max:100, unique:qns_question_usage_type,code | "Code is required." / "This code already exists." |
| name | required, string, max:255 | "Name is required." (NO unique constraint on name) |
| description | nullable, string | —
| is_active | nullable, boolean | — |

---

## 6. BC-AUTH — Authorization

| Controller Method | Gate Used | Notes |
|-------------------|-----------|-------|
| index() | `tenant.question_bank.viewAny` | Returns 404 (abort) — gate never reached |
| create() | `tenant.question_bank.create` | Policy NOT wired; uses question_bank namespace |
| store() | `tenant.question_bank.create` | Same as create |
| show() | `tenant.question_bank.view` | Policy NOT wired |
| edit() | `tenant.question_bank.update` | Policy NOT wired |
| update() | `tenant.question_bank.update` | Policy NOT wired |
| destroy() | `tenant.question_bank.delete` | No pre-seeded or usage check (code gap) |
| trashed() | `tenant.question_bank.restore` | Policy NOT wired |
| restore() | `tenant.question_bank.restore` | Policy NOT wired |
| forceDelete() | `tenant.question_bank.forceDelete` | No pre-seeded or usage check (code gap) |
| toggleStatus() | `tenant.question_bank.update` | Not using `.status` gate |

**Note:** `QuestionUsageTypePolicy` defines `tenant.question-usage-type.*` gates but controller bypasses it entirely — policy is unreachable.

**Blade @can directives used in views:**
- `@can('tenant.question-usage-type.status')` — Status toggle column
- `@can('tenant.question-usage-type.view')` — View action button
- `@can('tenant.question-usage-type.edit')` / `@can('tenant.question-usage-type.update')` — Edit action button
- `@can('tenant.question-usage-type.delete')` — Delete action button

---

## 7. BC-BIZ — Business Logic

| BC-BIZ ID | Rule | Description |
|-----------|------|-------------|
| BC-BIZ-01 | Unique Code Constraint | `code` must be unique across all records; validated in FormRequest with `unique:qns_question_usage_type,code` |
| BC-BIZ-02 | Unique Name Constraint | `name` must be unique across all records; validated in FormRequest with `unique:qns_question_usage_type,name` |
| BC-BIZ-03 | Pre-seeded Defaults | 4 default records seeded: QUIZ, QUEST, ONLINE_EXAM, OFFLINE_EXAM — these should not be deleted if referenced |
| BC-BIZ-04 | Code Format Convention | Codes stored in UPPER_SNAKE_CASE convention (e.g., QUIZ, ONLINE_EXAM) |
| BC-BIZ-05 | Soft Delete | `destroy()` sets `deleted_at` and `is_active = false` (NO pre-seeded or usage check — code gap) |
| BC-BIZ-06 | Force Delete | `forceDelete()` permanently removes record unconditionally (NO pre-seeded or usage check — code gap) |
| BC-BIZ-07 | Activity Logging | `store()`, `update()`, `destroy()`, `restore()`, `forceDelete()` call `activityLog()` with appropriate event name, message, and `performed_by` — all 5 operations logged |

---

## 8. BC-REF — Referential Integrity

| Foreign Key | Column | References Table | On Delete |
|-------------|--------|-----------------|-----------|
| fk_usage_log_type | qns_question_usage_log.question_usage_type_id | qns_question_usage_type.id | CASCADE |
| fk_diff_config_usage_type | lms_quiz_diff_config.usage_type_id | qns_question_usage_type.id | RESTRICT | Quiz difficulty distribution config references usage type |
| fk_quiz_type_usage_type | exm_exam_type.assessment_usage_type_id | qns_question_usage_type.id | RESTRICT | Exam type references usage type |

---

## 9. Test Case Summary

### 9.1 Question Usage Type — Positive TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-UT-P01 | Usage Type CRUD | Positive | Usage type list loads with pagination and filters | 4 |
| TC-UT-P02 | Usage Type CRUD | Positive | Create usage type — all required fields | 5 |
| TC-UT-P03 | Usage Type CRUD | Positive | Create usage type — with description | 5 |
| TC-UT-P04 | Usage Type CRUD | Positive | Edit usage type — update name and description | 5 |
| TC-UT-P05 | Usage Type CRUD | Positive | View usage type detail | 4 |
| TC-UT-P06 | Usage Type CRUD | Positive | Toggle status — active to inactive | 4 |
| TC-UT-P07 | Usage Type CRUD | Positive | Toggle status — inactive to active | 4 |
| TC-UT-P08 | Usage Type CRUD | Positive | Soft-delete usage type — no usage log reference | 5 |
| TC-UT-P09 | Usage Type CRUD | Positive | Restore usage type from trash | 4 |
| TC-UT-P10 | Usage Type CRUD | Positive | Pre-seeded records visible in list | 3 |

### 9.2 Question Usage Type — Negative TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-UT-N01 | Usage Type CRUD | Negative | Create — missing required code | 2 |
| TC-UT-N02 | Usage Type CRUD | Negative | Create — missing required name | 2 |
| TC-UT-N03 | Usage Type CRUD | Negative | Create — duplicate code | 2 |
| TC-UT-N04 | Usage Type CRUD | Negative | Create — code exceeds max 100 characters | 2 |
| TC-UT-N05 | Usage Type CRUD | Negative | Create — name exceeds max 255 characters | 2 |
| TC-UT-N06 | Usage Type CRUD | Negative | Edit — duplicate code (existing different record) | 2 |
| TC-UT-N07 | Usage Type CRUD | Negative | Permission — index without viewAny | 2 |
| TC-UT-N08 | Usage Type CRUD | Negative | Permission — create without create gate | 2 |
| TC-UT-N09 | Usage Type CRUD | Negative | Permission — edit without update gate | 2 |
| TC-UT-N10 | Usage Type CRUD | Negative | Permission — delete without delete gate | 2 |

### 9.3 Code Review TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-CR01 | Code Review | Review | index() — Gate check + pagination + filter data | 4 |
| TC-CR02 | Code Review | Review | store() — Validation + try-catch + redirect | 4 |
| TC-CR03 | Code Review | Review | update() — Usage type update flow | 4 |
| TC-CR04 | Code Review | Review | toggleStatus() — Activity log invocation | 3 |
| TC-CR05 | Code Review | Review | QuestionUsageTypeRequest — Code unique validation with ignore on update | 4 |
| TC-CR06 | Code Review | Review | Blade @can directives in index view | 3 |
| TC-CR07 | Code Review | Review | Flash messages on store/update/destroy/restore/forceDelete | 5 |
| TC-CR08 | Code Review | Review | Pre-seeded data seeder — 4 default records | 3 |

### 9.4 Dependency TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-D01 | Dependency | Dependency | Referential integrity — FK CASCADE when usage type deleted | 4 |
| TC-D02 | Dependency | Dependency | Pre-seeded data — records present after fresh migration/seed | 3 |
| TC-D03 | Dependency | Dependency | Activity log entry created on toggleStatus | 3 |
| TC-D04 | Dependency | Dependency | Cross-module RESTRICT — Quiz diff_config blocks usage type delete | 3 |
| TC-D05 | Dependency | Dependency | Cross-module RESTRICT — Exam type blocks usage type delete | 3 |

---

## 10. Test Case Steps

### 10.1 Positive TC Steps — Question Usage Type CRUD

#### TC-UT-P01: Usage type list loads with pagination and filters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.question-usage-type.viewAny` permission navigates to Question Usage Type page | Page loads |
| 2 | Verify table columns: #, Code, Name, Description, Active toggle, Action | All columns present |
| 3 | Verify pagination (20 per page) | Paginated |
| 4 | Verify Add New button visible based on permission | Conditional visibility |

#### TC-UT-P02: Create usage type — all required fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.question-usage-type.create` permission clicks "Add New" | Create form loads |
| 2 | Enter code = `ASSIGNMENT` | Code entered |
| 3 | Enter name = `Assignment` | Name entered |
| 4 | Click Save | Redirected to list |
| 5 | Verify new usage type appears in the list with correct code and name | Usage type created |

#### TC-UT-P03: Create usage type — with description

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open create form | Form loads |
| 2 | Enter code = `PRACTICAL` | Code entered |
| 3 | Enter name = `Practical Exam` | Name entered |
| 4 | Enter description = `Hands-on practical examination conducted in lab` | Description entered |
| 5 | Click Save | Usage type created with description populated |

#### TC-UT-P04: Edit usage type — update name and description

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open edit for existing usage type (e.g., QUIZ) | Edit form loads with pre-filled data |
| 2 | Change name to `Quiz (Updated)` | Name updated |
| 3 | Add/update description = `Updated quiz usage type description` | Description updated |
| 4 | Click Save | Redirected to list |
| 5 | Verify list shows updated name | Updated |

#### TC-UT-P05: View usage type detail

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.question-usage-type.view` permission clicks View on a usage type | Detail view loads |
| 2 | Verify code displayed | Code visible |
| 3 | Verify name displayed | Name visible |
| 4 | Verify description displayed (if any) | Description visible |

#### TC-UT-P06: Toggle status — active to inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User with `tenant.question-usage-type.status` permission clicks toggle on active usage type | Toggle action triggers |
| 2 | Verify success flash message | Message shown |
| 3 | Verify status column shows "Inactive" badge | Status updated |
| 4 | Verify DB: `is_active = 0` for the record | DB verified |

#### TC-UT-P07: Toggle status — inactive to active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User clicks toggle on inactive usage type | Toggle action triggers |
| 2 | Verify success flash message | Message shown |
| 3 | Verify status column shows "Active" badge | Status updated |
| 4 | Verify DB: `is_active = 1` for the record | DB verified |

#### TC-UT-P08: Soft-delete usage type — no usage log reference

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open delete for a usage type with no usage log references | Confirmation prompt |
| 2 | Confirm delete | Usage type soft-deleted |
| 3 | Verify usage type in Trash view | In trash |
| 4 | Verify DB: `deleted_at` is not null | Soft-deleted |
| 5 | Verify usage type does not appear in active list | Hidden |

#### TC-UT-P09: Restore usage type from trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash view | Trash list loads with soft-deleted records |
| 2 | User with `tenant.question-usage-type.restore` permission clicks Restore | Restore action triggers |
| 3 | Verify success flash message | Message shown |
| 4 | Verify usage type removed from trash and appears in active list | Restored |

#### TC-UT-P10: Pre-seeded records visible in list

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to usage type list | List loads |
| 2 | Verify QUIZ, QUEST, ONLINE_EXAM, OFFLINE_EXAM are present | All 4 pre-seeded records visible |
| 3 | Verify each has correct code and name mapping | Data integrity maintained |

### 10.2 Negative TC Steps — Question Usage Type CRUD

#### TC-UT-N01: Create — missing required code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form without code | Validation error |
| 2 | Verify error: "The code field is required." | Error shown |

#### TC-UT-N02: Create — missing required name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form without name | Validation error |
| 2 | Verify error: "The name field is required." | Error shown |

#### TC-UT-N03: Create — duplicate code

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create with code = `QUIZ` (already exists) | Validation error |
| 2 | Verify error: "The code has already been taken." | Error shown |

#### TC-UT-N04: Create — code exceeds max 100 characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create with code of 101+ characters | Validation error |
| 2 | Verify error: "The code must not be greater than 100 characters." | Error shown |

#### TC-UT-N05: Create — name exceeds max 255 characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create with name of 256+ characters | Validation error |
| 2 | Verify error: "The name must not be greater than 255 characters." | Error shown |

#### TC-UT-N06: Edit — duplicate code (existing different record)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Edit usage type "QUEST", change code to `QUIZ` | Code conflict |
| 2 | Submit | Error: "This code already exists." |

<!-- TC-UT-N07 removed — name has no unique constraint in code -->
<!-- TC-UT-N08 removed — pre-seeded protection does not exist in code -->
<!-- TC-UT-N09 removed — usage check does not exist in code -->
<!-- TC-UT-N10 removed — pre-seeded protection does not exist in code -->

#### TC-UT-N07: Permission — index without viewAny

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.question_bank.viewAny` accesses index | 403 Forbidden |

#### TC-UT-N08: Permission — create without create gate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.question_bank.create` accesses create | 403 Forbidden |

#### TC-UT-N09: Permission — edit without update gate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.question_bank.update` accesses edit | 403 Forbidden |

#### TC-UT-N10: Permission — delete without delete gate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User without `tenant.question_bank.delete` attempts delete | 403 Forbidden |

<!-- TC-UT-N11 removed — usage check does not exist in code -->

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Attempt to force delete a usage type that has records in `qns_question_usage_log` | Usage check triggers |
| 2 | Verify error: "Cannot force delete. This usage type is referenced in usage logs." | Error shown |

### 10.3 Code Review TC Steps

#### TC-CR01: index() — Gate check + pagination (index aborts 404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.question_bank.viewAny')` at method start | Gate present (but never reached — abort(404) comes first) |
| 2 | Review pagination: `QuestionUsageType::orderBy('name')->paginate(10)` | 10 per page |
| 3 | Review `compact()` includes variable for view | Variable passed |

#### TC-CR02: store() — Validation + redirect (no try-catch)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.question_bank.create')` | Gate present |
| 2 | Review request type-hint: `QuestionUsageTypeRequest $request` | Validation injected |
| 3 | Review `QuestionUsageType::create($request->validated())` | Model created |
| 4 | Note: No try-catch block present — error not handled locally | Gap identified |

#### TC-CR03: update() — Usage type update flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.question_bank.update')` | Gate present |
| 2 | Review manual resolution: `$id` → `findOrFail($id)` (no route model binding) | Manual resolution |
| 3 | Review `$questionUsageType->update($request->validated())` | Model updated |
| 4 | Review redirect with flash success message | Flash message present |

<!-- TC-CR04 removed — destroy() has NO pre-seeded check or usage check -->
<!-- TC-CR05 removed — forceDelete() has NO pre-seeded check or usage check -->

#### TC-CR04: toggleStatus() — Activity log invocation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Gate::authorize('tenant.question_bank.update')` | Gate present |
| 2 | Review toggle logic: `$questionUsageType->is_active = !$questionUsageType->is_active` | Toggle present |
| 3 | Review `activityLog()` call after status change | Activity logged |

#### TC-CR05: QuestionUsageTypeRequest — Code unique validation with ignore on update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `rules()` method for `code` field | `unique:qns_question_usage_type,code` present (name has NO unique rule) |
| 2 | Review route binding to ignore current record on code update | Ignore logic present via `$this->route('question_usage_type') ?? $this->route('id')` |
| 3 | Review custom error messages | Messages configured: "Code is required.", "This code already exists." |

#### TC-CR06: Blade @can directives in index view

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `@can('tenant.question-usage-type.edit')` around edit button | Note: policy has `update()`, not `edit()` — `tenant.question-usage-type.edit` permission may not be seeded |
| 2 | Review `@can('tenant.question-usage-type.delete')` around delete button | Delete button gated |

#### TC-CR07: Flash messages on store/update/destroy/restore/forceDelete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review store() — `flash('created.question_usage_type')` | Flash present (translation helper, not hardcoded) |
| 2 | Review update() — `flash('updated.question_usage_type')` | Flash present |
| 3 | Review destroy() — `flash('trashed.question_usage_type')` | Flash present |
| 4 | Review restore() — `flash('restored.question_usage_type')` | Flash present |
| 5 | Review forceDelete() — `flash('force_deleted.question_usage_type')` | Flash present |

#### TC-CR08: Pre-seeded data seeder — 4 default records

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review seeder class `QuestionUsageTypeSeeder` | Seeder exists |
| 2 | Verify records: ('QUIZ','Quiz'), ('QUEST','Quest'), ('ONLINE_EXAM','Online Exam'), ('OFFLINE_EXAM','Offline Exam') | All 4 records |
| 3 | Review `is_active = 1` and timestamps set for each | Defaults correct |

### 10.4 Dependency TC Steps

#### TC-D01: Referential integrity — FK CASCADE when usage type deleted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Usage type UT1 has 3 records in `qns_question_usage_log` | Log records exist |
| 2 | Force delete UT1 (bypass service-level check for test) | UT1 deleted |
| 3 | Verify `qns_question_usage_log` records referencing UT1 are also deleted | CASCADE works |
| 4 | Verify other usage types and their log records unaffected | No side effects |

#### TC-D02: Pre-seeded data — records present after fresh migration/seed

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Run `php artisan migrate:fresh --seed` | Migration and seed complete |
| 2 | Query `qns_question_usage_type` table | 4 records present |
| 3 | Verify codes: QUIZ, QUEST, ONLINE_EXAM, OFFLINE_EXAM | All seeded |

#### TC-D03: Activity log entry created on toggleStatus

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Toggle status of a usage type | Toggle action triggers |
| 2 | Verify `activity_log` table has entry with event = `QuestionUsageType Toggled` | Log entry created |
| 3 | Verify log contains old and new status values | Status change captured |

#### TC-D04: Cross-module RESTRICT — Quiz diff_config blocks usage type delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Usage type UT1 (e.g., QUIZ) is referenced by `lms_quiz_diff_config.usage_type_id` for a quiz difficulty config | Reference exists |
| 2 | Attempt to force delete UT1 | Operation blocked (integrity constraint violation from FK RESTRICT) |
| 3 | Verify UT1 still exists in `qns_question_usage_type` | Usage type preserved |

#### TC-D05: Cross-module RESTRICT — Exam type blocks usage type delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Usage type UT1 (e.g., ONLINE_EXAM) is referenced by `exm_exam_type.assessment_usage_type_id` for an exam type | Reference exists |
| 2 | Attempt to force delete UT1 | Operation blocked (integrity constraint violation from FK RESTRICT) |
| 3 | Verify UT1 still exists in `qns_question_usage_type` | Usage type preserved |

---

## 11. Route Reference

| Method | URL | Name | Controller Method | Required Permission |
|--------|-----|------|-------------------|---------------------|
| GET | `/question-bank/question-usage-type` | question-bank.question-usage-type.index | index() | tenant.question_bank.viewAny (but abort(404)) |
| GET | `/question-bank/question-usage-type/create` | question-bank.question-usage-type.create | create() | tenant.question_bank.create |
| POST | `/question-bank/question-usage-type` | question-bank.question-usage-type.store | store() | tenant.question_bank.create |
| GET | `/question-bank/question-usage-type/{question_usage}` | question-bank.question-usage-type.show | show() | tenant.question_bank.view |
| GET | `/question-bank/question-usage-type/{question_usage}/edit` | question-bank.question-usage-type.edit | edit() | tenant.question_bank.update |
| PUT | `/question-bank/question-usage-type/{question_usage}` | question-bank.question-usage-type.update | update() | tenant.question_bank.update |
| DELETE | `/question-bank/question-usage-type/{question_usage}` | question-bank.question-usage-type.destroy | destroy() | tenant.question_bank.delete |
| POST | `/question-bank/question-usage-type/{question_usage}/toggle-status` | question-bank.question-usage-type.toggleStatus | toggleStatus() | tenant.question_bank.update |
| GET | `/question-bank/question-usage-type/trash/view` | question-bank.question-usage-type.trashed | trashed() | tenant.question_bank.restore |
| GET | `/question-bank/question-usage-type/{id}/restore` | question-bank.question-usage-type.restore | restore() | tenant.question_bank.restore |
| DELETE | `/question-bank/question-usage-type/{id}/force-delete` | question-bank.question-usage-type.forceDelete | forceDelete() | tenant.question_bank.forceDelete |

---

## 12. Known Issues

| # | Issue | Severity | Details |
|---|-------|----------|---------|
| KI-01 | Pre-seeded protection NOT implemented | **High** | `destroy()` and `forceDelete()` have NO pre-seeded check (`id <= 4`). Pre-seeded records CAN be deleted despite BC-BIZ documentation |
| KI-02 | Usage-log check NOT implemented | **High** | `destroy()` and `forceDelete()` have NO usage-log check. Records with usage references CAN be deleted, causing FK cascade data loss |
| KI-03 | Permission namespace mismatch | **Medium** | Controller uses `tenant.question_bank.*` (underscore), policy defines `tenant.question-usage-type.*` — policy is **not wired** to controller |
| KI-04 | Controller index returns 404 | **High** | index() has `abort(404)` at line 22 — list page is dead via direct route; only accessible via QuestionBank tab module |

---

## 13. Feature Summary Matrix

| Feature | REQ ID | Controller Method(s) | Key Models | Pagination |
|---------|--------|---------------------|------------|------------|
| Usage Type List | REQ-QNS-USAGE-001 | index() | QuestionUsageType | 10 per page |
| Create Usage Type | REQ-QNS-USAGE-001, 002 | create(), store() | QuestionUsageType | None (form) |
| Edit Usage Type | REQ-QNS-USAGE-001 | edit(), update() | QuestionUsageType | None (form) |
| View Usage Type | REQ-QNS-USAGE-001 | show() | QuestionUsageType | None |
| Delete/Restore | REQ-QNS-USAGE-001 | destroy(), trashed(), restore(), forceDelete() | QuestionUsageType | None |
| Status Toggle | REQ-QNS-USAGE-003 | toggleStatus() | QuestionUsageType | None |

(End of file)
