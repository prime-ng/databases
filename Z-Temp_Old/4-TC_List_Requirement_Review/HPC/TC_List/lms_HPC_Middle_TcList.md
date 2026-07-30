# lms_HPC_Middle — Test Case List & Business Conditions

**Module:** HPC (Holistic Progress Card, CODE `HPC`, prefix `lms_HPC_`) · **Feature:** Teacher Card — Middle (BV3)
**DB scope:** TENANT-side (`hpc_*` → tenant DB) · **Test style:** Browser Dusk (`extends DuskTestCase`)
**Primary tables:** `hpc_reports`, `hpc_report_items`, `hpc_report_table` · **Module URL prefix:** `/hpc`
**Test file:** `lms_HPC_Middle_TestCas.php`
**Grade band:** Class 7th, 8th, 9th, 10th · **Total pages:** 46

---

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | HPC (Holistic Progress Card) |
| Tab Group | Teacher Card |
| Feature | Teacher Card - Middle (BV3) |
| URL(s) | `hpc/hpc-form/{student_id}` (GET), `hpc/form/store` (POST) |
| Controller | `Modules\Hpc\Http\Controllers\HpcController` (methods: `hpc_form`, `formStore`) |
| Model(s) | `Modules\Hpc\Models\HpcTemplates`, `Modules\Hpc\Models\HpcReport`, `Modules\Hpc\Models\HpcReportItem`, `Modules\Hpc\Models\HpcReportTable` |
| Validation | Inline validation in `HpcController@formStore` (no FormRequest) |
| Permissions | `tenant.hpc.view` (read), `tenant.hpc.create` (first save), `tenant.hpc.update` (subsequent saves) |
| Soft Deletes | Yes — `HpcReport` uses `SoftDeletes` trait |
| Activity Log | None |

---

## 2. Pre-conditions

| # | Pre-condition | Details |
|---|---------------|---------|
| PC-01 | Authenticated teacher user | Logged in as teacher role with HPC permissions |
| PC-02 | Student record exists | Student enrolled in grade 7-10 with class/section/academic session |
| PC-03 | HPC template configured | Middle template (`template_id` 37-54 range) with 46 parts created in Template Management |
| PC-04 | Academic term active | Valid `academic_session_id` and `term_id` exist for current year |
| PC-05 | Student profile data | Admission details, parent/guardian info, address, health records exist |
| PC-06 | LMS module available (optional) | LMS exam scores, quiz results, homework data may exist for auto-fill |
| PC-07 | Browser JavaScript enabled | 46-tab navigation, ASC rubric radio selection, drag-drop require JS |
| PC-08 | Database transaction support | InnoDB engine for `DB::beginTransaction`/`commit`/`rollback` in `formStore` |
| PC-09 | Student self-assessment submitted | Student has completed self-assessment via Student Portal |
| PC-10 | Parent observation submitted | Parent has filled observation form via Parent Portal |
| PC-11 | Peer reviews completed | At least 3 peer reviews submitted for collaborative rubric |
| PC-12 | Attendance data seeded | Monthly attendance records for Apr-Mar academic year exist |

---

## 3. Default Data Load

| Data Element | Source | Auto-fill Behaviour |
|-------------|--------|---------------------|
| School name, address, UDISE code | School settings | Auto-filled on page 1, read-only |
| Student name, admission no, roll no | `std_students` | Auto-filled on page 1, read-only |
| Date of birth, gender, class, section | `std_students` | Auto-filled on page 1, read-only |
| Parent/guardian names, phone, occupation | `std_guardians` via junction | Auto-filled on page 1, read-only |
| Address, pincode, religion, caste | `std_student_addresses` | Auto-filled on page 1, read-only |
| Height, weight, blood group | `std_health_profiles` | Auto-filled on page 1, read-only |
| Attendance (Apr-Mar monthly rows) | Attendance module aggregation | Auto-calculated %, teacher enters working/present days |
| Student self-intro (dream job, friends) | Student Portal (self-assessment) | Auto-filled on page 2, read-only |
| LMS exam scores, quiz results, homework | LMS module | Auto-filled in grey boxes, read-only |
| Peer review averages | Peer review module | Auto-filled in dedicated section, read-only |
| Parent observation text | Parent Portal | Auto-filled in parent feedback section, read-only |
| Rubric items and ASC levels | `hpc_report_table` + template config | Empty radio buttons, teacher selects |
| Competency mapping codes | Template configuration | Auto-displayed badges, read-only |

---

## 4. Test Data Strategy

| Strategy | Approach |
|----------|----------|
| Student data | Create test student records in grades 7, 8, 9, 10 with complete profile data |
| Template data | Create Middle template with 46 parts, sections, rubrics, and items for each grade |
| Attendance data | Generate 12-month attendance records (Apr-Mar) with varied working/present days |
| LMS data | Seed exam scores and quiz results for at least 3 subjects with known values |
| Self-assessment | Submit student self-assessment for 3 subjects via Student Portal seed |
| Parent observation | Submit parent observation form for the test student |
| Peer review | Generate 5 peer review submissions with calculated averages |
| Boundary data | Test minimum (1 rubric row) and maximum (all 46 pages filled) data volumes |
| Negative data | Invalid student IDs, missing required fields, type-mismatched rubric values |
| Concurrent data | Simultaneous save requests from different sessions for the same student |
| Permission data | Create users with varying permission sets (view-only, create, update, none) |
| Grade boundary | Test students at grade 7 (lower bound) and grade 10 (upper bound) |

---

## 5. Business Conditions

### 4.1 Database Schema — Primary Tables

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | hpc_reports.id | BIGINT PK | Auto-increment |
| BC-DB-02 | hpc_reports.academic_session_id | INT | NOT NULL |
| BC-DB-03 | hpc_reports.term_id | INT | NOT NULL |
| BC-DB-04 | hpc_reports.student_id | INT | NOT NULL |
| BC-DB-05 | hpc_reports.class_id | INT | NOT NULL |
| BC-DB-06 | hpc_reports.section_id | INT | NOT NULL |
| BC-DB-07 | hpc_reports.template_id | INT | NOT NULL |
| BC-DB-08 | hpc_reports.prepared_by | INT | NOT NULL |
| BC-DB-09 | hpc_reports.report_date | DATE | NULLABLE |
| BC-DB-10 | hpc_reports.status | ENUM('Draft','Final','Published','Archived') | NOT NULL DEFAULT 'Draft' |
| BC-DB-11 | hpc_reports.created_at | TIMESTAMP | NULLABLE |
| BC-DB-12 | hpc_reports.updated_at | TIMESTAMP | NULLABLE |
| BC-DB-13 | hpc_reports.deleted_at | TIMESTAMP | NULLABLE (soft delete) |
| BC-DB-14 | hpc_reports — composite UNIQUE | (academic_session_id, term_id, student_id) | UNIQUE constraint |
| BC-DB-15 | hpc_reports — composite INDEX | (class_id, section_id) | INDEX |
| BC-DB-16 | hpc_reports — INDEX | (prepared_by) | INDEX |
| BC-DB-17 | hpc_report_items.id | BIGINT PK | Auto-increment |
| BC-DB-18 | hpc_report_items.report_id | INT FK → hpc_reports.id ON DELETE CASCADE | NOT NULL |
| BC-DB-19 | hpc_report_items.template_id | INT | NOT NULL |
| BC-DB-20 | hpc_report_items.rubric_id | INT | NOT NULL |
| BC-DB-21 | hpc_report_items.rubric_item_id | INT FK → hpc_rubric_items.id | NOT NULL |
| BC-DB-22 | hpc_report_items.in_numeric_value | DECIMAL | NULLABLE |
| BC-DB-23 | hpc_report_items.in_text_value | TEXT | NULLABLE |
| BC-DB-24 | hpc_report_items.in_boolean_value | BOOLEAN | NULLABLE |
| BC-DB-25 | hpc_report_items.in_selected_value | VARCHAR(255) | NULLABLE |
| BC-DB-26 | hpc_report_items.in_image_path | VARCHAR(255) | NULLABLE |
| BC-DB-27 | hpc_report_items.in_filename | VARCHAR(255) | NULLABLE |
| BC-DB-28 | hpc_report_items.in_filepath | VARCHAR(255) | NULLABLE |
| BC-DB-29 | hpc_report_items.in_json_value | JSON | NULLABLE |
| BC-DB-30 | hpc_report_items.out_numeric_value | DECIMAL | NULLABLE |
| BC-DB-31 | hpc_report_items.out_text_value | TEXT | NULLABLE |
| BC-DB-32 | hpc_report_items.out_boolean_value | BOOLEAN | NULLABLE |
| BC-DB-33 | hpc_report_items.out_selected_value | VARCHAR(255) | NULLABLE |
| BC-DB-34 | hpc_report_items.out_image_path | VARCHAR(255) | NULLABLE |
| BC-DB-35 | hpc_report_items.out_filename | VARCHAR(255) | NULLABLE |
| BC-DB-36 | hpc_report_items.out_filepath | VARCHAR(255) | NULLABLE |
| BC-DB-37 | hpc_report_items.out_json_value | JSON | NULLABLE |
| BC-DB-38 | hpc_report_items.remark | TEXT | NULLABLE |
| BC-DB-39 | hpc_report_items.assessed_by | INT FK → sys_users.id | NULLABLE |
| BC-DB-40 | hpc_report_items.assessed_at | TIMESTAMP | NULLABLE |
| BC-DB-41 | hpc_report_items.created_at | TIMESTAMP | NULLABLE |
| BC-DB-42 | hpc_report_items.updated_at | TIMESTAMP | NULLABLE |
| BC-DB-43 | hpc_report_items — FK report_id | → hpc_reports.id | ON DELETE CASCADE |
| BC-DB-44 | hpc_report_items — FK rubric_item_id | → hpc_rubric_items.id | — |
| BC-DB-45 | hpc_report_table.id | BIGINT PK | Auto-increment |
| BC-DB-46 | hpc_report_table.report_id | INT FK → hpc_reports.id ON DELETE CASCADE | NOT NULL |
| BC-DB-47 | hpc_report_table.rubric_item_id | INT | NOT NULL |
| BC-DB-48 | hpc_report_table.rubric_id | INT | NOT NULL |
| BC-DB-49 | hpc_report_table.stream_value | BOOLEAN | DEFAULT 0 |
| BC-DB-50 | hpc_report_table.mountain_value | BOOLEAN | DEFAULT 0 |
| BC-DB-51 | hpc_report_table.sky_value | BOOLEAN | DEFAULT 0 |
| BC-DB-52 | hpc_report_table.peak_value | BOOLEAN | DEFAULT 0 |
| BC-DB-53 | hpc_report_table.selected_level | VARCHAR(20) | NULLABLE |
| BC-DB-54 | hpc_report_table.created_at | TIMESTAMP | NULLABLE |
| BC-DB-55 | hpc_report_table.updated_at | TIMESTAMP | NULLABLE |
| BC-DB-56 | hpc_report_table — UNIQUE | (report_id, rubric_item_id) | UNIQUE composite |
| BC-DB-57 | hpc_templates.id | BIGINT PK | Auto-increment |
| BC-DB-58 | hpc_templates.code | VARCHAR(100) | UNIQUE NOT NULL |
| BC-DB-59 | hpc_templates.title | VARCHAR(255) | NOT NULL |
| BC-DB-60 | hpc_templates.version | INT | DEFAULT 1 |
| BC-DB-61 | hpc_templates.applicable_grades | JSON | NOT NULL |
| BC-DB-62 | hpc_templates.is_active | BOOLEAN | DEFAULT 1 |
| BC-DB-63 | hpc_templates.created_at | TIMESTAMP | NULLABLE |
| BC-DB-64 | hpc_templates.updated_at | TIMESTAMP | NULLABLE |
| BC-DB-65 | hpc_templates.deleted_at | TIMESTAMP | NULLABLE (SoftDeletes) |
| BC-DB-66 | hpc_templates_part.id | BIGINT PK | Auto-increment |
| BC-DB-67 | hpc_templates_part.template_id | INT FK → hpc_templates.id ON DELETE CASCADE | NOT NULL |
| BC-DB-68 | hpc_templates_part.code | VARCHAR(100) | — |
| BC-DB-69 | hpc_templates_part.description | VARCHAR(255) | — |
| BC-DB-70 | hpc_templates_part.display_order | INT | — |
| BC-DB-71 | hpc_templates_part.page_no | INT | — |
| BC-DB-72 | hpc_templates_part.has_items | BOOLEAN | DEFAULT 0 |
| BC-DB-73 | hpc_templates_part.help_file | VARCHAR(255) | NULLABLE |
| BC-DB-74 | hpc_templates_part.created_at | TIMESTAMP | NULLABLE |
| BC-DB-75 | hpc_templates_part.updated_at | TIMESTAMP | NULLABLE |
| BC-DB-76 | hpc_templates_section.id | BIGINT PK | Auto-increment |
| BC-DB-77 | hpc_templates_section.part_id | INT FK → hpc_templates_part.id ON DELETE CASCADE | NOT NULL |
| BC-DB-78 | hpc_templates_section.code | VARCHAR(100) | — |
| BC-DB-79 | hpc_templates_section.title | VARCHAR(255) | — |
| BC-DB-80 | hpc_templates_section.display_order | INT | — |
| BC-DB-81 | hpc_templates_section.created_at | TIMESTAMP | NULLABLE |
| BC-DB-82 | hpc_templates_section.updated_at | TIMESTAMP | NULLABLE |
| BC-DB-83 | hpc_rubrics.id | BIGINT PK | Auto-increment |
| BC-DB-84 | hpc_rubrics.section_id | INT FK → hpc_templates_section.id ON DELETE CASCADE | NOT NULL |
| BC-DB-85 | hpc_rubrics.code | VARCHAR(100) | — |
| BC-DB-86 | hpc_rubrics.title | VARCHAR(255) | — |
| BC-DB-87 | hpc_rubrics.rubric_type | ENUM('radio','dropdown','numeric','text','boolean','checkbox','image','file','json') | NOT NULL |
| BC-DB-88 | hpc_rubrics.display_order | INT | — |
| BC-DB-89 | hpc_rubrics.created_at | TIMESTAMP | NULLABLE |
| BC-DB-90 | hpc_rubrics.updated_at | TIMESTAMP | NULLABLE |
| BC-DB-91 | hpc_rubric_items.id | BIGINT PK | Auto-increment |
| BC-DB-92 | hpc_rubric_items.rubric_id | INT FK → hpc_rubrics.id ON DELETE CASCADE | NOT NULL |
| BC-DB-93 | hpc_rubric_items.code | VARCHAR(100) | — |
| BC-DB-94 | hpc_rubric_items.label | VARCHAR(255) | — |
| BC-DB-95 | hpc_rubric_items.item_type | ENUM('radio','dropdown','numeric','text','boolean','checkbox','image','file','json') | NOT NULL |
| BC-DB-96 | hpc_rubric_items.options | JSON | NULLABLE |
| BC-DB-97 | hpc_rubric_items.display_order | INT | — |
| BC-DB-98 | hpc_rubric_items.is_required | BOOLEAN | DEFAULT 0 |
| BC-DB-99 | hpc_rubric_items.created_at | TIMESTAMP | NULLABLE |
| BC-DB-100 | hpc_rubric_items.updated_at | TIMESTAMP | NULLABLE |
| BC-DB-101 | `hpc_reports.report_date` nullable DATE | DATE | DEFAULT NULL; set on first save if provided, else defaults to today |
| BC-DB-102 | `hpc_reports.prepared_by` FK → sys_users.id | INT FK | Auto-set to current authenticated user ID |
| BC-DB-103 | `hpc_report_items.assessed_by` nullable FK → sys_users.id | INT FK | Set to teacher user ID when teacher assesses |
| BC-DB-104 | `hpc_report_items.assessed_at` nullable TIMESTAMP | TIMESTAMP | Auto-set to NOW() when item is saved |
| BC-DB-105 | All `hpc_*` tables — engine | InnoDB | utf8mb4_unicode_ci charset |
| BC-DB-106 | Cascade DELETE: hpc_reports → hpc_report_items, hpc_report_table | FK ON DELETE CASCADE | No orphan records |
| BC-DB-107 | `HpcReport` model — SoftDeletes trait | table: hpc_reports | fillable: [academic_session_id, term_id, student_id, class_id, section_id, template_id, prepared_by, report_date, status] casts: [status => 'string', report_date => 'date', deleted_at => 'datetime'] |
| BC-DB-108 | `HpcReportItem` model | table: hpc_report_items | fillable: [report_id, template_id, rubric_id, rubric_item_id, in_numeric_value, in_text_value, in_boolean_value, in_selected_value, in_image_path, in_filename, in_filepath, in_json_value, out_numeric_value, out_text_value, out_boolean_value, out_selected_value, out_image_path, out_filename, out_filepath, out_json_value, remark, assessed_by, assessed_at] |
| BC-DB-109 | `HpcReportTable` model | table: hpc_report_table | fillable: [report_id, rubric_item_id, rubric_id, stream_value, mountain_value, sky_value, peak_value, selected_level] |

### 4.2 Validation Rules — Controller (Create)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-01 | template_id | required, integer, exists:hpc_templates,id WHERE deleted_at IS NULL | — |
| BC-VAL-02 | student_id | required, integer, exists:std_students,id WHERE deleted_at IS NULL | — |
| BC-VAL-03 | academic_session_id | required, integer, exists:academic_sessions,id | — |
| BC-VAL-04 | term_id | required, integer, exists:terms,id | — |
| BC-VAL-05 | class_id | required, integer, must correspond to student's enrolled class | — |
| BC-VAL-06 | section_id | required, integer, must correspond to student's enrolled section | — |
| BC-VAL-07 | report_date | required date format (Y-m-d) when explicitly provided | — |
| BC-VAL-08 | in_numeric_value | numeric (integer or decimal) when rubric_item type is 'numeric' | — |
| BC-VAL-09 | in_boolean_value | boolean (0, 1, true, false) when rubric_item type is 'boolean' | — |
| BC-VAL-10 | in_selected_value | must be in allowed rubric_item.options array when type is 'dropdown' or 'radio' | — |
| BC-VAL-11 | in_text_value | string, max:5000 when rubric_item type is 'text' | — |
| BC-VAL-12 | in_image_path | valid base64 encoded image (png/jpg/jpeg/gif, max 2MB) when type is 'image' | — |
| BC-VAL-13 | in_filepath | valid file reference (pdf/doc/docx/jpg/png, max 5MB) when type is 'file' | — |
| BC-VAL-14 | in_json_value | parseable JSON string when rubric_item type is 'json' or 'checkbox' | — |
| BC-VAL-15 | working_days | required integer, min:0, max:31 per monthly row | — |
| BC-VAL-16 | present_days | required integer, min:0, must be ≤ working_days | — |
| BC-VAL-17 | reason_for_absence | nullable string, max:500 | — |
| BC-VAL-18 | Extra fields outside fillable | stripped — mass-assignment protection via model fillable | — |
| BC-VAL-19 | Student grade | must be in range 7-10 for Middle template — controller validates before loading | — |
| BC-VAL-20 | assessed_by | auto-set to auth user ID, cannot be overridden via request input | — |
| BC-VAL-21 | assessed_at | auto-set to current timestamp when item is saved, cannot be overridden | — |
| BC-VAL-22 | Required rubric items | is_required=true must have non-null value submitted | — |
| BC-VAL-23 | Radio in_selected_value | must be exactly one of the predefined option values | — |
| BC-VAL-24 | Checkbox in_json_value | must be an array of valid option values | — |
| BC-VAL-25 | Image upload max size | 2048 KB (2MB) enforced in PHP upload settings | — |
| BC-VAL-26 | File upload max size | 5120 KB (5MB) enforced in PHP upload settings | — |
| BC-VAL-27 | Allowed image MIME types | image/jpeg, image/png, image/gif | — |
| BC-VAL-28 | Allowed document MIME types | application/pdf, application/msword, application/vnd.openxmlformats-officedocument.wordprocessingml.document, image/jpeg, image/png | — |

### 4.3 Validation Rules — Controller (Update)

| BC ID | Field | Rule | Error Message |
|-------|-------|------|---------------|
| BC-VAL-U01 | out_* fields | NOT validated — system-computed from in_* values on read | — |
| BC-VAL-U02 | Status transitions | Draft→Final, Final→Published, Published→Archived. Reverse not allowed | — |
| BC-VAL-U03 | report_date | if omitted defaults to today's date (Carbon::now()) | — |
| BC-VAL-U04 | Unique constraint violation | (academic_session_id, term_id, student_id) — existing record updated instead of error | — |
| BC-VAL-U05 | Existing report re-save | Must find HpcReport by unique combo; update existing, no duplicate | — |

### 4.4 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | tenant.hpc.view | hpc_form() | Without → 403 |
| BC-AUTH-02 | tenant.hpc.create | formStore() | Without → 403 |
| BC-AUTH-03 | tenant.hpc.update | formStore() | Without → 403 |
| BC-AUTH-04 | — | Gate::authorize() | Throws AuthorizationException (403) on failure |
| BC-AUTH-05 | — | Guest user | Redirected to /login (auth middleware) |
| BC-AUTH-06 | — | module:HPC middleware | Returns 404 when HPC module disabled |
| BC-AUTH-07 | Tenant scope | hpc_form() | Teacher can only view/save students within their assigned class and section |
| BC-AUTH-08 | Tenant scope | hpc_form() | Principal/Admin can view any student across all classes and sections (bypass class restriction) |
| BC-AUTH-09 | tenant.hpc.view | generatePdf() | Without → 403 |
| BC-AUTH-10 | Status transition | formStore() | Requires additional gates for submit/finalize/publish/archive |
| BC-AUTH-11 | Soft-delete | Model level | No permission check for soft-delete on report (handled at model level, not controller auth) |

### 4.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Template resolution from student's grade | Grade 7-10 maps to Middle template (first_form with template_id=3) |
| BC-BIZ-02 | Template ID mapping | template_id=1→Foundation, =2→Preparatory, =3→Middle, =4→Secondary |
| BC-BIZ-03 | 46-tab navigation system | Each tab corresponds to a `hpc_templates_part` record with sequential display_order |
| BC-BIZ-04 | Multi-contributor data merge | Teacher assessment + student self-assessment + parent observation + peer review all visible on one card |
| BC-BIZ-05 | ASC rubric tables | 4 performance levels: Stream (A/Beginning), Mountain (B/Developing), Sky (C/Achieved), Peak (D/Advanced) |
| BC-BIZ-06 | Competency mapping codes | Badge labels on each subject assessment page, linked to NEP 2020 learning outcomes |
| BC-BIZ-07 | Auto-fill from student profile | Student details, address, guardians, academic sessions, attendance, health records |
| BC-BIZ-08 | Auto-fill from LMS module | Exam scores, quiz results, homework grades — graceful fallback when LMS module tables absent |
| BC-BIZ-09 | Attendance aggregation | April to March academic year — 12 monthly rows displayed |
| BC-BIZ-10 | formStore update-or-create logic | Attempts to find existing HpcReport by (academic_session_id, term_id, student_id) unique combo; creates new if none found |
| BC-BIZ-11 | DB::beginTransaction | Called at start of formStore; DB::commit on success; DB::rollback caught in try-catch on exception |
| BC-BIZ-12 | Soft deletes on HpcReport | `$report->delete()` sets deleted_at; records restorable via restore() |
| BC-BIZ-13 | Report status lifecycle | Draft (editable) → Final (locked, submitted) → Published (parent-visible) → Archived (historical). Principal can send Draft→Final back to Draft |
| BC-BIZ-14 | Status change Draft→Final | Sets report_date automatically if not already set |
| BC-BIZ-15 | Student self-assessment stored | assessed_by = student's user ID; teacher assessment uses teacher's user ID; differentiation via assessed_by column |
| BC-BIZ-16 | `$getStudentValue()` helper | 4-level closure chain: student record → academic session → school settings → hardcoded default |
| BC-BIZ-17 | Role-based field filtering | Fields with assessed_by != current user are set to readonly/disabled in the view |
| BC-BIZ-18 | Attendance % computation | round((present_days / working_days) * 100, 1) — 1 decimal place |
| BC-BIZ-19 | Drag-and-drop section reordering | AJAX call updates section display_order in hpc_templates_section |
| BC-BIZ-20 | Editable field labels | Double-click label → inline edit → save via AJAX → label updated in hpc_rubric_items |
| BC-BIZ-21 | PDF preview | Full 46-page document using DomPDF; school header, student details, all 46 pages |
| BC-BIZ-22 | Save ALL 46 pages single request | All rubric items, attendance, comments sent as nested array |
| BC-BIZ-23 | Empty rubric rows stored as NULL | No radio selected, no text entered → stored as NULL, not empty string or 0 |
| BC-BIZ-24 | File uploads storage | Tenant-specific: storage/tenant_{id}/hpc/{report_id}/ |
| BC-BIZ-25 | in_json_value complex structures | Checkbox arrays as ["opt1","opt3"]; competency mappings as {"comp_code":"SCI.9.M.01","level":"Sky"} |
| BC-BIZ-26 | out_* fields computed on read | From in_* values via transformation rules — e.g. out_selected_value = label of selected option |
| BC-BIZ-27 | Add attendance row | Dynamically inserts new monthly row with empty values, removable via delete button |
| BC-BIZ-28 | Remove attendance row | Confirmation dialog "Are you sure you want to delete this row?" before removal |
| BC-BIZ-29 | Three-column layout | Fields wrap into 3 equal-width columns within each section |
| BC-BIZ-30 | LMS auto-fill graceful fallback | If LMS tables absent, section shows "LMS data not available" |
| BC-BIZ-31 | Missing student self-assessment | Section shows "Self-assessment not yet submitted" with muted styling |
| BC-BIZ-32 | Missing parent observation | Section shows "No parent observation submitted for this term" |
| BC-BIZ-33 | Missing peer reviews | Section shows "Peer reviews pending — 0 submissions received" |
| BC-BIZ-34 | Report table grid stores ASC selections | Each row stores level (stream/mountain/sky/peak) for each rubric_item in hpc_report_table |
| BC-BIZ-35 | Radio single-select behavior | Clicking radio deselects previously selected radio in same row, other rows unaffected |
| BC-BIZ-36 | Student grade validation | If student not in grade 7-10, Middle template not loaded — redirect or error |
| BC-BIZ-37 | prepared_by auto-set | auth()->id() on create, not updatable on subsequent saves |
| BC-BIZ-38 | assessed_at auto-set | now() each time rubric item is saved |
| BC-BIZ-39 | Unique constraint violation handling | Caught gracefully — existing record updated instead of error |
| BC-BIZ-40 | PDF generation layout by template_id | 1-18 Foundation, 19-36 Preparatory, 37-54 Middle, 55+ Secondary |

### 4.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | hpc_reports.student_id | std_students (id) | No cascade (student_id orphaned) |
| BC-REF-02 | hpc_reports.template_id | hpc_templates (id) | Restrict or orphan |
| BC-REF-03 | hpc_reports.prepared_by | sys_users (id) | — |
| BC-REF-04 | hpc_report_items.report_id | hpc_reports (id) | CASCADE |
| BC-REF-05 | hpc_report_items.rubric_item_id | hpc_rubric_items (id) | — |
| BC-REF-06 | hpc_report_table.report_id | hpc_reports (id) | CASCADE |
| BC-REF-07 | hpc_report_table.rubric_item_id | hpc_rubric_items (id) | — |
| BC-REF-08 | hpc_templates_part.template_id | hpc_templates (id) | CASCADE |
| BC-REF-09 | hpc_templates_section.part_id | hpc_templates_part (id) | CASCADE |
| BC-REF-10 | hpc_rubrics.section_id | hpc_templates_section (id) | CASCADE |
| BC-REF-11 | hpc_rubric_items.rubric_id | hpc_rubrics (id) | CASCADE |
| BC-REF-12 | hpc_reports — UNIQUE (academic_session_id, term_id, student_id) | — | Prevents duplicate card creation |

---

## 6. Test Case List

### 5.1 Positive Test Cases — Card Page Load

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TCM-P10 | Page loads with 46 tabs for valid Middle-grade student in grade 8 | 46 tab headers visible, first tab active, no JS console errors | test_middle_page_loads | test_middle_page_loads_v2 | ⬜ |
| TCM-P11 | School information auto-filled on page 1 | School name, address, UDISE code, medium of instruction displayed, all read-only | test_middle_school_info | test_middle_school_info_v2 | ⬜ |
| TCM-P12 | Student details auto-filled from admission records on page 1 | Full name, DOB (dd/mm/yyyy), gender, admission no, roll no, class, section, house displayed | test_middle_student_details | test_middle_student_details_v2 | ⬜ |
| TCM-P13 | Parent/guardian details auto-filled on page 1 | Father name, mother name, guardian name, phone numbers (10-digit), occupations, emails shown | test_middle_parent_details | test_middle_parent_details_v2 | ⬜ |
| TCM-P14 | Address and demographics auto-filled on page 1 | Address, pincode (6 boxes), religion, caste, nationality, mother tongue, blood group, EWS status shown | test_middle_demographics | test_middle_demographics_v2 | ⬜ |
| TCM-P15 | Physical measurements auto-filled from health records on page 1 | Height (cm), weight (kg) displayed with source label from health profiles | test_middle_health_measurements | test_middle_health_measurements_v2 | ⬜ |
| TCM-P16 | Attendance table renders with 12 monthly rows (April to March) | 12 rows with columns: Month, Working Days, Days Present, Attendance %, Reason for Absence | test_middle_attendance_rows | test_middle_attendance_rows_v2 | ⬜ |
| TCM-P17 | Student self-intro page (page 2) shows all auto-filled profile data | Gender selection, age dropdown, birthday datepicker, city, family emoji toggles, dream job, friends list, favorites dropdowns all populated | test_middle_self_intro | test_middle_self_intro_v2 | ⬜ |
| TCM-P18 | All 46 tabs are navigable — clicking each tab loads correct content section | Tab click switches displayed content, URL hash updates, content matches tab label | test_middle_tab_navigation | test_middle_tab_navigation_v2 | ⬜ |
| TCM-P19 | Subject rubric pages render with ASC radio buttons (4 levels per row) | Each rubric row displays 4 radio circles: Stream, Mountain, Sky, Peak. Only one selectable per row | test_middle_asc_rubric_render | test_middle_asc_rubric_render_v2 | ⬜ |
| TCM-P20 | Competency mapping codes displayed as badges on subject pages | Badge/label area shows competency codes with descriptions, e.g. "SCI.9.M.01 — Applies scientific methods" | test_middle_competency_codes | test_middle_competency_codes_v2 | ⬜ |
| TCM-P21 | LMS exam scores auto-filled in read-only grey boxes | Exam scores, quiz results, homework grades appear in designated grey-background sections, non-editable | test_middle_lms_data_prefill | test_middle_lms_data_prefill_v2 | ⬜ |
| TCM-P22 | Student self-assessment ratings shown in separate coloured column | Student ratings visible in blue/shaded column next to teacher column, label "Student Self-Assessment" | test_middle_self_assessment_view | test_middle_self_assessment_view_v2 | ⬜ |
| TCM-P23 | Parent observation section displays parent text with parent name label | Parent name, submission date, observation text shown in dedicated feedback section | test_middle_parent_observation | test_middle_parent_observation_v2 | ⬜ |
| TCM-P24 | Peer review summary section displays average ratings and comments | Average score (e.g. "4.2/5") and summarized comments shown, no individual names visible | test_middle_peer_review | test_middle_peer_review_v2 | ⬜ |
| TCM-P25 | Life skills assessment pages render with rubric tables (4 pages) | 4 life skill pages: Communication, Collaboration, Problem-Solving, Self-Awareness. Each with ASC rubric rows | test_middle_life_skills | test_middle_life_skills_v2 | ⬜ |
| TCM-P26 | Co-curricular activity pages render (5 pages: sports, art, music, dance, clubs) | Co-curricular sections with sport-specific, art-specific, music-specific rubric items displayed | test_middle_cocurricular | test_middle_cocurricular_v2 | ⬜ |
| TCM-P27 | Values education pages render (3 pages) | Honesty, respect, civic sense, environmental awareness rubric rows with ASC levels | test_middle_values_education | test_middle_values_education_v2 | ⬜ |
| TCM-P28 | Vocational/work education pages render (3 pages) | Computer skills, gardening, carpentry sections with rubric items | test_middle_vocational | test_middle_vocational_v2 | ⬜ |
| TCM-P29 | Physical education & health pages render (3 pages) | Fitness tests, yoga, sports skills sections displayed | test_middle_pe_pages | test_middle_pe_pages_v2 | ⬜ |
| TCM-P30 | Page loads for grade 7 student — correct template resolves | Middle template (template_id in range 37-54) loaded, 46 pages displayed | test_middle_grade7_load | test_middle_grade7_load_v2 | ⬜ |
| TCM-P31 | Page loads for grade 10 student — correct template resolves | Middle template loaded, 46 pages displayed | test_middle_grade10_load | test_middle_grade10_load_v2 | ⬜ |
| TCM-P32 | Drag-and-drop handles visible on each section header | ⠿ (grip) icon present on each section, draggable with cursor change on hover | test_middle_drag_handle | test_middle_drag_handle_v2 | ⬜ |
| TCM-P33 | Editable field labels — double-click triggers rename mode | Double-click on label text converts to editable input field with Save/Cancel buttons | test_middle_editable_label | test_middle_editable_label_v2 | ⬜ |
| TCM-P34 | PDF preview button visible and triggers download | "Preview PDF" button at bottom, clicking initiates PDF download with correct filename format | test_middle_pdf_preview | test_middle_pdf_preview_v2 | ⬜ |
| TCM-P35 | First tab active and content visible by default on page load | Page 1 content (School & Student Information) visible, first tab highlighted | test_middle_first_tab_active | test_middle_first_tab_active_v2 | ⬜ |
| TCM-P36 | Aadhar ID and APAAR ID shown as individual digit boxes | 12 separate input boxes for Aadhar, APAAR ID shown similarly, one digit per box | test_middle_aadhar_boxes | test_middle_aadhar_boxes_v2 | ⬜ |
| TCM-P37 | Student photo area with upload button visible | Photo placeholder with "Upload" button, accepts image file | test_middle_student_photo | test_middle_student_photo_v2 | ⬜ |
| TCM-P38 | Add Friend button on page 2 adds friend badge | Clicking "Add Friend" opens input, entering name creates badge with X remove button | test_middle_add_friend | test_middle_add_friend_v2 | ⬜ |

### 5.2 Positive Test Cases — Card Save

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TCM-P40 | Save ASC rubric radio selection — valid level per rubric row | Selected level (Stream/Mountain/Sky/Peak) stored in hpc_report_table.selected_level | test_middle_save_rubric_radio | test_middle_save_rubric_radio_v2 | ⬜ |
| TCM-P41 | Save text comment in rubric remark field | Text stored in hpc_report_items.remark column | test_middle_save_text_comment | test_middle_save_text_comment_v2 | ⬜ |
| TCM-P42 | Save numeric score value for numeric rubric item | Decimal/integer stored in hpc_report_items.in_numeric_value | test_middle_save_numeric | test_middle_save_numeric_v2 | ⬜ |
| TCM-P43 | Save boolean toggle (Yes/No) for boolean rubric item | Value 0 or 1 stored in hpc_report_items.in_boolean_value | test_middle_save_boolean | test_middle_save_boolean_v2 | ⬜ |
| TCM-P44 | Save dropdown selection for dropdown rubric item | Selected option value stored in hpc_report_items.in_selected_value | test_middle_save_dropdown | test_middle_save_dropdown_v2 | ⬜ |
| TCM-P45 | Save checkbox multi-select values for checkbox rubric item | Array of selected values stored as JSON in hpc_report_items.in_json_value | test_middle_save_checkbox | test_middle_save_checkbox_v2 | ⬜ |
| TCM-P46 | Save image upload — valid image for image rubric item | Image saved to storage, path stored in hpc_report_items.in_image_path | test_middle_save_image | test_middle_save_image_v2 | ⬜ |
| TCM-P47 | Save file upload — valid document for file rubric item | File saved to storage, path stored in hpc_report_items.in_filepath | test_middle_save_file | test_middle_save_file_v2 | ⬜ |
| TCM-P48 | Save attendance data — valid working/present days for all 12 months | Attendance rows saved, percentage auto-calculated, stored in report | test_middle_save_attendance | test_middle_save_attendance_v2 | ⬜ |
| TCM-P49 | Save ALL 46 pages at once — all rubric items, comments, attendance | Single save request persists data across all pages, success message "Saved successfully" displayed | test_middle_save_all_pages | test_middle_save_all_pages_v2 | ⬜ |
| TCM-P50 | Re-open card after save — previously saved data persists | On re-loading hpc/hpc-form/{id}, all rubric selections, comments, scores visible | test_middle_reopen_data | test_middle_reopen_data_v2 | ⬜ |
| TCM-P51 | First save creates new hpc_reports record with status='Draft' | New row inserted in hpc_reports with correct academic_session_id, term_id, student_id, status='Draft' | test_middle_first_save_creates | test_middle_first_save_creates_v2 | ⬜ |
| TCM-P52 | Subsequent saves update existing hpc_reports record — no duplicate | hpc_reports row updated (updated_at changes), no duplicate row created | test_middle_subsequent_save | test_middle_subsequent_save_v2 | ⬜ |
| TCM-P53 | report_date defaults to today when not provided in save payload | report_date column equals today's date (Y-m-d) | test_middle_report_date_default | test_middle_report_date_default_v2 | ⬜ |
| TCM-P54 | prepared_by set to current authenticated user ID | prepared_by column equals auth()->id() | test_middle_prepared_by | test_middle_prepared_by_v2 | ⬜ |
| TCM-P55 | Attendance % auto-calculated: 25 present / 30 working = 83.3% | Correct percentage stored and displayed: (25/30)*100 = 83.3 | test_middle_attendance_percent | test_middle_attendance_percent_v2 | ⬜ |
| TCM-P56 | All 22 academic subject pages save data correctly | Subject rubrics across all academic subjects persisted in hpc_report_items | test_middle_academic_subjects_save | test_middle_academic_subjects_save_v2 | ⬜ |
| TCM-P57 | Life skills (4 pages) save rubric selections correctly | Life skill rubric selections persisted in hpc_report_table | test_middle_life_skills_save | test_middle_life_skills_save_v2 | ⬜ |
| TCM-P58 | Co-curricular (5 pages) save rubric selections correctly | Co-curricular rubric selections persisted | test_middle_cocurricular_save | test_middle_cocurricular_save_v2 | ⬜ |
| TCM-P59 | Values education (3 pages) save rubric selections correctly | Values rubric selections persisted | test_middle_values_save | test_middle_values_save_v2 | ⬜ |
| TCM-P60 | Vocational education (3 pages) save rubric selections correctly | Vocational rubric selections persisted | test_middle_vocational_save | test_middle_vocational_save_v2 | ⬜ |
| TCM-P61 | Physical education (3 pages) save data correctly | PE rubric and fitness test data persisted | test_middle_pe_save | test_middle_pe_save_v2 | ⬜ |
| TCM-P62 | Student self-assessment fields are read-only on teacher card view | Student columns have `disabled`/`readonly` HTML attribute, form submission ignores changes | test_middle_self_readonly | test_middle_self_readonly_v2 | ⬜ |
| TCM-P63 | Parent feedback section is read-only on teacher card | Parent text fields have `readonly` attribute, cannot be modified | test_middle_parent_readonly | test_middle_parent_readonly_v2 | ⬜ |
| TCM-P64 | Peer review section is read-only | Peer average score fields not editable | test_middle_peer_readonly | test_middle_peer_readonly_v2 | ⬜ |
| TCM-P65 | Save with empty rubric rows — NULL values stored | Unselected rubric items stored as NULL in DB | test_middle_empty_rubric_save | test_middle_empty_rubric_save_v2 | ⬜ |
| TCM-P66 | Transaction commit on successful save — all data persisted atomically | After commit, all hpc_report_items for this save are present in DB | test_middle_transaction_commit | test_middle_transaction_commit_v2 | ⬜ |
| TCM-P67 | Transaction rollback on exception — no partial data | When save throws exception, no records partially persisted, DB state unchanged | test_middle_transaction_rollback | test_middle_transaction_rollback_v2 | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TCM-N70 | Load page with invalid student_id that does not exist in DB | 404 Not Found or redirect to student list with error flash message | test_middle_invalid_student | test_middle_invalid_student_v2 | ⬜ |
| TCM-N71 | Load page with student_id of soft-deleted student | 404 or error: student record not found | test_middle_deleted_student | test_middle_deleted_student_v2 | ⬜ |
| TCM-N72 | Template soft-deleted before teacher opens card | Error message: template configuration missing, fallback to default or redirect | test_middle_deleted_template | test_middle_deleted_template_v2 | ⬜ |
| TCM-N73 | Save with missing required field `template_id` | Validation error, HTTP 422 or redirect back with errors | test_middle_missing_template_id | test_middle_missing_template_id_v2 | ⬜ |
| TCM-N74 | Save with missing required field `student_id` | Validation error, save rejected | test_middle_missing_student_id | test_middle_missing_student_id_v2 | ⬜ |
| TCM-N75 | Save with missing required field `academic_session_id` | Validation error, save rejected | test_middle_missing_session_id | test_middle_missing_session_id_v2 | ⬜ |
| TCM-N76 | Save with missing required field `term_id` | Validation error, save rejected | test_middle_missing_term_id | test_middle_missing_term_id_v2 | ⬜ |
| TCM-N77 | Save with missing required field `class_id` | Validation error, save rejected | test_middle_missing_class_id | test_middle_missing_class_id_v2 | ⬜ |
| TCM-N78 | Save with missing required field `section_id` | Validation error, save rejected | test_middle_missing_section_id | test_middle_missing_section_id_v2 | ⬜ |
| TCM-N79 | Rubric `in_numeric_value` receives non-numeric string (e.g. "abc") | Validation error, field rejected | test_middle_numeric_type_mismatch | test_middle_numeric_type_mismatch_v2 | ⬜ |
| TCM-N80 | Rubric `in_boolean_value` receives non-boolean value (e.g. "yes") | Validation error, field rejected | test_middle_boolean_type_mismatch | test_middle_boolean_type_mismatch_v2 | ⬜ |
| TCM-N81 | Rubric `in_selected_value` receives value not in allowed options list | Validation error, field rejected | test_middle_select_invalid_option | test_middle_select_invalid_option_v2 | ⬜ |
| TCM-N82 | Concurrent save requests from 2 teacher sessions for same student | Second save overwrites or merges based on last-write-wins; no DB constraint violation | test_middle_concurrent_save | test_middle_concurrent_save_v2 | ⬜ |
| TCM-N83 | User without `tenant.hpc.view` permission tries to load form | 403 Forbidden (AuthorizationException) | test_middle_permission_denied_view | test_middle_permission_denied_view_v2 | ⬜ |
| TCM-N84 | User without `tenant.hpc.create` tries first-time save (new report) | 403 Forbidden | test_middle_permission_denied_create | test_middle_permission_denied_create_v2 | ⬜ |
| TCM-N85 | User without `tenant.hpc.update` tries subsequent save (update report) | 403 Forbidden | test_middle_permission_denied_update | test_middle_permission_denied_update_v2 | ⬜ |
| TCM-N86 | Guest (unauthenticated) user accesses hpc/hpc-form/{id} | Redirected to /login | test_middle_guest_access | test_middle_guest_access_v2 | ⬜ |
| TCM-N87 | Save attempt for duplicate (academic_session_id, term_id, student_id) combo | Existing record updated, no duplicate created, no constraint violation error | test_middle_duplicate_term_student | test_middle_duplicate_term_student_v2 | ⬜ |
| TCM-N88 | LMS module absent — graceful fallback with no error thrown | LMS sections show "LMS data not available" message, rest of page renders normally | test_middle_lms_fallback | test_middle_lms_fallback_v2 | ⬜ |
| TCM-N89 | Attendance calculation with 0 working days entered | Division by zero prevented — shows 0% or "N/A", no PHP error or exception | test_middle_attendance_zero_working | test_middle_attendance_zero_working_v2 | ⬜ |
| TCM-N90 | Present days (30) exceeds working days (25) for a month | Validation error: present_days must be ≤ working_days | test_middle_attendance_exceed | test_middle_attendance_exceed_v2 | ⬜ |
| TCM-N91 | Student in grade 5 (Preparatory band) — wrong grade for Middle template | Template mismatch: wrong template loaded or redirect with error message | test_middle_wrong_grade_student | test_middle_wrong_grade_student_v2 | ⬜ |
| TCM-N92 | Save with `in_json_value` containing invalid JSON string | Validation error, JSON parse failure | test_middle_invalid_json | test_middle_invalid_json_v2 | ⬜ |
| TCM-N93 | Image upload exceeding 2MB size limit | Validation error: file too large | test_middle_image_size_exceed | test_middle_image_size_exceed_v2 | ⬜ |
| TCM-N94 | File upload with disallowed MIME type (e.g. .exe) | Validation error: invalid file type | test_middle_file_type_invalid | test_middle_file_type_invalid_v2 | ⬜ |
| TCM-N95 | Module disabled (HPC module deactivated) — access any HPC route | 404 Not Found via module:HPC middleware | test_middle_module_disabled_route | test_middle_module_disabled_route_v2 | ⬜ |
| TCM-N96 | Teacher tries to access student from another class they don't teach | 403 or redirected, access denied | test_middle_cross_class_access | test_middle_cross_class_access_v2 | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TCM-D100 | A | Template selection by grade band — grade 7 student gets Middle template | Template resolved as Middle template (template_id 37-54 range, code 'HPC-MID') | test_middle_template_selection | test_middle_template_selection_v2 | ⬜ |
| TCM-D101 | B | formStore wraps all DB operations in DB::beginTransaction/commit/rollback | Transaction block present in controller method, commit on success, rollback on exception | test_middle_transaction_wrapper | test_middle_transaction_wrapper_v2 | ⬜ |
| TCM-D102 | C | HpcReport unique constraint on (academic_session_id, term_id, student_id) | Attempt to manually insert duplicate throws Integrity constraint violation (23000) | test_middle_unique_constraint | test_middle_unique_constraint_v2 | ⬜ |
| TCM-D103 | D | hpc_report_items FK ON DELETE CASCADE — deleting report removes items | After hpc_reports row hard-deleted, associated hpc_report_items removed | test_middle_report_items_cascade | test_middle_report_items_cascade_v2 | ⬜ |
| TCM-D104 | E | SoftDeletes on HpcReport model — delete() sets deleted_at | Calling delete() sets deleted_at timestamp, record excluded from default queries | test_middle_softdelete | test_middle_softdelete_v2 | ⬜ |
| TCM-D105 | E | HpcReport restore() recovers soft-deleted record | After restore(), deleted_at becomes NULL, record visible in default queries | test_middle_softdelete_restore | test_middle_softdelete_restore_v2 | ⬜ |
| TCM-D106 | E | Soft-deleting report does NOT cascade soft-delete to hpc_report_items | Items remain with report_id intact, deleted_at on report only | test_middle_softdelete_items | test_middle_softdelete_items_v2 | ⬜ |
| TCM-D107 | F | `$getStudentValue()` 4-level closure: student→session→school→default | Value resolved checking each level in order, returns first non-null match | test_middle_get_student_value | test_middle_get_student_value_v2 | ⬜ |
| TCM-D108 | G | Role-based field filtering: teacher/student/parent fields correctly gated | Teacher rubric fields editable, student columns disabled, parent columns readonly | test_middle_role_field_filtering | test_middle_role_field_filtering_v2 | ⬜ |
| TCM-D109 | H | Attendance percentage re-computed on form load and after save | Value updates after save with new working/present day numbers | test_middle_attendance_compute_timing | test_middle_attendance_compute_timing_v2 | ⬜ |
| TCM-D110 | I | hpc_report_table grid storage: ASC level per rubric_item_id | Grid stores selected_level for each rubric_item_id with correct report_id | test_middle_report_table_storage | test_middle_report_table_storage_v2 | ⬜ |
| TCM-D111 | J | ASC rubric radio single-select: selecting one deselects others in same row | Only one radio selected per row. Selecting Sky deselects Stream/Mountain if previously selected | test_middle_rubric_single_select | test_middle_rubric_single_select_v2 | ⬜ |
| TCM-D112 | K | 46 template parts with display_order sequential 1-46 | Query hpc_templates_part count = 46, display_order values 1 through 46 | test_middle_part_count_sequence | test_middle_part_count_sequence_v2 | ⬜ |
| TCM-D113 | L | Save button disabled during AJAX request — prevents double-submit | Button disabled on click, re-enabled after success or error response | test_middle_save_button_disable | test_middle_save_button_disable_v2 | ⬜ |
| TCM-D114 | M | PDF generation uses Middle layout for template_id in 37-54 range | PDF file rendered with Middle-specific layout sections (includes self-assessment, peer review blocks) | test_middle_pdf_layout_type | test_middle_pdf_layout_type_v2 | ⬜ |
| TCM-D115 | N | Image upload stored in correct tenant-specific directory path | File path starts with `storage/tenant_{id}/hpc/{report_id}/` | test_middle_image_storage_path | test_middle_image_storage_path_v2 | ⬜ |
| TCM-D116 | O | Add attendance row (+) inserts new row with empty fields | New row appears below existing rows with empty Working Days, Present Days, input fields | test_middle_attendance_add_row | test_middle_attendance_add_row_v2 | ⬜ |
| TCM-D117 | P | Remove attendance row (-) shows confirmation popup before deletion | JavaScript confirm() or modal "Are you sure?" on clicking remove button | test_middle_attendance_remove_confirm | test_middle_attendance_remove_confirm_v2 | ⬜ |
| TCM-D118 | Q | Three-column layout on assessment pages — fields wrap in 3 equal columns | CSS grid or flexbox creates 3 columns, fields distribute left to right | test_middle_three_column_layout | test_middle_three_column_layout_v2 | ⬜ |
| TCM-D119 | R | Drag reordering persists section display_order in DB via AJAX | After drop, AJAX call updates section ordinal, on reload sections appear in new order | test_middle_drag_persist | test_middle_drag_persist_v2 | ⬜ |
| TCM-D120 | S | Editable label persists after rename, save, and reload | Custom label text saved in DB, displayed on page reload | test_middle_label_persist | test_middle_label_persist_v2 | ⬜ |
| TCM-D121 | T | Multi-contributor columns correctly labelled (Teacher / Student / Parent / Peer) | Column headers differentiate data source with labels and distinct styling | test_middle_contributor_labels | test_middle_contributor_labels_v2 | ⬜ |
| TCM-D122 | U | Missing student self-assessment shows "Not yet submitted" message | Section displays empty-state message with muted styling, no error | test_middle_self_missing_state | test_middle_self_missing_state_v2 | ⬜ |
| TCM-D123 | V | Missing parent observation shows "No observation submitted" message | Empty-state message displayed in parent feedback section | test_middle_parent_missing_state | test_middle_parent_missing_state_v2 | ⬜ |
| TCM-D124 | W | Missing peer reviews shows "Peer reviews pending" message | Empty-state with counter "0 submissions received" | test_middle_peer_missing_state | test_middle_peer_missing_state_v2 | ⬜ |
| TCM-D125 | X | `out_*` value computed from `in_*` value on read via model accessor | Accessor transforms in_selected_value to out_selected_value (e.g. value→label mapping) | test_middle_out_value_computed | test_middle_out_value_computed_v2 | ⬜ |
| TCM-D126 | Y | `assessed_at` auto-set to current timestamp on item save | hpc_report_items.assessed_at = NOW() after save | test_middle_assessed_at_timestamp | test_middle_assessed_at_timestamp_v2 | ⬜ |
| TCM-D127 | Z | Remarks field stores free-text teacher comment per rubric item | Text saved in hpc_report_items.remark, displayed on reload | test_middle_remark_storage | test_middle_remark_storage_v2 | ⬜ |
| TCM-D128 | AA | Grid radio selection stored in hpc_report_table.selected_level | Value "Sky" or "Mountain" etc stored as VARCHAR in selected_level column | test_middle_grid_selected_level | test_middle_grid_selected_level_v2 | ⬜ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Blade @can Directives — Permission-based visibility for action buttons | View includes @can('tenant.hpc.view') for card page load, @can('tenant.hpc.create') for save button when creating new report, @can('tenant.hpc.update') for save button when updating existing report; expired permissions hide corresponding UI elements | — | — | ◌ |
| TC-CR02 | CR | P1 | Controller — DB Transactions in formStore | formStore() uses DB::beginTransaction + DB::commit/rollback with try-catch; all DB operations wrapped atomically; no partial data on exception | — | — | ◌ |
| TC-CR03 | CR | P1 | Controller — JSON Success/Error Response After Save | formStore() returns response()->json() with success: true/false and message; client-side JS handles display of success/error feedback to user | — | — | ◌ |
| TC-CR04 | CR | P1 | View — isset()/null-safe Checks for Auto-Fill Variables | Relationship expressions in Blade use isset($var->relation) / optional($var?->relation) / null-safe operator; no undefined index/property errors when LMS module tables absent or self-assessment not submitted | — | — | ◌ |
| TC-CR05 | CR | P1 | Route — Auth + Module Middleware Applied to All HPC Routes | All routes under /hpc prefix have auth middleware and module:HPC middleware; accessing HPC routes without authentication redirects to /login; disabled module returns 404 | — | — | ◌ |

---

## 7. Detailed Test Steps

#### TC-CR01: Blade @can Directives — Permission-based Visibility for Action Buttons

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect view file for hpc_form.blade.php | @can('tenant.hpc.view') wraps the card container; user without view permission does not see the form |
| 2 | Inspect save button rendering | @can('tenant.hpc.create') and @can('tenant.hpc.update') handle save button visibility based on whether creating or updating |
| 3 | Log in as user with tenant.hpc.view only | Card page loads in read-only mode; no save button visible |
| 4 | Log in as user with tenant.hpc.create only | Can create new report but cannot re-save (update) existing ones |
| 5 | Log in as user with all permissions | Card loads fully; save button visible and functional |

#### TC-CR02: Controller — DB Transactions in formStore

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open HpcController.php | Controller class found in Modules/Hpc/Http/Controllers/ |
| 2 | Inspect formStore() method | DB::beginTransaction() at start, try-catch block wrapping all DB operations |
| 3 | Verify commit path | DB::commit() called on successful save |
| 4 | Verify rollback path | DB::rollback() called in catch block on exception |
| 5 | Simulate DB failure during save | Transaction rolled back; no partial data persisted |
| 6 | Verify successful save | All hpc_report_items and hpc_report_table rows committed atomically |

#### TC-CR03: Controller — JSON Success/Error Response After Save

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Submit a valid save request to formStore() | Controller returns response()->json() |
| 2 | Verify JSON response after successful save | Response contains success: true and message: 'Saved successfully' |
| 3 | Submit invalid data (missing required field) | JSON response with success: false and validation error messages |
| 4 | Trigger exception during save | JSON response with success: false and error message; 500 status |
| 5 | Verify JS handles the response | Success flash message displayed on success; error alert on failure |

#### TC-CR04: View — isset()/null-safe Checks for Auto-Fill Variables

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open hpc_form.blade.php | View file found in hpc module resources |
| 2 | Scan for relationship access patterns (e.g. $student->guardians) | All such expressions use isset() or optional() or ?-> null-safe operator |
| 3 | Scan for foreach loops over relationships | Loop target checked with isset() or !empty() before iterating |
| 4 | Load card for student without self-assessment | View renders without undefined index/property error; "Self-assessment not yet submitted" shown |
| 5 | Load card with LMS module disabled | LMS sections show "LMS data not available"; no 500 errors |

#### TC-CR05: Route — Auth + Module Middleware Applied to All HPC Routes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open web.php route file for HPC module | Route group defined with /hpc prefix |
| 2 | Verify middleware stack on route group | auth and module:HPC middleware applied to all routes |
| 3 | Access GET /hpc/hpc-form/{id} while logged out | Redirected to /login |
| 4 | POST to /hpc/form/store while logged out | Redirected to /login |
| 5 | Access any HPC route with HPC module disabled | 404 Not Found via module:HPC middleware |
| 6 | Access routes while authenticated with module enabled | Routes accessible, HTTP 200 |

#### TCM-P10: Page loads with 46 tabs for valid Middle-grade student

**Pre-conditions:**
- Authenticated as teacher with `tenant.hpc.view` permission
- Student record exists in grade 8 with academic session, class, section
- Middle template configured with 46 parts

**Steps:**
1. Navigate to `GET /hpc/hpc-form/{student_id}` where student_id is a valid grade 8 student
2. Wait for DOM ready — wait for `.hpc-form-container` element to be visible
3. Count tab elements: `document.querySelectorAll('.nav-tabs .tab-item').length`
4. Assert tab count equals 46
5. Verify first tab has class `active` and label equals "School & Student Information"
6. Verify page title `<h1>` or equivalent renders correct student name
7. Check browser console for 0 JavaScript errors
8. Check network request completes with HTTP 200 status

**Expected:** 46 tabs render, first tab active, zero JS errors, page title correct, HTTP 200.

**V1 Test:** `test_middle_page_loads`
**V2 Test:** `test_middle_page_loads_v2`

---

#### TCM-P11: School information auto-filled on page 1

**Pre-conditions:**
- School settings configured with name, address, UDISE code, medium, affiliation number

**Steps:**
1. Load page 1 of Middle card
2. Locate school name field — assert value equals school name from settings
3. Locate address field — assert non-empty
4. Locate UDISE code field — assert 11 boxes visible
5. Locate pincode field — assert 6 boxes visible
6. Locate medium of instruction — assert value matches
7. Attempt to edit any school field — assert field is read-only/disabled

**Expected:** All school fields auto-filled, read-only, UDISE has 11 boxes, pincode has 6 boxes.

**V1 Test:** `test_middle_school_info`
**V2 Test:** `test_middle_school_info_v2`

---

#### TCM-P18: All 46 tabs navigable — each tab loads correct content

**Pre-conditions:**
- Card loaded for Middle student
- 46 tabs rendered in tab bar

**Steps:**
1. Verify first tab ("School & Student Information") is active
2. Click tab 2 ("Student Profile & Me") — assert content area updates, tab 2 becomes active
3. Click tab 3 (first subject page) — assert content updates
4. Click tab 10 (random middle tab) — assert correct content area
5. Click tab 46 (overall summary) — assert last page content loaded
6. Click tab 1 again — assert back to first page
7. For each tab click, verify URL hash updates (e.g. #tab-3)
8. Verify no 404 or JS errors on any tab switch

**Expected:** All 46 tabs navigable, content updates on click, no errors.

**V1 Test:** `test_middle_tab_navigation`
**V2 Test:** `test_middle_tab_navigation_v2`

---

#### TCM-P19: Subject rubric pages render with ASC radio buttons

**Pre-conditions:**
- Template configured with ASC rubrics for subject pages

**Steps:**
1. Navigate to first subject tab (e.g. English tab 3)
2. Locate rubric table with class `.asc-rubric-table`
3. Assert table has 4 radio columns: Stream, Mountain, Sky, Peak
4. Assert each rubric row has exactly 4 radio inputs
5. Click "Sky" radio in first row — verify it becomes checked
6. Click "Peak" radio in same row — verify Sky becomes unchecked, Peak checked
7. Verify rows below are unaffected by selection

**Expected:** 4-level ASC rubric renders, single-select radio behaviour per row.

**V1 Test:** `test_middle_asc_rubric_render`
**V2 Test:** `test_middle_asc_rubric_render_v2`

---

#### TCM-P40: Save ASC rubric radio selection

**Pre-conditions:**
- Card loaded for Middle student
- Subject page with ASC rubric visible

**Steps:**
1. On page 3 (English), select "Sky" for rubric row 1
2. Select "Mountain" for rubric row 2
3. Select "Peak" for rubric row 3
4. Leave rubric row 4 unselected
5. Switch to page 10 (Physics), select "Stream" for rubric row 1
6. Click Save button at bottom
7. Wait for success flash message "Saved successfully"
8. Reload the page
9. Navigate to page 3 — verify row 1 = Sky, row 2 = Mountain, row 3 = Peak, row 4 = null
10. Navigate to page 10 — verify row 1 = Stream
11. Check DB: hpc_report_table has rows with correct report_id, rubric_item_id, selected_level

**Expected:** Rubric selections persist after save and reload across all pages.

**V1 Test:** `test_middle_save_rubric_radio`
**V2 Test:** `test_middle_save_rubric_radio_v2`

---

#### TCM-P49: Save ALL 46 pages at once

**Pre-conditions:**
- Card loaded for Middle student
- Rubric selections, comments, attendance filled across multiple pages

**Steps:**
1. Fill rubric selections on pages 3, 5, 10, 15, 20, 25, 30, 35, 40, 45 (10 pages)
2. Enter attendance data on page 1 for all 12 months
3. Enter text comments on 3 rubric items
4. Enter numeric scores on 2 rubric items
5. Click Save button
6. Assert success message appears
7. Verify DB: 46 pages' worth of data saved in hpc_report_items
8. Verify DB: hpc_reports updated_at changed
9. Verify no data loss across any page

**Expected:** Single save persists data for all 46 pages atomically.

**V1 Test:** `test_middle_save_all_pages`
**V2 Test:** `test_middle_save_all_pages_v2`

---

#### TCM-N70: Load page with invalid non-existent student_id

**Pre-conditions:**
- Authenticated as teacher with HPC view permission

**Steps:**
1. Navigate to `GET /hpc/hpc-form/999999` (non-existent student ID)
2. Observe HTTP response status code
3. If redirect, follow redirect and check flash message
4. Assert no card data is loaded

**Expected:** 404 Not Found page or redirect to student list with error "Student not found."

**V1 Test:** `test_middle_invalid_student`
**V2 Test:** `test_middle_invalid_student_v2`

---

#### TCM-N83: User without tenant.hpc.view permission

**Pre-conditions:**
- Authenticated as user (e.g. clerk role) without `tenant.hpc.view`
- Valid student ID in grade 8

**Steps:**
1. Navigate to `GET /hpc/hpc-form/{valid_student_id}`
2. Observe HTTP response

**Expected:** 403 Forbidden — AuthorizationException thrown by Gate::authorize().

**V1 Test:** `test_middle_permission_denied_view`
**V2 Test:** `test_middle_permission_denied_view_v2`

---

#### TCM-D104: SoftDeletes on HpcReport

**Pre-conditions:**
- Existing HpcReport record for Middle student with associated hpc_report_items

**Steps:**
1. Load HpcReport model from DB — assert deleted_at IS NULL
2. Call `$report->delete()`
3. Query without withTrashed() — assert report NOT returned
4. Query with withTrashed() — assert report returned, deleted_at NOT NULL
5. Assert hpc_report_items still exist (items NOT cascade on soft-delete)
6. Call `$report->restore()` — assert deleted_at becomes NULL
7. Query default — assert report returned again

**Expected:** Soft-delete sets deleted_at, hides from default queries, preserves items, restorable.

**V1 Test:** `test_middle_softdelete`
**V2 Test:** `test_middle_softdelete_v2`

---

#### TCM-D111: ASC rubric single-select per row

**Pre-conditions:**
- Card loaded with ASC rubric table on a subject page

**Steps:**
1. On rubric row 1, click "Stream" radio — verify checked
2. Click "Sky" radio on same row — verify Stream unchecked, Sky checked
3. Click "Mountain" radio on same row — verify Sky unchecked, Mountain checked
4. On rubric row 2, click "Peak" — verify Peak checked
5. On rubric row 3, click "Stream" — verify Stream checked
6. Verify row 2 and row 3 selections are independent of each other
7. Verify row 1 still has "Mountain" selected (unchanged)

**Expected:** Only one radio selected per row. Row selections independent.

**V1 Test:** `test_middle_rubric_single_select`
**V2 Test:** `test_middle_rubric_single_select_v2`

---

## Test Method Index

### File: `lms_HPC_Middle_TestCas.php` (113 methods)

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_middle_page_loads | TCM-P10 | UI | 10-19 |
| 2 | test_middle_school_info | TCM-P11 | UI | 10-19 |
| 3 | test_middle_student_details | TCM-P12 | UI | 10-19 |
| 4 | test_middle_parent_details | TCM-P13 | UI | 10-19 |
| 5 | test_middle_demographics | TCM-P14 | UI | 10-19 |
| 6 | test_middle_health_measurements | TCM-P15 | UI | 10-19 |
| 7 | test_middle_attendance_rows | TCM-P16 | UI | 10-19 |
| 8 | test_middle_self_intro | TCM-P17 | UI | 10-19 |
| 9 | test_middle_tab_navigation | TCM-P18 | Nav | 10-19 |
| 10 | test_middle_asc_rubric_render | TCM-P19 | UI | 10-19 |
| 11 | test_middle_competency_codes | TCM-P20 | UI | 10-19 |
| 12 | test_middle_lms_data_prefill | TCM-P21 | Biz | 20-29 |
| 13 | test_middle_self_assessment_view | TCM-P22 | UI | 20-29 |
| 14 | test_middle_parent_observation | TCM-P23 | UI | 20-29 |
| 15 | test_middle_peer_review | TCM-P24 | UI | 20-29 |
| 16 | test_middle_life_skills | TCM-P25 | UI | 20-29 |
| 17 | test_middle_cocurricular | TCM-P26 | UI | 20-29 |
| 18 | test_middle_values_education | TCM-P27 | UI | 20-29 |
| 19 | test_middle_vocational | TCM-P28 | UI | 20-29 |
| 20 | test_middle_pe_pages | TCM-P29 | UI | 20-29 |
| 21 | test_middle_grade7_load | TCM-P30 | Biz | 30-39 |
| 22 | test_middle_grade10_load | TCM-P31 | Biz | 30-39 |
| 23 | test_middle_drag_handle | TCM-P32 | UI | 30-39 |
| 24 | test_middle_editable_label | TCM-P33 | UI | 30-39 |
| 25 | test_middle_pdf_preview | TCM-P34 | Biz | 30-39 |
| 26 | test_middle_first_tab_active | TCM-P35 | UI | 30-39 |
| 27 | test_middle_aadhar_boxes | TCM-P36 | UI | 30-39 |
| 28 | test_middle_student_photo | TCM-P37 | UI | 30-39 |
| 29 | test_middle_add_friend | TCM-P38 | UI | 30-39 |
| 30 | test_middle_save_rubric_radio | TCM-P40 | Biz | 40-49 |
| 31 | test_middle_save_text_comment | TCM-P41 | Biz | 40-49 |
| 32 | test_middle_save_numeric | TCM-P42 | Biz | 40-49 |
| 33 | test_middle_save_boolean | TCM-P43 | Biz | 40-49 |
| 34 | test_middle_save_dropdown | TCM-P44 | Biz | 40-49 |
| 35 | test_middle_save_checkbox | TCM-P45 | Biz | 40-49 |
| 36 | test_middle_save_image | TCM-P46 | Biz | 40-49 |
| 37 | test_middle_save_file | TCM-P47 | Biz | 40-49 |
| 38 | test_middle_save_attendance | TCM-P48 | Biz | 40-49 |
| 39 | test_middle_save_all_pages | TCM-P49 | Biz | 40-49 |
| 40 | test_middle_reopen_data | TCM-P50 | Biz | 50-59 |
| 41 | test_middle_first_save_creates | TCM-P51 | Biz | 50-59 |
| 42 | test_middle_subsequent_save | TCM-P52 | Biz | 50-59 |
| 43 | test_middle_report_date_default | TCM-P53 | Biz | 50-59 |
| 44 | test_middle_prepared_by | TCM-P54 | Biz | 50-59 |
| 45 | test_middle_attendance_percent | TCM-P55 | Biz | 50-59 |
| 46 | test_middle_academic_subjects_save | TCM-P56 | Biz | 50-59 |
| 47 | test_middle_life_skills_save | TCM-P57 | Biz | 50-59 |
| 48 | test_middle_cocurricular_save | TCM-P58 | Biz | 50-59 |
| 49 | test_middle_values_save | TCM-P59 | Biz | 60-69 |
| 50 | test_middle_vocational_save | TCM-P60 | Biz | 60-69 |
| 51 | test_middle_pe_save | TCM-P61 | Biz | 60-69 |
| 52 | test_middle_self_readonly | TCM-P62 | Val | 60-69 |
| 53 | test_middle_parent_readonly | TCM-P63 | Val | 60-69 |
| 54 | test_middle_peer_readonly | TCM-P64 | Val | 60-69 |
| 55 | test_middle_empty_rubric_save | TCM-P65 | Biz | 60-69 |
| 56 | test_middle_transaction_commit | TCM-P66 | Biz | 60-69 |
| 57 | test_middle_transaction_rollback | TCM-P67 | Biz | 60-69 |
| 58 | test_middle_invalid_student | TCM-N70 | Edge | 70-79 |
| 59 | test_middle_deleted_student | TCM-N71 | Edge | 70-79 |
| 60 | test_middle_deleted_template | TCM-N72 | Edge | 70-79 |
| 61 | test_middle_missing_template_id | TCM-N73 | Val | 70-79 |
| 62 | test_middle_missing_student_id | TCM-N74 | Val | 70-79 |
| 63 | test_middle_missing_session_id | TCM-N75 | Val | 70-79 |
| 64 | test_middle_missing_term_id | TCM-N76 | Val | 70-79 |
| 65 | test_middle_missing_class_id | TCM-N77 | Val | 70-79 |
| 66 | test_middle_missing_section_id | TCM-N78 | Val | 70-79 |
| 67 | test_middle_numeric_type_mismatch | TCM-N79 | Val | 80-89 |
| 68 | test_middle_boolean_type_mismatch | TCM-N80 | Val | 80-89 |
| 69 | test_middle_select_invalid_option | TCM-N81 | Val | 80-89 |
| 70 | test_middle_concurrent_save | TCM-N82 | Concur | 80-89 |
| 71 | test_middle_permission_denied_view | TCM-N83 | Auth | 80-89 |
| 72 | test_middle_permission_denied_create | TCM-N84 | Auth | 80-89 |
| 73 | test_middle_permission_denied_update | TCM-N85 | Auth | 80-89 |
| 74 | test_middle_guest_access | TCM-N86 | Auth | 80-89 |
| 75 | test_middle_duplicate_term_student | TCM-N87 | Biz | 80-89 |
| 76 | test_middle_lms_fallback | TCM-N88 | Biz | 90-99 |
| 77 | test_middle_attendance_zero_working | TCM-N89 | Edge | 90-99 |
| 78 | test_middle_attendance_exceed | TCM-N90 | Val | 90-99 |
| 79 | test_middle_wrong_grade_student | TCM-N91 | Edge | 90-99 |
| 80 | test_middle_invalid_json | TCM-N92 | Val | 90-99 |
| 81 | test_middle_image_size_exceed | TCM-N93 | Val | 90-99 |
| 82 | test_middle_file_type_invalid | TCM-N94 | Val | 90-99 |
| 83 | test_middle_module_disabled_route | TCM-N95 | Auth | 90-99 |
| 84 | test_middle_cross_class_access | TCM-N96 | Auth | 90-99 |
| 85 | test_middle_template_selection | TCM-D100 | Arch | 100-109 |
| 86 | test_middle_transaction_wrapper | TCM-D101 | Arch | 100-109 |
| 87 | test_middle_unique_constraint | TCM-D102 | DB | 100-109 |
| 88 | test_middle_report_items_cascade | TCM-D103 | DB | 100-109 |
| 89 | test_middle_softdelete | TCM-D104 | DB | 100-109 |
| 90 | test_middle_softdelete_restore | TCM-D105 | DB | 100-109 |
| 91 | test_middle_softdelete_items | TCM-D106 | DB | 100-109 |
| 92 | test_middle_get_student_value | TCM-D107 | Arch | 100-109 |
| 93 | test_middle_role_field_filtering | TCM-D108 | Arch | 110-119 |
| 94 | test_middle_attendance_compute_timing | TCM-D109 | Biz | 110-119 |
| 95 | test_middle_report_table_storage | TCM-D110 | DB | 110-119 |
| 96 | test_middle_rubric_single_select | TCM-D111 | UI | 110-119 |
| 97 | test_middle_part_count_sequence | TCM-D112 | Arch | 110-119 |
| 98 | test_middle_save_button_disable | TCM-D113 | UI | 110-119 |
| 99 | test_middle_pdf_layout_type | TCM-D114 | Arch | 110-119 |
| 100 | test_middle_image_storage_path | TCM-D115 | Biz | 120-129 |
| 101 | test_middle_attendance_add_row | TCM-D116 | UI | 120-129 |
| 102 | test_middle_attendance_remove_confirm | TCM-D117 | UI | 120-129 |
| 103 | test_middle_three_column_layout | TCM-D118 | UI | 120-129 |
| 104 | test_middle_drag_persist | TCM-D119 | Biz | 120-129 |
| 105 | test_middle_label_persist | TCM-D120 | Biz | 120-129 |
| 106 | test_middle_contributor_labels | TCM-D121 | UI | 120-129 |
| 107 | test_middle_self_missing_state | TCM-D122 | UI | 130-139 |
| 108 | test_middle_parent_missing_state | TCM-D123 | UI | 130-139 |
| 109 | test_middle_peer_missing_state | TCM-D124 | UI | 130-139 |
| 110 | test_middle_out_value_computed | TCM-D125 | Biz | 130-139 |
| 111 | test_middle_assessed_at_timestamp | TCM-D126 | Biz | 130-139 |
| 112 | test_middle_remark_storage | TCM-D127 | Biz | 130-139 |
| 113 | test_middle_grid_selected_level | TCM-D128 | DB | 130-139 |

**Total: 113 methods**

---

### Execution Status

| Cycle | Date | Tester | Pass | Fail | Blocked | Not Executed | Signature |
|-------|------|--------|------|------|---------|--------------|-----------|
| V1 | — | — | — | — | — | 113 | — |
| V2 | — | — | — | — | — | 113 | — |

---

*Test cases derived from HPC Teacher Card Middle requirement document (BV3), HpcController code analysis, migration schema, and BC-DB/BC-VAL/BC-AUTH/BC-BIZ/BC-REF conditions. Covers grades 7-10 with 46-page Middle template.*
## 8. CODE-TRACE: Controller Method Execution Traces

### CODE-TRACE-01: `index()` � HpcController (Line 56)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcController.php:58` | `$this->authorizeHpcIndex()` � calls `Gate::authorize('tenant.hpc.viewAny')` via HpcIndexDataTrait |
| 2 | `HpcIndexDataTrait.php:28-49` | `$this->getHpcIndexData()` � loads sessions, terms, classes, sections, and paginated students |
| 3 | `HpcController.php:63-64` | `SchoolClass::active()->get()`, `Section::active()->get()` � load filter dropdowns |
| 4 | `HpcController.php:65` | `$this->getFilteredStudents($request)->paginate(10)` � filters by class/section/session/term |
| 5 | `HpcController.php:67` | `return view('hpc::hpc.index', $data)` � renders HPC dashboard/student list |

### CODE-TRACE-02: `hpc_form()` � HpcController (Line 301)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcController.php:303` | `Gate::authorize('tenant.hpc.view')` |
| 2 | `HpcController.php:305-310` | Validates request: student_id, academic_session_id, term_id, template_id |
| 3 | `HpcController.php:312-318` | Loads template with nested relations: `->with('parts.sections.rubrics.items')` |
| 4 | `HpcController.php:320-330` | Groups template parts by `page_no` for paginated form rendering |
| 5 | `HpcController.php:332-340` | Loads `Student` with `currentClassSection`, `currentAcademicSession`, `guardians` |
| 6 | `HpcController.php:342-360` | Computes sibling data via `StudentGuardianJnt` |
| 7 | `HpcController.php:362-400` | Server-side attendance aggregation: 2-query batch (present/absence grouped by month), illness keyword counting |
| 8 | `HpcController.php:402-410` | Upserts attendance data to `HpcTemplateSectionTable` |
| 9 | `HpcController.php:412-440` | Loads saved values via `reportService->getSavedValues()` |
| 10 | `HpcController.php:442-460` | Auto-feeds LMS data via `HpcDataMappingService::mergeIntoSavedValues()` |
| 11 | `HpcController.php:462-480` | Returns template-specific view: `third_form` for Middle (template_id=3) |

### CODE-TRACE-03: `formStore()` � HpcController (Line 670)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcController.php:672-676` | `Gate::authorize('tenant.hpc.update')` � checks update permission |
| 2 | `HpcController.php:678-705` | Validates request: student_id, template_id, academic_session_id, term_id, class_id, section_id, status |
| 3 | `HpcController.php:707-720` | Loads template with `parts.sections.rubrics.items` � nested eager load |
| 4 | `HpcController.php:722-740` | Builds 4 mappings: `$fieldMapping`, `$globalRubricMapping`, `$tableMapping`, `$tableCellMapping` |
| 5 | `HpcController.php:742-760` | Normalizes `_hidden`/`_empty` fields from form data |
| 6 | `HpcController.php:762-780` | Applies role-based section locking via `HpcSectionRoleService::filterPayloadByRole()` |
| 7 | `HpcController.php:782-850` | Routes fields: explicit tableMapping, tableCellMapping, attendance (working_days_, days_present_), `page_N_cell_R_C` pattern, checkbox arrays (strengths/barriers?JSON), pincode/UDISE, scalars |
| 8 | `HpcController.php:852-870` | Processes file uploads via `processFileUploads()` |
| 9 | `HpcController.php:872-880` | Calls `$this->reportService->saveReport()` with named arguments |
| 10 | `HpcController.php:882-890` | Catches `ValidationException`, `QueryException`, `Exception` � returns JSON error |

### CODE-TRACE-04: Workflow Methods � HpcController

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `submitReport()` (Line 1856) | `Gate::authorize('tenant.hpc.update')` ? `HpcWorkflowService::finalize()` ? JSON |
| 2 | `reviewReport()` (Line 1875) | `Gate::authorize('tenant.hpc.review')` ? `HpcWorkflowService::publish()` ? JSON |
| 3 | `approveReport()` (Line 1894) | `Gate::authorize('tenant.hpc.review')` ? `HpcWorkflowService::finalize()` ? JSON |
| 4 | `sendBackReport()` (Line 1913) | `Gate::authorize('tenant.hpc.review')` ? `HpcWorkflowService::sendBackToDraft()` ? JSON |
| 5 | `publishReport()` (Line 1932) | `Gate::authorize('tenant.hpc.publish')` ? `HpcWorkflowService::publish()` ? JSON |
| 6 | `archiveReport()` (Line 1951) | `Gate::authorize('tenant.hpc.update')` ? `HpcWorkflowService::archive()` ? JSON |
| 7 | `workflowStatus()` (Line 1970) | `Gate::authorize('tenant.hpc.view')` ? `HpcWorkflowService::getAuditInfo()` ? JSON |

---
