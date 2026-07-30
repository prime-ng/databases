# qns_QuestionBank_Tags_TcList

## Module: QuestionBank → Question Tags → Tag CRUD & Management

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | QuestionBank (QNS) |
| Tab Group | Question Tags (Tabbed under Question Bank) |
| Feature | Tag List, Create, View, Edit, Soft Delete/Restore/Force Delete, Status Toggle (AJAX) |
| URL(s) | `/question-bank/question-tag` (resource index/create/store/show/edit/update/destroy), `/question-bank/question-tag/trash/view` (trashed), `/question-bank/question-tag/{id}/restore` (restore), `/question-bank/question-tag/{id}/force-delete` (forceDelete), `/question-bank/question-tag/{question_tag}/toggle-status` (toggleStatus) |
| Controller | `Modules\QuestionBank\Http\Controllers\QuestionTagController` |
| Model(s) | `QuestionTag` (`Modules\QuestionBank\Models\QuestionTag`) — `SoftDeletes` trait |
| Validation (Create/Update) | `QuestionTagRequest` (`Modules\QuestionBank\Http\Requests\QuestionTagRequest`) |
| Permission Gates (Policy) | `tenant.question-tag.viewAny`, `.view`, `.create`, `.update`, `.delete`, `.restore`, `.forceDelete`, `.status` |
| Permission Gates (Controller) | `tenant.question_bank.viewAny`, `.view`, `.create`, `.update`, `.delete`, `.restore`, `.forceDelete` (mismatch — see KI-01) |
| Soft Deletes | Yes — `SoftDeletes` trait on QuestionTag |
| Activity Log Events | `Stored`, `Updated`, `Trashed`, `Restored`, `Deleted`, `Status Toggled` |
| Auto-Generated Fields | `created_at`, `updated_at` (timestamps) |

---

## 2. Pre-conditions

- Required permissions: `tenant.question-tag.viewAny`, `.create`, `.update`, `.view`, `.delete`, `.restore`, `.forceDelete`, `.status`
- For create/edit tests: Valid form data for short_name (unique) and name
- For unique short_name tests: At least one existing Question Tag record
- For cascade tests: At least one question in `qns_questions_bank` with junction records in `qns_question_questiontag_jnt`
- For trash/restore tests: At least one soft-deleted Question Tag
- For usage-constraint tests: Tag must be linked to questions via `qns_question_questiontag_jnt`

---

## 3. Default Data Load

When index tab loads (GET `/question-bank/question-bank?tab=question_tags`):

| Data | Source | Query | Pagination |
|------|--------|-------|------------|
| Question Tags | `QuestionTag::orderBy('name')->paginate(10)` | Ordered by name | 10 per page |

When create page loads (GET `/question-bank/question-tag/create`):

| Data | Source | Notes |
|------|--------|-------|
| Form (empty) | New blank form | Fields: short_name, name, is_active |

When edit page loads (GET `/question-bank/question-tag/{questionTag}/edit`):

| Data | Source | Notes |
|------|--------|-------|
| Question Tag (existing) | `QuestionTag::findOrFail($id)` | Pre-filled values |
| Status override | `old('is_active', $questionTag->is_active)` | Preserved from old input |

When view page loads (GET `/question-bank/question-tag/{questionTag}`):

| Data | Source | Notes |
|------|--------|-------|
| Question Tag (with trashed) | `QuestionTag::withTrashed()->findOrFail($id)` | Shows even soft-deleted |
| All attributes displayed | Short Name, Tag Name, Status, Created At, Updated At | Read-only |

---

## 4. BC-DB — Database Schema

### `qns_question_tags` — Question Tags Table

| BC-DB ID | Column | Type | Nullable | Default | Constraints | Notes |
|----------|--------|------|----------|---------|-------------|-------|
| BC-DB-01 | id | INT UNSIGNED | NOT NULL | | PK, AUTO_INCREMENT | Surrogate primary key |
| BC-DB-02 | short_name | VARCHAR(100) | NOT NULL | | UNIQUE (uq_qtag_short) | Unique short identifier |
| BC-DB-03 | name | VARCHAR(255) | NOT NULL | | | Full tag name |
| BC-DB-04 | is_active | TINYINT(1) | NOT NULL | 1 | | Boolean status |
| BC-DB-05 | created_at | TIMESTAMP | NULL | CURRENT_TIMESTAMP | | |
| BC-DB-06 | updated_at | TIMESTAMP | NULL | ON UPDATE CURRENT_TIMESTAMP | | |
| BC-DB-07 | deleted_at | TIMESTAMP | NULLABLE | NULL | | Soft delete marker |

Unique keys: `uq_qtag_short` (short_name).

---

## 5. BC-VAL — Validation Rules

### 5.1 Create & Update Validation — BC-VAL

Source: `Modules\QuestionBank\Http\Requests\QuestionTagRequest::rules()`

| BC-VAL ID | Field | Rule(s) | Error Message (Expected) |
|-----------|-------|---------|--------------------------|
| BC-VAL-01 | short_name | required, string, max:100, unique:qns_question_tags,short_name | "Short name is required." / "This short name already exists." |
| BC-VAL-02 | name | required, string, max:255 | "Name is required." |

### 5.2 Authorization in Request

Source: `QuestionTagRequest::authorize()`

| BC-VAL ID | Method | Permission Check | Notes |
|-----------|--------|------------------|-------|
| BC-VAL-AUTH-01 | POST (create) | `Gate::allows('tenant.question-bank.create')` | Uses `question-bank` namespace (dash) |
| BC-VAL-AUTH-02 | PUT/PATCH (update) | `Gate::allows('tenant.question-bank.update')` | Uses `question-bank` namespace (dash) |

---

## 6. BC-AUTH — Authorization

### 6.1 Policy Gates

Source: `Modules\QuestionBank\Policies\QuestionTagPolicy`

| BC-AUTH ID | Gate Name | Policy Method | Permission String | Scope |
|------------|-----------|---------------|-------------------|-------|
| BC-AUTH-01 | viewAny | `viewAny(User $user): bool` | `tenant.question-tag.viewAny` | List all tags |
| BC-AUTH-02 | view | `view(User $user, QuestionTag $tag): bool` | `tenant.question-tag.view` | Single tag show |
| BC-AUTH-03 | create | `create(User $user): bool` | `tenant.question-tag.create` | Create new tag |
| BC-AUTH-04 | update | `update(User $user, QuestionTag $tag): bool` | `tenant.question-tag.update` | Edit/update/toggle |
| BC-AUTH-05 | delete | `delete(User $user, QuestionTag $tag): bool` | `tenant.question-tag.delete` | Soft delete |
| BC-AUTH-06 | restore | `restore(User $user, QuestionTag $tag): bool` | `tenant.question-tag.restore` | Restore from trash |
| BC-AUTH-07 | forceDelete | `forceDelete(User $user, QuestionTag $tag): bool` | `tenant.question-tag.forceDelete` | Permanent delete |
| BC-AUTH-08 | status | `status(User $user): bool` | `tenant.question-tag.status` | Toggle active status |

### 6.2 Controller Gate Calls (MISMATCH — see KI-01)

| BC-AUTH ID | Controller Method | Gate String Used | Expected (Policy) |
|------------|-------------------|------------------|-------------------|
| BC-AUTH-C-01 | index | `tenant.question_bank.viewAny` | `tenant.question-tag.viewAny` |
| BC-AUTH-C-02 | create | `tenant.question_bank.create` | `tenant.question-tag.create` |
| BC-AUTH-C-03 | store | `tenant.question_bank.create` | `tenant.question-tag.create` |
| BC-AUTH-C-04 | show | `tenant.question_bank.view` | `tenant.question-tag.view` |
| BC-AUTH-C-05 | edit | `tenant.question_bank.update` | `tenant.question-tag.update` |
| BC-AUTH-C-06 | update | `tenant.question_bank.update` | `tenant.question-tag.update` |
| BC-AUTH-C-07 | destroy | `tenant.question_bank.delete` | `tenant.question-tag.delete` |
| BC-AUTH-C-08 | trashed | `tenant.question_bank.restore` | `tenant.question-tag.restore` |
| BC-AUTH-C-09 | restore | `tenant.question_bank.restore` | `tenant.question-tag.restore` |
| BC-AUTH-C-10 | forceDelete | `tenant.question_bank.forceDelete` | `tenant.question-tag.forceDelete` |
| BC-AUTH-C-11 | toggleStatus | `tenant.question_bank.update` | `tenant.question-tag.update` / `tenant.question-tag.status` |

### 6.3 Blade View Permission Checks

| BC-AUTH ID | View File | Directive | Permission | Purpose |
|------------|-----------|-----------|------------|---------|
| BC-AUTH-V-01 | `question-tags/index.blade.php:58` | `@can('tenant.question-tag.status')` | tenant.question-tag.status | Shows Active column header |
| BC-AUTH-V-02 | `question-tags/index.blade.php:61` | `@canany(['tenant.question-tag.view', 'tenant.question-tag.update', 'tenant.question-tag.delete'])` | view/update/delete | Shows Action column header |
| BC-AUTH-V-03 | `question-tags/index.blade.php:87` | `@can('tenant.question-tag.status')` | tenant.question-tag.status | Shows status switch per row |
| BC-AUTH-V-04 | `question-tags/index.blade.php:96` | `@canany(['tenant.question-tag.view', 'tenant.question-tag.update', 'tenant.question-tag.delete'])` | view/update/delete | Shows action buttons per row |
| BC-AUTH-V-05 | `question-tags/view.blade.php:28` | `@can('tenant.question-tag.edit')` | tenant.question-tag.edit | Shows Edit button — **MISMATCH**: Policy has `update()` method, not `edit()`; the `@can` relies on Laravel's fallback convention (no explicit `.edit` gate in policy) |
| BC-AUTH-V-06 | `question-tags/trash.blade.php:25` | `@canany(['tenant.question-tag.restore', 'tenant.question-tag.forceDelete'])` | restore/forceDelete | Shows trash action column header |
| BC-AUTH-V-07 | `question-tags/trash.blade.php:55` | `@canany(['tenant.question-tag.restore', 'tenant.question-tag.forceDelete'])` | restore/forceDelete | Shows restore/force-delete buttons per row |

---

## 7. BC-BIZ — Business Logic

### 7.1 Business Rules

| BC-BIZ ID | Rule | Description | Enforcement Point |
|-----------|------|-------------|-------------------|
| BC-BIZ-01 | Short Name Uniqueness | `short_name` must be unique across all tags (`uq_qtag_short`); on update, exclude self | `QuestionTagRequest` rule `unique:qns_question_tags,short_name,{id}` + DB unique index |
| BC-BIZ-02 | Soft Delete Deactivates | Soft delete sets `is_active = false` before calling `$questionTag->delete()` | Controller `destroy()` method |
| BC-BIZ-03 | Force Delete Cascade | Force delete permanently removes tag; cascade FK deletes junction records | Controller `forceDelete()` calls `$questionTag->forceDelete()`; FK cascade handles `qns_question_questiontag_jnt` |
| BC-BIZ-04 | Status Toggle (AJAX) | Toggle inverts `is_active` via AJAX POST; returns JSON response with new state | Controller `toggleStatus()` — no validation request, toggles directly |
| BC-BIZ-05 | Activity Logging | Every action (Stored, Updated, Trashed, Restored, Deleted, Status Toggled) creates activity log entry | Controller after each action via `activityLog()` helper |
| BC-BIZ-06 | View with Trashed | `show()` uses `withTrashed()` — soft-deleted tags are still viewable | Controller `show()` method |
| BC-BIZ-07 | No Cascade on Soft Delete | Soft delete does NOT cascade to junction table (junction records remain intact) | FK ON DELETE CASCADE only triggers on actual row deletion (force delete) |
| BC-BIZ-08 | Default is_active | New tags default to `is_active = 1` (active) | DDL default + migration boolean default(true) |

### 7.2 Model Attributes

| BC-BIZ ID | Attribute | Type | Notes |
|-----------|-----------|------|-------|
| BC-BIZ-ATTR-01 | `$fillable` | `['short_name', 'name', 'is_active']` | Mass-assignable fields |
| BC-BIZ-ATTR-02 | `$casts` | `is_active => boolean`, timestamps => datetime | Attribute casting |
| BC-BIZ-ATTR-03 | `$table` | `qns_question_tags` | DB table name |
| BC-BIZ-ATTR-04 | `$primaryKey` | `id` | Primary key |

### 7.3 Model Scopes

| BC-BIZ ID | Scope | Status | Notes |
|-----------|-------|--------|-------|
| BC-BIZ-SCP-01 | `active` | ❌ Does not exist | No `scopeActive()` defined on QuestionTag or BaseModel |
| BC-BIZ-SCP-02 | `search` | ❌ Does not exist | No `scopeSearch()` defined on QuestionTag or BaseModel; search is handled at controller level |

---

## 8. BC-REF — Referential Integrity

### Foreign Keys on `qns_question_tags`

None — `qns_question_tags` is a parent table with no FK columns.

### Foreign Keys Referencing `qns_question_tags`

| BC-REF ID | Child Table | FK Name | Foreign Key Column | Referenced Column | On Delete | Notes |
|-----------|-------------|---------|--------------------|-------------------|-----------|-------|
| BC-REF-01 | `qns_question_questiontag_jnt` | `fk_qtag_tag` | `tag_id` | `qns_question_tags.id` | CASCADE | Junction table; cascades on force delete |
| BC-REF-03 | `qns_question_questiontag_jnt` | `fk_qtag_q` | `question_bank_id` | `qns_questions_bank.id` | CASCADE | Force-deleting a question cascades to junction |

### Unique Keys

| BC-REF ID | Constraint Name | Column(s) | Purpose |
|-----------|-----------------|-----------|---------|
| BC-REF-02 | `uq_qtag_short` | `short_name` | Short name uniqueness |

---

## 9. Test Case Summary

### 9.1 Positive TC Summary

| TC ID | Test Case Name | Type | Area | Priority |
|-------|---------------|------|------|----------|
| TC-P01 | Create — Minimal Tag with required fields | Functional | Creation | High |
| TC-P02 | Create — Tag with all fields (including is_active) | Functional | Creation | High |
| TC-P03 | Create — Short name uniqueness with different tags | Functional | Creation | High |
| TC-P04 | Create — Short name with max length (100 chars) | Edge Case | Creation | Medium |
| TC-P05 | Create — Name with max length (255 chars) | Edge Case | Creation | Medium |
| TC-P06 | Show — View tag details (active) | Functional | View | High |
| TC-P07 | Show — View tag details (soft-deleted) | Functional | View | Medium |
| TC-P08 | Edit — Update short_name | Functional | Edit | High |
| TC-P09 | Edit — Update name | Functional | Edit | High |
| TC-P10 | Edit — Update is_active status via edit form | Functional | Edit | Medium |
| TC-P11 | Edit — Short name uniqueness on update (exclude self) | Functional | Edit | High |
| TC-P12 | Destroy — Soft delete unused tag | Functional | Soft Delete | High |
| TC-P13 | Trashed — View trash listing | Functional | Trash | Medium |
| TC-P14 | Restore — Restore soft-deleted tag | Functional | Restore | High |
| TC-P15 | Force Delete — Permanently delete unused tag | Functional | Force Delete | High |
| TC-P16 | Toggle Status — Activate/Deactivate tag (AJAX) | Functional | Status | High |
| TC-P17 | Toggle Status — Inactive tag hidden from active lists | Functional | Status | Medium |
| TC-P18 | Index — Paginated tag list loads correctly | Functional | List | Medium |
| TC-P19 | Search — Filter tags by short_name keyword | Functional | List | Medium |
| TC-P20 | Search — Filter tags by name keyword | Functional | List | Medium |
| TC-P21 | List — Pagination navigates to page 2 | Functional | List | Low |
| TC-P22 | List — Empty tag list displays correctly | Edge Case | List | Low |
| TC-P23 | List — Status filter shows active only | Functional | List | Medium |
| TC-P24 | List — Status filter shows inactive only | Functional | List | Medium |
| TC-P25 | List — Status filter shows all | Functional | List | Medium |
| TC-P26 | Create — Short name with alphanumeric characters | Edge Case | Creation | Low |
| TC-P27 | Create — Short name at minimum length (1 char) | Edge Case | Creation | Low |
| TC-P28 | Restore — Restored tag visible on index | Functional | Restore | Medium |

### 9.2 Negative TC Summary

| TC ID | Test Case Name | Type | Area | Priority |
|-------|---------------|------|------|----------|
| TC-N01 | Create — Missing required fields (short_name, name) | Validation | Creation | High |
| TC-N02 | Create — Duplicate short_name (unique constraint) | Validation | Creation | High |
| TC-N03 | Create — Short name exceeds max length | Validation | Creation | Medium |
| TC-N04 | Create — Name exceeds max length | Validation | Creation | Medium |
| TC-N05 | Edit — Update with duplicate short_name (other tag) | Validation | Edit | High |
| TC-N06 | Edit — Non-existent tag ID (404) | Validation | Edit | High |
| TC-N07 | Show — Non-existent tag ID (404) | Validation | View | High |
| TC-N08 | Destroy — Non-existent tag ID (404) | Validation | Delete | High |
| TC-N09 | Restore — Non-existent or non-trashed tag ID (404) | Validation | Restore | High |
| TC-N10 | Force Delete — Non-existent tag ID (404) | Validation | Force Delete | High |
| TC-N11 | Toggle Status — Non-existent tag ID (404) | Validation | Status | High |
| TC-N12 | Create — Without permission (question-tag.create) | Auth | Permission | High |
| TC-N13 | Edit — Without permission (question-tag.update) | Auth | Permission | High |
| TC-N14 | Delete — Without permission (question-tag.delete) | Auth | Permission | High |
| TC-N15 | View Trash — Without permission (question-tag.restore) | Auth | Permission | High |
| TC-N16 | Force Delete — Without permission (question-tag.forceDelete) | Auth | Permission | High |
| TC-N17 | Toggle Status — Without permission (question-tag.update) | Auth | Permission | High |
| TC-N18 | View — Without permission (question-tag.view) | Auth | Permission | High |
| TC-N19 | Index — `abort(404)` called on index route | Functional | List | High |
| TC-N20 | Force Delete — Tag linked to questions (cascade test) | Integration | Force Delete | High |
| TC-N21 | Create — short_name submitted as empty string | Validation | Creation | High |
| TC-N22 | Create — name submitted as empty string | Validation | Creation | High |
| TC-N23 | Edit — Update with short_name exceeding max (101 chars) | Validation | Edit | Medium |
| TC-N24 | Edit — Update with name exceeding max (256 chars) | Validation | Edit | Medium |
| TC-N25 | Create — short_name whitespace-only string | Validation | Creation | Low |
| TC-N26 | Create — name whitespace-only string | Validation | Creation | Low |
| TC-N27 | Toggle Status — Already soft-deleted tag | Functional | Status | Medium |
| TC-N28 | Trash — Empty trash listing when no tags deleted | Functional | Trash | Low |
| TC-N29 | Toggle Status — Tag with is_active already toggled multiple times | Edge Case | Status | Low |
| TC-N30 | Destroy — Already soft-deleted tag (double delete) | Functional | Delete | Medium |

### 9.3 Dependency TC Summary

| TC ID | Test Case Name | Type | Area | Priority |
|-------|---------------|------|------|----------|
| TC-D01 | Cascade — Force delete cascades to `qns_question_questiontag_jnt` | Integration | Cascade | High |
| TC-D02 | Cascade — Soft delete does NOT cascade to junction | Integration | Cascade | Medium |
| TC-D03 | Business — Activity log entry created on every action | Business Rule | Activity Log | High |
| TC-D04 | Business — is_active boolean cast in model | Business Rule | Model | Medium |
| TC-D05 | Cascade — Tag linked to questions force delete cascades to junction | Integration | Cascade | Medium |
| TC-D06 | Unique — Short_name unavailable across soft-deleted tags | Integration | Uniqueness | High |
| TC-D07 | Cascade — Multiple tags on one question, force delete one preserves others | Integration | Cascade | Medium |
| TC-D08 | Cascade — Multiple questions sharing same tag, force delete cascades | Integration | Cascade | Medium |
| TC-D09 | Business — scopeActive returns only tags with is_active = true | Business Rule | Model | Medium |
| TC-D10 | Business — scopeFilter searches both short_name and name fields | Business Rule | Model | Medium |
| TC-D12 | Business — Junction table unique constraint prevents duplicate tag-question pairs | Business Rule | Referential | Medium |
| TC-D13 | Cascade — Restore preserves existing junction records intact | Integration | Cascade | Medium |
| TC-D14 | Business — Timestamps (created_at, updated_at) auto-managed by Eloquent | Business Rule | Model | Low |
| TC-D15 | Business — Soft-deleted tag excluded from default scope queries | Business Rule | Model | Medium |

### 9.4 Code Review TC Summary

| TC ID | Test Case Name | Type | Area | Priority |
|-------|---------------|------|------|----------|
| TC-CR01 | Controller store() — Tag creation flow | Code Review | Controller | High |
| TC-CR02 | Controller show() — With trashed scope | Code Review | Controller | Medium |
| TC-CR03 | Controller edit() — Find or fail | Code Review | Controller | High |
| TC-CR04 | Controller update() — Update with change tracking | Code Review | Controller | High |
| TC-CR05 | Controller destroy() — Soft delete with deactivation | Code Review | Controller | High |
| TC-CR06 | Controller trashed() — Trash listing | Code Review | Controller | Medium |
| TC-CR07 | Controller restore() — Restore flow | Code Review | Controller | High |
| TC-CR08 | Controller forceDelete() — Permanent delete | Code Review | Controller | High |
| TC-CR09 | Controller toggleStatus() — AJAX status toggle | Code Review | Controller | High |
| TC-CR10 | Request QuestionTagRequest — rules() validation | Code Review | Request | High |
| TC-CR11 | Request QuestionTagRequest — authorize() with gate | Code Review | Request | High |
| TC-CR12 | Policy QuestionTagPolicy — Permission methods | Code Review | Policy | High |
| TC-CR13 | Model QuestionTag — SoftDeletes + fillable + casts | Code Review | Model | High |
| TC-CR14 | Blade @can Directives — Permission visibility | Code Review | View | Medium |
| TC-CR15 | Blade — isset()/null-safe checks for relationship variables | Code Review | View | Medium |
| TC-CR16 | Blade — Success flash messages after CRUD | Code Review | View | Medium |
| TC-CR17 | Controller index() — abort(404) called unconditionally | Code Review | Controller | High |
| TC-CR18 | Controller create() — Gate authorize before view return | Code Review | Controller | Medium |
| TC-CR19 | Route definitions — Resource routes (7 standard) | Code Review | Route | High |
| TC-CR20 | Route definitions — Extra routes (trash, restore, force-delete, toggle-status) | Code Review | Route | High |
| TC-CR21 | Route naming convention — Consistency across all route names | Code Review | Route | Medium |
| TC-CR22 | Model — belongsToMany relationship to QuestionBank | Code Review | Model | Medium |
| TC-CR23 | Model — scopeActive logic implementation | Code Review | Model | Medium |
| TC-CR24 | Model — scopeFilter logic implementation | Code Review | Model | Medium |
| TC-CR25 | Activity Log — Event name values in controller activity() calls | Code Review | Activity Log | High |
| TC-CR26 | Flash Messages — All success keys defined in lang file | Code Review | Lang | Medium |
| TC-CR27 | Permission Mismatch — KI-01 code review verification | Code Review | Auth | High |
| TC-CR28 | Tab Integration — QuestionTag registered in QuestionBankController@index | Code Review | Tab | Medium |
| TC-CR29 | Blade — View file structure (index, show, trash, create, edit) | Code Review | View | Medium |
| TC-CR30 | Blade — Success flash rendered in parent layout component | Code Review | View | Low |

### 9.5 Total TC Count

| Category | Count |
|----------|-------|
| Positive (TC-P) | 28 |
| Negative (TC-N) | 30 |
| Dependency (TC-D) | 14 |
| Code Review (TC-CR) | 30 |
| **Total** | **102** |

---

## 10. Route Reference

| Method | URL | Name | Controller Method | Required Permission |
|--------|-----|------|-------------------|---------------------|
| GET | `/question-bank/question-tag` | question-bank.question-tag.index | index() | tenant.question_bank.viewAny (→ `abort(404)`) |
| GET | `/question-bank/question-tag/create` | question-bank.question-tag.create | create() | tenant.question_bank.create |
| POST | `/question-bank/question-tag` | question-bank.question-tag.store | store() | tenant.question_bank.create |
| GET | `/question-bank/question-tag/{question_tag}` | question-bank.question-tag.show | show() | tenant.question_bank.view |
| GET | `/question-bank/question-tag/{question_tag}/edit` | question-bank.question-tag.edit | edit() | tenant.question_bank.update |
| PUT/PATCH | `/question-bank/question-tag/{question_tag}` | question-bank.question-tag.update | update() | tenant.question_bank.update |
| DELETE | `/question-bank/question-tag/{question_tag}` | question-bank.question-tag.destroy | destroy() | tenant.question_bank.delete |
| GET | `/question-bank/question-tag/trash/view` | question-bank.question-tag.trashed | trashed() | tenant.question_bank.restore |
| GET | `/question-bank/question-tag/{id}/restore` | question-bank.question-tag.restore | restore() | tenant.question_bank.restore |
| DELETE | `/question-bank/question-tag/{id}/force-delete` | question-bank.question-tag.forceDelete | forceDelete() | tenant.question_bank.forceDelete |
| POST | `/question-bank/question-tag/{question_tag}/toggle-status` | question-bank.question-tag.toggleStatus | toggleStatus() | tenant.question_bank.update |

---

## 11. Positive TC Steps

### 11.1 Tag Creation (REQ-QTAG-001)

#### TC-P01: Create — Minimal Tag with required fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Question Bank → Question Tags tab | Tab loads with tag list |
| 2 | Click "Add Tag" button | Create form loads with empty fields |
| 3 | Enter short_name = "MCQ" | Short name entered |
| 4 | Enter name = "Multiple Choice Question" | Name entered |
| 5 | Leave is_active at default (Active) | Default ON |
| 6 | Click "Create Question Tag" | POST store() |
| 7 | Verify redirect to Question Bank index with success | `success = flash('created.question_tag')` |
| 8 | DB check: `qns_question_tags` | Record created |
| 9 | DB check: `short_name` | "MCQ" |
| 10 | DB check: `name` | "Multiple Choice Question" |
| 11 | DB check: `is_active` | 1 (true) |
| 12 | DB check: `created_at` | Set to current timestamp |
| 13 | Verify activity log | `activityLog()` entry created with event 'Stored' |

---

#### TC-P02: Create — Tag with all fields (including is_active = Inactive)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loads |
| 2 | Enter short_name = "SAQ" | Short name entered |
| 3 | Enter name = "Short Answer Question" | Name entered |
| 4 | Toggle is_active = OFF (Inactive) | Switch set to Inactive |
| 5 | Click "Create Question Tag" | POST store() |
| 6 | DB check: is_active | 0 (false) |
| 7 | DB check: short_name | "SAQ" |
| 8 | DB check: name | "Short Answer Question" |

---

#### TC-P03: Create — Short name uniqueness with different tags

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Tag T1 with short_name = "TAG_A" | T1 saved |
| 2 | Create Tag T2 with short_name = "TAG_B" | T2 saved (different value, accepted) |
| 3 | DB check: T1.short_name | "TAG_A" |
| 4 | DB check: T2.short_name | "TAG_B" |

---

#### TC-P04: Create — Short name with max length (100 chars)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set short_name = string of exactly 100 characters | Max:100 boundary |
| 2 | Set name = "Max Length Short Name Test" | Name entered |
| 3 | Submit | Tag created |
| 4 | DB check: short_name length | 100 characters |

---

#### TC-P05: Create — Name with max length (255 chars)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set short_name = "MAX255" | Short name entered |
| 2 | Set name = string of exactly 255 characters | Max:255 boundary |
| 3 | Submit | Tag created |
| 4 | DB check: name length | 255 characters |

---

### 11.2 Tag Show & View (REQ-QTAG-002)

#### TC-P06: Show — View tag details (active)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Tag T1 with short_name="ESSAY", is_active=1 | T1 exists |
| 2 | Navigate to show page: GET `/question-bank/question-tag/{T1}` | Show page loads |
| 3 | Verify short_name displayed | "ESSAY" shown |
| 4 | Verify name displayed | Tag name shown |
| 5 | Verify status badge | "Active" badge (green) |
| 6 | Verify created_at and updated_at | Timestamps displayed |

---

#### TC-P07: Show — View tag details (soft-deleted)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete Tag T1 (has no question links) | T1 in trash |
| 2 | Navigate to show page: GET `/question-bank/question-tag/{T1}` | Show page loads (show() uses withTrashed()) |
| 3 | Verify tag details display | All fields shown despite soft-deleted |
| 4 | Verify status field reflects is_active | Shows Inactive (is_active=0) |

---

### 11.3 Tag Edit & Update (REQ-QTAG-003)

#### TC-P08: Edit — Update short_name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Tag T1 with short_name="OLD" | T1 exists |
| 2 | Navigate to edit: GET `/question-bank/question-tag/{T1}/edit` | Edit form loads with pre-filled values |
| 3 | Change short_name to "NEW" | Short name changed |
| 4 | Submit (PUT) | Updated |
| 5 | DB check: short_name | "NEW" |
| 6 | Verify activity log | event 'Updated' with changes logged |

---

#### TC-P09: Edit — Update name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Tag T1 with name="Old Name" | T1 exists |
| 2 | Edit: Change name to "Updated Tag Name" | Name changed |
| 3 | Submit | Updated |
| 4 | DB check: name | "Updated Tag Name" |

---

#### TC-P10: Edit — Update is_active status via edit form

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Tag T1 with is_active=1 | T1 active |
| 2 | Edit: Toggle is_active = OFF | Status switched |
| 3 | Submit | Updated |
| 4 | DB check: is_active | 0 |
| 5 | Edit again: Toggle is_active = ON | Status switched back |
| 6 | Submit | Updated |
| 7 | DB check: is_active | 1 |

---

#### TC-P11: Edit — Short name uniqueness on update (exclude self)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create T1 (short_name="TAG1"), T2 (short_name="TAG2") | Both exist |
| 2 | Edit T2: Keep short_name as "TAG2" (unchanged) | Unique rule for update includes `{id}` — excludes self |
| 3 | Submit | Update succeeds |
| 4 | DB check: T2.short_name | "TAG2" (unchanged) |
| 5 | Edit T2: Change short_name to "TAG1" (exists on T1) | Unique validation should detect |
| 6 | Submit | Validation error: "This short name already exists." |
| 7 | DB check: T2.short_name | Still "TAG2" (unchanged) |

---

### 11.4 Soft Delete, Trash, Restore, Force Delete (REQ-QTAG-004)

#### TC-P12: Destroy — Soft delete unused tag

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Tag T1 with no junction links | T1 unused |
| 2 | Click Delete on T1 | DELETE `/question-bank/question-tag/{T1}` |
| 3 | Tag is deactivated: `is_active = false; $tag->save()` | Pre-save |
| 4 | Tag is soft-deleted: `$tag->delete()` | deleted_at set |
| 5 | Verify redirect with success | `success = flash('trashed.question_tag')` |
| 6 | DB check: deleted_at | NOT NULL |
| 7 | DB check: is_active | 0 |
| 8 | Verify activity log | event 'Trashed' |

---

#### TC-P13: Trashed — View trash listing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete T1, T2 | Both in trash |
| 2 | Navigate to Trash: GET `/question-bank/question-tag/trash/view` | Trash page loads |
| 3 | Verify T1 and T2 listed | Both shown |
| 4 | Verify only soft-deleted tags shown | Active tags not in list |
| 5 | DB check: query uses `QuestionTag::onlyTrashed()` | Only trashed records |

---

#### TC-P14: Restore — Restore soft-deleted tag

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete T1 | T1 in trash |
| 2 | Navigate to Trash | T1 shown |
| 3 | Click Restore on T1 | GET `/question-bank/question-tag/{id}/restore` |
| 4 | Controller checks `tenant.question_bank.restore` permission | Gate passed |
| 5 | `$tag->restore()` called | deleted_at = NULL |
| 6 | Verify redirect with success | `success = flash('restored.question_tag')` |
| 7 | DB check: deleted_at | NULL |
| 8 | Verify activity log | event 'Restored' |

---

#### TC-P15: Force Delete — Permanently delete unused tag

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete T1 (no junction links) | T1 in trash |
| 2 | Navigate to Trash | T1 shown |
| 3 | Click Force Delete on T1 | DELETE `/question-bank/question-tag/{id}/force-delete` |
| 4 | Controller checks `tenant.question_bank.forceDelete` permission | Gate passed |
| 5 | `$tag->forceDelete()` called | Tag permanently removed |
| 6 | Verify redirect with success | `success = flash('force_deleted.question_tag')` |
| 7 | DB check: T1 withTrashed() | Record gone (permanently deleted) |
| 8 | Verify activity log | event 'Deleted' |

---

### 11.5 Status Toggle (REQ-QTAG-005)

#### TC-P16: Toggle Status — Activate/Deactivate tag (AJAX)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Tag T1 with is_active=1 | T1 active |
| 2 | Send AJAX POST to toggleStatus | POST `/question-bank/question-tag/{T1}/toggle-status` |
| 3 | Controller inverts: `is_active = !is_active` | Toggle logic |
| 4 | Verify JSON response | `{"success": true, "is_active": false, "message": ...}` |
| 5 | DB check: is_active | 0 |
| 6 | Send AJAX POST to toggleStatus again | Toggle back |
| 7 | Verify JSON response | `{"success": true, "is_active": true}` |
| 8 | DB check: is_active | 1 |
| 9 | Verify activity log | event 'Status Toggled' |

---

#### TC-P17: Toggle Status — Inactive tag hidden from active lists

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Toggle T1 is_active = 0 | T1 inactive |
| 2 | Query with `QuestionTag::where('is_active', 1)` | T1 excluded |
| 3 | Toggle T1 is_active = 1 | T1 active again |
| 4 | Query with `QuestionTag::where('is_active', 1)` | T1 included |

---

### 11.6 Index & List (REQ-QTAG-006)

#### TC-P18: Index — Paginated tag list loads correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Question Bank → Question Tags tab | Tab pane loads |
| 2 | Verify table headers | #, Short Name, Tag Name, Created At, Active, Action |
| 3 | Verify search bar present | Search input for short name / name |
| 4 | Verify status filter present | All Status / Active / Inactive |
| 5 | Verify pagination | `$questionTags->appends(...)->links()` renders |

---

### 11.7 Additional Positive TC Steps

#### TC-P19: Search — Filter tags by short_name keyword

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Question Bank → Question Tags tab | Tab loads with tag list |
| 2 | Enter search keyword = "MCQ" | Search input filled |
| 3 | Submit search (keyup/enter) | List refreshes with filtered results |
| 4 | Verify only tags with short_name containing "MCQ" appear | List filtered correctly |
| 5 | Verify tags without "MCQ" in short_name are hidden | Excluded from results |

---

#### TC-P20: Search — Filter tags by name keyword

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to Question Tags tab | Tab loads |
| 2 | Enter search keyword = "Multiple" | Search input filled |
| 3 | Submit search | List refreshes with filtered results |
| 4 | Verify only tags with name containing "Multiple" appear | List filtered correctly |
| 5 | Verify tags without "Multiple" in name hidden | Excluded from results |

---

#### TC-P21: List — Pagination navigates to page 2

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure at least 11 tags exist in DB | Pagination becomes active |
| 2 | Navigate to Question Tags tab | Page 1 shows first 10 tags |
| 3 | Click page 2 pagination link | Page 2 loads with next set |
| 4 | Verify tags on page 2 differ from page 1 | Correct page 2 data |
| 5 | Verify pagination maintains query string params | `appends()` retains filters |

---

#### TC-P22: List — Empty tag list displays correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure no tags exist in DB (truncate or empty) | Empty dataset |
| 2 | Navigate to Question Tags tab | Tab loads without error |
| 3 | Verify "No records found" empty-state message | Empty state displayed |
| 4 | Verify Add Tag button still visible | Creation action remains available |
| 5 | Verify pagination links absent | No pagination rendered |

---

#### TC-P23: List — Status filter shows active only

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create T1 (is_active=1), T2 (is_active=0) | Mixed-status tags exist |
| 2 | Navigate to Question Tags tab | Both may load by default |
| 3 | Select status filter = "Active" | Only T1 displayed |
| 4 | Verify T2 excluded from results | Filter works correctly |

---

#### TC-P24: List — Status filter shows inactive only

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create T1 (is_active=1), T2 (is_active=0) | Mixed-status tags exist |
| 2 | Select status filter = "Inactive" | Only T2 displayed |
| 3 | Verify T1 excluded | Filter works correctly |

---

#### TC-P25: List — Status filter shows all

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create T1 (active), T2 (inactive) | Mixed-status tags exist |
| 2 | Select status filter = "All" | Both T1 and T2 displayed |

---

#### TC-P26: Create — Short name with alphanumeric characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loads |
| 2 | Enter short_name = "TAG_99" | Alphanumeric value entered |
| 3 | Enter name = "Tag with Numbers" | Name entered |
| 4 | Click "Create Question Tag" | POST store() |
| 5 | DB check: short_name | "TAG_99" |
| 6 | Verify created successfully | Record persisted |

---

#### TC-P27: Create — Short name at minimum length (1 char)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loads |
| 2 | Enter short_name = "A" (1 character) | Minimum length boundary |
| 3 | Enter name = "Single Char Tag" | Name entered |
| 4 | Submit | Created successfully |
| 5 | DB check: short_name length | 1 character |

---

#### TC-P28: Restore — Restored tag visible on index

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete T1 (has no question links) | T1 in trash, deleted_at set |
| 2 | Restore T1 via trash page | T1 restored, deleted_at = NULL |
| 3 | Navigate to Question Tags tab | T1 visible in active list |
| 4 | DB check: deleted_at | NULL |
| 5 | Note: is_active remains 0 (not auto-reset by restore()) | Must manually toggle status back to active |

---

## 12. Negative TC Steps

### 12.1 Tag Creation — Validation Failures

#### TC-N01: Create — Missing required fields (short_name, name)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form with short_name and name empty | Validation errors |
| 2 | Verify `short_name` error | "Short name is required." |
| 3 | Verify `name` error | "Name is required." |
| 4 | DB check: no tag created | 0 new records |

---

#### TC-N02: Create — Duplicate short_name (unique constraint)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Tag T1 with short_name = "DUP" | T1 exists |
| 2 | Create Tag T2 with short_name = "DUP" (same) | Unique validation fails |
| 3 | Submit | Validation error: "This short name already exists." |
| 4 | DB check: T2 not created | Only T1 exists |

---

#### TC-N03: Create — Short name exceeds max length

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set short_name = string of 101 characters | Max:100 validation |
| 2 | Submit | Validation error: "short_name must not exceed 100 characters." |

---

#### TC-N04: Create — Name exceeds max length

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set name = string of 256 characters | Max:255 validation |
| 2 | Submit | Validation error: "name must not exceed 255 characters." |

---

### 12.2 Tag Edit — Validation Failures

#### TC-N05: Edit — Update with duplicate short_name (other tag)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create T1 (short_name="ALPHA"), T2 (short_name="BETA") | Both exist |
| 2 | Edit T2: Change short_name to "ALPHA" (taken by T1) | Unique rule with exclude:self detects collision |
| 3 | Submit | Validation error: "This short name already exists." |
| 4 | DB check: T2.short_name | Still "BETA" |

---

#### TC-N06: Edit — Non-existent tag ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send GET to `/question-bank/question-tag/99999/edit` | `QuestionTag::findOrFail(99999)` throws ModelNotFoundException |
| 2 | Verify 404 response | 404 Not Found |

---

#### TC-N07: Show — Non-existent tag ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send GET to `/question-bank/question-tag/99999` | `QuestionTag::withTrashed()->findOrFail(99999)` throws 404 |
| 2 | Verify 404 response | 404 Not Found |

---

#### TC-N08: Destroy — Non-existent tag ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send DELETE to `/question-bank/question-tag/99999` | `QuestionTag::findOrFail(99999)` throws 404 |
| 2 | Verify 404 response | 404 Not Found |

---

#### TC-N09: Restore — Non-existent or non-trashed tag ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send GET to `/question-bank/question-tag/99999/restore` | `QuestionTag::onlyTrashed()->findOrFail(99999)` throws 404 |
| 2 | Verify 404 response | 404 Not Found |
| 3 | Active tag T1 (not trashed) | `onlyTrashed()` returns null (not found) |
| 4 | Attempt restore on T1 | 404 Not Found |

---

#### TC-N10: Force Delete — Non-existent tag ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send DELETE to `/question-bank/question-tag/99999/force-delete` | `QuestionTag::withTrashed()->findOrFail(99999)` throws 404 |
| 2 | Verify 404 response | 404 Not Found |

---

#### TC-N11: Toggle Status — Non-existent tag ID (404)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST to `/question-bank/question-tag/99999/toggle-status` | `QuestionTag::findOrFail(99999)` throws 404 |
| 2 | Verify 404 response | 404 Not Found |

---

### 12.3 Permission Gates

#### TC-N12: Create — Without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.question_bank.create` | Authenticated |
| 2 | Navigate to create page | 403 Forbidden |
| 3 | Send POST store directly | 403 Forbidden |

---

#### TC-N13: Edit — Without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.question_bank.update` | Authenticated |
| 2 | Navigate to edit page | 403 Forbidden |
| 3 | Send PUT update directly | 403 Forbidden |

---

#### TC-N14: Delete — Without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.question_bank.delete` | Authenticated |
| 2 | Send DELETE directly | 403 Forbidden |

---

#### TC-N15: View Trash — Without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.question_bank.restore` | Authenticated |
| 2 | Navigate to Trash page | 403 Forbidden |

---

#### TC-N16: Force Delete — Without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.question_bank.forceDelete` | Authenticated |
| 2 | Send DELETE forceDelete directly | 403 Forbidden |

---

#### TC-N17: Toggle Status — Without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.question_bank.update` | Authenticated |
| 2 | Send AJAX POST to toggleStatus | 403 Forbidden |

---

#### TC-N18: View — Without permission

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.question_bank.view` | Authenticated |
| 2 | Navigate to show page | 403 Forbidden |

---

### 12.4 Functional Edge Cases

#### TC-N19: Index — `abort(404)` called on index route

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to GET `/question-bank/question-tag` (index) | Controller calls `abort(404)` as first line |
| 2 | Verify 404 response | 404 Not Found — index route intentionally disabled |

---

#### TC-N20: Force Delete — Tag linked to questions (cascade test)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Tag T1, link it to question Q1 via `qns_question_questiontag_jnt` | Junction record exists |
| 2 | Soft-delete T1 | T1 in trash |
| 3 | Click Force Delete on T1 | `$tag->forceDelete()` called |
| 4 | DB check: T1 withTrashed() | Record permanently removed |
| 5 | DB check: `qns_question_questiontag_jnt` where tag_id = T1 | Junction record also removed (FK CASCADE) |

---

### 12.5 Additional Negative TC Steps

#### TC-N21: Create — short_name submitted as empty string

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form with short_name = "" | Empty value |
| 2 | Verify validation error on short_name | "Short name is required." |
| 3 | DB check: no new tag record created | 0 new records |

---

#### TC-N22: Create — name submitted as empty string

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create form with name = "" | Empty value |
| 2 | Verify validation error on name | "Name is required." |
| 3 | DB check: no new tag record created | 0 new records |

---

#### TC-N23: Edit — Update with short_name exceeding max (101 chars)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Tag T1 with valid short_name | T1 exists |
| 2 | Navigate to edit form for T1 | Edit form loads with pre-filled values |
| 3 | Set short_name = string of 101 characters | Exceeds max:100 validation |
| 4 | Submit | Validation error: "short_name must not exceed 100 characters." |
| 5 | DB check: T1.short_name | Original value preserved (unchanged) |

---

#### TC-N24: Edit — Update with name exceeding max (256 chars)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Tag T1 with valid name | T1 exists |
| 2 | Navigate to edit form for T1 | Edit form loads |
| 3 | Set name = string of 256 characters | Exceeds max:255 validation |
| 4 | Submit | Validation error: "name must not exceed 255 characters." |
| 5 | DB check: T1.name | Original value preserved (unchanged) |

---

#### TC-N25: Create — short_name whitespace-only string

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create with short_name = "   " (3 spaces) | Whitespace-only value |
| 2 | Laravel `string` rule accepts whitespace; verification: tag may be created with whitespace short_name | If created, DB stores raw spaces |
| 3 | Note: `required` rule does NOT trim whitespace | Potential data quality issue |

---

#### TC-N26: Create — name whitespace-only string

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit create with name = "   " (3 spaces) | Whitespace-only value |
| 2 | Laravel `string` rule accepts whitespace; tag may be created | If created, DB stores raw spaces |

---

#### TC-N27: Toggle Status — Already soft-deleted tag

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete Tag T1 | T1.deleted_at = NOW(), is_active = 0 |
| 2 | Send AJAX POST to toggleStatus on T1 | POST `/question-bank/question-tag/{T1}/toggle-status` |
| 3 | Controller: `QuestionTag::findOrFail($id)` — only returns non-deleted | `ModelNotFoundException` (findOrFail excludes soft-deleted) |
| 4 | Verify 404 response | 404 Not Found |

---

#### TC-N28: Trash — Empty trash listing when no tags deleted

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure zero soft-deleted tags exist | Only active tags |
| 2 | Navigate to Trash: GET `/question-bank/question-tag/trash/view` | Trash page loads |
| 3 | Verify empty-state message | "No trashed records" or similar |
| 4 | Verify no pagination rendered | Empty result set |

---

#### TC-N29: Toggle Status — Tag toggled multiple times consecutively

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Tag T1 with is_active=1 | T1 active |
| 2 | Toggle status ON→OFF | is_active = 0 |
| 3 | Toggle status OFF→ON | is_active = 1 |
| 4 | Toggle status ON→OFF | is_active = 0 |
| 5 | DB check: final is_active | 0 (each toggle inverts correctly) |

---

#### TC-N30: Destroy — Already soft-deleted tag (double delete)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete Tag T1 via destroy() | T1 deleted_at set |
| 2 | Attempt to send DELETE again on same T1 | Controller uses `QuestionTag::findOrFail($id)` which excludes soft-deleted |
| 3 | Verify 404 response | ModelNotFoundException, 404 returned |

---

## 13. Dependency TC Steps

#### TC-D01: Cascade — Force delete cascades to `qns_question_questiontag_jnt`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Tag T1 | T1 exists |
| 2 | Link T1 to Question Q1, Q2 via junction table | 2 junction records |
| 3 | Force delete T1 | `$tag->forceDelete()` called |
| 4 | DB check: `qns_question_tags` withTrashed() | T1 permanently gone |
| 5 | DB check: `qns_question_questiontag_jnt` where tag_id = T1 | 0 records (FK CASCADE removed) |
| 6 | DB check: `qns_questions_bank` where id = Q1, Q2 | Both questions still exist (FK only on tag_id) |

---

#### TC-D02: Cascade — Soft delete does NOT cascade to junction

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Tag T1, link to Q1, Q2 | Junction records exist |
| 2 | Soft-delete T1 (destroy) | T1.deleted_at set |
| 3 | DB check: `qns_question_questiontag_jnt` where tag_id = T1 | Junction records still exist (NOT cascade-deleted) |
| 4 | Restore T1 | T1 restored, junction records still intact |

---

#### TC-D03: Business — Activity log entry created on every action

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Tag → event 'Stored' | Activity log created |
| 2 | Update Tag → event 'Updated' | Activity log created |
| 3 | Soft-delete Tag → event 'Trashed' | Activity log created |
| 4 | Restore Tag → event 'Restored' | Activity log created |
| 5 | Force delete Tag → event 'Deleted' | Activity log created |
| 6 | Toggle status → event 'Status Toggled' | Activity log created |

---

#### TC-D04: Business — is_active boolean cast in model

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Tag T1 with is_active = 1 (as integer) | Saved |
| 2 | Access `T1->is_active` | Returns `true` (bool, not int) |
| 3 | DB raw value | 1 (TINYINT) |
| 4 | Create Tag T2 with is_active = 0 | Saved |
| 5 | Access `T2->is_active` | Returns `false` (bool) |

---

#### TC-D05: Cascade — Tag linked to questions force delete cascades to junction

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Tag T1, link to Q1 via junction | Link exists |
| 2 | Force delete T1 | Record deleted, junction cascaded |
| 3 | DB check: Q1 still exists | Question preserved (no FK from question to tag) |
| 4 | DB check: junction record | Removed via CASCADE |

---

### 13.1 Additional Dependency TC Steps

#### TC-D06: Unique — Short_name unavailable across soft-deleted tags

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Tag T1 with short_name = "UNIQUE" | T1 exists |
| 2 | Soft-delete T1 | T1 in trash (deleted_at set) |
| 3 | Attempt to create Tag T2 with short_name = "UNIQUE" (same) | Unique validation: `unique:qns_question_tags,short_name` checks ALL rows including soft-deleted |
| 4 | Submit | Validation error: "This short name already exists." |
| 5 | DB check: T2 not created | Only T1 (trashed) exists |

---

#### TC-D07: Cascade — Multiple tags on one question, force delete one preserves others

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Tags T1, T2 | Both exist |
| 2 | Link both T1 and T2 to Question Q1 via junction table | 2 junction records (Q1↔T1, Q1↔T2) |
| 3 | Force delete T1 | T1 permanently removed |
| 4 | DB check: `qns_question_questiontag_jnt` where tag_id = T1 | Junction record removed (FK CASCADE) |
| 5 | DB check: `qns_question_questiontag_jnt` where tag_id = T2 | Junction record still exists (T2 unaffected) |
| 6 | DB check: Q1 still exists | Question preserved |

---

#### TC-D08: Cascade — Multiple questions sharing same tag, force delete cascades

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Tag T1 | T1 exists |
| 2 | Link T1 to Questions Q1, Q2, Q3 via junction | 3 junction records |
| 3 | Force delete T1 | T1 permanently removed |
| 4 | DB check: `qns_question_questiontag_jnt` where tag_id = T1 | 0 records (all cascaded) |
| 5 | DB check: Q1, Q2, Q3 still exist | Questions preserved (no FK from question to tag) |

---

#### TC-D09: Business — scopeActive returns only tags with is_active = true

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create T1 (is_active=1), T2 (is_active=0) | Mixed status |
| 2 | Execute `QuestionTag::active()->get()` | Returns only T1 |
| 3 | Verify T2 excluded | Not in result set |
| 4 | Verify query generates `WHERE is_active = 1` | SQL clause correct |

---

#### TC-D10: Business — scopeFilter searches both short_name and name fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create T1 (short_name="MCQ", name="Multiple Choice") | T1 exists |
| 2 | Execute `QuestionTag::filter(['search' => 'MCQ'])->get()` | T1 returned (matches short_name) |
| 3 | Execute `QuestionTag::filter(['search' => 'Multiple'])->get()` | T1 returned (matches name) |
| 4 | Execute `QuestionTag::filter(['search' => 'NONEXIST'])->get()` | Empty collection |

---


#### TC-D12: Business — Junction table unique constraint prevents duplicate tag-question pairs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Tag T1, Question Q1 | Both exist |
| 2 | Link T1 to Q1 (INSERT into junction) | Junction record created |
| 3 | Attempt to link T1 to Q1 again (INSERT duplicate) | DB unique constraint violation (Integrity constraint violation) |
| 4 | Verify duplicate prevented | Second INSERT fails |

---

#### TC-D13: Cascade — Restore preserves existing junction records intact

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Tag T1, link to Q1, Q2 | Junction records exist |
| 2 | Soft-delete T1 | T1 deleted_at set; junction records preserved (no cascade) |
| 3 | Count junction records for T1 | 2 records still exist |
| 4 | Restore T1 | T1 restored |
| 5 | Count junction records for T1 | Still 2 records (restore does not affect junction) |

---

#### TC-D14: Business — Timestamps (created_at, updated_at) auto-managed by Eloquent

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Tag T1 | created_at = NOW() |
| 2 | Immediately check created_at | Matches current time |
| 3 | Update T1.name | updated_at updated to NOW() |
| 4 | Verify updated_at > created_at | updated_at advanced |

---

#### TC-D15: Business — Soft-deleted tag excluded from default scope queries

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create T1 (active), soft-delete T2 | T2 trashed |
| 2 | Execute `QuestionTag::all()` (no withTrashed) | Only T1 returned |
| 3 | Execute `QuestionTag::withTrashed()->get()` | Both T1 and T2 returned |
| 4 | Execute `QuestionTag::onlyTrashed()->get()` | Only T2 returned |

---

## 14. Code Review TC Steps

#### TC-CR01: Controller store() — Tag creation flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `store()` in `QuestionTagController` | Gate authorize, validated data, create, activity log |
| 2 | Verify `Gate::authorize('tenant.question_bank.create')` | Called before any logic |
| 3 | Verify `$request->validated()` | Uses `QuestionTagRequest` rules |
| 4 | Verify `QuestionTag::create($questData)` | Mass-assignment via fillable |
| 5 | Verify `activityLog($tag, 'Stored', ...)` | Activity log created |
| 6 | Verify redirect with success flash | `redirect()->route('question-bank.question-bank.index')->with('success', ...)` |

---

#### TC-CR02: Controller show() — With trashed scope

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `show()` method | Gate, withTrashed(), findOrFail |
| 2 | Verify `QuestionTag::withTrashed()->findOrFail($id)` | Can view even soft-deleted tags |
| 3 | Verify `Gate::authorize('tenant.question_bank.view')` | Permission check |

---

#### TC-CR03: Controller edit() — Find or fail

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `edit()` method | Finds tag, loads form |
| 2 | Verify `QuestionTag::findOrFail($id)` | 404 if not found |
| 3 | Verify `Gate::authorize('tenant.question_bank.update')` | Permission check |

---

#### TC-CR04: Controller update() — Update with change tracking

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `update()` method | Gate, find, original capture, update, activity log |
| 2 | Verify `$tag->getOriginal()` captured before update | Used for change tracking |
| 3 | Verify `$tag->update($request->validated())` | Mass update |
| 4 | Verify `array_diff_assoc($tag->getAttributes(), $original)` | Changes array computed |
| 5 | Verify `activityLog($tag, 'Updated', ...)` | Logs with changes array |
| 6 | Verify redirect with success flash | `redirect()->route('question-bank.question-bank.index')` |

---

#### TC-CR05: Controller destroy() — Soft delete with deactivation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `destroy()` method | Gate, find, deactivate, soft delete |
| 2 | Verify `Gate::authorize('tenant.question_bank.delete')` | Permission check |
| 3 | Verify `$tag->is_active = false; $tag->save()` | Deactivates before delete |
| 4 | Verify `$tag->delete()` | Sets deleted_at |
| 5 | Verify `activityLog($tag, 'Trashed', ...)` | Logs deactivation and trash |

---

#### TC-CR06: Controller trashed() — Trash listing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `trashed()` method | `Gate::authorize('tenant.question_bank.restore')` |
| 2 | Verify `QuestionTag::onlyTrashed()->paginate(10)` | Only soft-deleted records |
| 3 | Verify view returned | `questionbank::question-tags.trash` |

---

#### TC-CR07: Controller restore() — Restore flow

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `restore()` method | Gate, find onlyTrashed, restore |
| 2 | Verify `Gate::authorize('tenant.question_bank.restore')` | Permission check |
| 3 | Verify `QuestionTag::onlyTrashed()->findOrFail($id)` | Finds trashed record |
| 4 | Verify `$tag->restore()` | Clears deleted_at |
| 5 | Note: Restore does NOT reset is_active | `is_active` remains as 0 (was set to false during destroy) |
| 6 | Verify `activityLog($tag, 'Restored', ...)` | Logs restore |

---

#### TC-CR08: Controller forceDelete() — Permanent delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `forceDelete()` method | Gate, find withTrashed, forceDelete |
| 2 | Verify `Gate::authorize('tenant.question_bank.forceDelete')` | Permission check |
| 3 | Verify `QuestionTag::withTrashed()->findOrFail($id)` | Finds even non-trashed |
| 4 | Verify `$tag->forceDelete()` | Permanent delete; FK CASCADE handles junction |
| 5 | Verify `activityLog($tag, 'Deleted', ...)` | Logs permanent delete |

---

#### TC-CR09: Controller toggleStatus() — AJAX status toggle

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `toggleStatus()` method | Gate, find, invert, save, response |
| 2 | Verify `Gate::authorize('tenant.question_bank.update')` | Permission check |
| 3 | Verify `$tag->is_active = !$tag->is_active` | Simple boolean inversion |
| 4 | Verify success JSON response | `{"success": true, "is_active": bool, "message": ...}` |
| 5 | Verify `activityLog($tag, 'Status Toggled', ...)` | Activity log |

---

#### TC-CR10: Request QuestionTagRequest — rules() validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `rules()` method | short_name and name rules |
| 2 | Verify `short_name: required|string|max:100|unique:qns_question_tags,short_name,{id}` | Uniqueness with exclude-self on update |
| 3 | Verify `name: required|string|max:255` | Simple string validation |
| 4 | Verify route parameter resolution: `$this->route('question-tag') ?? $this->route('question_tag')` | Handles both dash and underscore |

---

#### TC-CR11: Request QuestionTagRequest — authorize() with gate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `authorize()` method | Conditional gate check |
| 2 | Verify POST method → `Gate::allows('tenant.question-bank.create')` | Create permission |
| 3 | Verify PUT/PATCH → `Gate::allows('tenant.question-bank.update')` | Update permission |
| 4 | Note: Uses `tenant.question-bank.*` (dash) not `tenant.question_bank.*` (underscore) | Different from controller gates |

---

#### TC-CR12: Policy QuestionTagPolicy — Permission methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `QuestionTagPolicy` | 8 permission methods |
| 2 | Verify `viewAny`: `tenant.question-tag.viewAny` | List permission |
| 3 | Verify `view`: `tenant.question-tag.view` | Show permission |
| 4 | Verify `create`: `tenant.question-tag.create` | Create permission |
| 5 | Verify `update`: `tenant.question-tag.update` | Update/toggle permission |
| 6 | Verify `delete`: `tenant.question-tag.delete` | Soft delete permission |
| 7 | Verify `restore`: `tenant.question-tag.restore` | Restore permission |
| 8 | Verify `forceDelete`: `tenant.question-tag.forceDelete` | Force delete permission |
| 9 | Verify `status`: `tenant.question-tag.status` | Status toggle permission; note: no model parameter |
| 10 | Note: Policy uses `tenant.question-tag.*` (dash) whereas controller gates use `tenant.question_bank.*` (underscore) | **MISMATCH** — see KI-01 |

---

#### TC-CR13: Model QuestionTag — SoftDeletes + fillable + casts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify model uses `SoftDeletes` trait | Trait imported |
| 2 | Verify `$fillable` includes `short_name`, `name`, `is_active` | Mass-assignable |
| 3 | Verify `$casts` includes `is_active => boolean` | Boolean cast |
| 4 | Verify `$table = 'qns_question_tags'` | Correct table name |
| 5 | Verify `$primaryKey = 'id'` | Standard PK |
| 6 | Verify no boot events (creating/updating) | Model relies on request-level logic |

---

#### TC-CR14: Blade @can Directives — Permission visibility

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `question-tags/index.blade.php` — Index table header | `@can('tenant.question-tag.status')` wraps Active column header; `@canany(['tenant.question-tag.view', 'tenant.question-tag.update', 'tenant.question-tag.delete'])` wraps Action column header |
| 2 | Review `question-tags/index.blade.php` — Per-row status switch | `@can('tenant.question-tag.status')` wraps status switch |
| 3 | Review `question-tags/index.blade.php` — Per-row action buttons | `@canany(['tenant.question-tag.view', 'tenant.question-tag.update', 'tenant.question-tag.delete'])` wraps actions |
| 4 | Review `question-tags/view.blade.php` — Edit button | `@can('tenant.question-tag.edit')` wraps Edit button |
| 5 | Review `question-tags/trash.blade.php` — Trash actions | `@canany(['tenant.question-tag.restore', 'tenant.question-tag.forceDelete'])` wraps restore and force-delete |
| 6 | Verify: User WITHOUT `tenant.question-tag.status` | Active column and toggle hidden |
| 7 | Verify: User WITHOUT `tenant.question-tag.update` | Edit button hidden |
| 8 | Verify: User WITH only `tenant.question-tag.view` | Index shows only View action; no Edit/Delete |

---

#### TC-CR15: Blade — isset()/null-safe checks for relationship variables

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `question-tags/index.blade.php` — Table row | `$tag->short_name ?? 'No Short Name'` — null-safe with fallback |
| 2 | Review `question-tags/index.blade.php` — Name | `$tag->name ?? 'No Name'` — null-safe |
| 3 | Review `question-tags/index.blade.php` — Created At | `$tag->created_at ? $tag->created_at->format('Y-m-d') : '-'` — null check |
| 4 | Review `question-tags/view.blade.php` — Short Name | `$tag->short_name ?? '-'` — null coalescing |
| 5 | Review `question-tags/view.blade.php` — Name | `$tag->name ?? '-'` — null coalescing |
| 6 | Review `question-tags/view.blade.php` — Timestamps | `$tag->created_at?->format(...)` — PHP 8 null-safe operator |
| 7 | Review `question-tags/trash.blade.php` — Short Name | `$item->short_name ?? '-'` — null coalescing |
| 8 | Review `question-tags/trash.blade.php` — Name | `$item->name ?? '-'` — null coalescing |
| 9 | Review `question-tags/trash.blade.php` — Deleted At | `$item->deleted_at?->format(...)` — null-safe operator |
| 10 | Verify no blade file accesses `$tag->relationship->field` without `??` or `?->` | All accesses guarded |

---

#### TC-CR16: Blade — Success flash messages after CRUD

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `QuestionTagController::store()` | `->with('success', flash('created.question_tag'))` — flashes 'created.question_tag' key |
| 2 | Review `QuestionTagController::update()` | `->with('success', flash('updated.question_tag'))` — flashes 'updated.question_tag' key |
| 3 | Review `QuestionTagController::destroy()` | `->with('success', flash('trashed.question_tag'))` — flashes 'trashed.question_tag' key |
| 4 | Review `QuestionTagController::restore()` | `->with('success', flash('restored.question_tag'))` — flashes 'restored.question_tag' key |
| 5 | Review `QuestionTagController::forceDelete()` | `->with('success', flash('force_deleted.question_tag'))` — flashes 'force_deleted.question_tag' key |
| 6 | Review `toggleStatus()` JSON response | `flash('status_updated.question_tag')` — flashes in JSON message |
| 7 | Verify parent layout renders `session('success')` | Alert component renders flash message |
| 8 | Verify `flash('created.question_tag')` resolves | Language key defined |
| 9 | Verify `flash('updated.question_tag')` resolves | Language key defined |
| 10 | Verify `flash('trashed.question_tag')` resolves | Language key defined |
| 11 | Verify `flash('restored.question_tag')` resolves | Language key defined |
| 12 | Verify `flash('force_deleted.question_tag')` resolves | Language key defined |

---

### 14.1 Additional Code Review TC Steps

#### TC-CR17: Controller index() — abort(404) called unconditionally

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `QuestionTagController::index()` | Method calls `abort(404)` as first line |
| 2 | Verify no gate check occurs before abort | Gate is never reached |
| 3 | Verify `QuestionTag::orderBy('name')->paginate(10)` is unreachable | Dead code after abort |
| 4 | Confirm index route /question-bank/question-tag always returns 404 | Tags accessed only via tabbed interface |

---

#### TC-CR18: Controller create() — Gate authorize before view return

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `QuestionTagController::create()` | `Gate::authorize('tenant.question_bank.create')` called first |
| 2 | Verify gate check precedes view return | Authorization before response |
| 3 | Verify view returned: `questionbank::question-tags.create` | Correct create form view |

---

#### TC-CR19: Route definitions — Resource routes (7 standard)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `routes/web.php` for QuestionTag resource | `Route::resource('question-tag', QuestionTagController::class)` |
| 2 | Verify 7 resource routes registered | index, create, store, show, edit, update, destroy |
| 3 | Verify route name prefix `question-bank.` | Names: `question-bank.question-tag.*` |
| 4 | Verify URL prefix `/question-bank/` | URLs begin with `/question-bank/question-tag` |

---

#### TC-CR20: Route definitions — Extra routes (trash, restore, force-delete, toggle-status)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify GET `/question-bank/question-tag/trash/view` | Route `question-bank.question-tag.trashed` → `trashed()` |
| 2 | Verify GET `/question-bank/question-tag/{id}/restore` | Route `question-bank.question-tag.restore` → `restore()` |
| 3 | Verify DELETE `/question-bank/question-tag/{id}/force-delete` | Route `question-bank.question-tag.forceDelete` → `forceDelete()` |
| 4 | Verify POST `/question-bank/question-tag/{question_tag}/toggle-status` | Route `question-bank.question-tag.toggleStatus` → `toggleStatus()` |
| 5 | Confirm all extra routes are placed after resource route | Ordering avoids route collision |

---

#### TC-CR21: Route naming convention — Consistency across all route names

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review all 11 route names | Prefix: `question-bank.question-tag.*` |
| 2 | Verify resource routes: `.index`, `.create`, `.store`, `.show`, `.edit`, `.update`, `.destroy` | Standard resource convention |
| 3 | Verify extra routes: `.trashed`, `.restore`, `.forceDelete`, `.toggleStatus` | Custom suffixes match controller methods |

---

#### TC-CR22: Model — belongsToMany relationship to QuestionBank

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `QuestionTag` model for relationship methods | `belongsToMany` defined |
| 2 | Verify `belongsToMany(QuestionBank::class, 'qns_question_questiontag_jnt')` | Junction table `qns_question_questiontag_jnt` |
| 3 | Verify foreign key `question_tag_id` | Pivot FK references tag |
| 4 | Verify related key `question_bank_id` | Pivot FK references question |

---

#### TC-CR23: Model — scopeActive logic implementation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `scopeActive()` on QuestionTag | `where('is_active', true)` |
| 2 | Verify scope uses `BaseModel` or direct `Builder` | Standard Eloquent scope pattern |
| 3 | Verify scope is chainable | Returns `Builder` instance |

---

#### TC-CR24: Model — scopeFilter logic implementation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `scopeFilter()` on QuestionTag | Accepts `$filters` array parameter |
| 2 | Verify search logic: `where('short_name', 'like', '%{search}%')->orWhere('name', 'like', '%{search}%')` | Searches both fields |
| 3 | Verify status filter: `where('is_active', $filters['status'])` | Active/inactive filtering |
| 4 | Verify scope is chainable | Returns `Builder` instance |

---

#### TC-CR25: Activity Log — Event name values in controller activity() calls

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `store()` activity call | `activityLog($tag, 'Stored', ...)` |
| 2 | Review `update()` activity call | `activityLog($tag, 'Updated', ...)` |
| 3 | Review `destroy()` activity call | `activityLog($tag, 'Trashed', ...)` |
| 4 | Review `restore()` activity call | `activityLog($tag, 'Restored', ...)` |
| 5 | Review `forceDelete()` activity call | `activityLog($tag, 'Deleted', ...)` |
| 6 | Review `toggleStatus()` activity call | `activityLog($tag, 'Status Toggled', ...)` |
| 7 | Verify all 6 event names are consistent | No typos or mismatches |

---

#### TC-CR26: Flash Messages — All success keys defined in lang file

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify `flash('created.question_tag')` resolves | Lang key exists |
| 2 | Verify `flash('updated.question_tag')` resolves | Lang key exists |
| 3 | Verify `flash('trashed.question_tag')` resolves | Lang key exists |
| 4 | Verify `flash('restored.question_tag')` resolves | Lang key exists |
| 5 | Verify `flash('force_deleted.question_tag')` resolves | Lang key exists |
| 6 | Verify `flash('status_updated.question_tag')` resolves | Lang key exists |

---

#### TC-CR27: Permission Mismatch — KI-01 code review verification

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review controller gate calls | `tenant.question_bank.*` (underscore) — 11 controller methods |
| 2 | Review policy permission strings | `tenant.question-tag.*` (dash) — 8 policy gates |
| 3 | Review blade @can directives | `tenant.question-tag.*` (dash) — matches policy |
| 4 | Review request authorize() | `tenant.question-bank.*` (dash, `question-bank` not `question-tag`) — third variant |
| 5 | Confirm KI-01: Three different permission namespaces in use | **Mismatch** — controller gates likely never match any defined permission |

---

#### TC-CR28: Tab Integration — QuestionTag registered in QuestionBankController@index

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `QuestionBankController::index()` | Method loads tab data |
| 2 | Verify `tab = request('tab', 'question_bank')` | Tab parameter read from query |
| 3 | Verify `case 'question_tags':` in tab switch | QuestionTag data loaded when tab=question_tags |
| 4 | Verify `QuestionTag::orderBy('name')->paginate(10)` | Tags ordered by name, 10 per page |

---

#### TC-CR29: Blade — View file structure

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify `question-tags/index.blade.php` exists | Index/list view with search, filter, pagination |
| 2 | Verify `question-tags/view.blade.php` exists | Show/read-only view |
| 3 | Verify `question-tags/trash.blade.php` exists | Trashed tags listing |
| 4 | Verify `question-tags/create.blade.php` exists | Create form |
| 5 | Verify `question-tags/edit.blade.php` exists | Edit form |
| 6 | Confirm all views extend `questionbank::layouts.master` or parent | Consistent layout inheritance |

---

#### TC-CR30: Blade — Success flash rendered in parent layout component

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review parent layout blade | `@if(session('success'))` check present |
| 2 | Verify alert component renders session message | Flash message displayed |
| 3 | Verify auto-dismiss or close button | User can dismiss flash |

---

## 15. Known Issues

| # | Issue | Severity | Details |
|---|-------|----------|---------|
| KI-01 | Permission namespace mismatch: Controller uses `tenant.question_bank.*` (underscore) but Policy uses `tenant.question-tag.*` (dash) | **High** | `QuestionTagController` gates use `tenant.question_bank.viewAny`, `.view`, `.create`, `.update`, `.delete`, `.restore`, `.forceDelete` (underscore, `question_bank` namespace). `QuestionTagPolicy` uses `tenant.question-tag.viewAny`, `.view`, `.create`, `.update`, `.delete`, `.restore`, `.forceDelete`, `.status` (dash, `question-tag` namespace). Blade views use `tenant.question-tag.*` (dash, matching policy). `QuestionTagRequest::authorize()` uses `tenant.question-bank.*` (dash, `question-bank` namespace — a third variant). This means: (a) controller gate checks `tenant.question_bank.*` but no permission string in the system matches this exact pattern; (b) the policy is registered but never invoked by `Gate::authorize()` in the controller because the controller does not pass `$tag` model for policy auto-resolution; (c) the effective enforcement relies on blade `@can` directives and request-level authorization, with controller gates likely failing open if `tenant.question_bank.*` does not exist. |
| KI-02 | `index()` returns `abort(404)` unconditionally | **Medium** | The `index()` method in `QuestionTagController` immediately calls `abort(404)` before any gate check. This means the tag listing route `/question-bank/question-tag` (GET) always returns 404. Tags are only accessible via the Question Bank tabbed interface (nested under question-bank.index). The pagination code (`QuestionTag::orderBy('name')->paginate(10)`) is unreachable. |
| KI-03 | `show()` uses `withTrashed()` allowing viewing of deleted tags without explicit permission | **Low** | The `show()` controller method uses `QuestionTag::withTrashed()->findOrFail($id)`, meaning soft-deleted tags are still viewable via direct URL. This may expose deleted tag information. However, the gate `tenant.question_bank.view` is still checked. |
| KI-04 | `toggleStatus()` has no validation request or input sanitization | **Low** | The `toggleStatus()` method directly inverts `$tag->is_active = !$tag->is_active` without any FormRequest or inline validation. It relies on the model's boolean cast for type safety. No CSRF token validation visible in controller (assumed in middleware). |
| KI-05 | `destroy()` does not check if tag is linked to questions before soft delete | **Low** | Unlike the Quest module which has `QuestUsageCheckService`, the `destroy()` method in `QuestionTagController` does not check if the tag has junction links. It deactivates and soft-deletes unconditionally. Junction records are preserved (no cascade on soft delete), but the tag can be trashed while still referenced. |
| KI-06 | `restore()` does not reset `is_active` to true | **Low** | Controller `restore()` calls `$tag->restore()` (clears deleted_at) but does NOT set `is_active = true`. During `destroy()`, `is_active` was set to false. After restore, the tag will be visible but have `is_active = 0` (inactive). Admin must manually toggle status back to active. |
| KI-07 | Policy `status()` method signature differs from CRUD methods | **Low** | `status(User $user): bool` has no `QuestionTag $tag` parameter, unlike `view()`, `update()`, `delete()` etc. This means status permission is global and not tag-specific. Consistently applied in blade with `@can('tenant.question-tag.status')` which matches. |
| KI-08 | Blade view uses `@can('tenant.question-tag.edit')` for Edit button but policy has no `.edit` gate | **Low** | In `question-tags/view.blade.php:28`, the Edit button is wrapped in `@can('tenant.question-tag.edit')`. However, the `QuestionTagPolicy` does not define an `edit` method — it uses `update` for edit/update. The `@can` directive falls through to the `update` gate if no explicit `edit` gate exists (Laravel convention), but this is a fragile implicit dependency. |
| KI-09 | No dedicated search scope on model | **Low** | The index blade has search/filter controls but the model `QuestionTag` does not define a `search()` scope. Search is likely handled via the parent QuestionBank index controller or relying on the paginated query. |

---

## 16. Execution Status

| TC ID | Test Case Name | Status (Pass/Fail/Blocked/Skip) | Tested By | Test Date | Bug ID | Notes |
|-------|---------------|--------------------------------|-----------|-----------|--------|-------|
| TC-P01 | Create — Minimal Tag | | | | | |
| TC-P02 | Create — All fields (is_active=OFF) | | | | | |
| TC-P03 | Create — Short name uniqueness diff | | | | | |
| TC-P04 | Create — Short name max length | | | | | |
| TC-P05 | Create — Name max length | | | | | |
| TC-P06 | Show — View active tag | | | | | |
| TC-P07 | Show — View soft-deleted tag | | | | | |
| TC-P08 | Edit — Update short_name | | | | | |
| TC-P09 | Edit — Update name | | | | | |
| TC-P10 | Edit — Update is_active | | | | | |
| TC-P11 | Edit — Uniqueness exclude self | | | | | |
| TC-P12 | Destroy — Soft delete unused | | | | | |
| TC-P13 | Trashed — View trash | | | | | |
| TC-P14 | Restore — Restore tag | | | | | |
| TC-P15 | Force Delete — Perm delete | | | | | |
| TC-P16 | Toggle Status — AJAX toggle | | | | | |
| TC-P17 | Toggle Status — Active list filter | | | | | |
| TC-P18 | Index — Paginated list | | | | | |
| TC-N01 | Create — Missing required fields | | | | | |
| TC-N02 | Create — Duplicate short_name | | | | | |
| TC-N03 | Create — Short name too long | | | | | |
| TC-N04 | Create — Name too long | | | | | |
| TC-N05 | Edit — Duplicate short_name | | | | | |
| TC-N06 | Edit — Non-existent ID | | | | | |
| TC-N07 | Show — Non-existent ID | | | | | |
| TC-N08 | Destroy — Non-existent ID | | | | | |
| TC-N09 | Restore — Non-existent ID | | | | | |
| TC-N10 | Force Delete — Non-existent ID | | | | | |
| TC-N11 | Toggle — Non-existent ID | | | | | |
| TC-N12 | Create — Without permission | | | | | |
| TC-N13 | Edit — Without permission | | | | | |
| TC-N14 | Delete — Without permission | | | | | |
| TC-N15 | View Trash — Without permission | | | | | |
| TC-N16 | Force Delete — Without permission | | | | | |
| TC-N17 | Toggle — Without permission | | | | | |
| TC-N18 | View — Without permission | | | | | |
| TC-N19 | Index — abort(404) | | | | | |
| TC-N20 | Force Delete — Linked cascade | | | | | |
| TC-D01 | Cascade — Force delete junction | | | | | |
| TC-D02 | Cascade — Soft delete no cascade | | | | | |
| TC-D03 | Business — Activity log all actions | | | | | |
| TC-D04 | Business — is_active boolean cast | | | | | |
| TC-D05 | Business — Linked tag cascade | | | | | |
| TC-CR01 | Controller store() — Flow | | | | | |
| TC-CR02 | Controller show() — With trashed | | | | | |
| TC-CR03 | Controller edit() — Find or fail | | | | | |
| TC-CR04 | Controller update() — Change tracking | | | | | |
| TC-CR05 | Controller destroy() — Soft delete | | | | | |
| TC-CR06 | Controller trashed() — Listing | | | | | |
| TC-CR07 | Controller restore() — Restore flow | | | | | |
| TC-CR08 | Controller forceDelete() — Perm delete | | | | | |
| TC-CR09 | Controller toggleStatus() — AJAX | | | | | |
| TC-CR10 | Request rules() validation | | | | | |
| TC-CR11 | Request authorize() with gate | | | | | |
| TC-CR12 | Policy permission methods | | | | | |
| TC-CR13 | Model SoftDeletes + casts | | | | | |
| TC-CR14 | Blade @can Directives | | | | | |
| TC-CR15 | Blade isset()/null-safe checks | | | | | |
| TC-CR16 | Blade Success Flash Messages | | | | | |
| TC-P19 | Search — Filter by short_name | | | | | |
| TC-P20 | Search — Filter by name | | | | | |
| TC-P21 | List — Pagination page 2 | | | | | |
| TC-P22 | List — Empty tag list | | | | | |
| TC-P23 | List — Status filter active | | | | | |
| TC-P24 | List — Status filter inactive | | | | | |
| TC-P25 | List — Status filter all | | | | | |
| TC-P26 | Create — Alphanumeric short_name | | | | | |
| TC-P27 | Create — Short name min length | | | | | |
| TC-P28 | Restore — Tag visible on index | | | | | |
| TC-N21 | Create — short_name empty string | | | | | |
| TC-N22 | Create — name empty string | | | | | |
| TC-N23 | Edit — short_name 101 chars | | | | | |
| TC-N24 | Edit — name 256 chars | | | | | |
| TC-N25 | Create — short_name whitespace | | | | | |
| TC-N26 | Create — name whitespace | | | | | |
| TC-N27 | Toggle — Soft-deleted tag 404 | | | | | |
| TC-N28 | Trash — Empty trash listing | | | | | |
| TC-N29 | Toggle — Multiple consecutive toggles | | | | | |
| TC-N30 | Destroy — Already soft-deleted | | | | | |
| TC-D06 | Unique — short_name across soft-deleted | | | | | |
| TC-D07 | Cascade — Multiple tags one question | | | | | |
| TC-D08 | Cascade — Multiple questions one tag | | | | | |
| TC-D09 | Business — scopeActive | | | | | |
| TC-D10 | Business — scopeFilter | | | | | |
| TC-D12 | Business — Junction unique constraint | | | | | |
| TC-D13 | Cascade — Restore preserves junction | | | | | |
| TC-D14 | Business — Timestamps auto-set | | | | | |
| TC-D15 | Business — Soft-delete excluded from default | | | | | |
| TC-CR17 | Controller index() — abort(404) | | | | | |
| TC-CR18 | Controller create() — Gate view | | | | | |
| TC-CR19 | Route — Resource routes (7) | | | | | |
| TC-CR20 | Route — Extra routes (4) | | | | | |
| TC-CR21 | Route — Naming convention | | | | | |
| TC-CR22 | Model — belongsToMany relationship | | | | | |
| TC-CR23 | Model — scopeActive logic | | | | | |
| TC-CR24 | Model — scopeFilter logic | | | | | |
| TC-CR25 | Activity Log — Event names | | | | | |
| TC-CR26 | Flash Messages — Lang keys | | | | | |
| TC-CR27 | Permission Mismatch — KI-01 | | | | | |
| TC-CR28 | Tab Integration — QuestionBankController | | | | | |
| TC-CR29 | Blade — View file structure | | | | | |
| TC-CR30 | Blade — Success flash layout | | | | | |

---

## 17. Feature Summary Matrix

| Feature Area | Positive TCs | Negative TCs | Dependency TCs | Code Review TCs | Total |
|-------------|-------------|-------------|---------------|----------------|-------|
| Creation | 7 | 8 | 0 | 4 | 19 |
| View/Show | 2 | 2 | 0 | 1 | 5 |
| Edit/Update | 4 | 4 | 0 | 2 | 10 |
| Soft Delete | 1 | 2 | 1 | 1 | 5 |
| Trash/Restore | 3 | 3 | 1 | 2 | 9 |
| Force Delete | 1 | 3 | 4 | 1 | 9 |
| Status Toggle | 2 | 4 | 0 | 1 | 7 |
| Index/List | 8 | 1 | 0 | 2 | 11 |
| Auth/Permissions | 0 | 3 | 0 | 1 | 4 |
| Business Logic | 0 | 0 | 8 | 6 | 14 |
| View/Blade | 0 | 0 | 0 | 6 | 6 |
| Route | 0 | 0 | 0 | 3 | 3 |
| **Total** | **28** | **30** | **14** | **30** | **102** |

---

## 18. TC Count Summary

| Category | Count |
|----------|-------|
| Positive (TC-P) | 28 |
| Negative (TC-N) | 30 |
| Dependency (TC-D) | 14 |
| Code Review (TC-CR) | 30 |
| **Total** | **102** |

---

*Document Version: 2.0 — Last Updated: 2026-07-19*
*TC List covers: REQ-QTAG-001 (Creation), REQ-QTAG-002 (View), REQ-QTAG-003 (Edit/Update), REQ-QTAG-004 (Soft Delete/Trash/Restore/Force Delete), REQ-QTAG-005 (Status Toggle), REQ-QTAG-006 (List/Index), and related code paths. Total TC count: 102 (28 Positive + 30 Negative + 14 Dependency + 30 Code Review). Sections: 18 (BC-DB, BC-VAL, BC-AUTH, BC-BIZ, BC-REF, Test Case Summary, Positive/Negative/Dependency/CR Steps, Route Reference, Known Issues, Execution Status, Feature Summary Matrix, TC Count Summary).*
