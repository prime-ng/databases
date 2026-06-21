# HPC Tab 5: Rubric Configuration

This tab manages the rubric definitions used within HPC templates. A rubric is a scoring guide used to evaluate student performance against specific criteria. Rubrics are attached to a template and optionally to a specific part or section. Each rubric contains multiple rubric items that define the input levels (what the teacher selects) and output levels (what appears on the report card).

---

## How It Works

The user begins by selecting a template from the dropdown. The screen then shows all rubrics defined for that template. Each rubric row displays its code, description, whether it is mandatory, and its display order within the template. Rubrics can be associated with a specific part and section, or left at the template level for global use.

Clicking a rubric opens the rubric item configuration panel. Here, the user defines the individual assessment levels. Each rubric item has:
- An **input type** — how the evaluator enters data (Descriptor, Numeric, Grade, Text, Boolean, Image, or JSON).
- An **output type** — how the data is displayed on the final report (same options).
- An **input level** label (e.g., "Excellent," "Good," "Developing," "Needs Support").
- An **output level** label (which may differ from the input level for parent-friendly language).
- Optional numeric equivalents (e.g., 4 = Excellent, 3 = Good).
- A weight value for weighted scoring calculations.

The user can add multiple rubric items to a single rubric, creating a complete scoring scale. The items are ordered by ordinal. The configuration also lets the user decide whether to display the input label or the numeric value on screen and in print output.

---

## Important Business Rules

- A rubric must belong to a template. It may optionally belong to a part and/or section.
- The display_order of rubrics must be unique within the same section. If no section is assigned, order is unique within the template.
- Each rubric item must have a unique input_level within its parent rubric.
- The input_type and output_type define what kind of data is captured and displayed. They can be different — for example, input as Numeric (4, 3, 2, 1) and output as Descriptor ("Excellent," "Good," etc.).
- If input_required is 1, the evaluator must provide a value for this rubric item before the evaluation can be saved.
- Weight values are decimal and can be NULL. When NULL, no weighting is applied in calculations.
- The display_input_label flag determines whether the label or the numeric value is shown on screen during data entry. The print_output_label flag controls the same for printed reports.
- Rubrics and their items support soft delete. Deleting a rubric cascades to its items.

---

## Database Columns & Behavior

### hpc_template_rubrics
- `id` — Primary key. INT AUTO_INCREMENT.
- `template_id` — FK to hpc_templates. INT UNSIGNED NOT NULL.
- `part_id` — FK to hpc_template_parts. INT UNSIGNED NOT NULL.
- `section_id` — Optional FK to hpc_template_sections. Can be NULL for template-level rubrics. INT UNSIGNED.
- `display_order` — Ordering position. Unique per section or template. SMALLINT UNSIGNED, default 0.
- `code` — Optional rubric code. VARCHAR(50). NULL allowed.
- `description` — Optional description. VARCHAR(512). NULL allowed.
- `mandatory` — Whether this rubric must be filled. TINYINT(1), default 0.
- `visible` — Whether visible on screen. TINYINT(1), default 1.
- `print` — Whether visible in print output. TINYINT(1), default 1.
- `is_active` — Soft enable/disable flag. TINYINT(1), default 1.

### hpc_template_rubric_items
- `id` — Primary key. INT UNSIGNED AUTO_INCREMENT.
- `rubric_id` — FK to hpc_template_rubrics. INT UNSIGNED NOT NULL.
- `html_object_name` — Frontend binding name. VARCHAR(50) NOT NULL.
- `ordinal` — Order within the rubric. TINYINT UNSIGNED, default 1.
- `input_required` — Whether input is mandatory. TINYINT(1), default 1.
- `input_type` — Data entry type. ENUM('Descriptor','Numeric','Grade','Text','Boolean','Image','Json'), default 'Descriptor'.
- `output_type` — Report display type. ENUM same options, default 'Descriptor'.
- `input_level` — Label for the input value (e.g., "Excellent"). VARCHAR(255) NOT NULL.
- `output_level` — Label for the output value. VARCHAR(255) NOT NULL.
- `input_level_numeric` — Numeric equivalent for input (e.g., 4). INT UNSIGNED. NULL allowed.
- `output_level_numeric` — Numeric equivalent for output. INT UNSIGNED. NULL allowed.
- `display_input_label` — If 1, show input_level on screen; if 0, show numeric value. TINYINT(1), default 0.
- `print_output_label` — If 1, show output_level on print; if 0, show numeric value. TINYINT(1), default 0.
- `weight` — Decimal weight for scoring. DECIMAL(8,3). NULL allowed.
- `description` — Optional description of this rubric item. VARCHAR(255). NULL allowed.
- `is_active` — Soft enable/disable flag. TINYINT(1), default 1.

---

## Deep Analysis

### Business Workflows & State Machines
- **Rubric assignment workflow:** Rubrics are created within a template context. They can be scoped to a specific part + section, or left at the template level for global use across all parts/sections. The scope determines where the rubric appears during evaluation.
- **Input-to-Output transformation:** Each rubric item has an `input_type` (what the teacher selects) and an `output_type` (what appears on the report). These can differ — e.g., teacher inputs a numeric grade (1-4) but the report shows a descriptor ("Excellent"). The system stores both and applies transformation logic at render time.
- **Weighted scoring calculation:** Each rubric item has a `weight` decimal. When evaluating, the system can calculate a weighted score across all rubric items in a rubric. If `weight` is NULL for all items, no weighting is applied (simple average or sum).
- **Mandatory enforcement:** If `mandatory=1` on a rubric, the evaluator must fill in at least one rubric item for that rubric before the evaluation can be saved or marked complete.

### Validation Rules & Edge Cases
- **Unique display_order per scope:** `display_order` must be unique within the same section. If `section_id` is NULL, uniqueness is scoped to the template level. Mixing section-scoped and template-scoped rubrics can cause ordering conflicts.
- **Unique input_level per rubric:** Each rubric item must have a unique `input_level` within its parent rubric. Duplicate levels (e.g., two "Excellent" entries) are rejected.
- **Input/Output type mismatch handling:** If `input_type` is "Numeric" and `output_type` is "Descriptor", the system must have a mapping table or transformation rule to convert numbers to labels. If no mapping exists for a given numeric value, the output could be NULL.
- **Display vs. Print label control:** `display_input_label=0` means show the numeric value on screen instead of the label. `print_output_label=0` means show the numeric value on print instead of the label. These are independent and can be toggled per item.
- **Minimal rubric:** A rubric can exist with zero rubric items. In this case, it appears in the evaluation UI as an empty container and the evaluator cannot provide input.

### Integration Points
- **`hpc_templates`** — Rubrics are always associated with a template. Deleting a template cascades to its rubrics.
- **`hpc_template_parts`, `hpc_template_sections`** — Optional FKs for scoping. If a part or section is deleted, the rubric loses its scope and defaults to template-level.
- **`hpc_report_items`** (Tab 8) — When a report is generated, each rubric item becomes a report item with its input/output values. Rubric changes after report generation do not update existing report items.
- **`hpc_student_evaluation`** (Tab 6) — Evaluation dropdowns are populated from rubric items' `input_level` values for the selected template.

### Permissions Matrix
| Action | Teacher | Class Teacher | Principal | Admin |
|---|---|---|---|---|
| View rubrics | ✅ | ✅ | ✅ | ✅ |
| Create rubric | ❌ | ❌ | ✅ | ✅ |
| Edit rubric items | ❌ | ❌ | ✅ | ✅ |
| Configure input/output types | ❌ | ❌ | ✅ | ✅ |
| Set weight values | ❌ | ❌ | ✅ | ✅ |
| Delete rubric | ❌ | ❌ | ❌ | ✅ |
