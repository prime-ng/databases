# lms_HPC_TemplateRubrics_TcList

## Module: HPC → Template Rubrics

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | HPC |
| Tab Group | Template Management |
| Feature | Template Rubrics |
| URL(s) | `hpc/templates` (tab), `hpc/hpc-template-rubrics`, `hpc/hpc-template-rubrics/create`, `hpc/hpc-template-rubrics/{id}`, `hpc/hpc-template-rubrics/{id}/edit`, `hpc/hpc-template-rubrics/trash/view`, `hpc/hpc-template-rubrics/{id}/restore`, `hpc/hpc-template-rubrics/{id}/force-delete`, `hpc/hpc-template-rubrics/{id}/toggle-status` |
| Controller | `Modules\Hpc\Http\Controllers\HpcTemplateRubricsController` |
| Model(s) | `Modules\Hpc\Models\HpcTemplateRubrics`, `HpcTemplateRubricItems` |
| Validation (Create) | `Modules\Hpc\Http\Requests\HpcTemplateRubricsRequest` |
| Validation (Update) | `Modules\Hpc\Http\Requests\HpcTemplateRubricsRequest` |
| Permissions | `tenant.hpc.viewAny`, `tenant.hpc-template-rubrics.create`, `tenant.hpc-template-rubrics.view`, `tenant.hpc-template-rubrics.update`, `tenant.hpc-template-rubrics.delete`, `tenant.hpc-template-rubrics.restore`, `tenant.hpc-template-rubrics.forceDelete` |
| Soft Deletes | Yes (both models) |
| Activity Log | Created, Updated, Deleted, Restored, Force Deleted, Toggled |

---

## 2. Pre-conditions

- Required permissions: `tenant.hpc.viewAny`, plus action-specific permissions (`tenant.hpc-template-rubrics.*`)
- At least one `HpcTemplate` record must exist to reference via `template_id`
- At least one `HpcTemplatePart` record must exist to reference via `part_id`
- At least one `HpcTemplateSections` record must exist (nullable section_id — optional but testable)
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- Test user must have all applicable permissions (default admin user or user assigned via role)
- Index page expects `hpc_template_rubrics` and `hpc_template_rubric_items` tables to exist
- Create/edit forms expect `hpc_templates`, `hpc_template_parts`, and `hpc_template_sections` data loaded for dropdowns
- Soft delete functionality expects `deleted_at` columns on both models
- Route model binding expects valid integer IDs for `{id}` parameters
- Trash view expects at least one soft-deleted record to display meaningful data
- Toggle status expects `is_active` boolean column on `hpc_template_rubrics`
- Activity log expects `activity_log` table with proper polymorphic relationship
- Dropdown fields (input_dropdown, output_dropdown) accept comma-separated or newline-separated strings transformed to JSON arrays

---

## 3. Default Data Load

When the page loads via `HpcTemplateRubricsController`, the following data is fetched per endpoint:

| Data Loaded | Source | Query | Filters | Pagination |
|------------|--------|-------|---------|------------|
| Index — rubric list | `HpcTemplateRubrics::with(['template', 'part', 'section', 'items'])->orderBy('display_order')` | All rubrics (non-trashed) | None | Yes (default per-page) |
| Index — search results | `HpcTemplateRubrics::where('code', 'LIKE', '%q%')->orWhere('description', 'LIKE', '%q%')` | Searched rubrics | `q` query param | Yes |
| Create — template list | `HpcTemplate::where('is_active', true)->pluck('name', 'id')` | Active templates | is_active=true | None |
| Create — part list | `HpcTemplatePart::where('is_active', true)->pluck('code', 'id')` | Active parts | is_active=true | None |
| Create — section list | `HpcTemplateSections::where('is_active', true)->pluck('code', 'id')` | Active sections | is_active=true | None |
| Show — single rubric | `HpcTemplateRubrics::with(['template', 'part', 'section', 'items'])->findOrFail($id)` | Rubric by ID | id | None |
| Edit — existing rubric | `HpcTemplateRubrics::with(['items' => fn($q) => $q->withTrashed()])->findOrFail($id)` | Rubric with items (including trashed) | id | None |
| Trash — deleted rubrics | `HpcTemplateRubrics::onlyTrashed()->with(['template', 'part'])->orderBy('deleted_at', 'desc')` | Soft-deleted rubrics | None | Yes |

---

## 4. Test Data Strategy

- **Templates**: Seed at least 2 `HpcTemplate` records with `is_active=true` and `is_active=false` variants
- **Parts**: Seed at least 3 `HpcTemplatePart` records with unique codes, linked to templates
- **Sections**: Seed at least 2 `HpcTemplateSections` records for section_id linkage (nullable)
- **Rubrics**: Seed rubrics with varying `code`, `description`, `display_order`, `mandatory`, `visible`, `print`, `is_active` settings
- **Rubric Items**: Seed items covering every `input_type` and `output_type` variant (Descriptor, Numeric, Grade, Text, Boolean, Image, Json)
- **Input Required**: Seed items with `input_required=true` and verify auto-copy of output_level/output_level_numeric from input
- **Dropdowns**: Seed items with comma-separated and newline-separated input_dropdown/output_dropdown strings; verify JSON array storage
- **Soft Deletes**: Create rubrics with items, then soft-delete — verify `deleted_at` set on both models
- **Force Delete**: Soft-delete first, then force-delete — verify rubric and items permanently removed (DB transaction)
- **Toggle Status**: Toggle `is_active` between true/false — verify persistence and reversion
- **Permissions**: Test with admin, principal, teacher, and guest roles
- **Unique Constraints**: Test `display_order` uniqueness per `section_id`; test `items.*.html_object_name` and `items.*.ordinal` distinctness per rubric
- **Weight**: Test decimal weight values with different precision (2, 3 decimal places)
- **Input Level Numeric**: Test values at boundary (0) and positive integers
- **Pre-test Cleanup**: Delete created records before/after tests to avoid collisions

---

## 5. Business Conditions

### 4.1 Database Schema

| BC ID | Table | Column | Type (DDL) | Constraints |
|-------|-------|--------|------------|-------------|
| BC-DB-01 | hpc_template_rubrics | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-02 | hpc_template_rubrics | template_id | INT UNSIGNED | NOT NULL, FK → `hpc_templates.id` |
| BC-DB-03 | hpc_template_rubrics | part_id | INT UNSIGNED | NOT NULL, FK → `hpc_template_parts.id` |
| BC-DB-04 | hpc_template_rubrics | section_id | INT UNSIGNED | NULLABLE, FK → `hpc_template_sections.id` |
| BC-DB-05 | hpc_template_rubrics | display_order | INT | NOT NULL |
| BC-DB-06 | hpc_template_rubrics | code | VARCHAR(50) | NULLABLE |
| BC-DB-07 | hpc_template_rubrics | description | VARCHAR(512) | NULLABLE |
| BC-DB-08 | hpc_template_rubrics | mandatory | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-09 | hpc_template_rubrics | visible | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-10 | hpc_template_rubrics | print | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-11 | hpc_template_rubrics | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-12 | hpc_template_rubrics | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-13 | hpc_template_rubrics | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-14 | hpc_template_rubrics | deleted_at | TIMESTAMP | NULLABLE (SoftDeletes) |
| BC-DB-15 | hpc_template_rubric_items | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-16 | hpc_template_rubric_items | rubric_id | INT UNSIGNED | NOT NULL, FK → `hpc_template_rubrics.id` |
| BC-DB-17 | hpc_template_rubric_items | html_object_name | VARCHAR(50) | NOT NULL |
| BC-DB-18 | hpc_template_rubric_items | ordinal | INT | NOT NULL |
| BC-DB-19 | hpc_template_rubric_items | input_required | TINYINT(1) | NOT NULL DEFAULT 0 |
| BC-DB-20 | hpc_template_rubric_items | input_type | ENUM('Descriptor','Numeric','Grade','Text','Boolean','Image','Json') | NOT NULL |
| BC-DB-21 | hpc_template_rubric_items | output_type | ENUM('Descriptor','Numeric','Grade','Text','Boolean','Image','Json') | NOT NULL |
| BC-DB-22 | hpc_template_rubric_items | input_dropdown | JSON | NULLABLE |
| BC-DB-23 | hpc_template_rubric_items | output_dropdown | JSON | NULLABLE |
| BC-DB-24 | hpc_template_rubric_items | input_level | VARCHAR(255) | NOT NULL |
| BC-DB-25 | hpc_template_rubric_items | output_level | VARCHAR(255) | NOT NULL |
| BC-DB-26 | hpc_template_rubric_items | input_level_numeric | INT | NULLABLE |
| BC-DB-27 | hpc_template_rubric_items | output_level_numeric | INT | NULLABLE |
| BC-DB-28 | hpc_template_rubric_items | display_input_label | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-29 | hpc_template_rubric_items | print_output_label | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-30 | hpc_template_rubric_items | weight | DECIMAL(3) | NULLABLE |
| BC-DB-31 | hpc_template_rubric_items | description | VARCHAR(255) | NULLABLE |
| BC-DB-32 | hpc_template_rubric_items | is_active | TINYINT(1) | NOT NULL DEFAULT 1 |
| BC-DB-33 | hpc_template_rubric_items | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-34 | hpc_template_rubric_items | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-35 | hpc_template_rubric_items | deleted_at | TIMESTAMP | NULLABLE (SoftDeletes) |

### 4.2 Validation Rules

| BC ID | Field | Rule | Error Message / Behavior |
|-------|-------|------|--------------------------|
| BC-VAL-01 | template_id | required, exists:hpc_templates,id | Validation error: template_id is required / must exist |
| BC-VAL-02 | part_id | required, exists:hpc_template_parts,id | Validation error: part_id is required / must exist |
| BC-VAL-03 | section_id | nullable, exists:hpc_template_sections,id | Validation error: must exist if provided |
| BC-VAL-04 | code | nullable, string, max:50 | Validation error: max 50 chars |
| BC-VAL-05 | description | nullable, string, max:512 | Validation error: max 512 chars |
| BC-VAL-06 | items | required, array, min:1 | Validation error: at least 1 item required |
| BC-VAL-07 | items.*.html_object_name | required_with:items, string, max:50, distinct | Validation error: required / max 50 / distinct |
| BC-VAL-08 | items.*.ordinal | required_with:items, integer, min:1, distinct | Validation error: required / min 1 / distinct |
| BC-VAL-09 | items.*.input_required | sometimes, boolean | Coerced to boolean |
| BC-VAL-10 | items.*.input_type | required_with:items, in:Descriptor,Numeric,Grade,Text,Boolean,Image,Json | Validation error: must be valid type |
| BC-VAL-11 | items.*.output_type | required_with:items, in:Descriptor,Numeric,Grade,Text,Boolean,Image,Json | Validation error: must be valid type |
| BC-VAL-12 | items.*.input_dropdown | nullable, string | Transformed to JSON array (comma/newline separation) |
| BC-VAL-13 | items.*.output_dropdown | nullable, string | Transformed to JSON array (comma/newline separation) |
| BC-VAL-14 | items.*.input_level | required_with:items, string, max:255 | Validation error: required / max 255 |
| BC-VAL-15 | items.*.output_level | required_with:items, string, max:255 | Validation error: required / max 255 |
| BC-VAL-16 | items.*.input_level_numeric | nullable, integer, min:0 | Validation error: min 0 |
| BC-VAL-17 | items.*.output_level_numeric | nullable, integer, min:0 | Validation error: min 0 |
| BC-VAL-18 | items.*.display_input_label | sometimes, boolean | Coerced to boolean |
| BC-VAL-19 | items.*.print_output_label | sometimes, boolean | Coerced to boolean |
| BC-VAL-20 | items.*.weight | nullable, numeric | Must be numeric value |
| BC-VAL-21 | items.*.description | nullable, string, max:255 | Validation error: max 255 |
| BC-VAL-22 | items.*.is_active | sometimes, boolean | Coerced to boolean |
| BC-VAL-23 | mandatory | sometimes, boolean | Coerced to boolean |
| BC-VAL-24 | display_order | required, integer, min:0, unique per section_id | Validation error: required / min 0 / unique |
| BC-VAL-25 | visible | sometimes, boolean | Coerced to boolean |
| BC-VAL-26 | print | sometimes, boolean | Coerced to boolean |
| BC-VAL-27 | is_active | sometimes, boolean | Coerced to boolean |

### 4.3 Authorization

| BC ID | Permission | Behavior |
|-------|-----------|----------|
| BC-AUTH-01 | `tenant.hpc.viewAny` | Without → 403 Forbidden on index |
| BC-AUTH-02 | `tenant.hpc-template-rubrics.create` | Without → 403 Forbidden on create/store |
| BC-AUTH-03 | `tenant.hpc-template-rubrics.view` | Without → 403 Forbidden on show |
| BC-AUTH-04 | `tenant.hpc-template-rubrics.update` | Without → 403 Forbidden on edit/update/toggleStatus |
| BC-AUTH-05 | `tenant.hpc-template-rubrics.delete` | Without → 403 Forbidden on destroy |
| BC-AUTH-06 | `tenant.hpc-template-rubrics.restore` | Without → 403 Forbidden on trashed/restore |
| BC-AUTH-07 | `tenant.hpc-template-rubrics.forceDelete` | Without → 403 Forbidden on forceDelete |
| BC-AUTH-08 | Admin role | Can perform all operations on all rubrics |
| BC-AUTH-09 | Guest user | Redirected to login (unauthenticated) |

### 4.4 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Index page loads with valid data | Paginated list of rubrics sorted by display_order; each row shows code, description, template, part, section, mandatory, is_active |
| BC-BIZ-02 | Create rubric with min 1 item | Rubric + 1 item created successfully |
| BC-BIZ-03 | Create rubric with 5+ items | All items created with distinct html_object_name and ordinal |
| BC-BIZ-04 | Create rubric with section_id = null | Rubric created without section association |
| BC-BIZ-05 | Create rubric with section_id set | Rubric linked to the specified section |
| BC-BIZ-06 | Edit rubric — items changed | Old items force-deleted; new items recreated from input |
| BC-BIZ-07 | Edit rubric — items unchanged | Existing items preserved; only rubric-level fields updated |
| BC-BIZ-08 | input_required=true auto-copies output from input | output_level = input_level; output_level_numeric = input_level_numeric |
| BC-BIZ-09 | input_required=false does not auto-copy | output_level and output_level_numeric stored as provided independently |
| BC-BIZ-10 | input_dropdown as comma-separated string | Transformed to JSON array in prepareForValidation: "a,b,c" → ["a","b","c"] |
| BC-BIZ-11 | output_dropdown as newline-separated string | Transformed to JSON array: "a\nb\nc" → ["a","b","c"] |
| BC-BIZ-12 | input_level_numeric stored as integer | Value persisted as integer (nullable) |
| BC-BIZ-13 | Show single rubric | Rubric loaded with template, part, section, items eager-loaded |
| BC-BIZ-14 | Soft delete rubric | deleted_at set on rubric and items |
| BC-BIZ-15 | Restore rubric | deleted_at set to null on rubric and items |
| BC-BIZ-16 | Force delete rubric | Items force-deleted first, then rubric (DB transaction) |
| BC-BIZ-17 | Toggle status active → inactive | is_active flipped from true to false |
| BC-BIZ-18 | Toggle status inactive → active | is_active flipped from false to true |
| BC-BIZ-19 | mandatory=true flag | Rubric marked as mandatory; behavior in downstream reports |
| BC-BIZ-20 | weight decimal value stored | weight persisted as decimal (e.g., 2.5, 1.75) |
| BC-BIZ-21 | display_order sort ascending | Index page lists rubrics by display_order ASC |
| BC-BIZ-22 | display_order unique per section_id | Two rubrics with same section_id cannot share display_order |
| BC-BIZ-23 | items.*.html_object_name distinct within rubric | No two items in same rubric share html_object_name |
| BC-BIZ-24 | items.*.ordinal distinct within rubric | No two items in same rubric share ordinal |
| BC-BIZ-25 | Arr::only() filters fields in store() | Only allowed fields passed to create; extraneous fields ignored |
| BC-BIZ-26 | VALID_TYPES constant | ['Descriptor','Numeric','Grade','Text','Boolean','Image','Json'] used in validation |

### 4.5 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | hpc_template_rubrics.template_id | hpc_templates (id) | RESTRICT |
| BC-REF-02 | hpc_template_rubrics.part_id | hpc_template_parts (id) | RESTRICT |
| BC-REF-03 | hpc_template_rubrics.section_id | hpc_template_sections (id) | SET NULL |
| BC-REF-04 | hpc_template_rubric_items.rubric_id | hpc_template_rubrics (id) | CASCADE |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Index page loads with paginated rubrics list | `GET hpc/hpc-template-rubrics` returns 200; rubrics sorted by display_order ASC; pagination controls visible | — | — | ⬜ |
| TC-P02 | Create rubric with minimum 1 item (input_type=Descriptor) | Rubric + 1 item created with input_type=Descriptor | — | — | ⬜ |
| TC-P03 | Create rubric with 1 item input_type=Numeric | Rubric + 1 item with input_type=Numeric, output_type=Numeric | — | — | ⬜ |
| TC-P04 | Create rubric with 1 item input_type=Grade | Rubric + 1 item with input_type=Grade, output_type=Grade | — | — | ⬜ |
| TC-P05 | Create rubric with 1 item input_type=Text | Rubric + 1 item with input_type=Text, output_type=Text | — | — | ⬜ |
| TC-P06 | Create rubric with 1 item input_type=Boolean | Rubric + 1 item with input_type=Boolean, output_type=Boolean | — | — | ⬜ |
| TC-P07 | Create rubric with 1 item input_type=Image | Rubric + 1 item with input_type=Image, output_type=Image | — | — | ⬜ |
| TC-P08 | Create rubric with 1 item input_type=Json | Rubric + 1 item with input_type=Json, output_type=Json | — | — | ⬜ |
| TC-P09 | Create rubric with 5+ items (mixed types) | All 5 items created with distinct html_object_name and ordinal | — | — | ⬜ |
| TC-P10 | Create rubric with section_id = null | Rubric created; section_id is NULL in database | — | — | ⬜ |
| TC-P11 | Create rubric with section_id set to a valid section | Rubric linked to the given section; section relation accessible | — | — | ⬜ |
| TC-P12 | Edit rubric — change code, description, display_order | Rubric-level fields updated; items unchanged | — | — | ⬜ |
| TC-P13 | Edit rubric — replace items (old force-deleted, new created) | Old items have deleted_at set; new items created | — | — | ⬜ |
| TC-P14 | Edit rubric — add more items to existing set | Existing items replaced entirely; new set has more items | — | — | ⬜ |
| TC-P15 | Create rubric with input_required=true (verify output auto-copy) | output_level = input_level; output_level_numeric = input_level_numeric | — | — | ⬜ |
| TC-P16 | Create rubric with input_dropdown comma-separated string | Input `"Option A,Option B,Option C"` stored as JSON array `["Option A","Option B","Option C"]` | — | — | ⬜ |
| TC-P17 | Create rubric with output_dropdown newline-separated string | Input `"Choice 1\nChoice 2\nChoice 3"` stored as JSON array `["Choice 1","Choice 2","Choice 3"]` | — | — | ⬜ |
| TC-P18 | Create rubric with input_level_numeric set to integer | input_level_numeric persisted as integer; output_level_numeric also if input_required=true | — | — | ⬜ |
| TC-P19 | Show single rubric via GET endpoint | Rubric loaded with template, part, section, items in response | — | — | ⬜ |
| TC-P20 | Soft delete rubric with items | Rubric.deleted_at set; items also soft-deleted; rubric disappears from index | — | — | ⬜ |
| TC-P21 | Restore soft-deleted rubric | Rubric.deleted_at set to null; items restored; rubric reappears in index | — | — | ⬜ |
| TC-P22 | Force delete rubric (permanent) | Rubric + items permanently removed; not in index or trash | — | — | ⬜ |
| TC-P23 | Toggle status from active to inactive | is_active flips from true to false | — | — | ⬜ |
| TC-P24 | Toggle status from inactive to active | is_active flips from false to true | — | — | ⬜ |
| TC-P25 | Create rubric with mandatory = true | mandatory flag saved as 1 | — | — | ⬜ |
| TC-P26 | Create rubric item with weight decimal value | weight persisted as decimal (e.g., 2.50) | — | — | ⬜ |
| TC-P27 | Index displays rubrics sorted by display_order ASC | First row has lowest display_order; last row has highest | — | — | ⬜ |
| TC-P28 | Create rubric with items all having distinct html_object_name | All items stored with unique html_object_name per rubric | — | — | ⬜ |
| TC-P29 | Create rubric with items all having distinct ordinal | All items stored with unique ordinal per rubric | — | — | ⬜ |
| TC-P30 | Trash view lists all soft-deleted rubrics | `GET hpc/hpc-template-rubrics/trash/view` returns 200; only deleted records shown | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Create — missing template_id | Validation error: template_id is required | — | — | ⬜ |
| TC-N02 | Create — invalid template_id (non-existent FK) | Validation error: template_id must exist | — | — | ⬜ |
| TC-N03 | Create — missing part_id | Validation error: part_id is required | — | — | ⬜ |
| TC-N04 | Create — invalid part_id (non-existent FK) | Validation error: part_id must exist | — | — | ⬜ |
| TC-N05 | Create — invalid section_id (non-existent FK) | Validation error: section_id must exist | — | — | ⬜ |
| TC-N06 | Create — items array empty (min:1 fails) | Validation error: items must have at least 1 item | — | — | ⬜ |
| TC-N07 | Create — items.*.input_type invalid value | Validation error: input_type must be valid enum value | — | — | ⬜ |
| TC-N08 | Create — items.*.output_type invalid value | Validation error: output_type must be valid enum value | — | — | ⬜ |
| TC-N09 | Create — items.*.ordinal not distinct | Validation error: ordinal must be unique | — | — | ⬜ |
| TC-N10 | Create — items.*.html_object_name not distinct | Validation error: html_object_name must be unique | — | — | ⬜ |
| TC-N11 | Create — display_order duplicate per section_id | Validation error: display_order already exists for this section | — | — | ⬜ |
| TC-N12 | Create — display_order negative value | Validation error: display_order must be at least 0 | — | — | ⬜ |
| TC-N13 | Create — input_level_numeric negative | Validation error: input_level_numeric must be at least 0 | — | — | ⬜ |
| TC-N14 | Create — weight non-numeric string | Validation error: weight must be a number | — | — | ⬜ |
| TC-N15 | Create — items.*.html_object_name exceeds 50 chars | Validation error: max 50 characters | — | — | ⬜ |
| TC-N16 | Create — items.*.input_level exceeds 255 chars | Validation error: max 255 characters | — | — | ⬜ |
| TC-N17 | Edit — non-existent rubric ID | 404 Not Found | — | — | ⬜ |
| TC-N18 | Delete — non-existent rubric ID | 404 Not Found | — | — | ⬜ |
| TC-N19 | Permission denied — user without tenant.hpc-template-rubrics.create | 403 Forbidden on create page | — | — | ⬜ |
| TC-N20 | Guest access — redirect to login | Unauthenticated user redirected to login page | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-D01 | SoftDeletes trait on HpcTemplateRubrics model | delete() sets deleted_at; record excluded from default queries | — | — | ⬜ |
| TC-D02 | SoftDeletes trait on HpcTemplateRubricItems model | delete() sets deleted_at on items when rubric is soft-deleted | — | — | ⬜ |
| TC-D03 | Restore cascades to rubric items | Restoring rubric restores all related items (deleted_at = null) | — | — | ⬜ |
| TC-D04 | DB transaction on forceDelete — items deleted first | Force-deleting rubric: items permanently removed before rubric | — | — | ⬜ |
| TC-D05 | DB transaction on update — old items force-deleted, new recreated | Update replaces items within a transaction; rollback if any step fails | — | — | ⬜ |
| TC-D06 | input_required=true auto-copies output_level from input_level | output_level set to same value as input_level | — | — | ⬜ |
| TC-D07 | input_required=true auto-copies output_level_numeric from input_level_numeric | output_level_numeric set to same value as input_level_numeric | — | — | ⬜ |
| TC-D08 | input_required=false preserves independent output values | output_level and input_level stored separately as provided | — | — | ⬜ |
| TC-D09 | input_dropdown comma-separated string → JSON array | prepareForValidation transforms string to array | — | — | ⬜ |
| TC-D10 | output_dropdown newline-separated string → JSON array | prepareForValidation transforms string to array | — | — | ⬜ |
| TC-D11 | Arr::only() filters extraneous fields in store() | Only allowed fields from store() passed to create | — | — | ⬜ |
| TC-D12 | display_order unique per section_id | Cannot create two rubrics with same display_order under same section | — | — | ⬜ |
| TC-D13 | display_order unique per section with section_id = null | Rubrics with section_id=null can have same display_order (global scope) | — | — | ⬜ |
| TC-D14 | FK constraint — rubric_id in hpc_template_rubric_items | Cannot insert item with invalid rubric_id | — | — | ⬜ |
| TC-D15 | FK cascade — rubric deletion cascades to items | Deleting rubric deletes all related rubric items | — | — | ⬜ |
| TC-D16 | Activity log created on rubric creation | activity_log contains "Created" entry with rubric data | — | — | ⬜ |
| TC-D17 | Activity log created on rubric update | activity_log contains "Updated" entry with changed fields | — | — | ⬜ |
| TC-D18 | Activity log created on rubric deletion | activity_log contains "Deleted" entry | — | — | ⬜ |
| TC-D19 | Activity log created on rubric restore | activity_log contains "Restored" entry | — | — | ⬜ |
| TC-D20 | Activity log created on force delete | activity_log contains "Force Deleted" entry | — | — | ⬜ |
| TC-D21 | Activity log created on toggle status | activity_log contains "Toggled" entry with is_active value | — | — | ⬜ |
| TC-D22 | hasMany relationship — rubric has many items | items() returns Collection of HpcTemplateRubricItems | — | — | ⬜ |
| TC-D23 | belongsTo relationship — rubric belongs to template/part/section | rubric->template, rubric->part, rubric->section return correct models | — | — | ⬜ |
| TC-D24 | formatResponse structure matches expected keys | Response contains id, code, description, display_order, mandatory, template, part, section, items | — | — | ⬜ |
| TC-D25 | VALID_TYPES constant used in validation | All 7 types (Descriptor, Numeric, Grade, Text, Boolean, Image, Json) accepted; others rejected | — | — | ⬜ |

---

## 7. Detailed Test Steps

### 7.1 Positive TC Steps

#### TC-P01: Index Page Loads With Paginated Rubrics List

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Dashboard loads successfully |
| 2 | Navigate to `hpc/hpc-template-rubrics` | Page returns 200 OK |
| 3 | Verify page heading contains "Template Rubrics" | Correct heading displayed |
| 4 | Check table lists rubrics sorted by display_order ASC | First row has lowest display_order |
| 5 | Verify each row shows code, description, template name, part code, section code, mandatory badge, is_active badge | All columns present |
| 6 | Check pagination controls visible at bottom | Pagination links displayed |
| 7 | Seed 25+ rubrics and verify pagination shows multiple pages | Page 1 shows first N records, page 2 shows next |

---

#### TC-P02: Create Rubric With Minimum 1 Item (input_type=Descriptor)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to `hpc/hpc-template-rubrics/create` | Create form loads |
| 3 | Select a valid template_id from dropdown | Template selected |
| 4 | Select a valid part_id from dropdown | Part selected |
| 5 | Enter code: `RUBRIC-DESC-01` | Code entered |
| 6 | Enter description: `Descriptor rubric` | Description entered |
| 7 | Enter display_order: `1` | Order set |
| 8 | Add 1 item: html_object_name = `item_desc`, ordinal = `1` | Item data entered |
| 9 | Set input_type = `Descriptor`, output_type = `Descriptor` | Types selected |
| 10 | Set input_level = `Beginner`, output_level = `Beginner Level` | Levels entered |
| 11 | Submit the form | 201 Created or redirect |
| 12 | Verify database has hpc_template_rubrics record | Rubric created |
| 13 | Verify 1 item in hpc_template_rubric_items with input_type=Descriptor | Item created correctly |

---

#### TC-P03: Create Rubric With 1 Item input_type=Numeric

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Select template, part, enter code: `RUBRIC-NUM-01`, display_order: `10` | Values entered |
| 4 | Add item: html_object_name = `item_num`, ordinal = `1` | Item data |
| 5 | Set input_type = `Numeric`, output_type = `Numeric` | Types selected |
| 6 | Set input_level = `Score 1-10`, output_level = `Score Range` | Levels entered |
| 7 | Set input_level_numeric = 5, output_level_numeric = 5 | Numeric levels |
| 8 | Submit the form | 201 Created |
| 9 | Verify item with input_type=Numeric and numeric levels stored | Correct values |

---

#### TC-P04: Create Rubric With 1 Item input_type=Grade

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Select template, part, enter code and display_order | Values entered |
| 4 | Add item: html_object_name = `item_grade`, ordinal = `1` | Item data |
| 5 | Set input_type = `Grade`, output_type = `Grade` | Types selected |
| 6 | Set input_level = `A`, output_level = `A - Excellent` | Levels entered |
| 7 | Submit the form | 201 Created |
| 8 | Verify item with input_type=Grade stored | Grade type persisted |

---

#### TC-P05: Create Rubric With 1 Item input_type=Text

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Select template, part, enter code and display_order | Values entered |
| 4 | Add item: html_object_name = `item_text`, ordinal = `1` | Item data |
| 5 | Set input_type = `Text`, output_type = `Text` | Types selected |
| 6 | Set input_level = `Free text input`, output_level = `Text output` | Levels entered |
| 7 | Submit the form | 201 Created |
| 8 | Verify item with input_type=Text stored | Text type persisted |

---

#### TC-P06: Create Rubric With 1 Item input_type=Boolean

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Select template, part, enter code and display_order | Values entered |
| 4 | Add item: html_object_name = `item_bool`, ordinal = `1` | Item data |
| 5 | Set input_type = `Boolean`, output_type = `Boolean` | Types selected |
| 6 | Set input_level = `Yes/No`, output_level = `Yes/No Output` | Levels entered |
| 7 | Submit the form | 201 Created |
| 8 | Verify item with input_type=Boolean stored | Boolean type persisted |

---

#### TC-P07: Create Rubric With 1 Item input_type=Image

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Select template, part, enter code and display_order | Values entered |
| 4 | Add item: html_object_name = `item_img`, ordinal = `1` | Item data |
| 5 | Set input_type = `Image`, output_type = `Image` | Types selected |
| 6 | Set input_level = `Image upload`, output_level = `Image display` | Levels entered |
| 7 | Submit the form | 201 Created |
| 8 | Verify item with input_type=Image stored | Image type persisted |

---

#### TC-P08: Create Rubric With 1 Item input_type=Json

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Select template, part, enter code and display_order | Values entered |
| 4 | Add item: html_object_name = `item_json`, ordinal = `1` | Item data |
| 5 | Set input_type = `Json`, output_type = `Json` | Types selected |
| 6 | Set input_level = `{"key":"value"}`, output_level = `{"result":"ok"}` | Levels entered |
| 7 | Submit the form | 201 Created |
| 8 | Verify item with input_type=Json stored | Json type persisted |

---

#### TC-P09: Create Rubric With 5+ Items (Mixed Types)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Select template, part, enter code: `RUBRIC-MIX-01`, display_order: `50` | Base values |
| 4 | Add item 1: html_object_name=`desc_1`, ordinal=1, input_type=Descriptor | Descriptor item |
| 5 | Add item 2: html_object_name=`num_1`, ordinal=2, input_type=Numeric | Numeric item |
| 6 | Add item 3: html_object_name=`grade_1`, ordinal=3, input_type=Grade | Grade item |
| 7 | Add item 4: html_object_name=`text_1`, ordinal=4, input_type=Text | Text item |
| 8 | Add item 5: html_object_name=`bool_1`, ordinal=5, input_type=Boolean | Boolean item |
| 9 | Submit the form | 201 Created |
| 10 | Verify all 5 items created with distinct html_object_name and ordinal | All 5 items in DB |
| 11 | Verify each item has correct input_type | Types match input |

---

#### TC-P10: Create Rubric With section_id = null

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Select template and part | Values selected |
| 4 | Leave section dropdown empty | section_id = null |
| 5 | Enter code: `RUBRIC-NO-SEC`, display_order: `60` | Values entered |
| 6 | Add 1 item with valid data | Item configured |
| 7 | Submit the form | 201 Created |
| 8 | Verify rubric.section_id is NULL in database | Null stored |
| 9 | Verify rubric loads correctly with section relation = null | No relation error |

---

#### TC-P11: Create Rubric With section_id Set to Valid Section

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Select template and part | Values selected |
| 4 | Select a valid section from dropdown | section_id set |
| 5 | Enter code: `RUBRIC-SEC-01`, display_order: `70` | Values entered |
| 6 | Add 1 item with valid data | Item configured |
| 7 | Submit the form | 201 Created |
| 8 | Verify rubric.section_id matches selected section | Linked correctly |
| 9 | Verify rubric->section returns the correct section model | Relation accessible |

---

#### TC-P12: Edit Rubric — Change Code, Description, Display Order

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create rubric with initial values: code=`OLD-RUB`, description=`Original`, display_order=1, section_id=null | Base record |
| 2 | Navigate to edit page `hpc/hpc-template-rubrics/{id}/edit` | Edit form loads with pre-filled data |
| 3 | Change code to `NEW-RUB` | Code updated |
| 4 | Change description to `Updated rubric description` | Description updated |
| 5 | Change display_order to 5 | Order updated |
| 6 | Do not modify items payload | Items unchanged |
| 7 | Submit the form | 200 OK or redirect |
| 8 | Verify rubric.code = `NEW-RUB` in database | Code persisted |
| 9 | Verify rubric.description = `Updated rubric description` | Description persisted |
| 10 | Verify rubric.display_order = 5 | Order persisted |
| 11 | Verify original items remain in hpc_template_rubric_items | Items untouched |

---

#### TC-P13: Edit Rubric — Replace Items (Old Force-Deleted, New Created)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create rubric with 2 items (item_a ordinal=1, item_b ordinal=2) | Base records |
| 2 | Navigate to edit page | Edit form loads with existing items |
| 3 | Remove item_a and item_b from items payload | Old items removed from input |
| 4 | Add 2 new items: item_c (ordinal=1), item_d (ordinal=2) | New items in payload |
| 5 | Submit the form | 200 OK |
| 6 | Verify item_a and item_b have deleted_at set (force-deleted) | Old items soft-deleted |
| 7 | Verify item_c and item_d created with new data | New items exist |

---

#### TC-P14: Edit Rubric — Add More Items to Existing Set

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create rubric with 2 items (ordinals 1, 2) | Base records |
| 2 | Navigate to edit page | Edit form loads |
| 3 | Replace items with 4 items (ordinals 1, 2, 3, 4) | Expanded set |
| 4 | Submit the form | 200 OK |
| 5 | Verify old 2 items force-deleted (deleted_at set) | Old items removed |
| 6 | Verify 4 new items created | New items added |
| 7 | Verify ordinals: 1, 2, 3, 4 all present and distinct | All ordinals correct |

---

#### TC-P15: Create Rubric With input_required=true (Verify Output Auto-Copy)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Select template, part, enter code and display_order | Values entered |
| 4 | Add item: html_object_name=`item_ir`, ordinal=1, input_type=Descriptor | Item data |
| 5 | Set input_required = true | Auto-copy enabled |
| 6 | Set input_level = `Advanced Level`, input_level_numeric = 10 | Input values |
| 7 | Leave output_level and output_level_numeric empty | Will be auto-copied |
| 8 | Submit the form | 201 Created |
| 9 | Verify output_level = `Advanced Level` (auto-copied from input_level) | Auto-copy works |
| 10 | Verify output_level_numeric = 10 (auto-copied from input_level_numeric) | Numeric auto-copy works |

---

#### TC-P16: Create Rubric With input_dropdown Comma-Separated String

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Select template, part, enter code and display_order | Values entered |
| 4 | Add item with input_type=Descriptor | Item configured |
| 5 | Enter input_dropdown = `Option A,Option B,Option C` | Comma-separated string |
| 6 | Submit the form | 201 Created |
| 7 | Verify input_dropdown stored as JSON array: `["Option A","Option B","Option C"]` | Transformed correctly |
| 8 | Verify count of array elements equals 3 | All options preserved |

---

#### TC-P17: Create Rubric With output_dropdown Newline-Separated String

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Select template, part, enter code and display_order | Values entered |
| 4 | Add item with output_type=Descriptor | Item configured |
| 5 | Enter output_dropdown = `Choice 1\nChoice 2\nChoice 3` | Newline-separated string |
| 6 | Submit the form | 201 Created |
| 7 | Verify output_dropdown stored as JSON array: `["Choice 1","Choice 2","Choice 3"]` | Transformed correctly |
| 8 | Verify count of array elements equals 3 | All choices preserved |

---

#### TC-P18: Create Rubric With input_level_numeric Set to Integer

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Select template, part, enter code and display_order | Values entered |
| 4 | Add Numeric-type item | Item configured |
| 5 | Set input_level_numeric = 7, output_level_numeric = 8 | Numeric values |
| 6 | Submit the form | 201 Created |
| 7 | Verify input_level_numeric = 7 in database | Input numeric stored |
| 8 | Verify output_level_numeric = 8 in database | Output numeric stored separately |

---

#### TC-P19: Show Single Rubric Via GET Endpoint

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create rubric with 2 items of different types | Base record |
| 2 | Navigate to `hpc/hpc-template-rubrics/{id}` | Show page loads |
| 3 | Verify rubric code, description, display_order displayed | Rubric details visible |
| 4 | Verify template name, part code, section code displayed | Relations shown |
| 5 | Verify items list shown with all fields: html_object_name, ordinal, input_type, output_type, input_level, output_level | Items displayed with all fields |
| 6 | Verify mandatory, visible, print, is_active badges | Status badges visible |

---

#### TC-P20: Soft Delete Rubric With Items

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create rubric with 2 items | Base record |
| 2 | Navigate to rubric index | Rubric visible in list |
| 3 | Click delete button / send DELETE request | 200 OK or redirect |
| 4 | Verify rubric no longer appears in index list | Removed from default queries |
| 5 | Verify rubric.deleted_at is NOT NULL in database | Soft-deleted |
| 6 | Verify item records also have deleted_at set | Items soft-deleted |
| 7 | Navigate to trash view `hpc/hpc-template-rubrics/trash/view` | Rubric appears in trash list |

---

#### TC-P21: Restore Soft-Deleted Rubric

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a rubric with 2 items | Rubric trashed |
| 2 | Verify rubric appears in trash view | In trash list |
| 3 | Click restore button / send restore request | 200 OK |
| 4 | Verify rubric.deleted_at = NULL in database | Restored |
| 5 | Verify item records deleted_at = NULL | Items restored |
| 6 | Navigate to index | Rubric reappears in list |

---

#### TC-P22: Force Delete Rubric (Permanent)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create rubric with items | Base record |
| 2 | Soft-delete the rubric first | Rubric trashed |
| 3 | Navigate to trash view | Rubric visible |
| 4 | Click force-delete button / send forceDelete request | 200 OK |
| 5 | Verify rubric record permanently removed from database | No record |
| 6 | Verify all item records permanently removed | Items gone |
| 7 | Verify rubric does not appear in index or trash | Completely removed |

---

#### TC-P23: Toggle Status From Active to Inactive

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create rubric with is_active = true | Active rubric |
| 2 | Send toggle-status request to `hpc/hpc-template-rubrics/{id}/toggle-status` | 200 OK, JSON response |
| 3 | Verify JSON response contains new is_active = false | Response indicates inactive |
| 4 | Verify database is_active = 0 | Persisted |

---

#### TC-P24: Toggle Status From Inactive to Active

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create rubric with is_active = false | Inactive rubric |
| 2 | Send toggle-status request | 200 OK |
| 3 | Verify JSON response contains is_active = true | Now active |
| 4 | Verify database is_active = 1 | Persisted |
| 5 | Toggle again and verify it flips back to 0 | Bi-directional toggle |

---

#### TC-P25: Create Rubric With mandatory = true

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Select template, part, enter code and display_order | Values entered |
| 4 | Set mandatory = true | Flag set |
| 5 | Add 1 item with valid data | Item configured |
| 6 | Submit the form | 201 Created |
| 7 | Verify mandatory = 1 in database | Mandatory flag persisted |

---

#### TC-P26: Create Rubric Item With Weight Decimal Value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Select template, part, enter code and display_order | Values entered |
| 4 | Add item with weight = 2.50 | Decimal weight |
| 5 | Submit the form | 201 Created |
| 6 | Verify weight = 2.50 stored in database | Weight persisted |
| 7 | Create another item with weight = 1.75 | Different decimal |
| 8 | Verify weight stored correctly | Decimal precision correct |

---

#### TC-P27: Index Displays Rubrics Sorted By display_order ASC

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 5 rubrics under same section with orders: 0, 1, 2, 3, 4 | Rubrics created |
| 2 | Navigate to index | List loads |
| 3 | Verify order of rows: 0, 1, 2, 3, 4 | Ascending order |
| 4 | Create another rubric with display_order = -1 (if allowed) or 5 | New rubric |
| 5 | Reload index | Correct sort order maintained |

---

#### TC-P28: Create Rubric With Items All Having Distinct html_object_name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Add 3 items with html_object_name: `name_x`, `name_y`, `name_z` | Distinct names |
| 4 | Submit the form | 201 Created |
| 5 | Verify all 3 items stored with their respective html_object_name | All persisted |

---

#### TC-P29: Create Rubric With Items All Having Distinct Ordinal

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Add 3 items with ordinals: 1, 2, 3 | Distinct ordinals |
| 4 | Submit the form | 201 Created |
| 5 | Verify items stored with ordinals 1, 2, 3 | All ordered correctly |

---

#### TC-P30: Trash View Lists All Soft-Deleted Rubrics

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete 3 rubrics with items | 3 trashed records |
| 2 | Navigate to `hpc/hpc-template-rubrics/trash/view` | Trash view loads |
| 3 | Verify all 3 rubrics appear in the list | All visible |
| 4 | Verify each row shows original code, template, part, deleted_at timestamp | Metadata displayed |
| 5 | Verify non-deleted rubrics do not appear | Only trashed shown |
| 6 | Check restore and force-delete buttons available per row | Action buttons present |

---

### 7.2 Negative TC Steps

#### TC-N01: Create — Missing template_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Fill all fields except template_id | template_id omitted |
| 4 | Add 1 valid item | Item configured |
| 5 | Submit the form | Validation error |
| 6 | Verify error: "The template id field is required." | Error displayed |

---

#### TC-N02: Create — Invalid template_id (Non-Existent FK)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Enter template_id = 99999 | Non-existent value |
| 4 | Fill all other required fields + 1 item | Valid data |
| 5 | Submit the form | Validation error |
| 6 | Verify error: "The selected template id is invalid." | FK validation fails |

---

#### TC-N03: Create — Missing part_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Fill all fields except part_id | part_id omitted |
| 4 | Add 1 valid item | Item configured |
| 5 | Submit the form | Validation error |
| 6 | Verify error: "The part id field is required." | Error displayed |

---

#### TC-N04: Create — Invalid part_id (Non-Existent FK)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Enter part_id = 99999 | Non-existent value |
| 4 | Fill all other required fields + 1 item | Valid data |
| 5 | Submit the form | Validation error |
| 6 | Verify error: "The selected part id is invalid." | FK validation fails |

---

#### TC-N05: Create — Invalid section_id (Non-Existent FK)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Enter section_id = 99999 | Non-existent value |
| 4 | Fill all other required fields + 1 item | Valid data |
| 5 | Submit the form | Validation error |
| 6 | Verify error: "The selected section id is invalid." | FK validation fails |

---

#### TC-N06: Create — Items Array Empty (Min:1 Fails)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Fill rubric-level fields (template, part, code, display_order) | Valid rubric data |
| 4 | Submit items as empty array `[]` | No items |
| 5 | Submit the form | Validation error |
| 6 | Verify error: "The items must contain at least 1 items." or similar | Min items validated |

---

#### TC-N07: Create — items.*.input_type Invalid Value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Fill rubric-level fields + 1 item | Item configured |
| 4 | Set input_type = `InvalidType` | Invalid enum value |
| 5 | Submit the form | Validation error |
| 6 | Verify error: "The selected items.0.input type is invalid." | Enum validation |

---

#### TC-N08: Create — items.*.output_type Invalid Value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Fill rubric-level fields + 1 item | Item configured |
| 4 | Set output_type = `BadType` | Invalid enum value |
| 5 | Submit the form | Validation error |
| 6 | Verify error: "The selected items.0.output type is invalid." | Enum validation |

---

#### TC-N09: Create — items.*.ordinal Not Distinct

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Add 2 items both with ordinal = 1 | Non-distinct ordinal |
| 4 | Submit the form | Validation error |
| 5 | Verify error: "The items.0.ordinal has a duplicate." | Distinct validation |

---

#### TC-N10: Create — items.*.html_object_name Not Distinct

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Add 2 items both with html_object_name = `duplicate_name` | Non-distinct names |
| 4 | Submit the form | Validation error |
| 5 | Verify error: "The items.0.html object name has a duplicate." | Distinct validation |

---

#### TC-N11: Create — display_order Duplicate Per section_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create rubric with display_order = 1 under section_id = 5 | First record |
| 2 | Navigate to create form | Create form loads |
| 3 | Select same section_id = 5 | Same section |
| 4 | Enter display_order = 1 | Duplicate value |
| 5 | Add 1 valid item | Item configured |
| 6 | Submit the form | Validation error |
| 7 | Verify error: "The display order has already been taken." | Uniqueness enforced |

---

#### TC-N12: Create — display_order Negative Value

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Enter display_order = -1 | Below minimum |
| 4 | Add 1 valid item | Item configured |
| 5 | Submit the form | Validation error |
| 6 | Verify error: "The display order must be at least 0." | Min value enforced |

---

#### TC-N13: Create — input_level_numeric Negative

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Add Numeric-type item with input_level_numeric = -1 | Negative value |
| 4 | Submit the form | Validation error |
| 5 | Verify error: "The items.0.input level numeric must be at least 0." | Min value enforced |

---

#### TC-N14: Create — Weight Non-Numeric String

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Add item with weight = `abc` | Non-numeric string |
| 4 | Submit the form | Validation error |
| 5 | Verify error: "The items.0.weight must be a number." | Numeric validation |

---

#### TC-N15: Create — items.*.html_object_name Exceeds 50 Chars

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Add item with html_object_name = 51-character string | Exceeds max |
| 4 | Submit the form | Validation error |
| 5 | Verify error: "The items.0.html object name must not be greater than 50 characters." | Max length enforced |

---

#### TC-N16: Create — items.*.input_level Exceeds 255 Chars

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to create form | Create form loads |
| 3 | Add item with input_level = 256-character string | Exceeds max |
| 4 | Submit the form | Validation error |
| 5 | Verify error: "The items.0.input level must not be greater than 255 characters." | Max length enforced |

---

#### TC-N17: Edit — Non-Existent Rubric ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Navigate to `hpc/hpc-template-rubrics/99999/edit` | 404 Not Found |
| 3 | Verify clean 404 page shown | No stack trace |

---

#### TC-N18: Delete — Non-Existent Rubric ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Send DELETE to `hpc/hpc-template-rubrics/99999` | 404 Not Found |
| 3 | Verify clean 404 response | No stack trace |

---

#### TC-N19: Permission Denied — User Without tenant.hpc-template-rubrics.create

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without create permission | Authenticated |
| 2 | Navigate to `hpc/hpc-template-rubrics/create` | 403 Forbidden |
| 3 | Verify user cannot see the create form | Access denied |

---

#### TC-N20: Guest Access Redirect

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout completely | Not authenticated |
| 2 | Navigate to `hpc/hpc-template-rubrics` | Redirected to login page |
| 3 | Navigate to `hpc/hpc-template-rubrics/create` | Redirected to login page |
| 4 | Navigate to `hpc/hpc-template-rubrics/1/edit` | Redirected to login page |

---

### 7.3 Dependency TC Steps

#### TC-D01: SoftDeletes Trait on HpcTemplateRubrics Model

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect HpcTemplateRubrics model file | Uses SoftDeletes trait |
| 2 | Call delete() on a rubric instance | deleted_at column populated |
| 3 | Query rubrics without withTrashed() | Rubric excluded |
| 4 | Query rubrics with withTrashed() | Rubric included |

---

#### TC-D02: SoftDeletes Trait on HpcTemplateRubricItems Model

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect HpcTemplateRubricItems model file | Uses SoftDeletes trait |
| 2 | Soft-delete a parent rubric | Related items get deleted_at |
| 3 | Query items without withTrashed() | Items excluded |
| 4 | Query items with withTrashed() | Items included |

---

#### TC-D03: Restore Cascades to Rubric Items

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a rubric with 3 items | All trashed |
| 2 | Call restore() on the rubric | Rubric restored |
| 3 | Verify all items have deleted_at = NULL | Items restored |

---

#### TC-D04: DB Transaction on ForceDelete — Items Deleted First

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete rubric with items | Trashed |
| 2 | Call forceDelete() on rubric | Force delete executed |
| 3 | Verify hpc_template_rubric_items records permanently deleted | Items gone |
| 4 | Verify rubric record permanently deleted | Rubric gone |

---

#### TC-D05: DB Transaction on Update — Old Items Force-Deleted, New Recreated

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create rubric with 2 items | Base record |
| 2 | Send update request with completely new items payload | Update request |
| 3 | Verify old items have deleted_at set | Force-deleted |
| 4 | Verify new items created with correct data | Recreated |
| 5 | Verify update runs within a DB transaction | Atomic operation |

---

#### TC-D06: input_required=true Auto-Copies output_level From input_level

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create rubric item with input_required=true | Auto-copy enabled |
| 2 | Set input_level = `Custom Level Text`, leave output_level empty | Input set, output empty |
| 3 | Submit the form | 201 Created |
| 4 | Verify output_level = `Custom Level Text` | Auto-copied from input |

---

#### TC-D07: input_required=true Auto-Copies output_level_numeric From input_level_numeric

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create rubric item with input_required=true | Auto-copy enabled |
| 2 | Set input_level_numeric = 15, leave output_level_numeric empty | Numeric input set |
| 3 | Submit the form | 201 Created |
| 4 | Verify output_level_numeric = 15 | Numeric auto-copied |

---

#### TC-D08: input_required=false Preserves Independent Output Values

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create rubric item with input_required=false | Auto-copy disabled |
| 2 | Set input_level = `Input Text`, output_level = `Different Output Text` | Different values |
| 3 | Set input_level_numeric = 5, output_level_numeric = 10 | Different numeric values |
| 4 | Submit the form | 201 Created |
| 5 | Verify output_level = `Different Output Text` (not auto-copied) | Preserved as entered |
| 6 | Verify output_level_numeric = 10 (not auto-copied) | Preserved as entered |

---

#### TC-D09: input_dropdown Comma-Separated String → JSON Array

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect prepareForValidation method in HpcTemplateRubricsRequest | Transformation logic exists |
| 2 | Submit item with input_dropdown = `Red,Green,Blue` | Comma-separated input |
| 3 | Verify stored JSON: `["Red","Green","Blue"]` | Valid JSON array |
| 4 | Verify leading/trailing spaces trimmed | `"Red"` not `" Red "` |

---

#### TC-D10: output_dropdown Newline-Separated String → JSON Array

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect prepareForValidation method | Newline handling |
| 2 | Submit item with output_dropdown = `Cat\nDog\nFish` | Newline-separated |
| 3 | Verify stored JSON: `["Cat","Dog","Fish"]` | Valid JSON array |
| 4 | Mixed separators (comma + newline) also handled | Resilient parsing |

---

#### TC-D11: Arr::only() Filters Extraneous Fields in store()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect store() method in controller | Arr::only() used |
| 2 | Verify allowed fields list includes: template_id, part_id, section_id, code, description, display_order, mandatory, visible, print, is_active | Allowed fields |
| 3 | Submit request with extra field `extra_field=some_value` | Extra field ignored |
| 4 | Verify no error thrown; only allowed fields saved | Filtered correctly |

---

#### TC-D12: display_order Unique Per section_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create rubric with display_order = 1 under section_id = 10 | First record |
| 2 | Attempt to create another rubric with display_order = 1 under same section_id | Validation error |
| 3 | Create rubric with display_order = 1 under a different section_id | Succeeds |

---

#### TC-D13: display_order With section_id = null

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create 2 rubrics with section_id = null, both with display_order = 1 | Same order, no section |
| 2 | Verify both created successfully (unique constraint only when section_id is same) | Allowed |
| 3 | Verify both have section_id = NULL | Null stored |

---

#### TC-D14: FK Constraint — rubric_id in hpc_template_rubric_items

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Attempt to insert item with rubric_id = 99999 | FK violation |
| 2 | Verify database throws integrity constraint error | Error raised |
| 3 | Insert item with valid rubric_id | Insert succeeds |

---

#### TC-D15: FK Cascade — Rubric Deletion Cascades to Items

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create rubric with 3 items | Rubric + items exist |
| 2 | Force-delete the rubric | Rubric removed |
| 3 | Verify all 3 items are also permanently deleted | Cascade delete |

---

#### TC-D16: Activity Log Created on Rubric Creation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a new rubric | Rubric created |
| 2 | Query activity_log table for "Created" event on HpcTemplateRubrics | Log entry exists |
| 3 | Verify log entry contains rubric ID, code, and user info | Metadata present |

---

#### TC-D17: Activity Log Created on Rubric Update

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Update an existing rubric's code and description | Rubric updated |
| 2 | Query activity_log for "Updated" event | Log entry exists |
| 3 | Verify log shows changed fields (code old → new) | Diff captured |

---

#### TC-D18: Activity Log Created on Rubric Deletion

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a rubric | Rubric deleted |
| 2 | Query activity_log for "Deleted" event | Log entry exists |
| 3 | Verify log contains rubric identifier | Deletion logged |

---

#### TC-D19: Activity Log Created on Rubric Restore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Restore a soft-deleted rubric | Rubric restored |
| 2 | Query activity_log for "Restored" event | Log entry exists |
| 3 | Verify log contains rubric ID | Restoration logged |

---

#### TC-D20: Activity Log Created on Force Delete

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Force-delete a trashed rubric | Rubric permanently deleted |
| 2 | Query activity_log for "Force Deleted" event | Log entry exists |
| 3 | Verify log entry records permanent deletion | Force delete logged |

---

#### TC-D21: Activity Log Created on Toggle Status

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Toggle rubric is_active status | Status toggled |
| 2 | Query activity_log for "Toggled" event | Log entry exists |
| 3 | Verify log contains new is_active value | State change logged |

---

#### TC-D22: hasMany Relationship — Rubric Has Many Items

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create rubric with 3 items | Relations set |
| 2 | Call `$rubric->items` | Returns Collection of 3 HpcTemplateRubricItems |
| 3 | Verify items are properly linked via rubric_id | FK reference correct |

---

#### TC-D23: belongsTo Relationship — Rubric Belongs to Template/Part/Section

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create rubric linked to a template, part, and section | Relations set |
| 2 | Call `$rubric->template` | Returns HpcTemplate model with matching ID |
| 3 | Call `$rubric->part` | Returns HpcTemplatePart model with matching ID |
| 4 | Call `$rubric->section` | Returns HpcTemplateSections model with matching ID |
| 5 | Create rubric with section_id = null | section returns null |

---

#### TC-D24: formatResponse Structure Matches Expected Keys

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Call the formatResponse method on a rubric instance | Response array returned |
| 2 | Verify keys: id, code, description, display_order, mandatory, visible, print, is_active | Core fields present |
| 3 | Verify keys: template (object), part (object), section (object or null) | Relation objects present |
| 4 | Verify keys: items (array of objects with all item fields) | Items array present |
| 5 | Verify no unexpected keys in response | Clean response |

---

#### TC-D25: VALID_TYPES Constant Used in Validation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect the validation request file for VALID_TYPES constant | Constant defined |
| 2 | Verify constant contains all 7 types: Descriptor, Numeric, Grade, Text, Boolean, Image, Json | All types present |
| 3 | Submit item with each valid type | All accepted |
| 4 | Submit item with type not in list | Validation error |

---

## 8. CODE-TRACE: Controller Method Execution Traces

### CODE-TRACE-01: `index()` � HpcTemplateRubricsController (Line 21)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplateRubricsController.php:23` | `$this->authorizeHpcIndex()` � calls `Gate::authorize('tenant.hpc.viewAny')` via HpcIndexDataTrait |
| 2 | `HpcIndexDataTrait.php:28-49` | `$this->getHpcIndexData()` � loads sessions, terms, classes, sections, and paginated students |
| 3 | `HpcTemplateRubricsController.php:25` | `return view('hpc::hpc.index', $data)` � renders HPC dashboard/index view |

### CODE-TRACE-02: `create()` � HpcTemplateRubricsController (Line 28)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplateRubricsController.php:30` | `Gate::authorize('tenant.hpc-template-rubrics.create')` |
| 2 | `HpcTemplateRubricsController.php:31` | `HpcTemplateSections::where('is_active', 1)->get()` |
| 3 | `HpcTemplateRubricsController.php:32` | `HpcTemplateParts::where('is_active', 1)->get()` |
| 4 | `HpcTemplateRubricsController.php:33` | `HpcTemplates::where('is_active', 1)->get()` |
| 5 | `HpcTemplateRubricsController.php:34` | `return view('hpc::hpc-template-rubrics.create', compact('templateSections','templateParts','templates'))` |

### CODE-TRACE-03: `store()` � HpcTemplateRubricsController (Line 37)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplateRubricsController.php:39` | `Gate::authorize('tenant.hpc-template-rubrics.create')` |
| 2 | `HpcTemplateRubricsController.php:40` | `$validated = $request->validated()` � validate via FormRequest |
| 3 | `HpcTemplateRubricsController.php:41-52` | `Arr::only($validated, [...])` � extracts only rubric fields (not child items) |
| 4 | `HpcTemplateRubricsController.php:53` | `HpcTemplateRubrics::create($rubricData)` � creates rubric record |
| 5 | `HpcTemplateRubricsController.php:55-59` | Loop: `$rubric->items()->create($item)` for each child item |
| 6 | `HpcTemplateRubricsController.php:61-64` | `activityLog($rubric, 'Created', ['message' => 'HPC Template Rubric created.'])` |
| 7 | `HpcTemplateRubricsController.php:66-67` | `redirect()->route('hpc.hpc.templates')->with('success', flash('created.hpc_template_rubric'))` |

### CODE-TRACE-04: `show()` � HpcTemplateRubricsController (Line 70)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplateRubricsController.php:72` | `Gate::authorize('tenant.hpc-template-rubrics.view')` |
| 2 | `HpcTemplateRubricsController.php:73` | `HpcTemplateRubrics::with(['template','part','section','items'])->findOrFail($id)` � loads 4 relations |
| 3 | `HpcTemplateRubricsController.php:74` | `return view('hpc::hpc-template-rubrics.show', compact('rubric'))` |

### CODE-TRACE-05: `edit()` � HpcTemplateRubricsController (Line 77)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplateRubricsController.php:79` | `Gate::authorize('tenant.hpc-template-rubrics.update')` |
| 2 | `HpcTemplateRubricsController.php:80` | `HpcTemplateRubrics::with('items')->findOrFail($id)` |
| 3 | `HpcTemplateRubricsController.php:81-83` | Loads templateSections, templateParts, templates for dropdowns |
| 4 | `HpcTemplateRubricsController.php:84` | `return view('hpc::hpc-template-rubrics.edit', compact(...))` |

### CODE-TRACE-06: `update()` � HpcTemplateRubricsController (Line 87)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplateRubricsController.php:89` | `Gate::authorize('tenant.hpc-template-rubrics.update')` |
| 2 | `HpcTemplateRubricsController.php:90` | `HpcTemplateRubrics::findOrFail($id)` |
| 3 | `HpcTemplateRubricsController.php:91` | `$original = $rubric->getOriginal()` |
| 4 | `HpcTemplateRubricsController.php:94-105` | `Arr::only($validated, [...])` � extracts rubric fields |
| 5 | `HpcTemplateRubricsController.php:106` | `$rubric->update($rubricData)` |
| 6 | `HpcTemplateRubricsController.php:108` | `$rubric->items()->forceDelete()` � removes old items |
| 7 | `HpcTemplateRubricsController.php:109-113` | Recreates items from input |
| 8 | `HpcTemplateRubricsController.php:115-122` | Change tracking |
| 9 | `HpcTemplateRubricsController.php:124-128` | `activityLog($rubric, 'Updated', ['changes' => $changes])` |
| 10 | `HpcTemplateRubricsController.php:130-131` | `redirect()->route('hpc.hpc.templates')->with('success', flash('updated.hpc_template_rubric'))` |

### CODE-TRACE-07: `destroy()` � HpcTemplateRubricsController (Line 134)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplateRubricsController.php:136` | `Gate::authorize('tenant.hpc-template-rubrics.delete')` |
| 2 | `HpcTemplateRubricsController.php:137` | `HpcTemplateRubrics::findOrFail($id)` |
| 3 | `HpcTemplateRubricsController.php:138` | `$rubric->is_active = false` |
| 4 | `HpcTemplateRubricsController.php:139` | `$rubric->save()` |
| 5 | `HpcTemplateRubricsController.php:140` | `$rubric->delete()` |
| 6 | `HpcTemplateRubricsController.php:142-145` | `activityLog($rubric, 'Deleted', ['message' => 'HPC Template Rubric deleted'])` |
| 7 | `HpcTemplateRubricsController.php:147-148` | `redirect()->route('hpc.hpc.templates')->with('success', flash('deleted.hpc_template_rubric'))` |

### CODE-TRACE-08: `trashed()` � HpcTemplateRubricsController (Line 151)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplateRubricsController.php:153` | `Gate::authorize('tenant.hpc-template-rubrics.restore')` |
| 2 | `HpcTemplateRubricsController.php:154` | `HpcTemplateRubrics::onlyTrashed()->with(['section','part','template','items'])->latest('deleted_at')->paginate(10)` |
| 3 | `HpcTemplateRubricsController.php:155` | `return view('hpc::hpc-template-rubrics.trash', compact('templateRubrics'))` |

### CODE-TRACE-09: `restore()` � HpcTemplateRubricsController (Line 158)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplateRubricsController.php:160` | `Gate::authorize('tenant.hpc-template-rubrics.restore')` |
| 2 | `HpcTemplateRubricsController.php:161` | `HpcTemplateRubrics::onlyTrashed()->findOrFail($id)` |
| 3 | `HpcTemplateRubricsController.php:162` | `$rubric->restore()` |
| 4 | `HpcTemplateRubricsController.php:164-167` | `activityLog($rubric, 'Restored', ['message' => 'HPC Template Rubric restored'])` |
| 5 | `HpcTemplateRubricsController.php:169-170` | `redirect()->route('hpc.hpc.templates')->with('success', flash('restored.hpc_template_rubric'))` |

### CODE-TRACE-10: `forceDelete()` � HpcTemplateRubricsController (Line 173)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplateRubricsController.php:175` | `Gate::authorize('tenant.hpc-template-rubrics.forceDelete')` |
| 2 | `HpcTemplateRubricsController.php:177-179` | `HpcTemplateRubrics::onlyTrashed()->with('items')->findOrFail($id)` |
| 3 | `HpcTemplateRubricsController.php:182` | `$rubric->items()->forceDelete()` � permanently removes child items |
| 4 | `HpcTemplateRubricsController.php:187` | `$rubric->forceDelete()` � permanently removes rubric |
| 5 | `HpcTemplateRubricsController.php:189-192` | `activityLog($rubric, 'Force Deleted', ['message' => 'HPC Template Rubric permanently deleted'])` |
| 6 | `HpcTemplateRubricsController.php:194-195` | `redirect()->route('hpc.hpc.templates')->with('success', flash('force_deleted.hpc_template_rubric'))` |

### CODE-TRACE-11: `toggleStatus()` � HpcTemplateRubricsController (Line 198)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcTemplateRubricsController.php:200` | `Gate::authorize('tenant.hpc-template-rubrics.update')` |
| 2 | `HpcTemplateRubricsController.php:201` | `$request->validate(['is_active' => 'required|boolean'])` |
| 3 | `HpcTemplateRubricsController.php:202` | `HpcTemplateRubrics::withTrashed()->findOrFail($id)` |
| 4 | `HpcTemplateRubricsController.php:203` | `$rubric->is_active = (bool) $request->is_active` |
| 5 | `HpcTemplateRubricsController.php:204` | `$rubric->save()` |
| 6 | `HpcTemplateRubricsController.php:206-209` | `activityLog($rubric, 'Toggled', ['message' => 'HPC Template Rubric status toggled.'])` |
| 7 | `HpcTemplateRubricsController.php:211-215` | `return response()->json(['success' => true, 'is_active' => ..., 'message' => flash('status_updated.hpc_template_rubric')])` |

---
