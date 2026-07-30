# lms_HPC_Foundation_TcList

## Module: HPC → Teacher Card → Foundation (BV1)

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | HPC |
| Tab Group | Teacher Card |
| Feature | Teacher Card - Foundation (BV1) |
| URL(s) | `hpc/hpc-form/{student_id}` (GET — hpc_form), `hpc/form/store` (POST — formStore) |
| Controller | `Modules\Hpc\Http\Controllers\HpcController` — `hpc_form()` (lines 15-80), `formStore()` (lines 85-220) |
| Model(s) | `Modules\Hpc\Models\HpcTemplates`, `Modules\Hpc\Models\HpcReport`, `Modules\Hpc\Models\HpcReportItem`, `Modules\Hpc\Models\HpcReportTable` |
| Validation (Create) | None — validates inline in `formStore()` controller method |
| Validation (Update) | None — validates inline in `formStore()` controller method (update-or-create pattern) |
| Permissions | `tenant.hpc.view`, `tenant.hpc.create`, `tenant.hpc.update` |
| Soft Deletes | Yes — `HpcReport` and `HpcReportItem` use `SoftDeletes` trait |
| Activity Log | None — `HpcController` does not call `activityLog()` |
| Template Scope | Foundation template (Nursery–3rd Grade, 18 pages) |
| Data Source | HPC templates master, student master, LMS integration, session/term/class/section |
| Page Config | 18-page tabbed interface with sections for student info, attendance, family, friends, favorites, goals, rubrics, images, school info, signature |

---

## 2. Pre-conditions

- Required permissions: `tenant.hpc.view`, `tenant.hpc.create`, `tenant.hpc.update`
- Required seed data: At least one Foundation template (grade range Nursery–3rd) in `hpc_templates` with 18 page definitions
- Required seed data: At least one student enrolled in Nursery–3rd grade with valid `student_id`
- Required seed data: Academic session, term, class, and section records linked to the student
- Test user must have `tenant.hpc.view` permission to view the form, `tenant.hpc.create` to save new cards, `tenant.hpc.update` to edit existing cards
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- Attendance module must have configuration for the student's class (for attendance table page)
- LMS integration optional — test both with and without LMS data availability
- For email send test: SMTP configuration must be active
- For PDF generation test: PDF library (DomPDF/TCPDF) must be configured
- For image upload test: Storage directory must be writable

---

## 3. Default Data Load

When the page loads via `HpcController@hpc_form()`, the following data is fetched:

| Data | Source | Query | Filters | Pagination |
|------|--------|-------|---------|------------|
| Template Definition | `HpcTemplates::where('grade_range', ...)` | `HpcTemplates::where('grade_min', '<=', $grade)->where('grade_max', '>=', $grade)->where('type', 'foundation')->firstOrFail()` | By student grade and type=foundation | None (single template) |
| Student Info | `Student` model via `student_id` | `Student::with(['class', 'section', 'parent'])->findOrFail($student_id)` | By student_id | None |
| Existing Report | `HpcReport::where(...)` | `HpcReport::where('student_id', $id)->where('academic_session_id', $sessionId)->where('term_id', $termId)->first()` | By student + session + term | None |
| Report Items | `HpcReportItem::where('report_id', ...)` (if report exists) | `HpcReportItem::where('report_id', $report->id)->orderBy('page_no')->orderBy('display_order')->get()` | By report_id | None |
| Report Tables | `HpcReportTable::where('report_id', ...)` (if report exists) | `HpcReportTable::where('report_id', $report->id)->get()` | By report_id | None |
| Attendance Data | Attendance module | Attendance summary query by student + term grouped by month | By student + term | None |
| LMS Data | LMS module (optional) | Lesson/topic completion data by student + subject | By student + subject | None |
| Academic Session | `AcademicSession::where('is_active', true)` | Active session for current tenant | is_active=1 | None |
| Term | `Term::where('session_id', $sessionId)->where('is_active', true)` | Active term for current session | is_active=1 | None |

---

## 4. Test Data Strategy

- Create test students with `uniqueSuffix()` appended to names to avoid collisions across test runs
- Create Foundation HPC templates for grades Nursery, LKG, UKG, 1, 2, 3 with specific `grade_min`/`grade_max` boundaries
- Each test template must have 18 page definitions covering: student info, attendance, gender emoji selection, family details, friends, favorites, goals, rubrics, image upload, pincode/UDISE, signature
- For auto-fill tests, ensure student master data (name, DOB, parent name, address, class, section) is seeded with distinct values
- For attendance tests, seed 3+ months of attendance records for the test student in the current term with varying present/absent/leave counts
- For image upload tests, prepare valid image files (jpg 100KB, png 200KB, gif 500KB) and oversized files (3MB), and invalid files (exe, zip, txt)
- For PDF generation test, ensure the PDF library (DomPDF/TCPDF) is configured with proper fonts
- For email send test, ensure mail configuration points to a test mail trap (Mailtrap or similar)
- For drag-drop tests, ensure the page has at least 4 sortable elements
- Pre-test cleanup: Delete created HpcReport records by student_id + session_id + term_id in setUp/tearDown
- Unique suffix generation: Use `Carbon::now()->format('YmdHisu')` for unique identifiers

---

## 5. Business Conditions

### 4.1 Database Schema — `hpc_reports`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-01 | id | BIGINT UNSIGNED | PK, Auto-increment |
| BC-DB-02 | academic_session_id | BIGINT UNSIGNED | NOT NULL, FK → academic_sessions.id, ON DELETE CASCADE |
| BC-DB-03 | term_id | BIGINT UNSIGNED | NOT NULL, FK → terms.id, ON DELETE CASCADE |
| BC-DB-04 | student_id | BIGINT UNSIGNED | NOT NULL, FK → students.id, ON DELETE CASCADE |
| BC-DB-05 | class_id | BIGINT UNSIGNED | NOT NULL, FK → classes.id, ON DELETE CASCADE |
| BC-DB-06 | section_id | BIGINT UNSIGNED | NOT NULL, FK → sections.id, ON DELETE CASCADE |
| BC-DB-07 | template_id | BIGINT UNSIGNED | NOT NULL, FK → hpc_templates.id, ON DELETE RESTRICT |
| BC-DB-08 | prepared_by | BIGINT UNSIGNED | NOT NULL, FK → users.id, ON DELETE CASCADE |
| BC-DB-09 | report_date | DATE | NOT NULL |
| BC-DB-10 | status | ENUM('draft','completed','archived') | NOT NULL, DEFAULT 'draft' |
| BC-DB-11 | created_at | TIMESTAMP | NULL, DEFAULT CURRENT_TIMESTAMP |
| BC-DB-12 | updated_at | TIMESTAMP | NULL, ON UPDATE CURRENT_TIMESTAMP |
| BC-DB-13 | deleted_at | TIMESTAMP | NULL — Soft delete marker |

### 4.2 Database Schema — `hpc_report_items`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-14 | id | BIGINT UNSIGNED | PK, Auto-increment |
| BC-DB-15 | report_id | BIGINT UNSIGNED | NOT NULL, FK → hpc_reports.id, ON DELETE CASCADE |
| BC-DB-16 | page_no | SMALLINT UNSIGNED | NOT NULL, min:1, max:18 |
| BC-DB-17 | section_code | VARCHAR(50) | NOT NULL |
| BC-DB-18 | field_name | VARCHAR(100) | NOT NULL |
| BC-DB-19 | field_value | TEXT | NULL |
| BC-DB-20 | field_type | ENUM('text','emoji','image','number','boolean','json') | NOT NULL, DEFAULT 'text' |
| BC-DB-21 | display_order | SMALLINT UNSIGNED | NOT NULL, DEFAULT 0 |
| BC-DB-22 | created_at | TIMESTAMP | NULL |
| BC-DB-23 | updated_at | TIMESTAMP | NULL |
| BC-DB-24 | deleted_at | TIMESTAMP | NULL — Soft delete marker |

### 4.3 Database Schema — `hpc_report_tables`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-25 | id | BIGINT UNSIGNED | PK, Auto-increment |
| BC-DB-26 | report_id | BIGINT UNSIGNED | NOT NULL, FK → hpc_reports.id, ON DELETE CASCADE |
| BC-DB-27 | page_no | SMALLINT UNSIGNED | NOT NULL |
| BC-DB-28 | table_code | VARCHAR(50) | NOT NULL |
| BC-DB-29 | row_data | JSON | NOT NULL |
| BC-DB-30 | col_count | TINYINT UNSIGNED | NOT NULL |
| BC-DB-31 | row_count | TINYINT UNSIGNED | NOT NULL |
| BC-DB-32 | created_at | TIMESTAMP | NULL |
| BC-DB-33 | updated_at | TIMESTAMP | NULL |

### 4.4 Database Schema — `hpc_templates`

| BC ID | Column | Type (DDL) | Constraints |
|-------|--------|------------|-------------|
| BC-DB-34 | id | BIGINT UNSIGNED | PK, Auto-increment |
| BC-DB-35 | name | VARCHAR(200) | NOT NULL |
| BC-DB-36 | type | ENUM('foundation','preparatory') | NOT NULL |
| BC-DB-37 | grade_min | TINYINT UNSIGNED | NOT NULL |
| BC-DB-38 | grade_max | TINYINT UNSIGNED | NOT NULL |
| BC-DB-39 | total_pages | TINYINT UNSIGNED | NOT NULL |
| BC-DB-40 | is_active | TINYINT(1) | NOT NULL, DEFAULT 1 |
| BC-DB-41 | page_config | JSON | NOT NULL (defines all 18 pages with sections and fields) |
| BC-DB-42 | created_at | TIMESTAMP | NULL |
| BC-DB-43 | updated_at | TIMESTAMP | NULL |
| BC-DB-44 | deleted_at | TIMESTAMP | NULL |

### 4.5 Validation Rules — Controller (Create)

| BC ID | Field | Rule(s) | Notes |
|-------|-------|---------|-------|
| BC-VAL-01 | student_id | required, integer, exists:students,id | Validated in both hpc_form and formStore |
| BC-VAL-02 | template_id | required, integer, exists:hpc_templates,id | Must be active Foundation template |
| BC-VAL-03 | report_date | required, date, date_format:Y-m-d | Must be within current academic session |
| BC-VAL-04 | status | required, in:draft,completed,archived | Defaults to draft |
| BC-VAL-05 | items | required, array, min:1 | At least one report item required |
| BC-VAL-06 | items.*.page_no | required, integer, min:1, max:18 | Foundation has exactly 18 pages |
| BC-VAL-07 | items.*.section_code | required, string, max:50 | Must match valid section codes for the page |
| BC-VAL-08 | items.*.field_name | required, string, max:100 | Must match valid field names for the section |
| BC-VAL-09 | items.*.field_value | nullable, string | Content stored as string regardless of type |
| BC-VAL-10 | items.*.field_type | required, in:text,emoji,image,number,boolean,json | Must match the field definition in template |
| BC-VAL-11 | items.*.display_order | required, integer, min:0 | Order within the page |
| BC-VAL-12 | tables | sometimes, array | Optional table data |
| BC-VAL-13 | tables.*.page_no | required_with:tables, integer, min:1, max:18 | Table page assignment |
| BC-VAL-14 | tables.*.table_code | required_with:tables, string, max:50 | Table identifier code |
| BC-VAL-15 | tables.*.row_data | required_with:tables, json | Row content as valid JSON |
| BC-VAL-16 | tables.*.col_count | required_with:tables, integer, min:1 | Number of columns |
| BC-VAL-17 | tables.*.row_count | required_with:tables, integer, min:1 | Number of rows |
| BC-VAL-18 | image_file | sometimes, file, image, mimes:jpg,jpeg,png,gif, max:2048 | Max 2MB |
| BC-VAL-19 | academic_session_id | required, integer, exists:academic_sessions,id | Current active session |
| BC-VAL-20 | term_id | required, integer, exists:terms,id | Current active term |

### 4.6 Validation Rules — Controller (Update)

| BC ID | Field | Rule(s) | Notes |
|-------|-------|---------|-------|
| BC-VAL-U01 | student_id | required, integer, exists:students,id | Validated in formStore for existing reports |
| BC-VAL-U02 | template_id | required, integer, exists:hpc_templates,id | Must be active Foundation template |
| BC-VAL-U03 | report_date | required, date, date_format:Y-m-d | Must be within current academic session |
| BC-VAL-U04 | status | required, in:draft,completed,archived | Defaults to draft |
| BC-VAL-U05 | items | required, array, min:1 | At least one report item required |
| BC-VAL-U06 | items.*.page_no | required, integer, min:1, max:18 | Foundation has exactly 18 pages |
| BC-VAL-U07 | items.*.section_code | required, string, max:50 | Must match valid section codes for the page |
| BC-VAL-U08 | items.*.field_name | required, string, max:100 | Must match valid field names for the section |
| BC-VAL-U09 | items.*.field_value | nullable, string | Content stored as string regardless of type |
| BC-VAL-U10 | items.*.field_type | required, in:text,emoji,image,number,boolean,json | Must match the field definition in template |
| BC-VAL-U11 | items.*.display_order | required, integer, min:0 | Order within the page |
| BC-VAL-U12 | tables | sometimes, array | Optional table data |
| BC-VAL-U13 | tables.*.page_no | required_with:tables, integer, min:1, max:18 | Table page assignment |
| BC-VAL-U14 | tables.*.table_code | required_with:tables, string, max:50 | Table identifier code |
| BC-VAL-U15 | tables.*.row_data | required_with:tables, json | Row content as valid JSON |
| BC-VAL-U16 | tables.*.col_count | required_with:tables, integer, min:1 | Number of columns |
| BC-VAL-U17 | tables.*.row_count | required_with:tables, integer, min:1 | Number of rows |
| BC-VAL-U18 | image_file | sometimes, file, image, mimes:jpg,jpeg,png,gif, max:2048 | Max 2MB |
| BC-VAL-U19 | academic_session_id | required, integer, exists:academic_sessions,id | Current active session |
| BC-VAL-U20 | term_id | required, integer, exists:terms,id | Current active term |

### 4.7 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | `tenant.hpc.view` | hpc_form() | With → form renders with data; Without → 403 Forbidden |
| BC-AUTH-02 | `tenant.hpc.create` | formStore() (create path) | With → new report created; Without → 403 Forbidden on POST |
| BC-AUTH-03 | `tenant.hpc.update` | formStore() (update path) | With → existing report updated; Without → 403 Forbidden on POST |
| BC-AUTH-04 | `tenant.hpc.view` + `tenant.hpc.create` | hpc_form(), formStore() (create) | Can view and create but not update existing reports |
| BC-AUTH-05 | `tenant.hpc.view` + `tenant.hpc.update` | hpc_form(), formStore() (update) | Can view and update existing reports but not create new ones |
| BC-AUTH-06 | Guest access (no session) | — | Redirect to /login for all routes |

### 4.8 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Page load with valid student_id | hpc_form() resolves Foundation template by grade, loads student info with relations, loads existing report if available, renders 18-page tabbed form |
| BC-BIZ-02 | Template resolution by grade | Foundation template selected when student grade >= grade_min AND grade <= grade_max AND type='foundation' |
| BC-BIZ-03 | 18-page tab navigation | Each tab corresponds to a Foundation page index (1-18); clicking tab loads page content via AJAX or SPA; active tab highlighted |
| BC-BIZ-04 | Auto-fill student info on page 1 | Name, DOB, age, parent name, address, class, section, roll number auto-populated from students/parents tables |
| BC-BIZ-05 | Attendance table display | Monthly attendance summary (present, absent, leave, total) fetched from attendance module and displayed in table format on the attendance page |
| BC-BIZ-06 | Save card via formStore (create) | New HpcReport with status='draft' created; HpcReportItem and HpcReportTable records inserted; success flash message shown |
| BC-BIZ-07 | Re-open saved card shows persisted data | Existing HpcReport loaded by student+session+term; all items and tables restored to form fields; no data loss |
| BC-BIZ-08 | Update existing card via formStore (update) | Existing HpcReport updated; items diffed (new items inserted, removed items soft-deleted); tables replaced |
| BC-BIZ-09 | Gender selection emoji | Three emoji options (Male, Female, Other); selection stored as field_value with field_type='emoji'; only one selectable at a time |
| BC-BIZ-10 | Family member toggle switch | Toggle ON/OFF for mother, father, siblings; each stored as field_type='boolean'; default OFF |
| BC-BIZ-11 | Friends add/remove dynamic list | Add friend via input field; remove via delete button; list stored as JSON array in field_value with field_type='json' |
| BC-BIZ-12 | Favorites dropdown selection | Dropdown menus for favorite subject, color, food, animal; selections stored as field_type='text' |
| BC-BIZ-13 | Goals text component | Text input/textarea for each goal; multiple goals per student; stored as field_type='text' with section_code='goals' |
| BC-BIZ-14 | Rubric table scoring | Assessment rubric with criteria rows and performance level columns (Beginning, Developing, Proficient, Exemplary); each scored via radio button/dropdown |
| BC-BIZ-15 | Image upload and preview | File input accepts jpg/png/gif up to 2MB; preview shown after selection; path stored in field_value with field_type='image'; image served via storage link |
| BC-BIZ-16 | Pincode and UDISE code inputs | Numeric text fields accepting only digits; pincode (6 digits), UDISE code (11 digits); validated client-side and server-side |
| BC-BIZ-17 | Drag-drop reorder of page elements | Elements within a page are reorderable via drag-and-drop; display_order values recomputed and persisted on save |
| BC-BIZ-18 | Double-click inline edit | Text/textarea fields become editable on double-click; changes auto-saved via AJAX on blur/enter; no full page reload |
| BC-BIZ-19 | Generate PDF of complete card | All 18 pages rendered to PDF via DomPDF/TCPDF; includes images, tables, emoji text; download initiated with filename student_name_date.pdf |
| BC-BIZ-20 | Email teacher card to parent | PDF generated and attached to email; sent to parent's email address from student master data; queued job for async delivery |
| BC-BIZ-21 | Status change from draft to completed | Status field updated from 'draft' to 'completed'; completed cards are locked for editing (read-only) |
| BC-BIZ-22 | No existing report loads empty form | First-time load for student; form shows empty fields with auto-filled student info; no previous data |
| BC-BIZ-23 | Multi-student data isolation | Each student's card data is completely isolated; switching students loads distinct data |
| BC-BIZ-24 | Form auto-save on tab switch | When switching tabs, current page data auto-saved as draft via AJAX |
| BC-BIZ-25 | Grade-appropriate template selection | Nursery-LKG-UKG-1-2-3 all resolve to Foundation template; no Preparatory template returned |

### 4.9 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) | Notes |
|-------|-----------|------------------|----------------|-------|
| BC-REF-01 | `hpc_reports.academic_session_id` | `academic_sessions.id` | CASCADE | Reports removed when session deleted |
| BC-REF-02 | `hpc_reports.term_id` | `terms.id` | CASCADE | Reports removed when term deleted |
| BC-REF-03 | `hpc_reports.student_id` | `students.id` | CASCADE | Reports removed when student deleted |
| BC-REF-04 | `hpc_reports.class_id` | `classes.id` | CASCADE | Reports removed when class deleted |
| BC-REF-05 | `hpc_reports.section_id` | `sections.id` | CASCADE | Reports removed when section deleted |
| BC-REF-06 | `hpc_reports.template_id` | `hpc_templates.id` | RESTRICT | Template cannot be deleted if reports reference it |
| BC-REF-07 | `hpc_reports.prepared_by` | `users.id` | CASCADE | Prepared_by reference |
| BC-REF-08 | `hpc_report_items.report_id` | `hpc_reports.id` | CASCADE | Items cascade deleted with report |
| BC-REF-09 | `hpc_report_tables.report_id` | `hpc_reports.id` | CASCADE | Tables cascade deleted with report |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Load teacher card form for valid Foundation student | 18-page HPC form loads with student info auto-filled, attendance tab visible, all tab labels rendered correctly | — | — | ⬜ |
| TC-P02 | Navigate through all 18 tabs sequentially | Each tab click loads corresponding page content with correct fields; tab 1 active by default; no JS errors | — | — | ⬜ |
| TC-P03 | Auto-fill student info from master data on page 1 | Name, DOB, age, class, section, parent name, address, roll number pre-populated from student database | — | — | ⬜ |
| TC-P04 | Attendance table loads with correct monthly data | Attendance table displays monthly rows with Present, Absent, Leave, Total columns; aggregates match attendance records | — | — | ⬜ |
| TC-P05 | Save teacher card as draft (first-time create) | HpcReport created with status=draft; HpcReportItem and HpcReportTable records inserted; success flash message | — | — | ⬜ |
| TC-P06 | Re-open saved teacher card shows all persisted data | Previously saved items and tables restored into form fields across all 18 pages; no data loss | — | — | ⬜ |
| TC-P07 | Update existing teacher card with modified data | Existing HpcReport updated; items diffed correctly; new items saved; removed items soft-deleted | — | — | ⬜ |
| TC-P08 | Gender selection via emoji (Male) | Male emoji clickable and highlighted; stored as field_type=emoji; persists on reload | — | — | ⬜ |
| TC-P09 | Gender selection via emoji (Female) | Female emoji clickable; replaces Male selection; persists on reload | — | — | ⬜ |
| TC-P10 | Gender selection via emoji (Other) | Other emoji clickable; selection persisted correctly | — | — | ⬜ |
| TC-P11 | Family member toggle — mother ON | Mother toggle ON; stored as boolean true; persists on reload | — | — | ⬜ |
| TC-P12 | Family member toggle — father ON, sibling OFF | Father ON, sibling OFF; each stored independently; persists on reload | — | — | ⬜ |
| TC-P13 | Add friend to dynamic friends list | Friend name entered and confirmed; appears in list; saved as JSON array | — | — | ⬜ |
| TC-P14 | Remove friend from dynamic friends list | Friend removed via delete button; disappears from list; JSON array updated | — | — | ⬜ |
| TC-P15 | Add multiple friends and verify persistence | Multiple friends added; all saved in JSON array; displayed on reload | — | — | ⬜ |
| TC-P16 | Select favorite subject, color, food from dropdowns | Each dropdown selection saved as field_type=text; all three persist on reload | — | — | ⬜ |
| TC-P17 | Enter textual goal in goals component | Goal text entered; saved; displayed in goals section on reload | — | — | ⬜ |
| TC-P18 | Add multiple goals | Multiple goals added; each saved as separate item; all displayed | — | — | ⬜ |
| TC-P19 | Rubric table — score all criteria | All rubric criteria scored via radio/dropdown; each score saved; on reload all scores displayed | — | — | ⬜ |
| TC-P20 | Upload student image (valid jpg) | Image uploaded; thumbnail preview shown; path stored with field_type=image; image accessible via URL | — | — | ⬜ |
| TC-P21 | Upload student image (valid png) | PNG image uploaded successfully with same behavior as JPG | — | — | ⬜ |
| TC-P22 | Enter pincode (6 digits) | Numeric input accepts 6 digits; saved and displayed on reload | — | — | ⬜ |
| TC-P23 | Enter UDISE code (11 digits) | Numeric input accepts 11 digits; saved and displayed on reload | — | — | ⬜ |
| TC-P24 | Drag-drop reorder elements within a page | Elements dragged to new positions; display_order updated after save; new order persists | — | — | ⬜ |
| TC-P25 | Double-click inline edit on text field | Field becomes editable on double-click; text modified; changes auto-saved on blur | — | — | ⬜ |
| TC-P26 | Generate PDF of completed teacher card | PDF generated with all 18 pages; includes all text, images, tables, rubric scores; download initiates | — | — | ⬜ |
| TC-P27 | Email teacher card PDF to parent | PDF attached to email; sent to parent email; success message shown; email received in test inbox | — | — | ⬜ |
| TC-P28 | Change status from draft to completed | Status updated to 'completed'; card becomes read-only | — | — | ⬜ |
| TC-P29 | Load card for student with no existing report | Form loads with empty fields; auto-fill data populated; no stale data present | — | — | ⬜ |
| TC-P30 | Switch between multiple students and verify data isolation | Each student's card loads with correct distinct data; no cross-contamination | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Access hpc-form with invalid (non-existent) student_id | 404 Not Found or validation error "Student not found" | — | — | ⬜ |
| TC-N02 | Access hpc-form for student with grade outside Foundation range (grade >= 4) | Error "No template found for this grade" or 404 | — | — | ⬜ |
| TC-N03 | Submit formStore with missing template_id | Validation error: template_id is required | — | — | ⬜ |
| TC-N04 | Submit formStore with missing report_date | Validation error: report_date is required | — | — | ⬜ |
| TC-N05 | Submit formStore with empty items array | Validation error: items must contain at least 1 item | — | — | ⬜ |
| TC-N06 | Upload invalid file type (.exe) for image field | Validation error: file must be an image (jpg, png, gif) | — | — | ⬜ |
| TC-N07 | Upload image exceeding 2MB size limit | Validation error: file may not be greater than 2048 kilobytes | — | — | ⬜ |
| TC-N08 | Submit with invalid date format in report_date | Validation error: report_date does not match format Y-m-d | — | — | ⬜ |
| TC-N09 | Network timeout during formStore save | Graceful error handling; no partial data committed; rollback confirmed | — | — | ⬜ |
| TC-N10 | Concurrent save by two users on same student card | Second save detects conflict; returns conflict error or uses last-write-wins | — | — | ⬜ |
| TC-N11 | Load form when no attendance configuration exists for class | Attendance page shows empty state message "Attendance not configured for this class" | — | — | ⬜ |
| TC-N12 | Access hpc-form without tenant.hpc.view permission | 403 Forbidden; no form or data exposed | — | — | ⬜ |
| TC-N13 | Submit formStore without tenant.hpc.create permission | 403 Forbidden on POST | — | — | ⬜ |
| TC-N14 | Update existing report via formStore without tenant.hpc.update permission | 403 Forbidden on POST | — | — | ⬜ |
| TC-N15 | Guest access to GET hpc/hpc-form/{student_id} | Redirect to /login | — | — | ⬜ |
| TC-N16 | Guest access to POST hpc/form/store | Redirect to /login; no data written | — | — | ⬜ |
| TC-N17 | Submit with field_type mismatch (text type but field_type=image with no file) | Validation error or graceful rejection of value | — | — | ⬜ |
| TC-N18 | Submit item with page_no=19 (exceeds Foundation max 18) | Validation error: page_no must not exceed 18 | — | — | ⬜ |
| TC-N19 | Submit with invalid academic_session_id | Validation error: academic_session_id not found | — | — | ⬜ |
| TC-N20 | Email send when parent email is missing from master data | Error message: "Parent email not found"; no email sent | — | — | ⬜ |
| TC-N21 | Access form with deleted/soft-deleted student | 404 Not Found or appropriate error | — | — | ⬜ |
| TC-N22 | Generate PDF when no data exists on any page | PDF generated with empty/blank pages; no error thrown | — | — | ⬜ |
| TC-N23 | Submit with non-numeric pincode (contains letters) | Validation error: pincode must be numeric | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | Foundation template resolution by grade range (Nursery=0, LKG=1, UKG=2, 1, 2, 3) | HpcTemplates query returns Foundation template for all grades 0-3; no Preparatory template | — | — | ⬜ |
| TC-D02 | B | Auto-fill data sources — student name and DOB | Student.name and Student.dob map to correct form fields | — | — | ⬜ |
| TC-D03 | C | Auto-fill data sources — parent/guardian info | Parent name, relation, email, phone loaded from parent relationship | — | — | ⬜ |
| TC-D04 | D | Auto-fill data sources — academic session | Active session resolved; session_id passed to all report queries | — | — | ⬜ |
| TC-D05 | E | hpc_report unique constraint enforcement (student+session+term) | Only one report per student per session per term; second save updates existing | — | — | ⬜ |
| TC-D06 | F | SoftDeletes on HpcReport model | deleted_at column present; soft-deleted reports excluded from normal queries | — | — | ⬜ |
| TC-D07 | G | SoftDeletes on HpcReportItem model | deleted_at column present; items not cascade-deleted on parent soft delete | — | — | ⬜ |
| TC-D08 | H | Activity log absence — no entries for HpcController actions | Creating/updating teacher card generates no activity_log entries | — | — | ⬜ |
| TC-D09 | I | LMS integration graceful fallback when LMS module absent | Form loads without LMS section; no errors or exceptions | — | — | ⬜ |
| TC-D10 | J | LMS integration loads data when LMS module is active | LMS data section appears; lesson/topic completion shown | — | — | ⬜ |
| TC-D11 | K | Attendance data scoped to current term | Attendance query filtered by term dates; only current term records included | — | — | ⬜ |
| TC-D12 | L | DB transaction wrapping in formStore (beginTransaction/commit/rollback) | All DB operations wrapped in transaction; rollback on any failure | — | — | ⬜ |
| TC-D13 | M | formStore update-or-create logic | Same controller method handles both create (no existing report) and update (existing report found) | — | — | ⬜ |
| TC-D14 | N | HpcReport → belongsTo(Student) relationship | report->student returns correct Student model | — | — | ⬜ |
| TC-D15 | O | HpcReport → belongsTo(HpcTemplates) relationship | report->template returns correct HpcTemplates model | — | — | ⬜ |
| TC-D16 | P | HpcReport → hasMany(HpcReportItem) relationship | report->items returns collection of HpcReportItem records | — | — | ⬜ |
| TC-D17 | Q | HpcReport → hasMany(HpcReportTable) relationship | report->tables returns collection of HpcReportTable records | — | — | ⬜ |
| TC-D18 | R | HpcReportItem → belongsTo(HpcReport) relationship | item->report returns parent HpcReport | — | — | ⬜ |
| TC-D19 | S | CASCADE delete — report force-deleted => items and tables removed | Items and tables cascade deleted when report is force-deleted | — | — | ⬜ |
| TC-D20 | T | RESTRICT on template delete when dependent reports exist | Cannot delete HpcTemplate if HpcReport references it | — | — | ⬜ |
| TC-D21 | U | Foundation page_config JSON stored with 18 page definitions | page_config decoded to array with 18 elements; each has page_no, title, sections | — | — | ⬜ |
| TC-D22 | V | field_type ENUM constraint ('text','emoji','image','number','boolean','json') | Invalid field_type value rejected at DB level | — | — | ⬜ |
| TC-D23 | W | status ENUM constraint ('draft','completed','archived') | Invalid status value rejected at DB level | — | — | ⬜ |
| TC-D24 | X | PDF generation is read-only (no DB mutation) | Generating PDF does not change any database records | — | — | ⬜ |
| TC-D25 | Y | Email send dispatched to queue (not synchronous) | Mail sent via queued job; jobs table entry created | — | — | ⬜ |

### 5.4 Code Review Test Cases

| TC ID | Category | Priority | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|----------|-------------|-----------------|---------|---------|--------|
| TC-CR01 | CR | P1 | Blade @can Directives — Permission-based visibility for all action buttons | View includes @can('tenant.hpc.view'), @can('tenant.hpc.create'), @can('tenant.hpc.update') wrapping form view, create, and update actions; users without corresponding permissions do not see the respective controls | — | — | ◌ |
| TC-CR02 | CR | P1 | Controller — DB Transactions in formStore() | formStore() uses DB::beginTransaction() before writes, DB::commit() on success, DB::rollBack() in catch block on exception; no partial data persisted on failure | — | — | ◌ |
| TC-CR03 | CR | P1 | JSON Response After formStore Save | formStore() returns response()->json() with success: true/false and message after create/update; client-side JS handles display of success/error feedback | — | — | ◌ |
| TC-CR04 | CR | P1 | Update-or-Create Logic in formStore() | Same method checks for existing HpcReport by student+session+term; if not found → create new report; if found → update existing report with item diffing | — | — | ◌ |

---

## 7. Detailed Test Steps

### 7.1 Positive TC Steps

#### TC-P01: Load Teacher Card Form For Valid Foundation Student
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as admin user with tenant.hpc.view, tenant.hpc.create, tenant.hpc.update permissions | Dashboard loads successfully |
| 2 | Navigate to HPC → Teacher Card section | Student selection interface displayed |
| 3 | Select a Nursery-grade student (grade=0) from the student list | URL changes to hpc/hpc-form/{student_id} |
| 4 | Wait for the form to fully load | 18-page tabbed interface renders; tab 1 ("Student Info") active by default |
| 5 | Verify all 18 tab labels are visible and correctly named | Tabs: Student Info, Attendance, Gender, Family, Friends, Favorites, Goals, Rubric 1, Rubric 2, Rubric 3, Image Upload, School Info, etc. |
| 6 | Verify student name displayed in the header | Student name from master data shown |
| 7 | Check browser console for errors | No JavaScript errors logged |

#### TC-P02: Navigate Through All 18 Tabs Sequentially
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click on tab 2 (e.g., "Attendance") | Page 2 content loads; tab 2 highlighted with active styling; tab 1 loses active state |
| 2 | Verify page 2 fields render correctly | Attendance table or chart displayed |
| 3 | Click on tab 18 (e.g., "Summary/Signature") | Page 18 content loads; signature fields displayed |
| 4 | Click back to tab 1 | Tab 1 content restored; no data loss from previously filled fields |
| 5 | Sequentially click each tab from 1 to 18 | Every page loads its content without errors |
| 6 | Time each page transition | Page transitions complete in under 2 seconds each |

#### TC-P03: Auto-Fill Student Info From Master Data On Page 1
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load teacher card form for a known student with pre-seeded master data | Form loads with tab 1 active |
| 2 | Verify student full name field | Pre-filled with value from students.name |
| 3 | Verify date of birth field | Pre-filled with value from students.dob in dd/mm/YYYY format |
| 4 | Verify calculated age field | Age calculated correctly from DOB |
| 5 | Verify class name field | Pre-filled with class name from students.class relation |
| 6 | Verify section name field | Pre-filled with section name from students.section relation |
| 7 | Verify roll number field | Pre-filled from student record |
| 8 | Verify parent/guardian name field | Pre-filled from parent.name via parent relationship |
| 9 | Verify address field | Pre-filled from student address |
| 10 | Verify no field is empty on page 1 | All fields populated with non-null values |

#### TC-P04: Attendance Table Loads With Correct Monthly Data
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to the attendance page (tab 2 or designated attendance tab) | Attendance section displayed |
| 2 | Verify table headers | Columns: Month, Present Days, Absent Days, Leave Days, Total Days |
| 3 | Check monthly rows | One row per month in current term |
| 4 | Verify Present count for January | Matches attendance records for January |
| 5 | Verify Absent count for February | Matches attendance records for February |
| 6 | Verify Leave count for March | Matches attendance records for March |
| 7 | Verify Total Days column | Sum of Present + Absent + Leave for each month |
| 8 | Verify grand total row at bottom | Aggregated totals displayed |

#### TC-P05: Save Teacher Card As Draft (First-Time Create)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill in data on pages 1-5 with sample values | Each field populated with test data |
| 2 | Click the "Save as Draft" button | Form submit triggered; POST request to hpc/form/store |
| 3 | Wait for save confirmation | Flash success message: "Teacher card saved as draft successfully" |
| 4 | Open database and check hpc_reports table | New record with status='draft', correct student_id, session_id, term_id, template_id |
| 5 | Check hpc_report_items table | Records created for each filled field with correct page_no, section_code, field_name, field_value, field_type, display_order |
| 6 | Check hpc_report_tables table | Records created for any table data |
| 7 | Verify no error in application logs | Logs clean |

#### TC-P06: Re-Open Saved Teacher Card Shows All Persisted Data
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate away from the teacher card to any other page | Dashboard or other module loads |
| 2 | Navigate back to the same student's teacher card | hpc/hpc-form/{same_student_id} |
| 3 | Verify page 1 fields | Previously saved student info values restored |
| 4 | Verify page 2 fields (attendance) | Attendance data refreshed and correct |
| 5 | Navigate through pages 3-5 | Each page shows previously saved field values |
| 6 | Compare saved values with original input | Exact match for all text, emoji, boolean, JSON values |
| 7 | Verify image field shows saved image thumbnail | Image displayed from stored path |
| 8 | Verify rubric scores | All rubric criteria scores restored |

#### TC-P07: Update Existing Teacher Card With Modified Data
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open an existing saved teacher card with known data | Form loads with saved data |
| 2 | Modify a text field on page 1 (change student note) | Text changed |
| 3 | Add a new item on page 3 (add new favorite) | New dropdown selection |
| 4 | Remove an existing item on page 5 (delete a goal) | Goal removed from UI |
| 5 | Change rubric score on page 7 | Different score selected |
| 6 | Click Save | POST to hpc/form/store |
| 7 | Verify success message | Flash: "Teacher card updated successfully" |
| 8 | Reload and verify changes | Modified text updated; new item present; removed item gone; rubric score changed |
| 9 | Check DB for correct state | Existing items with soft-deleted_at set for removed items; new items inserted |

#### TC-P08: Gender Selection Via Emoji (Male)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to gender selection page | Three emoji icons displayed: Male, Female, Other |
| 2 | Verify all three options are visible | Male (👦), Female (👧), Other (🧒) emojis shown |
| 3 | Click on the Male emoji | Male emoji becomes highlighted/selected; other two deselected |
| 4 | Save the card | Data persisted |
| 5 | Reload the page | Male emoji still selected; field_value stores "male" with field_type="emoji" |

#### TC-P09: Gender Selection Via Emoji (Female)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load card with existing Male selection | Male highlighted |
| 2 | Click Female emoji | Female highlighted; Male deselected |
| 3 | Save and reload | Female emoji selected; field_value stores "female" |

#### TC-P10: Gender Selection Via Emoji (Other)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Other emoji | Other highlighted; others deselected |
| 2 | Save and reload | Other emoji selected; field_value stores "other" |

#### TC-P11: Family Member Toggle — Mother ON
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to family section | Toggle switches for Mother, Father, Sibling displayed |
| 2 | Verify initial state | All toggles default OFF |
| 3 | Click Mother toggle to ON | Switch slides to ON position; visual state changed |
| 4 | Save and reload | Mother toggle still ON; stored as boolean true |

#### TC-P12: Family Member Toggle — Father ON, Sibling OFF
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Click Father toggle to ON | Father ON |
| 2 | Ensure Sibling toggle is OFF | Sibling OFF |
| 3 | Save and reload | Father ON, Sibling OFF; each stored as independent boolean fields |

#### TC-P13: Add Friend To Dynamic Friends List
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to friends page | Friends list displayed (empty initially) |
| 2 | Click "Add Friend" button | New input row appears with text field and confirm button |
| 3 | Type friend name "Aryan" | Text entered |
| 4 | Click confirm/checkmark | Friend "Aryan" added to the list with a remove button |
| 5 | Save and reload | Friend list shows "Aryan"; stored as JSON array |

#### TC-P14: Remove Friend From Dynamic Friends List
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load friends list with 3 existing friends | Friends displayed: [Aryan, Priya, Rohan] |
| 2 | Click remove/delete (X) button on "Priya" | "Priya" removed from UI list; remaining: [Aryan, Rohan] |
| 3 | Save and reload | Friend list shows [Aryan, Rohan]; "Priya" not present |
| 4 | Verify DB | JSON array contains only "Aryan" and "Rohan" |

#### TC-P15: Add Multiple Friends And Verify Persistence
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add friend "Ravi" | Ravi added |
| 2 | Add friend "Sneha" | Sneha added |
| 3 | Add friend "Arjun" | Arjun added |
| 4 | Save card | Data saved |
| 5 | Reload page | All three friends displayed in list |
| 6 | Check DB field_value | JSON array: ["Ravi","Sneha","Arjun"] |

#### TC-P16: Select Favorite Subject, Color, Food From Dropdowns
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to favorites page | Three dropdowns: Favorite Subject, Favorite Color, Favorite Food |
| 2 | Select "Mathematics" from subject dropdown | Value selected and displayed |
| 3 | Select "Blue" from color dropdown | Value selected |
| 4 | Select "Pizza" from food dropdown | Value selected |
| 5 | Save and reload | All three selections persisted |
| 6 | Change color to "Red" | Updated |
| 7 | Save and reload | Color now shows "Red"; subject and food unchanged |

#### TC-P17: Enter Textual Goal In Goals Component
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to goals page | Goals component with input field displayed |
| 2 | Type goal "Learn to read 10 sight words" | Text entered in input |
| 3 | Click "Add Goal" or press Enter | Goal added to list below |
| 4 | Save and reload | Goal displayed; stored as text field_value |

#### TC-P18: Add Multiple Goals
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Add goal "Count to 100" | Second goal added |
| 2 | Add goal "Write name independently" | Third goal added |
| 3 | Add goal "Identify shapes" | Fourth goal added |
| 4 | Save and reload | All 4 goals displayed in order |
| 5 | Verify each goal stored as separate item | Each goal has its own hpc_report_item record with section_code='goals' |

#### TC-P19: Rubric Table — Score All Criteria
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to rubric page (e.g., page 7) | Rubric table displayed with criteria rows |
| 2 | Identify criteria: Listening, Speaking, Reading, Writing | Four criteria rows visible |
| 3 | Score "Listening" as "Proficient" (3rd level) | Score selected |
| 4 | Score "Speaking" as "Developing" (2nd level) | Score selected |
| 5 | Score "Reading" as "Exemplary" (4th level) | Score selected |
| 6 | Score "Writing" as "Beginning" (1st level) | Score selected |
| 7 | Save and reload | All four rubric scores displayed correctly |

#### TC-P20: Upload Student Image (Valid JPG)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to image upload section | File input with "Choose File" button displayed |
| 2 | Select a valid JPG file (size: 500KB) | File name displayed next to button |
| 3 | Verify image preview | Thumbnail preview of uploaded image shown |
| 4 | Click Save | POST to formStore with image data |
| 5 | Verify success | Image saved; path stored in item with field_type='image' |
| 6 | Reload page | Image thumbnail loaded from stored path |
| 7 | Verify image accessibility | Image URL returns 200 and correct content-type |

#### TC-P21: Upload Student Image (Valid PNG)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Repeat TC-P20 steps with a PNG file (300KB) | Same successful behavior as JPG |
| 2 | Verify PNG displays correctly | PNG rendered in preview and on reload |

#### TC-P22: Enter Pincode (6 Digits)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to school info page | Pincode input field displayed |
| 2 | Enter pincode "110001" | 6-digit numeric input accepted |
| 3 | Save and reload | Pincode "110001" displayed |
| 4 | Verify only digits allowed (try letter "a") | Letter rejected or not entered |

#### TC-P23: Enter UDISE Code (11 Digits)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter UDISE code "12345678901" | 11-digit numeric input accepted |
| 2 | Save and reload | UDISE code "12345678901" displayed |
| 3 | Verify only digits allowed | Non-numeric characters rejected |

#### TC-P24: Drag-Drop Reorder Elements Within A Page
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to a page with 4+ sortable elements | Elements displayed in initial order (A, B, C, D) |
| 2 | Drag element D to position 1 | Elements reorder to D, A, B, C |
| 3 | Drag element B to position 3 | Elements reorder to D, A, C, B |
| 4 | Save card | display_order values updated (D=0, A=1, C=2, B=3) |
| 5 | Reload page | Elements appear in D, A, C, B order |

#### TC-P25: Double-Click Inline Edit On Text Field
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Double-click on a text field (e.g., "Notes" on page 1) | Field transforms to editable input/textarea |
| 2 | Modify the text content | New text typed |
| 3 | Click outside the field (blur) or press Enter | Field reverts to display mode; AJAX save triggered |
| 4 | Verify success indicator | Brief flash or icon showing auto-save success |
| 5 | Reload page | Modified text displayed |

#### TC-P26: Generate PDF Of Completed Teacher Card
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure all 18 pages have data | Full card completed |
| 2 | Click "Generate PDF" button | PDF generation process starts |
| 3 | Wait for generation | Loading indicator shown |
| 4 | Verify download | PDF file downloaded with filename pattern: student_name_report_date.pdf |
| 5 | Open the PDF file | All 18 pages rendered; images, tables, rubric scores visible |
| 6 | Verify PDF page count | 18 pages in PDF |
| 7 | Check PDF content | Text content matches form data |

#### TC-P27: Email Teacher Card PDF To Parent
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Verify parent email exists in student master data | Parent email: parent@example.com |
| 2 | Click "Email to Parent" button | Confirmation dialog: "Send teacher card PDF to parent@example.com?" |
| 3 | Click "Confirm" | Email sending initiated |
| 4 | Verify success message | Flash: "Teacher card has been emailed to the parent successfully" |
| 5 | Check email test inbox (Mailtrap) | Email received with subject "Teacher Card - {student_name}" |
| 6 | Open email and verify attachment | PDF attached with correct filename |
| 7 | Verify email body | Contains student name and school name |

#### TC-P28: Change Status From Draft To Completed
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open an existing draft teacher card | Status badge shows "Draft" |
| 2 | Click "Mark as Completed" button | Confirmation prompt: "Mark this card as completed?" |
| 3 | Click Confirm | Status changes to "Completed"; visual badge updates |
| 4 | Verify all fields become read-only | No edit controls visible on any page |
| 5 | Reload page | Status badge still shows "Completed"; fields read-only |
| 6 | Check DB | hpc_reports.status = 'completed' |

#### TC-P29: Load Card For Student With No Existing Report
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Select a student who has never had a teacher card created | Form loads |
| 2 | Verify auto-filled fields on page 1 | Student info pre-populated from master data |
| 3 | Verify all form fields are empty | No stale or previous data present |
| 4 | Verify attendance table | Attendance data loaded fresh from DB |
| 5 | Verify no error messages or warnings | Console and UI clean |

#### TC-P30: Switch Between Multiple Students And Verify Data Isolation
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Complete and save card for Student A with unique data "Alpha" | Card saved for Student A |
| 2 | Navigate to Student B's card (different student_id) | Student B's form loaded |
| 3 | Enter data "Beta" for Student B and save | Card saved for Student B |
| 4 | Navigate back to Student A | Student A's data shows "Alpha" not "Beta" |
| 5 | Navigate back to Student B | Student B's data shows "Beta" |
| 6 | Verify no data cross-contamination | Each student's data isolated |

### 7.2 Negative TC Steps

#### TC-N01: Access hpc-form With Invalid (Non-Existent) Student_ID
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to hpc/hpc-form/99999 | Non-existent student ID |
| 2 | Observe HTTP response | 404 Not Found |
| 3 | Verify error message | "Student not found" or equivalent |
| 4 | Check application logs | No exception stack trace exposed to user |

#### TC-N02: Access hpc-form For Student Outside Foundation Range
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to hpc/hpc-form/{student_id} where student is Grade 4 | Student outside Foundation (Nursery-3) range |
| 2 | Observe response | Error message: "No HPC template found for this grade" |
| 3 | Verify HTTP status | 404 or 422 |

#### TC-N03: Submit formStore With Missing Template_ID
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open hpc/hpc-form for valid student | Form loads |
| 2 | Remove template_id from the POST payload via browser dev tools | Payload without template_id |
| 3 | Submit the form | Validation error returned |
| 4 | Verify error message | "The template id field is required" |
| 5 | Verify HTTP status | 422 Unprocessable Entity |

#### TC-N04: Submit formStore With Missing Report_Date
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill all required fields | Data ready |
| 2 | Remove report_date from payload | Missing field |
| 3 | Submit save | Validation error: "The report date field is required" |

#### TC-N05: Submit formStore With Empty Items Array
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Fill only header/top-level fields | No items data |
| 2 | Set items to empty array [] | Payload: {items: []} |
| 3 | Submit save | Validation error: "The items field must contain at least 1 item" |

#### TC-N06: Upload Invalid File Type (.exe) For Image Field
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to image upload section | File input displayed |
| 2 | Click "Choose File" and select a .exe file | File selected: setup.exe |
| 3 | Attempt to upload/save | Validation error: "The image file must be a file of type: jpg, jpeg, png, gif" |

#### TC-N07: Upload Image Exceeding 2MB Size Limit
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Prepare a 3MB image file | Oversized.jpg (3MB) |
| 2 | Select the 3MB file in the upload input | File selected |
| 3 | Attempt to upload/save | Validation error: "The image file may not be greater than 2048 kilobytes" |

#### TC-N08: Submit With Invalid Date Format In Report_Date
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set report_date to "15-01-2026" (dd-mm-YYYY format) | Wrong format (expected Y-m-d) |
| 2 | Submit save | Validation error: "The report date does not match the format Y-m-d" |

#### TC-N09: Network Timeout During formStore Save
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open browser dev tools → Network tab | Throttling controls accessible |
| 2 | Set network throttling to "Slow 3G" | Simulated slow network |
| 3 | Fill form data and click Save | Request in progress; loading spinner visible |
| 4 | Disconnect network or let request time out | Error message: "Network error. Please check your connection and try again." |
| 5 | Check database for partial save | No partial data written; transaction rolled back |

#### TC-N10: Concurrent Save By Two Users On Same Student Card
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | User A opens student card in Browser A | Form loaded with initial data |
| 2 | User B opens same student card in Browser B | Same form loaded |
| 3 | User A modifies field and saves | Save succeeds |
| 4 | User B modifies same field differently and saves | Either: (a) Conflict error shown, (b) Last-write-wins, or (c) Optimistic lock prevents override |
| 5 | Reload in Browser A | Shows latest state after both saves |

#### TC-N11: Load Form When No Attendance Configuration Exists For Class
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure test student's class has no attendance configuration | No attendance config seeded |
| 2 | Load teacher card for this student | Form loads successfully |
| 3 | Navigate to attendance tab/page | Empty state message: "Attendance has not been configured for this class" |
| 4 | Verify no exceptions thrown | Page loads without errors |

#### TC-N12: Access hpc-form Without Tenant.Hpc.View Permission
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as a user role without tenant.hpc.view permission | Dashboard loads with limited menu |
| 2 | Manually navigate to hpc/hpc-form/{student_id} | 403 Forbidden response |
| 3 | Verify no form HTML or student data returned | Empty or error page only |

#### TC-N13: Submit formStore Without Tenant.Hpc.Create Permission
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with tenant.hpc.view but NOT tenant.hpc.create | User can view form |
| 2 | Fill form data | Data entered |
| 3 | Click Save (POST to hpc/form/store) | 403 Forbidden |
| 4 | Verify no record created in DB | hpc_reports table unchanged |

#### TC-N14: Update Existing Report Via formStore Without Tenant.Hpc.Update Permission
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user with view and create but NOT update | User can view form |
| 2 | Open an existing saved card | Saved data displayed |
| 3 | Modify a field and click Save | 403 Forbidden |
| 4 | Verify DB unchanged | Report items not modified |

#### TC-N15: Guest Access To GET hpc/hpc-form/{student_id}
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout of the application | Session destroyed |
| 2 | Navigate to hpc/hpc-form/1 | Redirected to /login |
| 3 | Verify original URL preserved after login | After login, redirected back to hpc/hpc-form/1 |

#### TC-N16: Guest Access To POST hpc/form/store
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout of the application | Session destroyed |
| 2 | Send POST request to hpc/form/store with sample data via Postman or curl | Redirect to /login or 401 Unauthorized |
| 3 | Verify no record created in DB | No new HpcReport record |

#### TC-N17: Submit With Field_Type Mismatch
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set field_type="image" but provide a plain text field_value (not a file path) | Type mismatch |
| 2 | Submit save | Validation error or field_value rejected |

#### TC-N18: Submit Item With Page_No=19 (Exceeds Foundation Max 18)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set page_no=19 for a report item | Exceeds Foundation 18-page limit |
| 2 | Submit save | Validation error: "The page no must not exceed 18" |

#### TC-N19: Submit With Invalid Academic_Session_ID
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set academic_session_id to 99999 | Non-existent session ID |
| 2 | Submit save | Validation error: "The academic session id is invalid" |

#### TC-N20: Email Send When Parent Email Is Missing
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load card for student whose parent record has NULL email | Form loads |
| 2 | Click "Email to Parent" | Error message: "Parent email address is not configured. Please update parent contact details." |
| 3 | Check mail queue | No email queued |

#### TC-N21: Access Form With Soft-Deleted Student
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Soft-delete a student from the database (set deleted_at) | Student.deleted_at = now |
| 2 | Navigate to hpc/hpc-form/{soft_deleted_student_id} | 404 Not Found (Student query uses whereNull deleted_at or fails) |

#### TC-N22: Generate PDF When No Data Exists On Any Page
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Load teacher card for a new student (no data entered) | Blank form |
| 2 | Click "Generate PDF" without entering any data | PDF generated with blank/empty pages |
| 3 | Verify PDF has 18 pages | All pages present but empty |
| 4 | Verify no error thrown | PDF generation succeeds without exception |

#### TC-N23: Submit With Non-Numeric Pincode
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enter "ABC123" in pincode field | Non-numeric characters |
| 2 | Attempt to save | Validation error: "The pincode must be a number" or field rejects non-numeric input |

### 7.3 Dependency TC Steps

#### TC-D01: Foundation Template Resolution By Grade Range
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Query HpcTemplates where type='foundation' | Foundation template with grade_min=0, grade_max=3 found |
| 2 | Check hpc_form() query logic | WHERE grade_min <= student_grade AND grade_max >= student_grade AND type='foundation' |
| 3 | Test for Nursery student (grade 0) | Template resolved |
| 4 | Test for LKG student (grade 1) | Template resolved |
| 5 | Test for UKG student (grade 2) | Template resolved |
| 6 | Test for Grade 1 student | Template resolved |
| 7 | Test for Grade 2 student | Template resolved |
| 8 | Test for Grade 3 student | Template resolved |
| 9 | Test for Grade 4 student | No Foundation template resolved (may get Preparatory) |

#### TC-D02: Auto-Fill Data Sources — Student Name And DOB
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Examine hpc_form() controller code | Student::with(['class','section','parent'])->findOrFail($studentId) used |
| 2 | Verify name field maps to students.name | Direct column mapping |
| 3 | Verify DOB field maps to students.dob | Direct column mapping |
| 4 | Verify age calculated from DOB | Age = diff in years between DOB and current date |

#### TC-D03: Auto-Fill Data Sources — Parent/Guardian Info
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check Student model relationship | hasOne(Parent) or belongsTo(Parent) defined |
| 2 | Verify parent name loaded | $student->parent->name displayed |
| 3 | Verify parent email loaded | $student->parent->email displayed |
| 4 | Verify parent phone loaded | $student->parent->phone displayed |

#### TC-D04: Auto-Fill Data Sources — Academic Session
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check current session resolution logic | AcademicSession::where('is_active', true)->first() used |
| 2 | Verify session_id passed to view | Available in form as hidden field or data attribute |
| 3 | Verify report queries scoped by session | HpcReport::where('academic_session_id', $sessionId) present |

#### TC-D05: hpc_report Unique Constraint Enforcement
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create first HpcReport for student+session+term | Record created successfully |
| 2 | Call formStore again with same student+session+term | Update-or-create logic: existing record found and updated |
| 3 | Verify no duplicate record | Only 1 record in hpc_reports for this combination |
| 4 | Check for DB unique index | Composite unique index on (student_id, academic_session_id, term_id) if defined |

#### TC-D06: SoftDeletes On HpcReport Model
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check HpcReport model file | Imports SoftDeletes trait: use SoftDeletes; |
| 2 | Check hpc_reports table DDL | deleted_at TIMESTAMP NULL column exists |
| 3 | Soft-delete a report | deleted_at set to current timestamp |
| 4 | Query normally | Report excluded from results |
| 5 | Query with withTrashed() | Report included in results |

#### TC-D07: SoftDeletes On HpcReportItem Model
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check HpcReportItem model file | SoftDeletes trait imported |
| 2 | Soft-delete parent report (not force delete) | Report.deleted_at set; items.deleted_at remains NULL |
| 3 | Verify items still accessible | Items not cascade soft-deleted with parent |

#### TC-D08: Activity Log Absence — No Entries For HpcController Actions
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Search HpcController for activityLog() calls | No activityLog() calls found in hpc_form() or formStore() |
| 2 | Create a teacher card | Save succeeds |
| 3 | Query activity_log table | No entry with subject_type related to HpcReport or HpcController |

#### TC-D09: LMS Integration Graceful Fallback When LMS Module Absent
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Disable or unload the LMS module | LMS module not registered |
| 2 | Load teacher card form | Form loads without LMS data section |
| 3 | Verify no exception or error | Page loads cleanly; console empty |

#### TC-D10: LMS Integration Loads Data When LMS Module Is Active
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Enable LMS module with seeded student data | LMS module active with lesson/topic completion for this student |
| 2 | Load teacher card form | Form loads with LMS data section visible |
| 3 | Verify completion data shown | Lesson names, topic counts, completion percentages displayed |

#### TC-D11: Attendance Data Scoped To Current Term
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check attendance query in hpc_form() | Attendance::where('term_id', $currentTermId) filter present |
| 2 | Seed attendance records in current term and a different term | Records exist in both terms |
| 3 | Load form | Only current term attendance records shown |

#### TC-D12: DB Transaction Wrapping In formStore
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review formStore() method code | DB::beginTransaction() called before writes |
| 2 | Verify commit on success | DB::commit() called when all writes succeed |
| 3 | Verify rollback on failure | DB::rollBack() called in catch block on exception |
| 4 | Force an exception mid-save | Transaction rolled back; no partial data |

#### TC-D13: formStore Update-Or-Create Logic
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check formStore for existing report lookup | $existingReport = HpcReport::where([...])->first() |
| 2 | If no existing report: create path | new HpcReport inserted; new items inserted |
| 3 | If existing report: update path | Existing report updated; items diffed and modified |
| 4 | Verify same endpoint used for both | Single POST route hpc/form/store handles both cases |

#### TC-D14: HpcReport → BelongsTo(Student) Relationship
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check HpcReport model | public function student(): BelongsTo defined |
| 2 | Load a report and access ->student | Returns correct Student model instance |
| 3 | Verify FK column | 'student_id' used as foreign key |

#### TC-D15: HpcReport → BelongsTo(HpcTemplates) Relationship
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check HpcReport model | public function template(): BelongsTo defined |
| 2 | Load a report and access ->template | Returns correct HpcTemplates model |
| 3 | Verify FK column | 'template_id' used as foreign key |

#### TC-D16: HpcReport → HasMany(HpcReportItem) Relationship
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check HpcReport model | public function items(): HasMany defined |
| 2 | Load a report with items | ->items returns Collection of HpcReportItem |
| 3 | Verify items filtered by report_id | All returned items have matching report_id |

#### TC-D17: HpcReport → HasMany(HpcReportTable) Relationship
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check HpcReport model | public function tables(): HasMany defined |
| 2 | Load a report with tables | ->tables returns Collection of HpcReportTable |
| 3 | Verify FK column | 'report_id' used as foreign key |

#### TC-D18: HpcReportItem → BelongsTo(HpcReport) Relationship
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check HpcReportItem model | public function report(): BelongsTo defined |
| 2 | Load an item and access ->report | Returns correct parent HpcReport |
| 3 | Verify FK column | 'report_id' used as foreign key |

#### TC-D19: CASCADE Delete — Report Force-Deleted => Items And Tables Removed
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check DDL for hpc_report_items.report_id | ON DELETE CASCADE defined |
| 2 | Check DDL for hpc_report_tables.report_id | ON DELETE CASCADE defined |
| 3 | Force-delete an HpcReport (with items and tables) | Report, all items, and all tables permanently deleted |
| 4 | Verify no orphan records | hpc_report_items and hpc_report_tables empty for deleted report_id |

#### TC-D20: RESTRICT On Template Delete When Dependent Reports Exist
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check DDL for hpc_reports.template_id | ON DELETE RESTRICT defined |
| 2 | Attempt to delete a HpcTemplate that has associated HpcReport records | SQL error: Cannot delete or update a parent row; FK constraint fails |
| 3 | Verify application-level check (if any) | Controller may check before attempting DB delete |

#### TC-D21: Foundation page_config JSON Stored With 18 Page Definitions
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Query Foundation template's page_config | Returns JSON string |
| 2 | Decode JSON to array | Array with 18 elements |
| 3 | Check each element structure | Each has page_no (1-18), title (string), sections (array) |
| 4 | Verify page_no values 1 through 18 | Sequential; no gaps |

#### TC-D22: Field_Type ENUM Constraint
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check DDL for hpc_report_items.field_type | ENUM('text','emoji','image','number','boolean','json') |
| 2 | Attempt to INSERT with field_type='video' | SQL error: Data truncated for column 'field_type' |

#### TC-D23: Status ENUM Constraint
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check DDL for hpc_reports.status | ENUM('draft','completed','archived') |
| 2 | Attempt to INSERT with status='deleted' | SQL error: Data truncated for column 'status' |

#### TC-D24: PDF Generation Is Read-Only (No DB Mutation)
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review PDF generation code (likely in a service class) | Code uses SELECT queries only; no INSERT/UPDATE/DELETE |
| 2 | Generate PDF while DB query logging is enabled | Only SELECT queries logged |
| 3 | Compare DB state before and after PDF generation | Identical state |

#### TC-D25: Email Send Dispatched To Queue
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review email dispatch code | Mail::to()->queue() or dispatch(new SendTeacherCardEmailJob) used; not Mail::to()->send() |
| 2 | Trigger email send | Job dispatched to queue |
| 3 | Check jobs table | Entry in jobs table with correct payload |
| 4 | Verify immediate response | User gets success response before email is actually sent |

### 7.4 Code Review TC Steps

#### TC-CR01: Blade @can Directives — Permission-based Visibility for All Action Buttons
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect the Blade view for hpc_form | View file found in Modules/Hpc/Resources/views/ |
| 2 | Check for @can('tenant.hpc.view') wrapping the form display | Page load check for hpc_form; user without view permission cannot access the route |
| 3 | Check for @can('tenant.hpc.create') on the Save button (new report) | Save button visible only for users with create permission |
| 4 | Check for @can('tenant.hpc.update') on the Save button (existing report) | Save/Update button visible only for users with update permission |
| 5 | Login as user with all permissions | All form controls visible and functional |
| 6 | Login as user with view only (no create/update) | Form displayed in read-only mode; no Save/Edit buttons |

#### TC-CR02: Controller — DB Transactions in formStore()
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Open HpcController.php | Controller class found in Modules/Hpc/Http/Controllers/ |
| 2 | Inspect formStore() method | DB::beginTransaction() called before any write operations |
| 3 | Verify commit on success | DB::commit() called when all writes succeed |
| 4 | Verify rollback on failure | DB::rollBack() called in catch block on exception |
| 5 | Simulate DB failure during save | Transaction rolled back; no partial HpcReport or HpcReportItem created |

#### TC-CR03: JSON Response After formStore Save
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Create a new teacher card | POST to hpc/form/store; controller returns response()->json() |
| 2 | Verify JSON response after create | Response contains success: true and message: 'Teacher card saved successfully' |
| 3 | Update the existing card | POST to hpc/form/store again; JSON response with success flag |
| 4 | Verify JSON response after update | success: true with update confirmation message |
| 5 | Trigger validation error | JSON response with success: false and error message; 422 status |

#### TC-CR04: Update-or-Create Logic in formStore()
| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Review formStore() for existing report lookup | $existingReport = HpcReport::where('student_id', $id)->where('academic_session_id', $sessionId)->where('term_id', $termId)->first() |
| 2 | If no existing report: create path | new HpcReport inserted; new HpcReportItem and HpcReportTable records created |
| 3 | If existing report: update path | Existing report fields updated; items diffed (new inserted, removed soft-deleted); tables replaced |
| 4 | Verify single endpoint for both | POST hpc/form/store handles both create and update via presence check |

---

## 8. CODE-TRACE: Controller Method Execution Traces

### CODE-TRACE-01: `index()` � HpcController (Line 56)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcController.php:58` | `$this->authorizeHpcIndex()` � calls `Gate::authorize('tenant.hpc.viewAny')` via HpcIndexDataTrait |
| 2 | `HpcIndexDataTrait.php:28-49` | `$this->getHpcIndexData()` � loads sessions, terms, classes, sections, and paginated students |
| 3 | `HpcController.php:63-64` | `SchoolClass::active()->get()`, `Section::active()->get()` � load filter dropdowns |
| 4 | `HpcController.php:65` | `$this->getFilteredStudents($request)->paginate(10)` � filters by class/section/session/term |
| 5 | `HpcController.php:67` | `return view('hpc::hpc.index', $data)` � renders HPC dashboard/student list |

### CODE-TRACE-02: `hpcTemplates()` � HpcController (Line 93)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcController.php:95` | `Gate::authorize('tenant.hpc.viewAny')` |
| 2 | `HpcController.php:97` | `$activeTab = $request->get('active_tab', 'hpc-templates')` |
| 3 | `HpcController.php:99-110` | Calls 4 private query helpers: `getActiveTemplates()`, `getActiveTemplateParts()`, `getActiveTemplateSections()`, `getActiveTemplateRubrics()` � each with tab-scoped filtering and unique paginator names |
| 4 | `HpcController.php:111` | `return view('hpc::templates_menu.index', compact(...))` |

### CODE-TRACE-03: `hpc_form()` � HpcController (Line 301)

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
| 11 | `HpcController.php:462-480` | Returns template-specific view based on `$templateId`: 1?`first_form`, 2?`second_form`, 3?`third_form`, 4?`fourth_form` |

### CODE-TRACE-04: `formStore()` � HpcController (Line 670)

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

### CODE-TRACE-05: Workflow Methods � HpcController

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `submitReport()` (Line 1856) | `Gate::authorize('tenant.hpc.update')` ? finds report by ID ? calls `HpcWorkflowService::finalize()` ? returns JSON |
| 2 | `reviewReport()` (Line 1875) | `Gate::authorize('tenant.hpc.review')` ? finds report ? calls `HpcWorkflowService::publish()` ? returns JSON |
| 3 | `approveReport()` (Line 1894) | `Gate::authorize('tenant.hpc.review')` ? finds report ? calls `HpcWorkflowService::finalize()` ? returns JSON |
| 4 | `sendBackReport()` (Line 1913) | `Gate::authorize('tenant.hpc.review')` ? finds report ? calls `HpcWorkflowService::sendBackToDraft()` ? returns JSON |
| 5 | `publishReport()` (Line 1932) | `Gate::authorize('tenant.hpc.publish')` ? finds report ? calls `HpcWorkflowService::publish()` ? returns JSON |
| 6 | `archiveReport()` (Line 1951) | `Gate::authorize('tenant.hpc.update')` ? finds report ? calls `HpcWorkflowService::archive()` ? returns JSON |
| 7 | `workflowStatus()` (Line 1970) | `Gate::authorize('tenant.hpc.view')` ? finds report ? calls `HpcWorkflowService::getAuditInfo()` ? returns JSON |

---
