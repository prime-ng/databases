# tmp_Template_Engine_TcList

## Module: Template → Template Engine → Rendering Service

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | Template (TPL) |
| Tab Group | N/A — Backend Service |
| Features | HTML Rendering (render/renderById), PDF Generation (toPdf), Variable Resolution (data array + DB auto-resolution), Loop Block Expansion, Legacy Marker Translation, Data Provider Integration (MarksheetDataProvider, StudentIdCardDataProvider, TransportStaffIdCardDataProvider), 3-Tier Template Resolution (direct session → fallback JNT session → no session default), Background Image URL replacement |
| URL(s) | N/A — Service Layer (no UI routes) |
| Service Class | `Modules\Template\Services\TemplateEngine` (implements `TemplateEngineInterface`) — stateless singleton |
| Deprecated Wrapper | `TemplateService` (delegates to TemplateEngine) |
| Interface | `TemplateEngineInterface` — `render()`, `renderById()`, `toPdf()` |
| Exceptions | `TemplateNotFoundException` (with `forPurpose()` and `forId()` static constructors), `TemplateRenderException` (with `emptyContent()` and `wrap()` static constructors) |
| Data Providers | MARKSHEET_PRINT → MarksheetDataProvider, STUDENT_ID_CARD → StudentIdCardDataProvider, TRANSPORT_STAFF_ID_CARD → TransportStaffIdCardDataProvider (registered in `config/template.php`) |
| Config | `config('template.providers')` — maps purpose codes to DataProvider classes |
| Soft Deletes | Used — Template, TemplateAssignment, TemplateVariable, TemplatePurpose, TemplateType all use `SoftDeletes`; engine queries explicitly filter `deleted_at IS NULL` |
| Events | None — Engine is a pure service with no event dispatches |

---

## 2. Pre-conditions

- At least one DataProvider class must be registered in `config('template.providers')` for each purpose code used in tests
- Active Template records must exist in `tmp_templates` with non-empty `html_content` and `is_active = 1`
- Active Assignment records must exist in `tmp_template_assignments` linking purposes (via `purpose_id`) to templates with `is_active = 1`
- For 3-tier resolution tests: `tmp_template_assignments` must have records for (class, session), (class, null session), (null class, null session), and fallback JNT session combinations
- For DB auto-resolution tests: records must exist in `std_students`, `std_student_academic_sessions`, `std_student_profiles`, `sch_classes`, `sch_organizations`, `sch_org_academic_sessions_jnt`, `hrs_employees`
- For `toPdf` tests: PDF rendering backend (e.g. DomPDF or similar) must be configured and operational
- For `__BG_URL__` replacement tests: tenant asset URL helper must be resolvable

---

## 3. Default Data Load

### 3.1 Provider Data Loading

The `resolveProviderData(purpose, ids)` method:
- Reads `config('template.providers')` to find a DataProvider class for the given purpose code
- Instantiates the DataProvider and calls `provide(ids)`
- Returns the provider data array
- If no provider is registered for the purpose, returns an empty array (no try/catch for individual provider errors)
- The merged data combines provider data with caller data via `$mergedData = array_merge($providerData, $data)` — caller data wins

### 3.2 Template Resolution — 3-Tier Logic

The `resolveTemplate(purposeCode, classId, sessionId)` method:
- **Tier 1 — Direct session match:** Joins `tmp_template_assignments` (via `purpose_id`) → `tmp_template_purposes` (via `code`), filtering by `class_id`, `academic_session_id`, and `is_active = 1`. Among matches, prefers class-specific over school-wide (null class_id). If a record is found, returns the associated Template (must be active).
- **Tier 2 — Fallback JNT session match:** If no direct match, queries assignments linked through `sch_org_academic_sessions_jnt` (JNT session) for the given class and session. Again prefers class-specific over school-wide.
- **Tier 3 — No session (default):** If neither Tier 1 nor Tier 2 yields a result, queries assignments where `purpose_id` matches and `academic_session_id IS NULL`. Prefers class-specific over school-wide.
- If no template is found after all three tiers, throws `TemplateNotFoundException::forPurpose($purposeCode)`.

### 3.3 Variable Resolution

The `resolveVariables(html, template, data, studentId, employeeId, classId)` method:
- Iterates over all variables defined on the `$template` (Template model relationship)
- For each variable, attempts to resolve from the merged data array first
- If not found in data, calls `resolveFromDb(var, studentId, employeeId, classId)` for DB lookup
- Formats the final value via `formatVariableValue(valueType, raw, name)`
- Missing data for any placeholder results in a blank string (not an error)

### 3.4 Data Providers

| Purpose Code | DataProvider Class | Description |
|-------------|-------------------|-------------|
| MARKSHEET_PRINT | MarksheetDataProvider | Provides marksheet-related data for rendering |
| STUDENT_ID_CARD | StudentIdCardDataProvider | Provides student identity card data |
| TRANSPORT_STAFF_ID_CARD | TransportStaffIdCardDataProvider | Provides transport staff ID card data |

---

## 4. BC-DB — Database Schema

### 4.1 `tmp_templates` — Template Definitions

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| code | VARCHAR(50) | NOT NULL | — | Unique machine code |
| name | VARCHAR(255) | NOT NULL | — | Template name |
| type_id | INT UNSIGNED | NOT NULL | — | FK → tmp_templates_type(id) |
| description | TEXT | YES | NULL | Template description |
| canvas_json | JSON | YES | NULL | Canvas/Template designer state |
| html_content | LONGTEXT | NOT NULL | — | Template HTML with variable placeholders |
| background_image | VARCHAR(255) | YES | NULL | Background image path |
| is_active | TINYINT(1) | YES | 1 | Active flag |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | Update time |
| deleted_at | TIMESTAMP | YES | NULL | Soft delete |

**Indexes:**
- PRIMARY KEY (`id`)
- UNIQUE KEY `uq_tmp_template_code` (`code`)

### 4.2 `tmp_template_assignments` — Purpose-to-Template Mappings

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| template_id | INT UNSIGNED | NOT NULL | — | FK → tmp_templates(id) |
| purpose_id | INT UNSIGNED | NOT NULL | — | FK → tmp_template_purposes(id) |
| academic_session_id | SMALLINT UNSIGNED | YES | NULL | FK → sch_org_academic_sessions_jnt(id) |
| class_id | INT UNSIGNED | YES | NULL | FK → sch_classes(id); null = school-wide |
| class_group_id | INT UNSIGNED | YES | NULL | FK → sch_class_groups_jnt(id); null = school-wide |
| scope_hash | VARCHAR(80) | NOT NULL | GENERATED ALWAYS AS ... STORED | Unique scope fingerprint |
| is_active | TINYINT(1) | YES | 1 | Active flag |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | Update time |
| deleted_at | TIMESTAMP | YES | NULL | Soft delete |

**Indexes:**
- PRIMARY KEY (`id`)
- UNIQUE KEY `uq_tmp_ta_scope_hash` (`scope_hash`)
- KEY `idx_tmp_ta_template` (`template_id`)
- KEY `idx_tmp_ta_purpose` (`purpose_id`)
- KEY `idx_tmp_ta_session` (`academic_session_id`)
- KEY `idx_tmp_ta_class` (`class_id`)
- KEY `idx_tmp_ta_class_group` (`class_group_id`)
- KEY `idx_tmp_ta_purpose_session_class` (`purpose_id`, `academic_session_id`, `class_id`)
- KEY `idx_tmp_ta_purpose_session_group` (`purpose_id`, `academic_session_id`, `class_group_id`)
- KEY `idx_tmp_ta_is_active` (`is_active`)

### 4.3 `tmp_template_variables` — Template Variable Definitions

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| template_type_id | INT UNSIGNED | NOT NULL | — | FK → tmp_templates_type(id) (NOT template_id) |
| name | VARCHAR(255) | NOT NULL | — | Variable placeholder name |
| description | VARCHAR(255) | YES | NULL | Variable description |
| db_name | VARCHAR(100) | YES | NULL | Named DB source (e.g., student alias DB) |
| table_name | VARCHAR(100) | YES | NULL | DB table for auto-resolution |
| field_name | VARCHAR(100) | YES | NULL | DB column for auto-resolution |
| is_active | TINYINT(1) | YES | 1 | Active flag |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | Update time |
| deleted_at | TIMESTAMP | YES | NULL | Soft delete |

**Indexes:**
- PRIMARY KEY (`id`)
- KEY `idx_tmp_var_template_type` (`template_type_id`)
- KEY `idx_tmp_var_name` (`name`)

### 4.4 `tmp_templates_type` — Template Type Definitions

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| name | VARCHAR(30) | NOT NULL | — | Type name |
| description | VARCHAR(255) | YES | NULL | Type description |
| is_active | TINYINT(1) | YES | 1 | Active flag |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | Update time |
| deleted_at | TIMESTAMP | YES | NULL | Soft delete |

**Indexes:**
- PRIMARY KEY (`id`)

### 4.5 `tmp_template_purposes` — Template Purpose Definitions

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| code | VARCHAR(30) | NOT NULL | — | Unique purpose code (e.g. MARKSHEET_PRINT) |
| name | VARCHAR(100) | NOT NULL | — | Purpose display name |
| description | VARCHAR(255) | YES | NULL | Purpose description |
| scope_type_id | INT UNSIGNED | NOT NULL | — | FK → sys_dropdown_table(id) |
| display_order | SMALLINT UNSIGNED | YES | 1 | Sort order |
| is_system | TINYINT(1) | YES | 0 | System-defined flag |
| is_active | TINYINT(1) | YES | 1 | Active flag |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | Update time |
| deleted_at | TIMESTAMP | YES | NULL | Soft delete |

**Indexes:**
- PRIMARY KEY (`id`)
- UNIQUE KEY `uq_tmp_tp_code` (`code`)
- KEY `idx_tmp_tp_scope_type` (`scope_type_id`)
- KEY `idx_tmp_tp_is_active` (`is_active`)

#### Junction: `tmp_templates_variables_jnt` (Template–Variable M:N)

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| template_id | INT UNSIGNED | NOT NULL | — | FK → tmp_templates(id) ON DELETE CASCADE |
| variable_id | INT UNSIGNED | NOT NULL | — | FK → tmp_template_variables(id) ON DELETE CASCADE |
| display_order | INT UNSIGNED | YES | NULL | Display order |
| default_value | VARCHAR(255) | YES | NULL | Default variable value |
| is_active | TINYINT(1) | YES | 1 | Active flag |
| created_at | TIMESTAMP | YES | CURRENT_TIMESTAMP | Creation time |
| updated_at | TIMESTAMP | YES | CURRENT_TIMESTAMP ON UPDATE | Update time |

**Indexes:**
- PRIMARY KEY (`id`)
- FOREIGN KEY `fk_tmp_tv_template` (`template_id`) REFERENCES `tmp_templates`(`id`) ON DELETE CASCADE
- FOREIGN KEY `fk_tmp_tv_variable` (`variable_id`) REFERENCES `tmp_template_variables`(`id`) ON DELETE CASCADE

### 4.6 `std_students` — Student Records (DB Auto-Resolution)

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| first_name | VARCHAR(100) | YES | NULL | Student first name |
| middle_name | VARCHAR(100) | YES | NULL | Student middle name |
| last_name | VARCHAR(100) | YES | NULL | Student last name |
| admission_no | VARCHAR(50) | YES | NULL | Roll/admission number |
| date_of_birth | DATE | YES | NULL | Date of birth |
| gender | VARCHAR(20) | YES | NULL | Gender |
| ... | ... | ... | ... | Additional student fields |

### 4.7 `sch_classes` — Class Records (DB Auto-Resolution)

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| class_name | VARCHAR(100) | NOT NULL | — | Class/grade name |
| section | VARCHAR(50) | YES | NULL | Section name |
| ... | ... | ... | ... | Additional class fields |

### 4.8 `hrs_employees` — Employee Records (DB Auto-Resolution)

| Column | Data Type | Nullable | Default | Notes |
|--------|-----------|----------|---------|-------|
| id | INT UNSIGNED | NOT NULL | AUTO_INCREMENT | Primary Key |
| first_name | VARCHAR(100) | YES | NULL | Employee first name |
| last_name | VARCHAR(100) | YES | NULL | Employee last name |
| employee_code | VARCHAR(50) | YES | NULL | Employee code |
| ... | ... | ... | ... | Additional employee fields |

---

## 5. BC-VAL — Validation Rules

N/A — TemplateEngine is a backend service with no FormRequest or user-input validation. Input validation is handled at the caller/controller level. The engine itself performs no validation of input parameters beyond type hints in the interface signature.

---

## 6. BC-AUTH — Authorization

N/A — TemplateEngine is a backend service with no permission gates or authorization checks. Authorization is handled at the caller level (controllers, jobs, etc.) before calling the engine. The engine itself does not perform any `Gate::authorize()` or policy checks.

---

## 7. BC-BIZ — Business Logic

| BC-BIZ ID | Rule | Description |
|-----------|------|-------------|
| BC-BIZ-01 | Stateless Singleton | TemplateEngine is registered as a singleton; no mutable state is stored between calls — all rendering is self-contained per invocation |
| BC-BIZ-02 | 3-Tier Template Resolution | resolveTemplate() tries direct session match first, then fallback JNT session, then no-session default; throws TemplateNotFoundException if all three tiers fail |
| BC-BIZ-03 | Class-Specific Over School-Wide | Within each resolution tier, assignments with a specific class_id are preferred over null class_id (school-wide) |
| BC-BIZ-04 | Active-Only Filtering | Both tmp_templates.is_active = 1 and tmp_template_assignments.is_active = 1 are enforced; inactive templates or assignments are skipped |
| BC-BIZ-05 | Merged Data Priority | `$mergedData = array_merge($providerData, $data)` — caller-supplied $data overrides provider data on key collision |
| BC-BIZ-06 | Provider Failure Resilience | If resolveProviderData encounters an exception from the DataProvider, the exception is logged and an empty array is returned — rendering continues with caller data only |
| BC-BIZ-07 | Unregistered Provider Graceful Degradation | If no DataProvider is registered for the purpose code, an empty array is returned — rendering continues normally |
| BC-BIZ-08 | Legacy Marker Translation | translateLegacyMarkers() converts SUBJECT_TABLE_START/END → LOOP subjects, EXAM_COLUMNS_START/END → LOOP exam_columns, COSCHO_TABLE_START/END → LOOP coscho_rows before loop expansion |
| BC-BIZ-09 | Loop Block Expansion | expandLoopBlocks() finds `<!-- LOOP: name -->...<!-- ENDLOOP: name -->` blocks and repeats inner content for each item in the matching data array; empty data produces a blank result |
| BC-BIZ-10 | Variable Resolution Chain | Variables are resolved first from merged data array, then from DB (via table_name+field_name or db_name+studentId), formatted by value_type |
| BC-BIZ-11 | Text Value Escaping | formatVariableValue('text', raw) calls `e()` (Laravel htmlspecialchars helper) to escape HTML entities |
| BC-BIZ-12 | HTML Value Pass-Through | formatVariableValue('html', raw) returns the raw value unescaped — trusted HTML content |
| BC-BIZ-13 | Image Value Wrapping | formatVariableValue('image', url) wraps the URL in `<img src="..." />`; empty image URL produces blank string |
| BC-BIZ-14 | Missing Placeholder Graceful Handling | If a variable's value cannot be resolved from data or DB, the placeholder is replaced with a blank string — no error is thrown |
| BC-BIZ-15 | Empty HTML Content Guard | If the template's html_content is empty (after trimming), TemplateRenderException::emptyContent() is thrown |
| BC-BIZ-16 | __BG_URL__ Replacement | The string `__BG_URL__` in template HTML is replaced with the tenant asset URL before rendering |
| BC-BIZ-17 | DB Auto-Resolution Table Matching | fetchColumn() matches table_name against known tables (std_students, std_student_academic_sessions, std_student_profiles, sch_classes, sch_organizations, sch_org_academic_sessions_jnt, hrs_employees) and builds the appropriate WHERE query using the provided ID |
| BC-BIZ-18 | Student Alias Resolution | If a variable has db_name set and studentId is provided, resolveStudentAlias() checks common student field name variations to fetch the value |
| BC-BIZ-20 | toPdf Default Parameters | toPdf() defaults to paperSize='a4' and orientation='portrait' when not explicitly provided |

---

## 8. BC-REF — Referential Integrity

| Foreign Key | Column | References Table | On Delete |
|-------------|--------|-----------------|-----------|
| fk_tmp_assign_template | tmp_template_assignments.template_id | tmp_templates.id | CASCADE |
| fk_tmp_var_template | tmp_template_variables.template_id | tmp_templates.id | CASCADE |
| fk_tmp_assign_class | tmp_template_assignments.class_id | sch_classes.id | SET NULL (implied) |
| fk_tmp_assign_session | tmp_template_assignments.session_id | sch_org_academic_sessions.id | SET NULL (implied) |
| — | tmp_template_variables.table_name | Logical reference (not FK) to std_students, sch_classes, etc. | N/A (string-based) |

---

## 9. Test Case Summary

### 9.1 Template Engine — Positive TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-TPL-P01 | Template Engine | Positive | render() with valid purpose + class + session — direct session match | 5 |
| TC-TPL-P02 | Template Engine | Positive | render() with fallback JNT session match — Tier 2 resolution | 5 |
| TC-TPL-P03 | Template Engine | Positive | render() with no session (default) — Tier 3 resolution | 5 |
| TC-TPL-P04 | Template Engine | Positive | renderById() with valid template ID | 4 |
| TC-TPL-P05 | Template Engine | Positive | toPdf() with default parameters (A4, portrait) | 4 |
| TC-TPL-P06 | Template Engine | Positive | toPdf() with custom paper size and orientation | 4 |
| TC-TPL-P07 | Template Engine | Positive | expandLoopBlocks() — single loop block expansion | 4 |
| TC-TPL-P08 | Template Engine | Positive | expandLoopBlocks() — multiple loop blocks in same template | 4 |
| TC-TPL-P09 | Template Engine | Positive | expandLoopBlocks() — empty data array produces blank output | 3 |
| TC-TPL-P10 | Template Engine | Positive | translateLegacyMarkers() — SUBJECT_TABLE_START/END → LOOP subjects | 2 |
| TC-TPL-P11 | Template Engine | Positive | translateLegacyMarkers() — EXAM_COLUMNS_START/END → LOOP exam_columns | 2 |
| TC-TPL-P12 | Template Engine | Positive | translateLegacyMarkers() — COSCHO_TABLE_START/END → LOOP coscho_rows | 2 |
| TC-TPL-P13 | Template Engine | Positive | resolveVariables() — variable resolved from data array | 3 |
| TC-TPL-P14 | Template Engine | Positive | resolveVariables() — variable resolved from DB (std_students) via table_name+field_name | 4 |
| TC-TPL-P15 | Template Engine | Positive | resolveVariables() — variable resolved from DB (sch_organizations) | 4 |
| TC-TPL-P16 | Template Engine | Positive | resolveVariables() — variable resolved from DB (hrs_employees) | 4 |
| TC-TPL-P17 | Template Engine | Positive | formatVariableValue() — text value escaping via e() | 2 |
| TC-TPL-P18 | Template Engine | Positive | formatVariableValue() — html value pass-through (unescaped) | 2 |
| TC-TPL-P19 | Template Engine | Positive | formatVariableValue() — image url wrapped in img tag | 2 |
| TC-TPL-P20 | Template Engine | Positive | formatVariableValue() — empty image url produces blank string | 2 |
| TC-TPL-P21 | Template Engine | Positive | Caller data overrides provider data on key collision | 4 |
| TC-TPL-P22 | Template Engine | Positive | Provider returns empty data array — rendering continues with caller data | 4 |
| TC-TPL-P23 | Template Engine | Positive | render() with no DataProvider registered for purpose — graceful degradation | 3 |
| TC-TPL-P24 | Template Engine | Positive | render() with provider that throws exception — logged, continues empty | 4 |
| TC-TPL-P25 | Template Engine | Positive | Preview scenario — synthetic data passed directly without provider | 4 |
| TC-TPL-P26 | Template Engine | Positive | __BG_URL__ replacement in rendered HTML output | 3 |
| TC-TPL-P27 | Template Engine | Positive | render() with class-specific assignment preferred over school-wide within same tier | 5 |
| TC-TPL-P29 | Template Engine | Positive | resolveStudentAlias() — variable resolved via db_name + studentId | 3 |
| TC-TPL-P30 | Template Engine | Positive | renderById() with template that has multiple variables of all value types | 4 |
| TC-TPL-P31 | TemplateHtmlNormalizer | Positive | normalize() with typeName='Marksheet' — triggers normalizeMarksheet | 3 |
| TC-TPL-P32 | TemplateHtmlNormalizer | Positive | normalize() with non-Marksheet type — unchanged pass-through | 2 |
| TC-TPL-P33 | TemplateHtmlNormalizer | Positive | wireCommonImagePlaceholders — replaces "Student Photo" span with @{{student_photo}} | 2 |
| TC-TPL-P34 | TemplateHtmlNormalizer | Positive | wireCommonImagePlaceholders — replaces "CBSE Logo" span with @{{school_logo}} | 2 |
| TC-TPL-P35 | TemplateHtmlNormalizer | Positive | wireCommonImagePlaceholders — replaces "School Logo" span with @{{school_logo}} | 2 |
| TC-TPL-P36 | TemplateHtmlNormalizer | Positive | normalizeMarksheet — first table with data rows becomes LOOP block | 3 |
| TC-TPL-P37 | TemplateHtmlNormalizer | Positive | normalizeMarksheet — already has LOOP: subjects (idempotent) | 2 |
| TC-TPL-P38 | TemplateHtmlNormalizer | Positive | normalizeMarksheet — no `&lt;tr&gt;` in middle (no-op — just header) | 2 |
| TC-TPL-P39 | TemplateHtmlNormalizer | Positive | normalizeMarksheet — no `&lt;table&gt;` (unchanged) | 2 |
| TC-TPL-P40 | TemplateHtmlNormalizer | Positive | fillEmptyHeaderCells — all empty `&lt;td&gt;` cells filled with header labels | 2 |
| TC-TPL-P41 | TemplateHtmlNormalizer | Positive | fillEmptyHeaderCells — some cells non-empty (unchanged) | 2 |
| TC-TPL-P42 | TemplateHtmlNormalizer | Positive | wireCommonImagePlaceholders — no matching pattern (unchanged) | 2 |
| TC-TPL-P43 | Template Engine | Positive | resolveFromDb — fetch from std_student_academic_sessions with studentId | 3 |
| TC-TPL-P44 | Template Engine | Positive | resolveFromDb — fetch from std_student_profiles with studentId | 3 |
| TC-TPL-P45 | Template Engine | Positive | resolveFromDb — fetch from sch_classes with classId | 3 |
| TC-TPL-P46 | Template Engine | Positive | resolveFromDb — fetch from sch_org_academic_sessions_jnt (no ID needed) | 3 |
| TC-TPL-P47 | Template Engine | Positive | resolveTemplate — Tier 1b: direct session + school-wide (no class match) | 4 |
| TC-TPL-P48 | Template Engine | Positive | resolveTemplate — Tier 2b: JNT fallback + school-wide (no class match) | 4 |
| TC-TPL-P49 | Template Engine | Positive | resolveTemplate — Tier 3a: no session + class match | 4 |
| TC-TPL-P50 | Template Engine | Positive | resolveTemplate — all tiers exhausted → TemplateNotFoundException | 2 |
| TC-TPL-P51 | Template Engine | Positive | resolveVariables — {{var}} without @ prefix still resolved correctly | 3 |

### 9.2 Template Engine — Negative TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-TPL-N01 | Template Engine | Negative | render() with invalid/unregistered purpose code → TemplateNotFoundException | 2 |
| TC-TPL-N02 | Template Engine | Negative | render() with valid purpose but no assignment for class → TemplateNotFoundException | 2 |
| TC-TPL-N03 | Template Engine | Negative | render() — template exists but is inactive (is_active=0) → skipped, falls to next tier | 3 |
| TC-TPL-N04 | Template Engine | Negative | render() — assignment exists but is inactive (is_active=0) → skipped, falls to next tier | 3 |
| TC-TPL-N05 | Template Engine | Negative | render() — all three resolution tiers exhausted, no match → TemplateNotFoundException | 2 |
| TC-TPL-N06 | Template Engine | Negative | render() — resolved template has empty html_content → TemplateRenderException | 2 |
| TC-TPL-N07 | Template Engine | Negative | renderById() with non-existent template ID → TemplateNotFoundException | 2 |
| TC-TPL-N08 | Template Engine | Negative | renderById() with inactive template ID → TemplateNotFoundException | 2 |
| TC-TPL-N09 | Template Engine | Negative | render() — resolved template empty after trimming whitespace → TemplateRenderException | 2 |
| TC-TPL-N10 | Template Engine | Negative | toPdf() with invalid template resolution → TemplateNotFoundException | 2 |
| TC-TPL-N11 | Template Engine | Negative | toPdf() — resolved template has empty html_content → TemplateRenderException | 2 |
| TC-TPL-N12 | Template Engine | Negative | render() — provider returns data but template references non-existent variable | 3 |
| TC-TPL-N13 | Template Engine | Negative | resolveFromDb — unrecognized table name returns null (default case) | 2 |
| TC-TPL-N14 | Template Engine | Negative | resolveFromDb — db_name not in known student fields returns null | 2 |
| TC-TPL-N15 | Template Engine | Negative | renderById — non-TemplateRenderException caught and wrapped (e.g., malformed data → wrapped) | 3 |
| TC-TPL-N16 | Template Engine | Negative | expandLoopBlocks — LOOP with associative array data (not list) returns '' | 2 |
| TC-TPL-N17 | Template Engine | Negative | expandLoopBlocks — non-array row item skipped (continue) | 2 |

### 9.3 Code Review TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-CR01 | Code Review | Review | resolveTemplate() — 3-tier logic: direct session, JNT fallback, no-session default | 5 |
| TC-CR02 | Code Review | Review | resolveTemplate() — class-specific vs school-wide preference within each tier | 4 |
| TC-CR03 | Code Review | Review | resolveTemplate() — active-only filtering on both assignments and templates | 3 |
| TC-CR04 | Code Review | Review | resolveFromDb() — table_name matching logic against known tables | 4 |
| TC-CR05 | Code Review | Review | fetchColumn() — per-table WHERE queries differ by table (std_students, sch_classes, hrs_employees, etc.) | 5 |
| TC-CR06 | Code Review | Review | fetchColumn() — correct ID parameter used based on table type | 4 |
| TC-CR07 | Code Review | Review | formatVariableValue() — three format types: text→e(), html→raw, image→`&lt;img&gt;` | 4 |
| TC-CR08 | Code Review | Review | expandLoopBlocks() — regex pattern for LOOP/ENDLOOP markers | 4 |
| TC-CR09 | Code Review | Review | translateLegacyMarkers() — all three marker mappings correct | 3 |
| TC-CR10 | Code Review | Review | __BG_URL__ replacement — location and timing in render pipeline | 3 |
| TC-CR11 | Code Review | Review | mergedData priority — array_merge order (provider first, caller second = caller wins) | 3 |
| TC-CR12 | Code Review | Review | Config provider registration — config('template.providers') key structure | 3 |
| TC-CR13 | Code Review | Review | resolveProviderData() — try/catch around DataProvider instantiation and provide() call | 4 |
| TC-CR14 | Code Review | Review | Empty html_content guard — trim check before rendering | 2 |
| TC-CR15 | Code Review | Review | resolveStudentAlias() — common student field name iteration | 3 |
| TC-CR16 | Code Review | Review | renderById() — loads template by ID, validates active, delegates to render pipeline | 3 |
| TC-CR17 | Code Review | Review | toPdf() — parameters mapped through to render() then PDF conversion | 4 |
| TC-CR18 | Code Review | Review | TemplateNotFoundException — forPurpose() and forId() factory methods | 2 |
| TC-CR19 | Code Review | Review | TemplateRenderException — emptyContent() and wrap() factory methods | 2 |
| TC-CR20 | Code Review | Review | Domain-prefixed variable resolution from nested data arrays | 3 |
| TC-CR21 | Code Review | Review | normalize() dispatches by typeName match | 3 |
| TC-CR22 | Code Review | Review | wireCommonImagePlaceholders regex patterns (3 replacements) | 3 |
| TC-CR23 | Code Review | Review | normalizeMarksheet regex — first `&lt;table&gt;` only (limit=1), idempotency | 3 |
| TC-CR24 | Code Review | Review | fillEmptyHeaderCells — allEmpty check before filling | 2 |
| TC-CR25 | Code Review | Review | TemplateService::renderByPurpose() — delegates to TemplateEngine::render() with correct param mapping | 3 |
| TC-CR26 | Code Review | Review | TemplateService::render() — delegates to TemplateEngine::renderById() | 2 |
| TC-CR27 | Code Review | Review | TemplateService — person type routing (student vs employee) | 3 |
| TC-CR28 | Code Review | Review | expandLoopBlocks — case-insensitive flag (/is) on LOOP regex | 2 |
| TC-CR29 | Code Review | Review | Facade\Template — getFacadeAccessor() returns TemplateEngineInterface::class | 2 |

### 9.4 Dependency TCs

| TC ID | Feature | Type | Description | Steps |
|-------|---------|------|-------------|-------|
| TC-D01 | Dependency | Dependency | DataProvider registration — config('template.providers') must be populated for MARKSHEET_PRINT, STUDENT_ID_CARD, TRANSPORT_STAFF_ID_CARD | 3 |
| TC-D02 | Dependency | Dependency | Template active status — is_active=1 enforced at query level | 3 |
| TC-D03 | Dependency | Dependency | Assignment active status — is_active=1 enforced in resolution query | 3 |
| TC-D04 | Dependency | Dependency | DB table existence — std_students, sch_classes, hrs_employees must exist for auto-resolution | 3 |
| TC-D05 | Dependency | Dependency | DB column mapping — field_name must match actual column in referenced table for auto-resolution | 3 |
| TC-D06 | Dependency | Dependency | tmp_template_variables relationship — variables must belong to a template via template_id FK | 3 |
| TC-D07 | Dependency | Dependency | sch_org_academic_sessions_jnt table — required for Tier 2 JNT fallback resolution | 3 |
| TC-D08 | Dependency | Dependency | PDF rendering library — required for toPdf() output | 2 |
| TC-D09 | Dependency | Dependency | Tenant asset URL helper — required for __BG_URL__ replacement | 2 |

---

## 10. Test Case Steps

### 10.1 Positive TC Steps — Template Engine

#### TC-TPL-P01: render() with valid purpose + class + session — direct session match

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Register DataProvider for purpose "MARKSHEET_PRINT" in config | Provider configured |
| 2 | Create active template T with non-empty html_content containing `{{student_name}}` and active assignment A with purpose="MARKSHEET_PRINT", class_id=C, session_id=S | Template + assignment ready |
| 3 | Call `TemplateEngine::render('MARKSHEET_PRINT', ['student_name' => 'John'], null, null, C, S)` | Resolution succeeds at Tier 1 |
| 4 | Verify assignment query: WHERE purpose_code='MARKSHEET_PRINT' AND class_id=C AND session_id=S AND is_active=1 | Direct match query executed |
| 5 | Verify returned HTML contains "John" | Variable resolved correctly |

#### TC-TPL-P02: render() with fallback JNT session match — Tier 2 resolution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active assignment A with purpose="STUDENT_ID_CARD", class_id=C, session_id=S1 (JNT session linked via sch_org_academic_sessions_jnt) | JNT assignment exists |
| 2 | No direct session match available for class_id=C, session_id=S2 (direct match returns empty) | Tier 1 yields nothing |
| 3 | Call `TemplateEngine::render('STUDENT_ID_CARD', data, null, null, C, S2)` | Resolution falls to Tier 2 |
| 4 | Verify query searches sch_org_academic_sessions_jnt for S2 to find linked JNT session | JNT fallback query executed |
| 5 | Verify template is loaded and rendered successfully | Fallback resolution works |

#### TC-TPL-P03: render() with no session (default) — Tier 3 resolution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active assignment A with purpose="TRANSPORT_STAFF_ID_CARD", class_id=C, session_id=NULL | Default (no-session) assignment exists |
| 2 | No direct or JNT fallback match available | Tiers 1 and 2 yield nothing |
| 3 | Call `TemplateEngine::render('TRANSPORT_STAFF_ID_CARD', data, null, null, C, S999)` | Resolution falls to Tier 3 |
| 4 | Verify query: WHERE purpose_code='TRANSPORT_STAFF_ID_CARD' AND session_id IS NULL AND is_active=1 | No-session query executed |
| 5 | Verify template rendered successfully | Default resolution works |

#### TC-TPL-P04: renderById() with valid template ID

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active template T with non-empty html_content and at least one variable | Template exists |
| 2 | Call `TemplateEngine::renderById(T->id, data, studentId, employeeId, classId)` | Loads template by ID |
| 3 | Verify loadTemplate() query: WHERE id=T->id AND is_active=1 | Active check enforced |
| 4 | Verify returned HTML contains resolved variables | Rendering completes |

#### TC-TPL-P05: toPdf() with default parameters (A4, portrait)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active template and assignment for purpose "MARKSHEET_PRINT" | Test data ready |
| 2 | Call `TemplateEngine::toPdf('MARKSHEET_PRINT', data, studentId, employeeId, classId, sessionId, subjectId, extra)` | toPdf with defaults |
| 3 | Verify paperSize and orientation default to 'a4' and 'portrait' internally | Defaults applied |
| 4 | Verify returned output is a valid PDF (starts with %PDF- header) | PDF generated |

#### TC-TPL-P06: toPdf() with custom paper size and orientation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Same setup as TC-TPL-P05 | Test data ready |
| 2 | Call `TemplateEngine::toPdf('MARKSHEET_PRINT', data, ..., paperSize='legal', orientation='landscape')` | Custom params |
| 3 | Verify paperSize='legal' and orientation='landscape' are passed to PDF backend | Params forwarded |
| 4 | Verify generated PDF uses legal/landscape dimensions | Custom output |

#### TC-TPL-P07: expandLoopBlocks() — single loop block expansion

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template HTML contains `<!-- LOOP: items --><p>{{name}}</p><!-- ENDLOOP: items -->` | Loop block present |
| 2 | Data includes `['items' => [['name' => 'A'], ['name' => 'B'], ['name' => 'C']]]` | 3 items in loop data |
| 3 | Call expandLoopBlocks with template HTML and data | Expansion runs |
| 4 | Verify output: `<p>A</p><p>B</p><p>C</p>` (3 iterations) | Loop expanded correctly |

#### TC-TPL-P08: expandLoopBlocks() — multiple loop blocks in same template

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template HTML contains `<!-- LOOP: colors --><span>{{c}}</span><!-- ENDLOOP: colors --><!-- LOOP: sizes --><b>{{s}}</b><!-- ENDLOOP: sizes -->` | Two loop blocks |
| 2 | Data includes colors=[{c: Red}, {c: Blue}] and sizes=[{s: M}, {s: L}] | Two loop datasets |
| 3 | Call expandLoopBlocks with template HTML and data | Expansion runs |
| 4 | Verify output: `<span>Red</span><span>Blue</span><b>M</b><b>L</b>` | Both loops expanded |

#### TC-TPL-P09: expandLoopBlocks() — empty data array produces blank output

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template HTML contains `<!-- LOOP: items --><p>{{name}}</p><!-- ENDLOOP: items -->` | Loop block present |
| 2 | Data includes `['items' => []]` | Empty items array |
| 3 | Verify loop block content is removed, producing blank (empty string) at the loop location | Empty data → blank |

#### TC-TPL-P10: translateLegacyMarkers() — SUBJECT_TABLE_START/END → LOOP subjects

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | HTML contains `SUBJECT_TABLE_START<tr><td>{{sub}}</td></tr>SUBJECT_TABLE_END` | Legacy markers present |
| 2 | Call translateLegacyMarkers(html) | Translation runs |
| 3 | Verify output: `<!-- LOOP: subjects --><tr><td>{{sub}}</td></tr><!-- ENDLOOP: subjects -->` | Correct translation |

#### TC-TPL-P11: translateLegacyMarkers() — EXAM_COLUMNS_START/END → LOOP exam_columns

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | HTML contains `EXAM_COLUMNS_START<td>{{exam}}</td>EXAM_COLUMNS_END` | Legacy markers present |
| 2 | Call translateLegacyMarkers(html) | Translation runs |
| 3 | Verify output: `<!-- LOOP: exam_columns --><td>{{exam}}</td><!-- ENDLOOP: exam_columns -->` | Correct translation |

#### TC-TPL-P12: translateLegacyMarkers() — COSCHO_TABLE_START/END → LOOP coscho_rows

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | HTML contains `COSCHO_TABLE_START<div>{{row}}</div>COSCHO_TABLE_END` | Legacy markers present |
| 2 | Call translateLegacyMarkers(html) | Translation runs |
| 3 | Verify output: `<!-- LOOP: coscho_rows --><div>{{row}}</div><!-- ENDLOOP: coscho_rows -->` | Correct translation |

#### TC-TPL-P13: resolveVariables() — variable resolved from data array

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template has a variable with name="full_name" and value_type="text" | Variable defined on template |
| 2 | Merged data contains `['full_name' => 'Jane Doe']` | Data available |
| 3 | Call resolveVariables with html containing `{{full_name}}`, template, data | Variable resolved from data |
| 4 | Verify output contains "Jane Doe" (escaped via e()) | Data resolution works |

#### TC-TPL-P14: resolveVariables() — variable resolved from DB (std_students) via table_name+field_name

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template has a variable: name="dob", table_name="std_students", field_name="date_of_birth" | DB-resolved variable defined |
| 2 | Student with studentId=42 has date_of_birth="2010-05-15" in std_students | DB record exists |
| 3 | Merged data does NOT contain "dob" key | Not in data array |
| 4 | Call resolveVariables with studentId=42 | Falls to DB resolution |
| 5 | Verify output contains "2010-05-15" | DB auto-resolution works |

#### TC-TPL-P15: resolveVariables() — variable resolved from DB (sch_organizations)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template has a variable: name="org_name", table_name="sch_organizations", field_name="name" | DB-resolved variable defined |
| 2 | Organization record (classId's org) has name="Springfield High" | DB record exists |
| 3 | Merged data does NOT contain "org_name" key | Not in data array |
| 4 | Call resolveVariables with classId=C (org resolved via class → org relationship chain) | Falls to DB resolution |
| 5 | Verify output contains "Springfield High" | Organization resolution works |

#### TC-TPL-P16: resolveVariables() — variable resolved from DB (hrs_employees)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template has a variable: name="emp_name", table_name="hrs_employees", field_name="first_name" | DB-resolved variable defined |
| 2 | Employee with employeeId=7 has first_name="Robert" in hrs_employees | DB record exists |
| 3 | Merged data does NOT contain "emp_name" key | Not in data array |
| 4 | Call resolveVariables with employeeId=7 | Falls to DB resolution |
| 5 | Verify output contains "Robert" | Employee resolution works |

#### TC-TPL-P17: formatVariableValue() — text value escaping via e()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Raw value = `<script>alert('xss')</script>` with value_type="text" | Malicious input |
| 2 | Call formatVariableValue('text', raw, 'some_var') | Text formatting |
| 3 | Verify output = `&lt;script&gt;alert(&#039;xss&#039;)&lt;/script&gt;` (HTML-escaped) | Escaped via e() |

#### TC-TPL-P18: formatVariableValue() — html value pass-through (unescaped)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Raw value = `<strong>Bold</strong>` with value_type="html" | HTML value |
| 2 | Call formatVariableValue('html', raw, 'some_var') | HTML formatting |
| 3 | Verify output = `<strong>Bold</strong>` (returned as-is, unescaped) | Pass-through |

#### TC-TPL-P19: formatVariableValue() — image url wrapped in img tag

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Raw value = `https://example.com/photo.jpg` with value_type="image" | Image URL |
| 2 | Call formatVariableValue('image', raw, 'photo') | Image formatting |
| 3 | Verify output = `<img src="https://example.com/photo.jpg" />` | Wrapped in img tag |

#### TC-TPL-P20: formatVariableValue() — empty image url produces blank string

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Raw value = `` (empty string) with value_type="image" | Empty image URL |
| 2 | Call formatVariableValue('image', raw, 'photo') | Image formatting |
| 3 | Verify output = `` (blank string) | Empty → blank |

#### TC-TPL-P21: Caller data overrides provider data on key collision

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Provider returns `['student_name' => 'ProviderName']` | Provider data |
| 2 | Caller passes `['student_name' => 'CallerName']` | Caller data |
| 3 | Merged data via `array_merge(provider, caller)` = `['student_name' => 'CallerName']` | Caller wins |
| 4 | Verify rendered HTML contains "CallerName" not "ProviderName" | Override confirmed |

#### TC-TPL-P22: Provider returns empty data array — rendering continues with caller data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Provider returns `[]` (empty array) | No provider data |
| 2 | Caller passes `['student_name' => 'John']` | Caller data available |
| 3 | Merged data = `['student_name' => 'John']` | Only caller data |
| 4 | Verify rendered HTML contains "John" | Rendering unaffected |

#### TC-TPL-P23: render() with no DataProvider registered for purpose — graceful degradation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | No provider registered in config('template.providers') for purpose "UNREGISTERED_PURPOSE" | No config entry |
| 2 | Call `TemplateEngine::render('UNREGISTERED_PURPOSE', ['key' => 'val'], ...)` with active template | Render called |
| 3 | Verify resolveProviderData returns empty array, no exception thrown, template rendered with caller data only | Graceful degradation |

#### TC-TPL-P24: render() with provider that throws exception — logged, continues empty

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Provider for purpose "BROKEN_PROVIDER" throws RuntimeException in provide() | Faulty provider |
| 2 | Call render with purpose="BROKEN_PROVIDER" and caller data | Render called |
| 3 | Verify exception is caught and logged (Log::warning or similar) | Exception logged |
| 4 | Verify rendering continues with caller data only — no crash | Resilient |

#### TC-TPL-P25: Preview scenario — synthetic data passed directly without provider

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | No provider registration for this purpose | No provider |
| 2 | Caller passes complete synthetic data `['name' => 'Preview', 'class' => '10A', ...]` | Full caller data |
| 3 | Verify template renders with synthetic data as if real provider data | Preview works |
| 4 | Verify no attempt to instantiate a DataProvider for this purpose | No provider call |

#### TC-TPL-P26: __BG_URL__ replacement in rendered HTML output

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template HTML contains `<div style="background: url(__BG_URL__/bg.png)">` | Background marker |
| 2 | tenant_asset URL helper returns `https://tenant.example.com/assets` | Asset URL |
| 3 | Call render pipeline | __BG_URL__ replacement runs |
| 4 | Verify output contains `<div style="background: url(https://tenant.example.com/assets/bg.png)">` | URL replaced |

#### TC-TPL-P27: render() with class-specific assignment preferred over school-wide within same tier

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create assignment A1: purpose="MARKSHEET_PRINT", class_id=C, session_id=S, template=T1 | Class-specific |
| 2 | Create assignment A2: purpose="MARKSHEET_PRINT", class_id=NULL, session_id=S, template=T2 | School-wide |
| 3 | Call render with class_id=C, session_id=S | Both match Tier 1 |
| 4 | Verify template T1 is selected (class-specific over school-wide) | Class preference |
| 5 | Verify output from T1, not T2 | Correct template chosen |

#### TC-TPL-P28: resolveVariables() — dot-notation variable resolved from nested data array

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template has variable with name="student.first_name" and value_type="text" | Dot-notation var |
| 2 | Merged data contains `['student' => ['first_name' => 'Alice']]` | Nested data |
| 3 | Verify rendered HTML contains "Alice" | Dot-notation resolved |

#### TC-TPL-P29: resolveStudentAlias() — variable resolved via db_name + studentId

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template variable has db_name="student_photo" but no table_name/field_name | Alias-based var |
| 2 | resolveStudentAlias('student_photo', studentId=42) checks common student field names | Alias lookup |
| 3 | Student record has a matching field (e.g., 'photo' or 'photo_url') with value "/photos/42.jpg" | Field found |
| 4 | Verify output contains "/photos/42.jpg" | Alias resolution works |

#### TC-TPL-P30: renderById() with template that has multiple variables of all value types

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template T has variables: name="student_name" (text), name="bio_html" (html), name="photo" (image) | Mixed types |
| 2 | Data provides all three values: "John", "`&lt;p&gt;Bio&lt;/p&gt;`", "https://example.com/p.jpg" | Full data |
| 3 | Call renderById(T->id, data, ...) | Multi-variable render |
| 4 | Verify output: "John" (escaped), `&lt;p&gt;Bio&lt;/p&gt;` (raw), `&lt;img src="https://example.com/p.jpg" /&gt;` (wrapped) | All types formatted |

#### TC-TPL-P31: normalize() with typeName='Marksheet' — triggers normalizeMarksheet

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Pass HTML containing a `<table>` with `<tr>` data rows and typeName='Marksheet' to normalize() | normalize() called |
| 2 | normalize() checks typeName === 'Marksheet' and dispatches to normalizeMarksheet() | normalizeMarksheet invoked |
| 3 | Verify returned HTML has `<!-- LOOP: subjects -->` wrapping the data rows | Marksheet normalization applied |

#### TC-TPL-P32: normalize() with non-Marksheet type — unchanged pass-through

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Pass HTML containing `<table>` rows with typeName='IdCard' to normalize() | normalize() called |
| 2 | Verify normalizeMarksheet is NOT called and HTML is returned unchanged | Pass-through intact |

#### TC-TPL-P33: wireCommonImagePlaceholders — replaces "Student Photo" span with @{{student_photo}}

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Pass HTML containing `<span>Student Photo</span>` to wireCommonImagePlaceholders() | Input with Student Photo |
| 2 | Verify `<span>Student Photo</span>` is replaced with `@{{student_photo}}` | Replacement correct |

#### TC-TPL-P34: wireCommonImagePlaceholders — replaces "CBSE Logo" span with @{{school_logo}}

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Pass HTML containing `<span>CBSE Logo</span>` to wireCommonImagePlaceholders() | Input with CBSE Logo |
| 2 | Verify `<span>CBSE Logo</span>` is replaced with `@{{school_logo}}` | Replacement correct |

#### TC-TPL-P35: wireCommonImagePlaceholders — replaces "School Logo" span with @{{school_logo}}

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Pass HTML containing `<span>School Logo</span>` to wireCommonImagePlaceholders() | Input with School Logo |
| 2 | Verify `<span>School Logo</span>` is replaced with `@{{school_logo}}` | Replacement correct |

#### TC-TPL-P36: normalizeMarksheet — first table with data rows becomes LOOP block

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Pass HTML with `<table>` containing `<tr>` header row and one or more `<tr>` data rows | Table with data rows |
| 2 | normalizeMarksheet wraps only the data rows (not header) in `<!-- LOOP: subjects -->...<!-- ENDLOOP: subjects -->` | LOOP block created |
| 3 | Verify header row remains outside the LOOP block | Header preserved |

#### TC-TPL-P37: normalizeMarksheet — already has LOOP: subjects (idempotent)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Pass HTML that already contains `<!-- LOOP: subjects -->` wrapping data rows | Already normalized |
| 2 | Verify normalizeMarksheet returns HTML unchanged (no double-wrapping) | Idempotent |

#### TC-TPL-P38: normalizeMarksheet — no <tr> in middle (no-op — just header)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Pass HTML with `<table>` containing only a header `<tr>` and no data `<tr>` rows | Header-only table |
| 2 | Verify normalizeMarksheet returns HTML unchanged (no LOOP added) | No-op |

#### TC-TPL-P39: normalizeMarksheet — no `&lt;table&gt;` (unchanged)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Pass HTML with no `&lt;table&gt;` tag at all | No table present |
| 2 | Verify normalizeMarksheet returns HTML completely unchanged | No-op |

#### TC-TPL-P40: fillEmptyHeaderCells — all empty `&lt;td&gt;` cells filled with header labels

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Pass HTML with `&lt;td&gt;&lt;/td&gt;` (empty) cells in header row that follow a non-empty cell | Empty cells present |
| 2 | Verify each empty `&lt;td&gt;` gets the textual content of its preceding non-empty header cell | Cells filled |

#### TC-TPL-P41: fillEmptyHeaderCells — some cells non-empty (unchanged)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Pass HTML with header `&lt;td&gt;` cells already containing text (e.g., "Subject", "Marks") | Non-empty cells |
| 2 | Verify all cells remain unchanged — no filling applied | Unchanged |

#### TC-TPL-P42: wireCommonImagePlaceholders — no matching pattern (unchanged)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Pass HTML with no "Student Photo", "CBSE Logo", or "School Logo" spans | No matches |
| 2 | Verify HTML returned completely unchanged | Unchanged |

#### TC-TPL-P43: resolveFromDb — fetch from std_student_academic_sessions with studentId

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template variable has table_name="std_student_academic_sessions", field_name="session", studentId=42 | DB-resolved variable |
| 2 | Student academic session record for student_id=42 has session="2024-2025" | DB record exists |
| 3 | Call resolveFromDb | Lookup executes |
| 4 | Verify return value is "2024-2025" | Correct value fetched |

#### TC-TPL-P44: resolveFromDb — fetch from std_student_profiles with studentId

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template variable has table_name="std_student_profiles", field_name="mother_tongue", studentId=42 | DB-resolved variable |
| 2 | Student profile for student_id=42 has mother_tongue="Hindi" | DB record exists |
| 3 | Call resolveFromDb | Lookup executes |
| 4 | Verify return value is "Hindi" | Correct value fetched |

#### TC-TPL-P45: resolveFromDb — fetch from sch_classes with classId

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template variable has table_name="sch_classes", field_name="class_name", classId=15 | DB-resolved variable |
| 2 | Class record with id=15 has class_name="10-A" | DB record exists |
| 3 | Call resolveFromDb | Lookup executes |
| 4 | Verify return value is "10-A" | Correct value fetched |

#### TC-TPL-P46: resolveFromDb — fetch from sch_org_academic_sessions_jnt (no ID needed)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template variable has table_name="sch_org_academic_sessions_jnt", field_name="session_name" | DB-resolved variable |
| 2 | Record exists in sch_org_academic_sessions_jnt with session_name="2024-2025" | DB record exists |
| 3 | Call resolveFromDb with no specific ID required | Lookup executes |
| 4 | Verify return value is the session name or relevant field | Correct value fetched |

#### TC-TPL-P47: resolveTemplate — Tier 1b: direct session + school-wide (no class match)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create assignment A1: school-wide (class_id=NULL) with purpose="MARKSHEET_PRINT", session_id=S, template=T1 (active) | School-wide assignment exists |
| 2 | No class-specific assignment exists for purpose="MARKSHEET_PRINT", class_id=C, session_id=S | No class-specific match |
| 3 | Call resolveTemplate('MARKSHEET_PRINT', C, S) | Resolution runs Tier 1 |
| 4 | Verify school-wide assignment A1 is returned (no class-specific to prefer) | School-wide match |

#### TC-TPL-P48: resolveTemplate — Tier 2b: JNT fallback + school-wide (no class match)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create assignment A1: school-wide (class_id=NULL) via JNT session S1, purpose="MARKSHEET_PRINT" | JNT school-wide assignment |
| 2 | No Tier 1 match exists for class=C, session=S2 | Tier 1 empty |
| 3 | No class-specific JNT match exists | No class-specific |
| 4 | Call resolveTemplate('MARKSHEET_PRINT', C, S2) | Resolution runs Tier 2 |
| 5 | Verify school-wide JNT assignment is returned | JNT school-wide match |

#### TC-TPL-P49: resolveTemplate — Tier 3a: no session + class match

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create assignment A1: class-specific (class_id=C), session_id=NULL, purpose="MARKSHEET_PRINT" | Class-specific default |
| 2 | No Tier 1 or Tier 2 match exists | Tiers 1-2 empty |
| 3 | Call resolveTemplate('MARKSHEET_PRINT', C, S999) | Resolution runs Tier 3 |
| 4 | Verify class-specific no-session assignment A1 is returned | Class default match |

#### TC-TPL-P50: resolveTemplate — all tiers exhausted → TemplateNotFoundException

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | No assignments exist for purpose="MARKSHEET_PRINT" at all | No assignments |
| 2 | Call resolveTemplate('MARKSHEET_PRINT', C, S) | All 3 tiers empty |
| 3 | Verify TemplateNotFoundException::forPurpose('MARKSHEET_PRINT') thrown | Exception thrown |

#### TC-TPL-P51: resolveVariables — {{var}} without @ prefix still resolved correctly

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template HTML contains `{{student_name}}` (no @ prefix) | Variable placeholder |
| 2 | Merged data contains `['student_name' => 'John']` | Data available |
| 3 | Call resolveVariables | Resolution runs |
| 4 | Verify `{{student_name}}` is replaced with "John" | Standard syntax works |

### 10.2 Negative TC Steps — Template Engine

#### TC-TPL-N01: render() with invalid/unregistered purpose code → TemplateNotFoundException

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | No assignment exists for purpose="NONEXISTENT_PURPOSE" | No matching assignment |
| 2 | Call `TemplateEngine::render('NONEXISTENT_PURPOSE', data, ...)` | All 3 tiers empty |
| 3 | Verify TemplateNotFoundException is thrown with forPurpose() message | Exception thrown |

#### TC-TPL-N02: render() with valid purpose but no assignment for class → TemplateNotFoundException

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Assignment exists for purpose="MARKSHEET_PRINT" but only for class_id=C1 | Limited scope |
| 2 | Call render with class_id=C2 (no assignment for this class) | No matching assignment |
| 3 | Verify TemplateNotFoundException::forPurpose() thrown | Exception thrown |

#### TC-TPL-N03: render() — template exists but is inactive (is_active=0) → skipped, falls to next tier

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Assignment A1 exists with template T1 (inactive) for purpose="MARKSHEET_PRINT", class=C, session=S | Tier 1 match but T1 inactive |
| 2 | Assignment A2 exists with template T2 (active) for same purpose, JNT fallback | Tier 2 candidate |
| 3 | Verify template T2 is loaded (T1 skipped due to inactive) | Falls through |

#### TC-TPL-N04: render() — assignment exists but is inactive (is_active=0) → skipped, falls to next tier

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Assignment A1 exists with is_active=0 for purpose="MARKSHEET_PRINT", class=C, session=S | Inactive assignment |
| 2 | Assignment A2 exists with is_active=1 for same purpose, no session (default) | Tier 3 candidate |
| 3 | Verify A1 is skipped (inactive) and A2 is used from Tier 3 | Falls through |

#### TC-TPL-N05: render() — all three resolution tiers exhausted, no match → TemplateNotFoundException

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | No assignments at all for purpose="MARKSHEET_PRINT" | No data |
| 2 | Call render with any class/session | Tiers 1, 2, 3 all empty |
| 3 | Verify TemplateNotFoundException::forPurpose() thrown | Exception thrown |

#### TC-TPL-N06: render() — resolved template has empty html_content → TemplateRenderException

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template T has html_content = '' (empty string) | Empty content |
| 2 | Assignment exists pointing to T, all tiers match | Resolution succeeds |
| 3 | Verify TemplateRenderException::emptyContent() thrown | Exception thrown |

#### TC-TPL-N07: renderById() with non-existent template ID → TemplateNotFoundException

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | No template exists with ID=99999 | Non-existent ID |
| 2 | Call `TemplateEngine::renderById(99999, data, ...)` | Load fails |
| 3 | Verify TemplateNotFoundException::forId(99999) thrown | Exception thrown |

#### TC-TPL-N08: renderById() with inactive template ID → TemplateNotFoundException

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template T exists but has is_active=0 | Inactive template |
| 2 | Call `TemplateEngine::renderById(T->id, data, ...)` | Load fails active check |
| 3 | Verify TemplateNotFoundException::forId(T->id) thrown | Exception thrown |

#### TC-TPL-N09: render() — resolved template empty after trimming whitespace → TemplateRenderException

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template T has html_content = "   \n  \t  " (whitespace only) | Whitespace-only content |
| 2 | Resolution succeeds, loads template | Template loaded |
| 3 | Verify trim check detects empty content and throws TemplateRenderException::emptyContent() | Exception thrown |

#### TC-TPL-N10: toPdf() with invalid template resolution → TemplateNotFoundException

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | No assignment exists for purpose="NONEXISTENT" | No resolution |
| 2 | Call `TemplateEngine::toPdf('NONEXISTENT', data, ...)` | Resolution fails |
| 3 | Verify TemplateNotFoundException thrown (same as render) | Exception thrown |

#### TC-TPL-N11: toPdf() — resolved template has empty html_content → TemplateRenderException

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template has empty html_content | Empty content |
| 2 | Resolution succeeds | Template loaded |
| 3 | Verify TemplateRenderException::emptyContent() thrown | Exception thrown |

#### TC-TPL-N12: render() — provider returns data but template references non-existent variable

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template has variable `{{missing_var}}` | Placeholder in HTML |
| 2 | Neither merged data nor DB can resolve it | Unresolvable variable |
| 3 | Verify placeholder is replaced with blank string (not an error) | Graceful blank |

#### TC-TPL-N13: resolveFromDb — unrecognized table name returns null (default case)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template variable has table_name="unknown_table", field_name="anything" | Unknown table |
| 2 | Call resolveFromDb with var config and IDs | Lookup attempted |
| 3 | Verify fetchColumn returns null (default case in switch) | Null returned |

#### TC-TPL-N14: resolveFromDb — db_name not in known student fields returns null

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template variable has db_name="nonexistent_field", studentId=42 | Unknown db_name |
| 2 | Call resolveFromDb | Student alias resolution attempted |
| 3 | Verify resolveStudentAlias returns null (no matching field found) | Null returned |

#### TC-TPL-N15: renderById — non-TemplateRenderException caught and wrapped (e.g., malformed data → wrapped)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create active template with valid html_content | Template exists |
| 2 | Call renderById with data that triggers a RuntimeException during rendering (e.g., malformed data causing loop error) | Error triggered |
| 3 | Verify the RuntimeException is caught and a TemplateRenderException is thrown via wrap() | Wrapped exception |

#### TC-TPL-N16: expandLoopBlocks — LOOP with associative array data (not list) returns ''

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template HTML contains `<!-- LOOP: items --><p>{{val}}</p><!-- ENDLOOP: items -->` | LOOP block |
| 2 | Data `['items' => ['a' => 1, 'b' => 2]]` is an associative (non-list) array | Not a list |
| 3 | Call expandLoopBlocks | Expansion runs |
| 4 | Verify loop block is replaced with blank string (non-list data rejected) | Blank output |

#### TC-TPL-N17: expandLoopBlocks — non-array row item skipped (continue)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template HTML contains `<!-- LOOP: items --><p>{{val}}</p><!-- ENDLOOP: items -->` | LOOP block |
| 2 | Data `['items' => [['val' => 'A'], 'not_an_array', ['val' => 'B']]]` | Mixed array with non-array item |
| 3 | Call expandLoopBlocks | Expansion runs |
| 4 | Verify output is `<p>A</p><p>B</p>` (non-array item skipped without error) | Non-array skipped |

### 10.3 Code Review TC Steps

#### TC-CR01: resolveTemplate() — 3-tier logic: direct session, JNT fallback, no-session default

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review Tier 1 query: assignments WHERE purpose_code=X AND class_id=Y AND session_id=Z AND is_active=1 | Direct session match query |
| 2 | Review Tier 2 query: assignments joined with sch_org_academic_sessions_jnt for fallback session match | JNT fallback query |
| 3 | Review Tier 3 query: assignments WHERE purpose_code=X AND session_id IS NULL AND is_active=1 | No-session default query |
| 4 | Review early return pattern: if Tier 1 finds a match, return immediately; else fall through | Tier cascade |
| 5 | Review final throw: `TemplateNotFoundException::forPurpose($purposeCode)` if all 3 tiers yield nothing | Exception at end |

#### TC-CR02: resolveTemplate() — class-specific vs school-wide preference within each tier

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review ordering within each tier: class-specific (class_id IS NOT NULL) prioritized over school-wide (class_id IS NULL) | Preference ordering |
| 2 | Review how multiple matches are resolved — first or explicit ordering? | Single result selection |
| 3 | Review null-safe handling: class_id can be null in both assignment and input | Null handling |
| 4 | Review edge case: what if class_id IS NULL in input (school-wide request)? | Null input handling |

#### TC-CR03: resolveTemplate() — active-only filtering on both assignments and templates

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$assignment->template` relationship loading — eager or lazy? | Relationship loading |
| 2 | Review active check: `if (!$template || !$template->is_active)` after loading | Template active check |
| 3 | Review assignment active check: `$assignments->where('is_active', 1)` or in query WHERE | Assignment active check |

#### TC-CR04: resolveFromDb() — table_name matching logic against known tables

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review switch/match/case block mapping table_name to known table constants | Table mapping |
| 2 | Review which tables are supported: std_students, std_student_academic_sessions, std_student_profiles, sch_classes, sch_organizations, sch_org_academic_sessions_jnt, hrs_employees | Supported tables |
| 3 | Review fallback for unrecognized table_name — returns null/blank | Unknown table handling |
| 4 | Review how table_name relates to the actual DB query builder table reference | Query table binding |

#### TC-CR05: fetchColumn() — per-table WHERE queries differ by table

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review std_students query: `WHERE id = studentId` selecting field_name | Student query |
| 2 | Review std_student_academic_sessions query: `WHERE student_id = studentId AND ...` (session context) | Academic session query |
| 3 | Review sch_classes query: `WHERE id = classId` selecting field_name | Class query |
| 4 | Review sch_organizations query: resolved via class → org relationship | Org query |
| 5 | Review hrs_employees query: `WHERE id = employeeId` selecting field_name | Employee query |

#### TC-CR06: fetchColumn() — correct ID parameter used based on table type

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review std_students uses studentId parameter | Correct ID for students |
| 2 | Review hrs_employees uses employeeId parameter | Correct ID for employees |
| 3 | Review sch_classes uses classId parameter | Correct ID for classes |
| 4 | Review fallback when required ID is null — returns null/blank | Missing ID handling |

#### TC-CR07: formatVariableValue() — three format types: text→e(), html→raw, image→<img>

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review switch on value_type: 'text' → `e($raw)` | Text escaping |
| 2 | Review 'html' → `$raw` (no escaping, trust assumption) | HTML pass-through |
| 3 | Review 'image' → `<img src="{$raw}" />` with empty URL guard | Image wrapping |
| 4 | Review default case for unknown value_type — returns blank or raw? | Fallback handling |

#### TC-CR08: expandLoopBlocks() — regex pattern for LOOP/ENDLOOP markers

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review regex: pattern to match `<!-- LOOP: name -->...<!-- ENDLOOP: name -->` | Loop regex |
| 2 | Review capture groups: loop name and inner content | Groups captured |
| 3 | Review preg_match_all or preg_replace_callback approach | Execution method |
| 4 | Review iteration: for each match, repeat inner content count($data[$name]) times | Iteration logic |

#### TC-CR09: translateLegacyMarkers() — all three marker mappings correct

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review SUBJECT_TABLE_START replacement → `<!-- LOOP: subjects -->` | Marker 1 start |
| 2 | Review SUBJECT_TABLE_END replacement → `<!-- ENDLOOP: subjects -->` | Marker 1 end |
| 3 | Review EXAM_COLUMNS_START/END → LOOP exam_columns | Marker 2 mapping |
| 4 | Review COSCHO_TABLE_START/END → LOOP coscho_rows | Marker 3 mapping |

#### TC-CR10: __BG_URL__ replacement — location and timing in render pipeline

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review where in render pipeline __BG_URL__ replacement occurs | Pipeline location |
| 2 | Review replacement value: `tenant_asset('')` or similar helper | URL source |
| 3 | Review whether replacement uses str_replace or regex (literal replacement) | Replacement method |

#### TC-CR11: mergedData priority — array_merge order (provider first, caller second = caller wins)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `$mergedData = array_merge($providerData, $data)` | Merge order |
| 2 | Verify array_merge behavior: later keys overwrite earlier ones | PHP merge semantics |
| 3 | Verify both are arrays (not null) before merge — type safety | Defensive check |

#### TC-CR12: Config provider registration — config('template.providers') key structure

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `config('template.providers')` structure: array keyed by purpose code | Config structure |
| 2 | Review how DataProvider class is resolved from config string | Class resolution |
| 3 | Review fallback when config key is missing or null | Missing config handling |

#### TC-CR13: resolveProviderData() — try/catch around DataProvider instantiation and provide() call

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review try/catch wrapping: `try { ... } catch (\Exception $e) { ... }` | Exception handling |
| 2 | Review catch block: logs warning with purpose code and exception message | Logging |
| 3 | Review catch return: empty array `[]` | Graceful return |
| 4 | Review instantiation: `app(DataProvider::class)` or `new DataProvider()` | Instantiation method |

#### TC-CR14: Empty html_content guard — trim check before rendering

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review check: `if (empty(trim($template->html_content)))` | Empty check |
| 2 | Review exception: `throw TemplateRenderException::emptyContent()` | Exception type |

#### TC-CR15: resolveStudentAlias() — common student field name iteration

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review list of common field names checked (e.g., photo, photo_url, image, avatar, etc.) | Field name list |
| 2 | Review iteration: foreach over candidate fields, first non-null match wins | Match logic |
| 3 | Review fallback: if no field matches, returns null/blank | No match fallback |

#### TC-CR16: renderById() — loads template by ID, validates active, delegates to render pipeline

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `Template::findOrFail($templateId)` or custom query | Load by ID |
| 2 | Review active check: `if (!$template->is_active)` | Active validation |
| 3 | Review delegation: calls private/internal render method with template object | Pipeline delegation |

#### TC-CR17: toPdf() — parameters mapped through to render() then PDF conversion

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review parameter forwarding: purpose, data, ids all passed to internal render | Parameter mapping |
| 2 | Review default application: paperSize='a4', orientation='portrait' if not provided | Defaults |
| 3 | Review PDF conversion: DomPDF or similar library call | PDF backend |
| 4 | Review output: returns PDF binary string, not HTML | Return type |

#### TC-CR18: TemplateNotFoundException — forPurpose() and forId() factory methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `forPurpose($purposeCode)` static constructor | Creates exception with purpose message |
| 2 | Review message format: "Template not found for purpose: {purpose}" | Purpose message format |

#### TC-CR19: TemplateRenderException — emptyContent() and wrap() factory methods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review `emptyContent()` static constructor | Creates exception with "empty content" message |
| 2 | Review `wrap($message, $previous)` static constructor | Wraps another exception with context |

#### TC-CR20: Domain-prefixed variable resolution from nested data arrays

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review dot-notation parsing: `student.first_name` → split on '.' | Key parsing |
| 2 | Review nested array access: `$data['student']['first_name']` | Tree traversal |
| 3 | Review fallback: if intermediate key doesn't exist, returns blank | Missing key handling |

#### TC-CR21: normalize() dispatches by typeName match

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review normalize() method signature and body | Method structure |
| 2 | Verify a conditional checks `$typeName === 'Marksheet'` or similar switch | Type check present |
| 3 | Verify when typeName matches, normalizeMarksheet() is called on the HTML | Dispatch correct |
| 4 | Verify when typeName does not match, HTML is returned unchanged | Pass-through correct |

#### TC-CR22: wireCommonImagePlaceholders regex patterns (3 replacements)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review the regex or string replacements for "Student Photo" → @{{student_photo}} | Pattern 1 |
| 2 | Review the regex or string replacements for "CBSE Logo" → @{{school_logo}} | Pattern 2 |
| 3 | Review the regex or string replacements for "School Logo" → @{{school_logo}} | Pattern 3 |

#### TC-CR23: normalizeMarksheet regex — first <table> only (limit=1), idempotency

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review regex for matching `<table>` content — uses limit=1 to target only first table | First table only |
| 2 | Review logic checking for existing `<!-- LOOP: subjects -->` before applying transformation | Idempotency guard |
| 3 | Review behavior when no `<tr>` data rows exist between header and end of table | No-op for header-only tables |

#### TC-CR24: fillEmptyHeaderCells — allEmpty check before filling

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review the check that determines if a `<td>` is empty (no content) | Empty detection |
| 2 | Review the filling logic — copies content from preceding non-empty header cell | Fill logic |

#### TC-CR25: TemplateService::renderByPurpose() — delegates to TemplateEngine::render() with correct param mapping

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review renderByPurpose() method body | Method body |
| 2 | Verify it calls `$this->templateEngine->render(...)` with purpose, data, and other params mapped correctly | Correct delegation |
| 3 | Verify the return value from TemplateEngine::render() is returned as-is | Return pass-through |

#### TC-CR26: TemplateService::render() — delegates to TemplateEngine::renderById()

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review TemplateService::render() method | Method body |
| 2 | Verify it calls `$this->templateEngine->renderById(...)` with template ID and data | Correct delegation |

#### TC-CR27: TemplateService — person type routing (student vs employee)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review routing logic: how personType determines whether to pass studentId or employeeId | Person type routing |
| 2 | Verify when personType='student', studentId is passed and employeeId is null | Student routing |
| 3 | Verify when personType='employee', employeeId is passed and studentId is null | Employee routing |

#### TC-CR28: expandLoopBlocks — case-insensitive flag (/is) on LOOP regex

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review the regex pattern used to match `<!-- LOOP: name -->...<!-- ENDLOOP: name -->` | LOOP regex |
| 2 | Verify the regex uses the `i` (case-insensitive) and `s` (dotall) flags | /is flags present |

#### TC-CR29: Facade\Template — getFacadeAccessor() returns TemplateEngineInterface::class

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review Facade\Template class | Facade class |
| 2 | Verify getFacadeAccessor() returns `TemplateEngineInterface::class` | Correct service key |

### 10.4 Dependency TC Steps

#### TC-D01: DataProvider registration — config('template.providers') populated for all 3 purposes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify `config('template.providers.MARKSHEET_PRINT')` returns MarksheetDataProvider class | MARKSHEET_PRINT registered |
| 2 | Verify `config('template.providers.STUDENT_ID_CARD')` returns StudentIdCardDataProvider class | STUDENT_ID_CARD registered |
| 3 | Verify `config('template.providers.TRANSPORT_STAFF_ID_CARD')` returns TransportStaffIdCardDataProvider class | TRANSPORT_STAFF_ID_CARD registered |

#### TC-D02: Template active status — is_active=1 enforced at query level

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create template with is_active=0, assignment linking to it | Inactive template |
| 2 | Call render for the purpose that matches this assignment | Resolution finds assignment |
| 3 | Verify template is rejected in loadTemplate() due to is_active=0 | Rejected |

#### TC-D03: Assignment active status — is_active=1 enforced in resolution query

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create assignment with is_active=0 linking to an active template | Inactive assignment |
| 2 | Call render for the purpose/class/session that should match this assignment | Resolution runs |
| 3 | Verify assignment is skipped (is_active=0 filtered in query) | Skipped |

#### TC-D04: DB table existence — required tables exist for auto-resolution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify std_students table exists in schema | Students table present |
| 2 | Verify sch_classes and sch_organizations tables exist | Class/org tables present |
| 3 | Verify hrs_employees table exists | Employees table present |

#### TC-D05: DB column mapping — field_name matches actual column in referenced table

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Template variable has table_name='std_students' and field_name='date_of_birth' | Column reference |
| 2 | Verify 'date_of_birth' column exists in std_students table | Column exists |
| 3 | If field_name references non-existent column, fetchColumn returns null → blank in output | Graceful handling |

#### TC-D06: tmp_template_variables relationship — variables belong to a template via template_id FK

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check Template model has `variables()` relationship (hasMany or morphMany) | Relationship defined |
| 2 | Verify template_id FK exists on tmp_template_variables | FK exists |
| 3 | Verify loading template eager-loads variables for resolution loop | Eager loading |

#### TC-D07: sch_org_academic_sessions_jnt table — required for Tier 2 JNT fallback resolution

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify sch_org_academic_sessions_jnt table exists with session_id and jnt_session_id columns | JNT table exists |
| 2 | Verify the relationship query in resolveTemplate correctly joins this table | Join query correct |
| 3 | If table is empty or missing, Tier 2 returns empty set — falls to Tier 3 | Graceful fallback |

#### TC-D08: PDF rendering library — required for toPdf() output

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify DomPDF or similar library is installed (composer.json) | Library present |
| 2 | Verify toPdf() output is a valid PDF binary starting with %PDF- | Valid PDF output |

#### TC-D09: Tenant asset URL helper — required for __BG_URL__ replacement

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify `tenant_asset()` helper function exists globally | Helper present |
| 2 | Verify `__BG_URL__` is replaced with `tenant_asset('')` result before final output | Replacement correct |

---

## 11. Service Method Reference

| Method | Signature | Returns | Exceptions |
|--------|-----------|---------|------------|
| render | render(purpose, data, studentId, employeeId, classId, sessionId, subjectId, extra) | string (HTML) | TemplateNotFoundException, TemplateRenderException |
| renderById | renderById(templateId, data, studentId, employeeId, classId, sessionId) | string (HTML) | TemplateNotFoundException, TemplateRenderException |
| toPdf | toPdf(purpose, data, studentId, employeeId, classId, sessionId, subjectId, extra, paperSize='a4', orientation='portrait') | PDF binary | TemplateNotFoundException, TemplateRenderException |

## 12. Known Issues

| # | Issue | Severity | Details |
|---|-------|----------|---------|
| KI-01 | TemplateEngine is stateless singleton but could hold cached state if properties are accidentally added | **Low** | Currently no mutable state, but developer must ensure no properties are added that persist between calls |
| KI-02 | HTML value type passes through unescaped content — potential XSS if untrusted data reaches a html-typed variable | **Medium** | Trust assumption on html value_type; callers must ensure only trusted content uses value_type='html' |
| KI-03 | Legacy marker translation is a one-way operation — no reverse mapping for debugging | **Info** | Translated HTML cannot be mapped back to original legacy markers |
| KI-04 | No caching on template resolution — each render() call queries the DB for templates, assignments, and variables | **Medium** | No query result caching; repeated calls for the same purpose/class/session re-execute identical queries |
| KI-05 | fetchColumn() uses raw table names as strings — no constant or enum for table references | **Low** | Table names hardcoded as strings; typo risk if new tables added or names change |
| KI-06 | Provider failure wraps in TemplateRenderException — not individually caught or logged at provider level | **Low** | renderById() outer catch catches Throwable and re-throws as TemplateRenderException::wrap(); no individual try/catch around resolveProviderData() |
| KI-07 | TemplateService deprecated but may still be in use — dual code paths | **Low** | Deprecated wrapper still exists, creating confusion about which service to use |
| KI-08 | Dot-notation variable resolution not implemented — variable lookup is flat `$data[$name]` only | **Low** | `student.first_name` looks for literal key `"student.first_name"`, not `$data['student']['first_name']`; nested data must be pre-flattened by caller |

---

## 13. Feature Summary Matrix

| Feature | Method(s) | Key Dependencies | Output |
|---------|-----------|-----------------|--------|
| HTML Render | render() | DataProvider, db: templates/assignments/variables | HTML string |
| Render by ID | renderById() | db: templates/variables | HTML string |
| PDF Generation | toPdf() | render() + PDF library (DomPDF) | PDF binary |
| Loop Expansion | expandLoopBlocks() (private) | Data array with numeric arrays | Modified HTML |
| Legacy Translation | translateLegacyMarkers() (private) | None (string replacement) | Modified HTML |
| Variable Resolution | resolveVariables() (private) | Data array + template variables + DB | Modified HTML |
| DB Auto-Resolution | fetchColumn(), resolveFromDb(), resolveStudentAlias() (private) | DB tables: std_students, sch_classes, hrs_employees, etc. | Scalar value |
| Value Formatting | formatVariableValue() (private) | value_type (text/html/image) | Formatted string |
| Data Provider Integration | resolveProviderData() (private) | config('template.providers') | Data array |
| Template Resolution | resolveTemplate() (private) | db: assignments, sch_org_academic_sessions_jnt | Template model |
| **TC Count** | **Positive: 51 / Negative: 17 / Code Review: 29 / Dependency: 9** | **Total: 106** | |
