# Deep Technical Verification Report: School Setup (9 Tabs)
**DDL Reference:** `SchoolSetup_DDL_v4.6.sql`  
**Module Implementation:** `/home/shailesh/shailesh/prime_ai/Modules/SchoolSetup`

---

## 1. Deep Codebase Verification Matrix

| # | Tab / Sub-Module | DDL Target Table | FormRequest Validator | UI Engine | Reorder (`ordinal`) | Status Switch | Delete Mechanism |
|---|---|---|---|---|---|---|---|
| **1** | **Sections** | `sch_sections` | `SectionRequest.php` | Blade + jQuery AJAX | SortableJS (`js.blade.php`) | `<x-backend.table.status-switch>` | Soft Delete (`deleted_at`) + 3s Reload |
| **2** | **Class** | `sch_classes` & `sch_class_section_jnt` | `SchoolClassRequest.php` | Blade + Modal Checkboxes | SortableJS | `<x-backend.table.status-switch>` | Soft Delete + Junction cascade |
| **3** | **Subject Type** | `sch_subject_types` | `SubjectTypeRequest.php` | Blade + Modal | SortableJS | `<x-backend.table.status-switch>` | Soft Delete (`deleted_at`) |
| **4** | **Study Format** | `sch_study_formats` | `StudyFormatRequest.php` | Blade + Modal | SortableJS | `<x-backend.table.status-switch>` | `is_system` Guarded Delete |
| **5** | **Subject** | `sch_subjects` | `SubjectRequest.php` | Blade + Search Filter | SortableJS | `<x-backend.table.status-switch>` | `is_system` Guarded Delete |
| **6** | **Subject + Study Format** | `sch_subject_study_format_jnt` | Dynamic Controller JSON | **Vue 3 Global Build** | SortableJS | Table & Matrix switch | Triple UQ Constraint (`uq_ssfj...`) |
| **7** | **Class Group** | `sch_class_groups_jnt` | `ClassGroupRequest.php` | Blade + Modal | SortableJS | `<x-backend.table.status-switch>` | Period & Room Rule checks |
| **8** | **Subject Group** | `sch_subject_groups` | `SubjectGroupRequest.php` | Blade + Student counter | SortableJS | `<x-backend.table.status-switch>` | Guarded if `registered_students > 0` |
| **9** | **Stream** | `sch_class_streams` | `ClassStreamRequest.php` | Blade + Modal | SortableJS | `<x-backend.table.status-switch>` | Soft Delete + Item cleanup |

---

## 2. In-Depth Mechanism Checks

### A. Drag & Drop Reordering (`ordinal`)
- **Found in:** `Modules/SchoolSetup/resources/views/school-class/partials/js/js.blade.php`
- **Library:** `Sortable.min.js` attached to all `.sortable-table` containers with handle `.drag-handle`.
- **Payload & Endpoint:**
  ```javascript
  const payload = {
      module: moduleName,
      item_id: draggedItemId,
      old_ordinal: oldOrdinal,
      new_ordinal: newOrdinal,
  };
  // POST to route('school-setup.common.reorder')
  ```
- **Live DOM Sync:** On success, dynamically shifts sibling `data-ordinal` values up or down by 1 to maintain database gapless unique ordinal sequence.

### B. Status Switch & Cross-Tab Dependency
- **Found in:** Every tab uses `<x-backend.table.status-switch>` calling `POST .../{module}/status`.
- **Cascading Effect:**
  ```javascript
  $(document).on('change', '#sections-table .status-toggle', function () {
      const sectionId = $(this).data('id');
      const isActive = $(this).is(':checked');
      const modalRows = $(`#classWithSectionModal tr[data-row-id="${sectionId}"], #classSectionModal tr[data-row-id="${sectionId}"]`);
      if (isActive) {
          modalRows.show();
      } else {
          modalRows.hide();
          modalRows.find('.row-edit-toggle').prop('checked', false).trigger('change');
      }
  });
  ```
  *When a Section is toggled inactive, it is instantly hidden and unselected inside the Class Mapping modal!*

### C. System Protection (`is_system`)
- Tables `sch_study_formats` and `sch_subjects` contain `is_system tinyint(1) default 0`.
- In views `study-format/index.blade.php` and `subject/index.blade.php`:
  ```blade
  @if(!$item->is_system)
      <button onclick="deleteItem(...)">Delete</button>
  @else
      <span class="badge bg-secondary">System Locked</span>
  @endif
  ```
  *Prevents deleting pre-seeded foundational subjects (e.g. English, Math) or core formats (Lecture, Practical).*

### D. SweetAlert Double Confirmation Guard
- **Edit Action:** `Swal.fire({ title: 'Sure to Edit?', icon: 'warning', confirmButtonText: 'Yes, proceed!' })`
- **Delete Action:** `Swal.fire({ title: 'Are you sure?', text: 'Move to Trash: The item can be restored later.', confirmButtonText: 'Yes, delete it!' })`
