# Comprehensive Master Test Plan & Manual Browser Test Scripts (All 9 Tabs)
**Target DDL:** `/home/shailesh/shailesh/pgdatabase/2-DDL_Tenant_Enhanced/SchoolSetup/SchoolSetup_DDL_v4.6.sql`  
**Base URL:** `http://test.localhost:8000/school-setup/school-class`

---

## Complete Test Matrix Covered for Every Tab

| # | Test Dimension | Verification Details |
|---|---|---|
| **1** | **Table & UI Elements** | Column headers, action icons, tooltips, sort indicators, empty state alert. |
| **2** | **Pagination & Filters** | Page navigation (next/prev/numbers), items-per-page, search keyword, status filter, reset filter button. |
| **3** | **Required Field Validation** | Empty modal submission, red highlight (`.is-invalid`), specific field error labels under input. |
| **4** | **DDL Character Limit (CHAR)** | Maxlength attribute & backend rejection when entering exceeding characters. |
| **5** | **CRUD Creation (Positive Flow)** | Valid data entry, AJAX submit, modal close, SweetAlert toast, new row in table. |
| **6** | **Uniqueness & Duplicate Check** | Attempting identical `code`, `name`, `short_name`, or composite keys (`UQ` constraints). |
| **7** | **Active / Inactive Status Toggle** | Toggle switch, AJAX update, SweetAlert confirmation, cascading effect on dependent dropdowns. |
| **8** | **Drag & Drop Sequence (Ordinal)** | Table row reordering via drag handle `☰`, AJAX ordinal sync, `uq_*_ordinal` verification. |
| **9** | **CRUD Edit & Update** | Click edit, "Sure to Edit?" SweetAlert confirmation, modal pre-fill, change data, save, verify update. |
| **10** | **Soft Delete & Trash Recovery** | Click delete, SweetAlert confirm, row removal, verify record moves to Trash view (`deleted_at`). |
| **11** | **System Protected Records** | Rows where `is_system = 1` must have edit & delete buttons hidden or disabled. |
| **12** | **Foreign Key Dependency Integrity** | Parent record cannot be deleted if referenced in junction/child tables (RESTRICT check). |

---

## TAB 1: Sections (`sch_sections`)
- **Direct URL:** `http://test.localhost:8000/school-setup/school-class?tab=sections#sections`
- **DDL Target:** `sch_sections`
- **Unique Constraints:** `uq_sections_name` (`name`), `uq_sections_code` (`code`), `uq_sections_ordinal` (`ordinal`)

### Test Cases:
1. **TC-SEC-01 (Table Structure & Pagination):**
   - Verify columns: `#`, `Name`, `Short Name`, `Code`, `Status`, `Actions`.
   - Verify pagination bar (`Previous`, `1`, `2`, `Next`) and result text (`Showing X to Y of Z`).
2. **TC-SEC-02 (Empty Form Validation):**
   - Click `+ Add Section`. Submit without inputs.
   - Assert error spans under `name` and `code`.
3. **TC-SEC-03 (DDL Limit CHAR(4)):**
   - Enter `TOOLONG` (7 chars) in Section Code.
   - Assert input enforces `maxlength="4"` or throws validation rejection.
4. **TC-SEC-04 (CRUD Positive Create):**
   - Fill Name: `Section Alpha`, Short Name: `SEC-A`, Code: `ALPH`, Status: `Active`.
   - Click Save. Assert toast notification and row presence in active table.
5. **TC-SEC-05 (Duplicate Code Check):**
   - Re-submit form with Code `ALPH` but different name.
   - Assert duplicate code error message (`uq_sections_code`).
6. **TC-SEC-06 (Duplicate Name Check):**
   - Re-submit form with Name `Section Alpha` but different code.
   - Assert duplicate name error message (`uq_sections_name`).
7. **TC-SEC-07 (Status Switch & Cascading Dependency):**
   - Switch status toggle from Active to Inactive.
   - Open Tab 2 (Class). Verify `Section Alpha` is hidden or disabled from section mapping options.
8. **TC-SEC-08 (Ordinal Drag & Drop):**
   - Drag row by handle `☰` to row position 1.
   - Refresh page & verify updated order is retained (`uq_sections_ordinal`).
9. **TC-SEC-09 (CRUD Edit Flow):**
   - Click Edit icon. SweetAlert pops up: *"Sure to Edit? Do you want to proceed to edit?"*
   - Click *"Yes, proceed!"*. Modal loads pre-filled data.
   - Update Name to `Section Alpha Upd`. Click Save. Assert updated text in table.
10. **TC-SEC-10 (Soft Delete Flow):**
    - Click Delete icon. SweetAlert: *"Move to Trash: The item can be restored later."*
    - Click *"Yes, delete it!"*. Assert row removed from table and visible in Section Trash view.

---

## TAB 2: Class (`sch_classes` & `sch_class_section_jnt`)
- **Direct URL:** `http://test.localhost:8000/school-setup/school-class?tab=class-sections#class-sections`
- **DDL Target:** `sch_classes`, `sch_class_section_jnt`
- **Constraints:** `uq_classes_code` (`code`), `uq_classes_shortName` (`short_name`), `uq_classes_name` (`name`), `uq_classes_ordinal` (`ordinal`)

### Test Cases:
1. **TC-CLS-01 (Table Structure & Section Tags):**
   - Verify columns: `#`, `Class Name`, `Short Name`, `Code`, `Sections`, `Status`, `Actions`.
   - Verify assigned sections render as badges (e.g. `[A]`, `[B]`).
2. **TC-CLS-02 (Empty Form Validation):**
   - Click `+ Add Class`. Submit without filling fields.
   - Assert validation errors on `name`, `short_name`, and `code`.
3. **TC-CLS-03 (DDL Limit CHAR(5)):**
   - Enter `GRADE10` (7 chars) in Class Code.
   - Assert DDL CHAR(5) restriction (`maxlength="5"` or error).
4. **TC-CLS-04 (CRUD Positive Create with Section Mapping):**
   - Fill Name: `Grade 10th`, Short Name: `10th`, Code: `10TH`.
   - Check section checkboxes `A` and `B`.
   - Click Save. Verify class row created and `sch_class_section_jnt` rows exist.
5. **TC-CLS-05 (Duplicate Class Code & Name):**
   - Re-attempt submission with `10TH` code &rarr; duplicate rejection (`uq_classes_code`).
   - Re-attempt submission with `Grade 10th` name &rarr; duplicate rejection (`uq_classes_name`).
6. **TC-CLS-06 (Status Toggle & Ordinal Drag Drop):**
   - Toggle class Active switch.
   - Drag row handle to reorder classes. Verify position persists on refresh.
7. **TC-CLS-07 (Edit & Delete):**
   - Edit class to uncheck Section `B` and add Section `C`. Save & verify tag updates.
   - Delete class &rarr; SweetAlert confirm &rarr; assert class and junction removed.

---

## TAB 3: Subject Type (`sch_subject_types`)
- **Direct URL:** `http://test.localhost:8000/school-setup/school-class?tab=subject-type#subject-type`
- **DDL Target:** `sch_subject_types`
- **Constraints:** `uq_subjectTypes_name` (`name`), `uq_subjectTypes_code` (`code`)

### Test Cases:
1. **TC-STP-01 (Listing & Categories):**
   - Verify pre-seeded types: Major, Minor, Compulsory, Optional, Skill.
2. **TC-STP-02 (Validation & DDL Limits):**
   - Submit empty create modal &rarr; asserts required fields.
   - Test code max limit.
3. **TC-STP-03 (Positive Create):**
   - Create Subject Type: Name: `Co-Curricular`, Short: `CO-CUR`, Code: `COCUR`.
   - Assert creation in table.
4. **TC-STP-04 (Duplicate Code & Name):**
   - Assert duplicate rejection on re-entering `COCUR` (`uq_subjectTypes_code`).
5. **TC-STP-05 (Status & Dependency in Subject Mapping):**
   - Deactivate `Co-Curricular`.
   - Go to Tab 6 (Subject + Study Format) & Tab 7 (Class Group) &rarr; Verify deactivated subject type is disabled.

---

## TAB 4: Study Format (`sch_study_formats`)
- **Direct URL:** `http://test.localhost:8000/school-setup/school-class?tab=study-format#study-format`
- **DDL Target:** `sch_study_formats`
- **Special Rule:** `is_system` tinyint(1) default 0. System-defined formats cannot be edited/deleted!

### Test Cases:
1. **TC-SFM-01 (Table & System Records Identification):**
   - Check default formats: Lecture (`LEC`), Practical (`PRAC`), Tutorial (`TUT`), Lab (`LAB`).
   - Verify `is_system = 1` rows do not show Delete buttons or show disabled badges.
2. **TC-SFM-02 (Custom Study Format Create):**
   - Create Name: `Seminar`, Short Name: `SEM`, Code: `SEMIN`.
   - Save & assert created with `is_system = 0`.
3. **TC-SFM-03 (Duplicate Check):**
   - Try creating duplicate Code `SEMIN` &rarr; asserts `uq_studyFormats_code` rejection.
4. **TC-SFM-04 (Edit & Delete for Custom Record):**
   - Custom `Seminar` record allows Edit & Soft Delete.
   - System record `Lecture` rejects deletion.

---

## TAB 5: Subject (`sch_subjects`)
- **Direct URL:** `http://test.localhost:8000/school-setup/school-class?tab=subject#subject`
- **DDL Target:** `sch_subjects`
- **Constraints:** `uq_subjects_code` (`code`), `uq_subjects_shortName` (`short_name`), `uq_subjects_name` (`name`), `is_system` protection.

### Test Cases:
1. **TC-SBJ-01 (Table, Filters & Search):**
   - Test keyword search (e.g. search "Math") & verify table filters correctly.
   - Test Active/Inactive dropdown filter and "Clear Filter" button.
2. **TC-SBJ-02 (Validation & DDL CHAR(10)):**
   - Submit empty modal &rarr; asserts required fields.
   - Enter 11+ characters in Code &rarr; assert CHAR(10) constraint.
3. **TC-SBJ-03 (CRUD Positive Create):**
   - Fill Name: `Computer Vision`, Short: `CV`, Code: `COMP_VIS`.
   - Save and assert row created.
4. **TC-SBJ-04 (Duplicate Code & Short Name Check):**
   - Assert `uq_subjects_code` duplicate rejection.
   - Assert `uq_subjects_shortName` duplicate rejection.
5. **TC-SBJ-05 (System Subject Protection):**
   - Check core subjects where `is_system = 1`: Delete option must be blocked.
6. **TC-SBJ-06 (Edit & Soft Delete):**
   - Edit custom subject name; soft delete custom subject and verify Trash view.

---

## TAB 6: Subject + Study Format (`sch_subject_study_format_jnt`)
- **Direct URL:** `http://test.localhost:8000/school-setup/school-class?tab=subject-study-format#subject-study-format`
- **DDL Target:** `sch_subject_study_format_jnt`
- **Key Constraint:** `uq_ssfj_subjectId_stFormat` (`subject_id`, `study_format_id`, `subject_type_id`)

### Test Cases:
1. **TC-SSF-01 (Junction Table View):**
   - Columns: `#`, `Subject`, `Study Format`, `Subject Type`, `Generated Code`, `Actions`.
2. **TC-SSF-02 (Triple Mapping Uniqueness):**
   - Map `Physics` + `Practical` + `Major`. Save successfully.
   - Try mapping identical `Physics` + `Practical` + `Major` again.
   - Assert duplicate error rejection (`uq_ssfj_subjectId_stFormat`).
3. **TC-SSF-03 (Filter Verification):**
   - Filter by Subject dropdown (e.g. select `Physics`) &rarr; Table displays only Physics mappings.
   - Filter by Study Format (e.g. select `Practical`) &rarr; Table refines accordingly.
4. **TC-SSF-04 (Foreign Key Integrity Check):**
   - Verify deleting a subject format junction that has downstream class group links is guarded by FK constraints (`ON DELETE RESTRICT`).

---

## TAB 7: Class Group (`sch_class_groups_jnt`)
- **Direct URL:** `http://test.localhost:8000/school-setup/school-class?tab=subject-class-mapping#subject-class-mapping`
- **DDL Target:** `sch_class_groups_jnt`
- **Key Constraint:** `uq_classGroups_cls_Sec_subStdFmt_SubTyp` (`class_id`, `section_id`, `subject_study_format_id`)

### Test Cases:
1. **TC-CGP-01 (Table & Timetable Attributes Check):**
   - Columns: Class, Section (or ALL), Subject+Format, Weekly Periods, Priority, Room Requirement.
2. **TC-CGP-02 (Form Validation & Period Rules):**
   - Validate Required Weekly Periods (must be >= 1).
   - Validate Max consecutive periods and allow consecutive periods toggle.
3. **TC-CGP-03 (Room Type Requirement):**
   - Test "Class House Room" checkbox vs "Specific Room Type" dropdown (`required_room_type_id`).
4. **TC-CGP-04 (Duplicate Combination Check):**
   - Create mapping for Class 10 + Section A + Mathematics Lecture.
   - Attempt duplicate creation of same combination &rarr; assert uniqueness error.
5. **TC-CGP-05 (Filter & Search):**
   - Filter by Class and Section.

---

## TAB 8: Subject Group (`sch_subject_groups` & `sch_subject_group_subject_jnt`)
- **Direct URL:** `http://test.localhost:8000/school-setup/school-class?tab=subject-group#subject-group`
- **DDL Target:** `sch_subject_groups`, `sch_subject_group_subject_jnt`
- **Key Constraint:** `uq_sgsj_subjGrpId_classGroup` (`subject_group_id`, `class_group_id`)

### Test Cases:
1. **TC-SGP-01 (Group Bundling Display):**
   - Shows subject bundles assigned to students (e.g. `11th Science PCM+CS`).
   - Columns: Code, Name, Class, Stream, Registered Students Count.
2. **TC-SGP-02 (Ordinal Drag & Drop):**
   - Reorder subject groups via drag handle; verify ordinal field updates.
3. **TC-SGP-03 (Add Class Groups to Subject Group):**
   - Assign Class Groups into Subject Group.
   - Assert `uq_sgsj_subjGrpId_classGroup` prevents adding duplicate class group to the same subject group.
4. **TC-SGP-04 (Student Dependency Deletion Lock):**
   - Check if `registered_students_count > 0`: System blocks deletion with alert *"Cannot delete group with registered students"*.
   - If count == 0: allows safe deletion.

---

## TAB 9: Stream (`sch_class_streams` & `sch_class_stream_items`)
- **Direct URL:** `http://test.localhost:8000/school-setup/school-class?tab=class-stream#class-stream`
- **DDL Target:** `sch_class_streams`, `sch_class_stream_items`

### Test Cases:
1. **TC-STR-01 (Stream Listing View):**
   - Shows Higher Secondary Streams (Science, Commerce, Arts/Humanities) mapped to classes.
2. **TC-STR-02 (Validation & CHAR(5) Code Limit):**
   - Validate mandatory Class selection, Stream Code, Stream Name.
   - Assert CHAR(5) code limit (e.g. `SCI`, `COMM`, `ARTS`).
3. **TC-STR-03 (Positive Stream Creation):**
   - Create Stream for Class 11: Code: `VOCAT`, Name: `Vocational Studies`, Short: `VOC`.
   - Save and verify row in table.
4. **TC-STR-04 (Stream Items & Subject Options):**
   - Open Stream items configuration &rarr; verify stream subject options (e.g. Biology vs Computer Science).
5. **TC-STR-05 (Duplicate & Delete Flow):**
   - Duplicate stream code under same class throws rejection.
   - Delete stream with SweetAlert confirm.
