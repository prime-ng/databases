# lms_HPC_TemplateParts_TcList

## Module: HPC → Template Parts

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | HPC |
| Tab Group | Template Management |
| Feature | Template Parts |
| URL(s) | `hpc/templates` (tab), `hpc/hpc-template-parts`, `hpc/hpc-template-parts/create`, `hpc/hpc-template-parts/{id}`, `hpc/hpc-template-parts/{id}/edit`, `hpc/hpc-template-parts/trash/view`, `hpc/hpc-template-parts/{id}/restore`, `hpc/hpc-template-parts/{id}/force-delete`, `hpc/hpc-template-parts/{id}/toggle-status` |
| Controller | `Modules\Hpc\Http\Controllers\HpcTemplatePartsController` |
| Model(s) | `Modules\Hpc\Models\HpcTemplateParts`, `Modules\Hpc\Models\HpcTemplatePartsItems` |
| Validation (Create) | `Modules\Hpc\Http\Requests\HpcTemplatePartsRequest` |
| Validation (Update) | `Modules\Hpc\Http\Requests\HpcTemplatePartsRequest` |
| Permissions | `tenant.hpc.viewAny`, `tenant.hpc-template-parts.create`, `tenant.hpc-template-parts.view`, `tenant.hpc-template-parts.update`, `tenant.hpc-template-parts.delete`, `tenant.hpc-template-parts.restore`, `tenant.hpc-template-parts.forceDelete` |
| Soft Deletes | Yes (both models) |
| Activity Log | Created, Updated, Deleted, Restored, Force Deleted, Toggled |

---

## 2. Pre-conditions

- Required permissions: `tenant.hpc.viewAny` for index, plus specific `tenant.hpc-template-parts.*` for CRUD actions
- At least one `HpcTemplate` record must exist to reference via `template_id`
- At least one `HpcTemplateParts` record exists for list/view/update/delete operations
- Test user must have all applicable permissions (default admin user or user assigned via role)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For seeding, the `hpc_templates` table must have at least 1 active template record
- For items testing, `hpc_template_parts_items` table must be properly migrated with FK to `hpc_template_parts`
- Create/edit forms expect `HpcTemplates::where('is_active', 1)->get()` loaded for template dropdown
- Create form expects `$itemsCount = 1` passed to view (dynamic items count)
- Edit form expects `$part->items` loaded via relationship for items table display
- Store/update expects `$request->items` array with child item data
- Items on update use `forceDelete()` + recreate pattern (not individual item updates)
- Trash operations require at least one soft-deleted record
- Pagination tests require at least 16 seeded records to test page 2
- Search/filter tests require multiple records with varied label values
- Toggle status expects `is_active` boolean column on `hpc_template_parts`

---

## 3. Default Data Load

When the index page loads via `HpcTemplatePartsController` (GET `hpc/hpc-template-parts`), the following data is fetched:

| Data Loaded | Source | Query | Filters | Pagination |
|------------|--------|-------|---------|------------|
| All active template parts | `HpcTemplateParts::with('template')->latest()` | All non-trashed records with template relation | Search by label | 10 per page |
| Single part | `HpcTemplateParts::with('template', 'items')->findOrFail($id)` | Route binding by id with template + items | None | None |
| Trash list | `HpcTemplateParts::onlyTrashed()->with('template')->latest('deleted_at')->paginate(10)` | Soft-deleted records only with template | None | 10 per page |
| Templates for dropdown (create) | `HpcTemplates::where('is_active', 1)->get()` | Active templates only | is_active = 1 | None |
| Templates for dropdown (edit) | `HpcTemplates::where('is_active', 1)->get()` | Active templates only | is_active = 1 | None |

---

## 4. Test Data Strategy

- **List/index**: Seed 20+ `HpcTemplateParts` records with varied label, template_id, display_order, and is_active values
- **Search**: Ensure at least 3 records share a partial label match (e.g., "Math", "Science")
- **Create**: Use valid `hpc_templates.id` references for template_id; provide 2-3 items in items array
- **Create (no items)**: Submit without items; only parent record created, no children
- **Edit**: Update existing record fields including label, template_id, display_order, is_active; modify items array
- **Edit — remove all items**: Submit with empty items array; all existing items forceDeleted, no new items created
- **Edit — add new items**: Submit with items array containing new entries; old items forceDeleted, new ones created
- **Soft Delete**: Select a record to delete; verify `is_active=false` before `deleted_at` set
- **Restore**: Soft-delete a record first, then restore; verify `is_active` returns to original value
- **Force Delete**: Soft-delete first, then force-delete; verify permanent removal from database
- **Toggle Status**: Toggle `is_active` from true→false and false→true; verify response structure
- **display_order**: Seed with varied order values (1, 2, 3, etc.) and verify ordering in list
- **Permissions**: Test with admin, user with specific permission, user without permission, and guest roles
- **Pre-test cleanup**: Delete created records before/after tests to avoid collisions

---

## 5. Business Conditions

### 4.1 Database Schema — `hpc_template_parts`

| BC ID | Table | Column | Type (DDL) | Constraints |
|-------|-------|--------|------------|-------------|
| BC-DB-01 | hpc_template_parts | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-02 | hpc_template_parts | template_id | INT UNSIGNED | NOT NULL, FK → hpc_templates.id |
| BC-DB-03 | hpc_template_parts | label | VARCHAR(255) | NOT NULL |
| BC-DB-04 | hpc_template_parts | display_order | INT | NOT NULL, DEFAULT 0 |
| BC-DB-05 | hpc_template_parts | is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-06 | hpc_template_parts | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-07 | hpc_template_parts | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-08 | hpc_template_parts | deleted_at | TIMESTAMP | NULLABLE, SoftDeletes |

### 4.2 Database Schema — `hpc_template_parts_items`

| BC ID | Table | Column | Type (DDL) | Constraints |
|-------|-------|--------|------------|-------------|
| BC-DB-09 | hpc_template_parts_items | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-10 | hpc_template_parts_items | part_id | INT UNSIGNED | NOT NULL, FK → hpc_template_parts.id |
| BC-DB-11 | hpc_template_parts_items | item_type | VARCHAR(50) | NOT NULL |
| BC-DB-12 | hpc_template_parts_items | code | VARCHAR(50) | NULLABLE |
| BC-DB-13 | hpc_template_parts_items | description | TEXT | NULLABLE |
| BC-DB-14 | hpc_template_parts_items | marks | DECIMAL(8,2) | NULLABLE |
| BC-DB-15 | hpc_template_parts_items | display_order | INT | NOT NULL, DEFAULT 0 |
| BC-DB-16 | hpc_template_parts_items | is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-17 | hpc_template_parts_items | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-18 | hpc_template_parts_items | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-19 | hpc_template_parts_items | deleted_at | TIMESTAMP | NULLABLE, SoftDeletes |

### 4.3 Validation Rules — `HpcTemplatePartsRequest` (Create)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | template_id | required, integer, exists:hpc_templates,id | The template id field is required. / The selected template id is invalid. |
| BC-VAL-02 | label | required, string, max:255 | The label field is required. / The label must not exceed 255 characters. |
| BC-VAL-03 | display_order | required, integer, min:0 | The display order field is required. / The display order must be at least 0. |
| BC-VAL-04 | is_active | sometimes, boolean | The is active field must be true or false. |
| BC-VAL-05 | items | nullable, array | The items must be an array. |
| BC-VAL-06 | items.*.item_type | required_with:items, string, max:50 | The item type field is required. |
| BC-VAL-07 | items.*.code | nullable, string, max:50 | The code must not exceed 50 characters. |
| BC-VAL-08 | items.*.description | nullable, string | The description must be a string. |
| BC-VAL-09 | items.*.marks | nullable, numeric, min:0 | The marks must be a valid number. |
| BC-VAL-10 | items.*.display_order | required_with:items, integer, min:0 | The display order field is required. |

### 4.4 Validation Rules — `HpcTemplatePartsRequest` (Update)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-U01 | template_id | required, integer, exists:hpc_templates,id | The template id field is required. / The selected template id is invalid. |
| BC-VAL-U02 | label | required, string, max:255 | The label field is required. / The label must not exceed 255 characters. |
| BC-VAL-U03 | display_order | required, integer, min:0 | The display order field is required. / The display order must be at least 0. |
| BC-VAL-U04 | is_active | sometimes, boolean | The is active field must be true or false. |
| BC-VAL-U05 | items | nullable, array | The items must be an array. |
| BC-VAL-U06 | items.*.item_type | required_with:items, string, max:50 | The item type field is required. |
| BC-VAL-U07 | items.*.code | nullable, string, max:50 | The code must not exceed 50 characters. |
| BC-VAL-U08 | items.*.description | nullable, string | The description must be a string. |
| BC-VAL-U09 | items.*.marks | nullable, numeric, min:0 | The marks must be a valid number. |
| BC-VAL-U10 | items.*.display_order | required_with:items, integer, min:0 | The display order field is required. |

### 4.5 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | `tenant.hpc.viewAny` | index() | Without → 403 on `hpc/hpc-template-parts` index |
| BC-AUTH-02 | `tenant.hpc-template-parts.create` | create(), store() | Without → 403 on `create` page and `store` POST |
| BC-AUTH-03 | `tenant.hpc-template-parts.view` | show() | Without → 403 on `show` GET |
| BC-AUTH-04 | `tenant.hpc-template-parts.update` | edit(), update(), toggleStatus() | Without → 403 on `edit` page and `update` PUT |
| BC-AUTH-05 | `tenant.hpc-template-parts.delete` | destroy() | Without → 403 on `destroy` DELETE |
| BC-AUTH-06 | `tenant.hpc-template-parts.restore` | trashed(), restore() | Without → 403 on `trashed`, `restore` |
| BC-AUTH-07 | `tenant.hpc-template-parts.forceDelete` | forceDelete() | Without → 403 on `forceDelete` DELETE |
| BC-AUTH-08 | Guest (unauthenticated) | — | Redirect to login for all routes |

### 4.6 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | `store()` called with items array | Creates parent HpcTemplateParts record, then iterates items array and creates child HpcTemplatePartsItems records via `$part->items()->create($item)` |
| BC-BIZ-02 | `store()` called without items array | Creates parent record only; no child items created |
| BC-BIZ-03 | `update()` called with items array | `$part->items()->forceDelete()` removes all existing items, then recreates them with new data |
| BC-BIZ-04 | `update()` called without items array | Parent record updated; `$part->items()->forceDelete()` not called; items unchanged |
| BC-BIZ-05 | `update()` called with empty items array | `$part->items()->forceDelete()` removes all existing items; no new items created |
| BC-BIZ-06 | `destroy()` called on active part | Sets `is_active = false`, then calls `delete()` (SoftDeletes) |
| BC-BIZ-07 | `toggleStatus()` called | Flips `is_active` boolean value; returns JSON success response |
| BC-BIZ-08 | `restore()` called | Restores soft-deleted record; `is_active` set back to original value |
| BC-BIZ-09 | `forceDelete()` called | Permanently removes record from database (must be trashed first) |
| BC-BIZ-10 | Activity Log on create | Event `Created` fired with message "HPC Template Part created." |
| BC-BIZ-11 | Activity Log on update | Event `Updated` fired with changes diff (for each changed attribute) |
| BC-BIZ-12 | Activity Log on soft delete | Event `Deleted` fired with message "HPC Template Part deleted." |
| BC-BIZ-13 | Activity Log on restore | Event `Restored` fired with message "HPC Template Part restored." |
| BC-BIZ-14 | Activity Log on force delete | Event `Force Deleted` fired with message "HPC Template Part permanently deleted." |
| BC-BIZ-15 | Activity Log on toggle status | Event `Toggled` fired with message "HPC Template Part status toggled." |
| BC-BIZ-16 | Index page loads with `with('template')` | Returns paginated collection with attached template name |
| BC-BIZ-17 | Trash page renders only soft-deleted | Uses `onlyTrashed()` scope; no active records shown |
| BC-BIZ-18 | Search filters by label | `where('label', 'like', '%search%')` applied |
| BC-BIZ-19 | show() loads items relation | `$part = HpcTemplateParts::with('template', 'items')->findOrFail($id)` — both relations loaded |
| BC-BIZ-20 | Create form initial items count | View receives `$itemsCount = 1` — at least 1 item row rendered in form |
| BC-BIZ-21 | display_order default on create | Defaults to 0 unless explicitly set |

### 4.7 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | hpc_template_parts.template_id | hpc_templates (id) | CASCADE |
| BC-REF-02 | hpc_template_parts_items.part_id | hpc_template_parts (id) | CASCADE |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Index page loads with paginated template parts list | `hpc/hpc-template-parts` renders with 10 records per page, template name column visible | — | — | ⬜ |
| TC-P02 | Pagination navigates to page 2 | Page 2 loads with next set of records; pagination controls visible | — | — | ⬜ |
| TC-P03 | Search by label filters results | Typing partial label in search field filters list to matching records | — | — | ⬜ |
| TC-P04 | Create template part with items | All fields saved; parent + 2 child items created; redirect to index with success message | — | — | ⬜ |
| TC-P05 | Create template part without items | Parent record created with no children; items table empty for this part | — | — | ⬜ |
| TC-P06 | Create template part with minimum fields (label, template_id, display_order only) | Part created with is_active=true by default; no items created | — | — | ⬜ |
| TC-P07 | Edit template part — update all fields + items | Parent fields updated; old items forceDeleted; new items created; success message shown | — | — | ⬜ |
| TC-P08 | Edit template part — remove all items | Submit with empty items array; all existing items forceDeleted; parent unchanged | — | — | ⬜ |
| TC-P09 | Edit template part — update parent only, keep existing items | Parent fields updated; items unchanged | — | — | ⬜ |
| TC-P10 | View single template part with items | Show page displays all parent fields + items table with all child records | — | — | ⬜ |
| TC-P11 | Soft delete an active template part | `destroy()` sets is_active=false then soft-deletes; record appears in trash | — | — | ⬜ |
| TC-P12 | Restore template part from trash | Restored record removed from trash view; reappears in main list; is_active restored | — | — | ⬜ |
| TC-P13 | Force delete template part from trash | Record permanently removed; does not appear in trash or main list | — | — | ⬜ |
| TC-P14 | Toggle template part from active to inactive | is_active flips to false; JSON response confirms success | — | — | ⬜ |
| TC-P15 | Toggle template part from inactive to active | is_active flips to true; JSON response confirms success | — | — | ⬜ |
| TC-P16 | Create template part with display_order = 0 | display_order stored and displayed correctly; order default applied | — | — | ⬜ |
| TC-P17 | Create template part with display_order = 99 | Custom order value stored; sorts correctly in listing | — | — | ⬜ |
| TC-P18 | Index page shows template name from relation | `$part->template->title` or `->code` displayed in template column | — | — | ⬜ |
| TC-P19 | View trash list | Trash page shows only soft-deleted records with restore/force-delete actions | — | — | ⬜ |
| TC-P20 | Verify activity log entry on template part create | Activity log shows "HPC Template Part created." with correct model reference | — | — | ⬜ |
| TC-P21 | Verify activity log entry on template part update with changes | Activity log shows detailed changes array with old/new values | — | — | ⬜ |
| TC-P22 | Bulk permissions — user with all hpc-template-parts permissions | User can perform all CRUD, restore, forceDelete, and toggle actions | — | — | ⬜ |
| TC-P23 | Create form loads with itemsCount=1 | Create view renders with at least 1 dynamic item row | — | — | ⬜ |
| TC-P24 | Edit form loads with existing items populated | Existing items rendered in items table within edit form | — | — | ⬜ |
| TC-P25 | Navigate from trash back to main list | Link returns to active template parts index | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Create — missing template_id | 422 Validation Error: "The template id field is required." | — | — | ⬜ |
| TC-N02 | Create — invalid template_id (non-existent) | 422 Validation Error: "The selected template id is invalid." | — | — | ⬜ |
| TC-N03 | Create — missing label | 422 Validation Error: "The label field is required." | — | — | ⬜ |
| TC-N04 | Create — label exceeds 255 characters | 422 Validation Error: "The label must not exceed 255 characters." | — | — | ⬜ |
| TC-N05 | Create — missing display_order | 422 Validation Error: "The display order field is required." | — | — | ⬜ |
| TC-N06 | Create — negative display_order | 422 Validation Error: "The display order must be at least 0." | — | — | ⬜ |
| TC-N07 | Create — items.*.item_type missing when items provided | 422 Validation Error: "The item type field is required." | — | — | ⬜ |
| TC-N08 | Create — items.*.marks negative | 422 Validation Error: "The marks must be at least 0." | — | — | ⬜ |
| TC-N09 | Edit — non-existent part ID | 404 Not Found | — | — | ⬜ |
| TC-N10 | Edit — invalid template_id | 422 Validation Error: "The selected template id is invalid." | — | — | ⬜ |
| TC-N11 | Delete — non-existent part ID | 404 Not Found | — | — | ⬜ |
| TC-N12 | Restore — non-deleted (active) part | Error: cannot restore a record that is not soft-deleted | — | — | ⬜ |
| TC-N13 | Force delete — non-trashed (active) part | Error: cannot force-delete a record that is not soft-deleted first | — | — | ⬜ |
| TC-N14 | Toggle — non-existent part ID | 404 Not Found | — | — | ⬜ |
| TC-N15 | Permission denied — index page without tenant.hpc.viewAny | 403 Forbidden | — | — | ⬜ |
| TC-N16 | Permission denied — create without tenant.hpc-template-parts.create | 403 Forbidden on create page and store action | — | — | ⬜ |
| TC-N17 | Guest access — redirect to login | Unauthenticated user redirected to login page for all routes | — | — | ⬜ |
| TC-N18 | Label exceeds max length on update | 422 Validation Error: "The label must not exceed 255 characters." | — | — | ⬜ |
| TC-N19 | display_order exceeds max integer range | 422 Validation Error: integer validation | — | — | ⬜ |
| TC-N20 | items.*.code exceeds 50 characters | 422 Validation Error: "The code must not exceed 50 characters." | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | template_id FK integrity — creating part with valid template | Part created successfully referencing existing template | — | — | ⬜ |
| TC-D02 | A | template_id FK integrity — creating part with invalid template | 422 Validation Error from FormRequest | — | — | ⬜ |
| TC-D03 | A | Cascade delete — deleting template cascades to parts | When template deleted, associated parts may cascade or be restricted based on DDL | — | — | ⬜ |
| TC-D04 | B | SoftDeletes trait applied correctly | Calling `delete()` sets `deleted_at` timestamp; record excluded from normal queries | — | — | ⬜ |
| TC-D05 | B | destroy() sets is_active=false before delete | Before soft-delete, `is_active` set to 0; after restore, `is_active` returns to original | — | — | ⬜ |
| TC-D06 | B | restore() brings back record | `restore()` clears `deleted_at`; record reappears in normal queries | — | — | ⬜ |
| TC-D07 | B | forceDelete() removes permanently | Record removed from DB; `withTrashed()` does not find it either | — | — | ⬜ |
| TC-D08 | B | withTrashed() scope on trash view | Trash page uses `onlyTrashed()`; shows only soft-deleted records | — | — | ⬜ |
| TC-D09 | B | toggleStatus() response structure | Returns JSON with `success: true` and updated `is_active` value | — | — | ⬜ |
| TC-D10 | C | hasMany('items') relationship loads correctly | Part->items eager-loadable; items array present in show view and edit form | — | — | ⬜ |
| TC-D11 | C | belongsTo('template') relationship loads correctly | Part->template relation loads template title/code | — | — | ⬜ |
| TC-D12 | C | Items forceDelete+recreate on update | Calling update with items array forceDeletes all old items and creates new ones with new IDs | — | — | ⬜ |
| TC-D13 | D | FormRequest authorize() gate check | Create/Update FormRequest has `authorize()` that checks permission gate | — | — | ⬜ |
| TC-D14 | D | Index pagination default page size (10 per page) | With 20 records, page 1 shows 10, page 2 shows 10 | — | — | ⬜ |
| TC-D15 | D | Index sort order | Records sorted by `created_at` DESC or `display_order` ASC | — | — | ⬜ |
| TC-D16 | E | is_active default value on create | Creating without is_active defaults to true | — | — | ⬜ |
| TC-D17 | E | Timestamps auto-set on create and update | `created_at` set on insert; `updated_at` refreshed on update | — | — | ⬜ |
| TC-D18 | E | deleted_at nullable after restore | After restore, `deleted_at` is NULL; record acts as active | — | — | ⬜ |
| TC-D19 | F | ActivityLog events fire correct message format | "HPC Template Part created.", "HPC Template Part updated.", "HPC Template Part deleted.", "HPC Template Part restored.", "HPC Template Part permanently deleted.", "HPC Template Part status toggled." | — | — | ⬜ |
| TC-D20 | F | Route model binding resolves correctly | Routes bind `{id}` to `HpcTemplateParts` model; invalid ID returns 404 | — | — | ⬜ |
| TC-D21 | F | Route permission middleware applied to all routes | Each route group has `can:` or `Auth` middleware protecting it | — | — | ⬜ |
| TC-D22 | F | Activity log records association via polymorphic relationship | Activity log entries have correct `subject_type` and `subject_id` referencing HpcTemplateParts | — | — | ⬜ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Blade @can Directives — Permission-based visibility for all action buttons | View includes @can('tenant.hpc-template-parts.create'), @can('tenant.hpc-template-parts.update'), @can('tenant.hpc-template-parts.delete'), @canany(['tenant.hpc-template-parts.restore', 'tenant.hpc-template-parts.forceDelete']) for access control on all CRUD buttons and actions | — | — | ◌ |
| TC-CR02 | CR | P1 | Breadcrumb Config — Route registered in config/breadcrumb.php | Breadcrumb configuration for HPC template parts module defined in breadcrumb config; breadcrumb visible and links correctly | — | — | ◌ |
| TC-CR03 | CR | P1 | Controller — DB Transactions in store/update | store() and update() use DB::transaction() or DB::beginTransaction+commit/rollback with try-catch for atomic parent+children operations | — | — | ◌ |
| TC-CR04 | CR | P1 | Controller — Change Tracking on Update | update() captures `$original = $part->getOriginal()`, then iterates `$part->getChanges()` to build changes array, skips updated_at | — | — | ◌ |
| TC-CR05 | CR | P1 | Controller — Items forceDelete+recreate Atomicity | update() calls `$part->items()->forceDelete()` then recreates items in same operation; failure should rollback entire transaction | — | — | ◌ |

---

## 7. Detailed Test Steps

### 7.1 Positive TC Steps

#### TC-P01: Index Page Loads With Paginated Template Parts List

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard page loads successfully |
| 2 | Navigate to `hpc/hpc-template-parts` | Index page renders without errors |
| 3 | Verify page heading shows "Template Parts" or equivalent | Correct heading displayed |
| 4 | Check that records are displayed in a table/list | Records visible |
| 5 | Count visible rows | Shows 10 records (pagination limit) |
| 6 | Verify pagination controls at bottom of page | Pagination bar visible |
| 7 | Check columns: label, template, display_order, is_active, action | All columns present |

---

#### TC-P02: Pagination Navigates To Page 2

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed at least 16 HpcTemplateParts records | 16+ records exist |
| 2 | Navigate to `hpc/hpc-template-parts` | Page 1 shows 10 records |
| 3 | Click page 2 link in pagination control | Page 2 loads |
| 4 | Verify page 2 shows remaining records | 6+ record(s) displayed |
| 5 | Verify page 2 URL contains `?page=2` | Query parameter present |
| 6 | Navigate back to page 1 | First 10 records shown again |

---

#### TC-P03: Search By Label Filters Results

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed parts with labels: "Math Problems", "Science Lab", "Art Project" | Varied labels |
| 2 | Navigate to `hpc/hpc-template-parts` | Index loads |
| 3 | Enter "Math" in search field | Filter triggers |
| 4 | Verify only records with "Math" in label are shown | 1 result (Math Problems) |
| 5 | Enter "Project" in search field | Shows 1 result (Art Project) |
| 6 | Clear search and verify all records return | Full list restored |

---

#### TC-P04: Create Template Part With Items

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `hpc/hpc-template-parts/create` | Create form loads |
| 2 | Select template_id from dropdown | Template selected |
| 3 | Enter label: "Test Part With Items" | Label populated |
| 4 | Enter display_order: 1 | Order set |
| 5 | Add 2 item rows: Item1 (type=input, code=INP-01, marks=5), Item2 (type=textarea, code=TA-01, marks=10) | Items added to form |
| 6 | Set is_active: true | Active checked |
| 7 | Click Submit/Save | Form submitted |
| 8 | Verify redirect to `hpc/hpc-template-parts` | Redirected |
| 9 | Verify success message "HPC Template Part created successfully" | Flash message visible |
| 10 | Query DB for new record | Part record exists with all provided values |
| 11 | Query hpc_template_parts_items for child records | 2 items created with correct part_id |

---

#### TC-P05: Create Template Part Without Items

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `hpc/hpc-template-parts/create` | Create form loads |
| 2 | Select template_id | Template selected |
| 3 | Enter label: "Empty Part" | Label populated |
| 4 | Enter display_order: 2 | Order set |
| 5 | Do not add any item rows | No items |
| 6 | Set is_active: true | Active checked |
| 7 | Click Submit/Save | Form submitted |
| 8 | Verify success message | Flash message visible |
| 9 | Query DB: record exists | Parent record created |
| 10 | Query hpc_template_parts_items: no records for this part_id | Items table empty |

---

#### TC-P06: Create Template Part With Minimum Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `hpc/hpc-template-parts/create` | Create form loads |
| 2 | Select template_id | Template selected |
| 3 | Enter label: "Minimal Part" | Label populated |
| 4 | Enter display_order: 0 | Order set |
| 5 | Leave is_active at default | Default checked (true) |
| 6 | Click Submit/Save | Form submitted |
| 7 | Verify success message | Flash message visible |
| 8 | Query DB: is_active is true, display_order is 0, no items | Values correct |

---

#### TC-P07: Edit Template Part — Update All Fields + Items

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create initial part with 2 items | Base record + 2 items exist |
| 2 | Navigate to `hpc/hpc-template-parts/{id}/edit` | Edit form loads with pre-filled data and existing items |
| 3 | Change label to "Updated Part Label" | Label updated |
| 4 | Change display_order to 5 | Order updated |
| 5 | Remove old items and add 3 new items with different data | Items changed |
| 6 | Toggle is_active to false | Active unchecked |
| 7 | Click Update/Save | Form submitted |
| 8 | Verify redirect and success message | Redirected |
| 9 | Query DB: parent fields match updated values | Persisted correctly |
| 10 | Query hpc_template_parts_items: old items forceDeleted (deleted_at set), 3 new items created with new IDs | Items replaced |

---

#### TC-P08: Edit Template Part — Remove All Items

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create initial part with 2 items | Base record + 2 items exist |
| 2 | Navigate to edit for this part | Edit form loads |
| 3 | Remove all item rows from form | No items in form |
| 4 | Submit with empty items array | Form submitted |
| 5 | Verify success message | Flash message visible |
| 6 | Query DB: parent record unchanged | Part still exists |
| 7 | Query items: old items have deleted_at set (forceDeleted) | Items removed |

---

#### TC-P09: Edit Template Part — Update Parent Only

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create initial part with 2 items | Base record + items exist |
| 2 | Navigate to edit | Edit form loads |
| 3 | Change label only | Label changed |
| 4 | Leave items unchanged | Items array not submitted |
| 5 | Click Update/Save | Form submitted |
| 6 | Verify success message | Flash message visible |
| 7 | Query DB: label updated, items still exist unchanged | Parent updated, children intact |

---

#### TC-P10: View Single Template Part With Items

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create part with 3 items | Record + 3 items |
| 2 | Navigate to `hpc/hpc-template-parts/{id}` | Show page renders |
| 3 | Verify all parent fields displayed | template, label, display_order, is_active visible |
| 4 | Verify items table displayed | All 3 items shown with item_type, code, description, marks |
| 5 | Verify edit button visible (with permission) | Edit action available |
| 6 | Verify delete button visible (with permission) | Delete action available |

---

#### TC-P11: Soft Delete An Active Template Part

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure a template part record exists | Record present |
| 2 | Navigate to `hpc/hpc-template-parts` | Index loads |
| 3 | Click delete button for the record | Confirmation dialog appears |
| 4 | Confirm deletion | Process executes |
| 5 | Verify success message | Flash message visible |
| 6 | Query DB: `is_active = 0` AND `deleted_at` is set | Soft deleted |
| 7 | Verify record no longer visible in main list | Index shows remaining records |
| 8 | Verify record appears in trash view | Trash shows the record |

---

#### TC-P12: Restore Template Part From Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure a soft-deleted part exists | Trashed record present |
| 2 | Navigate to trash view | Trash list loads |
| 3 | Click restore button for the record | Confirmation appears |
| 4 | Confirm restore | Process executes |
| 5 | Verify success message | Flash message visible |
| 6 | Query DB: `deleted_at` is NULL, `is_active` = 1 | Restored |
| 7 | Verify record reappears in main list | Index shows the restored record |

---

#### TC-P13: Force Delete Template Part From Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure a soft-deleted part exists | Trashed record present |
| 2 | Navigate to trash view | Trash list loads |
| 3 | Click force-delete button | Confirmation appears |
| 4 | Confirm permanent deletion | Process executes |
| 5 | Verify success message | Flash message visible |
| 6 | Query DB: record does not exist (withTrashed also returns empty) | Permanently removed |

---

#### TC-P14: Toggle Template Part From Active To Inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure an active part exists | Record with is_active=1 |
| 2 | Navigate to `hpc/hpc-template-parts` | Index loads |
| 3 | Click status toggle switch for the record | AJAX request sent |
| 4 | Verify JSON response: `{"success": true, "is_active": false}` | Response correct |
| 5 | Verify UI badge changes to Inactive | Visual feedback updated |

---

#### TC-P15: Toggle Template Part From Inactive To Active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure an inactive part exists | Record with is_active=0 |
| 2 | Navigate to `hpc/hpc-template-parts` | Index loads |
| 3 | Click status toggle switch | AJAX request sent |
| 4 | Verify JSON response: `{"success": true, "is_active": true}` | Response correct |
| 5 | Verify UI badge changes to Active | Visual feedback updated |

---

#### TC-P16: Create Template Part With display_order = 0

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Create loads |
| 2 | Select template, enter label "Order Zero Part" | Fields filled |
| 3 | Enter display_order: 0 | Order set to 0 |
| 4 | Submit form | Created |
| 5 | Verify in index listing | Record shown with order 0 |

---

#### TC-P17: Create Template Part With display_order = 99

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Create loads |
| 2 | Select template, enter label "High Order Part" | Fields filled |
| 3 | Enter display_order: 99 | Order set |
| 4 | Submit form | Created |
| 5 | Verify in index listing sorted by display_order | Record shown with order 99 |

---

#### TC-P18: Index Page Shows Template Name From Relation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create template "Math Template" first | Template exists |
| 2 | Create part assigned to "Math Template" | Part with template_id = Math Template's ID |
| 3 | Navigate to index page | List loads |
| 4 | Verify the template column shows "Math Template" | Template name visible |

---

#### TC-P19: View Trash List

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `hpc/hpc-template-parts/trash/view` | Trash page loads |
| 2 | Verify only soft-deleted records shown | No active records |
| 3 | Verify each record has restore and force-delete action buttons | Actions visible |
| 4 | Click "Back to list" or navigate to index | Main list loads |

---

#### TC-P20: Verify Activity Log Entry On Template Part Create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a new template part | Part created |
| 2 | Navigate to activity log | Log entries visible |
| 3 | Find the entry for created part | Entry exists with event "Created" and message "HPC Template Part created." |

---

#### TC-P21: Verify Activity Log Entry On Template Part Update With Changes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create template part with label "Original Label" | Part exists |
| 2 | Edit part — change label to "Updated Label" | Part updated |
| 3 | Navigate to activity log | Log entries visible |
| 4 | Find the update entry | Entry has event "Updated", changes array includes label with old/new values |

---

#### TC-P22: Bulk Permissions — User With All Permissions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Assign user role with all `tenant.hpc-template-parts.*` permissions | User has full access |
| 2 | Login as this user | Dashboard loads |
| 3 | Navigate to `hpc/hpc-template-parts` | Index loads |
| 4 | Verify create button visible | Can create |
| 5 | Verify edit/view/delete buttons on each row | Can edit/view/delete |
| 6 | Create a new part | Success |
| 7 | Edit the part | Success |
| 8 | Delete the part | Record trashed |
| 9 | Restore from trash | Record restored |
| 10 | Force delete from trash | Record permanently removed |

---

#### TC-P23: Create Form Loads With itemsCount = 1

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `hpc/hpc-template-parts/create` | Create form loads |
| 2 | Verify at least 1 dynamic item row is present in the form | Item row visible with item_type, code, description, marks fields |

---

#### TC-P24: Edit Form Loads With Existing Items Populated

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create part with 3 items | Part + 3 items exist |
| 2 | Navigate to `hpc/hpc-template-parts/{id}/edit` | Edit form loads |
| 3 | Verify all 3 items are rendered in the items section | Item rows visible with pre-filled values |

---

#### TC-P25: Navigate From Trash Back To Main List

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash view | Trash list loads |
| 2 | Click "Back" or navigate to `hpc/hpc-template-parts` | Main index page loads |
| 3 | Verify only active (non-deleted) records shown | No trashed records |

---

### 7.2 Negative TC Steps

#### TC-N01: Create — Missing Template ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Create loads |
| 2 | Leave template_id unselected | Empty |
| 3 | Fill other required fields | Other fields filled |
| 4 | Submit form | 422 Validation Error |
| 5 | Verify error message: "The template id field is required." | Error displayed |

---

#### TC-N02: Create — Invalid Template ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Create loads |
| 2 | Enter template_id = 99999 (non-existent) | Invalid ID |
| 3 | Fill other required fields | Fields filled |
| 4 | Submit form | 422 Validation Error |
| 5 | Verify error message: "The selected template id is invalid." | Error displayed |

---

#### TC-N03: Create — Missing Label

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Create loads |
| 2 | Select valid template_id | Template selected |
| 3 | Leave label blank | Empty |
| 4 | Fill other required fields | Other fields filled |
| 5 | Submit form | 422 Validation Error |
| 6 | Verify error message: "The label field is required." | Error displayed |

---

#### TC-N04: Create — Label Exceeds 255 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Create loads |
| 2 | Enter label with 256 characters | Exceeds limit |
| 3 | Submit form | 422 Validation Error |
| 4 | Verify error message: "The label must not exceed 255 characters." | Error displayed |

---

#### TC-N05: Create — Missing Display Order

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Create loads |
| 2 | Fill all fields except display_order | display_order blank |
| 3 | Submit form | 422 Validation Error |
| 4 | Verify error message: "The display order field is required." | Error displayed |

---

#### TC-N06: Create — Negative Display Order

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Create loads |
| 2 | Enter display_order = -1 | Negative value |
| 3 | Submit form | 422 Validation Error |
| 4 | Verify error message: "The display order must be at least 0." | Error displayed |

---

#### TC-N07: Create — Items Item Type Missing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Create loads |
| 2 | Add an item row but leave item_type blank | Missing item_type |
| 3 | Submit form | 422 Validation Error |
| 4 | Verify error message: "The item type field is required." | Error displayed |

---

#### TC-N08: Create — Items Marks Negative

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Create loads |
| 2 | Add item row with marks = -5 | Negative marks |
| 3 | Submit form | 422 Validation Error |
| 4 | Verify error message: "The marks must be at least 0." | Error displayed |

---

#### TC-N09: Edit — Non-Existent Part ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `hpc/hpc-template-parts/99999/edit` | Route loads |
| 2 | Verify 404 error page displayed | Not Found |

---

#### TC-N10: Edit — Invalid Template ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to edit for an existing part | Edit form loads |
| 2 | Change template_id to 99999 | Invalid ID |
| 3 | Submit form | 422 Validation Error |
| 4 | Verify error message: "The selected template id is invalid." | Error displayed |

---

#### TC-N11: Delete — Non-Existent Part ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send DELETE to `hpc/hpc-template-parts/99999` | Route resolves |
| 2 | Verify 404 error returned | Not Found |

---

#### TC-N12: Restore — Non-Deleted (Active) Part

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select an active (non-deleted) part | Active record |
| 2 | Attempt restore via `hpc/hpc-template-parts/{id}/restore` | Error returned |
| 3 | Verify error: cannot restore an active record | Appropriate error |

---

#### TC-N13: Force Delete — Non-Trashed (Active) Part

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select an active (non-trashed) part | Active record |
| 2 | Attempt forceDelete via `hpc/hpc-template-parts/{id}/force-delete` | Error: onlyTrashed record not found |
| 3 | Verify 404 error | Not Found |

---

#### TC-N14: Toggle — Non-Existent Part ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send POST toggle status to `hpc/hpc-template-parts/99999/toggle-status` | Route resolves |
| 2 | Verify 404 error returned | Not Found |

---

#### TC-N15: Permission Denied — Index Without `tenant.hpc.viewAny`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without `tenant.hpc.viewAny` | User lacks permission |
| 2 | Navigate to `hpc/hpc-template-parts` | 403 Forbidden |
| 3 | Verify no data is exposed | Error page shown |

---

#### TC-N16: Permission Denied — Create Without `tenant.hpc-template-parts.create`

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with `tenant.hpc.viewAny` but without `tenant.hpc-template-parts.create` | User lacks create permission |
| 2 | Navigate to `hpc/hpc-template-parts/create` | 403 Forbidden |
| 3 | POST to `hpc/hpc-template-parts` | 403 Forbidden |

---

#### TC-N17: Guest Access — Redirect To Login

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout (unauthenticated) | Guest session |
| 2 | Navigate to any hpc-template-parts route | Redirected to login page |
| 3 | Verify no CRUD data exposed | Login form shown |

---

#### TC-N18: Label Exceeds Max Length On Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to edit existing part | Edit form loads |
| 2 | Change label to >255 characters | Exceeds limit |
| 3 | Submit form | 422 Validation Error |
| 4 | Verify error message displayed | Error shown |

---

#### TC-N19: Display Order Exceeds Max Integer

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create or edit form | Form loads |
| 2 | Enter display_order as very large number (e.g., 99999999999) | Exceeds max |
| 3 | Submit form | 422 Validation Error |
| 4 | Verify integer validation error | Error shown |

---

#### TC-N20: Items Code Exceeds 50 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Create loads |
| 2 | Add item with code >50 characters | Exceeds limit |
| 3 | Submit form | 422 Validation Error |
| 4 | Verify error message: "The code must not exceed 50 characters." | Error displayed |

---

### 7.3 Dependency TC Steps

#### TC-D02: Template ID FK — Creating Part With Invalid Template

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Create loads |
| 2 | Set template_id to non-existent ID (99999) | Invalid |
| 3 | Fill other required fields | Fields filled |
| 4 | Submit form | 422 Validation Error |
| 5 | Verify error message | Error: "The selected template id is invalid." |

---

#### TC-D04: SoftDeletes Trait Applied Correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify model uses SoftDeletes trait | SoftDeletes present |
| 2 | Call `delete()` on a part record | deleted_at set to current timestamp |
| 3 | Query normal scope: record not returned | Excluded from results |
| 4 | Query withTrashed: record returned | Included in withTrashed |

---

#### TC-D05: destroy() Sets is_active=false Before Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select active part with is_active=1 | Active record |
| 2 | Navigate to index | Index loads |
| 3 | Click delete button | Confirmation |
| 4 | Confirm delete | Process executes |
| 5 | Query DB before soft delete completes | is_active = 0 |
| 6 | Query DB: deleted_at set | deleted_at non-null |

---

#### TC-D10: hasMany('items') Relationship Loads Correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create part with 3 items | Part + items exist |
| 2 | Query part with `->with('items')` | Items relation loaded |
| 3 | Access `$part->items` | Collection of 3 HpcTemplatePartsItems |
| 4 | Verify each item has correct part_id | FK references parent |

---

#### TC-D11: belongsTo('template') Relationship Loads Correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create template "Test Template" | Template exists |
| 2 | Create part assigned to that template | Part exists |
| 3 | Query part with `->with('template')` | Template relation loaded |
| 4 | Access `$part->template->title` | Returns "Test Template" |

---

#### TC-D12: Items ForceDelete + Recreate On Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create part with 2 items (IDs: 1, 2) | Part + items exist |
| 2 | Navigate to edit for this part | Edit form loads |
| 3 | Submit update with 3 new items | Form submitted |
| 4 | Query items with withTrashed: old items have deleted_at set | Old items forceDeleted |
| 5 | Query active items: 3 new items with new IDs | New items created |

---

#### TC-D16: is_active Default On Create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Create loads |
| 2 | Fill required fields | Fields filled |
| 3 | Do NOT set is_active (leave default) | Default |
| 4 | Submit form | Created |
| 5 | Query DB: is_active = 1 | Default true |

---

#### TC-D17: Timestamps Auto-Set On Create And Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create template part | created_at set |
| 2 | Record created_at timestamp | Timestamp matches creation time |
| 3 | Update a field on the part | updated_at refreshed |
| 4 | Verify updated_at > created_at | Timestamp changed |

---

#### TC-D19: Activity Log Events Fire Correct Message Format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create template part | Log: "HPC Template Part created." |
| 2 | Update template part | Log: "HPC Template Part updated." with changes |
| 3 | Delete template part | Log: "HPC Template Part deleted." |
| 4 | Restore template part | Log: "HPC Template Part restored." |
| 5 | Force delete template part | Log: "HPC Template Part permanently deleted." |
| 6 | Toggle status | Log: "HPC Template Part status toggled." |

---

## 8. CODE-TRACE: Controller Method Execution Traces

### CODE-TRACE-01: `index()` — HpcTemplatePartsController (Line 18)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplatePartsController.php:20` | `$this->authorizeHpcIndex()` — calls `Gate::authorize('tenant.hpc.viewAny')` via HpcIndexDataTrait |
| 2 | `HpcIndexDataTrait.php:28-49` | `$this->getHpcIndexData()` — loads sessions, terms, classes, sections, and paginated students |
| 3 | `HpcTemplatePartsController.php:22` | `return view('hpc::hpc.index', $data)` — renders HPC dashboard/index view |

### CODE-TRACE-02: `create()` — HpcTemplatePartsController (Line 25)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplatePartsController.php:27` | `Gate::authorize('tenant.hpc-template-parts.create')` — checks create permission |
| 2 | `HpcTemplatePartsController.php:28` | `HpcTemplates::where('is_active', 1)->get()` — loads active templates for dropdown |
| 3 | `HpcTemplatePartsController.php:29-30` | `$itemsCount = 1; return view('hpc::hpc-template-parts.create', compact('templates', 'itemsCount'))` — renders create form |

### CODE-TRACE-03: `store()` — HpcTemplatePartsController (Line 33)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplatePartsController.php:35` | `Gate::authorize('tenant.hpc-template-parts.create')` — checks create permission |
| 2 | `HpcTemplatePartsController.php:36` | `$part = HpcTemplateParts::create($request->validated())` — creates parent part record |
| 3 | `HpcTemplatePartsController.php:38-42` | If `$request->has('items')`: loop over items array, call `$part->items()->create($item)` for each child item |
| 4 | `HpcTemplatePartsController.php:44-47` | `activityLog($part, 'Created', ['message' => 'HPC Template Part created.'])` — logs creation |
| 5 | `HpcTemplatePartsController.php:49-50` | `redirect()->route('hpc.hpc.templates')->with('success', flash('created.hpc_template_part'))` — redirects to HPC master tab |

### CODE-TRACE-04: `show()` — HpcTemplatePartsController (Line 53)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplatePartsController.php:55` | `Gate::authorize('tenant.hpc-template-parts.view')` — checks view permission |
| 2 | `HpcTemplatePartsController.php:56` | `HpcTemplateParts::with('template', 'items')->findOrFail($id)` — loads part with template + items relations |
| 3 | `HpcTemplatePartsController.php:57` | `return view('hpc::hpc-template-parts.show', compact('part'))` — renders show view |

### CODE-TRACE-05: `edit()` — HpcTemplatePartsController (Line 60)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplatePartsController.php:62` | `Gate::authorize('tenant.hpc-template-parts.update')` — checks update permission |
| 2 | `HpcTemplatePartsController.php:63` | `$part = HpcTemplateParts::with('items')->findOrFail($id)` — loads existing record with items |
| 3 | `HpcTemplatePartsController.php:64` | `$templates = HpcTemplates::where('is_active', 1)->get()` — loads active templates for dropdown |
| 4 | `HpcTemplatePartsController.php:65` | `return view('hpc::hpc-template-parts.edit', compact('part', 'templates'))` — renders edit form with items |

### CODE-TRACE-06: `update()` — HpcTemplatePartsController (Line 68)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplatePartsController.php:70` | `Gate::authorize('tenant.hpc-template-parts.update')` — checks update permission |
| 2 | `HpcTemplatePartsController.php:71` | `$part = HpcTemplateParts::findOrFail($id)` — loads existing record |
| 3 | `HpcTemplatePartsController.php:72` | `$original = $part->getOriginal()` — captures pre-update state for change tracking |
| 4 | `HpcTemplatePartsController.php:74` | `$part->update($request->validated())` — updates parent record fields |
| 5 | `HpcTemplatePartsController.php:76-81` | If items present: `$part->items()->forceDelete()` removes all old items, then recreates each from `$request->items` |
| 6 | `HpcTemplatePartsController.php:83-90` | Change tracking: iterates `$part->getChanges()`, builds `$changes` array with old/new values, skips `updated_at` |
| 7 | `HpcTemplatePartsController.php:92-96` | `activityLog($part, 'Updated', ['message', 'changes' => $changes])` — logs update with attribute diff |
| 8 | `HpcTemplatePartsController.php:98-99` | `redirect()->route('hpc.hpc.templates')->with('success', flash('updated.hpc_template_part'))` |

### CODE-TRACE-07: `destroy()` — HpcTemplatePartsController (Line 102)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplatePartsController.php:104` | `Gate::authorize('tenant.hpc-template-parts.delete')` — checks delete permission |
| 2 | `HpcTemplatePartsController.php:105` | `$part = HpcTemplateParts::findOrFail($id)` — loads record |
| 3 | `HpcTemplatePartsController.php:106` | `$part->is_active = false` — deactivates record |
| 4 | `HpcTemplatePartsController.php:107` | `$part->save()` — persists is_active change |
| 5 | `HpcTemplatePartsController.php:108` | `$part->delete()` — soft deletes (sets deleted_at) |
| 6 | `HpcTemplatePartsController.php:110-113` | `activityLog($part, 'Deleted', ['message' => 'HPC Template Part deleted.'])` |
| 7 | `HpcTemplatePartsController.php:115-116` | `redirect()->route('hpc.hpc.templates')->with('success', flash('deleted.hpc_template_part'))` |

### CODE-TRACE-08: `trashed()` — HpcTemplatePartsController (Line 119)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplatePartsController.php:121` | `Gate::authorize('tenant.hpc-template-parts.restore')` — checks restore permission |
| 2 | `HpcTemplatePartsController.php:122` | `$templateParts = HpcTemplateParts::onlyTrashed()->with('template')->latest('deleted_at')->paginate(10)` — trashed records with template relation, 10 per page |
| 3 | `HpcTemplatePartsController.php:123` | `return view('hpc::hpc-template-parts.trash', compact('templateParts'))` |

### CODE-TRACE-09: `restore()` — HpcTemplatePartsController (Line 126)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplatePartsController.php:128` | `Gate::authorize('tenant.hpc-template-parts.restore')` |
| 2 | `HpcTemplatePartsController.php:129` | `$part = HpcTemplateParts::onlyTrashed()->findOrFail($id)` — finds trashed record |
| 3 | `HpcTemplatePartsController.php:130` | `$part->restore()` — clears deleted_at (sets to NULL) |
| 4 | `HpcTemplatePartsController.php:132-135` | `$part->is_active = true; $part->save(); activityLog(...)` — reactivates and logs |
| 5 | `HpcTemplatePartsController.php:137-138` | `redirect()->route('hpc.hpc.templates')->with('success', flash('restored.hpc_template_part'))` |

### CODE-TRACE-10: `forceDelete()` — HpcTemplatePartsController (Line 141)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplatePartsController.php:143` | `Gate::authorize('tenant.hpc-template-parts.forceDelete')` |
| 2 | `HpcTemplatePartsController.php:144` | `$part = HpcTemplateParts::withTrashed()->findOrFail($id)` — finds record even if trashed |
| 3 | `HpcTemplatePartsController.php:145` | `$part->forceDelete()` — permanently removes from database |
| 4 | `HpcTemplatePartsController.php:147-150` | `activityLog($part, 'Force Deleted', ['message' => 'HPC Template Part permanently deleted.'])` |
| 5 | `HpcTemplatePartsController.php:152-153` | `redirect()->route('hpc.hpc.templates')->with('success', flash('force_deleted.hpc_template_part'))` |

### CODE-TRACE-11: `toggleStatus()` — HpcTemplatePartsController (Line 156)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplatePartsController.php:158` | `Gate::authorize('tenant.hpc-template-parts.update')` |
| 2 | `HpcTemplatePartsController.php:159` | `$request->validate(['is_active' => 'required|boolean'])` |
| 3 | `HpcTemplatePartsController.php:160` | `$part = HpcTemplateParts::withTrashed()->findOrFail($id)` |
| 4 | `HpcTemplatePartsController.php:161` | `$part->is_active = (bool) $request->is_active` |
| 5 | `HpcTemplatePartsController.php:162` | `$part->save()` |
| 6 | `HpcTemplatePartsController.php:164-167` | `activityLog($part, 'Toggled', ['message' => 'HPC Template Part status toggled.'])` |
| 7 | `HpcTemplatePartsController.php:169-173` | `return response()->json(['success' => true, 'is_active' => $part->is_active, 'message' => flash('status_updated.hpc_template_part')])` |

---