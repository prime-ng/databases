# HPC Tab 4: Template Builder

This tab allows administrators to design and manage Holistic Progress Card templates. A template defines the overall structure of a progress card — its pages (called Parts), sections within each page, items within each section, and optional table layouts. Multiple templates can exist for different grade levels (e.g., Preparatory, Foundation, Middle, Secondary).

---

## How It Works

The user sees a list of all available templates. Each row shows the template code, version, title, and the grade levels it applies to. Clicking a template opens the template designer.

The designer has a hierarchical structure. At the top level are **Parts** (pages). Each part has a page number, display order, and a flag indicating whether it contains items or serves only as a container for sections. Below parts are **Sections**, which group related content within a part. Sections also have a display order and an item flag. Below sections are **Section Items**, which are the actual content rows. Each item has an HTML object name for frontend binding, a display label, a print label, and a type (Text, Image, or Table). Items can be individually toggled for screen visibility and print visibility.

When a section item's type is "Table," the user can define the table structure using the **Section Table** sub-screen. This allows configuring individual cells by row and column position, with each cell storing its own value and visibility settings.

The user can create new templates, clone existing ones, add version bumps, and deactivate outdated templates. Each template code can have multiple versions, but only one version is active at a time per code.

---

## Important Business Rules

- A template is uniquely identified by its code and version combination. The same code can have multiple versions, but each version must have a unique code+version pair.
- The applicable_to_grade field stores a JSON array of grade identifiers (e.g., ["1","2","3"] or ["Nur","LKG","UKG"]).
- Parts within a template must have unique page numbers and unique codes. Duplicate page numbers are rejected.
- Parts can optionally contain items. If has_items is 1, the part uses the hpc_template_parts_items table. If 0, the part acts as a pure container for sections.
- Sections within a part must have unique codes and unique display orders.
- Section items have an ordinal that must be unique within their parent section.
- Section items of type "Table" must define their cell data in the hpc_template_section_table table using row_id and column_id coordinates.
- A section can have both items and rubrics at the same time (rubrics are configured in Tab 5).
- Templates use soft delete. Deleting a template cascades deactivation to all its parts, sections, items, and table data.

---

## Database Columns & Behavior

### hpc_templates
- `id` — Primary key. INT AUTO_INCREMENT.
- `code` — Template code, max 50 characters. VARCHAR(50) NOT NULL.
- `version` — Version number of this template. TINYINT UNSIGNED, default 1.
- `title` — Display title. VARCHAR(255) NOT NULL.
- `description` — Optional description. VARCHAR(512). NULL allowed.
- `applicable_to_grade` — JSON array of grade identifiers. JSON NULL.
- `is_active` — Soft enable/disable flag. TINYINT(1), default 1.

### hpc_template_parts
- `id` — Primary key. INT AUTO_INCREMENT.
- `template_id` — FK to hpc_templates. INT UNSIGNED NOT NULL.
- `code` — Unique code within the template. VARCHAR(50) NOT NULL.
- `description` — Optional description. VARCHAR(512). NULL allowed.
- `help_file` — URL or path to a help file for filling this part. VARCHAR(255). NULL allowed.
- `display_order` — Ordering position. TINYINT UNSIGNED, default 1.
- `page_no` — Page number. Must be unique within the template. TINYINT UNSIGNED NOT NULL, default 1.
- `display_page_number` — Whether to show the page number. TINYINT(1), default 1.
- `has_items` — If 1, items from hpc_template_parts_items are used. TINYINT(1), default 1.

### hpc_template_parts_items
- `id` — Primary key. INT AUTO_INCREMENT.
- `part_id` — FK to hpc_template_parts. INT UNSIGNED NOT NULL.
- `ordinal` — Order within the part. Must be unique per part. TINYINT UNSIGNED, default 1.
- `html_object_name` — Frontend binding name. VARCHAR(50) NOT NULL.
- `level_display` — Label shown on screen. VARCHAR(150) NOT NULL.
- `level_print` — Label shown on the printed card. VARCHAR(150) NOT NULL.
- `visible` — Whether visible on screen. TINYINT(1), default 1.
- `print` — Whether visible in print output. TINYINT(1), default 1.

### hpc_template_sections
- `id` — Primary key. INT AUTO_INCREMENT.
- `template_id` — FK to hpc_templates. INT UNSIGNED NOT NULL.
- `part_id` — FK to hpc_template_parts. INT UNSIGNED NOT NULL.
- `code` — Unique code within the part. VARCHAR(50) NOT NULL.
- `description` — Optional description. VARCHAR(512). NULL allowed.
- `display_order` — Order within the part. Unique per part. TINYINT UNSIGNED, default 1.
- `has_items` — If 1, items from hpc_template_section_items are used. TINYINT(1), default 1.

### hpc_template_section_items
- `id` — Primary key. INT AUTO_INCREMENT.
- `section_id` — FK to hpc_template_sections. INT UNSIGNED NOT NULL.
- `html_object_name` — Frontend binding name. VARCHAR(50) NOT NULL.
- `ordinal` — Order within the section. Unique per section. TINYINT UNSIGNED, default 1.
- `level_display` — Label shown on screen. VARCHAR(150) NOT NULL.
- `level_print` — Label shown on the printed card. VARCHAR(150) NOT NULL.
- `section_type` — Content type. ENUM('Text','Image','Table'), default 'Text'.
- `visible` — Whether visible on screen. TINYINT(1), default 1.
- `print` — Whether visible in print output. TINYINT(1), default 1.

### hpc_template_section_table
- `id` — Primary key. INT AUTO_INCREMENT.
- `section_id` — FK to hpc_template_sections. INT UNSIGNED NOT NULL.
- `section_item_id` — FK to hpc_template_section_items. INT UNSIGNED NOT NULL.
- `html_object_name` — Frontend binding name. VARCHAR(50) NOT NULL.
- `row_id` — Row position (0-indexed). TINYINT UNSIGNED, default 0.
- `column_id` — Column position (0-indexed). TINYINT UNSIGNED, default 0.
- `value` — The cell value. VARCHAR(255) NOT NULL.
- `visible` — Whether visible on screen. TINYINT(1), default 1.
- `print` — Whether visible in print output. TINYINT(1), default 1.

---

## Deep Analysis

### Business Workflows & State Machines
- **Hierarchical designer workflow:** Template → Parts (pages) → Sections → Section Items (+ optional Table cells). Each level is created/edited independently but visually rendered as a nested tree. Changes at a parent level (e.g., deleting a part) cascade to all children.
- **Versioning lifecycle:** A template is uniquely identified by (`code`, `version`). The same `code` can have multiple versions, but only one version can be active at a time per code. Cloning a template creates a new version with an incremented version number.
- **Part/Section dual-mode design:** Each part and section has a `has_items` flag. When `has_items=1`, items are used directly on that part/section. When `has_items=0`, the part/section acts as a container for the next level down. This creates two rendering modes that the designer UI must enforce.
- **Print-vs-Screen dual visibility:** Every item and table cell has independent `visible` (screen) and `print` flags. This enables designs where certain elements appear only during data entry and others only on the printed card.

### Validation Rules & Edge Cases
- **Unique constraints per template:** Parts must have unique `page_no` and unique `code` within a template. Sections must have unique `code` and `display_order` within a part. Items must have unique `ordinal` within their parent section or part.
- **Table cell coordinate system:** `row_id` and `column_id` are 0-indexed. The unique constraint is on (`section_id`, `row_id`, `column_id`). No two cells can share the same coordinates. Gaps in coordinates (e.g., row 0, row 2 with no row 1) are allowed but may render oddly.
- **Grade targeting:** `applicable_to_grade` is a JSON array. If the JSON is malformed or empty, the template is not shown when selecting templates for a grade. Must validate JSON structure on save.
- **Empty template state:** A template can exist with zero parts. The designer shows an empty canvas with an "Add Part" button.
- **Deep hierarchy deletion:** Deleting a template must cascade-deactivate all parts, sections, items, and table cells. The DDL uses `ON DELETE` referential actions; the application must ensure soft deletes propagate.

### Integration Points
- **`hpc_templates`** — Referenced by `hpc_reports` (Tab 8) and `hpc_template_rubrics` (Tab 5). Changing a template affects all reports and rubrics that depend on it.
- **`hpc_template_rubrics`** — Rubrics are attached to a template and optionally to a part/section. The rubric configuration in Tab 5 depends on the template structure defined here.
- **`hpc_reports`** — When a report is generated, the report items structure mirrors the template's rubric items. Template changes after report generation do not retroactively update existing reports.

### Permissions Matrix
| Action | Teacher | Class Teacher | Principal | Admin |
|---|---|---|---|---|
| View templates | ✅ | ✅ | ✅ | ✅ |
| Create template | ❌ | ❌ | ✅ | ✅ |
| Edit template structure | ❌ | ❌ | ✅ | ✅ |
| Clone / version bump | ❌ | ❌ | ✅ | ✅ |
| Add/edit parts/sections | ❌ | ❌ | ✅ | ✅ |
| Configure table cells | ❌ | ❌ | ✅ | ✅ |
| Delete template | ❌ | ❌ | ❌ | ✅ |
