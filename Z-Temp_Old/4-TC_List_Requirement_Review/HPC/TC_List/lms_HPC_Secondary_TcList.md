# lms_HPC_Secondary — Test Case List & Business Conditions

**Module:** HPC (Holistic Progress Card, CODE `HPC`, prefix `lms_HPC_`) · **Feature:** Teacher Card — Secondary (BV4)
**DB scope:** TENANT-side (`hpc_*` → tenant DB) · **Test style:** Browser Dusk (`extends DuskTestCase`)
**Primary tables:** `hpc_reports`, `hpc_report_items`, `hpc_report_table` · **Module URL prefix:** `/hpc`
**Test file:** `lms_HPC_Secondary_TestCas.php`
**Grade band:** Class 11th, 12th · **Total pages:** 44

---

## 1. Feature Information

| Field | Value |
|-------|-------|
| Module | HPC (Holistic Progress Card) |
| Tab Group | Teacher Card |
| Feature | Teacher Card - Secondary (BV4) |
| URL(s) | `hpc/hpc-form/{student_id}` (GET), `hpc/form/store` (POST) |
| Controller | `Modules\Hpc\Http\Controllers\HpcController` (methods: `hpc_form`, `formStore`) |
| Model(s) | `Modules\Hpc\Models\HpcTemplates`, `Modules\Hpc\Models\HpcReport`, `Modules\Hpc\Models\HpcReportItem`, `Modules\Hpc\Models\HpcReportTable` |
| Validation | Inline validation in `HpcController@formStore` (no FormRequest) |
| Permissions | `tenant.hpc.view` (read), `tenant.hpc.create` (first save), `tenant.hpc.update` (subsequent saves) |
| Soft Deletes | Yes — `HpcReport` uses `SoftDeletes` trait |
| Activity Log | None |
| Unique Features | Stream-based subject filtering, NCrF Credits, Goals & Aspirations wizard, 5-level ASC rubric (Summit) |

---

## 2. Pre-conditions

| # | Pre-condition | Details |
|---|---------------|---------|
| PC-01 | Authenticated teacher user | Logged in as teacher role with HPC permissions |
| PC-02 | Student record exists | Student enrolled in grade 11-12 with class/section/academic session/stream |
| PC-03 | HPC template configured | Secondary template (`template_id` 55+) with 44 parts created in Template Management |
| PC-04 | Academic term active | Valid `academic_session_id` and `term_id` exist for current year |
| PC-05 | Student profile data | Admission details, parent/guardian info, address, health records, stream assignment exist |
| PC-06 | LMS module available (optional) | LMS exam scores, quiz results, homework data may exist for auto-fill |
| PC-07 | Browser JavaScript enabled | 44-tab navigation, ASC rubric radio selection, drag-drop require JS |
| PC-08 | Database transaction support | InnoDB engine for `DB::beginTransaction`/`commit`/`rollback` in `formStore` |
| PC-09 | Student self-assessment submitted | Student has completed self-assessment via Student Portal |
| PC-10 | Parent observation submitted | Parent has filled observation form via Parent Portal |
| PC-11 | Peer reviews completed | At least 3 peer reviews submitted for collaborative rubric |
| PC-12 | Attendance data seeded | Monthly attendance records for Apr-Mar academic year exist |
| PC-13 | Student stream assigned | Student has stream (Science/Commerce/Arts) set in academic records for subject filtering |
| PC-14 | NCrF credit configuration | Credit values configured for subjects and activities per government guidelines |
| PC-15 | Goals & Aspirations submitted | Student has completed career goal wizard via Student Portal |

---

## 3. Default Data Load

| Data Element | Source | Auto-fill Behaviour |
|-------------|--------|---------------------|
| School name, address, UDISE code | School settings | Auto-filled on page 1, read-only |
| Student name, admission no, roll no | `std_students` | Auto-filled on page 1, read-only |
| Date of birth, gender, class, section | `std_students` | Auto-filled on page 1, read-only |
| Stream assignment (Science/Commerce/Arts) | `std_students` | Auto-filled, determines visible subject pages |
| Parent/guardian names, phone, occupation | `std_guardians` via junction | Auto-filled on page 1, read-only |
| Address, pincode, religion, caste | `std_student_addresses` | Auto-filled on page 1, read-only |
| Height, weight, blood group | `std_health_profiles` | Auto-filled on page 1, read-only |
| Aadhar + APAAR ID digit boxes | Student records | 12 boxes for Aadhar, separate ID boxes for APAAR |
| Birth certificate number | Student records | Auto-filled on page 1 |
| Attendance (Apr-Mar monthly rows) | Attendance module aggregation | Auto-calculated %, teacher enters working/present days |
| Student self-intro (dream job, friends) | Student Portal (self-assessment) | Auto-filled on page 2, read-only |
| LMS exam scores, quiz results, homework | LMS module | Auto-filled in grey boxes, read-only |
| Peer review averages | Peer review module | Auto-filled in dedicated section, read-only |
| Parent observation text | Parent Portal | Auto-filled in parent feedback section, read-only |
| Rubric items and ASC levels | `hpc_report_table` + template config | Empty radio buttons, teacher selects |
| Competency mapping codes | Template configuration | Auto-displayed badges, read-only |
| Stream-specific subject rubrics | Template configuration | Only subjects matching student's stream are shown |
| Goals & Aspirations wizard data | Student Portal | Auto-filled on Goals pages, read-only; teacher adds comments |
| NCrF Credit Summary | Auto-calculated from grade + subjects | Auto-filled credit totals per subject and activity |

---

## 4. Test Data Strategy

| Strategy | Approach |
|----------|----------|
| Student data | Create test student records in grades 11, 12 with complete profile data including stream assignment |
| Stream data | Create students in all 3 streams: Science, Commerce, Arts to verify subject filtering |
| Template data | Create Secondary template with 44 parts, sections, rubrics, and items for each stream |
| Attendance data | Generate 12-month attendance records (Apr-Mar) with varied working/present days |
| LMS data | Seed exam scores and quiz results for at least 3 subjects with known values |
| Self-assessment | Submit student self-assessment for 3 subjects via Student Portal seed |
| Parent observation | Submit parent observation form for the test student |
| Peer review | Generate 5 peer review submissions with calculated averages |
| Goals data | Submit Goals & Aspirations wizard data for test student via Student Portal |
| NCrF credit data | Configure subject credit values and activity credit values per government framework |
| Boundary data | Test minimum (1 rubric row) and maximum (all 44 pages filled) data volumes |
| Negative data | Invalid student IDs, missing required fields, type-mismatched rubric values, wrong stream |
| Concurrent data | Simultaneous save requests from different sessions for the same student |
| Permission data | Create users with varying permission sets (view-only, create, update, none) |
| Grade boundary | Test students at grade 11 (lower bound) and grade 12 (upper bound) |

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
| BC-DB-53 | hpc_report_table.summit_value | BOOLEAN | DEFAULT 0 |
| BC-DB-54 | hpc_report_table.selected_level | VARCHAR(20) | NULLABLE |
| BC-DB-55 | hpc_report_table.created_at | TIMESTAMP | NULLABLE |
| BC-DB-56 | hpc_report_table.updated_at | TIMESTAMP | NULLABLE |
| BC-DB-57 | hpc_report_table — UNIQUE | (report_id, rubric_item_id) | UNIQUE composite |
| BC-DB-58 | hpc_templates.id | BIGINT PK | Auto-increment |
| BC-DB-59 | hpc_templates.code | VARCHAR(100) | UNIQUE NOT NULL |
| BC-DB-60 | hpc_templates.title | VARCHAR(255) | NOT NULL |
| BC-DB-61 | hpc_templates.version | INT | DEFAULT 1 |
| BC-DB-62 | hpc_templates.applicable_grades | JSON | NOT NULL |
| BC-DB-63 | hpc_templates.is_active | BOOLEAN | DEFAULT 1 |
| BC-DB-64 | hpc_templates.created_at | TIMESTAMP | NULLABLE |
| BC-DB-65 | hpc_templates.updated_at | TIMESTAMP | NULLABLE |
| BC-DB-66 | hpc_templates.deleted_at | TIMESTAMP | NULLABLE (SoftDeletes) |
| BC-DB-67 | hpc_templates_part.id | BIGINT PK | Auto-increment |
| BC-DB-68 | hpc_templates_part.template_id | INT FK → hpc_templates.id ON DELETE CASCADE | NOT NULL |
| BC-DB-69 | hpc_templates_part.code | VARCHAR(100) | — |
| BC-DB-70 | hpc_templates_part.description | VARCHAR(255) | — |
| BC-DB-71 | hpc_templates_part.display_order | INT | — |
| BC-DB-72 | hpc_templates_part.page_no | INT | — |
| BC-DB-73 | hpc_templates_part.has_items | BOOLEAN | DEFAULT 0 |
| BC-DB-74 | hpc_templates_part.help_file | VARCHAR(255) | NULLABLE |
| BC-DB-75 | hpc_templates_part.created_at | TIMESTAMP | NULLABLE |
| BC-DB-76 | hpc_templates_part.updated_at | TIMESTAMP | NULLABLE |
| BC-DB-77 | hpc_templates_section.id | BIGINT PK | Auto-increment |
| BC-DB-78 | hpc_templates_section.part_id | INT FK → hpc_templates_part.id ON DELETE CASCADE | NOT NULL |
| BC-DB-79 | hpc_templates_section.code | VARCHAR(100) | — |
| BC-DB-80 | hpc_templates_section.title | VARCHAR(255) | — |
| BC-DB-81 | hpc_templates_section.display_order | INT | — |
| BC-DB-82 | hpc_templates_section.created_at | TIMESTAMP | NULLABLE |
| BC-DB-83 | hpc_templates_section.updated_at | TIMESTAMP | NULLABLE |
| BC-DB-84 | hpc_rubrics.id | BIGINT PK | Auto-increment |
| BC-DB-85 | hpc_rubrics.section_id | INT FK → hpc_templates_section.id ON DELETE CASCADE | NOT NULL |
| BC-DB-86 | hpc_rubrics.code | VARCHAR(100) | — |
| BC-DB-87 | hpc_rubrics.title | VARCHAR(255) | — |
| BC-DB-88 | hpc_rubrics.rubric_type | ENUM('radio','dropdown','numeric','text','boolean','checkbox','image','file','json') | NOT NULL |
| BC-DB-89 | hpc_rubrics.display_order | INT | — |
| BC-DB-90 | hpc_rubrics.created_at | TIMESTAMP | NULLABLE |
| BC-DB-91 | hpc_rubrics.updated_at | TIMESTAMP | NULLABLE |
| BC-DB-92 | hpc_rubric_items.id | BIGINT PK | Auto-increment |
| BC-DB-93 | hpc_rubric_items.rubric_id | INT FK → hpc_rubrics.id ON DELETE CASCADE | NOT NULL |
| BC-DB-94 | hpc_rubric_items.code | VARCHAR(100) | — |
| BC-DB-95 | hpc_rubric_items.label | VARCHAR(255) | — |
| BC-DB-96 | hpc_rubric_items.item_type | ENUM('radio','dropdown','numeric','text','boolean','checkbox','image','file','json') | NOT NULL |
| BC-DB-97 | hpc_rubric_items.options | JSON | NULLABLE |
| BC-DB-98 | hpc_rubric_items.display_order | INT | — |
| BC-DB-99 | hpc_rubric_items.is_required | BOOLEAN | DEFAULT 0 |
| BC-DB-100 | hpc_rubric_items.created_at | TIMESTAMP | NULLABLE |
| BC-DB-101 | hpc_rubric_items.updated_at | TIMESTAMP | NULLABLE |
| BC-DB-102 | `hpc_reports.report_date` nullable DATE | DATE | DEFAULT NULL; set on first save if provided, else defaults to today |
| BC-DB-103 | `hpc_reports.prepared_by` FK → sys_users.id | INT FK | Auto-set to current authenticated user ID |
| BC-DB-104 | `hpc_report_items.assessed_by` nullable FK → sys_users.id | INT FK | Set to teacher user ID when teacher assesses |
| BC-DB-105 | `hpc_report_items.assessed_at` nullable TIMESTAMP | TIMESTAMP | Auto-set to NOW() when item is saved |
| BC-DB-106 | All `hpc_*` tables — engine | InnoDB | utf8mb4_unicode_ci charset |
| BC-DB-107 | Cascade DELETE: hpc_reports → hpc_report_items, hpc_report_table | FK ON DELETE CASCADE | No orphan records |
| BC-DB-108 | `HpcReport` model — SoftDeletes trait | table: hpc_reports | fillable: [academic_session_id, term_id, student_id, class_id, section_id, template_id, prepared_by, report_date, status] casts: [status => 'string', report_date => 'date', deleted_at => 'datetime'] |
| BC-DB-109 | `HpcReportItem` model | table: hpc_report_items | fillable: [report_id, template_id, rubric_id, rubric_item_id, in_numeric_value, in_text_value, in_boolean_value, in_selected_value, in_image_path, in_filename, in_filepath, in_json_value, out_numeric_value, out_text_value, out_boolean_value, out_selected_value, out_image_path, out_filename, out_filepath, out_json_value, remark, assessed_by, assessed_at] |
| BC-DB-110 | `HpcReportTable` model | table: hpc_report_table | fillable: [report_id, rubric_item_id, rubric_id, stream_value, mountain_value, sky_value, peak_value, summit_value, selected_level] |

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
| BC-VAL-19 | Student grade | must be in range 11-12 for Secondary template — controller validates before loading | — |
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
| BC-BIZ-01 | Template resolution from student's grade | Grade 11-12 maps to Secondary template (template_id 55+, code 'HPC-SEC') |
| BC-BIZ-02 | Stream-based subject filtering | Only subjects matching student's stream (Science/Commerce/Arts) rendered; non-matching subject pages hidden |
| BC-BIZ-03 | 44-tab navigation system | Each tab corresponds to a `hpc_templates_part` record with sequential display_order |
| BC-BIZ-04 | Multi-contributor data merge | Teacher assessment + student self-assessment + parent observation + peer review all visible on one card |
| BC-BIZ-05 | ASC rubric tables | 5 performance levels: Stream (A/Beginning), Mountain (B/Developing), Sky (C/Proficient), Peak (D/Advanced), Summit (E/Exemplary) |
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
| BC-BIZ-21 | PDF preview | Full 44-page document using DomPDF; school header, student details, all 44 pages |
| BC-BIZ-22 | Save ALL 44 pages single request | All rubric items, attendance, comments sent as nested array |
| BC-BIZ-23 | Empty rubric rows stored as NULL | No radio selected, no text entered → stored as NULL, not empty string or 0 |
| BC-BIZ-24 | File uploads storage | Tenant-specific: storage/tenant_{id}/hpc/{report_id}/ |
| BC-BIZ-25 | in_json_value complex structures | Checkbox arrays as ["opt1","opt3"]; competency mappings as {"comp_code":"SCI.12.M.01","level":"Sky"} |
| BC-BIZ-26 | out_* fields computed on read | From in_* values via transformation rules — e.g. out_selected_value = label of selected option |
| BC-BIZ-27 | Add attendance row | Dynamically inserts new monthly row with empty values, removable via delete button |
| BC-BIZ-28 | Remove attendance row | Confirmation dialog "Are you sure you want to delete this row?" before removal |
| BC-BIZ-29 | Three-column layout | Fields wrap into 3 equal-width columns within each section |
| BC-BIZ-30 | LMS auto-fill graceful fallback | If LMS tables absent, section shows "LMS data not available" |
| BC-BIZ-31 | Missing student self-assessment | Section shows "Self-assessment not yet submitted" with muted styling |
| BC-BIZ-32 | Missing parent observation | Section shows "No parent observation submitted for this term" |
| BC-BIZ-33 | Missing peer reviews | Section shows "Peer reviews pending — 0 submissions received" |
| BC-BIZ-34 | Report table grid stores ASC selections | Each row stores level (stream/mountain/sky/peak/summit) for each rubric_item in hpc_report_table |
| BC-BIZ-35 | Radio single-select behavior | Clicking radio deselects previously selected radio in same row, other rows unaffected |
| BC-BIZ-36 | Student grade validation | If student not in grade 11-12, Secondary template not loaded — redirect or error |
| BC-BIZ-37 | prepared_by auto-set | auth()->id() on create, not updatable on subsequent saves |
| BC-BIZ-38 | assessed_at auto-set | now() each time rubric item is saved |
| BC-BIZ-39 | Unique constraint violation handling | Caught gracefully — existing record updated instead of error |
| BC-BIZ-40 | PDF generation layout by template_id | 1-18 Foundation, 19-36 Preparatory, 37-54 Middle, 55+ Secondary |
| BC-BIZ-41 | NCrF Credit auto-calculation | Credits computed from grade level + subjects per government framework; displayed in NCrF Credit Summary page |
| BC-BIZ-42 | Goals & Aspirations auto-fill | Student's career goal wizard answers auto-filled from Student Portal; teacher adds comments and endorsements |
| BC-BIZ-43 | Stream switch detection | If student changes stream, subject pages automatically update to match new stream subjects |
| BC-BIZ-44 | Summit level in ASC rubric | 5th level (Summit/Exemplary) available for Secondary rubrics; Summit = can teach others, creates new knowledge |
| BC-BIZ-45 | NCrF credit display | Subject-wise credits, activity credits, total credits, credits earned in previous years displayed in summary section |

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
| TCS-P10 | Page loads with 44 tabs for valid Secondary-grade student in grade 12 | 44 tab headers visible, first tab active, no JS console errors | test_secondary_page_loads | test_secondary_page_loads_v2 | ⬜ |
| TCS-P11 | School information auto-filled on page 1 | School name, address, UDISE code, medium of instruction displayed, all read-only | test_secondary_school_info | test_secondary_school_info_v2 | ⬜ |
| TCS-P12 | Student details auto-filled from admission records on page 1 | Full name, DOB, gender, admission no, roll no, class, section, stream, house displayed | test_secondary_student_details | test_secondary_student_details_v2 | ⬜ |
| TCS-P13 | Stream label displayed correctly on page 1 | Stream (Science/Commerce/Arts) shown in student details section, read-only | test_secondary_stream_display | test_secondary_stream_display_v2 | ⬜ |
| TCS-P14 | Parent/guardian details auto-filled on page 1 | Father name, mother name, guardian name, phone numbers, occupations, emails shown | test_secondary_parent_details | test_secondary_parent_details_v2 | ⬜ |
| TCS-P15 | Address and demographics auto-filled with Aadhar/APAAR boxes | Address, pincode (6 boxes), Aadhar (12 boxes), APAAR ID boxes, religion, caste, nationality shown | test_secondary_demographics | test_secondary_demographics_v2 | ⬜ |
| TCS-P16 | Physical measurements auto-filled from health records on page 1 | Height (cm), weight (kg) displayed with source label from health profiles | test_secondary_health_measurements | test_secondary_health_measurements_v2 | ⬜ |
| TCS-P17 | Attendance table renders with 12 monthly rows (April to March) | 12 rows with columns: Month, Working Days, Days Present, Attendance %, Reason for Absence | test_secondary_attendance_rows | test_secondary_attendance_rows_v2 | ⬜ |
| TCS-P18 | Student self-intro page (page 2) shows all auto-filled profile data | Gender selection, age dropdown, birthday datepicker, city, family emoji toggles, dream job, friends list, favorites dropdowns all populated | test_secondary_self_intro | test_secondary_self_intro_v2 | ⬜ |
| TCS-P19 | All 44 tabs are navigable — clicking each tab loads correct content | Tab click switches displayed content, URL hash updates, content matches tab label | test_secondary_tab_navigation | test_secondary_tab_navigation_v2 | ⬜ |
| TCS-P20 | Subject rubric pages render with ASC radio buttons (5 levels per row) for Science stream | Each rubric row displays 5 radio circles: Stream, Mountain, Sky, Peak, Summit. Only one selectable per row | test_secondary_asc_rubric_render_science | test_secondary_asc_rubric_render_science_v2 | ⬜ |
| TCS-P21 | Subject rubric pages render with ASC radio buttons for Commerce stream | Commerce subjects (Accountancy, Business Studies, Economics, Mathematics) shown instead of Science subjects | test_secondary_asc_rubric_render_commerce | test_secondary_asc_rubric_render_commerce_v2 | ⬜ |
| TCS-P22 | Subject rubric pages render with ASC radio buttons for Arts stream | Arts subjects (History, Political Science, Geography, Sociology) shown instead of Science subjects | test_secondary_asc_rubric_render_arts | test_secondary_asc_rubric_render_arts_v2 | ⬜ |
| TCS-P23 | Competency mapping codes displayed as badges on subject pages | Badge/label area shows competency codes with descriptions, aligned to PARAKH standards | test_secondary_competency_codes | test_secondary_competency_codes_v2 | ⬜ |
| TCS-P24 | LMS exam scores auto-filled in read-only grey boxes | Exam scores, quiz results, homework grades appear in designated grey-background sections, non-editable | test_secondary_lms_data_prefill | test_secondary_lms_data_prefill_v2 | ⬜ |
| TCS-P25 | Student self-assessment ratings shown in separate coloured column | Student ratings visible in blue/shaded column next to teacher column | test_secondary_self_assessment_view | test_secondary_self_assessment_view_v2 | ⬜ |
| TCS-P26 | Parent observation section displays parent text with parent name label | Parent name, submission date, observation text shown in dedicated feedback section | test_secondary_parent_observation | test_secondary_parent_observation_v2 | ⬜ |
| TCS-P27 | Peer review summary section displays average ratings and comments | Average score and summarized comments shown, no individual names visible | test_secondary_peer_review | test_secondary_peer_review_v2 | ⬜ |
| TCS-P28 | Goals & Aspirations page renders with student's wizard answers | Career goal, college plans, course interest, skill targets, short/long-term goals all auto-filled | test_secondary_goals_display | test_secondary_goals_display_v2 | ⬜ |
| TCS-P29 | NCrF Credit Summary page renders with correct credit values | Subject-wise credits, activity credits, total credits displayed correctly | test_secondary_ncrf_credits | test_secondary_ncrf_credits_v2 | ⬜ |
| TCS-P30 | Life skills assessment pages render with rubric tables | Communication, Collaboration, Problem-Solving, Self-Awareness pages with ASC rubric rows | test_secondary_life_skills | test_secondary_life_skills_v2 | ⬜ |
| TCS-P31 | Co-curricular activity pages render (sports, clubs, drama, debate) | Co-curricular sections with rubric items displayed | test_secondary_cocurricular | test_secondary_cocurricular_v2 | ⬜ |
| TCS-P32 | Values education and work experience pages render | Values education (honesty, respect, civic sense) and vocational sections displayed | test_secondary_values_vocational | test_secondary_values_vocational_v2 | ⬜ |
| TCS-P33 | Physical education & health pages render | Fitness tests, yoga, sports skills sections displayed | test_secondary_pe_pages | test_secondary_pe_pages_v2 | ⬜ |
| TCS-P34 | Page loads for grade 11 student — correct template resolves | Secondary template (template_id 55+) loaded, 44 pages displayed | test_secondary_grade11_load | test_secondary_grade11_load_v2 | ⬜ |
| TCS-P35 | Page loads for grade 12 Science student — only Science subjects shown | No Commerce/Arts subject tabs visible; Physics, Chemistry, Biology, Mathematics tabs present | test_secondary_science_stream | test_secondary_science_stream_v2 | ⬜ |
| TCS-P36 | Page loads for grade 12 Commerce student — only Commerce subjects shown | No Science tabs visible; Accountancy, Business Studies, Economics tabs present | test_secondary_commerce_stream | test_secondary_commerce_stream_v2 | ⬜ |
| TCS-P37 | Drag-and-drop handles visible on each section header | ⠿ (grip) icon present on each section, draggable with cursor change on hover | test_secondary_drag_handle | test_secondary_drag_handle_v2 | ⬜ |
| TCS-P38 | Editable field labels — double-click triggers rename mode | Double-click on label text converts to editable input field with Save/Cancel buttons | test_secondary_editable_label | test_secondary_editable_label_v2 | ⬜ |
| TCS-P39 | PDF preview button visible and triggers download | "Preview PDF" button at bottom, clicking initiates PDF download with correct filename format | test_secondary_pdf_preview | test_secondary_pdf_preview_v2 | ⬜ |
| TCS-P40 | Teacher can add comments and endorse goals on Goals page | Teacher comment text boxes editable; Endorse button click shows endorsement with teacher name and date | test_secondary_goals_endorsement | test_secondary_goals_endorsement_v2 | ⬜ |
| TCS-P41 | Teacher comment on goals persists after save and reload | Comment text saved in DB, displayed on page reload with teacher name and timestamp | test_secondary_goals_comment_persist | test_secondary_goals_comment_persist_v2 | ⬜ |
| TCS-P42 | First tab active and content visible by default on page load | Page 1 content (School & Student Information) visible, first tab highlighted | test_secondary_first_tab_active | test_secondary_first_tab_active_v2 | ⬜ |
| TCS-P43 | Student photo area with upload button visible | Photo placeholder with "Upload" button, accepts image file | test_secondary_student_photo | test_secondary_student_photo_v2 | ⬜ |
| TCS-P44 | Birth certificate number and APAAR ID shown on page 1 | Birth certificate number text field and APAAR ID digit boxes visible | test_secondary_ids_display | test_secondary_ids_display_v2 | ⬜ |

### 5.2 Positive Test Cases — Card Save

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TCS-P50 | Save ASC rubric radio selection — valid level per rubric row | Selected level (Stream/Mountain/Sky/Peak/Summit) stored in hpc_report_table.selected_level | test_secondary_save_rubric_radio | test_secondary_save_rubric_radio_v2 | ⬜ |
| TCS-P51 | Save text comment in rubric remark field | Text stored in hpc_report_items.remark column | test_secondary_save_text_comment | test_secondary_save_text_comment_v2 | ⬜ |
| TCS-P52 | Save numeric score value for numeric rubric item | Decimal/integer stored in hpc_report_items.in_numeric_value | test_secondary_save_numeric | test_secondary_save_numeric_v2 | ⬜ |
| TCS-P53 | Save boolean toggle (Yes/No) for boolean rubric item | Value 0 or 1 stored in hpc_report_items.in_boolean_value | test_secondary_save_boolean | test_secondary_save_boolean_v2 | ⬜ |
| TCS-P54 | Save dropdown selection for dropdown rubric item | Selected option value stored in hpc_report_items.in_selected_value | test_secondary_save_dropdown | test_secondary_save_dropdown_v2 | ⬜ |
| TCS-P55 | Save checkbox multi-select values for checkbox rubric item | Array of selected values stored as JSON in hpc_report_items.in_json_value | test_secondary_save_checkbox | test_secondary_save_checkbox_v2 | ⬜ |
| TCS-P56 | Save image upload — valid image for image rubric item | Image saved to storage, path stored in hpc_report_items.in_image_path | test_secondary_save_image | test_secondary_save_image_v2 | ⬜ |
| TCS-P57 | Save file upload — valid document for file rubric item | File saved to storage, path stored in hpc_report_items.in_filepath | test_secondary_save_file | test_secondary_save_file_v2 | ⬜ |
| TCS-P58 | Save attendance data — valid working/present days for all 12 months | Attendance rows saved, percentage auto-calculated, stored in report | test_secondary_save_attendance | test_secondary_save_attendance_v2 | ⬜ |
| TCS-P59 | Save ALL 44 pages at once — all rubric items, comments, attendance | Single save request persists data across all pages, success message "Saved successfully" displayed | test_secondary_save_all_pages | test_secondary_save_all_pages_v2 | ⬜ |
| TCS-P60 | Re-open card after save — previously saved data persists | On re-loading hpc/hpc-form/{id}, all rubric selections, comments, scores visible | test_secondary_reopen_data | test_secondary_reopen_data_v2 | ⬜ |
| TCS-P61 | First save creates new hpc_reports record with status='Draft' | New row inserted in hpc_reports with correct academic_session_id, term_id, student_id, status='Draft' | test_secondary_first_save_creates | test_secondary_first_save_creates_v2 | ⬜ |
| TCS-P62 | Subsequent saves update existing hpc_reports record — no duplicate | hpc_reports row updated (updated_at changes), no duplicate row created | test_secondary_subsequent_save | test_secondary_subsequent_save_v2 | ⬜ |
| TCS-P63 | report_date defaults to today when not provided in save payload | report_date column equals today's date (Y-m-d) | test_secondary_report_date_default | test_secondary_report_date_default_v2 | ⬜ |
| TCS-P64 | prepared_by set to current authenticated user ID | prepared_by column equals auth()->id() | test_secondary_prepared_by | test_secondary_prepared_by_v2 | ⬜ |
| TCS-P65 | Attendance % auto-calculated: 25 present / 30 working = 83.3% | Correct percentage stored and displayed: (25/30)*100 = 83.3 | test_secondary_attendance_percent | test_secondary_attendance_percent_v2 | ⬜ |
| TCS-P66 | NCrF Credits properly stored and displayed after save | Credit values persist after save; totals calculated correctly | test_secondary_ncrf_save_persist | test_secondary_ncrf_save_persist_v2 | ⬜ |
| TCS-P67 | Goals & Aspirations teacher comments saved correctly | Teacher comment text saved, endorsement flag and timestamp stored | test_secondary_goals_save | test_secondary_goals_save_v2 | ⬜ |
| TCS-P68 | Student self-assessment fields are read-only on teacher card view | Student columns have `disabled`/`readonly` HTML attribute, form submission ignores changes | test_secondary_self_readonly | test_secondary_self_readonly_v2 | ⬜ |
| TCS-P69 | Parent feedback section is read-only on teacher card | Parent text fields have `readonly` attribute, cannot be modified | test_secondary_parent_readonly | test_secondary_parent_readonly_v2 | ⬜ |
| TCS-P70 | Peer review section is read-only | Peer average score fields not editable | test_secondary_peer_readonly | test_secondary_peer_readonly_v2 | ⬜ |
| TCS-P71 | Save with empty rubric rows — NULL values stored | Unselected rubric items stored as NULL in DB | test_secondary_empty_rubric_save | test_secondary_empty_rubric_save_v2 | ⬜ |
| TCS-P72 | Transaction commit on successful save — all data persisted atomically | After commit, all hpc_report_items for this save are present in DB | test_secondary_transaction_commit | test_secondary_transaction_commit_v2 | ⬜ |
| TCS-P73 | Transaction rollback on exception — no partial data | When save throws exception, no records partially persisted, DB state unchanged | test_secondary_transaction_rollback | test_secondary_transaction_rollback_v2 | ⬜ |

### 5.3 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TCS-N80 | Load page with invalid student_id that does not exist in DB | 404 Not Found or redirect to student list with error flash message | test_secondary_invalid_student | test_secondary_invalid_student_v2 | ⬜ |
| TCS-N81 | Load page with student_id of soft-deleted student | 404 or error: student record not found | test_secondary_deleted_student | test_secondary_deleted_student_v2 | ⬜ |
| TCS-N82 | Template soft-deleted before teacher opens card | Error message: template configuration missing, fallback to default or redirect | test_secondary_deleted_template | test_secondary_deleted_template_v2 | ⬜ |
| TCS-N83 | Save with missing required field `template_id` | Validation error, HTTP 422 or redirect back with errors | test_secondary_missing_template_id | test_secondary_missing_template_id_v2 | ⬜ |
| TCS-N84 | Save with missing required field `student_id` | Validation error, save rejected | test_secondary_missing_student_id | test_secondary_missing_student_id_v2 | ⬜ |
| TCS-N85 | Save with missing required field `academic_session_id` | Validation error, save rejected | test_secondary_missing_session_id | test_secondary_missing_session_id_v2 | ⬜ |
| TCS-N86 | Save with missing required field `term_id` | Validation error, save rejected | test_secondary_missing_term_id | test_secondary_missing_term_id_v2 | ⬜ |
| TCS-N87 | Save with missing required field `class_id` | Validation error, save rejected | test_secondary_missing_class_id | test_secondary_missing_class_id_v2 | ⬜ |
| TCS-N88 | Save with missing required field `section_id` | Validation error, save rejected | test_secondary_missing_section_id | test_secondary_missing_section_id_v2 | ⬜ |
| TCS-N89 | Rubric `in_numeric_value` receives non-numeric string (e.g. "abc") | Validation error, field rejected | test_secondary_numeric_type_mismatch | test_secondary_numeric_type_mismatch_v2 | ⬜ |
| TCS-N90 | Rubric `in_boolean_value` receives non-boolean value (e.g. "yes") | Validation error, field rejected | test_secondary_boolean_type_mismatch | test_secondary_boolean_type_mismatch_v2 | ⬜ |
| TCS-N91 | Rubric `in_selected_value` receives value not in allowed options list | Validation error, field rejected | test_secondary_select_invalid_option | test_secondary_select_invalid_option_v2 | ⬜ |
| TCS-N92 | Concurrent save requests from 2 teacher sessions for same student | Second save overwrites or merges based on last-write-wins; no DB constraint violation | test_secondary_concurrent_save | test_secondary_concurrent_save_v2 | ⬜ |
| TCS-N93 | User without `tenant.hpc.view` permission tries to load form | 403 Forbidden (AuthorizationException) | test_secondary_permission_denied_view | test_secondary_permission_denied_view_v2 | ⬜ |
| TCS-N94 | User without `tenant.hpc.create` tries first-time save (new report) | 403 Forbidden | test_secondary_permission_denied_create | test_secondary_permission_denied_create_v2 | ⬜ |
| TCS-N95 | User without `tenant.hpc.update` tries subsequent save (update report) | 403 Forbidden | test_secondary_permission_denied_update | test_secondary_permission_denied_update_v2 | ⬜ |
| TCS-N96 | Guest (unauthenticated) user accesses hpc/hpc-form/{id} | Redirected to /login | test_secondary_guest_access | test_secondary_guest_access_v2 | ⬜ |
| TCS-N97 | Save attempt for duplicate (academic_session_id, term_id, student_id) combo | Existing record updated, no duplicate created, no constraint violation error | test_secondary_duplicate_term_student | test_secondary_duplicate_term_student_v2 | ⬜ |
| TCS-N98 | LMS module absent — graceful fallback with no error thrown | LMS sections show "LMS data not available" message, rest of page renders normally | test_secondary_lms_fallback | test_secondary_lms_fallback_v2 | ⬜ |
| TCS-N99 | Attendance calculation with 0 working days entered | Division by zero prevented — shows 0% or "N/A", no PHP error or exception | test_secondary_attendance_zero_working | test_secondary_attendance_zero_working_v2 | ⬜ |
| TCS-N100 | Present days (30) exceeds working days (25) for a month | Validation error: present_days must be ≤ working_days | test_secondary_attendance_exceed | test_secondary_attendance_exceed_v2 | ⬜ |
| TCS-N101 | Student in grade 9 (Middle band) — wrong grade for Secondary template | Template mismatch: wrong template loaded or redirect with error message | test_secondary_wrong_grade_student | test_secondary_wrong_grade_student_v2 | ⬜ |
| TCS-N102 | Save with `in_json_value` containing invalid JSON string | Validation error, JSON parse failure | test_secondary_invalid_json | test_secondary_invalid_json_v2 | ⬜ |
| TCS-N103 | Image upload exceeding 2MB size limit | Validation error: file too large | test_secondary_image_size_exceed | test_secondary_image_size_exceed_v2 | ⬜ |
| TCS-N104 | File upload with disallowed MIME type (e.g. .exe) | Validation error: invalid file type | test_secondary_file_type_invalid | test_secondary_file_type_invalid_v2 | ⬜ |
| TCS-N105 | Module disabled (HPC module deactivated) — access any HPC route | 404 Not Found via module:HPC middleware | test_secondary_module_disabled_route | test_secondary_module_disabled_route_v2 | ⬜ |
| TCS-N106 | Teacher tries to access student from another class they don't teach | 403 or redirected, access denied | test_secondary_cross_class_access | test_secondary_cross_class_access_v2 | ⬜ |
| TCS-N107 | Science student loads Commerce-specific pages — not visible | 404 or redirect; Science student cannot see Commerce subject pages | test_secondary_stream_mismatch | test_secondary_stream_mismatch_v2 | ⬜ |
| TCS-N108 | Save with missing Goals & Aspirations data | No error — Goals pages simply show empty-state message | test_secondary_goals_missing_data | test_secondary_goals_missing_data_v2 | ⬜ |

### 5.4 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TCS-D120 | A | Template selection by grade band — grade 11 student gets Secondary template | Template resolved as Secondary template (template_id 55+, code 'HPC-SEC') | test_secondary_template_selection | test_secondary_template_selection_v2 | ⬜ |
| TCS-D121 | B | formStore wraps all DB operations in DB::beginTransaction/commit/rollback | Transaction block present in controller method, commit on success, rollback on exception | test_secondary_transaction_wrapper | test_secondary_transaction_wrapper_v2 | ⬜ |
| TCS-D122 | C | HpcReport unique constraint on (academic_session_id, term_id, student_id) | Attempt to manually insert duplicate throws Integrity constraint violation (23000) | test_secondary_unique_constraint | test_secondary_unique_constraint_v2 | ⬜ |
| TCS-D123 | D | hpc_report_items FK ON DELETE CASCADE — deleting report removes items | After hpc_reports row hard-deleted, associated hpc_report_items removed | test_secondary_report_items_cascade | test_secondary_report_items_cascade_v2 | ⬜ |
| TCS-D124 | E | SoftDeletes on HpcReport model — delete() sets deleted_at | Calling delete() sets deleted_at timestamp, record excluded from default queries | test_secondary_softdelete | test_secondary_softdelete_v2 | ⬜ |
| TCS-D125 | E | HpcReport restore() recovers soft-deleted record | After restore(), deleted_at becomes NULL, record visible in default queries | test_secondary_softdelete_restore | test_secondary_softdelete_restore_v2 | ⬜ |
| TCS-D126 | E | Soft-deleting report does NOT cascade soft-delete to hpc_report_items | Items remain with report_id intact, deleted_at on report only | test_secondary_softdelete_items | test_secondary_softdelete_items_v2 | ⬜ |
| TCS-D127 | F | `$getStudentValue()` 4-level closure: student→session→school→default | Value resolved checking each level in order, returns first non-null match | test_secondary_get_student_value | test_secondary_get_student_value_v2 | ⬜ |
| TCS-D128 | G | Role-based field filtering: teacher/student/parent fields correctly gated | Teacher rubric fields editable, student columns disabled, parent columns readonly | test_secondary_role_field_filtering | test_secondary_role_field_filtering_v2 | ⬜ |
| TCS-D129 | H | Attendance percentage re-computed on form load and after save | Value updates after save with new working/present day numbers | test_secondary_attendance_compute_timing | test_secondary_attendance_compute_timing_v2 | ⬜ |
| TCS-D130 | I | hpc_report_table grid storage: ASC level per rubric_item_id | Grid stores selected_level for each rubric_item_id with correct report_id | test_secondary_report_table_storage | test_secondary_report_table_storage_v2 | ⬜ |
| TCS-D131 | J | ASC rubric radio single-select per row | Only one radio selected per row. Selecting Sky deselects Stream/Mountain/Peak if previously selected | test_secondary_rubric_single_select | test_secondary_rubric_single_select_v2 | ⬜ |
| TCS-D132 | K | 44 template parts with display_order sequential 1-44 | Query hpc_templates_part count = 44, display_order values 1 through 44 | test_secondary_part_count_sequence | test_secondary_part_count_sequence_v2 | ⬜ |
| TCS-D133 | L | Stream-based subject filtering — correct subjects for each stream | Science student sees Physics/Chemistry/Bio/Math; Commerce sees Accts/BST/Eco; Arts sees History/PoliSci/Geo/Socio | test_secondary_stream_filtering | test_secondary_stream_filtering_v2 | ⬜ |
| TCS-D134 | M | PDF generation uses Secondary layout for template_id 55+ | PDF file rendered with Secondary-specific layout (includes NCrF, Goals pages) | test_secondary_pdf_layout_type | test_secondary_pdf_layout_type_v2 | ⬜ |
| TCS-D135 | N | Image upload stored in correct tenant-specific directory path | File path starts with `storage/tenant_{id}/hpc/{report_id}/` | test_secondary_image_storage_path | test_secondary_image_storage_path_v2 | ⬜ |
| TCS-D136 | O | NCrF Credit auto-calculation accuracy | Credit totals match sum of individual subject and activity credits | test_secondary_ncrf_calculation | test_secondary_ncrf_calculation_v2 | ⬜ |
| TCS-D137 | P | Goals & Aspirations data flow: Student Portal → Teacher Card | Student's wizard answers appear on teacher's card after submission | test_secondary_goals_data_flow | test_secondary_goals_data_flow_v2 | ⬜ |
| TCS-D138 | Q | Summit level (5th ASC level) selectable and stores correctly | Summit radio clickable; stored in hpc_report_table as 'Summit' | test_secondary_summit_level | test_secondary_summit_level_v2 | ⬜ |
| TCS-D139 | R | Save button disabled during AJAX request — prevents double-submit | Button disabled on click, re-enabled after success or error response | test_secondary_save_button_disable | test_secondary_save_button_disable_v2 | ⬜ |
| TCS-D140 | S | Drag reordering persists section display_order in DB via AJAX | After drop, AJAX call updates section ordinal, on reload sections appear in new order | test_secondary_drag_persist | test_secondary_drag_persist_v2 | ⬜ |
| TCS-D141 | T | Editable label persists after rename, save, and reload | Custom label text saved in DB, displayed on page reload | test_secondary_label_persist | test_secondary_label_persist_v2 | ⬜ |
| TCS-D142 | U | Multi-contributor columns correctly labelled | Column headers differentiate Teacher / Student / Parent / Peer data sources | test_secondary_contributor_labels | test_secondary_contributor_labels_v2 | ⬜ |
| TCS-D143 | V | Missing student self-assessment shows "Not yet submitted" | Empty-state message with muted styling, no error | test_secondary_self_missing_state | test_secondary_self_missing_state_v2 | ⬜ |
| TCS-D144 | W | Missing parent observation shows "No observation submitted" | Empty-state message in parent feedback section | test_secondary_parent_missing_state | test_secondary_parent_missing_state_v2 | ⬜ |
| TCS-D145 | X | Missing peer reviews shows "Peer reviews pending" | Empty-state with counter "0 submissions received" | test_secondary_peer_missing_state | test_secondary_peer_missing_state_v2 | ⬜ |
| TCS-D146 | Y | `out_*` value computed from `in_*` value on read via model accessor | Accessor transforms in_selected_value to out_selected_value (value→label mapping) | test_secondary_out_value_computed | test_secondary_out_value_computed_v2 | ⬜ |
| TCS-D147 | Z | `assessed_at` auto-set to current timestamp on item save | hpc_report_items.assessed_at = NOW() after save | test_secondary_assessed_at_timestamp | test_secondary_assessed_at_timestamp_v2 | ⬜ |
| TCS-D148 | AA | Remarks field stores free-text teacher comment per rubric item | Text saved in hpc_report_items.remark, displayed on reload | test_secondary_remark_storage | test_secondary_remark_storage_v2 | ⬜ |
| TCS-D149 | AB | Grid radio selection stored in hpc_report_table.selected_level | Value "Sky", "Peak", or "Summit" stored as VARCHAR in selected_level column | test_secondary_grid_selected_level | test_secondary_grid_selected_level_v2 | ⬜ |
| TCS-D150 | AC | Three-column layout on assessment pages | CSS grid or flexbox creates 3 columns, fields distribute left to right | test_secondary_three_column_layout | test_secondary_three_column_layout_v2 | ⬜ |

### 5.5 Code Review Test Cases

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

#### TCS-P10: Page loads with 44 tabs for valid Secondary-grade student

**Pre-conditions:**
- Authenticated as teacher with `tenant.hpc.view` permission
- Student record exists in grade 12 (Science stream) with academic session, class, section
- Secondary template configured with 44 parts

**Steps:**
1. Navigate to `GET /hpc/hpc-form/{student_id}` where student_id is a valid grade 12 Science student
2. Wait for DOM ready — wait for `.hpc-form-container` element to be visible
3. Count tab elements: `document.querySelectorAll('.nav-tabs .tab-item').length`
4. Assert tab count equals 44
5. Verify first tab has class `active` and label equals "School & Student Information"
6. Verify page title `<h1>` or equivalent renders correct student name
7. Check browser console for 0 JavaScript errors
8. Check network request completes with HTTP 200 status

**Expected:** 44 tabs render, first tab active, zero JS errors, page title correct, HTTP 200.

**V1 Test:** `test_secondary_page_loads`
**V2 Test:** `test_secondary_page_loads_v2`

---

#### TCS-P19: All 44 tabs navigable — each tab loads correct content

**Pre-conditions:**
- Card loaded for Secondary student
- 44 tabs rendered in tab bar

**Steps:**
1. Verify first tab ("School & Student Information") is active
2. Click tab 2 ("Student Profile & Me") — assert content area updates, tab 2 becomes active
3. Click tab 3 (first stream subject page) — assert content updates
4. Click tab 10 (random middle tab) — assert correct content area
5. Click tab 44 (Principal's Review) — assert last page content loaded
6. Click tab 1 again — assert back to first page
7. For each tab click, verify URL hash updates (e.g. #tab-3)
8. Verify no 404 or JS errors on any tab switch

**Expected:** All 44 tabs navigable, content updates on click, no errors.

**V1 Test:** `test_secondary_tab_navigation`
**V2 Test:** `test_secondary_tab_navigation_v2`

---

#### TCS-P35: Science stream — only Science subjects shown

**Pre-conditions:**
- Student record with stream = Science (grade 12)
- Secondary template configured with stream-specific rubrics

**Steps:**
1. Navigate to card for Science student
2. Verify tab list includes Physics, Chemistry, Biology/BIotech, Mathematics subject tabs
3. Verify Accountancy, Business Studies, Economics, History tabs are NOT present
4. Click Physics tab — assert rubric items for Physics displayed
5. Click Chemistry tab — assert rubric items for Chemistry displayed

**Expected:** Only Science stream subjects rendered; Commerce/Arts subjects hidden.

**V1 Test:** `test_secondary_science_stream`
**V2 Test:** `test_secondary_science_stream_v2`

---

#### TCS-P50: Save ASC rubric radio selection

**Pre-conditions:**
- Card loaded for Secondary student
- Subject page with ASC rubric visible (5 levels)

**Steps:**
1. On subject page (e.g. Physics), select "Sky" for rubric row 1
2. Select "Summit" for rubric row 2
3. Select "Peak" for rubric row 3
4. Leave rubric row 4 unselected
5. Click Save button at bottom
6. Wait for success flash message "Saved successfully"
7. Reload the page
8. Navigate to same subject page — verify row 1 = Sky, row 2 = Summit, row 3 = Peak, row 4 = null
9. Check DB: hpc_report_table has rows with correct report_id, rubric_item_id, selected_level

**Expected:** Rubric selections persist after save and reload.

**V1 Test:** `test_secondary_save_rubric_radio`
**V2 Test:** `test_secondary_save_rubric_radio_v2`

---

#### TCS-N80: Load page with invalid non-existent student_id

**Pre-conditions:**
- Authenticated as teacher with HPC view permission

**Steps:**
1. Navigate to `GET /hpc/hpc-form/999999` (non-existent student ID)
2. Observe HTTP response status code
3. If redirect, follow redirect and check flash message
4. Assert no card data is loaded

**Expected:** 404 Not Found page or redirect to student list with error "Student not found."

**V1 Test:** `test_secondary_invalid_student`
**V2 Test:** `test_secondary_invalid_student_v2`

---

#### TCS-N93: User without tenant.hpc.view permission

**Pre-conditions:**
- Authenticated as user without `tenant.hpc.view`
- Valid student ID in grade 12

**Steps:**
1. Navigate to `GET /hpc/hpc-form/{valid_student_id}`
2. Observe HTTP response

**Expected:** 403 Forbidden — AuthorizationException thrown by Gate::authorize().

**V1 Test:** `test_secondary_permission_denied_view`
**V2 Test:** `test_secondary_permission_denied_view_v2`

---

#### TCS-D124: SoftDeletes on HpcReport

**Pre-conditions:**
- Existing HpcReport record for Secondary student with associated hpc_report_items

**Steps:**
1. Load HpcReport model from DB — assert deleted_at IS NULL
2. Call `$report->delete()`
3. Query without withTrashed() — assert report NOT returned
4. Query with withTrashed() — assert report returned, deleted_at NOT NULL
5. Assert hpc_report_items still exist (items NOT cascade on soft-delete)
6. Call `$report->restore()` — assert deleted_at becomes NULL
7. Query default — assert report returned again

**Expected:** Soft-delete sets deleted_at, hides from default queries, preserves items, restorable.

**V1 Test:** `test_secondary_softdelete`
**V2 Test:** `test_secondary_softdelete_v2`

---

#### TCS-D136: NCrF Credit auto-calculation accuracy

**Pre-conditions:**
- NCrF credit values configured for subjects and activities per framework
- Student with assigned subjects

**Steps:**
1. Load NCrF Credit Summary page for student
2. Verify Physics credit = 5 (theory) + 2 (practical) = 7 total
3. Verify Chemistry credit = 5 (theory) + 2 (practical) = 7 total
4. Verify Mathematics credit = 5
5. Verify English credit = 4
6. Verify Physical Education credit = 2
7. Verify total = sum of all subject + activity credits
8. Save the card, reload, verify totals unchanged

**Expected:** NCrF credits correctly calculated and displayed; persist after save.

**V1 Test:** `test_secondary_ncrf_calculation`
**V2 Test:** `test_secondary_ncrf_calculation_v2`

---

## Test Method Index

### File: `lms_HPC_Secondary_TestCas.php` (TBD methods)

| # | Method | TC Map | Category | Band |
|---|--------|--------|----------|------|
| 1 | test_secondary_page_loads | TCS-P10 | UI | 10-19 |
| 2 | test_secondary_school_info | TCS-P11 | UI | 10-19 |
| 3 | test_secondary_student_details | TCS-P12 | UI | 10-19 |
| 4 | test_secondary_stream_display | TCS-P13 | UI | 10-19 |
| 5 | test_secondary_parent_details | TCS-P14 | UI | 10-19 |
| 6 | test_secondary_demographics | TCS-P15 | UI | 10-19 |
| 7 | test_secondary_health_measurements | TCS-P16 | UI | 10-19 |
| 8 | test_secondary_attendance_rows | TCS-P17 | UI | 10-19 |
| 9 | test_secondary_self_intro | TCS-P18 | UI | 10-19 |
| 10 | test_secondary_tab_navigation | TCS-P19 | Nav | 10-19 |
| 11 | test_secondary_asc_rubric_render_science | TCS-P20 | UI | 20-29 |
| 12 | test_secondary_asc_rubric_render_commerce | TCS-P21 | UI | 20-29 |
| 13 | test_secondary_asc_rubric_render_arts | TCS-P22 | UI | 20-29 |
| 14 | test_secondary_competency_codes | TCS-P23 | UI | 20-29 |
| 15 | test_secondary_lms_data_prefill | TCS-P24 | Biz | 20-29 |
| 16 | test_secondary_self_assessment_view | TCS-P25 | UI | 20-29 |
| 17 | test_secondary_parent_observation | TCS-P26 | UI | 20-29 |
| 18 | test_secondary_peer_review | TCS-P27 | UI | 20-29 |
| 19 | test_secondary_goals_display | TCS-P28 | UI | 20-29 |
| 20 | test_secondary_ncrf_credits | TCS-P29 | Biz | 20-29 |
| 21 | test_secondary_life_skills | TCS-P30 | UI | 30-39 |
| 22 | test_secondary_cocurricular | TCS-P31 | UI | 30-39 |
| 23 | test_secondary_values_vocational | TCS-P32 | UI | 30-39 |
| 24 | test_secondary_pe_pages | TCS-P33 | UI | 30-39 |
| 25 | test_secondary_grade11_load | TCS-P34 | Biz | 30-39 |
| 26 | test_secondary_science_stream | TCS-P35 | Biz | 30-39 |
| 27 | test_secondary_commerce_stream | TCS-P36 | Biz | 30-39 |
| 28 | test_secondary_drag_handle | TCS-P37 | UI | 30-39 |
| 29 | test_secondary_editable_label | TCS-P38 | UI | 30-39 |
| 30 | test_secondary_pdf_preview | TCS-P39 | Biz | 30-39 |
| 31 | test_secondary_goals_endorsement | TCS-P40 | Biz | 40-49 |
| 32 | test_secondary_goals_comment_persist | TCS-P41 | Biz | 40-49 |
| 33 | test_secondary_first_tab_active | TCS-P42 | UI | 40-49 |
| 34 | test_secondary_student_photo | TCS-P43 | UI | 40-49 |
| 35 | test_secondary_ids_display | TCS-P44 | UI | 40-49 |
| 36 | test_secondary_save_rubric_radio | TCS-P50 | Biz | 50-59 |
| 37 | test_secondary_save_text_comment | TCS-P51 | Biz | 50-59 |
| 38 | test_secondary_save_numeric | TCS-P52 | Biz | 50-59 |
| 39 | test_secondary_save_boolean | TCS-P53 | Biz | 50-59 |
| 40 | test_secondary_save_dropdown | TCS-P54 | Biz | 50-59 |
| 41 | test_secondary_save_checkbox | TCS-P55 | Biz | 50-59 |
| 42 | test_secondary_save_image | TCS-P56 | Biz | 50-59 |
| 43 | test_secondary_save_file | TCS-P57 | Biz | 50-59 |
| 44 | test_secondary_save_attendance | TCS-P58 | Biz | 50-59 |
| 45 | test_secondary_save_all_pages | TCS-P59 | Biz | 50-59 |
| 46 | test_secondary_reopen_data | TCS-P60 | Biz | 60-69 |
| 47 | test_secondary_first_save_creates | TCS-P61 | Biz | 60-69 |
| 48 | test_secondary_subsequent_save | TCS-P62 | Biz | 60-69 |
| 49 | test_secondary_report_date_default | TCS-P63 | Biz | 60-69 |
| 50 | test_secondary_prepared_by | TCS-P64 | Biz | 60-69 |
| 51 | test_secondary_attendance_percent | TCS-P65 | Biz | 60-69 |
| 52 | test_secondary_ncrf_save_persist | TCS-P66 | Biz | 60-69 |
| 53 | test_secondary_goals_save | TCS-P67 | Biz | 60-69 |
| 54 | test_secondary_self_readonly | TCS-P68 | Val | 60-69 |
| 55 | test_secondary_parent_readonly | TCS-P69 | Val | 60-69 |
| 56 | test_secondary_peer_readonly | TCS-P70 | Val | 60-69 |
| 57 | test_secondary_empty_rubric_save | TCS-P71 | Biz | 70-79 |
| 58 | test_secondary_transaction_commit | TCS-P72 | Biz | 70-79 |
| 59 | test_secondary_transaction_rollback | TCS-P73 | Biz | 70-79 |
| 60 | test_secondary_invalid_student | TCS-N80 | Edge | 80-89 |
| 61 | test_secondary_deleted_student | TCS-N81 | Edge | 80-89 |
| 62 | test_secondary_deleted_template | TCS-N82 | Edge | 80-89 |
| 63 | test_secondary_missing_template_id | TCS-N83 | Val | 80-89 |
| 64 | test_secondary_missing_student_id | TCS-N84 | Val | 80-89 |
| 65 | test_secondary_missing_session_id | TCS-N85 | Val | 80-89 |
| 66 | test_secondary_missing_term_id | TCS-N86 | Val | 80-89 |
| 67 | test_secondary_missing_class_id | TCS-N87 | Val | 80-89 |
| 68 | test_secondary_missing_section_id | TCS-N88 | Val | 80-89 |
| 69 | test_secondary_numeric_type_mismatch | TCS-N89 | Val | 80-89 |
| 70 | test_secondary_boolean_type_mismatch | TCS-N90 | Val | 80-89 |
| 71 | test_secondary_select_invalid_option | TCS-N91 | Val | 80-89 |
| 72 | test_secondary_concurrent_save | TCS-N92 | Concur | 90-99 |
| 73 | test_secondary_permission_denied_view | TCS-N93 | Auth | 90-99 |
| 74 | test_secondary_permission_denied_create | TCS-N94 | Auth | 90-99 |
| 75 | test_secondary_permission_denied_update | TCS-N95 | Auth | 90-99 |
| 76 | test_secondary_guest_access | TCS-N96 | Auth | 90-99 |
| 77 | test_secondary_duplicate_term_student | TCS-N97 | Biz | 90-99 |
| 78 | test_secondary_lms_fallback | TCS-N98 | Biz | 90-99 |
| 79 | test_secondary_attendance_zero_working | TCS-N99 | Edge | 90-99 |
| 80 | test_secondary_attendance_exceed | TCS-N100 | Val | 100-109 |
| 81 | test_secondary_wrong_grade_student | TCS-N101 | Edge | 100-109 |
| 82 | test_secondary_invalid_json | TCS-N102 | Val | 100-109 |
| 83 | test_secondary_image_size_exceed | TCS-N103 | Val | 100-109 |
| 84 | test_secondary_file_type_invalid | TCS-N104 | Val | 100-109 |
| 85 | test_secondary_module_disabled_route | TCS-N105 | Auth | 100-109 |
| 86 | test_secondary_cross_class_access | TCS-N106 | Auth | 100-109 |
| 87 | test_secondary_stream_mismatch | TCS-N107 | Edge | 100-109 |
| 88 | test_secondary_goals_missing_data | TCS-N108 | Edge | 100-109 |
| 89 | test_secondary_template_selection | TCS-D120 | Arch | 120-129 |
| 90 | test_secondary_transaction_wrapper | TCS-D121 | Arch | 120-129 |
| 91 | test_secondary_unique_constraint | TCS-D122 | DB | 120-129 |
| 92 | test_secondary_report_items_cascade | TCS-D123 | DB | 120-129 |
| 93 | test_secondary_softdelete | TCS-D124 | DB | 120-129 |
| 94 | test_secondary_softdelete_restore | TCS-D125 | DB | 120-129 |
| 95 | test_secondary_softdelete_items | TCS-D126 | DB | 120-129 |
| 96 | test_secondary_get_student_value | TCS-D127 | Arch | 120-129 |
| 97 | test_secondary_role_field_filtering | TCS-D128 | Arch | 130-139 |
| 98 | test_secondary_attendance_compute_timing | TCS-D129 | Biz | 130-139 |
| 99 | test_secondary_report_table_storage | TCS-D130 | DB | 130-139 |
| 100 | test_secondary_rubric_single_select | TCS-D131 | UI | 130-139 |
| 101 | test_secondary_part_count_sequence | TCS-D132 | Arch | 130-139 |
| 102 | test_secondary_stream_filtering | TCS-D133 | Biz | 130-139 |
| 103 | test_secondary_pdf_layout_type | TCS-D134 | Arch | 130-139 |
| 104 | test_secondary_image_storage_path | TCS-D135 | Biz | 140-149 |
| 105 | test_secondary_ncrf_calculation | TCS-D136 | Biz | 140-149 |
| 106 | test_secondary_goals_data_flow | TCS-D137 | Biz | 140-149 |
| 107 | test_secondary_summit_level | TCS-D138 | UI | 140-149 |
| 108 | test_secondary_save_button_disable | TCS-D139 | UI | 140-149 |
| 109 | test_secondary_drag_persist | TCS-D140 | Biz | 140-149 |
| 110 | test_secondary_label_persist | TCS-D141 | Biz | 140-149 |
| 111 | test_secondary_contributor_labels | TCS-D142 | UI | 150-159 |
| 112 | test_secondary_self_missing_state | TCS-D143 | UI | 150-159 |
| 113 | test_secondary_parent_missing_state | TCS-D144 | UI | 150-159 |
| 114 | test_secondary_peer_missing_state | TCS-D145 | UI | 150-159 |
| 115 | test_secondary_out_value_computed | TCS-D146 | Biz | 150-159 |
| 116 | test_secondary_assessed_at_timestamp | TCS-D147 | Biz | 150-159 |
| 117 | test_secondary_remark_storage | TCS-D148 | Biz | 150-159 |
| 118 | test_secondary_grid_selected_level | TCS-D149 | DB | 150-159 |
| 119 | test_secondary_three_column_layout | TCS-D150 | UI | 150-159 |

**Total: 119 methods**

---

### Execution Status

| Cycle | Date | Tester | Pass | Fail | Blocked | Not Executed | Signature |
|-------|------|--------|------|------|---------|--------------|-----------|
| V1 | — | — | — | — | — | 119 | — |
| V2 | — | — | — | — | — | 119 | — |

---

*Test cases derived from HPC Teacher Card Secondary requirement document (BV4), HpcController code analysis, migration schema, and BC-DB/BC-VAL/BC-AUTH/BC-BIZ/BC-REF conditions. Covers grades 11-12 with 44-page Secondary template, stream-based subjects, NCrF credits, and Goals & Aspirations wizard.*
## 8. CODE-TRACE: Controller Method Execution Traces

### CODE-TRACE-01: `index()` � HpcController (Line 56)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcController.php:58` | `$this->authorizeHpcIndex()` � calls `Gate::authorize('tenant.hpc.viewAny')` |
| 2 | `HpcIndexDataTrait.php:28-49` | `$this->getHpcIndexData()` � loads sessions, terms, classes, sections, filtered students |
| 3 | `HpcController.php:63-64` | `SchoolClass::active()->get()`, `Section::active()->get()` � filter dropdowns |
| 4 | `HpcController.php:65` | `$this->getFilteredStudents($request)->paginate(10)` |
| 5 | `HpcController.php:67` | `return view('hpc::hpc.index', $data)` |

### CODE-TRACE-02: `hpc_form()` � HpcController (Line 301)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcController.php:303` | `Gate::authorize('tenant.hpc.view')` |
| 2 | `HpcController.php:305-310` | Validates request params |
| 3 | `HpcController.php:312-318` | Loads template with `->with('parts.sections.rubrics.items')` |
| 4 | `HpcController.php:320-330` | Groups parts by `page_no` |
| 5 | `HpcController.php:332-340` | Loads Student with relations |
| 6 | `HpcController.php:342-360` | Computes sibling data |
| 7 | `HpcController.php:362-400` | Attendance aggregation |
| 8 | `HpcController.php:412-440` | Loads saved values via `reportService->getSavedValues()` |
| 9 | `HpcController.php:442-460` | Auto-feeds LMS data via `HpcDataMappingService::mergeIntoSavedValues()` |
| 10 | `HpcController.php:462-480` | Returns `fourth_form` (Secondary, template_id=4) |

### CODE-TRACE-03: `formStore()` � HpcController (Line 670)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcController.php:672-676` | `Gate::authorize('tenant.hpc.update')` |
| 2 | `HpcController.php:678-705` | Validates request |
| 3 | `HpcController.php:707-720` | Loads template with nested relations |
| 4 | `HpcController.php:722-740` | Builds 4 mappings (fieldMapping, globalRubricMapping, tableMapping, tableCellMapping) |
| 5 | `HpcController.php:742-760` | Normalizes `_hidden`/`_empty` fields |
| 6 | `HpcController.php:762-780` | Role-based section locking |
| 7 | `HpcController.php:782-850` | Routes fields to hpc_report_items or hpc_report_table |
| 8 | `HpcController.php:852-870` | Process file uploads |
| 9 | `HpcController.php:872-880` | `$this->reportService->saveReport()` |
| 10 | `HpcController.php:882-890` | Error handling with JSON response |

### CODE-TRACE-04: Workflow Methods � HpcController (Lines 1856-1981)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `submitReport()` (1856) | `Gate::authorize('tenant.hpc.update')` ? `HpcWorkflowService::finalize()` |
| 2 | `reviewReport()` (1875) | `Gate::authorize('tenant.hpc.review')` ? `HpcWorkflowService::publish()` |
| 3 | `approveReport()` (1894) | `Gate::authorize('tenant.hpc.review')` ? `HpcWorkflowService::finalize()` |
| 4 | `sendBackReport()` (1913) | `Gate::authorize('tenant.hpc.review')` ? `HpcWorkflowService::sendBackToDraft()` |
| 5 | `publishReport()` (1932) | `Gate::authorize('tenant.hpc.publish')` ? `HpcWorkflowService::publish()` |
| 6 | `archiveReport()` (1951) | `Gate::authorize('tenant.hpc.update')` ? `HpcWorkflowService::archive()` |
| 7 | `workflowStatus()` (1970) | `Gate::authorize('tenant.hpc.view')` ? `HpcWorkflowService::getAuditInfo()` |

### CODE-TRACE-05: `index()` � StudentGoalsController (Line 41)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `StudentGoalsController.php:43` | `Gate::authorize('tenant.hpc-student.view')` |
| 2 | `StudentGoalsController.php:46-48` | Validates report ownership: `HpcReport::where('student_id', $studentId)->findOrFail($reportId)` |
| 3 | `StudentGoalsController.php:51` | Checks `template_id == 4` (Secondary only) � else redirect |
| 4 | `StudentGoalsController.php:54-56` | Determines `currentStep` from request or defaults to first incomplete step |
| 5 | `StudentGoalsController.php:59-66` | Loads template with specific `page_no` matching step config |
| 6 | `StudentGoalsController.php:69-75` | Loads saved values via `reportService->getSavedValues()` |
| 7 | `StudentGoalsController.php:78-85` | Computes step completion via `getStepCompletion()` |
| 8 | `StudentGoalsController.php:88-94` | Returns `hpc::student.goals` view |

### CODE-TRACE-06: `save()` � StudentGoalsController (Line 100)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `StudentGoalsController.php:102` | `Gate::authorize('tenant.hpc-student.submit')` |
| 2 | `StudentGoalsController.php:105` | Validates report ownership |
| 3 | `StudentGoalsController.php:108-112` | Filters payload via `HpcSectionRoleService::filterPayloadByRole()` |
| 4 | `StudentGoalsController.php:115` | `$this->reportService->upsertReportItemsForFields(...)` � saves field values |
| 5 | `StudentGoalsController.php:118-138` | Returns JSON with `next_step` |

---
