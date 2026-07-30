# lms_HPC_Templates_TcList

## Module: HPC → Template Management

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | HPC |
| Tab Group | Template Management |
| Feature | Templates |
| URL(s) | `hpc/templates` (tab), `hpc/hpc-templates`, `hpc/hpc-templates/create`, `hpc/hpc-templates/{id}`, `hpc/hpc-templates/{id}/edit`, `hpc/hpc-templates/trash/view`, `hpc/hpc-templates/{id}/restore`, `hpc/hpc-templates/{id}/force-delete`, `hpc/hpc-templates/{id}/toggle-status` |
| Controller | `Modules\Hpc\Http\Controllers\HpcTemplatesController` |
| Model(s) | `Modules\Hpc\Models\HpcTemplates` |
| Validation (Create) | `Modules\Hpc\Http\Requests\HpcTemplatesRequest` |
| Validation (Update) | `Modules\Hpc\Http\Requests\HpcTemplatesRequest` |
| Permissions | `tenant.hpc.viewAny`, `tenant.hpc-templates.create`, `tenant.hpc-templates.view`, `tenant.hpc-templates.update`, `tenant.hpc-templates.delete`, `tenant.hpc-templates.restore`, `tenant.hpc-templates.forceDelete` |
| Soft Deletes | Yes |
| Activity Log | Created, Updated, Deleted, Restored, Force Deleted, Toggled |

---

## 2. Pre-conditions

- Required permissions: `tenant.hpc.viewAny` for index, plus specific `tenant.hpc-templates.*` for CRUD actions
- At least one `HpcTemplates` record exists for list/view/update/delete operations
- Test user must have the above permissions (default admin user or user assigned via role)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For applicable_to_grade multi-select testing, seed data must exist in `sch_classes` table
- Trash operations require at least one soft-deleted record
- Pagination tests require at least 16 seeded records to test page 2
- Search/filter tests require multiple records with varied code and title values
- Duplicate code+version tests require at least one existing record with a known code+version pair

---

## 3. Default Data Load

When the index page loads via `HpcTemplatesController` (GET `hpc/hpc-templates`), the following data is fetched:

| Data Loaded | Source | Query | Filters | Pagination |
|------------|--------|-------|---------|------------|
| All active templates | `HpcTemplates::query()` with `formatResponse()` | `->where('is_active', true)` or all (based on UI filter) | Search by code, title | 15 per page |
| Single template | `HpcTemplates::findOrFail($id)` | Route binding by id | None | None |
| Trash list | `HpcTemplates::onlyTrashed()->get()` | Soft-deleted records only | `withTrashed()` scope | 15 per page |
| Template count | `HpcTemplates::count()` | Full count for pagination metadata | None | None |

---

## 4. Test Data Strategy

- **List/index**: Seed 20+ `HpcTemplates` records with varied code, title, version, description, applicable_to_grade, and is_active values
- **Search**: Ensure at least 3 records share a partial code match (e.g., "TMPL-") and 3 share a partial title match
- **Create**: Use unique code+version combinations; use valid `sch_classes.id` references for applicable_to_grade
- **Edit**: Update existing record fields including code, version, title, description, applicable_to_grade, is_active
- **Soft Delete**: Select a record to delete; verify `is_active=false` before `deleted_at` set
- **Restore**: Soft-delete a record first, then restore; verify `is_active` returns to original value
- **Force Delete**: Soft-delete first, then force-delete; verify permanent removal from database
- **Toggle Status**: Toggle `is_active` from true→false and false→true; verify response structure
- **Duplicate validation**: Create code+version pair, then try creating the same pair again
- **applicable_to_grade**: Seed `sch_classes` records with IDs 1-5; assign template to classes [1,2,3] and verify JSON round-trip
- **Permissions**: Test with admin, user with specific permission, user without permission, and guest roles
- **Pre-test cleanup**: Delete created records before/after tests to avoid collisions

---

## 5. Business Conditions

### 4.1 Database Schema — `hpc_templates`

| BC ID | Table | Column | Type (DDL) | Constraints |
|-------|-------|--------|------------|-------------|
| BC-DB-01 | hpc_templates | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-02 | hpc_templates | code | VARCHAR(50) | NOT NULL |
| BC-DB-03 | hpc_templates | version | INT | NOT NULL |
| BC-DB-04 | hpc_templates | title | VARCHAR(255) | NOT NULL |
| BC-DB-05 | hpc_templates | description | VARCHAR(512) | NULLABLE |
| BC-DB-06 | hpc_templates | applicable_to_grade | JSON/TEXT | NULLABLE, stores array of class IDs |
| BC-DB-07 | hpc_templates | is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-08 | hpc_templates | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-09 | hpc_templates | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-10 | hpc_templates | deleted_at | TIMESTAMP | NULLABLE, SoftDeletes |

### 4.2 Validation Rules — `HpcTemplatesRequest` (Create)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | code | required, string, max:50 | The code field is required. / The code must not exceed 50 characters. |
| BC-VAL-02 | version | required, integer, min:1 | The version field is required. / The version must be at least 1. |
| BC-VAL-03 | title | required, string, max:255 | The title field is required. / The title must not exceed 255 characters. |
| BC-VAL-04 | description | nullable, string, max:512 | The description must not exceed 512 characters. |
| BC-VAL-05 | applicable_to_grade | nullable, array | The applicable to grade must be an array. |
| BC-VAL-06 | applicable_to_grade.* | required, integer, exists:sch_classes,id | The selected applicable to grade is invalid. |
| BC-VAL-07 | is_active | sometimes, boolean | The is active field must be true or false. |
| BC-VAL-08 | code + version (unique) | required, unique combination | "The combination of code and version already exists." |

### 4.3 Validation Rules — `HpcTemplatesRequest` (Update)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-U01 | code | required, string, max:50 | The code field is required. / The code must not exceed 50 characters. |
| BC-VAL-U02 | version | required, integer, min:1 | The version field is required. / The version must be at least 1. |
| BC-VAL-U03 | title | required, string, max:255 | The title field is required. / The title must not exceed 255 characters. |
| BC-VAL-U04 | description | nullable, string, max:512 | The description must not exceed 512 characters. |
| BC-VAL-U05 | applicable_to_grade | nullable, array | The applicable to grade must be an array. |
| BC-VAL-U06 | applicable_to_grade.* | required, integer, exists:sch_classes,id | The selected applicable to grade is invalid. |
| BC-VAL-U07 | is_active | sometimes, boolean | The is active field must be true or false. |
| BC-VAL-U08 | code + version (unique) | required, unique combination (ignores self) | "The combination of code and version already exists." |

### 4.4 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | `tenant.hpc.viewAny` | index() | Without → 403 on `hpc/hpc-templates` index |
| BC-AUTH-02 | `tenant.hpc-templates.create` | create(), store() | Without → 403 on `create` page and `store` POST |
| BC-AUTH-03 | `tenant.hpc-templates.view` | show() | Without → 403 on `show` GET |
| BC-AUTH-04 | `tenant.hpc-templates.update` | edit(), update(), toggleStatus() | Without → 403 on `edit` page and `update` PUT |
| BC-AUTH-05 | `tenant.hpc-templates.delete` | destroy() | Without → 403 on `destroy` DELETE |
| BC-AUTH-06 | `tenant.hpc-templates.restore` | trashed(), restore() | Without → 403 on `trashed`, `restore`, `forceDelete` |
| BC-AUTH-07 | `tenant.hpc-templates.forceDelete` | forceDelete() | Without → 403 on `forceDelete` DELETE |
| BC-AUTH-08 | Guest (unauthenticated) | — | Redirect to login for all routes |

### 4.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | `destroy()` called on active template | Sets `is_active = false`, then calls `delete()` (SoftDeletes) |
| BC-BIZ-02 | `toggleStatus()` called | Flips `is_active` boolean value; returns JSON success response |
| BC-BIZ-03 | `restore()` called | Restores soft-deleted record; `is_active` set back to original value |
| BC-BIZ-04 | `forceDelete()` called | Permanently removes record from database (must be trashed first) |
| BC-BIZ-05 | `applicable_to_grade` stored/retrieved | Stored as JSON in DB; accessed as array via Eloquent cast/accessor |
| BC-BIZ-06 | Activity Log on create | Event `created` fired with detail "created template {title}" |
| BC-BIZ-07 | Activity Log on update | Event `updated` fired with detail "updated template {title}" |
| BC-BIZ-08 | Activity Log on soft delete | Event `deleted` fired with detail "deleted template {title}" |
| BC-BIZ-09 | Activity Log on restore | Event `restored` fired with detail "restored template {title}" |
| BC-BIZ-10 | Activity Log on force delete | Event `forceDeleted` fired with detail "force deleted template {title}" |
| BC-BIZ-11 | Activity Log on toggle status | Event `toggled` fired with detail "toggled template {title}" |
| BC-BIZ-12 | Index page renders with `formatResponse()` | Returns paginated collection with id, code, version, title, description, applicable_to_grade, is_active, created_at, updated_at |
| BC-BIZ-13 | Trash page renders only soft-deleted | Uses `onlyTrashed()` scope; no active records shown |
| BC-BIZ-14 | Search filters by code | `where('code', 'like', '%search%')` applied |
| BC-BIZ-15 | Search filters by title | `where('title', 'like', '%search%')` applied |
| BC-BIZ-16 | Duplicate code+version on create | Custom validation rejects with 422 |
| BC-BIZ-17 | Duplicate code+version on update | Custom validation allows same record (ignores self) but rejects others |
| BC-BIZ-18 | applicable_to_grade empty array | Stored as `[]` or `null` in DB; retrieved as empty array |
| BC-BIZ-19 | is_active default on create | Defaults to `true` (1) unless explicitly set to false |

### 4.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | hpc_templates (no direct FK in this table) | — | — |
| BC-REF-02 | hpc_template_parts.template_id | hpc_templates (id) | CASCADE or RESTRICT |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Index page loads with paginated template list | `hpc/hpc-templates` renders with 15 records per page, columns displayed | — | — | ⬜ |
| TC-P02 | Pagination navigates to page 2 | Page 2 loads with next set of records; pagination controls visible | — | — | ⬜ |
| TC-P03 | Search by code filters results | Typing partial code in search field filters list to matching records | — | — | ⬜ |
| TC-P04 | Search by title filters results | Typing partial title in search field filters list to matching records | — | — | ⬜ |
| TC-P05 | Create template with all fields | All fields (code, version, title, description, applicable_to_grade, is_active) saved; redirect to index with success message | — | — | ⬜ |
| TC-P06 | Create template with minimum fields (code, version, title only) | Template created with no description, no applicable_to_grade, is_active=true by default | — | — | ⬜ |
| TC-P07 | Edit template — update all fields | Every field updated; redirect to index with success; changes persisted in DB | — | — | ⬜ |
| TC-P08 | Edit template — change code and version only | Code and version updated; other fields unchanged | — | — | ⬜ |
| TC-P09 | View single template | Show page displays all fields for the given template ID | — | — | ⬜ |
| TC-P10 | Soft delete an active template | `destroy()` sets is_active=false then soft-deletes; record appears in trash | — | — | ⬜ |
| TC-P11 | Restore template from trash | Restored record removed from trash view; reappears in main list; is_active restored | — | — | ⬜ |
| TC-P12 | Force delete template from trash | Record permanently removed; does not appear in trash or main list | — | — | ⬜ |
| TC-P13 | Toggle template from active to inactive | is_active flips to false; JSON response confirms success | — | — | ⬜ |
| TC-P14 | Toggle template from inactive to active | is_active flips to true; JSON response confirms success | — | — | ⬜ |
| TC-P15 | Verify is_active=false prevents template selection in dependent UIs | Template with is_active=false not shown in template dropdowns or selection lists | — | — | ⬜ |
| TC-P16 | Create duplicate code with different version (allowed) | Same code + different version passes unique validation; record created | — | — | ⬜ |
| TC-P17 | Create template with applicable_to_grade multi-select | Select classes [1,2,3]; stored as JSON array; retrieved correctly | — | — | ⬜ |
| TC-P18 | Index page displays correct columns | id, code, version, title, description, applicable_to_grade, is_active columns visible | — | — | ⬜ |
| TC-P19 | Create template with description filled | Description field populated; stored and displayed correctly | — | — | ⬜ |
| TC-P20 | Create template with applicable_to_grade empty | No classes selected; stored as null/empty array; no validation error | — | — | ⬜ |
| TC-P21 | Edit template — remove applicable_to_grade | Previously set classes removed; stored as null/empty array | — | — | ⬜ |
| TC-P22 | View trash list | Trash page shows only soft-deleted records with restore/force-delete actions | — | — | ⬜ |
| TC-P23 | Navigate from trash back to main list | Link returns to active templates index | — | — | ⬜ |
| TC-P24 | Verify activity log entry on template create | Activity log shows "created template {title}" with correct model reference | — | — | ⬜ |
| TC-P25 | Bulk permissions — user with all hpc-templates permissions | User can perform all CRUD, restore, forceDelete, and toggle actions | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Create — missing code field | 422 Validation Error: "The code field is required." | — | — | ⬜ |
| TC-N02 | Create — missing version field | 422 Validation Error: "The version field is required." | — | — | ⬜ |
| TC-N03 | Create — missing title field | 422 Validation Error: "The title field is required." | — | — | ⬜ |
| TC-N04 | Create — invalid version = 0 | 422 Validation Error: "The version must be at least 1." | — | — | ⬜ |
| TC-N05 | Create — code exceeds 50 characters | 422 Validation Error: "The code must not exceed 50 characters." | — | — | ⬜ |
| TC-N06 | Create — title exceeds 255 characters | 422 Validation Error: "The title must not exceed 255 characters." | — | — | ⬜ |
| TC-N07 | Create — description exceeds 512 characters | 422 Validation Error: "The description must not exceed 512 characters." | — | — | ⬜ |
| TC-N08 | Create — invalid applicable_to_grade.* (non-existent class ID) | 422 Validation Error: "The selected applicable to grade is invalid." | — | — | ⬜ |
| TC-N09 | Create — duplicate code+version combination | 422 Validation Error: unique code+version rule triggers | — | — | ⬜ |
| TC-N10 | Edit — update to duplicate code+version (conflicting with other record) | 422 Validation Error: unique code+version rule triggers for other records | — | — | ⬜ |
| TC-N11 | Edit — non-existent template ID | 404 Not Found | — | — | ⬜ |
| TC-N12 | Delete — non-existent template ID | 404 Not Found | — | — | ⬜ |
| TC-N13 | Restore — non-deleted (active) template | Error: cannot restore a record that is not soft-deleted | — | — | ⬜ |
| TC-N14 | Force delete — non-trashed (active) template | Error: cannot force-delete a record that is not soft-deleted first | — | — | ⬜ |
| TC-N15 | Toggle — non-existent template ID | 404 Not Found | — | — | ⬜ |
| TC-N16 | Permission denied — index page without tenant.hpc.viewAny | 403 Forbidden | — | — | ⬜ |
| TC-N17 | Permission denied — create without tenant.hpc-templates.create | 403 Forbidden on create page and store action | — | — | ⬜ |
| TC-N18 | Guest access — redirect to login | Unauthenticated user redirected to login page for all routes | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Unique code+version validation — create duplicate | Custom validation rule rejects duplicate code+version combo with 422 | — | — | ⬜ |
| TC-D02 | A | Unique code+version validation — update self (allowed) | Updating own record with same code+version passes validation | — | — | ⬜ |
| TC-D03 | B | SoftDeletes trait applied correctly | Calling `delete()` sets `deleted_at` timestamp; record excluded from normal queries | — | — | ⬜ |
| TC-D04 | B | destroy() sets is_active=false before delete | Before soft-delete, `is_active` set to 0; after restore, `is_active` returns to original | — | — | ⬜ |
| TC-D05 | B | restore() brings back record | `restore()` clears `deleted_at`; record reappears in normal queries | — | — | ⬜ |
| TC-D06 | B | forceDelete() removes permanently | Record removed from DB; `withTrashed()` does not find it either | — | — | ⬜ |
| TC-D07 | B | withTrashed() scope on trash view | Trash page uses `onlyTrashed()`; shows only soft-deleted records | — | — | ⬜ |
| TC-D08 | B | toggleStatus() response structure | Returns JSON with `success: true` and updated `is_active` value | — | — | ⬜ |
| TC-D09 | C | applicable_to_grade JSON cast round-trip | Array stored as JSON in DB; retrieved as array via accessor | — | — | ⬜ |
| TC-D10 | C | hasMany relationship loads correctly | Template has many template_parts; relationship eager-loadable | — | — | ⬜ |
| TC-D11 | C | formatResponse() returns correct structure | Index response includes id, code, version, title, description, applicable_to_grade, is_active, created_at, updated_at | — | — | ⬜ |
| TC-D12 | D | FormRequest authorize() gate check | Create/Update FormRequest has `authorize()` that checks permission gate | — | — | ⬜ |
| TC-D13 | D | HPCTemplateSeeder seeds valid data | Seed data includes minimum 5 templates with varied attributes | — | — | ⬜ |
| TC-D14 | D | Index pagination default page size (15 per page) | With 20 records, page 1 shows 15, page 2 shows 5 | — | — | ⬜ |
| TC-D15 | D | Index sort order | Records sorted by `created_at` DESC or appropriate default sort | — | — | ⬜ |
| TC-D16 | E | Code max:50 validation on update | Updating code with >50 chars returns 422 | — | — | ⬜ |
| TC-D17 | E | Version min:1 validation on update | Updating version to 0 returns 422 | — | — | ⬜ |
| TC-D18 | E | Description nullable on update | Sending null description clears the field; storing as NULL in DB | — | — | ⬜ |
| TC-D19 | E | is_active default value on create | Creating without is_active defaults to true | — | — | ⬜ |
| TC-D20 | E | Timestamps auto-set on create and update | `created_at` set on insert; `updated_at` refreshed on update | — | — | ⬜ |
| TC-D21 | E | deleted_at nullable after restore | After restore, `deleted_at` is NULL; record acts as active | — | — | ⬜ |
| TC-D22 | F | ActivityLog events fire correct message format | "created template {title}", "updated template {title}", "deleted template {title}", "restored template {title}", "force deleted template {title}", "toggled template {title}" | — | — | ⬜ |
| TC-D23 | F | Route model binding resolves correctly | Routes bind `{id}` to `HpcTemplates` model; invalid ID returns 404 | — | — | ⬜ |
| TC-D24 | F | Route permission middleware applied to all routes | Each route group has `can:` or `Auth` middleware protecting it | — | — | ⬜ |
| TC-D25 | F | Activity log records association via polymorphic relationship | Activity log entries have correct `subject_type` and `subject_id` referencing HpcTemplates | — | — | ⬜ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Blade @can Directives — Permission-based visibility for all action buttons | View includes @can('tenant.hpc-templates.create'), @can('tenant.hpc-templates.update'), @can('tenant.hpc-templates.delete'), @canany(['tenant.hpc-templates.restore', 'tenant.hpc-templates.forceDelete']) for access control on all CRUD buttons and actions | — | — | ◌ |
| TC-CR02 | CR | P1 | Breadcrumb Config — Route registered in config/breadcrumb.php | Breadcrumb configuration for HPC templates module defined in breadcrumb config; breadcrumb visible and links correctly | — | — | ◌ |
| TC-CR03 | CR | P1 | Controller — DB Transactions in store/update | store() and update() use DB::transaction() or DB::beginTransaction+commit/rollback with try-catch | — | — | ◌ |
| TC-CR04 | CR | P1 | Controller — JSON Success Response After Create/Update/Delete | All CRUD actions return response()->json() with success: true/false and message; client-side JS handles display of success/error feedback to user | — | — | ◌ |

---

## 7. Detailed Test Steps

### 7.1 Positive TC Steps

#### TC-P01: Index Page Loads With Paginated Template List

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard page loads successfully |
| 2 | Navigate to `hpc/hpc-templates` | Index page renders without errors |
| 3 | Verify page heading shows "Templates" or equivalent | Correct heading displayed |
| 4 | Check that records are displayed in a table/list | Records visible |
| 5 | Count visible rows | Shows 15 records (pagination limit) |
| 6 | Verify pagination controls at bottom of page | Pagination bar visible |
| 7 | Check columns: id, code, version, title, description, applicable_to_grade, is_active | All columns present |

---

#### TC-P02: Pagination Navigates To Page 2

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed at least 16 HpcTemplates records | 16+ records exist |
| 2 | Navigate to `hpc/hpc-templates` | Page 1 shows 15 records |
| 3 | Click page 2 link in pagination control | Page 2 loads |
| 4 | Verify page 2 shows remaining records | 1+ record(s) displayed |
| 5 | Verify page 2 URL contains `?page=2` | Query parameter present |
| 6 | Navigate back to page 1 | First 15 records shown again |

---

#### TC-P03: Search By Code Filters Results

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed templates with codes: "TMPL-001", "TMPL-002", "OTHER-001" | Varied codes |
| 2 | Navigate to `hpc/hpc-templates` | Index loads |
| 3 | Enter "TMPL" in search field | Filter triggers |
| 4 | Verify only records with "TMPL" in code are shown | 2 results (TMPL-001, TMPL-002) |
| 5 | Clear search and enter "OTHER" | Shows 1 result (OTHER-001) |
| 6 | Clear search and verify all records return | Full list restored |

---

#### TC-P04: Search By Title Filters Results

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed templates with titles: "Math Template", "Science Template", "Art Form" | Varied titles |
| 2 | Navigate to `hpc/hpc-templates` | Index loads |
| 3 | Enter "Template" in search field | Filter triggers |
| 4 | Verify only records with "Template" in title are shown | 2 results |
| 5 | Enter "Art" in search field | Shows 1 result |
| 6 | Clear search and verify all records return | Full list restored |

---

#### TC-P05: Create Template With All Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `hpc/hpc-templates/create` | Create form loads |
| 2 | Enter code: "TMPL-FULL-001" | Code field populated |
| 3 | Enter version: 2 | Version field populated |
| 4 | Enter title: "Full Template Test" | Title field populated |
| 5 | Enter description: "This is a complete test template with all fields filled in" | Description populated |
| 6 | Select applicable_to_grade: classes [1, 2, 3] | Classes selected |
| 7 | Set is_active: true | Active checked |
| 8 | Click Submit/Save | Form submitted |
| 9 | Verify redirect to `hpc/hpc-templates` | Redirected |
| 10 | Verify success message "Template created successfully" | Flash message visible |
| 11 | Query DB for new record | Record exists with all provided values |

---

#### TC-P06: Create Template With Minimum Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `hpc/hpc-templates/create` | Create form loads |
| 2 | Enter code: "TMPL-MIN-001" | Code field populated |
| 3 | Enter version: 1 | Version field populated |
| 4 | Enter title: "Minimal Template" | Title field populated |
| 5 | Leave description blank | Empty |
| 6 | Leave applicable_to_grade unselected | No classes selected |
| 7 | Leave is_active at default | Default checked |
| 8 | Click Submit/Save | Form submitted |
| 9 | Verify success message | Flash message visible |
| 10 | Query DB: description is null, applicable_to_grade is null/[], is_active is true | Values correct |

---

#### TC-P07: Edit Template — Update All Fields

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create initial template with known values | Base record exists |
| 2 | Navigate to `hpc/hpc-templates/{id}/edit` | Edit form loads with pre-filled data |
| 3 | Change code to "TMPL-UPDATED" | Code updated |
| 4 | Change version to 3 | Version updated |
| 5 | Change title to "Updated Template Title" | Title updated |
| 6 | Change description to "Updated description text" | Description updated |
| 7 | Change applicable_to_grade to [4, 5] | Classes updated |
| 8 | Toggle is_active to false | Active unchecked |
| 9 | Click Update/Save | Form submitted |
| 10 | Verify redirect and success message | Redirected to index |
| 11 | Query DB: all fields match updated values | Persisted correctly |

---

#### TC-P08: Edit Template — Change Code And Version Only

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create initial template with title "Original Title", description "Desc" | Base record |
| 2 | Navigate to edit for this template | Edit form loads |
| 3 | Change code from original to "CODE-CHANGED" | Code updated |
| 4 | Change version from original to 5 | Version updated |
| 5 | Leave title, description, applicable_to_grade, is_active unchanged | No changes |
| 6 | Click Update/Save | Form submitted |
| 7 | Query DB: title still "Original Title", description still "Desc" | Unchanged fields preserved |
| 8 | Verify code and version are new values | Changed fields updated |

---

#### TC-P09: View Single Template

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a template with known data | Record exists |
| 2 | Navigate to `hpc/hpc-templates/{id}` | Show page loads |
| 3 | Verify code displayed matches created record | Correct code |
| 4 | Verify version displayed matches created record | Correct version |
| 5 | Verify title displayed matches created record | Correct title |
| 6 | Verify description displayed matches created record | Correct description |
| 7 | Verify applicable_to_grade displayed | Classes shown correctly |
| 8 | Verify is_active status indicator | Active/Inactive shown |

---

#### TC-P10: Soft Delete An Active Template

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create an active template with is_active=true | Record exists, active |
| 2 | Navigate to `hpc/hpc-templates` | Index shows the template |
| 3 | Click delete/trash action for the template | Confirmation prompt |
| 4 | Confirm deletion | Record soft-deleted |
| 5 | Verify record no longer appears in main index | Removed from active list |
| 6 | Navigate to `hpc/hpc-templates/trash/view` | Record appears in trash |
| 7 | Query DB: is_active=0, deleted_at is not null | Correct DB state |
| 8 | Verify activity log entry: "deleted template {title}" | Log entry created |

---

#### TC-P11: Restore Template From Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure a template is soft-deleted (in trash) | Record trashed |
| 2 | Navigate to `hpc/hpc-templates/trash/view` | Trash page shows record |
| 3 | Click Restore action for the record | Restore triggered |
| 4 | Verify success message "Template restored successfully" | Flash message visible |
| 5 | Navigate to `hpc/hpc-templates` | Record reappears in active list |
| 6 | Navigate to `hpc/hpc-templates/trash/view` | Record no longer in trash |
| 7 | Query DB: deleted_at is null, is_active restored | Correct DB state |
| 8 | Verify activity log entry: "restored template {title}" | Log entry created |

---

#### TC-P12: Force Delete Template From Trash

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure a template is soft-deleted (in trash) | Record trashed |
| 2 | Navigate to `hpc/hpc-templates/trash/view` | Trash page shows record |
| 3 | Click Force Delete action for the record | Confirmation prompt |
| 4 | Confirm permanent deletion | Record force-deleted |
| 5 | Verify record removed from trash | Trash list no longer shows record |
| 6 | Verify record does not appear in main index | Not in active list |
| 7 | Query DB with `withTrashed()`: record does not exist | Permanently removed |
| 8 | Verify activity log entry: "force deleted template {title}" | Log entry created |

---

#### TC-P13: Toggle Template From Active To Inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create an active template (is_active=true) | Record active |
| 2 | Navigate to `hpc/hpc-templates` | Index shows template as Active |
| 3 | Click toggle-status action/button for the template | AJAX request sent |
| 4 | Verify JSON response: `{success: true, is_active: false}` | Correct response |
| 5 | Verify UI updates to show Inactive badge | Visual state changed |
| 6 | Query DB: is_active = 0 | DB updated |
| 7 | Verify activity log entry: "toggled template {title}" | Log entry created |

---

#### TC-P14: Toggle Template From Inactive To Active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create an inactive template (is_active=false) | Record inactive |
| 2 | Navigate to `hpc/hpc-templates` | Index shows template as Inactive |
| 3 | Click toggle-status action/button for the template | AJAX request sent |
| 4 | Verify JSON response: `{success: true, is_active: true}` | Correct response |
| 5 | Verify UI updates to show Active badge | Visual state changed |
| 6 | Query DB: is_active = 1 | DB updated |

---

#### TC-P15: Verify is_active=false Prevents Selection In Dependent UIs

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create two templates: T-A (is_active=true), T-B (is_active=false) | Active + inactive |
| 2 | Navigate to a dependent UI that selects templates (e.g., create report page) | Template selector loads |
| 3 | Open template dropdown/selector | Only T-A appears; T-B is absent |
| 4 | Verify T-B cannot be selected | Inactive templates hidden |

---

#### TC-P16: Create Duplicate Code With Different Version (Allowed)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create template with code="DUO", version=1 | First record exists |
| 2 | Navigate to create form | Create page loads |
| 3 | Enter code="DUO", version=2, title="Second Version" | Same code, different version |
| 4 | Click Submit | Record created successfully |
| 5 | Verify success message | Created |
| 6 | Query DB: two records with code="DUO", versions 1 and 2 | Both exist |

---

#### TC-P17: Create Template With applicable_to_grade Multi-Select

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure sch_classes has records with IDs 1, 2, 3, 4, 5 | Classes exist |
| 2 | Navigate to create form | Create page loads |
| 3 | Enter code, version, title | Required fields filled |
| 4 | Select applicable_to_grade: classes 1, 3, 5 | Multi-select |
| 5 | Submit form | Created |
| 6 | Query DB: applicable_to_grade = "[1,3,5]" | JSON stored |
| 7 | View show page: classes 1, 3, 5 displayed | Retrieved as array |

---

#### TC-P18: Index Page Displays Correct Columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `hpc/hpc-templates` | Index loads |
| 2 | Check table header for column: ID | Visible |
| 3 | Check table header for column: Code | Visible |
| 4 | Check table header for column: Version | Visible |
| 5 | Check table header for column: Title | Visible |
| 6 | Check table header for column: Description | Visible |
| 7 | Check table header for column: Applicable To Grade | Visible |
| 8 | Check table header for column: Status/Active | Visible |
| 9 | Verify each row shows data in all columns | Data populated |

---

#### TC-P19: Create Template With Description Filled

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loads |
| 2 | Fill code, version, title | Required fields |
| 3 | Enter description: "A detailed description spanning multiple words to test the description field storage and display functionality" | Description filled |
| 4 | Submit | Created |
| 5 | View show page: description visible | Displayed correctly |
| 6 | Query DB: description = entered text | Stored correctly |

---

#### TC-P20: Create Template With applicable_to_grade Empty

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loads |
| 2 | Fill code, version, title | Required fields |
| 3 | Leave applicable_to_grade unselected (deselect all) | Empty |
| 4 | Submit | Created |
| 5 | Query DB: applicable_to_grade is null or [] | Stored as empty |
| 6 | View show page: shows "None" or empty state | Graceful display |

---

#### TC-P21: Edit Template — Remove applicable_to_grade

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create template with applicable_to_grade = [1, 2, 3] | Has classes |
| 2 | Navigate to edit form | Edit page loads |
| 3 | Deselect all classes in applicable_to_grade | Cleared |
| 4 | Submit update | Updated |
| 5 | Query DB: applicable_to_grade is null or [] | Cleared |
| 6 | View show page: no classes shown | Display correct |

---

#### TC-P22: View Trash List

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete 3 templates | Trash has records |
| 2 | Navigate to `hpc/hpc-templates/trash/view` | Trash page loads |
| 3 | Verify only soft-deleted records shown | No active records |
| 4 | Verify each trashed record has Restore action | Restore button visible |
| 5 | Verify each trashed record has Force Delete action | Force Delete button visible |
| 6 | Verify columns match index (plus deleted_at) | Information complete |

---

#### TC-P23: Navigate From Trash Back To Main List

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to trash page `hpc/hpc-templates/trash/view` | Trash loads |
| 2 | Click "Back to Templates" or "Active Templates" link | Redirects to `hpc/hpc-templates` |
| 3 | Verify active index loads with all records | Active list displayed |
| 4 | Verify trash link is still accessible | Navigation intact |

---

#### TC-P24: Verify Activity Log Entry On Template Create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to activity log page | Log viewer loads |
| 2 | Note the last log entry timestamp | Baseline |
| 3 | Create a new template with title "Activity Test Template" | Template created |
| 4 | Navigate to activity log page | Log viewer loads |
| 5 | Find the latest entry for HpcTemplates | Entry exists |
| 6 | Verify description: "created template Activity Test Template" | Correct message |
| 7 | Verify subject_type: HpcTemplates model class | Correct model reference |
| 8 | Verify subject_id matches created template ID | Correct ID |

---

#### TC-P25: User With All Permissions Can Perform All Actions

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with all hpc-templates permissions | Authenticated |
| 2 | Navigate to index | 200 OK |
| 3 | Navigate to create | 200 OK |
| 4 | Submit valid create data | 201/302 Created |
| 5 | Navigate to show | 200 OK |
| 6 | Navigate to edit | 200 OK |
| 7 | Submit valid update | 302 Updated |
| 8 | Soft-delete the template | Deleted |
| 9 | View trash | 200 OK |
| 10 | Restore from trash | Restored |
| 11 | Soft-delete again, then force-delete | Force deleted |
| 12 | Create new template and toggle status | Toggled |

---

### 7.2 Negative TC Steps

#### TC-N01: Create — Missing Code Field

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `hpc/hpc-templates/create` | Create form loads |
| 2 | Leave code field empty | Blank |
| 3 | Fill version: 1, title: "Test" | Other fields filled |
| 4 | Click Submit | Form submitted |
| 5 | Verify 422 Validation Error returned | Error response |
| 6 | Verify error message: "The code field is required." | Correct message |
| 7 | Verify no record created in DB | No new record |

---

#### TC-N02: Create — Missing Version Field

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loads |
| 2 | Fill code: "TEST-N02", title: "Test" | Fields filled |
| 3 | Leave version field empty | Blank |
| 4 | Click Submit | Form submitted |
| 5 | Verify 422 Validation Error | Error response |
| 6 | Verify error message: "The version field is required." | Correct message |
| 7 | Verify no record created | No new record |

---

#### TC-N03: Create — Missing Title Field

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loads |
| 2 | Fill code: "TEST-N03", version: 1 | Fields filled |
| 3 | Leave title field empty | Blank |
| 4 | Click Submit | Form submitted |
| 5 | Verify 422 Validation Error | Error response |
| 6 | Verify error message: "The title field is required." | Correct message |
| 7 | Verify no record created | No new record |

---

#### TC-N04: Create — Invalid Version = 0

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loads |
| 2 | Fill code: "TEST-N04", title: "Test" | Fields filled |
| 3 | Enter version: 0 | Invalid value |
| 4 | Click Submit | Form submitted |
| 5 | Verify 422 Validation Error | Error response |
| 6 | Verify error message: "The version must be at least 1." | Correct message |

---

#### TC-N05: Create — Code Exceeds 50 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loads |
| 2 | Enter code with 51 characters: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1" | Exceeds max |
| 3 | Fill version: 1, title: "Test" | Other fields filled |
| 4 | Click Submit | Form submitted |
| 5 | Verify 422 Validation Error | Error response |
| 6 | Verify error message: "The code must not exceed 50 characters." | Correct message |

---

#### TC-N06: Create — Title Exceeds 255 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loads |
| 2 | Fill code: "TEST-N06", version: 1 | Required fields |
| 3 | Enter title with 256+ characters | Exceeds max |
| 4 | Click Submit | Form submitted |
| 5 | Verify 422 Validation Error | Error response |
| 6 | Verify error message: "The title must not exceed 255 characters." | Correct message |

---

#### TC-N07: Create — Description Exceeds 512 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loads |
| 2 | Fill code: "TEST-N07", version: 1, title: "Test" | Required fields |
| 3 | Enter description with 513+ characters | Exceeds max |
| 4 | Click Submit | Form submitted |
| 5 | Verify 422 Validation Error | Error response |
| 6 | Verify error message: "The description must not exceed 512 characters." | Correct message |

---

#### TC-N08: Create — Invalid applicable_to_grade.* (Non-Existent Class)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loads |
| 2 | Fill code: "TEST-N08", version: 1, title: "Test" | Required fields |
| 3 | Select applicable_to_grade with class ID 99999 (non-existent) | Invalid class |
| 4 | Click Submit | Form submitted |
| 5 | Verify 422 Validation Error | Error response |
| 6 | Verify error message: "The selected applicable to grade is invalid." | Correct message |

---

#### TC-N09: Create — Duplicate Code+Version Combination

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create template with code="DUP", version=1, title="Original" | First record exists |
| 2 | Navigate to create form | Form loads |
| 3 | Enter code="DUP", version=1, title="Duplicate" | Same code+version |
| 4 | Click Submit | Form submitted |
| 5 | Verify 422 Validation Error | Error response |
| 6 | Verify error message about unique code+version combination | Correct message |
| 7 | Verify no duplicate record created | Only original exists |

---

#### TC-N10: Edit — Update To Duplicate Code+Version (Conflicting Record)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Template A with code="TA", version=1 | Record A |
| 2 | Create Template B with code="TB", version=1 | Record B |
| 3 | Navigate to edit Template B | Edit form for B |
| 4 | Change Template B's code to "TA" and version=1 | Conflicts with A |
| 5 | Click Update | Form submitted |
| 6 | Verify 422 Validation Error | Error response |
| 7 | Verify error message about unique code+version | Correct message |
| 8 | Verify Template B unchanged in DB | Original TB values preserved |

---

#### TC-N11: Edit — Non-Existent Template ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to `hpc/hpc-templates/99999/edit` | Non-existent ID |
| 3 | Verify 404 Not Found page | Error page displayed |
| 4 | Verify no application stack trace shown | Clean error page |

---

#### TC-N12: Delete — Non-Existent Template ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Send DELETE to `hpc/hpc-templates/99999` | Non-existent ID |
| 3 | Verify 404 Not Found response | Error response |
| 4 | Verify no record accidentally deleted | DB unchanged |

---

#### TC-N13: Restore — Non-Deleted (Active) Template

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create an active template (not soft-deleted) | Active record |
| 2 | Send restore request to `hpc/hpc-templates/{id}/restore` | Restore triggered |
| 3 | Verify error: record is not soft-deleted | Error response or 400 |
| 4 | Verify record still active and unchanged | DB unchanged |

---

#### TC-N14: Force Delete — Non-Trashed (Active) Template

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create an active template (not soft-deleted) | Active record |
| 2 | Send force-delete to `hpc/hpc-templates/{id}/force-delete` | Force delete triggered |
| 3 | Verify error: record must be soft-deleted first | Error response or 400 |
| 4 | Verify record still exists in DB | Not deleted |

---

#### TC-N15: Toggle — Non-Existent Template ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Send toggle-status to `hpc/hpc-templates/99999/toggle-status` | Non-existent ID |
| 3 | Verify 404 Not Found response | Error response |
| 4 | Verify no toggle occurred on any record | DB unchanged |

---

#### TC-N16: Permission Denied — Index Without tenant.hpc.viewAny

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.hpc.viewAny` permission | Authenticated |
| 2 | Navigate to `hpc/hpc-templates` | 403 Forbidden |
| 3 | Verify user cannot see any template data | Access denied |
| 4 | Verify no template data leaked in response | Clean denial |

---

#### TC-N17: Permission Denied — Create Without tenant.hpc-templates.create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user WITHOUT `tenant.hpc-templates.create` permission | Authenticated |
| 2 | Navigate to `hpc/hpc-templates/create` | 403 Forbidden on GET |
| 3 | Attempt POST to `hpc/hpc-templates` with valid data | 403 Forbidden on POST |
| 4 | Verify no record created in DB | No new record |

---

#### TC-N18: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout completely | Not authenticated |
| 2 | Navigate to `hpc/hpc-templates` | Redirected to login page |
| 3 | Navigate to `hpc/hpc-templates/create` | Redirected to login page |
| 4 | Navigate to `hpc/hpc-templates/{id}` | Redirected to login page |
| 5 | Navigate to `hpc/hpc-templates/{id}/edit` | Redirected to login page |
| 6 | Navigate to `hpc/hpc-templates/trash/view` | Redirected to login page |

---

### 7.3 Dependency TC Steps

#### TC-D01: Unique Code+Version Validation — Create Duplicate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create template with code="UNIQUE", version=1 | Record exists |
| 2 | Attempt creating same code="UNIQUE", version=1 | Duplicate |
| 3 | Verify 422 response with custom validation error | Rejected |
| 4 | Check application debug/log for validation rule evaluation | Custom rule fired |

---

#### TC-D02: Unique Code+Version Validation — Update Self (Allowed)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create template with code="SELF", version=1 | Record A |
| 2 | Navigate to edit for Record A | Edit form |
| 3 | Keep code="SELF", version=1 unchanged | Same values |
| 4 | Change title to "Updated" | Other field changed |
| 5 | Submit update | 200/302 Success |
| 6 | Verify Record A updated with new title but same code+version | Allowed |

---

#### TC-D03: SoftDeletes Trait Applied Correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect HpcTemplates model class | SoftDeletes trait imported |
| 2 | Verify `$dates` or `$casts` includes `deleted_at` | Property exists |
| 3 | Soft-delete a template | deleted_at set |
| 4 | Query `HpcTemplates::all()` — record excluded | Not in results |
| 5 | Query `HpcTemplates::withTrashed()->get()` — record included | In results |
| 6 | Query `HpcTemplates::onlyTrashed()->get()` — only trashed | In results |

---

#### TC-D04: destroy() Sets is_active=false Before Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create template with is_active=true | Active record |
| 2 | Call destroy() via controller | Delete triggered |
| 3 | Before final delete, verify is_active set to 0 | is_active=false |
| 4 | Verify deleted_at is set | Soft-deleted |
| 5 | Restore the record | Restored |
| 6 | Verify is_active returns to true | Original value restored |

---

#### TC-D05: restore() Brings Back Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a template | Record trashed |
| 2 | Query `HpcTemplates::onlyTrashed()` — record found | In trash |
| 3 | Call restore() | Restore triggered |
| 4 | Query `HpcTemplates::onlyTrashed()` — record not found | Out of trash |
| 5 | Query `HpcTemplates::find()` — record found | Active again |
| 6 | Verify deleted_at is NULL | Fully restored |

---

#### TC-D06: forceDelete() Removes Permanently

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a template | Record trashed |
| 2 | Call forceDelete() | Permanent delete |
| 3 | Query `HpcTemplates::withTrashed()->find()` — null | Record gone |
| 4 | Query raw DB: record row deleted | No row exists |
| 5 | Verify no way to retrieve the record | Irrecoverable |

---

#### TC-D07: withTrashed() Scope On Trash View

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure at least 2 templates exist: 1 active, 1 soft-deleted | Mixed state |
| 2 | Navigate to `hpc/hpc-templates` | Only active shown |
| 3 | Navigate to `hpc/hpc-templates/trash/view` | Only soft-deleted shown |
| 4 | Verify active record not in trash view | Filtered correctly |
| 5 | Verify soft-deleted record not in main index | Filtered correctly |

---

#### TC-D08: toggleStatus() Response Structure

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a template with is_active=true | Active record |
| 2 | Send toggle-status request | AJAX/API call |
| 3 | Capture JSON response | Parse response |
| 4 | Verify response has `success` key = true | Key exists |
| 5 | Verify response has `is_active` key = false | Key exists |
| 6 | Toggle again: response `is_active` = true | Cycles correctly |

---

#### TC-D09: applicable_to_grade JSON Cast Round-Trip

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create template with applicable_to_grade = [2, 4, 6] | Array input |
| 2 | Query raw DB value: stored as JSON string "[2,4,6]" | JSON stored |
| 3 | Retrieve via Eloquent model: returned as array [2,4,6] | Array cast |
| 4 | Update to [1, 3, 5] | New values |
| 5 | Verify raw DB value updated | JSON updated |
| 6 | Set to [] — stored as "[]" or null | Empty handled |

---

#### TC-D10: hasMany Relationship Loads Correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Template with 3 related HpcTemplateParts records | Template + parts |
| 2 | Load template via `HpcTemplates::with('parts')->find($id)` | Eager loaded |
| 3 | Verify `$template->parts` returns collection of 3 | Correct count |
| 4 | Verify each part has correct `template_id` FK | FK matches |
| 5 | Verify relationship defined in model: `return $this->hasMany(HpcTemplateParts::class)` | Method exists |

---

#### TC-D11: formatResponse() Returns Correct Structure

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `hpc/hpc-templates` | Index loads |
| 2 | Inspect JSON response (or rendered data) | Response parsed |
| 3 | Verify `id` key present | Included |
| 4 | Verify `code` key present | Included |
| 5 | Verify `version` key present | Included |
| 6 | Verify `title` key present | Included |
| 7 | Verify `description` key present | Included |
| 8 | Verify `applicable_to_grade` key present | Included |
| 9 | Verify `is_active` key present | Included |
| 10 | Verify `created_at` and `updated_at` present | Included |

---

#### TC-D12: FormRequest authorize() Gate Check

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect `HpcTemplatesRequest` class | File exists |
| 2 | Check `authorize()` method exists | Method defined |
| 3 | Verify `authorize()` calls gate for `tenant.hpc-templates.create` or `update` | Gate check present |
| 4 | Verify user without permission gets 403 from FormRequest | Authorization enforced |
| 5 | Verify user with permission passes FormRequest | Authorization allows |

---

#### TC-D13: HPCTemplateSeeder Seeds Valid Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Locate `HPCTemplateSeeder` class | File exists |
| 2 | Run the seeder via `db:seed` | Seed executes |
| 3 | Verify minimum 5 templates created | Sufficient seed data |
| 4 | Verify each seed record has valid code, version, title | All required fields |
| 5 | Verify varied is_active values among seed records | Mixed active/inactive |

---

#### TC-D14: Index Pagination Default Page Size

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed exactly 20 template records | 20 records |
| 2 | Navigate to `hpc/hpc-templates?page=1` | Page 1 loads |
| 3 | Count displayed records: 15 | 15 shown |
| 4 | Navigate to `hpc/hpc-templates?page=2` | Page 2 loads |
| 5 | Count displayed records: 5 | Remaining shown |
| 6 | Verify total count shown in pagination: 20 | Correct total |

---

#### TC-D15: Index Sort Order

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed templates with varying created_at dates | Timestamps vary |
| 2 | Navigate to index | List loads |
| 3 | Note order of records | Most recent first (DESC) |
| 4 | Verify first record is newest created_at | Sort correct |
| 5 | Verify last record on page is oldest created_at | Sort correct |

---

#### TC-D16: Code Max:50 Validation On Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create template with valid code | Record exists |
| 2 | Navigate to edit form | Edit loads |
| 3 | Change code to 51-character string | Exceeds max |
| 4 | Submit update | 422 error |
| 5 | Verify DB: code unchanged from original | Preserved |

---

#### TC-D17: Version Min:1 Validation On Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create template with version=2 | Record exists |
| 2 | Navigate to edit form | Edit loads |
| 3 | Change version to 0 | Invalid |
| 4 | Submit update | 422 error |
| 5 | Verify DB: version still 2 | Preserved |

---

#### TC-D18: Description Nullable On Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create template with description="Some description" | Has description |
| 2 | Navigate to edit form | Edit loads |
| 3 | Clear description field (set to null/empty) | Cleared |
| 4 | Submit update | Updated |
| 5 | Query DB: description is NULL | Stored as null |
| 6 | View show page: description shows empty state | Graceful display |

---

#### TC-D19: is_active Default Value On Create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to create form | Form loads |
| 2 | Fill code, version, title only | No is_active specified |
| 3 | Submit | Created |
| 4 | Query DB: is_active = 1 (true) | Default applied |
| 5 | Check is_active checkbox in form: pre-checked | UI shows default |

---

#### TC-D20: Timestamps Auto-Set On Create And Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a new template | Record created |
| 2 | Note `created_at` timestamp | Set to current time |
| 3 | Wait 1 minute and update title field | Record updated |
| 4 | Verify `updated_at` changed to new timestamp | Updated |
| 5 | Verify `created_at` still shows original time | Unchanged |

---

#### TC-D21: deleted_at Nullable After Restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a template | deleted_at set |
| 2 | Restore the template | Restored |
| 3 | Query DB: deleted_at is NULL | Null |
| 4 | Verify `HpcTemplates::find($id)` returns record | Active query works |
| 5 | Verify `HpcTemplates::onlyTrashed()->find($id)` returns null | Not in trash |

---

#### TC-D22: ActivityLog Events Fire Correct Message Format

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create template titled "Log Test" | Created |
| 2 | Check activity log: "created template Log Test" | Correct message |
| 3 | Update template title to "Log Test Updated" | Updated |
| 4 | Check activity log: "updated template Log Test Updated" | Correct message |
| 5 | Soft-delete: "deleted template Log Test Updated" | Correct message |
| 6 | Restore: "restored template Log Test Updated" | Correct message |
| 7 | Soft-delete again, force-delete: "force deleted template Log Test Updated" | Correct message |
| 8 | Create new template, toggle: "toggled template {title}" | Correct message |

---

#### TC-D23: Route Model Binding Resolves Correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create template with known ID | Record exists |
| 2 | Navigate to `hpc/hpc-templates/{valid_id}` | Show loads |
| 3 | Navigate to `hpc/hpc-templates/{valid_id}/edit` | Edit loads |
| 4 | Navigate to `hpc/hpc-templates/99999` | 404 Not Found |
| 5 | Check route definition: `Route::resource('hpc-templates', ...)` | Resource or explicit routes |

---

#### TC-D24: Route Permission Middleware Applied To All Routes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect route definitions for hpc-templates | Routes defined |
| 2 | Verify middleware `can:tenant.hpc.viewAny` on index | Applied |
| 3 | Verify middleware `can:tenant.hpc-templates.create` on create/store | Applied |
| 4 | Verify middleware `can:tenant.hpc-templates.update` on edit/update | Applied |
| 5 | Verify middleware `can:tenant.hpc-templates.delete` on destroy | Applied |
| 6 | Verify middleware `can:tenant.hpc-templates.restore` on trash/restore | Applied |
| 7 | Verify middleware `can:tenant.hpc-templates.forceDelete` on force-delete | Applied |
| 8 | Verify `auth` middleware on all routes | Authenticated required |

---

#### TC-D25: Activity Log Association Via Polymorphic Relationship

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a template | Record + log entry created |
| 2 | Find the activity log entry for this action | Log found |
| 3 | Verify `subject_type` = `Modules\Hpc\Models\HpcTemplates` | Correct model class |
| 4 | Verify `subject_id` = created template's ID | Correct ID |
| 5 | Query `HpcTemplates::find($id)->activities()` (if morphMany exists) | Relationship works |
| 6 | Verify log entry `causer_id` references the authenticated user | Causer set |

---

## 8. CODE-TRACE: Controller Method Execution Traces

### CODE-TRACE-01: `index()` — HpcTemplatesController (Line 18)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplatesController.php:20` | `$this->authorizeHpcIndex()` — calls `Gate::authorize('tenant.hpc.viewAny')` via HpcIndexDataTrait |
| 2 | `HpcIndexDataTrait.php:28-49` | `$this->getHpcIndexData()` — loads OrganizationAcademicSession, sch_academic_term, SchoolClass::active(), Section::active(), and filtered students paginated (10) |
| 3 | `HpcTemplatesController.php:22` | `return view('hpc::hpc.index', $data)` — renders HPC dashboard/index view |

### CODE-TRACE-02: `create()` — HpcTemplatesController (Line 25)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplatesController.php:27` | `Gate::authorize('tenant.hpc-templates.create')` — checks create permission |
| 2 | `HpcTemplatesController.php:28` | `SchoolClass::where('is_active', 1)->get()` — loads all active school classes for applicable_to_grade dropdown |
| 3 | `HpcTemplatesController.php:29` | `return view('hpc::hpc-templates.create', compact('classes'))` — renders create form |

### CODE-TRACE-03: `store()` — HpcTemplatesController (Line 32)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplatesController.php:34` | `Gate::authorize('tenant.hpc-templates.create')` — checks create permission |
| 2 | `HpcTemplatesController.php:35` | `HpcTemplates::create($request->validated())` — creates record using validated FormRequest data |
| 3 | `HpcTemplatesController.php:37-40` | `activityLog($template, 'Created', ['message' => 'HPC Template created.', 'performed_by' => Auth::user()->name])` — logs creation |
| 4 | `HpcTemplatesController.php:42-43` | `redirect()->route('hpc.hpc.templates')->with('success', flash('created.hpc_template'))` — redirects to template tab |

### CODE-TRACE-04: `show()` — HpcTemplatesController (Line 46)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplatesController.php:48` | `Gate::authorize('tenant.hpc-templates.view')` — checks view permission |
| 2 | `HpcTemplatesController.php:49` | `HpcTemplates::findOrFail($id)` — loads template by ID, 404 if not found |
| 3 | `HpcTemplatesController.php:50` | `SchoolClass::whereIn('id', $template->applicable_to_grade ?? [])->get()` — loads class names for selected grade IDs |
| 4 | `HpcTemplatesController.php:51` | `return view('hpc::hpc-templates.show', compact('template', 'classes'))` — renders show view |

### CODE-TRACE-05: `edit()` — HpcTemplatesController (Line 54)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplatesController.php:56` | `Gate::authorize('tenant.hpc-templates.update')` — checks update permission |
| 2 | `HpcTemplatesController.php:57` | `HpcTemplates::findOrFail($id)` — loads existing record, 404 if not found |
| 3 | `HpcTemplatesController.php:58` | `SchoolClass::where('is_active', true)->get()` — loads all active classes for dropdown |
| 4 | `HpcTemplatesController.php:59` | `return view('hpc::hpc-templates.edit', compact('template', 'classes'))` — renders edit form |

### CODE-TRACE-06: `update()` — HpcTemplatesController (Line 62)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplatesController.php:64` | `Gate::authorize('tenant.hpc-templates.update')` — checks update permission |
| 2 | `HpcTemplatesController.php:65` | `HpcTemplates::findOrFail($id)` — loads existing record |
| 3 | `HpcTemplatesController.php:66` | `$original = $template->getOriginal()` — captures current DB state before update |
| 4 | `HpcTemplatesController.php:68` | `$template->update($request->validated())` — updates record with validated data |
| 5 | `HpcTemplatesController.php:70-77` | Change tracking loop: iterates `$template->getChanges()`, builds `$changes[$field] = ['old' => ..., 'new' => ...]`, skips `updated_at` |
| 6 | `HpcTemplatesController.php:79-83` | `activityLog($template, 'Updated', ['message' => 'HPC Template updated.', 'changes' => $changes, 'performed_by' => Auth::user()->name])` — logs update with attribute diff |
| 7 | `HpcTemplatesController.php:85-86` | `redirect()->route('hpc.hpc.templates')->with('success', flash('updated.hpc_template'))` — redirects |

### CODE-TRACE-07: `destroy()` — HpcTemplatesController (Line 89)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplatesController.php:91` | `Gate::authorize('tenant.hpc-templates.delete')` — checks delete permission |
| 2 | `HpcTemplatesController.php:92` | `HpcTemplates::findOrFail($id)` — loads existing record |
| 3 | `HpcTemplatesController.php:93` | `$template->is_active = false` — deactivates before soft-delete |
| 4 | `HpcTemplatesController.php:94` | `$template->save()` — persists is_active change |
| 5 | `HpcTemplatesController.php:95` | `$template->delete()` — soft deletes (sets deleted_at) |
| 6 | `HpcTemplatesController.php:97-100` | `activityLog($template, 'Deleted', ['message' => 'HPC Template deleted'])` — logs deletion |
| 7 | `HpcTemplatesController.php:102-103` | `redirect()->route('hpc.hpc.templates')->with('success', flash('deleted.hpc_template'))` — redirects |

### CODE-TRACE-08: `trashed()` — HpcTemplatesController (Line 106)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplatesController.php:108` | `Gate::authorize('tenant.hpc-templates.restore')` — checks restore permission (NOT viewAny) |
| 2 | `HpcTemplatesController.php:109` | `HpcTemplates::onlyTrashed()->latest('deleted_at')->paginate(10)` — soft-deleted records only, most recently deleted first, 10 per page |
| 3 | `HpcTemplatesController.php:110` | `return view('hpc::hpc-templates.trash', compact('templates'))` — renders trash view |

### CODE-TRACE-09: `restore()` — HpcTemplatesController (Line 113)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplatesController.php:115` | `Gate::authorize('tenant.hpc-templates.restore')` — checks restore permission |
| 2 | `HpcTemplatesController.php:116` | `HpcTemplates::onlyTrashed()->findOrFail($id)` — finds trashed record, 404 if not trashed |
| 3 | `HpcTemplatesController.php:117` | `$template->restore()` — sets deleted_at to NULL |
| 4 | `HpcTemplatesController.php:119-122` | `activityLog($template, 'Restored', ['message' => 'HPC Template restored'])` — logs restore |
| 5 | `HpcTemplatesController.php:124-125` | `redirect()->route('hpc.hpc.templates')->with('success', flash('restored.hpc_template'))` — redirects |

### CODE-TRACE-10: `forceDelete()` — HpcTemplatesController (Line 128)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplatesController.php:130` | `Gate::authorize('tenant.hpc-templates.forceDelete')` — checks forceDelete permission |
| 2 | `HpcTemplatesController.php:131` | `HpcTemplates::onlyTrashed()->findOrFail($id)` — finds only trashed record, 404 if active |
| 3 | `HpcTemplatesController.php:132` | `$template->forceDelete()` — permanently removes record from DB |
| 4 | `HpcTemplatesController.php:134-137` | `activityLog($template, 'Force Deleted', ['message' => 'HPC Template permanently deleted'])` — logs permanent deletion |
| 5 | `HpcTemplatesController.php:139-140` | `redirect()->route('hpc.hpc.templates')->with('success', flash('force_deleted.hpc_template'))` — redirects |

### CODE-TRACE-11: `toggleStatus()` — HpcTemplatesController (Line 143)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplatesController.php:145` | `Gate::authorize('tenant.hpc-templates.update')` — checks update permission |
| 2 | `HpcTemplatesController.php:146` | `$request->validate(['is_active' => 'required|boolean'])` — inline validation |
| 3 | `HpcTemplatesController.php:147` | `HpcTemplates::withTrashed()->findOrFail($id)` — loads ANY record (active, inactive, or trashed) |
| 4 | `HpcTemplatesController.php:148` | `$template->is_active = (bool) $request->is_active` — sets new status |
| 5 | `HpcTemplatesController.php:149` | `$template->save()` — persists change |
| 6 | `HpcTemplatesController.php:151-154` | `activityLog($template, 'Toggled', ['message' => 'HPC Template status toggled.'])` — logs status change |
| 7 | `HpcTemplatesController.php:156-160` | `return response()->json(['success' => true, 'is_active' => ..., 'message' => flash('status_updated.hpc_template')])` — JSON response |

---