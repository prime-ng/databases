# HPC Tab 8: Report Generation

This tab handles the generation and management of Holistic Progress Card reports for individual students. A report is a complete assessment document that pulls together evaluations from multiple subjects, competencies, and ability parameters into a structured output based on a chosen template. Reports go through a lifecycle from Draft to Final to Published to Archived.

---

## How It Works

The user starts by selecting filters: Academic Session, Term, Class, and Section. The screen then shows a list of students in that section. Next to each student name, a "Generate Report" button is available if the student does not already have a report for the selected session and term.

Clicking "Generate Report" creates a new report record in Draft status using the default template for that grade level. The report pulls all existing evaluation data for that student into the report items table, mapping each rubric item from the template to the corresponding evaluation value. If the template includes table sections, the report table data is also populated.

Once generated, the report appears in the list with its status (Draft). The user can click "Edit" to modify individual report items — for example, adjusting the output value or adding remarks. When editing, the screen shows all rubric items grouped by rubric, part, and section, matching the template structure.

The user can preview the report as it would appear in print. After review, the user can change the status from Draft to Final, then to Published. A Published report is visible to parents/guardians through the student portal. Reports can also be Archived when they are no longer current.

The report list shows all existing reports for the selected filters with their current status, the template used, the prepared-by name, and the report date. Users can filter by status to see only Draft, Final, Published, or Archived reports.

---

## Important Business Rules

- Only one report can exist per academic session + term + student combination. Duplicate generation is prevented by a unique constraint.
- A report must reference an existing template. The template determines the report structure.
- The report_date is set to the current date when the report is first generated. It is not auto-updated on subsequent edits.
- The prepared_by field captures the logged-in user who generated the report.
- A Draft report can be edited freely. A Final report requires a status change back to Draft before editing. Published and Archived reports are read-only.
- Status transitions follow this order: Draft → Final → Published → Archived. A Published report can be moved back to Draft only by an Administrator.
- When a report is Published, the related student snapshot (hpc_student_hpc_snapshot) is regenerated to reflect the latest published data.
- Archiving a report does not delete it. Archived reports are hidden from the default view but can be retrieved by toggling a filter.
- Teachers can only generate reports for students in their assigned classes and sections. Administrators can generate reports for any student.

---

## Database Columns & Behavior

### hpc_reports
- `id` — Primary key. INT AUTO_INCREMENT.
- `academic_session_id` — FK to std_student_academic_sessions. INT UNSIGNED NOT NULL.
- `term_id` — FK to cbse_terms or sch_academic_term. INT UNSIGNED NOT NULL.
- `student_id` — FK to std_students. INT UNSIGNED NOT NULL.
- `class_id` — FK to sch_classes. INT UNSIGNED NOT NULL.
- `section_id` — FK to sch_sections. INT UNSIGNED NOT NULL.
- `template_id` — FK to hpc_templates. Determines the report structure. INT UNSIGNED NOT NULL.
- `prepared_by` — FK to sys_users. The user who generated the report. INT UNSIGNED. NULL allowed.
- `report_date` — Date of generation. Set once on creation. DATE NOT NULL.
- `status` — Lifecycle status. ENUM('Draft','Final','Published','Archived'), default 'Draft'.
- `created_at` — Record creation timestamp. TIMESTAMP.
- `updated_at` — Record update timestamp. TIMESTAMP.
- `deleted_at` — Soft delete timestamp. TIMESTAMP.

### hpc_report_items
- `id` — Primary key. BIGINT AUTO_INCREMENT.
- `report_id` — FK to hpc_reports. INT UNSIGNED NOT NULL.
- `template_id` — FK to hpc_templates. INT UNSIGNED NOT NULL.
- `rubric_id` — FK to hpc_template_rubrics. INT UNSIGNED NOT NULL.
- `rubric_item_id` — FK to hpc_template_rubric_items. INT UNSIGNED. NULL allowed.
- `in_numeric_value` — Input numeric value. DECIMAL(10,3). NULL allowed.
- `in_text_value` — Input text value. VARCHAR(512). NULL allowed.
- `in_boolean_value` — Input boolean value. TINYINT(1). NULL allowed.
- `in_selected_value` — Input categorical/descriptor value. VARCHAR(100). NULL allowed.
- `in_image_path` — Input image path. VARCHAR(255). NULL allowed.
- `in_filename` — Input file name. VARCHAR(100). NULL allowed.
- `in_filepath` — Input file path. VARCHAR(255). NULL allowed.
- `in_json_value` — Input JSON (table data). JSON. NULL allowed.
- `out_numeric_value` — Output numeric value. DECIMAL(10,3). NULL allowed.
- `out_text_value` — Output text value. VARCHAR(512). NULL allowed.
- `out_boolean_value` — Output boolean value. TINYINT(1). NULL allowed.
- `out_selected_value` — Output categorical/descriptor value. VARCHAR(100). NULL allowed.
- `out_image_path` — Output image path. VARCHAR(255). NULL allowed.
- `out_filename` — Output file name. VARCHAR(100). NULL allowed.
- `out_filepath` — Output file path. VARCHAR(255). NULL allowed.
- `out_json_value` — Output JSON (table data). JSON. NULL allowed.
- `remark` — Assessment remarks. TEXT. NULL allowed.
- `assessed_by` — FK to sys_users. INT UNSIGNED. NULL allowed.
- `assessed_at` — Assessment timestamp. TIMESTAMP. NULL allowed.

### hpc_report_table
- `id` — Primary key. INT AUTO_INCREMENT.
- `report_id` — FK to hpc_reports. INT UNSIGNED NOT NULL.
- `section_id` — FK to hpc_template_sections. INT UNSIGNED NOT NULL.
- `row_id` — Row position. TINYINT UNSIGNED, default 0.
- `column_id` — Column position. TINYINT UNSIGNED, default 0.
- `value` — Cell value. VARCHAR(255) NOT NULL.
- `visible` — Whether visible on screen. TINYINT(1), default 1.
- `print` — Whether visible in print output. TINYINT(1), default 1.
- `is_active` — Soft enable/disable flag. TINYINT(1), default 1.

---

## Deep Analysis

### Business Workflows & State Machines
- **Report lifecycle state machine:** Draft → Final → Published → Archived. Each transition is unidirectional by default except:
  - Published → Draft (Admin-only rollback)
  - Final → Draft (any user with edit permission)
  - Archived → Published (Admin-only restore)
- **Generation workflow:** User selects filters → student list loads → "Generate Report" creates a Draft report by cloning template structure into `hpc_report_items` and `hpc_report_table`. Evaluation data from Tab 6 is mapped to rubric items.
- **Snapshot regeneration trigger:** When a report transitions to Published, a backend job regenerates `hpc_student_hpc_snapshot` for that student to reflect the latest published data. This is a critical integration point.
- **Edit-in-Draft workflow:** Only Draft reports are editable. Final reports must be moved back to Draft before editing. Published/Archived reports are read-only. The edit screen mirrors the template's rubric structure grouped by part → section → rubric → item.

### Validation Rules & Edge Cases
- **One-report-per-student-term constraint:** Unique constraint on (`academic_session_id`, `term_id`, `student_id`). If a report already exists, "Generate Report" is disabled and replaced with "Edit Report."
- **Template requirement:** A report cannot exist without a valid template. If the template is deleted after report generation, the report becomes orphaned. The UI should show a warning: "Template no longer available."
- **Status transition guard:** Status changes must follow the defined lifecycle. Attempting to skip from Draft to Published directly (bypassing Final) should be rejected.
- **Report date immutability:** `report_date` is set once on generation and never updated. This means the report always shows the original generation date, even after edits.
- **Prepared-by auto-capture:** `prepared_by` is set to the currently logged-in user. If the generating user's account is later deactivated, the report still shows their name.
- **Archived report visibility:** Archived reports are hidden from the default list. A toggle filter "Show Archived" must be explicitly enabled to see them.

### Integration Points
- **`hpc_templates`** — The template defines the structure of report items and table data. Template changes do not retroactively modify existing reports.
- **`hpc_template_rubrics` / `hpc_template_rubric_items`** — Each rubric item in the template becomes a row in `hpc_report_items`. The polymorphic value fields (`in_*`, `out_*`) store the evaluation data.
- **`hpc_student_evaluation`** (Tab 6) — Source data for report items. When a report is regenerated, the latest evaluation values are pulled.
- **`hpc_student_hpc_snapshot`** — Regenerated when a report is Published. This feeds the Dashboard (Tab 1).
- **`std_student_academic_sessions`, `cbse_terms`** — Foreign key dependencies. If a term is deleted, the report becomes unlinked.
- **Student/Parent portal** — Published reports are visible to parents. The portal application reads `hpc_reports` where `status = 'Published'`.

### Permissions Matrix
| Action | Teacher | Class Teacher | Principal | Admin |
|---|---|---|---|---|
| View report list | Own class only | Own class only | All | All |
| Generate report | Own class only | Own class only | ✅ | ✅ |
| Edit Draft report | Own only | Own class only | All | All |
| Change Draft → Final | ❌ | ✅ | ✅ | ✅ |
| Change Final → Published | ❌ | ❌ | ✅ | ✅ |
| Change Published → Archived | ❌ | ❌ | ✅ | ✅ |
| Rollback Published → Draft | ❌ | ❌ | ❌ | ✅ |
| View Archived reports | ❌ | ❌ | ✅ | ✅ |
| Delete report (soft) | ❌ | ❌ | ❌ | ✅ |
