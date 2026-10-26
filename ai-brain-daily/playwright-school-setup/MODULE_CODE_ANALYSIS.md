# SchoolSetup Module Implementation & Code Architecture Insights
**Module Path:** `/home/shailesh/shailesh/prime_ai/Modules/SchoolSetup`  
**Matching DDL:** `/home/shailesh/shailesh/pgdatabase/2-DDL_Tenant_Enhanced/SchoolSetup/SchoolSetup_DDL_v4.6.sql`

---

## 1. Request Validation Architecture (`app/Http/Requests`)

Checking the exact backend Laravel code reveals the exact validation rules and error responses:

| Tab | FormRequest Class | Core Validation Rules | Exact Error Keys |
|---|---|---|---|
| **Sections** | `SectionRequest.php` | `name: required\|string\|max:50\|unique:sch_sections,name`<br>`short_name: required\|string\|max:20`<br>`code: required\|string\|max:4\|unique:sch_sections,code` | `name.required`, `name.unique`, `code.max`, `code.unique` |
| **Class** | `SchoolClassRequest.php` | `class_name: required\|string\|max:50\|unique:sch_classes,name`<br>`short_name: required\|string\|max:20\|unique:sch_classes,short_name`<br>`code: required\|string\|max:5\|unique:sch_classes,code` | `class_name.required`, `code.max`, `code.unique`, `short_name.unique` |
| **Subject Type** | `SubjectTypeRequest.php` | `name: required\|string\|max:50\|unique:sch_subject_types,name`<br>`code: required\|string\|max:5\|unique:sch_subject_types,code` | `name.required`, `code.unique` |
| **Study Format** | `StudyFormatRequest.php` | `name: required\|string\|max:50\|unique:sch_study_formats,name`<br>`code: required\|string\|max:5\|unique:sch_study_formats,code`<br>`is_system` protection check | `is_system`, `code.unique` |
| **Subject** | `SubjectRequest.php` | `name: required\|string\|max:50`<br>`short_name: required\|string\|max:20\|unique:sch_subjects,short_name`<br>`code: required\|string\|max:5\|unique:sch_subjects,code`<br>`is_main_optional_subject: in:Main,Optional,Both` | `short_name.unique`, `code.unique` |
| **Class Group** | `ClassGroupRequest.php` | `class_id: required\|exists:sch_classes,id`<br>`section_id: nullable\|exists:sch_sections,id`<br>`subject_study_format_id: required\|exists:sch_subject_study_format_jnt,id`<br>`required_weekly_periods: required\|integer\|min:1` | `class_id.required`, `required_weekly_periods.min` |
| **Subject Group** | `SubjectGroupRequest.php` | `class_id: required\|exists:sch_classes,id`<br>`name: required\|string\|max:100`<br>`code: required\|string\|max:20\|unique:sch_subject_groups,code` | `class_id.required`, `code.unique` |
| **Stream** | `ClassStreamRequest.php` | `class_id: required\|exists:sch_classes,id`<br>`section_id: nullable\|exists:sch_sections,id`<br>`code: required\|string\|max:5\|unique:sch_class_streams,code` | `class_id.required`, `code.max`, `code.unique` |

---

## 2. Blade & AJAX Behavioral Rules

1. **AJAX Form Submissions**:
   - Every modal submit sends JSON/AJAX.
   - On `422 Unprocessable Entity`: The controller returns `{ success: false, message: '...', errors: { field: ['...'] } }`.
   - The blade script automatically appends `<span class="text-danger">` next to the offending input and triggers a red SweetAlert toast.

2. **Edit Workflow & SweetAlert Guard**:
   - Clicking Edit triggers `Swal.fire({ title: 'Sure to Edit?', text: 'Do you want to proceed to edit?', icon: 'warning', confirmButtonText: 'Yes, proceed!' })`.
   - The modal is populated via AJAX `GET .../show/{id}` only after confirmation.

3. **Soft Delete & 3-Second Page Reload**:
   - `deleteSection(id)` calls `DELETE` via AJAX, removes `$('#section-row-' + id)` from the DOM immediately, shows a success toast, and issues `setTimeout(() => window.location.reload(), 3000)`.
   - The record receives `deleted_at = NOW()` in MySQL.

4. **Status Switch Real-Time Dependency**:
   - Changing `#sections-table .status-toggle` executes:
     ```javascript
     const modalRows = $(`#classWithSectionModal tr[data-row-id="${sectionId}"], #classSectionModal tr[data-row-id="${sectionId}"]`);
     if (isActive) {
       modalRows.show();
     } else {
       modalRows.hide();
       modalRows.find('.row-edit-toggle').prop('checked', false).trigger('change');
     }
     ```
   - Disabling a Section instantly de-links and hides it from the Class mapping modal in real time!
