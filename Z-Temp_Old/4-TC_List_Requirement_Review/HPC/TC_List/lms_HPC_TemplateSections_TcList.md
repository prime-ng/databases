# lms_HPC_TemplateSections_TcList

## Module: HPC → Template Sections

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | HPC |
| Tab Group | Template Management |
| Feature | Template Sections |
| URL(s) | `hpc/templates` (tab), `hpc/hpc-template-sections`, `hpc/hpc-template-sections/create`, `hpc/hpc-template-sections/{id}`, `hpc/hpc-template-sections/{id}/edit`, `hpc/hpc-template-sections/trash/view`, `hpc/hpc-template-sections/{id}/restore`, `hpc/hpc-template-sections/{id}/force-delete`, `hpc/hpc-template-sections/{id}/toggle-status` |
| Controller | `Modules\Hpc\Http\Controllers\HpcTemplateSectionsController` |
| Model(s) | `Modules\Hpc\Models\HpcTemplateSections`, `HpcTemplateSectionItems`, `HpcTemplateSectionTable` |
| Validation (Create) | `Modules\Hpc\Http\Requests\HpcTemplateSectionsRequest` |
| Validation (Update) | `Modules\Hpc\Http\Requests\HpcTemplateSectionsRequest` |
| Permissions | `tenant.hpc.viewAny`, `tenant.hpc-template-sections.create`, `tenant.hpc-template-sections.view`, `tenant.hpc-template-sections.update`, `tenant.hpc-template-sections.delete`, `tenant.hpc-template-sections.restore`, `tenant.hpc-template-sections.forceDelete` |
| Soft Deletes | Yes (all 3 models) |
| Activity Log | Created, Updated, Deleted, Restored, Force Deleted, Toggled |

---

## 2. Pre-conditions

- Required permissions: `tenant.hpc.viewAny`, plus action-specific permissions (`tenant.hpc-template-sections.*`)
- At least one `HpcTemplate` record must exist to reference via `template_id`
- At least one `HpcTemplatePart` record must exist to reference via `part_id`
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- Test user must have all applicable permissions (default admin user or user assigned via role)
- Index page expects `hpc_template_sections`, `hpc_template_section_items`, and `hpc_template_section_table` tables to exist
- Create/edit forms expect `hpc_templates` and `hpc_template_parts` data loaded for dropdowns
- Soft delete functionality expects `deleted_at` columns on all 3 models
- Route model binding expects valid integer IDs for `{id}` parameters
- Trash view expects at least one soft-deleted record to display meaningful data
- Toggle status expects `is_active` boolean column on `hpc_template_sections`
- Activity log expects `activity_log` table with proper polymorphic relationship

---

## 3. Default Data Load

When the page loads via `HpcTemplateSectionsController`, the following data is fetched per endpoint:

| Data Loaded | Source | Query | Filters | Pagination |
|------------|--------|-------|---------|------------|
| Index — section list | `HpcTemplateSections::with(['template', 'part', 'items'])->orderBy('display_order')` | All sections (non-trashed) | None | Yes (default per-page) |
| Index — search results | `HpcTemplateSections::where('code', 'LIKE', '%q%')->orWhere('description', 'LIKE', '%q%')` | Searched sections | `q` query param | Yes |
| Create — template list | `HpcTemplate::where('is_active', true)->pluck('name', 'id')` | Active templates | is_active=true | None |
| Create — part list | `HpcTemplatePart::where('is_active', true)->pluck('code', 'id')` | Active parts | is_active=true | None |
| Show — single section | `HpcTemplateSections::with(['template', 'part', 'items.tableItems'])->findOrFail($id)` | Section by ID | id | None |
| Edit — existing section | `HpcTemplateSections::with(['items' => fn($q) => $q->withTrashed(), 'items.tableItems' => fn($q) => $q->withTrashed()])->findOrFail($id)` | Section with items + tableItems | id | None |
| Trash — deleted sections | `HpcTemplateSections::onlyTrashed()->with(['template', 'part'])->orderBy('deleted_at', 'desc')` | Soft-deleted sections | None | Yes |
| Restore — single section | `HpcTemplateSections::onlyTrashed()->findOrFail($id)` | Trashed section by ID | id | None |

---

## 4. Test Data Strategy

- **Templates**: Seed at least 2 `HpcTemplate` records with `is_active=true` and `is_active=false` variants
- **Parts**: Seed at least 3 `HpcTemplatePart` records with unique codes, linked to templates
- **Sections**: Seed sections with varying `code`, `description`, `display_order`, `has_items` settings
- **Section Items**: Seed items with each `section_type` (Text, Image, Table) and varying visibility/print flags
- **Table Items**: Seed table cell data with multiple `row_id`/`column_id` combinations for Table-type sections
- **Soft Deletes**: Create sections, then soft-delete via `delete()` — verify `deleted_at` is set
- **Force Delete**: Soft-delete first, then force-delete — verify record and children permanently removed
- **Toggle Status**: Toggle `is_active` between true and false — verify persistence and reversion
- **Permissions**: Test with admin, principal, teacher, and guest roles
- **Unique Constraints**: Test `code` uniqueness per `part_id` and `display_order` uniqueness per `part_id`
- **Rich Text Sanitization**: Inject restricted HTML tags into `level_display` and verify sanitization
- **Pre-test Cleanup**: Delete created records before/after tests to avoid collisions

---

## 5. Business Conditions

### 4.1 Database Schema

| BC ID | Table | Column | Type (DDL) | Constraints |
|-------|-------|--------|------------|-------------|
| BC-DB-01 | hpc_template_sections | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-02 | hpc_template_sections | template_id | INT UNSIGNED | NOT NULL, FK → `hpc_templates.id` |
| BC-DB-03 | hpc_template_sections | part_id | INT UNSIGNED | NOT NULL, FK → `hpc_template_parts.id` |
| BC-DB-04 | hpc_template_sections | code | VARCHAR(50) | NOT NULL |
| BC-DB-05 | hpc_template_sections | description | VARCHAR(512) | NULLABLE |
| BC-DB-06 | hpc_template_sections | display_order | INT | NOT NULL |
| BC-DB-07 | hpc_template_sections | has_items | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-08 | hpc_template_sections | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-09 | hpc_template_sections | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-10 | hpc_template_sections | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-11 | hpc_template_sections | deleted_at | TIMESTAMP | NULLABLE (SoftDeletes) |
| BC-DB-12 | hpc_template_section_items | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-13 | hpc_template_section_items | section_id | INT UNSIGNED | NOT NULL, FK → `hpc_template_sections.id` |
| BC-DB-14 | hpc_template_section_items | html_object_name | VARCHAR(50) | NOT NULL |
| BC-DB-15 | hpc_template_section_items | ordinal | INT | NOT NULL |
| BC-DB-16 | hpc_template_section_items | level_display | VARCHAR(150) | NOT NULL (sanitized restricted HTML) |
| BC-DB-17 | hpc_template_section_items | level_print | VARCHAR(150) | NOT NULL |
| BC-DB-18 | hpc_template_section_items | section_type | ENUM('Text','Image','Table') | NOT NULL |
| BC-DB-19 | hpc_template_section_items | visible | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-20 | hpc_template_section_items | print | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-21 | hpc_template_section_items | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-22 | hpc_template_section_items | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-23 | hpc_template_section_items | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-24 | hpc_template_section_items | deleted_at | TIMESTAMP | NULLABLE (SoftDeletes) |
| BC-DB-25 | hpc_template_section_table | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-26 | hpc_template_section_table | section_id | INT UNSIGNED | NOT NULL, FK → `hpc_template_sections.id` |
| BC-DB-27 | hpc_template_section_table | section_item_id | INT UNSIGNED | NULLABLE, FK → `hpc_template_section_items.id` |
| BC-DB-28 | hpc_template_section_table | html_object_name | VARCHAR(50) | NOT NULL |
| BC-DB-29 | hpc_template_section_table | row_id | INT | NOT NULL |
| BC-DB-30 | hpc_template_section_table | column_id | INT | NOT NULL |
| BC-DB-31 | hpc_template_section_table | value | VARCHAR(255) | NOT NULL |
| BC-DB-32 | hpc_template_section_table | visible | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-33 | hpc_template_section_table | print | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-34 | hpc_template_section_table | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-35 | hpc_template_section_table | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-36 | hpc_template_section_table | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-37 | hpc_template_section_table | deleted_at | TIMESTAMP | NULLABLE (SoftDeletes) |

### 4.2 Validation Rules

| BC ID | Field | Rule | Error Message / Behavior |
|-------|-------|------|--------------------------|
| BC-VAL-01 | template_id | required, exists:hpc_templates,id | Validation error: template_id is required / must exist |
| BC-VAL-02 | part_id | required, exists:hpc_template_parts,id | Validation error: part_id is required / must exist |
| BC-VAL-03 | code | required, string, max:50 | Validation error: code is required / max 50 chars |
| BC-VAL-04 | code | unique per part_id (unique:hpc_template_sections,code,NULL,id,part_id,%part_id%) | Validation error: code already exists for this part |
| BC-VAL-05 | description | nullable, string, max:512 | Validation error: description max 512 chars |
| BC-VAL-06 | display_order | required, integer, min:1 | Validation error: display_order is required / min 1 |
| BC-VAL-07 | display_order | unique per part_id (unique:hpc_template_sections,display_order,NULL,id,part_id,%part_id%) | Validation error: display_order already exists for this part |
| BC-VAL-08 | has_items | sometimes, boolean | Coerced to boolean |
| BC-VAL-09 | is_active | sometimes, boolean | Coerced to boolean |
| BC-VAL-10 | items | nullable, array | Ignored if not provided |
| BC-VAL-11 | items.*.html_object_name | required_with:items, string, max:50, distinct | Validation error: html_object_name required / max 50 / must be unique |
| BC-VAL-12 | items.*.ordinal | required_with:items, integer, min:1, distinct | Validation error: ordinal required / min 1 / must be unique |
| BC-VAL-13 | items.*.level_display | required_with:items, string, max:150 | Validation error: level_display required / max 150 |
| BC-VAL-14 | items.*.level_print | required_with:items, string, max:150 | Validation error: level_print required / max 150 |
| BC-VAL-15 | items.*.section_type | required_with:items, in:Text,Image,Table | Validation error: section_type required / must be valid type |
| BC-VAL-16 | items.*.visible | sometimes, boolean | Coerced to boolean |
| BC-VAL-17 | items.*.print | sometimes, boolean | Coerced to boolean |
| BC-VAL-18 | items.*.is_active | sometimes, boolean | Coerced to boolean |
| BC-VAL-19 | table_items | nullable, array | Ignored if not provided |
| BC-VAL-20 | table_items.*.html_object_name | required_with:table_items, string, max:50 | Validation error: html_object_name required |
| BC-VAL-21 | table_items.*.row_id | required_with:table_items, integer, min:0 | Validation error: row_id required / min 0 |
| BC-VAL-22 | table_items.*.column_id | required_with:table_items, integer, min:0 | Validation error: column_id required / min 0 |
| BC-VAL-23 | table_items.*.value | required_with:table_items, string, max:255 | Validation error: value required / max 255 |
| BC-VAL-24 | table_items.*.visible | sometimes, boolean | Coerced to boolean |
| BC-VAL-25 | table_items.*.print | sometimes, boolean | Coerced to boolean |
| BC-VAL-26 | table_items.*.is_active | sometimes, boolean | Coerced to boolean |

### 4.3 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | `tenant.hpc.viewAny` | Without → 403 Forbidden on index |
| BC-AUTH-02 | `tenant.hpc-template-sections.create` | Without → 403 Forbidden on create/store |
| BC-AUTH-03 | `tenant.hpc-template-sections.view` | Without → 403 Forbidden on show |
| BC-AUTH-04 | `tenant.hpc-template-sections.update` | Without → 403 Forbidden on edit/update/toggleStatus |
| BC-AUTH-05 | `tenant.hpc-template-sections.delete` | Without → 403 Forbidden on destroy |
| BC-AUTH-06 | `tenant.hpc-template-sections.restore` | Without → 403 Forbidden on trashed/restore |
| BC-AUTH-07 | `tenant.hpc-template-sections.forceDelete` | Without → 403 Forbidden on forceDelete |
| BC-AUTH-08 | Admin role | Can perform all operations on all sections |
| BC-AUTH-09 | Guest user | Redirected to login (unauthenticated) |

### 4.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Index page loads with valid data | Paginated list of sections sorted by display_order; each row shows code, description, template, part, has_items, is_active |
| BC-BIZ-02 | Create section without items | Section record created; items table remains empty; has_items is false |
| BC-BIZ-03 | Create section with items (Text type) | Section + item created with section_type=Text; table_items ignored/empty |
| BC-BIZ-04 | Create section with items (Image type) | Section + item created with section_type=Image; table_items ignored/empty |
| BC-BIZ-05 | Create section with items (Table type) + table_items | Section + item created with section_type=Table; table_items populated with row/column data |
| BC-BIZ-06 | Update section — items changed | Old items + tableItems force-deleted; new items recreated from input (DB transaction) |
| BC-BIZ-07 | Update section — items unchanged | Existing items preserved; only section-level fields updated |
| BC-BIZ-08 | Update section — no items payload | Existing items kept untouched |
| BC-BIZ-09 | Show single section | Section loaded with template, part, items, and items.tableItems eager-loaded |
| BC-BIZ-10 | Soft delete section | deleted_at set on section, items, and tableItems (cascading soft deletes) |
| BC-BIZ-11 | Restore section | deleted_at set to null on section, items, and tableItems |
| BC-BIZ-12 | Force delete section | Items + tableItems force-deleted first, then section force-deleted (DB transaction) |
| BC-BIZ-13 | Toggle status active → inactive | is_active flipped from true to false |
| BC-BIZ-14 | Toggle status inactive → active | is_active flipped from false to true |
| BC-BIZ-15 | Display_order sort ascending | Index page lists sections by display_order ASC |
| BC-BIZ-16 | has_items=true shows items | When loading section with has_items=true, items relation is populated |
| BC-BIZ-17 | has_items=false hides items | When loading section with has_items=false, items relation is empty |
| BC-BIZ-18 | section_type=Table allows table_items | Table-type items have corresponding hpc_template_section_table rows |
| BC-BIZ-19 | section_type=Text/Image ignores table_items | Text/Image items have no hpc_template_section_table rows |
| BC-BIZ-20 | level_display sanitized with restricted HTML | Tags like <b>, <i>, <u> allowed; <script>, <iframe> stripped |
| BC-BIZ-21 | tableItems ordered by row_id then column_id | Table data exported/sorted by (row_id ASC, column_id ASC) |
| BC-BIZ-22 | Update with empty items array | Old items force-deleted; no new items created |
| BC-BIZ-23 | Force delete on non-trashed record | Record must be soft-deleted first; returns 404 or error |
| BC-BIZ-24 | Toggle status via dedicated endpoint | Endpoint returns JSON response with new is_active value |

### 4.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | hpc_template_sections.template_id | hpc_templates (id) | RESTRICT |
| BC-REF-02 | hpc_template_sections.part_id | hpc_template_parts (id) | RESTRICT |
| BC-REF-03 | hpc_template_section_items.section_id | hpc_template_sections (id) | CASCADE |
| BC-REF-04 | hpc_template_section_table.section_id | hpc_template_sections (id) | CASCADE |
| BC-REF-05 | hpc_template_section_table.section_item_id | hpc_template_section_items (id) | SET NULL |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Index page loads with paginated sections list | `GET hpc/hpc-template-sections` returns 200; sections sorted by display_order ASC; pagination controls visible | — | — | ⬜ |
| TC-P02 | Create section without items (has_items=false) | Section created with has_items=false; no items/table_items records inserted | — | — | ⬜ |
| TC-P03 | Create section with 1 item of type Text | Section + 1 item created with section_type=Text; table_items empty | — | — | ⬜ |
| TC-P04 | Create section with items of type Image | Section + 1+ items created with section_type=Image; table_items empty | — | — | ⬜ |
| TC-P05 | Create section with items of type Table + table_items | Section + item(s) with section_type=Table + table_items rows with row_id/column_id/value | — | — | ⬜ |
| TC-P06 | Create section with multiple items (3 items, mixed types) | All 3 items created with distinct html_object_name and ordinal; each has correct section_type | — | — | ⬜ |
| TC-P07 | Create section with all optional boolean flags set | visible, print, is_active, has_items all set to true/false explicitly; values persisted | — | — | ⬜ |
| TC-P08 | Create section with description as null | Section created; description is NULL in database | — | — | ⬜ |
| TC-P09 | Edit section — change code, description, display_order | Section-level fields updated; items unchanged | — | — | ⬜ |
| TC-P10 | Edit section — replace items (old force-deleted, new created) | Old items have deleted_at set; new items created with new data | — | — | ⬜ |
| TC-P11 | Edit section — change Text item to Table item + table_items | Old item force-deleted; new Table item + table_items rows created | — | — | ⬜ |
| TC-P12 | Edit section — add table_items to existing Table item | New table_items rows added; old ones force-deleted and recreated | — | — | ⬜ |
| TC-P13 | Show single section via GET endpoint | Section loaded with template, part, items, items.tableItems in response | — | — | ⬜ |
| TC-P14 | Soft delete section | Section.deleted_at set; section no longer appears in index; appears in trash | — | — | ⬜ |
| TC-P15 | Restore soft-deleted section | Section.deleted_at set to null; section reappears in index | — | — | ⬜ |
| TC-P16 | Force delete section (permanent) | Section + items + tableItems permanently deleted; not in index or trash | — | — | ⬜ |
| TC-P17 | Toggle status from active to inactive | is_active flips from true to false; section may be hidden from some views | — | — | ⬜ |
| TC-P18 | Toggle status from inactive to active | is_active flips from false to true; section becomes visible again | — | — | ⬜ |
| TC-P19 | Index displays sections sorted by display_order ASC | First row has lowest display_order; last row has highest | — | — | ⬜ |
| TC-P20 | Create section with items all having distinct html_object_name | No validation error; all items stored with unique html_object_name | — | — | ⬜ |
| TC-P21 | Create section with items all having distinct ordinal | No validation error; all items stored with unique ordinal | — | — | ⬜ |
| TC-P22 | Table items returned ordered by row_id then column_id | table_items sorted (row_id ASC, column_id ASC) in response | — | — | ⬜ |
| TC-P23 | Trash view lists all soft-deleted sections | `GET hpc/hpc-template-sections/trash/view` returns 200; shows only deleted records | — | — | ⬜ |
| TC-P24 | Index search by code keyword | Sections matching code filter returned; pagination preserved | — | — | ⬜ |
| TC-P25 | Index search by description keyword | Sections matching description filter returned; pagination preserved | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Create — missing template_id | Validation error: template_id is required | — | — | ⬜ |
| TC-N02 | Create — invalid template_id (non-existent FK) | Validation error: template_id must exist in hpc_templates | — | — | ⬜ |
| TC-N03 | Create — missing part_id | Validation error: part_id is required | — | — | ⬜ |
| TC-N04 | Create — invalid part_id (non-existent FK) | Validation error: part_id must exist in hpc_template_parts | — | — | ⬜ |
| TC-N05 | Create — duplicate code for same part_id | Validation error: code already exists for this part | — | — | ⬜ |
| TC-N06 | Create — duplicate display_order for same part_id | Validation error: display_order already exists for this part | — | — | ⬜ |
| TC-N07 | Create — display_order less than 1 | Validation error: display_order must be at least 1 | — | — | ⬜ |
| TC-N08 | Create — code exceeds 50 characters | Validation error: code max 50 characters | — | — | ⬜ |
| TC-N09 | Create — description exceeds 512 characters | Validation error: description max 512 characters | — | — | ⬜ |
| TC-N10 | Create — items.*.section_type invalid value | Validation error: section_type must be one of Text, Image, Table | — | — | ⬜ |
| TC-N11 | Create — items.*.html_object_name missing | Validation error: items.*.html_object_name is required | — | — | ⬜ |
| TC-N12 | Create — items.*.html_object_name not distinct | Validation error: items.*.html_object_name must be unique | — | — | ⬜ |
| TC-N13 | Create — items.*.ordinal not distinct | Validation error: items.*.ordinal must be unique | — | — | ⬜ |
| TC-N14 | Create — items.*.ordinal less than 1 | Validation error: items.*.ordinal min 1 | — | — | ⬜ |
| TC-N15 | Create — table_items.*.row_id negative | Validation error: table_items.*.row_id min 0 | — | — | ⬜ |
| TC-N16 | Edit — non-existent section ID | 404 Not Found | — | — | ⬜ |
| TC-N17 | Delete — non-existent section ID | 404 Not Found | — | — | ⬜ |
| TC-N18 | Permission denied — user without tenant.hpc-template-sections.create | 403 Forbidden on create page | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-D01 | SoftDeletes trait on HpcTemplateSections model | delete() sets deleted_at; record excluded from default queries | — | — | ⬜ |
| TC-D02 | SoftDeletes trait on HpcTemplateSectionItems model | delete() sets deleted_at on items when section is soft-deleted | — | — | ⬜ |
| TC-D03 | SoftDeletes trait on HpcTemplateSectionTable model | delete() sets deleted_at on table items when section is soft-deleted | — | — | ⬜ |
| TC-D04 | Restore cascades to items and tableItems | Restoring section restores all related items and tableItems (deleted_at = null) | — | — | ⬜ |
| TC-D05 | DB transaction on forceDelete — items + tableItems deleted first | Force-deleting section: items and tableItems permanently removed before section | — | — | ⬜ |
| TC-D06 | DB transaction on update — old items force-deleted, new recreated | Update replaces items within a transaction; rollback if any step fails | — | — | ⬜ |
| TC-D07 | FK constraint — section_id in hpc_template_section_items | Cannot insert item with invalid section_id | — | — | ⬜ |
| TC-D08 | FK constraint — section_id in hpc_template_section_table | Cannot insert table item with invalid section_id | — | — | ⬜ |
| TC-D09 | FK constraint — section_item_id in hpc_template_section_table (nullable) | Can be NULL; if set, must reference valid item ID | — | — | ⬜ |
| TC-D10 | SanitizesRichText trait on level_display | Script tags, iframes stripped; allowed tags (<b>, <i>, <u>) preserved | — | — | ⬜ |
| TC-D11 | display_order unique per part_id | Cannot create two sections with same display_order under same part | — | — | ⬜ |
| TC-D12 | code unique per part_id | Cannot create two sections with same code under same part | — | — | ⬜ |
| TC-D13 | hasMany relationship — section has many items | items() returns collection of HpcTemplateSectionItems | — | — | ⬜ |
| TC-D14 | hasMany relationship — section has many tableItems | tableItems() returns collection of HpcTemplateSectionTable | — | — | ⬜ |
| TC-D15 | hasMany relationship — item has many tableItems | An item's tableItems() returns related table rows | — | — | ⬜ |
| TC-D16 | Activity log created on section creation | activity_log contains "Created" entry with section data | — | — | ⬜ |
| TC-D17 | Activity log created on section update | activity_log contains "Updated" entry with changed fields | — | — | ⬜ |
| TC-D18 | Activity log created on section deletion | activity_log contains "Deleted" entry | — | — | ⬜ |
| TC-D19 | Activity log created on section restore | activity_log contains "Restored" entry | — | — | ⬜ |
| TC-D20 | Activity log created on force delete | activity_log contains "Force Deleted" entry | — | — | ⬜ |
| TC-D21 | Activity log created on toggle status | activity_log contains "Toggled" entry with is_active value | — | — | ⬜ |
| TC-D22 | belongsTo relationship — section belongs to template | Section->template returns related HpcTemplate model | — | — | ⬜ |
| TC-D23 | belongsTo relationship — section belongs to part | Section->part returns related HpcTemplatePart model | — | — | ⬜ |
| TC-D24 | formatResponse structure matches expected keys | Response contains id, code, description, display_order, template, part, items, table_items | — | — | ⬜ |
| TC-D25 | tableData alias relationship on items | Item->tableData() returns same as tableItems with proper eager loading | — | — | ⬜ |

---

## 7. Detailed Test Steps

### 7.1 Positive TC Steps

#### TC-P01: Index Page Loads With Paginated Sections List

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard loads successfully |
| 2 | Navigate to `hpc/hpc-template-sections` | Page returns 200 OK |
| 3 | Verify page heading contains "Template Sections" | Correct heading displayed |
| 4 | Check table lists sections sorted by display_order ASC | First row has lowest display_order |
| 5 | Verify each row shows code, description, template name, part code, has_items badge, is_active badge | All columns present |
| 6 | Check pagination controls visible at bottom | Pagination links displayed |
| 7 | Seed 25+ sections and verify pagination shows multiple pages | Page 1 shows first N records, page 2 shows next |

---

#### TC-P02: Create Section Without Items (has_items=false)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to `hpc/hpc-template-sections/create` | Create form loads |
| 3 | Select a valid template_id from dropdown | Template selected |
| 4 | Select a valid part_id from dropdown | Part selected |
| 5 | Enter code: `SEC-001` | Code entered |
| 6 | Enter description: `Section without items` | Description entered |
| 7 | Enter display_order: `1` | Order set |
| 8 | Leave has_items unchecked | has_items defaults to false |
| 9 | Leave items array empty | No items provided |
| 10 | Submit the form | 201 Created or redirect to index |
| 11 | Verify database has hpc_template_sections record with has_items=0 | Record created |
| 12 | Verify hpc_template_section_items table has no related rows | Items table empty |
| 13 | Verify hpc_template_section_table table has no related rows | Table items empty |

---

#### TC-P03: Create Section With 1 Item of Type Text

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Select template_id and part_id | Values selected |
| 4 | Enter code: `SEC-TEXT-01`, display_order: `10` | Values entered |
| 5 | Check has_items = true | Items section enabled |
| 6 | Add 1 item: html_object_name = `obj_text_1`, ordinal = `1` | Item data entered |
| 7 | Set level_display = `Text Display Level` | Display value set |
| 8 | Set level_print = `Text Print Level` | Print value set |
| 9 | Set section_type = `Text` | Type selected |
| 10 | Set visible = true, print = true, is_active = true | Flags set |
| 11 | Submit the form | 201 Created |
| 12 | Verify database: 1 section + 1 item with section_type=Text | Correct records |
| 13 | Verify no table_items rows created | Table empty |

---

#### TC-P04: Create Section With Items of Type Image

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Select template and part | Values selected |
| 4 | Enter code: `SEC-IMG-01`, display_order: `20` | Values entered |
| 5 | Check has_items = true | Items section enabled |
| 6 | Add item: html_object_name = `obj_img_1`, ordinal = `1` | Item data |
| 7 | Set section_type = `Image` | Type = Image |
| 8 | Set level_display = `Image Area` | Display value |
| 9 | Set level_print = `Image Print` | Print value |
| 10 | Submit the form | 201 Created |
| 11 | Verify section + item with section_type=Image | Correct records |
| 12 | Verify no table_items rows | Table empty |

---

#### TC-P05: Create Section With Items of Type Table + Table Items

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Select template and part | Values selected |
| 4 | Enter code: `SEC-TBL-01`, display_order: `30` | Values entered |
| 5 | Check has_items = true | Items section enabled |
| 6 | Add item: html_object_name = `obj_tbl_1`, ordinal = `1`, section_type = `Table` | Table item configured |
| 7 | Set level_display = `Table Section`, level_print = `Table Print` | Values set |
| 8 | Add table_items: html_object_name = `cell_a1`, row_id = 0, column_id = 0, value = `Header 1` | Cell data |
| 9 | Add table_items: html_object_name = `cell_a2`, row_id = 0, column_id = 1, value = `Header 2` | Cell data |
| 10 | Add table_items: html_object_name = `cell_b1`, row_id = 1, column_id = 0, value = `Data 1` | Cell data |
| 11 | Add table_items: html_object_name = `cell_b2`, row_id = 1, column_id = 1, value = `Data 2` | Cell data |
| 12 | Submit the form | 201 Created |
| 13 | Verify 1 section + 1 item with section_type=Table | Section + item created |
| 14 | Verify 4 table_items rows created with correct row_id/column_id/value | Table data persisted |

---

#### TC-P06: Create Section With Multiple Items (Mixed Types)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Select template and part | Values selected |
| 4 | Enter code: `SEC-MIX-01`, display_order: `40`, has_items = true | Base values |
| 5 | Add item 1: html_object_name = `item_text`, ordinal = 1, section_type = `Text` | Text item |
| 6 | Add item 2: html_object_name = `item_img`, ordinal = 2, section_type = `Image` | Image item |
| 7 | Add item 3: html_object_name = `item_tbl`, ordinal = 3, section_type = `Table` | Table item |
| 8 | For item 3, add 2 table_items rows | Table data |
| 9 | Submit the form | 201 Created |
| 10 | Verify 3 items created with distinct html_object_name and ordinal | All 3 items in DB |
| 11 | Verify each item has correct section_type | Types match input |
| 12 | Verify 2 table_items rows linked to item 3 | Table data correct |

---

#### TC-P07: Create Section With All Optional Boolean Flags Set

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Fill all required fields with valid data | Data entered |
| 4 | Explicitly set: has_items = true, is_active = false | Flags set |
| 5 | Add 1 item and set: visible = false, print = false, is_active = false | Item flags set opposite |
| 6 | Submit the form | 201 Created |
| 7 | Verify is_active = 0 in hpc_template_sections | Section inactive |
| 8 | Verify has_items = 1 | Section has items |
| 9 | Verify item visible = 0, print = 0, is_active = 0 | Item flags persisted |

---

#### TC-P08: Create Section With Description as Null

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Fill required fields (template_id, part_id, code, display_order) | Required data |
| 4 | Leave description field empty | Description = null |
| 5 | Set has_items = false | No items |
| 6 | Submit the form | 201 Created |
| 7 | Verify database description column is NULL | Null stored |

---

#### TC-P09: Edit Section — Change Code, Description, Display Order

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a section with initial values: code=`OLD`, description=`Original`, display_order=1 | Base record |
| 2 | Navigate to edit page `hpc/hpc-template-sections/{id}/edit` | Edit form loads with pre-filled data |
| 3 | Change code to `NEW-CODE` | Code updated |
| 4 | Change description to `Updated description` | Description updated |
| 5 | Change display_order to 5 | Order updated |
| 6 | Do not modify items payload | Items unchanged |
| 7 | Submit the form | 200 OK or redirect |
| 8 | Verify section.code = `NEW-CODE` in database | Code persisted |
| 9 | Verify section.description = `Updated description` | Description persisted |
| 10 | Verify section.display_order = 5 | Order persisted |
| 11 | Verify original items remain in hpc_template_section_items | Items untouched |

---

#### TC-P10: Edit Section — Replace Items (Old Force-Deleted, New Created)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create section with 2 items (item_a, item_b) | Base records |
| 2 | Navigate to edit page | Edit form loads with existing items |
| 3 | Remove item_a and item_b from items payload | Old items removed from input |
| 4 | Add 2 new items: item_c (ordinal=1), item_d (ordinal=2) | New items in payload |
| 5 | Submit the form | 200 OK |
| 6 | Verify item_a and item_b have deleted_at set (force-deleted) | Old items soft-deleted |
| 7 | Verify item_c and item_d created with new data | New items exist |
| 8 | Verify old table_items also force-deleted if present | Table items cleaned up |

---

#### TC-P11: Edit Section — Change Text Item to Table + Table Items

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create section with 1 Text item and no table_items | Base record |
| 2 | Navigate to edit page | Edit form loads |
| 3 | Change item's section_type from Text to Table | Type changed |
| 4 | Add 2 table_items rows (row_id=0, col=0 + row_id=0, col=1) | Table data added |
| 5 | Submit the form | 200 OK |
| 6 | Verify old Text item is force-deleted (deleted_at set) | Old item removed |
| 7 | Verify new Table item created with section_type=Table | New item created |
| 8 | Verify 2 table_items rows in hpc_template_section_table | Table data persisted |

---

#### TC-P12: Edit Section — Add Table Items to Existing Table Item

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create section with 1 Table item + 2 table_items rows | Base record |
| 2 | Navigate to edit page | Edit form loads with existing data |
| 3 | Keep item data unchanged | Item preserved |
| 4 | Replace table_items with 4 new rows (2x2 grid) | New table data |
| 5 | Submit the form | 200 OK |
| 6 | Verify old 2 table_items rows force-deleted | Old rows deleted |
| 7 | Verify 4 new table_items rows created | New rows exist |
| 8 | Verify the section's item remains unchanged | Item not affected |

---

#### TC-P13: Show Single Section Via GET Endpoint

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create section with 2 items and table_items | Base record |
| 2 | Navigate to `hpc/hpc-template-sections/{id}` | Show page loads |
| 3 | Verify section code, description, display_order displayed | Section details visible |
| 4 | Verify template name and part code displayed | Relations shown |
| 5 | Verify items list shown with all fields | Items displayed |
| 6 | Verify table_items shown for Table-type items | Table data displayed |
| 7 | Verify has_items badge (Yes/No) and is_active badge (Active/Inactive) | Status badges visible |

---

#### TC-P14: Soft Delete Section

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create section with 2 items and 2 table_items | Base record |
| 2 | Navigate to section index | Section visible in list |
| 3 | Click delete button / send DELETE request | 200 OK or redirect |
| 4 | Verify section no longer appears in index list | Removed from default queries |
| 5 | Verify section.deleted_at is NOT NULL in database | Soft-deleted |
| 6 | Verify item records also have deleted_at set | Items soft-deleted |
| 7 | Verify table_item records also have deleted_at set | Table items soft-deleted |
| 8 | Navigate to trash view `hpc/hpc-template-sections/trash/view` | Section appears in trash list |

---

#### TC-P15: Restore Soft-Deleted Section

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a section with items and table_items | Section trashed |
| 2 | Verify section appears in trash view | In trash list |
| 3 | Click restore button / send restore request | 200 OK |
| 4 | Verify section.deleted_at = NULL in database | Restored |
| 5 | Verify item records deleted_at = NULL | Items restored |
| 6 | Verify table_item records deleted_at = NULL | Table items restored |
| 7 | Navigate to index | Section reappears in list |

---

#### TC-P16: Force Delete Section (Permanent)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create section with items and table_items | Base record |
| 2 | Soft-delete the section first | Section trashed |
| 3 | Navigate to trash view | Section visible |
| 4 | Click force-delete button / send forceDelete request | 200 OK |
| 5 | Verify section record permanently removed from database | No record |
| 6 | Verify all item records permanently removed | Items gone |
| 7 | Verify all table_item records permanently removed | Table items gone |
| 8 | Verify section does not appear in index or trash | Completely removed |

---

#### TC-P17: Toggle Status From Active to Inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create section with is_active = true | Active section |
| 2 | Navigate to index — verify badge shows "Active" | Status indicator visible |
| 3 | Send toggle-status request to `hpc/hpc-template-sections/{id}/toggle-status` | 200 OK, JSON response |
| 4 | Verify JSON response contains new is_active = false | Response indicates inactive |
| 5 | Verify database is_active = 0 | Persisted |
| 6 | Reload index page — badge shows "Inactive" | Status updated |

---

#### TC-P18: Toggle Status From Inactive to Active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create section with is_active = false | Inactive section |
| 2 | Send toggle-status request | 200 OK |
| 3 | Verify JSON response contains is_active = true | Now active |
| 4 | Verify database is_active = 1 | Persisted |
| 5 | Toggle again and verify it flips back to 0 | Bi-directional toggle |

---

#### TC-P19: Index Displays Sections Sorted By display_order ASC

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 5 sections under same part with orders: 10, 20, 30, 40, 50 | Sections created |
| 2 | Navigate to index | List loads |
| 3 | Verify order of rows: 10, 20, 30, 40, 50 | Ascending order |
| 4 | Create another section with display_order = 5 | New section |
| 5 | Reload index | New section appears first (order 5) |
| 6 | Verify full sequence: 5, 10, 20, 30, 40, 50 | Correct sort |

---

#### TC-P20: Create Section With Items All Having Distinct html_object_name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Add 3 items with html_object_name: `name_a`, `name_b`, `name_c` | Distinct names |
| 4 | Set each with distinct ordinal and valid section_type | Valid items |
| 5 | Submit the form | 201 Created |
| 6 | Verify all 3 items stored with their respective html_object_name | All persisted |

---

#### TC-P21: Create Section With Items All Having Distinct Ordinal

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Add 3 items with ordinals: 1, 2, 3 | Distinct ordinals |
| 4 | Set each with distinct html_object_name and valid section_type | Valid items |
| 5 | Submit the form | 201 Created |
| 6 | Verify items stored with ordinals 1, 2, 3 | All ordered correctly |

---

#### TC-P22: Table Items Returned Ordered By row_id Then column_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create Table item with 6 table_items in shuffled order: (1,0), (0,1), (0,0), (1,1), (0,2), (1,2) | Shuffled input |
| 2 | Submit and retrieve the section via show endpoint | Data loaded |
| 3 | Verify table_items sorted: (0,0), (0,1), (0,2), (1,0), (1,1), (1,2) | Correct order |
| 4 | Verify values match expected for each coordinate | Data integrity |

---

#### TC-P23: Trash View Lists All Soft-Deleted Sections

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete 3 sections | 3 trashed records |
| 2 | Navigate to `hpc/hpc-template-sections/trash/view` | Trash view loads |
| 3 | Verify all 3 sections appear in the list | All visible |
| 4 | Verify each row shows original code, template, part, deleted_at timestamp | Metadata displayed |
| 5 | Verify non-deleted sections do not appear | Only trashed shown |
| 6 | Check restore and force-delete buttons available per row | Action buttons present |

---

#### TC-P24: Index Search By Code Keyword

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed sections with codes: `ALPHA-01`, `BETA-01`, `GAMMA-01` | 3 sections |
| 2 | Navigate to index with `?q=ALPHA` | Search results |
| 3 | Verify only `ALPHA-01` appears in results | Filtered correctly |
| 4 | Verify no results for non-matching keyword | Empty state displayed |
| 5 | Verify partial match works: `?q=PH` | Both ALPHA and GAMMA excluded; BETA shown |

---

#### TC-P25: Index Search By Description Keyword

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed sections with descriptions: "First section alpha", "Second section beta", "Third section gamma" | 3 sections |
| 2 | Navigate to index with `?q=alpha` | Search results |
| 3 | Verify section with "alpha" description returned | Filtered correctly |
| 4 | Verify case-insensitive search works | "Alpha", "ALPHA" also match |
| 5 | Verify pagination preserved in search results | Pagination links present |

---

### 7.2 Negative TC Steps

#### TC-N01: Create — Missing template_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Fill all fields except template_id | template_id omitted |
| 4 | Submit the form | Validation error |
| 5 | Verify error message: "The template id field is required." | Error displayed |

---

#### TC-N02: Create — Invalid template_id (Non-Existent FK)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Enter template_id = 99999 (non-existent) | Invalid value |
| 4 | Fill all other required fields | Valid data |
| 5 | Submit the form | Validation error |
| 6 | Verify error: "The selected template id is invalid." | FK validation fails |

---

#### TC-N03: Create — Missing part_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Fill all fields except part_id | part_id omitted |
| 4 | Submit the form | Validation error |
| 5 | Verify error: "The part id field is required." | Error displayed |

---

#### TC-N04: Create — Invalid part_id (Non-Existent FK)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Enter part_id = 99999 (non-existent) | Invalid value |
| 4 | Fill all other required fields | Valid data |
| 5 | Submit the form | Validation error |
| 6 | Verify error: "The selected part id is invalid." | FK validation fails |

---

#### TC-N05: Create — Duplicate Code For Same part_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create section with code = `DUP` under part_id = 1 | First record |
| 2 | Navigate to create form | Create form loads |
| 3 | Select same part_id = 1 | Same part |
| 4 | Enter code = `DUP` (duplicate) | Duplicate value |
| 5 | Fill all other required fields | Valid data |
| 6 | Submit the form | Validation error |
| 7 | Verify error: "The code has already been taken." | Uniqueness enforced |

---

#### TC-N06: Create — Duplicate display_order For Same part_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create section with display_order = 5 under part_id = 1 | First record |
| 2 | Navigate to create form | Create form loads |
| 3 | Select same part_id = 1 | Same part |
| 4 | Enter display_order = 5 (duplicate) | Duplicate value |
| 5 | Fill all other required fields | Valid data |
| 6 | Submit the form | Validation error |
| 7 | Verify error: "The display order has already been taken." | Uniqueness enforced |

---

#### TC-N07: Create — display_order Less Than 1

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Enter display_order = 0 | Below minimum |
| 4 | Submit the form | Validation error |
| 5 | Verify error: "The display order must be at least 1." | Min value enforced |

---

#### TC-N08: Create — code Exceeds 50 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Enter code = "A" repeated 51 times | Exceeds max |
| 4 | Submit the form | Validation error |
| 5 | Verify error: "The code must not be greater than 50 characters." | Max length enforced |

---

#### TC-N09: Create — description Exceeds 512 Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Enter description = "X" repeated 513 times | Exceeds max |
| 4 | Submit the form | Validation error |
| 5 | Verify error: "The description must not be greater than 512 characters." | Max length enforced |

---

#### TC-N10: Create — items.*.section_type Invalid Value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Fill required section fields | Valid section data |
| 4 | Add item with section_type = `InvalidType` | Invalid enum value |
| 5 | Submit the form | Validation error |
| 6 | Verify error: "The selected items.0.section type is invalid." | Enum validation |

---

#### TC-N11: Create — items.*.html_object_name Missing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Fill required section fields | Valid section data |
| 4 | Add item with all fields except html_object_name | Missing required field |
| 5 | Submit the form | Validation error |
| 6 | Verify error: "The items.0.html object name is required." | Required validation |

---

#### TC-N12: Create — items.*.html_object_name Not Distinct

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Add 2 items both with html_object_name = `same_name` | Non-distinct names |
| 4 | Submit the form | Validation error |
| 5 | Verify error: "The items.0.html object name has a duplicate." | Distinct validation |

---

#### TC-N13: Create — items.*.ordinal Not Distinct

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Add 2 items both with ordinal = 1 | Non-distinct ordinal |
| 4 | Submit the form | Validation error |
| 5 | Verify error: "The items.0.ordinal has a duplicate." | Distinct validation |

---

#### TC-N14: Create — items.*.ordinal Less Than 1

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Add item with ordinal = 0 | Below minimum |
| 4 | Submit the form | Validation error |
| 5 | Verify error: "The items.0.ordinal must be at least 1." | Min value enforced |

---

#### TC-N15: Create — table_items.*.row_id Negative

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Add Table-type item | Item configured |
| 4 | Add table_item with row_id = -1 | Negative value |
| 5 | Submit the form | Validation error |
| 6 | Verify error: "The table items.0.row id must be at least 0." | Min value enforced |

---

#### TC-N16: Edit — Non-Existent Section ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to `hpc/hpc-template-sections/99999/edit` | 404 Not Found |
| 3 | Verify clean 404 page shown | No stack trace |

---

#### TC-N17: Delete — Non-Existent Section ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Send DELETE to `hpc/hpc-template-sections/99999` | 404 Not Found |
| 3 | Verify clean 404 response | No stack trace |

---

#### TC-N18: Permission Denied — User Without tenant.hpc-template-sections.create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without create permission | Authenticated |
| 2 | Navigate to `hpc/hpc-template-sections/create` | 403 Forbidden |
| 3 | Verify user cannot see the create form | Access denied |

---

### 7.3 Dependency TC Steps

#### TC-D01: SoftDeletes Trait on HpcTemplateSections Model

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect HpcTemplateSections model file | Uses SoftDeletes trait |
| 2 | Call delete() on a section instance | deleted_at column populated |
| 3 | Query sections without withTrashed() | Section excluded |
| 4 | Query sections with withTrashed() | Section included |

---

#### TC-D02: SoftDeletes Trait on HpcTemplateSectionItems Model

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect HpcTemplateSectionItems model file | Uses SoftDeletes trait |
| 2 | Soft-delete a parent section | Related items get deleted_at |
| 3 | Query items without withTrashed() | Items excluded |
| 4 | Query items with withTrashed() | Items included |

---

#### TC-D03: SoftDeletes Trait on HpcTemplateSectionTable Model

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect HpcTemplateSectionTable model file | Uses SoftDeletes trait |
| 2 | Soft-delete a parent section | Related table items get deleted_at |
| 3 | Query table items without withTrashed() | Table items excluded |
| 4 | Query table items with withTrashed() | Table items included |

---

#### TC-D04: Restore Cascades to Items and Table Items

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a section with 2 items and 3 table_items | All trashed |
| 2 | Call restore() on the section | Section restored |
| 3 | Verify all items have deleted_at = NULL | Items restored |
| 4 | Verify all table_items have deleted_at = NULL | Table items restored |

---

#### TC-D05: DB Transaction on ForceDelete — Items + Table Items Deleted First

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete section with items and table_items | Trashed |
| 2 | Call forceDelete() on section | Force delete executed |
| 3 | Verify hpc_template_section_items records permanently deleted | Items gone |
| 4 | Verify hpc_template_section_table records permanently deleted | Table items gone |
| 5 | Verify section record permanently deleted | Section gone |

---

#### TC-D06: DB Transaction on Update — Old Items Force-Deleted, New Recreated

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create section with 2 items + 2 table_items | Base record |
| 2 | Send update request with completely new items payload | Update request |
| 3 | Verify old items have deleted_at set | Force-deleted |
| 4 | Verify new items created with correct data | Recreated |
| 5 | Verify old table_items also force-deleted | Table items removed |
| 6 | Verify update runs within a DB transaction | Atomic operation |

---

#### TC-D07: FK Constraint — section_id in hpc_template_section_items

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Attempt to insert item with section_id = 99999 | FK violation |
| 2 | Verify database throws integrity constraint error | Error raised |
| 3 | Insert item with valid section_id | Insert succeeds |

---

#### TC-D08: FK Constraint — section_id in hpc_template_section_table

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Attempt to insert table item with section_id = 99999 | FK violation |
| 2 | Verify database throws integrity constraint error | Error raised |
| 3 | Insert table item with valid section_id | Insert succeeds |

---

#### TC-D09: FK Constraint — section_item_id in hpc_template_section_table (Nullable)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Insert table item with section_item_id = NULL | Allowed |
| 2 | Insert table item with valid section_item_id | Allowed |
| 3 | Insert table item with section_item_id = 99999 | FK violation |
| 4 | Verify constraint error raised | Error on invalid FK |

---

#### TC-D10: SanitizesRichText Trait on level_display

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create item with level_display containing `<b>bold</b><script>alert('xss')</script>` | Input with malicious tags |
| 2 | Submit the form | 201 Created |
| 3 | Verify level_display stored as `<b>bold</b>alert('xss')` | Script tag stripped |
| 4 | Verify allowed tags `<b>`, `<i>`, `<u>` preserved | Allowed HTML kept |

---

#### TC-D11: display_order Unique Per part_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create section with display_order = 1 under part_id = 1 | First record |
| 2 | Attempt to create another section with display_order = 1 under same part_id | Validation error |
| 3 | Create section with display_order = 1 under part_id = 2 | Succeeds (different part) |

---

#### TC-D12: code Unique Per part_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create section with code = `UNIQUE-CODE` under part_id = 1 | First record |
| 2 | Attempt to create another section with same code under part_id = 1 | Validation error |
| 3 | Create section with same code under part_id = 2 | Succeeds (different part) |

---

#### TC-D13: hasMany Relationship — Section Has Many Items

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create section with 3 items | Relations set |
| 2 | Call `$section->items` | Returns Collection of 3 HpcTemplateSectionItems |
| 3 | Verify items are properly linked via section_id | FK reference correct |

---

#### TC-D14: hasMany Relationship — Section Has Many Table Items

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create section with Table item and 4 table_items | Relations set |
| 2 | Call `$section->tableItems` | Returns Collection of 4 HpcTemplateSectionTable |
| 3 | Verify table_items correctly linked via section_id | FK reference correct |

---

#### TC-D15: hasMany Relationship — Item Has Many Table Items

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create section with 1 Table item linked to 3 table_items | Relations set |
| 2 | Call `$item->tableItems` | Returns Collection of 3 HpcTemplateSectionTable |
| 3 | Verify table_items have correct section_item_id | FK reference correct |

---

#### TC-D16: Activity Log Created on Section Creation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a new section | Section created |
| 2 | Query activity_log table for "Created" event on HpcTemplateSections | Log entry exists |
| 3 | Verify log entry contains section ID, code, and user info | Metadata present |

---

#### TC-D17: Activity Log Created on Section Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Update an existing section's code | Section updated |
| 2 | Query activity_log for "Updated" event | Log entry exists |
| 3 | Verify log shows changed fields (code old → new) | Diff captured |

---

#### TC-D18: Activity Log Created on Section Deletion

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a section | Section deleted |
| 2 | Query activity_log for "Deleted" event | Log entry exists |
| 3 | Verify log contains section identifier | Deletion logged |

---

#### TC-D19: Activity Log Created on Section Restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Restore a soft-deleted section | Section restored |
| 2 | Query activity_log for "Restored" event | Log entry exists |
| 3 | Verify log contains section ID | Restoration logged |

---

#### TC-D20: Activity Log Created on Force Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Force-delete a trashed section | Section permanently deleted |
| 2 | Query activity_log for "Force Deleted" event | Log entry exists |
| 3 | Verify log entry records permanent deletion | Force delete logged |

---

#### TC-D21: Activity Log Created on Toggle Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Toggle section is_active status | Status toggled |
| 2 | Query activity_log for "Toggled" event | Log entry exists |
| 3 | Verify log contains new is_active value | State change logged |

---

#### TC-D22: belongsTo Relationship — Section Belongs to Template

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Retrieve a section with its template relation | Eager-loaded |
| 2 | Call `$section->template` | Returns HpcTemplate model |
| 3 | Verify template.id matches section.template_id | FK correct |

---

#### TC-D23: belongsTo Relationship — Section Belongs to Part

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Retrieve a section with its part relation | Eager-loaded |
| 2 | Call `$section->part` | Returns HpcTemplatePart model |
| 3 | Verify part.id matches section.part_id | FK correct |

---

#### TC-D24: formatResponse Structure Matches Expected Keys

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call the formatResponse method on a section instance | Response array returned |
| 2 | Verify keys: id, code, description, display_order, has_items, is_active | Core fields present |
| 3 | Verify keys: template (object), part (object) | Relation objects present |
| 4 | Verify keys: items (array), table_items (array) | Relation arrays present |
| 5 | Verify no unexpected keys in response | Clean response |

---

#### TC-D25: tableData Alias Relationship on Items

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create item with 2 table_items | Relations set |
| 2 | Call `$item->tableData` | Returns same Collection as tableItems |
| 3 | Verify tableData is defined as an alias relationship in model | Definition matches |
| 4 | Verify eager loading with `with('items.tableData')` works | Eager loading functional |

---

## 8. CODE-TRACE: Controller Method Execution Traces

### CODE-TRACE-01: `index()` � HpcTemplateSectionsController (Line 20)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplateSectionsController.php:22` | `$this->authorizeHpcIndex()` � calls `Gate::authorize('tenant.hpc.viewAny')` via HpcIndexDataTrait |
| 2 | `HpcIndexDataTrait.php:28-49` | `$this->getHpcIndexData()` � loads sessions, terms, classes, sections, and paginated students |
| 3 | `HpcTemplateSectionsController.php:24` | `return view('hpc::hpc.index', $data)` � renders HPC dashboard/index view |

### CODE-TRACE-02: `create()` � HpcTemplateSectionsController (Line 27)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplateSectionsController.php:29` | `Gate::authorize('tenant.hpc-template-sections.create')` � checks create permission |
| 2 | `HpcTemplateSectionsController.php:30` | `HpcTemplateParts::where('is_active', 1)->get()` � loads active template parts for dropdown |
| 3 | `HpcTemplateSectionsController.php:31` | `HpcTemplates::where('is_active', 1)->get()` � loads active templates for dropdown |
| 4 | `HpcTemplateSectionsController.php:32` | `return view('hpc::hpc-template-sections.create', compact('templateParts','templates'))` |

### CODE-TRACE-03: `store()` � HpcTemplateSectionsController (Line 35)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplateSectionsController.php:37` | `Gate::authorize('tenant.hpc-template-sections.create')` |
| 2 | `HpcTemplateSectionsController.php:38` | `HpcTemplateSections::create($request->validated())` � creates section |
| 3 | `HpcTemplateSectionsController.php:40-54` | Loop over items: `$section->items()->create($item)`. If section_type === 'Table', creates `tableItems()` from matching `table_items` array |
| 4 | `HpcTemplateSectionsController.php:56-59` | `activityLog($section, 'Created', ['message' => 'HPC Template Section created.'])` |
| 5 | `HpcTemplateSectionsController.php:61-62` | `redirect()->route('hpc.hpc.templates')->with('success', flash('created.hpc_template_section'))` |

### CODE-TRACE-04: `show()` � HpcTemplateSectionsController (Line 66)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplateSectionsController.php:68` | `Gate::authorize('tenant.hpc-template-sections.view')` |
| 2 | `HpcTemplateSectionsController.php:69` | `HpcTemplateSections::with(['part','template'])->findOrFail($id)` � loads with 2 relations |
| 3 | `HpcTemplateSectionsController.php:70` | `return view('hpc::hpc-template-sections.show', compact('section'))` |

### CODE-TRACE-05: `edit()` � HpcTemplateSectionsController (Line 73)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplateSectionsController.php:75` | `Gate::authorize('tenant.hpc-template-sections.update')` |
| 2 | `HpcTemplateSectionsController.php:76` | `HpcTemplateSections::findOrFail($id)` |
| 3 | `HpcTemplateSectionsController.php:77` | `HpcTemplateParts::where('is_active', 1)->get()` |
| 4 | `HpcTemplateSectionsController.php:78` | `HpcTemplates::where('is_active', 1)->get()` |
| 5 | `HpcTemplateSectionsController.php:79` | `return view('hpc::hpc-template-sections.edit', compact('section','templateParts','templates'))` |

### CODE-TRACE-06: `update()` � HpcTemplateSectionsController (Line 82)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplateSectionsController.php:84` | `Gate::authorize('tenant.hpc-template-sections.update')` |
| 2 | `HpcTemplateSectionsController.php:85` | `HpcTemplateSections::findOrFail($id)` |
| 3 | `HpcTemplateSectionsController.php:86` | `$original = $section->getOriginal()` |
| 4 | `HpcTemplateSectionsController.php:88` | `$section->update($request->validated())` |
| 5 | `HpcTemplateSectionsController.php:90-106` | If items: `->items()->forceDelete()`, `->tableItems()->forceDelete()`, then recreate all items + table entries |
| 6 | `HpcTemplateSectionsController.php:108-114` | Change tracking loop |
| 7 | `HpcTemplateSectionsController.php:116-120` | `activityLog($section, 'Updated', ['changes' => $changes])` |
| 8 | `HpcTemplateSectionsController.php:122-123` | `redirect()->route('hpc.hpc.templates')->with('success', flash('updated.hpc_template_section'))` |

### CODE-TRACE-07: `destroy()` � HpcTemplateSectionsController (Line 128)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplateSectionsController.php:130` | `Gate::authorize('tenant.hpc-template-sections.delete')` |
| 2 | `HpcTemplateSectionsController.php:131` | `HpcTemplateSections::findOrFail($id)` |
| 3 | `HpcTemplateSectionsController.php:132` | `$section->is_active = false` |
| 4 | `HpcTemplateSectionsController.php:133` | `$section->save()` |
| 5 | `HpcTemplateSectionsController.php:134` | `$section->delete()` |
| 6 | `HpcTemplateSectionsController.php:136-139` | `activityLog($section, 'Deleted', ['message' => 'HPC Template Section deleted'])` |
| 7 | `HpcTemplateSectionsController.php:141-142` | `redirect()->route('hpc.hpc.templates')->with('success', flash('deleted.hpc_template_section'))` |

### CODE-TRACE-08: `trashed()` � HpcTemplateSectionsController (Line 145)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplateSectionsController.php:147` | `Gate::authorize('tenant.hpc-template-sections.restore')` |
| 2 | `HpcTemplateSectionsController.php:148` | `HpcTemplateSections::onlyTrashed()->with('part')->latest('deleted_at')->paginate(10)` |
| 3 | `HpcTemplateSectionsController.php:149` | `return view('hpc::hpc-template-sections.trash', compact('templateSections'))` |

### CODE-TRACE-09: `restore()` � HpcTemplateSectionsController (Line 152)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplateSectionsController.php:154` | `Gate::authorize('tenant.hpc-template-sections.restore')` |
| 2 | `HpcTemplateSectionsController.php:155` | `HpcTemplateSections::onlyTrashed()->findOrFail($id)` |
| 3 | `HpcTemplateSectionsController.php:156` | `$section->restore()` |
| 4 | `HpcTemplateSectionsController.php:158-161` | `activityLog($section, 'Restored', ['message' => 'HPC Template Section restored'])` |
| 5 | `HpcTemplateSectionsController.php:163-164` | `redirect()->route('hpc.hpc.templates')->with('success', flash('restored.hpc_template_section'))` |

### CODE-TRACE-10: `forceDelete()` � HpcTemplateSectionsController (Line 167)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplateSectionsController.php:169` | `Gate::authorize('tenant.hpc-template-sections.forceDelete')` |
| 2 | `HpcTemplateSectionsController.php:171` | `DB::beginTransaction()` � wraps in DB transaction |
| 3 | `HpcTemplateSectionsController.php:173` | `HpcTemplateSections::onlyTrashed()->findOrFail($id)` |
| 4 | `HpcTemplateSectionsController.php:176` | `$section->items()->withTrashed()->forceDelete()` � deletes child items permanently |
| 5 | `HpcTemplateSectionsController.php:177` | `$section->tableItems()->withTrashed()->forceDelete()` � deletes table data permanently |
| 6 | `HpcTemplateSectionsController.php:180` | `$section->forceDelete()` � deletes section permanently |
| 7 | `HpcTemplateSectionsController.php:182` | `DB::commit()` � commits transaction |
| 8 | `HpcTemplateSectionsController.php:184-188` | `activityLog($section, 'Force Deleted', ['message' => '...with related data.'])` |
| 9 | `HpcTemplateSectionsController.php:190-191` | `redirect()->with('success', flash('force_deleted.hpc_template_section'))` |
| 10 | `HpcTemplateSectionsController.php:193-197` | Catch block: `DB::rollBack()` on exception, redirect with error |

### CODE-TRACE-11: `toggleStatus()` � HpcTemplateSectionsController (Line 201)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplateSectionsController.php:203` | `Gate::authorize('tenant.hpc-template-sections.update')` |
| 2 | `HpcTemplateSectionsController.php:204` | `$request->validate(['is_active' => 'required|boolean'])` |
| 3 | `HpcTemplateSectionsController.php:205` | `HpcTemplateSections::withTrashed()->findOrFail($id)` |
| 4 | `HpcTemplateSectionsController.php:206` | `$section->is_active = (bool) $request->is_active` |
| 5 | `HpcTemplateSectionsController.php:207` | `$section->save()` |
| 6 | `HpcTemplateSectionsController.php:209-212` | `activityLog($section, 'Toggled', ['message' => 'HPC Template Section status toggled.'])` |
| 7 | `HpcTemplateSectionsController.php:214-218` | `return response()->json(['success' => true, 'is_active' => ..., 'message' => flash('status_updated.hpc_template_section')])` |

---
