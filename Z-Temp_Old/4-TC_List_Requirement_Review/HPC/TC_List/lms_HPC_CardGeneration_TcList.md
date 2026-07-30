# lms_HPC_CardGeneration_TcList

## Module: HPC → Card Generation

---

## 1. Feature Information

| Item | Details |
|------|---------|
| Module | HPC |
| Tab Group | Card Generation |
| Feature | Card Generation |
| URL(s) | `hpc/hpc-single/{student_id}`, `hpc/generate-report`, `hpc/download-zip/{filename}`, `hpc/hpc-view/{student_id}` |
| Controller | `Modules\Hpc\Http\Controllers\HpcController` (generateSingleStudentPdf, generateReportPdf, downloadZip, viewPdfPage) |
| Model(s) | `Modules\Hpc\Models\HpcReport`, `HpcReportItem`, `HpcReportTable`, `StudentHpcSnapshot` |
| Permissions | `tenant.hpc.viewAny`, `tenant.hpc.view` (BUG-HPC-016: card generation missing gate) |
| Soft Deletes | No direct |
| Activity Log | None for generation (activity may be logged at workflow level) |

---

## 2. Pre-conditions

- Required permissions: `tenant.hpc.viewAny` for bulk operations, `tenant.hpc.view` for single card view (BUG-HPC-016: missing gate on generateSingleStudentPdf and generateReportPdf)
- At least one `HpcReport` with status = 'final' or 'published' exists with associated `HpcReportItem` and `HpcReportTable` records
- Student record exists and is accessible for the given `student_id`
- Template configuration exists for the `template_id` mapping to `first_pdf`/`second_pdf`/`third_pdf`/`fourth_pdf`/`default_pdf`
- Tenant context must be initialized via `tenancy()->initialize()`
- Dusk environment variables: `DUSK_TENANT_URL`, `DUSK_ADMIN_EMAIL`, `DUSK_ADMIN_PASSWORD`
- For bulk ZIP: storage directory writable for temp file creation
- For public view: encryption service available for student_id encryption/decryption
- `StudentHpcSnapshot` model exists but no migration has been created (feature not built)

---

## 3. Default Data Load

When the page loads for card generation, the following data is fetched:

| Data Loaded | Source | Filters | Pagination |
|------------|--------|---------|------------|
| HpcReport for PDF generation | `HpcReport::with('report_items', 'report_tables')->findOrFail($report_id)` | report_id | None (single record) |
| Student details | `Student::findOrFail($student_id)` | student_id | None |
| Template configuration | `HpcTemplate::find($template_id)` | template_id | None |
| All students for bulk selection | `Student::whereIn('id', $student_ids)->with('hpcReport')` | student_ids array | None |
| Public view data | `HpcReport::where('student_id', decrypt($encrypted_student_id))->first()` | decrypted student_id | None |
| StudentHpcSnapshot | `StudentHpcSnapshot::where('student_id', $student_id)->get()` | student_id | None (model exists, no migration) |

---

## 4. Test Data Strategy

- **PDF templates**: Seed template configurations with each layout type — `first_pdf`, `second_pdf`, `third_pdf`, `fourth_pdf`, `default_pdf`
- **Report data**: Seed `HpcReport` with multiple `HpcReportItem` and `HpcReportTable` records for comprehensive PDF content
- **Bulk ZIP**: Create test datasets of exactly 50 students and 51 students for boundary testing
- **Filename variations**: Test with special characters, spaces, long names to verify sanitization regex `[A-Za-z0-9_.-]`
- **Public view**: Seed encrypted student_id tokens with valid and invalid values
- **Status coverage**: Create reports with status= draft, final, published, archived
- **Template not found**: Delete or omit template configuration to test fallback
- **Empty data**: Create HpcReport with no associated items or tables
- **Pre-test cleanup**: Delete created records and temp files before/after tests

---

## 5. Business Conditions

### 4.1 Database Schema — Card Generation Tables

| BC ID | Table | Column | Type (DDL) | Constraints |
|-------|-------|--------|------------|-------------|
| BC-DB-01 | hpc_reports | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-02 | hpc_reports | student_id | INT UNSIGNED | NOT NULL, FK → `sch_students.id` |
| BC-DB-03 | hpc_reports | template_id | INT UNSIGNED | NOT NULL, FK → `hpc_templates.id` |
| BC-DB-04 | hpc_reports | status | ENUM('draft','final','published','archived') | NOT NULL DEFAULT 'draft' |
| BC-DB-05 | hpc_reports | created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |
| BC-DB-06 | hpc_reports | updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP ON UPDATE |
| BC-DB-07 | hpc_report_items | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-08 | hpc_report_items | hpc_report_id | INT UNSIGNED | NOT NULL, FK → `hpc_reports.id` |
| BC-DB-09 | hpc_report_items | section | VARCHAR(255) | NOT NULL |
| BC-DB-10 | hpc_report_items | field_name | VARCHAR(255) | NOT NULL |
| BC-DB-11 | hpc_report_items | field_value | TEXT | NULLABLE |
| BC-DB-12 | hpc_report_items | field_type | VARCHAR(50) | NOT NULL |
| BC-DB-13 | hpc_report_tables | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-14 | hpc_report_tables | hpc_report_id | INT UNSIGNED | NOT NULL, FK → `hpc_reports.id` |
| BC-DB-15 | hpc_report_tables | grid_data | JSON | NOT NULL |
| BC-DB-16 | hpc_report_tables | section | VARCHAR(255) | NOT NULL |
| BC-DB-17 | hpc_templates | id | INT UNSIGNED | PK, auto-increment |
| BC-DB-18 | hpc_templates | layout_type | ENUM('first_pdf','second_pdf','third_pdf','fourth_pdf','default_pdf') | NOT NULL |
| BC-DB-19 | student_hpc_snapshots | id | INT UNSIGNED | PK, auto-increment (model exists, no migration) |
| BC-DB-20 | student_hpc_snapshots | student_id | INT UNSIGNED | NOT NULL, FK → `sch_students.id` |

### 4.2 Validation Rules (Create)

| BC ID | Field | Rule | Error Message / Behavior |
|-------|-------|------|--------------------------|
| BC-VAL-01 | student_id (route) | Must be valid integer existing in sch_students | 404 Not Found |
| BC-VAL-02 | student_ids (bulk) | Array of integers, max 50 items | 422 Validation Error if > 50 or empty array |
| BC-VAL-03 | filename (download) | Must match regex `[A-Za-z0-9_.-]+` | 400 Bad Request |
| BC-VAL-04 | encrypted_student_id | Must be decryptable | 404 Not Found |
| BC-VAL-05 | template_id | Must exist in hpc_templates | Fallback to default_pdf |

### 4.3 Validation Rules (Update)

| BC ID | Field | Rule | Error Message / Behavior |
|-------|-------|------|--------------------------|
| BC-VAL-U01 | (No update-specific validation) | N/A — no update operations for card generation | No update operations exist for this feature |

### 4.4 Authorization (Permission Gates)

| BC ID | Permission | Controller Method | Behavior |
|-------|-----------|-------------------|----------|
| BC-AUTH-01 | `tenant.hpc.viewAny` | generateReportPdf(), downloadZip() | Required for bulk ZIP download and generate-report |
| BC-AUTH-02 | `tenant.hpc.view` | generateSingleStudentPdf() | Should gate single student PDF generation (BUG-HPC-016: missing) |
| BC-AUTH-03 | Public view (`hpc-view`) | viewPdfPage() | No auth required — accessible without authentication |
| BC-AUTH-04 | Guest access on protected routes | — | Redirected to login page |
| BC-AUTH-05 | Student access to own card | generateSingleStudentPdf() | Student can generate/view own card |

### 4.5 Business Logic

| BC ID | Condition | Expected Behavior |
|-------|-----------|-------------------|
| BC-BIZ-01 | Single PDF generation | Collects all saved data from HpcReport + HpcReportItem + HpcReportTable and renders to PDF |
| BC-BIZ-02 | Template-specific PDF layout | `template_id` maps to layout method: `first_pdf`/`second_pdf`/`third_pdf`/`fourth_pdf`/`default_pdf` |
| BC-BIZ-03 | Template 1 → first_pdf | Report with template_id=1 renders using first_pdf layout |
| BC-BIZ-04 | Template 2 → second_pdf | Report with template_id=2 renders using second_pdf layout |
| BC-BIZ-05 | Template 3 → third_pdf | Report with template_id=3 renders using third_pdf layout |
| BC-BIZ-06 | Template 4 → fourth_pdf | Report with template_id=4 renders using fourth_pdf layout |
| BC-BIZ-07 | Default template → default_pdf | Any other template_id or missing template renders using default_pdf layout |
| BC-BIZ-08 | Single PDF — immediate download | Browser initiates download of PDF file immediately |
| BC-BIZ-09 | Bulk ZIP — max 50 students | Accepts up to 50 student_ids; rejects > 50 |
| BC-BIZ-10 | Bulk ZIP — archive creation | Creates ZIP archive containing individual PDFs for each student |
| BC-BIZ-11 | Bulk ZIP — filename sanitized | Filename cleaned to match `[A-Za-z0-9_.-]+` |
| BC-BIZ-12 | Bulk ZIP — temp file deleted after download | Temporary ZIP file removed from storage after response is sent |
| BC-BIZ-13 | Public view — no auth required | `/hpc-view/{student_id}` accessible without authentication |
| BC-BIZ-14 | Public view — encrypted student_id | Student ID is encrypted in URL; decrypted server-side |
| BC-BIZ-15 | BUG-HPC-016: Missing authorization gate | `generateSingleStudentPdf` and `generateReportPdf` lack `@can` or policy gate check |
| BC-BIZ-16 | StudentHpcSnapshot — model exists | Model class exists in codebase but no migration table was created |
| BC-BIZ-17 | PDF content includes all sections | Report items (text fields) and report tables (grid data) both rendered in PDF |
| BC-BIZ-18 | HpcReport status check before generation | Based on status (Draft/Final/Published/Archived), PDF generation allowed or restricted |

### 4.6 Referential Integrity

| BC ID | FK Column | Referenced Table | onDelete (DDL) |
|-------|-----------|------------------|----------------|
| BC-REF-01 | hpc_reports.student_id | sch_students (id) | CASCADE |
| BC-REF-02 | hpc_reports.template_id | hpc_templates (id) | RESTRICT |
| BC-REF-03 | hpc_report_items.hpc_report_id | hpc_reports (id) | CASCADE |
| BC-REF-04 | hpc_report_tables.hpc_report_id | hpc_reports (id) | CASCADE |

---

## 6. Test Case List

### 5.1 Positive Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-P01 | Generate single student PDF (template 1 → first_pdf) | PDF generated using first_pdf layout; download initiated | — | — | ⬜ |
| TC-P02 | Generate single student PDF (template 2 → second_pdf) | PDF generated using second_pdf layout | — | — | ⬜ |
| TC-P03 | Generate single student PDF (template 3 → third_pdf) | PDF generated using third_pdf layout | — | — | ⬜ |
| TC-P04 | Generate single student PDF (template 4 → fourth_pdf) | PDF generated using fourth_pdf layout | — | — | ⬜ |
| TC-P05 | Generate single student PDF (default → default_pdf) | PDF generated using default_pdf layout | — | — | ⬜ |
| TC-P06 | PDF contains all report sections | Report items (text fields) and report table grid data both rendered in PDF | — | — | ⬜ |
| TC-P07 | Bulk ZIP exactly 50 students | ZIP created with 50 individual PDFs | — | — | ⬜ |
| TC-P08 | Bulk ZIP contains correct PDF count | ZIP archive contains exactly 1 PDF per student (50 PDFs) | — | — | ⬜ |
| TC-P09 | Bulk ZIP filename sanitized | Special chars stripped; filename matches `[A-Za-z0-9_.-]+` | — | — | ⬜ |
| TC-P10 | downloadZip triggers file download | Browser download of ZIP file initiated | — | — | ⬜ |
| TC-P11 | Public view renders card for valid encrypted student_id | Card page displays with student's report data | — | — | ⬜ |
| TC-P12 | Single PDF for student with final status | PDF generated successfully for final status report | — | — | ⬜ |
| TC-P13 | Single PDF for student with published status | PDF generated successfully for published status report | — | — | ⬜ |
| TC-P14 | Bulk ZIP with mixed template types | Multiple students with different template_ids each get correct layout in their PDF | — | — | ⬜ |
| TC-P15 | Bulk ZIP filename with underscores passes sanitization | Filename with underscores accepted | — | — | ⬜ |
| TC-P16 | Bulk ZIP filename with hyphens passes sanitization | Filename with hyphens accepted | — | — | ⬜ |
| TC-P17 | Bulk ZIP filename with periods passes sanitization | Filename with periods accepted | — | — | ⬜ |
| TC-P18 | Public view displays student name and class | Card shows correct student info from decrypted ID | — | — | ⬜ |
| TC-P19 | Public view shows all report sections | All HpcReportItem and HpcReportTable data visible | — | — | ⬜ |
| TC-P20 | Temp file cleaned after ZIP download | No leftover temp ZIP files in storage directory | — | — | ⬜ |
| TC-P21 | generateReportPdf with report_id | PDF generated from report_id directly | — | — | ⬜ |
| TC-P22 | PDF download with proper Content-Type header | Response Content-Type: application/pdf | — | — | ⬜ |

### 5.2 Negative Test Cases

| TC ID | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|-------------|----------------|---------|---------|--------|
| TC-N01 | Bulk ZIP 51 students — rejected | 422 Validation Error; max 50 students allowed | — | — | ⬜ |
| TC-N02 | Bulk ZIP with 0 students — rejected | 422 Validation Error; empty array not allowed | — | — | ⬜ |
| TC-N03 | Invalid filename characters (spaces/special chars) → 400 | Filename with invalid chars returns 400 Bad Request | — | — | ⬜ |
| TC-N04 | Student without card data (empty report) | PDF generated with empty/graceful content — no error | — | — | ⬜ |
| TC-N05 | Template not found → fallback to default_pdf | Missing template falls back to default_pdf layout | — | — | ⬜ |
| TC-N06 | Invalid encrypted student_id for public view | 404 Not Found — decryption fails | — | — | ⬜ |
| TC-N07 | Tampered encrypted student_id for public view | 404 Not Found — decryption/validation fails | — | — | ⬜ |
| TC-N08 | Permission denied for single student PDF | Should 403 but BUG-HPC-016: missing gate allows access | — | — | ⬜ |
| TC-N09 | Guest redirect on protected routes | Unauthenticated user redirected to login for protected routes | — | — | ⬜ |
| TC-N10 | Non-existent student_id for single PDF | 404 Not Found | — | — | ⬜ |
| TC-N11 | Draft status report → PDF generation | Based on policy — may be rejected or allowed (document expected behavior) | — | — | ⬜ |
| TC-N12 | Archived status report → PDF generation | Based on policy — may be rejected or allowed | — | — | ⬜ |
| TC-N13 | Bulk ZIP with duplicate student_ids | Duplicates handled — may generate duplicate PDFs or dedupe (document behavior) | — | — | ⬜ |
| TC-N14 | StudentHpcSnapshot table missing (no migration) | Model query fails gracefully; snapshot section shows N/A or empty | — | — | ⬜ |
| TC-N15 | Public view with non-existent decrypted student_id | 404 Not Found — student record not found after decryption | — | — | ⬜ |

### 5.3 Dependency Test Cases

| TC ID | Category | Description | Expected Result | V1 Test | V2 Test | Status |
|-------|----------|-------------|----------------|---------|---------|--------|
| TC-D01 | A | PDF layout selection by template_id logic | template_id=1 → first_pdf, template_id=2 → second_pdf, template_id=3 → third_pdf, template_id=4 → fourth_pdf, others → default_pdf | — | — | ⬜ |
| TC-D02 | B | File cleanup after zip download | Temp ZIP file deleted from `/tmp` or storage after response sent | — | — | ⬜ |
| TC-D03 | C | downloadZip filename validation regex | Filename matched against `[A-Za-z0-9_.-]+` — invalid chars rejected | — | — | ⬜ |
| TC-D04 | D | Public view encryption/decryption | Student_id encrypted in URL, decrypted server-side; invalid cipher → 404 | — | — | ⬜ |
| TC-D05 | E | StudentHpcSnapshot model without migration | Model class exists but query throws exception or returns empty — handled gracefully | — | — | ⬜ |
| TC-D06 | F | Activity log on generation (if any) | No activity log for generation (documented); verify none created | — | — | ⬜ |
| TC-D07 | G | HpcReport status check before generation | Check for Draft/Final/Published/Archived — behaviour per status documented | — | — | ⬜ |
| TC-D08 | H | report_items aggregation for PDF content | All report_item field_name/field_value pairs rendered in PDF sections | — | — | ⬜ |
| TC-D09 | I | report_table grid data for PDF | JSON grid_data rendered as formatted table in PDF | — | — | ⬜ |
| TC-D10 | J | BUG-HPC-016: Missing authorization gate | Code review confirms `@can` or Gate::check missing on generateSingleStudentPdf and generateReportPdf | — | — | ⬜ |
| TC-D11 | K | Bulk ZIP temp file name generation | Temp filename uses unique identifier to avoid collisions | — | — | ⬜ |
| TC-D12 | L | ZIP archive contains valid PDF files | Each file inside ZIP is a valid PDF (opens correctly) | — | — | ⬜ |
| TC-D13 | M | Single student PDF with all field_types | Text, number, date, textarea field_types all render correctly in PDF | — | — | ⬜ |
| TC-D14 | N | Public view without HpcReport record | 404 Not Found or empty state — student has no report | — | — | ⬜ |
| TC-D15 | O | Single PDF memory usage with large report | Report with 200+ items and 50+ table rows generates without memory exhaustion | — | — | ⬜ |
| TC-D16 | P | Bulk ZIP concurrent requests | Two simultaneous bulk ZIP requests process independently | — | — | ⬜ |
| TC-D17 | Q | Filename sanitization — unicode characters | Unicode chars stripped/replaced; only `[A-Za-z0-9_.-]` kept | — | — | ⬜ |
| TC-D18 | Q | Filename sanitization — path traversal attempts | '../' or '/' characters stripped; no path traversal | — | — | ⬜ |
| TC-D19 | R | Public view student_id encryption round-trip | encrypt(student_id) → URL → decrypt → original student_id | — | — | ⬜ |
| TC-D20 | S | generateReportPdf route binding | Route model binding for report_id resolves correctly | — | — | ⬜ |
| TC-D21 | T | downloadZip with non-existent filename | 404 Not Found — file never created or already expired | — | — | ⬜ |
| TC-D22 | U | Bulk ZIP partial failure (one student fails) | Other students' PDFs still generated; failed student skipped with warning | — | — | ⬜ |

---

## 7. Detailed Test Steps

### 7.1 Positive TC Steps

#### TC-P01: Generate Single Student PDF (Template 1 → first_pdf)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login with admin credentials | Authenticated |
| 2 | Ensure student has HpcReport with template_id=1, status=final, and associated report_items + report_tables | Seed data ready |
| 3 | Navigate to `hpc/hpc-single/{student_id}` | PDF download initiated |
| 4 | Verify Content-Type header is `application/pdf` | Correct MIME type |
| 5 | Verify Content-Disposition includes filename with `.pdf` extension | Attachment with PDF filename |
| 6 | Open downloaded PDF | PDF contains first_pdf layout styling and sections |
| 7 | Verify report_items data present in PDF | All saved field values visible |
| 8 | Verify report_tables grid data present in PDF | Grid tables rendered correctly |

---

#### TC-P02: Generate Single Student PDF (Template 2 → second_pdf)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure student has HpcReport with template_id=2 | Seed data ready |
| 2 | Navigate to `hpc/hpc-single/{student_id}` | PDF download initiated |
| 3 | Open downloaded PDF | PDF uses second_pdf layout (different from first_pdf) |
| 4 | Verify second_pdf specific sections present | Template 2 layout applied |

---

#### TC-P03: Generate Single Student PDF (Template 3 → third_pdf)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure student has HpcReport with template_id=3 | Seed data ready |
| 2 | Navigate to `hpc/hpc-single/{student_id}` | PDF download initiated |
| 3 | Open downloaded PDF | PDF uses third_pdf layout |
| 4 | Verify third_pdf specific sections present | Template 3 layout applied |

---

#### TC-P04: Generate Single Student PDF (Template 4 → fourth_pdf)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure student has HpcReport with template_id=4 | Seed data ready |
| 2 | Navigate to `hpc/hpc-single/{student_id}` | PDF download initiated |
| 3 | Open downloaded PDF | PDF uses fourth_pdf layout |
| 4 | Verify fourth_pdf specific sections present | Template 4 layout applied |

---

#### TC-P05: Generate Single Student PDF (Default → default_pdf)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure student has HpcReport with template_id=99 (non-standard) | Seed data ready |
| 2 | Navigate to `hpc/hpc-single/{student_id}` | PDF download initiated |
| 3 | Open downloaded PDF | PDF uses default_pdf layout |
| 4 | Verify default_pdf layout applied | Fallback to default works |

---

#### TC-P06: PDF Contains All Report Sections

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed report with 5 report_items (field types: text, number, date, textarea) and 2 report_tables (with JSON grid_data) | Rich dataset |
| 2 | Navigate to `hpc/hpc-single/{student_id}` | PDF download initiated |
| 3 | Open PDF and verify all 5 report_item fields rendered | Each field_name + field_value visible |
| 4 | Verify both report_table grid datasets rendered as tables | Grid data in table format visible |
| 5 | Verify section headers/labels present | All sections labelled correctly |

---

#### TC-P07: Bulk ZIP Exactly 50 Students

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure 50 students each have a HpcReport with final status | 50 student reports ready |
| 2 | POST to `hpc/generate-report` with all 50 student_ids | Request accepted (200) |
| 3 | ZIP file generated and download initiated | Download starts |
| 4 | Save ZIP and extract | Archive extracts successfully |

---

#### TC-P08: Bulk ZIP Contains Correct PDF Count

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Generate bulk ZIP with 50 students | ZIP downloaded |
| 2 | Extract ZIP archive | 50 files found |
| 3 | Count total PDF files in archive | Exactly 50 .pdf files |
| 4 | Verify each is a valid PDF | Each file opens correctly |

---

#### TC-P09: Bulk ZIP Filename Sanitized

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Request bulk ZIP with student set for class "Grade 5-A" (special chars) | Request accepted |
| 2 | Check generated filename in download response | Filename contains only `[A-Za-z0-9_.-]` chars |
| 3 | Spaces and special characters removed | Clean filename |

---

#### TC-P10: downloadZip Triggers File Download

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Generate a bulk ZIP (creates temp file) | ZIP created |
| 2 | Note the temp filename returned | Filename noted |
| 3 | Navigate to `hpc/download-zip/{filename}` | File download initiated |
| 4 | Verify Content-Type: application/zip | Correct MIME type |
| 5 | Verify Content-Disposition: attachment | Download prompt appears |

---

#### TC-P11: Public View Renders Card

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Encrypt a valid student_id using the app's encryption service | Encrypted string |
| 2 | Navigate to `hpc/hpc-view/{encrypted_student_id}` while logged OUT | Page loads without auth redirect |
| 3 | Verify card page displays student name | Student info visible |
| 4 | Verify card page displays report data | Report data visible |
| 5 | Verify no login prompt or 403 error | Public access works |

---

#### TC-P12: Single PDF With Final Status Report

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure student HpcReport has status='final' | Final report |
| 2 | Navigate to `hpc/hpc-single/{student_id}` | PDF generated and downloaded |
| 3 | Verify PDF contains full data | Complete report |

---

#### TC-P13: Single PDF With Published Status Report

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure student HpcReport has status='published' | Published report |
| 2 | Navigate to `hpc/hpc-single/{student_id}` | PDF generated and downloaded |
| 3 | Verify PDF contains full data | Complete report |

---

#### TC-P14: Bulk ZIP With Mixed Template Types

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 3 students: Student A (template_id=1), Student B (template_id=2), Student C (template_id=4) | Mixed templates |
| 2 | Generate bulk ZIP for these 3 students | ZIP downloaded |
| 3 | Extract ZIP and open Student A's PDF | Uses first_pdf layout |
| 4 | Open Student B's PDF | Uses second_pdf layout |
| 5 | Open Student C's PDF | Uses fourth_pdf layout |

---

#### TC-P15: Bulk ZIP Filename With Underscores

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Request bulk ZIP with filename "class_5_reports" | Request accepted |
| 2 | Check generated filename | Contains underscores, passes sanitization |

---

#### TC-P16: Bulk ZIP Filename With Hyphens

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Request bulk ZIP with filename "class-5-reports" | Request accepted |
| 2 | Check generated filename | Contains hyphens, passes sanitization |

---

#### TC-P17: Bulk ZIP Filename With Periods

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Request bulk ZIP with filename "class.5.reports" | Request accepted |
| 2 | Check generated filename | Contains periods, passes sanitization |

---

#### TC-P18: Public View Displays Student Name and Class

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Encrypt student_id for a known student | Encrypted token |
| 2 | Access public view URL | Page loads |
| 3 | Verify student full name displayed | Correct name |
| 4 | Verify class/grade information displayed | Correct class |

---

#### TC-P19: Public View Shows All Report Sections

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed report with multiple sections | Rich data |
| 2 | Access public view URL | Page loads |
| 3 | Scroll through entire page | All report sections visible |
| 4 | Verify report_items rendered | Field values shown |
| 5 | Verify report_tables rendered | Grid data shown |

---

#### TC-P20: Temp File Cleaned After ZIP Download

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Generate bulk ZIP and note temp path | Temp file created |
| 2 | Download ZIP file | Download completes |
| 3 | Check temp file path | File deleted from storage |
| 4 | Verify no orphaned temp files | Storage directory clean |

---

#### TC-P21: generateReportPdf With report_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure HpcReport exists with report_id | Report exists |
| 2 | POST to `hpc/generate-report` with report_id only | PDF generated |
| 3 | Verify correct student's data in PDF | Matches report_id |

---

#### TC-P22: PDF Download With Proper Content-Type Header

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Generate single student PDF | Download initiated |
| 2 | Check response header `Content-Type` | application/pdf |
| 3 | Check response header `Content-Disposition` | attachment; filename="*.pdf" |

---

### 7.2 Negative TC Steps

#### TC-N01: Bulk ZIP 51 Students — Rejected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to `hpc/generate-report` with 51 student_ids | 422 Validation Error |
| 2 | Verify error message mentions max 50 limit | "Maximum 50 students allowed" |
| 3 | No ZIP file created | No download initiated |

---

#### TC-N02: Bulk ZIP With 0 Students — Rejected

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to `hpc/generate-report` with empty student_ids array | 422 Validation Error |
| 2 | Verify error message mentions at least 1 required | At least one student required |

---

#### TC-N03: Invalid Filename Characters → 400

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Request download with filename "class report 2024!!" | 400 Bad Request |
| 2 | Verify error message about invalid characters | Filename sanitization error |
| 3 | Test filename with spaces | 400 Bad Request |
| 4 | Test filename with special chars `@#$%^&*` | 400 Bad Request |

---

#### TC-N04: Student Without Card Data

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure student has HpcReport but zero report_items and report_tables | Empty report |
| 2 | Navigate to `hpc/hpc-single/{student_id}` | PDF generated (no error) |
| 3 | Open PDF | PDF contains student info but sections are empty or show "No data available" |

---

#### TC-N05: Template Not Found → Fallback to default_pdf

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Assign student HpcReport to a non-existent template_id (e.g. 999) | Invalid template |
| 2 | Navigate to `hpc/hpc-single/{student_id}` | PDF generated |
| 3 | Open PDF | Uses default_pdf layout (fallback) |
| 4 | No 500 error thrown | Graceful fallback |

---

#### TC-N06: Invalid Encrypted student_id For Public View

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `hpc/hpc-view/invalid_encrypted_string` | 404 Not Found |
| 2 | Verify no stack trace shown | Clean 404 page |

---

#### TC-N07: Tampered Encrypted student_id For Public View

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Take valid encrypted string and modify a character | Tampered string |
| 2 | Navigate to `hpc/hpc-view/{tampered_string}` | 404 Not Found — decryption fails |

---

#### TC-N08: Permission Denied For Single Student PDF (BUG-HPC-016)

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Login as user without `tenant.hpc.view` permission | Authenticated |
| 2 | Navigate to `hpc/hpc-single/{student_id}` | PDF downloads (BUG: gate missing — should be 403) |
| 3 | Document this as BUG-HPC-016: Missing authorization gate on generateSingleStudentPdf | Known issue |

---

#### TC-N09: Guest Redirect On Protected Routes

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Logout completely | Not authenticated |
| 2 | Navigate to `hpc/hpc-single/{student_id}` | Redirected to login page |
| 3 | POST to `hpc/generate-report` | Redirected to login page |
| 4 | Navigate to `hpc/hpc-view/{student_id}` | Allowed — public route |

---

#### TC-N10: Non-Existent student_id For Single PDF

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `hpc/hpc-single/99999` | 404 Not Found |
| 2 | Verify clean 404 page | No application error trace |

---

#### TC-N11: Draft Status Report → PDF Generation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set student HpcReport status='draft' | Draft report |
| 2 | Navigate to `hpc/hpc-single/{student_id}` | Document behaviour — if rejected, show error; if allowed, PDF generated with draft watermark |

---

#### TC-N12: Archived Status Report → PDF Generation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Set student HpcReport status='archived' | Archived report |
| 2 | Navigate to `hpc/hpc-single/{student_id}` | Document behaviour — if rejected, show error; if allowed, PDF generated with archived notice |

---

#### TC-N13: Bulk ZIP With Duplicate student_ids

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to `hpc/generate-report` with duplicate student_ids (e.g. [1,2,3,1,2]) | Request accepted or rejected — document behaviour |
| 2 | If accepted, check ZIP for duplicate PDFs | Either deduped or duplicate files present |

---

#### TC-N14: StudentHpcSnapshot Table Missing

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Ensure student_hpc_snapshots table does NOT exist in DB (no migration) | Table missing |
| 2 | Navigate to `hpc/hpc-single/{student_id}` | PDF generated without errors |
| 3 | Snapshot section shows N/A or empty | Graceful handling |
| 4 | Verify no 500 error from missing table query | Caught exception |

---

#### TC-N15: Public View With Non-Existent Decrypted student_id

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Encrypt an integer that doesn't match any student (e.g. 99999) | Encrypted string |
| 2 | Navigate to `hpc/hpc-view/{encrypted_string}` | 404 Not Found — student not found after decryption |

---

### 7.3 Dependency TC Steps

#### TC-D01: PDF Layout Selection By template_id Logic

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect HpcController@generateSingleStudentPdf code | Layout selection logic found |
| 2 | Verify template_id=1 maps to `first_pdf` method | Mapping correct |
| 3 | Verify template_id=2 maps to `second_pdf` method | Mapping correct |
| 4 | Verify template_id=3 maps to `third_pdf` method | Mapping correct |
| 5 | Verify template_id=4 maps to `fourth_pdf` method | Mapping correct |
| 6 | Verify default case maps to `default_pdf` method | Fallback correct |
| 7 | Test each with actual PDF generation | Each layout applied correctly |

---

#### TC-D02: File Cleanup After ZIP Download

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Generate bulk ZIP and note the temp file path | Temp file path captured |
| 2 | Download ZIP | Download completes |
| 3 | Immediately check temp file path | File deleted |
| 4 | Check storage directory for any leftover temp ZIPs | No orphaned files |

---

#### TC-D03: downloadZip Filename Validation Regex

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect downloadZip method for filename validation | Regex pattern found |
| 2 | Verify regex matches `[A-Za-z0-9_.-]+` | Pattern correct |
| 3 | Test with valid: "report_2024-25.zip" | Passes validation |
| 4 | Test with invalid: "report 2024!!.zip" | Rejected with 400 |
| 5 | Test with invalid: "../../malicious.zip" | Rejected — no path traversal |

---

#### TC-D04: Public View Encryption/Decryption

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Take a valid student_id (e.g. 42) | Known ID |
| 2 | Encrypt using app's encryption service | Encrypted string |
| 3 | Pass encrypted string to viewPdfPage | Decrypts to 42 |
| 4 | Pass invalid/tampered string | Decryption fails → 404 |
| 5 | Inspect viewPdfPage code | Encryption/decryption logic verified |

---

#### TC-D05: StudentHpcSnapshot Model Without Migration

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Check migrations directory for student_hpc_snapshots table migration | No migration found |
| 2 | Check Models directory for StudentHpcSnapshot class | Model exists |
| 3 | Attempt to query StudentHpcSnapshot in code | Handles missing table gracefully |

---

#### TC-D06: Activity Log On Generation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Generate a single student PDF | PDF downloaded |
| 2 | Check activity_log table for generation event | No entry (no activity log for generation) |
| 3 | Confirm code has no activity logging for this action | Consistent with documentation |

---

#### TC-D07: HpcReport Status Check Before Generation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect generateSingleStudentPdf code | Status check logic found (or not) |
| 2 | Check if status is validated before PDF creation | Behaviour per status documented |
| 3 | Test with draft report | Actual behaviour observed |
| 4 | Test with final report | Allowed |
| 5 | Test with published report | Allowed |
| 6 | Test with archived report | Actual behaviour observed |

---

#### TC-D08: report_items Aggregation For PDF Content

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 10 report_items with various field_types and field_values | Rich data |
| 2 | Generate PDF | PDF created |
| 3 | Open PDF and verify all 10 items rendered | Each field_name: field_value visible |
| 4 | Verify field_types render correctly (text, number, date, textarea) | Proper formatting per type |

---

#### TC-D09: report_table Grid Data For PDF

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 2 report_tables with JSON grid_data containing rows/columns | Grid data |
| 2 | Generate PDF | PDF created |
| 3 | Open PDF and verify table data rendered | Tables with correct rows and columns |
| 4 | Verify table headers present | Column headers shown |

---

#### TC-D10: BUG-HPC-016 — Missing Authorization Gate

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Inspect HpcController@generateSingleStudentPdf code | No `@can` or `Gate::check` or `$this->authorize()` call found |
| 2 | Inspect HpcController@generateReportPdf code | No authorization gate found |
| 3 | Verify that other controller actions have proper gates | Inconsistency confirmed |
| 4 | Document finding as BUG-HPC-016 | Missing gate on card generation methods |

---

#### TC-D11: Bulk ZIP Temp File Name Generation

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Generate bulk ZIP and note temp filename | Filename observed |
| 2 | Generate another bulk ZIP immediately after | Different temp filename |
| 3 | Verify temp filenames are unique | No collision |

---

#### TC-D12: ZIP Archive Contains Valid PDF Files

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Generate bulk ZIP with 5 students | ZIP downloaded |
| 2 | Extract ZIP archive | 5 files extracted |
| 3 | Try to open each PDF | All 5 open without corruption |
| 4 | Verify each PDF contains correct student's data | Content matches student |

---

#### TC-D13: Single Student PDF With All Field Types

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed report_items with one of each field_type: text, number, date, textarea, select, checkbox | All types |
| 2 | Generate PDF | PDF created |
| 3 | Open PDF and verify each type renders correctly | Text shows as text, number formatted, date formatted, textarea wraps text, select shows selected value, checkbox shows checked/unchecked |

---

#### TC-D14: Public View Without HpcReport Record

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Encrypt student_id for a student with NO HpcReport | Encrypted string |
| 2 | Navigate to public view URL | 404 Not Found or page shows "No report available" |
| 3 | Verify no error/exception thrown | Graceful handling |

---

#### TC-D15: Single PDF Memory Usage With Large Report

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Seed 200 report_items and 50 report_tables for one student | Large report |
| 2 | Generate PDF | PDF generated within memory limits |
| 3 | Verify PDF contains all 200 items and 50 tables | Complete content |
| 4 | Check memory usage in logs | No memory exhaustion |

---

#### TC-D16: Bulk ZIP Concurrent Requests

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send 2 simultaneous bulk ZIP requests for different student sets | Both accepted |
| 2 | Both ZIP files generated independently | No cross-contamination |
| 3 | Each ZIP contains correct set of student PDFs | Data integrity maintained |

---

#### TC-D17: Filename Sanitization — Unicode Characters

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Request download with filename "étudiant_reports_2024" | Unicode chars stripped/replaced |
| 2 | Check sanitized filename | Only `[A-Za-z0-9_.-]` characters remain |

---

#### TC-D18: Filename Sanitization — Path Traversal Attempts

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Request download with filename "../../etc/passwd" | 400 Bad Request — path traversal chars stripped |
| 2 | Request download with filename "..\\..\\windows\\system32" | 400 Bad Request |
| 3 | Verify no directory traversal possible | Only safe filenames accepted |

---

#### TC-D19: Public View student_id Encryption Round-Trip

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Take student_id = 42 | Known ID |
| 2 | Encrypt: `encrypt(42)` → "abc123..." | Encrypted string |
| 3 | Decrypt: `decrypt("abc123...")` → 42 | Round-trip successful |
| 4 | Verify different student_id produces different encrypted string | No predictable mapping |

---

#### TC-D20: generateReportPdf Route Binding

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | POST to `hpc/generate-report` with valid report_id | PDF generated for that report |
| 2 | POST to `hpc/generate-report` with non-existent report_id | 404 Not Found |

---

#### TC-D21: downloadZip With Non-Existent Filename

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Navigate to `hpc/download-zip/nonexistent.zip` | 404 Not Found |
| 2 | Navigate to `hpc/download-zip/../config/app.php` | 404 or rejected — no path traversal |

---

#### TC-D22: Bulk ZIP Partial Failure

| Step # | Action | Expected Result |
|--------|--------|-----------------|
| 1 | Send 5 student_ids where 1 student has corrupt/no report data | Request processed |
| 2 | Verify 4 valid PDFs generated | 4 PDFs in ZIP |
| 3 | Verify failed student skipped with warning logged | Warning in log |
| 4 | No overall failure — ZIP still downloaded | Partial success handled |

## 8. CODE-TRACE: Controller Method Execution Traces

### CODE-TRACE-01: `generateSingleStudentPdf()` � HpcController (Line 2283)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcController.php:2286` | `Gate::authorize('tenant.hpc.view')` (unless `$bypassGate=true`) |
| 2 | `HpcController.php:2288-2295` | Loads latest `HpcReport` for student |
| 3 | `HpcController.php:2297-2305` | Loads `Student` with all relationships |
| 4 | `HpcController.php:2307-2315` | Resolves template, loads with `parts.sections.rubrics.items` |
| 5 | `HpcController.php:2317-2330` | Groups template parts by `page_no` |
| 6 | `HpcController.php:2332-2350` | Computes siblings, attendance aggregation |
| 7 | `HpcController.php:2352-2370` | Loads saved values via `reportService->getSavedValues()` |
| 8 | `HpcController.php:2372-2395` | Renders template-specific PDF view |
| 9 | `HpcController.php:2397-2420` | Builds PDF via `reportService->buildPdf()` |
| 10 | `HpcController.php:2422-2602` | Returns `$pdf->download()` |

### CODE-TRACE-02: `generateReportPdf()` � HpcController (Line 1256)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcController.php:1258` | No explicit Gate (handled by route middleware) |
| 2 | `HpcController.php:1260-1265` | Validates `student_ids` array, `academic_term_id` |
| 3 | `HpcController.php:1267-1285` | Batch pre-loads all students with relationships |
| 4 | `HpcController.php:1287-1310` | Batch loads attendance data grouped |
| 5 | `HpcController.php:1312-1335` | Loops each student: resolves template (cached), loads template, builds pages, computes siblings, attendance aggregation |
| 6 | `HpcController.php:1337-1360` | Loads saved values, feeds LMS data |
| 7 | `HpcController.php:1362-1395` | Renders template-specific PDF Blade view |
| 8 | `HpcController.php:1397-1420` | Generates PDF via `reportService->buildPdf()` |
| 9 | `HpcController.php:1422-1445` | Saves to `storage/app/public/hpc-reports/pdf/` |
| 10 | `HpcController.php:1447-1475` | Creates ZIP archive of all generated PDFs |
| 11 | `HpcController.php:1477-1639` | Returns JSON with `zip_url` and `pdf_urls` |

### CODE-TRACE-03: `downloadZip()` � HpcController (Line 1645)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcController.php:1647` | `Gate::authorize('tenant.hpc.viewAny')` |
| 2 | `HpcController.php:1649` | Sanitizes filename (alphanumeric + `_-.`) |
| 3 | `HpcController.php:1651-1661` | `return response()->download()` with `deleteFileAfterSend(true)` |

### CODE-TRACE-04: `viewPdfPage()` � HpcController (Line 1991)

| Step | Code Line | What Happens |
|------|-----------|--------------|
| 1 | `HpcController.php:1993-1997` | Tries to decrypt `$student_id` via `Crypt::decryptString()` |
| 2 | `HpcController.php:1999` | If numeric ID ? `Gate::authorize('tenant.hpc.view')`; if encrypted ? public access |
| 3 | `HpcController.php:2001` | Calls `$this->renderStudentReportView($student_id, $publicAccess)` |
| 4 | `HpcController.php:2003-2009` | Returns rendered PDF view (HTML for browser display) |

---
