# MarksheetGeneration Module — Gap Analysis: DDL vs Forms/Views

**Date:** 2026-04-19  
**Source DDL:** `MSG_DDL_v1.sql` (22 tables + 1 audit table)  
**Forms:** 18 FormRequests in `Modules/MarksheetGeneration/app/Http/Requests/`  
**Views:** 22 modal views + 10 full-page create/edit views

---

## Fixes Applied (2026-05-29)

The following gaps identified in this analysis have been resolved:

| # | Table | Fix Applied |
|---|-------|-------------|
| 1 | `msh_ia_component_types` | Full CRUD created — `IaComponentTypeRequest`, Controller, modal views, create/edit/show views, config tab, permissions, routes |
| 2 | `msh_student_results` | `promotion_status` and `result_status` dropdowns aligned to DDL values |
| 3 | `msh_student_attendance` | Show view created (`show.blade.php`), controller `show()` method added, route registered |
| 4 | `msh_student_attendance` | `is_active` checkbox added to create and edit views |
| 5 | `msh_subject_practical_configs` | Confirmed **NOT A GAP** — `has_practical` default handled by `prepareForValidation()` in FormRequest |

---

## Legend

| Symbol | Meaning |
|--------|---------|
| ✅ | Matches DDL |
| ⚠️ | Mismatch / partial gap |
| ❌ | Missing |
| N/A | Not applicable (system-computed, junction via parent, audit-only) |

---

## Table-by-Table Analysis

### 1. `msh_marksheet_types` (Master)
**FormRequest:** `MarksheetTypeRequest` | **Views:** `marksheet-type-{create,edit}.blade.php`

| DDL Field | Type/Null/Default | In Request | In View | Status |
|-----------|-------------------|------------|---------|--------|
| id | INT UNSIGNED PK AI | N/A | N/A | ✅ |
| code | VARCHAR(30) NOT NULL | required, max:30, unique | input | ✅ |
| name | VARCHAR(100) NOT NULL | required, max:100 | input | ✅ |
| description | VARCHAR(255) DEFAULT NULL | nullable, max:255 | textarea | ✅ |
| display_order | SMALLINT UNSIGNED NOT NULL DEFAULT 1 | required, integer, min:1 | input (min=0) | ✅ |
| is_active | TINYINT(1) NOT NULL DEFAULT 1 | required, boolean | checkbox | ✅ |
| created_by | INT UNSIGNED NOT NULL | N/A (model) | N/A | ✅ |
| updated_by | INT UNSIGNED DEFAULT NULL | N/A (model) | N/A | ✅ |

**Verdict:** ✅ No gaps.

---

### 2. `msh_source_components` (Master — fixed seed)
**No FormRequest** — fixed seeded data (EXAM, HOMEWORK, QUIZ, QUEST). Intentional.

**Verdict:** ✅ No gaps.

---

### 3. `msh_ia_component_types` (Master — seeded + school-extensible)
**FormRequest:** `IaComponentTypeRequest` | **Views:** `ia-component-type-{create,edit,show}.blade.php`

**Verdict:** ✅ **CRUD created (2026-05-29).** `IaComponentTypeRequest`, Controller, modal views, create/edit/show views, configuration tab, permissions, and routes added.

---

### 4. `msh_class_groups` (Configuration)
**FormRequest:** `ClassGroupRequest` | **Views:** `class-group-{create,edit}.blade.php`

| DDL Field | In Request | In View | Status |
|-----------|------------|---------|--------|
| code | required, max:30, unique | input | ✅ |
| name | required, max:100 | input | ✅ |
| description | nullable, max:255 | textarea | ✅ |
| display_order | required, integer, min:1 | input (min=1/0) | ✅ |
| is_active | required, boolean | checkbox | ✅ |
| class_ids (junction) | nullable, array | checkboxes | ✅ |

**Verdict:** ✅ No gaps.

---

### 5. `msh_class_group_items_jnt` (Junction)
**No FormRequest** — handled via `class_ids[]` array in `ClassGroupRequest`.

**Verdict:** ✅ No gaps.

---

### 6. `msh_exam_groups` (Configuration)
**FormRequest:** `ExamGroupRequest` | **Views:** `exam-group-{create,edit}.blade.php`

| DDL Field | In Request | In View | Status |
|-----------|------------|---------|--------|
| academic_session_id | required, exists | hidden (create) / hidden (edit) | ✅ |
| code | required, max:30, unique per session | input | ✅ |
| name | required, max:100 | input | ✅ |
| description | nullable, max:255 | textarea | ✅ |
| start_date | nullable, date | date input | ✅ |
| end_date | nullable, date, after_or_equal:start_date | date input | ✅ |
| is_active | sometimes, boolean | checkbox | ✅ |
| exam_type_ids (junction) | nullable, array | checkboxes | ✅ |

**Verdict:** ✅ No gaps.

---

### 7. `msh_exam_group_items_jnt` (Junction)
**No FormRequest** — handled via `exam_type_ids[]` array in `ExamGroupRequest`.

**Verdict:** ✅ No gaps.

---

### 8. `msh_config_templates` (Configuration)
**FormRequest:** `ConfigTemplateRequest` | **Views:** `config-template/{create,edit}.blade.php`

| DDL Field | In Request | In View | Status |
|-----------|------------|---------|--------|
| academic_session_id | required, exists | select | ✅ |
| marksheet_type_id | required, exists | select | ✅ |
| exam_group_id | required, exists | select | ✅ |
| grading_schema_id | nullable, exists | select | ✅ |
| code | required, max:50, unique per session | input | ✅ |
| name | required, max:150 | input | ✅ |
| description | nullable, max:500 | textarea | ✅ |
| board_code | nullable, max:50 | input | ✅ |
| passing_percentage | required, numeric, min:0, max:100 (default 33) | input | ✅ |
| compartment_max_failures | required, integer, min:0, max:255 (default 2) | input | ✅ |
| is_best_of_n_enabled | sometimes, boolean (default 0) | checkbox | ✅ |
| best_of_n_count | nullable, integer, min:1, max:255 | input | ✅ |
| is_locked | sometimes, boolean (default 0) | ❌ not in view | ✅ (system-set, not user-editable) |
| is_active | sometimes, boolean | status-switch | ✅ |
| class_assignments (junction) | nullable, array | partial include | ✅ |

**Verdict:** ✅ No gaps. `is_locked` is intentionally system-managed.

---

### 9. `msh_template_scholastic_components` (Configuration)
**FormRequest:** `TemplateScholasticComponentRequest` | **Views:** `template-scholastic-component-{create,edit}.blade.php`

| DDL Field | In Request | In View | Status |
|-----------|------------|---------|--------|
| config_template_id | required, exists | select | ✅ |
| source_component_id | required, exists, unique per template | select | ✅ |
| weightage_percent | required, numeric, min:0, max:100 | input | ✅ |
| max_marks | nullable, numeric, min:0 | input | ✅ |
| is_active | sometimes, boolean | checkbox | ✅ |

**Verdict:** ✅ No gaps.

---

### 10. `msh_template_exam_weightages` (Configuration)
**FormRequest:** `TemplateExamWeightageRequest` | **Views:** `template-exam-weightage-{create,edit}.blade.php`

| DDL Field | In Request | In View | Status |
|-----------|------------|---------|--------|
| config_template_id | required, exists | select | ✅ |
| exam_type_id | required, exists, unique per template | select | ✅ |
| weightage_percent | required, numeric, min:0, max:100 | input | ✅ |
| max_marks | nullable, numeric, min:0 | input | ✅ |
| is_active | sometimes, boolean | checkbox | ✅ |

**Verdict:** ✅ No gaps.

---

### 11. `msh_template_ia_components` (Configuration)
**FormRequest:** `TemplateIaComponentRequest` | **Views:** `template-ia-component-{create,edit}.blade.php`

| DDL Field | In Request | In View | Status |
|-----------|------------|---------|--------|
| config_template_id | required, exists | select | ✅ |
| ia_component_type_id | required, exists, unique per template | select | ✅ |
| max_marks | required, numeric, min:0 | input | ✅ |
| display_order | required, integer, min:1 (default 1) | input (min=0) | ✅ |
| is_active | sometimes, boolean | checkbox | ✅ |

**Verdict:** ✅ No gaps.

---

### 12. `msh_template_coscholastic_components` (Configuration)
**FormRequest:** `TemplateCoscholasticComponentRequest` | **Views:** `template-coscholastic-component-{create,edit}.blade.php`

| DDL Field | In Request | In View | Status |
|-----------|------------|---------|--------|
| config_template_id | required, exists | select | ✅ |
| name | required, max:100 | input | ✅ |
| code | required, max:30, unique per template | input | ✅ |
| grading_scale | sometimes, max:50 (default '3_POINT') | select (3_POINT/5_POINT/PERCENTAGE) | ✅ |
| is_ba_linked | sometimes, boolean (default 0) | checkbox | ✅ |
| display_order | required, integer, min:1 (default 1) | input (min=1) | ✅ |
| is_active | sometimes, boolean | checkbox | ✅ |

**Verdict:** ✅ No gaps.

---

### 13. `msh_class_config_jnt` (Junction)
**No FormRequest** — handled via `class_assignments` array in `ConfigTemplateRequest`.

**Verdict:** ✅ No gaps.

---

### 14. `msh_subject_practical_configs` (Configuration)
**FormRequest:** `SubjectPracticalConfigRequest` | **Views:** `subject-practical-config-{create,edit}.blade.php`

| DDL Field | In Request | In View | Status |
|-----------|------------|---------|--------|
| academic_session_id | required, exists | select | ✅ |
| class_id | required, exists, composite-unique | select | ✅ |
| subject_id | required, exists | select | ✅ |
| has_practical | sometimes, boolean (default 1) | checkbox (unchecked by default) | ✅ (handled in FormRequest) |
| theory_max_marks | required, numeric, min:0 | input | ✅ |
| practical_max_marks | required, numeric, min:0 | input | ✅ |
| is_active | sometimes, boolean | checkbox | ✅ |

**✅ NOT A GAP:** `has_practical` default is handled by `prepareForValidation()` in `SubjectPracticalConfigRequest`. When the checkbox is unchecked, the FormRequest explicitly sets `has_practical = 0` before validation, so unchecking correctly results in `has_practical = 0` (not the DDL default of `1`). No fix needed.

---

### 15. `msh_marksheet_schedules` (Schedule)
**FormRequest:** `MarksheetScheduleRequest` | **Views:** `marksheet-schedule/{create,edit}.blade.php`

| DDL Field | In Request | In View | Status |
|-----------|------------|---------|--------|
| config_template_id | required, exists | select | ✅ |
| academic_session_id | required, exists | select | ✅ |
| code | required, max:50, unique per session | input | ✅ |
| name | required, max:150 | input | ✅ |
| schedule_date | nullable, date | date input | ✅ |
| status_id | required, exists:sys_dropdowns | select | ✅ |
| is_locked | sometimes, boolean (default 0) | ❌ not in view | ✅ (system-set) |
| is_active | sometimes, boolean | status-switch | ✅ |
| class_section_ids | nullable, array | partial include | ✅ |
| last_computed_at | — | N/A (system) | ✅ |
| total_students | — | N/A (system) | ✅ |
| locked_at/locked_by/unlock_reason/… | — | N/A (unlock workflow) | ✅ |

**Verdict:** ✅ No gaps.

---

### 16. `msh_schedule_class_jnt` (Schedule)
**FormRequest:** `ScheduleClassRequest` | **Views:** `schedule-class-{create,edit}.blade.php`

| DDL Field | In Request | In View | Status |
|-----------|------------|---------|--------|
| schedule_id | required, exists | select | ✅ |
| class_section_id | required, exists, unique per schedule | select | ✅ |
| is_active | sometimes, boolean | checkbox | ✅ |

**Verdict:** ✅ No gaps.

---

### 17. `msh_student_results` (Result)
**FormRequest:** `StudentResultRequest` | **Views:** `student-result/{create,edit}.blade.php`

| DDL Field | In Request | In View | Status |
|-----------|------------|---------|--------|
| schedule_id | required, unique per student | select | ✅ |
| student_id | required, exists | select | ✅ |
| class_section_id | required, exists | select | ✅ |
| grand_total | nullable, numeric, min:0 | input | ✅ |
| grand_max | nullable, numeric, min:0 | input | ✅ |
| overall_percentage | nullable, numeric, min:0, max:100 | input | ✅ |
| overall_grade | nullable, string, max:10 | input | ✅ |
| division | nullable, string, max:30 | select (FIRST/SECOND/THIRD/FAIL) | ✅ |
| rank_in_section | nullable, integer, min:1 | input | ✅ |
| rank_in_class | nullable, integer, min:1 | input | ✅ |
| total_subjects | nullable, integer, min:0, max:255 | input | ✅ |
| subjects_passed | nullable, integer, min:0, max:255 | input | ✅ |
| subjects_failed | nullable, integer, min:0, max:255 | input | ✅ |
| promotion_status | nullable, string | select (PROMOTED/DETAINED/COMPARTMENT/PLACED) | ✅ FIXED |
| result_status | nullable, string | select (DECLARED/WITHHELD) | ✅ FIXED |
| withheld_reason | nullable, max:255 | textarea | ✅ |
| is_active | sometimes, boolean | status-switch | ✅ |

**✅ FIXED (2026-05-29):** `promotion_status` dropdown now uses DDL values: `PROMOTED`, `DETAINED`, `COMPARTMENT`, `PLACED`. `result_status` dropdown now uses DDL values: `DECLARED`, `WITHHELD`.

---

### 18. `msh_student_subject_results` (Result)
**FormRequest:** `StudentSubjectResultRequest` | **Views:** `student-subject-result/{create,edit}.blade.php`

| DDL Field | In Request | In View | Status |
|-----------|------------|---------|--------|
| schedule_id | required, unique per student+subject | select | ✅ |
| student_id | required, exists | select | ✅ |
| subject_id | required, exists | select | ✅ |
| exam_weighted_total | nullable, numeric, min:0 | input | ✅ |
| theory_marks | nullable, numeric, min:0 | input | ✅ |
| practical_marks | nullable, numeric, min:0 | input | ✅ |
| homework_score | nullable, numeric, min:0 | input | ✅ |
| quiz_score | nullable, numeric, min:0 | input | ✅ |
| quest_score | nullable, numeric, min:0 | input | ✅ |
| ia_total | nullable, numeric, min:0 | input | ✅ |
| subject_total | nullable, numeric, min:0 | input | ✅ |
| subject_max | nullable, numeric, min:0 | input | ✅ |
| subject_percentage | nullable, numeric, min:0, max:100 | input | ✅ |
| subject_grade | nullable, string, max:10 | input | ✅ |
| is_passed | nullable, boolean | checkbox | ✅ |
| is_active | sometimes, boolean | status-switch | ✅ |

**Verdict:** ✅ No gaps.

---

### 19. `msh_student_subject_exam_marks` (Result)
**No FormRequest** — computation-only table (written by `ComputeMarksheetJob`). Manual CRUD not needed.

**Verdict:** ✅ No gaps.

---

### 20. `msh_student_ia_marks` (Result)
**FormRequest:** `StudentIaMarkRequest` | **Views:** `student-ia-mark-{create,edit}.blade.php`

| DDL Field | In Request | In View | Status |
|-----------|------------|---------|--------|
| schedule_id | required, exists | select | ✅ |
| student_id | required, exists | select | ✅ |
| subject_id | required, exists | select | ✅ |
| ia_component_id | required, exists, unique per schedule+student+subject | select | ✅ |
| marks_obtained | nullable, numeric, min:0 | input | ✅ |
| max_marks | required, numeric, min:0 | input | ✅ |
| entered_by | nullable, exists:sys_users | ❌ not in view | ✅ (system-set) |
| entered_at | nullable, date | ❌ not in view | ✅ (system-set) |
| is_active | sometimes, boolean | checkbox | ✅ |

**Verdict:** ✅ No gaps.

---

### 21. `msh_student_coscholastic_results` (Result)
**FormRequest:** `StudentCoscholasticResultRequest` | **Views:** `student-coscholastic-result-{create,edit}.blade.php`

| DDL Field | In Request | In View | Status |
|-----------|------------|---------|--------|
| schedule_id | required, exists | select | ✅ |
| student_id | required, exists | select | ✅ |
| coscholastic_component_id | required, exists, unique per schedule+student | select | ✅ |
| grade | nullable, string, max:10 | input | ✅ |
| remarks | nullable, max:255 | textarea | ✅ |
| entered_by | nullable, exists:sys_users | ❌ not in view | ✅ (system-set) |
| entered_at | nullable, date | ❌ not in view | ✅ (system-set) |
| is_auto_from_ba | sometimes, boolean (default 0) | checkbox | ✅ |
| is_active | sometimes, boolean | checkbox | ✅ |

**Verdict:** ✅ No gaps.

---

### 22. `msh_student_attendance` (Result)
**FormRequest:** `StudentAttendanceRequest` | **Views:** `student-attendance/{create,edit}.blade.php`

| DDL Field | In Request | In View | Status |
|-----------|------------|---------|--------|
| schedule_id | required, unique per student | input (number) | ✅ |
| student_id | required, exists | input (number) | ✅ |
| total_working_days | nullable, integer, min:0, max:65535 | input | ✅ |
| days_present | nullable, integer, min:0, max:65535, lte:total_working_days | input | ✅ |
| entered_by | nullable, exists:sys_users | ❌ not in view | ✅ (system-set) |
| is_auto_populated | sometimes, boolean (default 0) | ❌ not in view | ⚠️ (system-computed) |
| is_active | sometimes, boolean (default 1) | checkbox (create/edit) | ✅ FIXED |

**✅ FIXED (2026-05-29):** `is_active` checkbox added to create and edit views. Show view created (`show.blade.php`), controller `show()` method added, route registered. `is_auto_populated` retained as system-computed field.

➡️ View uses plain `<input type="number">` for schedule_id and student_id instead of `<select>` with proper options, unlike other result forms.

---

### 23. `msh_computation_logs` (Audit)
**No FormRequest** — immutable audit log, no CRUD needed.

**Verdict:** ✅ No gaps.

---

## Summary of Gaps Found

### ✅ Resolved Gaps (Fixes Applied 2026-05-29)

| # | Table | Gap Type | Resolution |
|---|-------|----------|------------|
| 1 | `msh_ia_component_types` | **Missing CRUD** | `IaComponentTypeRequest`, Controller, modal views, create/edit/show views, configuration tab, permissions, and routes added |
| 2 | `msh_student_results` | **Value name mismatch** | `promotion_status` values aligned to DDL (`PROMOTED`/`DETAINED`/`COMPARTMENT`/`PLACED`); `result_status` aligned to DDL (`DECLARED`/`WITHHELD`) |
| 3 | `msh_student_attendance` | **Missing show view** | `show.blade.php` created, controller `show()` method added, route registered |
| 4 | `msh_student_attendance` | **Missing `is_active`** | Checkbox added to both create and edit views |

### 🟡 Remaining Items

| # | Table | Gap Type | Detail |
|---|-------|----------|--------|
| 1 | `msh_student_attendance` | **Missing `is_auto_populated`** | Field not in view (system-computed, not a blocker) |
| 2 | `msh_subject_practical_configs` | ~~Default mismatch~~ | ✅ **NOT A GAP** — handled by `prepareForValidation()` in `SubjectPracticalConfigRequest` |

### 🟢 Minor / Style Issues

| # | Table | Detail |
|---|-------|--------|
| 5 | `msh_student_attendance` | Uses raw `<input type="number">` for FK fields (`schedule_id`, `student_id`) instead of `<select>` with proper options, unlike other result forms |

---

## Fixes Applied & Remaining Items

### ✅ Applied (2026-05-29)

1. **Created `IaComponentTypeRequest`** and full CRUD for `msh_ia_component_types`
2. **Aligned `promotion_status` values** — views now use `PROMOTED`, `DETAINED`, `COMPARTMENT`, `PLACED`
3. **Aligned `result_status` values** — views now use `DECLARED`, `WITHHELD`
4. **Added missing show view** for `msh_student_attendance`
5. **Added `is_active` checkbox** to student-attendance create/edit views
6. **Marked `msh_subject_practical_configs` `has_practical`** as NOT A GAP (handled by `prepareForValidation`)

### 📋 Remaining Considerations

- `msh_student_attendance` — `is_auto_populated` could be exposed if auto-population logic is implemented (currently system-computed)
- `msh_student_attendance` — FK inputs (`schedule_id`, `student_id`) could be upgraded to `<select>` for consistency with other forms
